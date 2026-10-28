-- Staff Portal · © cmeproject. All rights reserved.
--
-- Onboarding and Compliance.
--   Everyone has "My onboarding": documents to read and confirm, trainings,
--   and documents to upload (with expiry dates). Staff admins look after
--   them in "Compliance" (the system admin can let other roles do it too).
--   Managers and team leaders see progress only, never the files.
--   A new starter gets a role once onboarding is finished, or earlier as a
--   conditional role: a reason, what's missing and a deadline, approved by a
--   manager. The person then gets a "Finish onboarding" task due that day.
-- Also: notifications for the bell (and email where it matters), who can
-- send invites, and staff admins hearing when someone joins.

-- ---------------------------------------------------------------------------
-- Settings
-- ---------------------------------------------------------------------------

insert into public.app_settings (key, value, label, description, is_public) values
  ('people.invite_roles', '["staff_admin", "manager"]', 'Who can send invites',
   'Besides the system admin. People they invite join as new starters.', false),
  ('compliance.manager_roles', '["staff_admin"]', 'Who manages Compliance',
   'Besides the system admin: who adds documents, trainings and uploads, and checks what people upload.', false),
  ('compliance.expiry_warning_days', '30', 'Expiry reminder (days before)',
   'Remind people (in the bell) this many days before an uploaded document expires.', false)
on conflict (key) do nothing;

create function public.setting_roles(p_key text)
returns public.app_role[]
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select array_agg(x::public.app_role)
                     from public.app_settings s, jsonb_array_elements_text(s.value) x
                    where s.key = p_key and jsonb_typeof(s.value) = 'array'), '{}')
$$;

create function public.can_invite()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.mfa_ok() and (public.my_role() = 'system_admin'
         or public.my_role() = any (public.setting_roles('people.invite_roles')))
$$;

create function public.can_manage_compliance()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.mfa_ok() and (public.my_role() = 'system_admin'
         or public.my_role() = any (public.setting_roles('compliance.manager_roles')))
$$;

