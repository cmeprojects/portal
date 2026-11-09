-- Staff Portal · © cmeproject. All rights reserved.
-- Update 56: My requests (leave, shift swap, shift change, availability,
-- timesheet, HR enquiry, other) with configurable approvers, two-step
-- approval, escalation, and leave periods and shift changes on approval.
-- Safe to run again. Undo: undo-56.sql.
begin;
create table if not exists public.request_types (
  key             text primary key,
  label           text not null,
  feature_key     text not null,
  first_approvers text[] not null default '{}',
  second_approvers text[] not null default '{}',
  notify          text[] not null default '{}',
  escalate_days   int not null default 3 check (escalate_days between 0 and 60),
  escalate_to     text[] not null default '{manager}',
  sort_order      int not null default 0
);

insert into public.request_types (key, label, feature_key, first_approvers, second_approvers, sort_order) values
  ('leave', 'Leave', 'hr_req_leave', '{team_leader}', '{manager}', 10),
  ('swap', 'Shift swap', 'hr_req_swap', '{team_leader}', '{manager}', 20),
  ('shift', 'Shift change', 'hr_req_shift', '{team_leader}', '{manager}', 30),
  ('availability', 'Availability change', 'hr_req_availability', '{team_leader}', '{manager}', 40),
  ('timesheet', 'Timesheet correction', 'hr_req_timesheet', '{staff_admin}', '{manager}', 50),
  ('hr', 'HR or employment enquiry', 'hr_req_hr', '{staff_admin}', '{manager}', 60),
  ('other', 'Other request', 'hr_req_other', '{staff_admin}', '{}', 70)
on conflict (key) do nothing;

create table if not exists public.requests (
  id          uuid primary key default gen_random_uuid(),
  ref_number  bigint generated always as identity,
  type        text not null references public.request_types (key),
  requester   uuid not null references public.profiles (id) on delete cascade,
  status      text not null default 'pending' check (status in ('pending', 'info_needed', 'approved', 'declined', 'withdrawn')),
  stage       int not null default 1 check (stage in (1, 2)),
  subject     text not null default '' check (length(subject) <= 200),
  details     jsonb not null default '{}'::jsonb,
  start_date  date,
  end_date    date,
  swap_with   uuid references public.profiles (id) on delete set null,
  partner_ok  boolean,
  escalated_at timestamptz,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  decided_at  timestamptz,
  check (end_date is null or start_date is null or end_date >= start_date)
);
create index if not exists requests_requester on public.requests (requester, created_at desc);
create index if not exists requests_open on public.requests (status) where status in ('pending', 'info_needed');

create table if not exists public.request_events (
  id         bigint generated always as identity primary key,
  request_id uuid not null references public.requests (id) on delete cascade,
  actor      uuid references public.profiles (id) on delete set null,
  type       text not null,
  comment    text not null default '',
  created_at timestamptz not null default now()
);
create index if not exists request_events_request on public.request_events (request_id, id);

