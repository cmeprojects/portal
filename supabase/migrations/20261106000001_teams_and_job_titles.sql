-- Staff Portal · © cmeproject. All rights reserved.
--
-- Teams:
--   support workers can be in several teams
--   team leaders belong to (and lead) one team only
--   managers and staff admins are the Core / Management team: managers see
--   every team's tasks; staff admins (HR) manage people but not task content
-- Job titles ("roles" in the portal): managers add titles like "Nurse" or
-- "House Coordinator", each linked to an access level that decides what the
-- person can see and do.

-- ---------------------------------------------------------------------------
-- Job titles
-- ---------------------------------------------------------------------------

create table public.job_titles (
  id           uuid primary key default gen_random_uuid(),
  org_id       uuid not null default public.default_org_id() references public.organisation (id),
  name         text not null check (length(trim(name)) between 1 and 80),
  access_level public.app_role not null check (access_level <> 'system_admin'),
  description  text not null default '',
  active       boolean not null default true,
  sort_order   int not null default 0,
  created_at   timestamptz not null default now()
);

create unique index job_titles_name_unique on public.job_titles (lower(name));

alter table public.profiles add column job_title_id uuid references public.job_titles (id);
alter table public.invitations add column job_title_id uuid references public.job_titles (id);

alter table public.job_titles enable row level security;
create policy "members read job titles" on public.job_titles
  for select to authenticated using (public.is_member());
create policy "managers add job titles" on public.job_titles
  for insert to authenticated with check (public.has_role(array['manager', 'system_admin']::public.app_role[]));
create policy "managers change job titles" on public.job_titles
  for update to authenticated
  using (public.has_role(array['manager', 'system_admin']::public.app_role[]))
  with check (public.has_role(array['manager', 'system_admin']::public.app_role[]));
revoke delete on public.job_titles from anon, authenticated;

-- A title's access level can't change while people have it (move them first).
create function public.guard_job_title()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.access_level <> old.access_level
     and exists (select 1 from public.profiles where job_title_id = old.id) then
    raise exception 'People have this role, so its access level can''t change. Give them another role first.';
  end if;
  if new.access_level <> old.access_level or new.name <> old.name or new.active <> old.active then
    perform public.write_audit('job_title_changed', 'job_title', new.id::text,
      jsonb_build_object('name', new.name, 'access_level', new.access_level, 'active', new.active));
  end if;
  return new;
end;
$$;

create trigger job_titles_guard
  before update on public.job_titles
  for each row execute function public.guard_job_title();

-- A person's access level always matches their job title. Runs before the
-- people guard (triggers run in name order), so the usual permission checks
-- apply to the resulting role change.
create function public.sync_title_and_role()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_level public.app_role;
begin
  if new.job_title_id is distinct from old.job_title_id and new.job_title_id is not null then
    select access_level into v_level from public.job_titles where id = new.job_title_id and active;
    if v_level is null then
      raise exception 'Choose a role that is in use';
    end if;
    new.role := v_level;
  elsif new.role is distinct from old.role and new.job_title_id is not null
        and (select access_level from public.job_titles where id = new.job_title_id) is distinct from new.role then
    -- A plain access-level change clears a title that no longer fits.
    new.job_title_id := null;
  end if;
  return new;
end;
$$;

create trigger profiles_a_sync_title
  before update on public.profiles
  for each row execute function public.sync_title_and_role();

-- ---------------------------------------------------------------------------
-- Teams
-- ---------------------------------------------------------------------------

alter table public.teams add column is_core boolean not null default false;
create unique index teams_one_core on public.teams ((true)) where is_core;
insert into public.teams (name, is_core) values ('Management (core team)', true)
on conflict do nothing;

create table public.team_members (
  team_id  uuid not null references public.teams (id) on delete cascade,
  user_id  uuid not null references public.profiles (id) on delete cascade,
  added_at timestamptz not null default now(),
  primary key (team_id, user_id)
);

create index team_members_user_idx on public.team_members (user_id);

-- Bring across the old one-team-per-person data.
insert into public.team_members (team_id, user_id)
select p.team_id, p.id from public.profiles p
  join public.teams t on t.id = p.team_id and not t.is_core
 where p.team_id is not null and p.role in ('support_worker', 'team_leader')
on conflict do nothing;
update public.profiles set team_id = null where team_id is not null;

-- Only team leaders lead teams, and each leads one (their earliest).
delete from public.team_leaders tl
 using public.profiles p
 where p.id = tl.user_id and p.role <> 'team_leader';