create function public.local_today()
returns date
language sql
stable
security definer
set search_path = ''
as $$
  select (now() at time zone coalesce((select value #>> '{}' from public.app_settings where key = 'region.timezone'),
                                      'Australia/Melbourne'))::date
$$;

-- ---------------------------------------------------------------------------
-- Notifications (the bell), with an email when it matters
-- ---------------------------------------------------------------------------

create table public.notifications (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  kind       text not null,
  title      text not null,
  body       text not null default '',
  href       text not null default '/' check (href like '/%'),
  created_at timestamptz not null default now(),
  seen_at    timestamptz
);

create index notifications_user_idx on public.notifications (user_id, created_at desc) where seen_at is null;

alter table public.notifications enable row level security;
create policy "read your own notifications" on public.notifications
  for select to authenticated using (user_id = auth.uid());
revoke insert, update, delete, truncate on public.notifications from anon, authenticated;

create function public.notify(p_user uuid, p_kind text, p_title text, p_body text, p_href text, p_email boolean default false)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_user is null or not exists (select 1 from public.profiles where id = p_user and active) then
    return;
  end if;
  insert into public.notifications (user_id, kind, title, body, href)
  values (p_user, p_kind, p_title, coalesce(p_body, ''), coalesce(p_href, '/'));
  if p_email and public.feature_enabled('email_notifications') then
    insert into public.email_outbox (to_user, template, data)
    values (p_user, 'notice', jsonb_build_object('title', p_title, 'body', coalesce(p_body, ''), 'href', coalesce(p_href, '/')));
  end if;
end;
$$;

create function public.mark_notification_seen(p_id bigint)
returns text
language sql
security definer
set search_path = ''
as $$
  update public.notifications set seen_at = coalesce(seen_at, now())
   where id = p_id and user_id = auth.uid()
  returning href
$$;

create function public.mark_all_notifications_seen()
returns void
language sql
security definer
set search_path = ''
as $$
  update public.notifications set seen_at = now() where user_id = auth.uid() and seen_at is null
$$;

-- Staff admins (and whoever manages Compliance) hear about people things.
create function public.people_admins()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select id from public.profiles
   where active and (role = 'staff_admin' or role = any (public.setting_roles('compliance.manager_roles')))
     and role <> 'system_admin'
$$;

-- ---------------------------------------------------------------------------
-- Joining and onboarding dates
-- ---------------------------------------------------------------------------

alter table public.profiles add column joined_at timestamptz, add column onboarded_at timestamptz;
update public.profiles set joined_at = created_at;

-- Called when someone finishes setting up their account from the invite.
create function public.mark_joined()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  me public.profiles;
  v_admin uuid;
  v_inviter uuid;
begin
  select * into me from public.profiles where id = auth.uid();
  if me.id is null or me.joined_at is not null then
    return;
  end if;
  update public.profiles set joined_at = now() where id = me.id;
  select invited_by into v_inviter from public.invitations where user_id = me.id order by created_at desc limit 1;
  for v_admin in select a from public.people_admins() a union select v_inviter where v_inviter is not null loop
    continue when v_admin = me.id;
    perform public.notify(v_admin, 'joined',
      format('%s has joined', coalesce(nullif(me.full_name, ''), me.email)),
      'They''ve created their account. Set their role and team once onboarding is done.',
      '/settings/staff', true);
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- What people read, complete and upload
-- ---------------------------------------------------------------------------

create table public.compliance_items (
  id            uuid primary key default gen_random_uuid(),
  org_id        uuid not null default public.default_org_id() references public.organisation (id),
  kind          text not null check (kind in ('read', 'training', 'upload')),
  title         text not null check (length(trim(title)) between 1 and 200),
  description   text not null default '',
  body          text not null default '',
  link_url      text not null default '' check (link_url = '' or link_url ~* '^https?://'),
  file_path     text,
  file_name     text,
  version       int not null default 1,
  needs_expiry  boolean not null default false,
  active        boolean not null default true,
  applies_roles public.app_role[] not null default '{}',
  applies_teams uuid[] not null default '{}',
  sort_order    int not null default 0,
  created_by    uuid references public.profiles (id) default auth.uid(),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create table public.compliance_records (
  id          bigint generated always as identity primary key,
  item_id     uuid not null references public.compliance_items (id) on delete cascade,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  version     int not null,
  status      text not null check (status in ('done', 'submitted', 'accepted', 'rejected')),
  file_path   text,
  file_name   text,
  expires_on  date,
  review_note text not null default '',
  reviewed_by uuid references public.profiles (id),
  reviewed_at timestamptz,
  created_at  timestamptz not null default now()
);

create index compliance_records_user_idx on public.compliance_records (user_id, item_id, created_at desc);

-- Expiry reminders already sent.
create table public.compliance_alerts (
  record_id bigint not null references public.compliance_records (id) on delete cascade,
  step      text not null check (step in ('expiring', 'expired')),
  primary key (record_id, step)
);

alter table public.compliance_items enable row level security;
alter table public.compliance_records enable row level security;
alter table public.compliance_alerts enable row level security;

create policy "members read onboarding items" on public.compliance_items
  for select to authenticated using (public.is_member());
create policy "compliance managers add items" on public.compliance_items
  for insert to authenticated with check (public.can_manage_compliance());
create policy "compliance managers change items" on public.compliance_items
  for update to authenticated using (public.can_manage_compliance()) with check (public.can_manage_compliance());
-- Items are switched off, never deleted, so the history stays.
revoke delete, truncate on public.compliance_items from anon, authenticated;

create policy "read your own records, or as compliance manager" on public.compliance_records
  for select to authenticated using (user_id = auth.uid() or public.can_manage_compliance());
revoke insert, update, delete, truncate on public.compliance_records from anon, authenticated;
revoke all on public.compliance_alerts from anon, authenticated;

create function public.compliance_items_touch()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger compliance_items_touch
  before update on public.compliance_items
  for each row execute function public.compliance_items_touch();

-- Does an item apply to someone with this role and these teams?
create function public.compliance_applies(p_item public.compliance_items, p_role public.app_role, p_teams uuid[])
returns boolean
language sql
stable
set search_path = ''
as $$
  select p_item.active
     and (cardinality(p_item.applies_roles) = 0 or p_role = any (p_item.applies_roles))
     and (cardinality(p_item.applies_teams) = 0 or p_item.applies_teams && coalesce(p_teams, '{}'))
$$;

-- Each item's state for one person (optionally as if they had another role
-- and teams). States: done, submitted, accepted, expiring (all count as done);
-- todo, update (a newer version to confirm), rejected, expired.
create function public.compliance_status(p_user uuid, p_role public.app_role default null, p_teams uuid[] default null)
returns table (item_id uuid, kind text, title text, state text, record_id bigint, expires_on date, note text, sort_order int)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_role public.app_role;
  v_teams uuid[];
  v_warn int := coalesce((select (value #>> '{}')::int from public.app_settings where key = 'compliance.expiry_warning_days'), 30);
  v_today date := public.local_today();
begin
  if not (p_user = auth.uid() or public.can_manage_compliance() or public.can_manage_people()
          or public.has_role(array['manager']::public.app_role[]) or public.leads_user(p_user)
          or auth.uid() is null) then
    return;
  end if;
  select coalesce(p_role, p.role) into v_role from public.profiles p where p.id = p_user;
  v_teams := coalesce(p_teams, (select array_agg(team_id) from public.team_members where user_id = p_user), '{}');

  return query
  select i.id, i.kind, i.title,
         case
           when r.id is null then 'todo'
           when i.kind <> 'upload' then case when r.version >= i.version then 'done' else 'update' end
           when r.status = 'rejected' then 'rejected'
           when r.expires_on is not null and r.expires_on < v_today then 'expired'
           when r.expires_on is not null and r.expires_on <= v_today + v_warn then 'expiring'
           else r.status
         end,
         r.id, r.expires_on, coalesce(r.review_note, ''), i.sort_order
    from public.compliance_items i
    left join lateral (
      select * from public.compliance_records cr
       where cr.item_id = i.id and cr.user_id = p_user
       order by cr.created_at desc, cr.id desc limit 1
    ) r on true
   where public.compliance_applies(i, v_role, v_teams)
   order by array_position(array['read', 'training', 'upload'], i.kind), i.sort_order, i.title;
end;
$$;

-- What's still missing (titles), for a role someone might be given.
create function public.onboarding_missing(p_user uuid, p_role public.app_role default null, p_teams uuid[] default null)
returns text[]
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(array_agg(s.title order by array_position(array['read', 'training', 'upload'], s.kind), s.sort_order, s.title), '{}')
    from public.compliance_status(p_user, p_role, p_teams) s
   where s.state not in ('done', 'submitted', 'accepted', 'expiring')
$$;

-- When everything is done: note it, tell the staff admins, and finish the
-- "Finish onboarding" task if there is one.
create function public.check_onboarding_complete(p_user uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  me public.profiles;
  v_admin uuid;
  v_task uuid;
begin
  select * into me from public.profiles where id = p_user;
  if me.id is null or cardinality(public.onboarding_missing(p_user)) > 0 then
    return;
  end if;
  if me.onboarded_at is null then
    update public.profiles set onboarded_at = now() where id = p_user;
    for v_admin in select a from public.people_admins() a loop
      perform public.notify(v_admin, 'onboarded',
        format('%s has finished onboarding', coalesce(nullif(me.full_name, ''), me.email)),
        case when me.role = 'new_starter' then 'You can now give them their role and team.' else '' end,
        '/compliance?tab=progress');
    end loop;
  end if;
  for v_task in
    select r.task_id from public.people_change_requests r
      join public.tasks t on t.id = r.task_id
     where r.user_id = p_user and r.kind = 'conditional' and t.status not in ('completed', 'closed')
  loop
    update public.tasks set status = 'completed', completed_at = now(), updated_at = now() where id = v_task;
    insert into public.task_events (task_id, actor_id, type, from_value, to_value, comment)
    values (v_task, null, 'status_changed', null, 'completed', 'Onboarding finished');
  end loop;
end;
$$;

create function public.confirm_compliance_item(p_item_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  i public.compliance_items;
begin
  if not public.is_member() then
    raise exception 'Please sign in again';
  end if;
  select * into i from public.compliance_items where id = p_item_id and active;
  if i.id is null or i.kind = 'upload' then
    raise exception 'Choose something to read or a training';
  end if;
  insert into public.compliance_records (item_id, user_id, version, status)
  values (i.id, auth.uid(), i.version, 'done');
  perform public.check_onboarding_complete(auth.uid());
end;
$$;

create function public.submit_compliance_upload(p_item_id uuid, p_path text, p_name text, p_expires date default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  i public.compliance_items;
  me public.profiles;
  v_admin uuid;
begin
  if not public.is_member() then
    raise exception 'Please sign in again';
  end if;
  select * into i from public.compliance_items where id = p_item_id and active and kind = 'upload';
  if i.id is null then
    raise exception 'Uploads for this document are switched off';
  end if;
  if p_path is null or p_path not like auth.uid()::text || '/%' then
    raise exception 'Upload the file again';
  end if;
  if i.needs_expiry and p_expires is null then
    raise exception 'Enter the expiry date';
  end if;
  if p_expires is not null and p_expires < public.local_today() then
    raise exception 'This document has already expired. Upload a current one.';
  end if;
  insert into public.compliance_records (item_id, user_id, version, status, file_path, file_name, expires_on)
  values (i.id, auth.uid(), i.version, 'submitted', p_path, left(coalesce(p_name, ''), 200), p_expires);

  select * into me from public.profiles where id = auth.uid();
  for v_admin in select a from public.people_admins() a loop
    continue when v_admin = auth.uid();
    perform public.notify(v_admin, 'upload_submitted',
      format('%s uploaded %s', coalesce(nullif(me.full_name, ''), me.email), i.title),
      'Check it on the Compliance page.', '/compliance/people/' || auth.uid());
  end loop;
  perform public.check_onboarding_complete(auth.uid());
end;
$$;

create function public.review_compliance_upload(p_record_id bigint, p_accept boolean, p_note text default '')
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.compliance_records;
  v_title text;
begin
  if not public.can_manage_compliance() then
    raise exception 'Only people who manage Compliance can check uploads';
  end if;
  select * into r from public.compliance_records where id = p_record_id for update;
  if r.id is null or r.status not in ('submitted', 'accepted', 'rejected') then
    raise exception 'Upload not found';
  end if;
  if r.user_id = auth.uid() then
    raise exception 'Someone else needs to check your own documents';
  end if;
  if not p_accept and coalesce(trim(p_note), '') = '' then
    raise exception 'Say what''s wrong, so they know what to upload';
  end if;
  update public.compliance_records
     set status = case when p_accept then 'accepted' else 'rejected' end,
         review_note = coalesce(trim(p_note), ''), reviewed_by = auth.uid(), reviewed_at = now()
   where id = r.id;
  select title into v_title from public.compliance_items where id = r.item_id;
  if not p_accept then
    perform public.notify(r.user_id, 'upload_rejected', format('Please upload %s again', v_title),
      trim(p_note), '/onboarding', true);
  end if;
  perform public.write_audit(case when p_accept then 'upload_accepted' else 'upload_rejected' end,
    'compliance_record', r.id::text, jsonb_build_object('item', v_title, 'note', p_note));
end;
$$;

-- New items (or a new version to confirm) go to everyone they apply to.
create function public.compliance_item_announce()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  p record;
  v_word text := case new.kind when 'read' then 'Please read and confirm' when 'training' then 'New training' else 'Please upload' end;
begin
  if not new.active then
    return new;
  end if;
  if tg_op = 'UPDATE' and new.version = old.version and old.active then
    return new;
  end if;
  for p in
    select pr.id, pr.role, (select array_agg(team_id) from public.team_members where user_id = pr.id) teams
      from public.profiles pr
     where pr.active and pr.role <> 'system_admin'
  loop
    if public.compliance_applies(new, p.role, p.teams) then
      perform public.notify(p.id, 'onboarding_item',
        case when tg_op = 'UPDATE' and new.version > old.version then format('Updated: %s', new.title) else format('%s: %s', v_word, new.title) end,
        'It''s on your My onboarding page.', '/onboarding');
    end if;
  end loop;
  return new;
end;
$$;

create trigger compliance_items_announce
  after insert or update on public.compliance_items
  for each row execute function public.compliance_item_announce();

-- Expiring and expired documents (called by the hourly timer).
create function public.run_compliance_alerts()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  s record;
  v_n int := 0;
  v_admin uuid;
  v_name text;
begin
  for s in
    select p.id user_id, coalesce(nullif(p.full_name, ''), p.email) person, st.title, st.state, st.record_id, st.expires_on
      from public.profiles p
      cross join lateral public.compliance_status(p.id) st
     where p.active and p.role <> 'system_admin' and st.state in ('expiring', 'expired') and st.record_id is not null
  loop
    insert into public.compliance_alerts (record_id, step) values (s.record_id, s.state) on conflict do nothing;
    continue when not found;
    v_n := v_n + 1;
    -- Bell before it expires; bell and email once it has.
    perform public.notify(s.user_id, 'document_' || s.state,
      case when s.state = 'expired' then format('%s has expired', s.title) else format('%s expires soon', s.title) end,
      format('Expiry date: %s. Upload a new one on My onboarding.', to_char(s.expires_on, 'FMDD Mon YYYY')),
      '/onboarding', s.state = 'expired');
    for v_admin in select a from public.people_admins() a loop
      continue when v_admin = s.user_id;
      perform public.notify(v_admin, 'document_' || s.state,
        format('%s: %s %s', s.person, s.title, case when s.state = 'expired' then 'has expired' else 'expires soon' end),
        format('Expiry date: %s.', to_char(s.expires_on, 'FMDD Mon YYYY')),
        '/compliance/people/' || s.user_id, s.state = 'expired');
    end loop;
  end loop;
  return jsonb_build_object('document_alerts', v_n);
end;
$$;

-- ---------------------------------------------------------------------------
-- Conditional roles
-- ---------------------------------------------------------------------------

alter table public.people_change_requests add column task_id uuid references public.tasks (id);
alter table public.people_change_requests drop constraint people_change_requests_kind_check;
alter table public.people_change_requests drop constraint people_change_requests_target_check;
alter table public.people_change_requests
  add constraint people_change_requests_kind_check check (kind in ('role', 'team', 'conditional')),
  add constraint people_change_requests_target_check check (
    (kind in ('role', 'conditional') and user_id is not null) or (kind = 'team' and team_id is not null));

-- Gives the role and teams and sets the "Finish onboarding" task (as the
-- approving manager).
create function public.apply_conditional_role(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.people_change_requests;
  v_team uuid;
  v_task uuid;
  v_missing text;
begin
  select * into r from public.people_change_requests where id = p_request_id;
  if (select role from public.profiles where id = r.user_id) <> 'new_starter' then
    raise exception 'They already have a role';
  end if;
  perform set_config('app.conditional_role', 'on', true);
  if r.to_value ->> 'title' is not null then
    update public.profiles set job_title_id = (r.to_value ->> 'title')::uuid where id = r.user_id;
  else
    update public.profiles set role = (r.to_value ->> 'role')::public.app_role where id = r.user_id;
  end if;
  perform set_config('app.conditional_role', 'off', true);

  if (r.to_value ->> 'role') in ('support_worker', 'team_leader') then
    for v_team in select x::uuid from jsonb_array_elements_text(coalesce(r.to_value -> 'teams', '[]')) x loop
      insert into public.team_members (team_id, user_id) values (v_team, r.user_id) on conflict do nothing;
    end loop;
  end if;

  select string_agg('• ' || x, E'\n') into v_missing from jsonb_array_elements_text(r.to_value -> 'missing') x;
  v_task := public.create_task(
    'Finish onboarding',
    (select id from public.registries where is_default and kind = 'tasks' and active order by sort_order limit 1),
    r.user_id,
    format(E'Your role was given on condition that you finish onboarding by %s.\n\nStill to do:\n%s\n\nReason: %s',
           to_char((r.to_value ->> 'deadline')::date, 'FMDD Mon YYYY'), coalesce(v_missing, ''), r.reason),
    'medium',
    (r.to_value ->> 'deadline')::date);
  update public.people_change_requests set task_id = v_task where id = r.id;
end;
$$;

-- Managers give a conditional role straight away; staff admins ask a manager.
create function public.give_conditional_role(
  p_user_id uuid, p_role public.app_role, p_title_id uuid, p_teams uuid[], p_reason text, p_deadline date
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  me public.profiles;
  v_role public.app_role := p_role;
  v_teams uuid[] := coalesce(p_teams, '{}');
  v_missing text[];
  v_id uuid;
  v_name text;
  v_manager uuid;
  v_to jsonb;
begin
  select * into me from public.profiles where id = auth.uid();
  if not public.can_manage_people() then
    raise exception 'Only managers and staff admins give roles';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'You cannot change your own role';
  end if;
  if (select role from public.profiles where id = p_user_id and active) is distinct from 'new_starter' then
    raise exception 'Conditional roles are for new starters';
  end if;
  if p_title_id is not null then
    select access_level into v_role from public.job_titles where id = p_title_id and active;
    if v_role is null then raise exception 'Choose a role that is in use'; end if;
  end if;
  if v_role in ('new_starter', 'system_admin') or not public.can_manage_role(v_role) then
    raise exception 'Choose a role you''re allowed to give';
  end if;
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'Give a reason for the conditional role';
  end if;
  if p_deadline is null or p_deadline < public.local_today() or p_deadline > public.local_today() + 180 then
    raise exception 'Choose a deadline in the next six months';
  end if;
  if v_role not in ('support_worker', 'team_leader') then
    v_teams := '{}';
  elsif v_role = 'team_leader' and cardinality(v_teams) > 1 then
    raise exception 'A team leader can be in one team only';
  end if;
  if exists (select 1 from unnest(v_teams) t where not exists (select 1 from public.teams where id = t and active and not is_core)) then
    raise exception 'Choose teams that are in use';
  end if;

  v_missing := public.onboarding_missing(p_user_id, v_role, v_teams);
  if cardinality(v_missing) = 0 then
    raise exception 'Their onboarding is finished, so give the role in the usual way';
  end if;

  v_to := jsonb_build_object('role', v_role, 'title', p_title_id, 'teams', to_jsonb(v_teams),
                             'deadline', p_deadline, 'missing', to_jsonb(v_missing));

  if me.role in ('manager', 'system_admin') then
    insert into public.people_change_requests (kind, user_id, from_value, to_value, reason, requested_by,
                                               status, decided_by, decided_at, requester_seen_at)
    values ('conditional', p_user_id, jsonb_build_object('role', 'new_starter'), v_to, trim(p_reason), auth.uid(),
            'approved', auth.uid(), now(), now())
    returning id into v_id;
    perform public.apply_conditional_role(v_id);
    perform public.write_audit('conditional_role_given', 'profile', p_user_id::text, v_to);
    return v_id;
  end if;

  v_id := public.add_change_request('conditional', p_user_id, null, jsonb_build_object('role', 'new_starter'), v_to, p_reason);
  select coalesce(nullif(full_name, ''), email) into v_name from public.profiles where id = p_user_id;
  for v_manager in select id from public.profiles where active and role = 'manager' loop
    perform public.notify(v_manager, 'approval_needed',
      format('Conditional role for %s needs your approval', v_name),
      format('%s asks to give them a role before onboarding is finished (deadline %s).',
             coalesce(nullif(me.full_name, ''), me.email), to_char(p_deadline, 'FMDD Mon YYYY')),
      '/settings/staff', true);
  end loop;
  return v_id;
end;
$$;

revoke execute on function public.notify(uuid, text, text, text, text, boolean) from public, anon, authenticated;
revoke execute on function public.people_admins() from public, anon, authenticated;
revoke execute on function public.check_onboarding_complete(uuid) from public, anon, authenticated;
revoke execute on function public.apply_conditional_role(uuid) from public, anon, authenticated;
revoke execute on function public.run_compliance_alerts() from public, anon, authenticated;
grant execute on function public.run_compliance_alerts() to service_role;
revoke execute on function public.mark_joined() from public, anon;
revoke execute on function public.confirm_compliance_item(uuid) from public, anon;
revoke execute on function public.submit_compliance_upload(uuid, text, text, date) from public, anon;
revoke execute on function public.review_compliance_upload(bigint, boolean, text) from public, anon;
revoke execute on function public.give_conditional_role(uuid, public.app_role, uuid, uuid[], text, date) from public, anon;
revoke execute on function public.compliance_status(uuid, public.app_role, uuid[]) from public, anon;
revoke execute on function public.onboarding_missing(uuid, public.app_role, uuid[]) from public, anon;
revoke execute on function public.mark_notification_seen(bigint) from public, anon;
revoke execute on function public.mark_all_notifications_seen() from public, anon;

-- ---------------------------------------------------------------------------
-- Existing rules, updated
-- ---------------------------------------------------------------------------

create or replace function public.guard_profile_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor uuid := auth.uid();
begin
  if new.id <> old.id or new.email <> old.email or new.org_id <> old.org_id then
    raise exception 'This field cannot be changed here';
  end if;

  if actor is not null then
    if new.role is distinct from old.role
       or new.team_id is distinct from old.team_id
       or new.active is distinct from old.active then

      if not public.can_manage_people() then
        raise exception 'Only managers and admins can change roles, teams or access';
      end if;

      -- Nobody promotes, demotes or deactivates themselves.
      if new.id = actor and (new.role is distinct from old.role or not new.active) then
        raise exception 'You cannot change your own role or deactivate yourself';
      end if;

      if new.id <> actor and (not public.can_manage_role(old.role) or not public.can_manage_role(new.role)) then
        raise exception 'Only a system admin can manage system admins';
      end if;

      -- A new starter gets a role once onboarding is finished (or as a
      -- conditional role, which sets app.conditional_role while it applies).
      if old.role = 'new_starter' and new.role <> 'new_starter'
         and coalesce(current_setting('app.conditional_role', true), '') <> 'on'
         and cardinality(public.onboarding_missing(new.id, new.role, null)) > 0 then
        raise exception 'They haven''t finished onboarding yet. Give a conditional role with a deadline instead.';
      end if;

      -- A staff admin's role changes need a manager's approval first.
      -- (Managers apply approved requests as themselves, so this never blocks them.)
      -- A new starter's first role is the exception: staff admins set it straight away.
      if new.role is distinct from old.role and public.my_role() = 'staff_admin'
         and public.rule_on('people.staff_admin_role_approval')
         and (old.role <> 'new_starter' or public.rule_on('people.first_role_approval')) then
        raise exception 'Role changes by a staff admin need a manager''s approval. Send it as a request.';
      end if;
      if new.team_id is distinct from old.team_id and public.my_role() = 'staff_admin'
         and public.rule_on('people.staff_admin_team_approval') then
        raise exception 'Team changes by a staff admin need a manager''s approval. Send it as a request.';
      end if;
    end if;
  end if;

  if old.role = 'system_admin' and old.active
     and (new.role <> 'system_admin' or not new.active)
     and not exists (
       select 1 from public.profiles
        where role = 'system_admin' and active and id <> old.id
     ) then
    raise exception 'There must always be at least one active system admin';
  end if;

  if new.active and not old.active then
    new.deactivated_at := null;
  elsif not new.active and old.active then
    new.deactivated_at := now();
  end if;

  if new.role is distinct from old.role then
    perform public.write_audit('role_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.role, 'to', new.role));
  end if;
  if new.active is distinct from old.active then
    perform public.write_audit(
      case when new.active then 'reactivated' else 'deactivated' end,
      'profile', new.id::text, '{}'::jsonb);
  end if;
  if new.team_id is distinct from old.team_id then
    perform public.write_audit('team_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.team_id, 'to', new.team_id));
  end if;

  return new;
end;
$$;

create or replace function public.guard_invitation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.can_invite() then
    raise exception 'You''re not set up to send invites. Ask a staff admin.';
  end if;
  -- People who can invite but don't manage staff send general invites only.
  if auth.uid() is not null and not public.can_manage_people() and (new.role <> 'new_starter' or new.team_id is not null) then
    raise exception 'Invite them as a new starter; a staff admin sets their role later';
  end if;
  if auth.uid() is not null and public.can_manage_people() and not public.can_manage_role(new.role) then
    raise exception 'Only a system admin can invite a system admin';
  end if;
  if auth.uid() is not null and public.rule_on('people.general_invites_only')
     and new.role <> 'new_starter' and public.my_role() <> 'system_admin' then
    raise exception 'Invites are general: they join as a new starter and you set their role afterwards';
  end if;
  if auth.uid() is not null and new.team_id is not null and public.my_role() = 'staff_admin'
     and public.rule_on('people.staff_admin_team_approval') then
    raise exception 'Add them to a team once they''ve joined; a manager approves team changes';
  end if;
  new.email := lower(trim(new.email));
  if tg_op = 'INSERT' then
    new.invited_by := coalesce(new.invited_by, auth.uid());
    perform public.write_audit('invited', 'invitation', new.email,
      jsonb_build_object('role', new.role));
  end if;
  return new;
end;
$$;

create policy "inviters create general invitations" on public.invitations
  for insert to authenticated with check (public.can_invite());

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
    if r.kind = 'conditional' then
      perform public.apply_conditional_role(r.id);
    elsif r.kind = 'role' then
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

create or replace function public.my_request_updates()
returns table (
  request_id uuid,
  kind text,
  status text,
  subject text,
  change text,
  decided_by_name text,
  decided_at timestamptz,
  note text
)
language sql
stable
security definer
set search_path = ''
as $$
  select r.id,
         r.kind,
         r.status,
         case when r.kind = 'team' then coalesce(t.name, 'A team')
              else coalesce(nullif(p.full_name, ''), p.email, 'Someone') end,
         case when r.kind in ('role', 'conditional')
              then coalesce((select j.name from public.job_titles j where j.id = (r.to_value ->> 'title')::uuid),
                            initcap(replace(r.to_value ->> 'role', '_', ' ')))
              else 'who is in the team' end,
         -- System admins stay hidden from other staff.
         case when d.role = 'system_admin' then 'Admin' else coalesce(nullif(d.full_name, ''), d.email, 'A manager') end,
         r.decided_at,
         r.decision_note
    from public.people_change_requests r
    left join public.profiles p on p.id = r.user_id
    left join public.teams t on t.id = r.team_id
    left join public.profiles d on d.id = r.decided_by
   where public.is_member()
     and r.requested_by = auth.uid()
     and r.status in ('approved', 'declined')
     and r.requester_seen_at is null
   order by r.decided_at desc
$$;

-- ---------------------------------------------------------------------------
-- Files (only where Supabase Storage is available)
-- ---------------------------------------------------------------------------
-- compliance-files:   what people upload, in a folder named by their id.
--                     The person and Compliance managers can open them.
-- compliance-library: policy documents and training files, for all staff.

do $storage$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  insert into storage.buckets (id, name, public, file_size_limit)
  values ('compliance-files', 'compliance-files', false, 10485760),
         ('compliance-library', 'compliance-library', false, 26214400)
  on conflict (id) do nothing;

  create policy "people upload their own documents" on storage.objects
    for insert to authenticated
    with check (bucket_id = 'compliance-files' and (storage.foldername(name))[1] = auth.uid()::text and public.is_member());
  create policy "people and compliance managers read documents" on storage.objects
    for select to authenticated
    using (bucket_id = 'compliance-files'
           and ((storage.foldername(name))[1] = auth.uid()::text or public.can_manage_compliance()));
  create policy "staff read the library" on storage.objects
    for select to authenticated using (bucket_id = 'compliance-library' and public.is_member());
  create policy "compliance managers add to the library" on storage.objects
    for insert to authenticated with check (bucket_id = 'compliance-library' and public.can_manage_compliance());
end;
$storage$;