-- What approval changes.
create table if not exists public.leave_periods (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  request_id uuid references public.requests (id) on delete set null,
  leave_type text not null,
  start_date date not null,
  end_date   date not null,
  created_at timestamptz not null default now()
);
create table if not exists public.shift_changes (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  request_id uuid references public.requests (id) on delete set null,
  on_date    date,
  change     text not null,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Who approves
-- ---------------------------------------------------------------------------

-- The people a list like {team_leader, manager, user:<id>} means for one requester.
create or replace function public.resolve_people(p_list text[], p_requester uuid)
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select distinct id from (
    select tl.user_id as id
      from public.team_leaders tl join public.team_members tm on tm.team_id = tl.team_id
     where 'team_leader' = any (p_list) and tm.user_id = p_requester
    union
    select p.id from public.profiles p
     where p.active and p.role::text = any (p_list) and p.role::text <> 'team_leader'
    union
    select substr(x, 6)::uuid from unnest(p_list) x where x like 'user:%'
  ) s
  where id is not null and id <> p_requester
    and exists (select 1 from public.profiles q where q.id = s.id and q.active);
$$;

-- Who acts on a request at its current stage. With no team leader (or a team
-- leader asking for themselves), the step falls to the managers.
create or replace function public.request_approvers(p_request uuid)
returns setof uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  r public.requests;
  t public.request_types;
  list text[];
begin
  select * into r from public.requests where id = p_request;
  select * into t from public.request_types where key = r.type;
  list := case when r.stage = 1 then t.first_approvers else t.second_approvers end;
  return query select * from public.resolve_people(list, r.requester);
  if not found then
    return query select * from public.resolve_people('{manager}', r.requester);
  end if;
end;
$$;

create or replace function public.can_act_on_request(p_request uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and (public.is_system_admin() or exists (select 1 from public.request_approvers(p_request) a where a = auth.uid()))
$$;

-- ---------------------------------------------------------------------------
-- Who sees what
-- ---------------------------------------------------------------------------

alter table public.request_types enable row level security;
alter table public.requests enable row level security;
alter table public.request_events enable row level security;
alter table public.leave_periods enable row level security;
alter table public.shift_changes enable row level security;

drop policy if exists "members read request types" on public.request_types;
create policy "members read request types" on public.request_types for select to authenticated using (public.is_member());
drop policy if exists "system admin changes request types" on public.request_types;
create policy "system admin changes request types" on public.request_types for update to authenticated using (public.is_system_admin()) with check (public.is_system_admin());

drop policy if exists "people involved see a request" on public.requests;
create policy "people involved see a request" on public.requests for select to authenticated using (
  public.feature_enabled('hr_requests') and (
    requester = auth.uid() or swap_with = auth.uid() or public.can_manage_people() or public.is_system_admin()
    or public.can_act_on_request(id)));
drop policy if exists "people involved see its history" on public.request_events;
create policy "people involved see its history" on public.request_events for select to authenticated using (
  exists (select 1 from public.requests r where r.id = request_id));
drop policy if exists "the person and people managers see leave" on public.leave_periods;
create policy "the person and people managers see leave" on public.leave_periods for select to authenticated using (
  user_id = auth.uid() or public.can_manage_people() or public.is_system_admin()
  or exists (select 1 from public.team_leaders tl join public.team_members tm on tm.team_id = tl.team_id where tl.user_id = auth.uid() and tm.user_id = leave_periods.user_id));
drop policy if exists "the person and people managers see shift changes" on public.shift_changes;
create policy "the person and people managers see shift changes" on public.shift_changes for select to authenticated using (
  user_id = auth.uid() or public.can_manage_people() or public.is_system_admin()
  or exists (select 1 from public.team_leaders tl join public.team_members tm on tm.team_id = tl.team_id where tl.user_id = auth.uid() and tm.user_id = shift_changes.user_id));

revoke insert, update, delete, truncate on public.requests, public.request_events, public.leave_periods, public.shift_changes from anon, authenticated;
revoke insert, delete, truncate on public.request_types from anon, authenticated;
grant select on public.request_types, public.requests, public.request_events, public.leave_periods, public.shift_changes to authenticated;
grant update (first_approvers, second_approvers, notify, escalate_days, escalate_to) on public.request_types to authenticated;

-- ---------------------------------------------------------------------------
-- Sending and acting on requests
-- ---------------------------------------------------------------------------

create or replace function public.request_ref(p_request uuid)
returns text language sql stable set search_path = '' as $$
  select 'REQ-' || lpad(ref_number::text, 4, '0') from public.requests where id = p_request
$$;

-- Tell a list of people (bell, and email when the type allows).
create or replace function public.notify_many(p_people uuid[], p_kind text, p_title text, p_body text, p_href text)
returns void language plpgsql security definer set search_path = '' as $$
declare u uuid;
begin
  foreach u in array coalesce(p_people, '{}') loop
    perform public.notify(u, p_kind, p_title, p_body, p_href, true);
  end loop;
end;
$$;

create or replace function public.submit_request(p_type text, p_subject text, p_details jsonb, p_start date, p_end date, p_swap_with uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.request_types;
  v_id uuid;
  v_ref text;
  who text;
begin
  select * into t from public.request_types where key = p_type;
  if t.key is null then raise exception 'Choose a request type.'; end if;
  if not public.is_member() or not public.feature_live(t.feature_key) then
    raise exception '% requests are switched off.', t.label;
  end if;
  if public.is_system_admin() then raise exception 'The system admin doesn''t send requests.'; end if;
  if p_end is not null and p_start is not null and p_end < p_start then raise exception 'The end date is before the start date.'; end if;
  if p_type in ('leave', 'availability') and p_start is null then raise exception 'Choose the start date.'; end if;
  if p_type = 'swap' and p_swap_with is null then raise exception 'Choose who you''re swapping with.'; end if;
  if p_swap_with = auth.uid() then raise exception 'You can''t swap with yourself.'; end if;

  insert into public.requests (type, requester, subject, details, start_date, end_date, swap_with)
  values (p_type, auth.uid(), left(coalesce(trim(p_subject), ''), 200), coalesce(p_details, '{}'), p_start, coalesce(p_end, p_start), p_swap_with)
  returning id into v_id;
  insert into public.request_events (request_id, actor, type) values (v_id, auth.uid(), 'submitted');
  v_ref := public.request_ref(v_id);
  select coalesce(nullif(full_name, ''), email) into who from public.profiles where id = auth.uid();

  if p_type = 'swap' then
    perform public.notify(p_swap_with, 'request_partner', who || ' wants to swap a shift with you', v_ref || ': accept or decline it first.', '/requests/' || v_id, true);
  else
    perform public.notify_many(array(select public.request_approvers(v_id)), 'request_submitted', t.label || ' request from ' || who, v_ref || ' is waiting for you.', '/requests/' || v_id);
  end if;
  perform public.notify_many(array(select public.resolve_people(t.notify, auth.uid())), 'request_submitted', t.label || ' request from ' || who, v_ref || ' (for your information).', '/requests/' || v_id);
  return v_id;
end;
$$;

-- What approval changes in the person's records.
create or replace function public.apply_request(p_request uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare r public.requests;
begin
  select * into r from public.requests where id = p_request;
  if r.type = 'leave' then
    insert into public.leave_periods (user_id, request_id, leave_type, start_date, end_date)
    values (r.requester, r.id, coalesce(r.details ->> 'leave_type', 'other'), r.start_date, coalesce(r.end_date, r.start_date));
  elsif r.type = 'availability' and jsonb_typeof(r.details -> 'availability') = 'object' then
    insert into public.staff_private (user_id) values (r.requester) on conflict do nothing;
    update public.staff_private set availability = r.details -> 'availability', updated_at = now() where user_id = r.requester;
  elsif r.type = 'swap' then
    insert into public.shift_changes (user_id, request_id, on_date, change) values
      (r.requester, r.id, r.start_date, 'Swapped: ' || coalesce(r.details ->> 'my_shift', '') || ' with ' || coalesce((select coalesce(nullif(full_name, ''), email) from public.profiles where id = r.swap_with), 'a colleague')),
      (r.swap_with, r.id, r.start_date, 'Swapped: takes ' || coalesce(r.details ->> 'my_shift', '') || ' from ' || coalesce((select coalesce(nullif(full_name, ''), email) from public.profiles where id = r.requester), 'a colleague'));
  elsif r.type = 'shift' then
    insert into public.shift_changes (user_id, request_id, on_date, change)
    values (r.requester, r.id, r.start_date, 'Changed: ' || coalesce(r.details ->> 'current_shift', '') || ' → ' || coalesce(r.details ->> 'new_shift', ''));
  end if;
end;
$$;

create or replace function public.request_action(p_request uuid, p_action text, p_comment text default '')
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.requests;
  t public.request_types;
  v_ref text;
  note text := left(coalesce(trim(p_comment), ''), 2000);
  title text;
begin
  select * into r from public.requests where id = p_request for update;
  if r.id is null then raise exception 'That request doesn''t exist.'; end if;
  select * into t from public.request_types where key = r.type;
  v_ref := public.request_ref(r.id);
  title := t.label || ' request ' || v_ref;
  if not public.feature_live('hr_requests') then raise exception 'My requests are switched off.'; end if;

  if p_action = 'comment' then
    if note = '' then raise exception 'Write a comment first.'; end if;
    if not (r.requester = auth.uid() or r.swap_with = auth.uid() or public.can_act_on_request(r.id) or public.can_manage_people()) then
      raise exception 'You can''t comment on this request.';
    end if;
    insert into public.request_events (request_id, actor, type, comment) values (r.id, auth.uid(), 'comment', note);
    -- A reply from the person answers "more information needed".
    if r.requester = auth.uid() and r.status = 'info_needed' then
      update public.requests set status = 'pending', updated_at = now() where id = r.id;
      perform public.notify_many(array(select public.request_approvers(r.id)), 'request_submitted', title || ' has more information', note, '/requests/' || r.id);
    elsif r.requester <> auth.uid() then
      perform public.notify(r.requester, 'request_decided', 'New comment on ' || title, note, '/requests/' || r.id, false);
    end if;
    return 'Comment added.';
  end if;

  if p_action = 'withdraw' then
    if r.requester <> auth.uid() then raise exception 'Only the person who sent it can withdraw it.'; end if;
    if r.status not in ('pending', 'info_needed') then raise exception 'It''s already been decided.'; end if;
    update public.requests set status = 'withdrawn', updated_at = now(), decided_at = now() where id = r.id;
    insert into public.request_events (request_id, actor, type, comment) values (r.id, auth.uid(), 'withdrawn', note);
    return 'Request withdrawn.';
  end if;

  if p_action in ('partner_accept', 'partner_decline') then
    if r.swap_with is distinct from auth.uid() then raise exception 'Only the person asked to swap can answer this.'; end if;
    if r.partner_ok is not null or r.status <> 'pending' then raise exception 'You''ve already answered.'; end if;
    if p_action = 'partner_accept' then
      update public.requests set partner_ok = true, updated_at = now() where id = r.id;
      insert into public.request_events (request_id, actor, type, comment) values (r.id, auth.uid(), 'partner_accepted', note);
      perform public.notify_many(array(select public.request_approvers(r.id)), 'request_submitted', title || ' is ready to approve', 'Both people agreed to the swap.', '/requests/' || r.id);
      perform public.notify(r.requester, 'request_decided', 'Your swap was accepted', v_ref || ' now goes for approval.', '/requests/' || r.id, false);
      return 'Thanks. It now goes for approval.';
    end if;
    update public.requests set partner_ok = false, status = 'declined', updated_at = now(), decided_at = now() where id = r.id;
    insert into public.request_events (request_id, actor, type, comment) values (r.id, auth.uid(), 'partner_declined', note);
    perform public.notify(r.requester, 'request_decided', 'Your swap was declined', coalesce(nullif(note, ''), v_ref), '/requests/' || r.id, true);
    return 'Swap declined.';
  end if;

  -- Approver actions
  if not public.can_act_on_request(r.id) then raise exception 'You''re not an approver for this request.'; end if;
  if r.status not in ('pending', 'info_needed') then raise exception 'It''s already been decided.'; end if;
  if r.type = 'swap' and r.partner_ok is not true then raise exception 'Wait until the other person accepts the swap.'; end if;

  if p_action = 'info' then
    if note = '' then raise exception 'Say what information you need.'; end if;
    update public.requests set status = 'info_needed', updated_at = now() where id = r.id;
    insert into public.request_events (request_id, actor, type, comment) values (r.id, auth.uid(), 'info_requested', note);
    perform public.notify(r.requester, 'request_decided', 'More information needed for ' || title, note, '/requests/' || r.id, true);
    return 'Asked for more information.';
  elsif p_action = 'decline' then
    if note = '' then raise exception 'Give a reason for declining.'; end if;
    update public.requests set status = 'declined', updated_at = now(), decided_at = now() where id = r.id;
    insert into public.request_events (request_id, actor, type, comment) values (r.id, auth.uid(), 'declined', note);
    perform public.notify(r.requester, 'request_decided', title || ' was declined', note, '/requests/' || r.id, true);
    return 'Request declined.';
  elsif p_action = 'approve' then
    -- Two-step approval means two people, unless nobody else can give the final one.
    if r.stage = 2 and not public.is_system_admin()
       and exists (select 1 from public.request_events where request_id = r.id and type = 'approved_first' and actor = auth.uid())
       and exists (select 1 from public.request_approvers(r.id) a where a <> auth.uid()) then
      raise exception 'You gave the first approval. Someone else needs to give the final one.';
    end if;
    if r.stage = 1 and cardinality(t.second_approvers) > 0 and exists (select 1 from public.resolve_people(t.second_approvers, r.requester)) then
      update public.requests set stage = 2, status = 'pending', updated_at = now(), escalated_at = null where id = r.id;
      insert into public.request_events (request_id, actor, type, comment) values (r.id, auth.uid(), 'approved_first', note);
      perform public.notify_many(array(select public.request_approvers(r.id)), 'request_submitted', title || ' needs final approval', 'First approval done.', '/requests/' || r.id);
      perform public.notify(r.requester, 'request_decided', title || ': first approval done', 'It now goes for final approval.', '/requests/' || r.id, false);
      return 'Approved. It now goes for final approval.';
    end if;
    update public.requests set status = 'approved', updated_at = now(), decided_at = now() where id = r.id;
    insert into public.request_events (request_id, actor, type, comment) values (r.id, auth.uid(), 'approved', note);
    perform public.apply_request(r.id);
    perform public.notify(r.requester, 'request_decided', title || ' was approved', coalesce(nullif(note, ''), 'Approved.'), '/requests/' || r.id, true);
    if r.swap_with is not null then
      perform public.notify(r.swap_with, 'request_decided', 'The shift swap ' || v_ref || ' was approved', '', '/requests/' || r.id, true);
    end if;
    return 'Request approved.';
  end if;
  raise exception 'Unknown action.';
end;
$$;

-- Requests nobody has acted on within the set days go to the escalation list
-- (once per stage). Run by the scheduled job.
create or replace function public.escalate_requests()
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare r record; n int := 0;
begin
  for r in
    select q.*, t.label, t.escalate_to, t.escalate_days from public.requests q join public.request_types t on t.key = q.type
     where q.status = 'pending' and q.escalated_at is null and t.escalate_days > 0
       and q.updated_at < now() - make_interval(days => t.escalate_days)
       and (q.type <> 'swap' or q.partner_ok is true)
  loop
    update public.requests set escalated_at = now() where id = r.id;
    insert into public.request_events (request_id, type, comment) values (r.id, 'escalated', 'Nobody acted within ' || r.escalate_days || ' days.');
    perform public.notify_many(array(select public.resolve_people(r.escalate_to, r.requester)), 'request_escalated', r.label || ' request ' || public.request_ref(r.id) || ' is waiting', 'Nobody has acted on it for ' || r.escalate_days || ' days.', '/requests/' || r.id);
    n := n + 1;
  end loop;
  return n;
end;
$$;

revoke execute on function public.resolve_people(text[], uuid), public.request_approvers(uuid), public.can_act_on_request(uuid), public.request_ref(uuid),
  public.notify_many(uuid[], text, text, text, text), public.submit_request(text, text, jsonb, date, date, uuid), public.apply_request(uuid),
  public.request_action(uuid, text, text), public.escalate_requests() from public, anon;
grant execute on function public.can_act_on_request(uuid), public.request_ref(uuid), public.submit_request(text, text, jsonb, date, date, uuid),
  public.request_action(uuid, text, text), public.request_approvers(uuid) to authenticated;
grant execute on function public.escalate_requests() to service_role;
commit;