delete from public.team_leaders tl
 where exists (select 1 from public.team_leaders o
                where o.user_id = tl.user_id and o.team_id::text < tl.team_id::text);
delete from public.team_members m
 using public.profiles p
 where p.id = m.user_id and p.role = 'team_leader'
   and not exists (select 1 from public.team_leaders tl where tl.user_id = m.user_id and tl.team_id = m.team_id)
   and exists (select 1 from public.team_leaders tl where tl.user_id = m.user_id);
insert into public.team_members (team_id, user_id)
select team_id, user_id from public.team_leaders on conflict do nothing;

-- A team leader leads one team.
create unique index team_leaders_one_team on public.team_leaders (user_id);

-- Who can be in a team, and the one-team rule for team leaders.
create function public.guard_team_member()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_role public.app_role;
begin
  select role into v_role from public.profiles where id = new.user_id;
  if (select is_core from public.teams where id = new.team_id) then
    raise exception 'The core team is managers and staff admins, automatically';
  end if;
  if v_role not in ('support_worker', 'team_leader') then
    raise exception 'Managers and staff admins are in the core team, which works across every team';
  end if;
  if v_role = 'team_leader' and exists (
       select 1 from public.team_members where user_id = new.user_id and team_id <> new.team_id) then
    raise exception 'A team leader can be in one team only';
  end if;
  return new;
end;
$$;

create trigger team_members_guard
  before insert on public.team_members
  for each row execute function public.guard_team_member();

create function public.guard_team_leader()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select role from public.profiles where id = new.user_id) <> 'team_leader' then
    raise exception 'Only team leaders can lead a team';
  end if;
  if (select is_core from public.teams where id = new.team_id) then
    raise exception 'The core team has no team leader';
  end if;
  -- A leader is a member of the team they lead (and of no other).
  insert into public.team_members (team_id, user_id) values (new.team_id, new.user_id) on conflict do nothing;
  return new;
end;
$$;

create trigger team_leaders_guard
  before insert on public.team_leaders
  for each row execute function public.guard_team_leader();

-- When someone's role changes, tidy up their teams.
create function public.tidy_teams_after_role_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.role is distinct from old.role then
    if new.role not in ('support_worker', 'team_leader') then
      -- Managers and staff admins move to the core team.
      delete from public.team_leaders where user_id = new.id;
      delete from public.team_members where user_id = new.id;
    elsif new.role = 'support_worker' then
      delete from public.team_leaders where user_id = new.id;
    elsif new.role = 'team_leader'
          and (select count(*) from public.team_members where user_id = new.id) > 1 then
      raise exception 'A team leader can be in one team only. Take them out of the other teams first.';
    end if;
  end if;
  return new;
end;
$$;

create trigger profiles_tidy_teams
  after update of role on public.profiles
  for each row execute function public.tidy_teams_after_role_change();

alter table public.team_members enable row level security;
create policy "members read team members" on public.team_members
  for select to authenticated using (public.is_member());
create policy "managers change team members" on public.team_members
  for all to authenticated
  using (public.has_role(array['manager', 'system_admin']::public.app_role[]))
  with check (public.has_role(array['manager', 'system_admin']::public.app_role[]));

-- Set a team's members and leader in one go (managers; staff admins send a
-- request instead, which a manager approves).
create function public.set_team(p_team_id uuid, p_members uuid[], p_leader uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_members uuid[] := coalesce(p_members, '{}');
  v_old jsonb;
begin
  if not public.has_role(array['manager', 'system_admin']::public.app_role[]) then
    raise exception 'Only managers change who is in a team. Send it as a request.';
  end if;
  if (select is_core from public.teams where id = p_team_id) then
    raise exception 'The core team is managers and staff admins, automatically';
  end if;
  if p_leader is not null and not (p_leader = any (v_members)) then
    v_members := v_members || p_leader;
  end if;
  select jsonb_build_object(
           'members', coalesce((select jsonb_agg(user_id order by user_id) from public.team_members where team_id = p_team_id), '[]'),
           'leader', (select to_jsonb(user_id) from public.team_leaders where team_id = p_team_id limit 1))
    into v_old;

  delete from public.team_leaders where team_id = p_team_id and user_id is distinct from p_leader;
  delete from public.team_members where team_id = p_team_id and not (user_id = any (v_members));
  insert into public.team_members (team_id, user_id)
  select p_team_id, m from unnest(v_members) m on conflict do nothing;
  if p_leader is not null then
    insert into public.team_leaders (team_id, user_id) values (p_team_id, p_leader) on conflict do nothing;
  end if;

  perform public.write_audit('team_changed', 'team', p_team_id::text,
    jsonb_build_object('from', v_old, 'to', jsonb_build_object('members', to_jsonb(v_members), 'leader', p_leader)));
end;
$$;

revoke execute on function public.set_team(uuid, uuid[], uuid) from public, anon;
grant execute on function public.set_team(uuid, uuid[], uuid) to authenticated;

-- Team leaders lead the people in their team.
create or replace function public.leads_user(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.team_leaders tl
      join public.team_members m on m.team_id = tl.team_id
     where tl.user_id = auth.uid()
       and m.user_id = p_user_id
  ) and public.has_role(array['team_leader', 'manager', 'system_admin']::public.app_role[])
$$;

-- Managers see every team's tasks.
create or replace function public.can_see_task(p_task_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and (
    public.has_role(array['manager', 'system_admin']::public.app_role[])
    or exists (
      select 1
        from public.tasks t
       where t.id = p_task_id
         and (
           t.assigned_to = auth.uid()
           or t.created_by = auth.uid()
           or exists (select 1 from public.task_helpers h where h.task_id = t.id and h.user_id = auth.uid())
           or public.leads_user(t.assigned_to)
           or public.leads_user(t.created_by)
         )
    )
  )
$$;

-- New people join the team (and get the title) they were invited with.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  inv public.invitations;
  first_user boolean;
  v_role public.app_role;
begin
  select not exists (select 1 from public.profiles) into first_user;

  select * into inv
    from public.invitations i
   where lower(i.email) = lower(new.email)
     and i.accepted_at is null
   order by i.created_at desc
   limit 1;

  v_role := case
    when first_user then 'system_admin'::public.app_role
    else coalesce((select access_level from public.job_titles where id = inv.job_title_id),
                  inv.role, 'support_worker'::public.app_role)
  end;

  insert into public.profiles (id, email, full_name, role, job_title_id, active)
  values (
    new.id,
    new.email,
    coalesce(nullif(inv.full_name, ''), new.raw_user_meta_data ->> 'full_name', ''),
    v_role,
    case when first_user then null else inv.job_title_id end,
    -- Public sign-up is off, but as a second lock anyone who arrives
    -- without an invitation starts deactivated.
    first_user or inv.id is not null
  );

  if inv.team_id is not null and v_role in ('support_worker', 'team_leader') then
    insert into public.team_members (team_id, user_id) values (inv.team_id, new.id) on conflict do nothing;
  end if;

  if inv.id is not null then
    update public.invitations
       set accepted_at = now(), user_id = new.id
     where id = inv.id;
  end if;

  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Change requests: role (with title) and team membership
-- ---------------------------------------------------------------------------

drop function public.request_team_change(uuid, uuid, text);
drop function public.request_team_leaders(uuid, uuid[], text);
drop function public.request_role_change(uuid, public.app_role, text);

alter table public.people_change_requests drop constraint people_change_requests_check;
alter table public.people_change_requests drop constraint people_change_requests_kind_check;
alter table public.people_change_requests
  add constraint people_change_requests_kind_check check (kind in ('role', 'team')),
  add constraint people_change_requests_target_check check (
    (kind = 'role' and user_id is not null) or (kind = 'team' and team_id is not null));

-- p_to: an access level, or a job title (which brings its own access level).
create function public.request_role_change(p_user_id uuid, p_to_role public.app_role, p_title_id uuid default null, p_reason text default '')
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_from public.app_role;
  v_from_title uuid;
  v_to public.app_role := p_to_role;
begin
  if p_user_id = auth.uid() then
    raise exception 'You cannot change your own role';
  end if;
  select role, job_title_id into v_from, v_from_title from public.profiles where id = p_user_id and active;
  if v_from is null then
    raise exception 'Choose someone who can sign in';
  end if;
  if p_title_id is not null then
    select access_level into v_to from public.job_titles where id = p_title_id and active;
    if v_to is null then raise exception 'Choose a role that is in use'; end if;
  end if;
  if v_from = v_to and v_from_title is not distinct from p_title_id then
    raise exception 'They already have that role';
  end if;
  if not public.can_manage_role(v_from) or not public.can_manage_role(v_to) then
    raise exception 'Only a system admin can manage system admins';
  end if;
  return public.add_change_request('role', p_user_id, null,
    jsonb_build_object('role', v_from, 'title', v_from_title),
    jsonb_build_object('role', v_to, 'title', p_title_id), p_reason);
end;
$$;

create function public.request_team_change(p_team_id uuid, p_members uuid[], p_leader uuid, p_reason text default '')
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_from jsonb;
  v_to jsonb;
begin
  if not exists (select 1 from public.teams where id = p_team_id and not is_core) then
    raise exception 'Choose a team (the core team is set automatically)';
  end if;
  select jsonb_build_object(
           'members', coalesce((select jsonb_agg(user_id order by user_id) from public.team_members where team_id = p_team_id), '[]'),
           'leader', (select to_jsonb(user_id) from public.team_leaders where team_id = p_team_id limit 1))
    into v_from;
  v_to := jsonb_build_object(
    'members', coalesce((select jsonb_agg(distinct m order by m) from unnest(coalesce(p_members, '{}') || coalesce(array[p_leader], '{}')) m where m is not null), '[]'),
    'leader', to_jsonb(p_leader));
  if v_from = v_to then
    raise exception 'Nothing has changed';
  end if;
  return public.add_change_request('team', null, p_team_id, v_from, v_to, p_reason);
end;
$$;

create or replace function public.add_change_request(
  p_kind text, p_user_id uuid, p_team_id uuid, p_from jsonb, p_to jsonb, p_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
begin
  if not public.has_role(array['staff_admin']::public.app_role[]) then
    raise exception 'Only staff admins send change requests; managers make changes straight away';
  end if;
  -- A new request replaces an older one still waiting.
  update public.people_change_requests
     set status = 'withdrawn', decided_by = auth.uid(), decided_at = now()
   where kind = p_kind and coalesce(user_id, team_id) = coalesce(p_user_id, p_team_id) and status = 'pending';
  insert into public.people_change_requests (kind, user_id, team_id, from_value, to_value, reason, requested_by)
  values (p_kind, p_user_id, p_team_id, p_from, p_to, coalesce(trim(p_reason), ''), auth.uid())
  returning id into v_id;
  perform public.write_audit(p_kind || '_change_requested', case when p_kind = 'team' then 'team' else 'profile' end,
    coalesce(p_user_id, p_team_id)::text, jsonb_build_object('from', p_from, 'to', p_to));
  return v_id;
end;
$$;

create or replace function public.decide_change_request(p_request_id uuid, p_approve boolean, p_note text default '')
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.people_change_requests;
  v_members uuid[];
begin
  if not public.has_role(array['manager', 'system_admin']::public.app_role[]) then
    raise exception 'Only managers can approve these changes';
  end if;
  select * into r from public.people_change_requests where id = p_request_id for update;
  if r.id is null or r.status <> 'pending' then
    raise exception 'This request has already been dealt with';
  end if;
  if r.user_id = auth.uid() then
    raise exception 'You cannot approve a change about yourself';
  end if;

  -- Applied as the approving manager, so all the usual checks still run.
  if p_approve then
    if r.kind = 'role' then
      if (select role::text from public.profiles where id = r.user_id) <> r.from_value ->> 'role' then
        raise exception 'Their role has changed since the request was made. Ask for a new request.';
      end if;
      if r.to_value ->> 'title' is not null then
        update public.profiles set job_title_id = (r.to_value ->> 'title')::uuid where id = r.user_id;
      else
        update public.profiles set role = (r.to_value ->> 'role')::public.app_role, job_title_id = null where id = r.user_id;
      end if;
    else
      select coalesce(array_agg(x::uuid), '{}') into v_members from jsonb_array_elements_text(r.to_value -> 'members') x;
      perform public.set_team(r.team_id, v_members, (r.to_value ->> 'leader')::uuid);
    end if;
  end if;

  update public.people_change_requests
     set status = case when p_approve then 'approved' else 'declined' end,
         decided_by = auth.uid(), decided_at = now(), decision_note = coalesce(trim(p_note), '')
   where id = p_request_id;
  perform public.write_audit(r.kind || case when p_approve then '_change_approved' else '_change_declined' end,
    case when r.kind = 'team' then 'team' else 'profile' end, coalesce(r.user_id, r.team_id)::text,
    jsonb_build_object('from', r.from_value, 'to', r.to_value));
end;
$$;

revoke execute on function public.request_role_change(uuid, public.app_role, uuid, text) from public, anon;
revoke execute on function public.request_team_change(uuid, uuid[], uuid, text) from public, anon;
grant execute on function public.request_role_change(uuid, public.app_role, uuid, text) to authenticated;
grant execute on function public.request_team_change(uuid, uuid[], uuid, text) to authenticated;
