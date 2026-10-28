-- Staff Portal · © cmeproject. All rights reserved.
--
-- Who manages whom:
--   managers      invite any role except system admin, and change roles
--                 straight away (except system admins)
--   staff admins  (HR) invite any role except system admin and create teams;
--                 their role and team changes are requests a manager approves
--   system admins everything, and the only ones who create system admins
--   everyone      can't change their own role
-- Managers can also change the company's SLA (default due dates).

-- Can the signed-in person invite someone with this role, or manage someone
-- who has it (deactivate, change team)?
create or replace function public.can_manage_role(p_role public.app_role)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case public.my_role()
    when 'system_admin' then true
    when 'manager' then p_role <> 'system_admin'
    when 'staff_admin' then p_role <> 'system_admin'
    else false
  end and public.mfa_ok()
$$;

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

      -- A staff admin's role changes need a manager's approval first.
      -- (Managers apply approved requests as themselves, so this never blocks them.)
      if new.role is distinct from old.role and public.my_role() = 'staff_admin' then
        raise exception 'Role changes by a staff admin need a manager''s approval. Send it as a request.';
      end if;
      if new.team_id is distinct from old.team_id and public.my_role() = 'staff_admin' then
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
  if auth.uid() is not null and not public.can_manage_people() then
    raise exception 'Only managers and admins can invite people';
  end if;
  if auth.uid() is not null and not public.can_manage_role(new.role) then
    raise exception 'Only a system admin can invite a system admin';
  end if;
  if auth.uid() is not null and new.team_id is not null and public.my_role() = 'staff_admin' then
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

-- ---------------------------------------------------------------------------
-- Change requests from staff admins, approved by managers:
--   role     – change someone's role
--   team     – move someone into (or out of) a team
--   leaders  – change who leads a team
-- ---------------------------------------------------------------------------

create table public.people_change_requests (
  id            uuid primary key default gen_random_uuid(),
  kind          text not null check (kind in ('role', 'team', 'leaders')),
  user_id       uuid references public.profiles (id),
  team_id       uuid references public.teams (id) on delete cascade,
  from_value    jsonb,
  to_value      jsonb not null,
  reason        text not null default '',
  requested_by  uuid not null references public.profiles (id),
  requested_at  timestamptz not null default now(),
  status        text not null default 'pending' check (status in ('pending', 'approved', 'declined', 'withdrawn')),
  decided_by    uuid references public.profiles (id),
  decided_at    timestamptz,
  decision_note text not null default '',
  check ((kind in ('role', 'team') and user_id is not null) or (kind = 'leaders' and team_id is not null))
);

-- One request waiting per person (role, team) or per team (leaders).
create unique index people_change_requests_one_pending
  on public.people_change_requests (kind, coalesce(user_id, team_id)) where status = 'pending';

alter table public.people_change_requests enable row level security;
create policy "managers and admins see change requests" on public.people_change_requests
  for select to authenticated using (public.can_manage_people());
revoke insert, update, delete, truncate on public.people_change_requests from anon, authenticated;

-- Shared checks and bookkeeping for a new request.
create function public.add_change_request(
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
  perform public.write_audit(p_kind || '_change_requested', case when p_kind = 'leaders' then 'team' else 'profile' end,
    coalesce(p_user_id, p_team_id)::text, jsonb_build_object('from', p_from, 'to', p_to));
  return v_id;
end;
$$;

create function public.request_role_change(p_user_id uuid, p_to_role public.app_role, p_reason text default '')
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_from public.app_role;
begin
  if p_user_id = auth.uid() then
    raise exception 'You cannot change your own role';
  end if;
  select role into v_from from public.profiles where id = p_user_id and active;
  if v_from is null then
    raise exception 'Choose someone who can sign in';
  end if;
  if v_from = p_to_role then
    raise exception 'They already have that role';
  end if;
  if not public.can_manage_role(v_from) or not public.can_manage_role(p_to_role) then
    raise exception 'Only a system admin can manage system admins';
  end if;
  return public.add_change_request('role', p_user_id, null, to_jsonb(v_from), to_jsonb(p_to_role), p_reason);
end;
$$;

create function public.request_team_change(p_user_id uuid, p_team_id uuid, p_reason text default '')
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_from uuid;
  v_role public.app_role;
begin
  select team_id, role into v_from, v_role from public.profiles where id = p_user_id and active;
  if v_role is null then
    raise exception 'Choose someone who can sign in';
  end if;
  if not public.can_manage_role(v_role) then
    raise exception 'Only a system admin can manage system admins';
  end if;
  if v_from is not distinct from p_team_id then
    raise exception 'They are already in that team';
  end if;
  if p_team_id is not null and not exists (select 1 from public.teams where id = p_team_id and active) then
    raise exception 'Choose a team that is in use';
  end if;
  return public.add_change_request('team', p_user_id, null, to_jsonb(v_from), coalesce(to_jsonb(p_team_id), 'null'::jsonb), p_reason);
end;
$$;

create function public.request_team_leaders(p_team_id uuid, p_leaders uuid[], p_reason text default '')
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_from uuid[];
  v_to uuid[];
begin
  if not exists (select 1 from public.teams where id = p_team_id) then
    raise exception 'Team not found';
  end if;
  select coalesce(array_agg(user_id order by user_id), '{}') into v_from from public.team_leaders where team_id = p_team_id;
  select coalesce(array_agg(distinct x order by x), '{}') into v_to
    from unnest(coalesce(p_leaders, '{}')) x
    join public.profiles p on p.id = x and p.active and p.role in ('team_leader', 'manager');
  if v_from = v_to then
    raise exception 'Those are already the team''s leaders';
  end if;
  return public.add_change_request('leaders', null, p_team_id, to_jsonb(v_from), to_jsonb(v_to), p_reason);
end;
$$;

create function public.decide_change_request(p_request_id uuid, p_approve boolean, p_note text default '')
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.people_change_requests;
  v_leader uuid;
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
      if (select to_jsonb(role) from public.profiles where id = r.user_id) <> r.from_value then
        raise exception 'Their role has changed since the request was made. Ask for a new request.';
      end if;
      update public.profiles set role = (r.to_value #>> '{}')::public.app_role where id = r.user_id;
    elsif r.kind = 'team' then
      update public.profiles set team_id = (r.to_value #>> '{}')::uuid where id = r.user_id;
    else
      if exists (select 1 from jsonb_array_elements_text(r.to_value) x where x::uuid = auth.uid())
         or exists (select 1 from public.team_leaders where team_id = r.team_id and user_id = auth.uid()) then
        raise exception 'You cannot approve a change to a team you lead';
      end if;
      delete from public.team_leaders where team_id = r.team_id;
      for v_leader in select x::uuid from jsonb_array_elements_text(r.to_value) x loop
        insert into public.team_leaders (team_id, user_id) values (r.team_id, v_leader) on conflict do nothing;
      end loop;
    end if;
  end if;

  update public.people_change_requests
     set status = case when p_approve then 'approved' else 'declined' end,
         decided_by = auth.uid(), decided_at = now(), decision_note = coalesce(trim(p_note), '')
   where id = p_request_id;
  perform public.write_audit(r.kind || case when p_approve then '_change_approved' else '_change_declined' end,
    case when r.kind = 'leaders' then 'team' else 'profile' end, coalesce(r.user_id, r.team_id)::text,
    jsonb_build_object('from', r.from_value, 'to', r.to_value));
end;
$$;

revoke execute on function public.add_change_request(text, uuid, uuid, jsonb, jsonb, text) from public, anon, authenticated;
revoke execute on function public.request_role_change(uuid, public.app_role, text) from public, anon;
revoke execute on function public.request_team_change(uuid, uuid, text) from public, anon;
revoke execute on function public.request_team_leaders(uuid, uuid[], text) from public, anon;
revoke execute on function public.decide_change_request(uuid, boolean, text) from public, anon;
grant execute on function public.request_role_change(uuid, public.app_role, text) to authenticated;
grant execute on function public.request_team_change(uuid, uuid, text) to authenticated;
grant execute on function public.request_team_leaders(uuid, uuid[], text) to authenticated;
grant execute on function public.decide_change_request(uuid, boolean, text) to authenticated;

-- Staff admins create and rename teams; who's in a team, and who leads it,
-- goes through a manager (above). Managers change them straight away.
drop policy "managers and admins manage team leaders" on public.team_leaders;
create policy "managers set team leaders" on public.team_leaders
  for all to authenticated
  using (public.has_role(array['manager', 'system_admin']::public.app_role[]))
  with check (public.has_role(array['manager', 'system_admin']::public.app_role[]));

-- ---------------------------------------------------------------------------
-- Managers change the SLA settings (every change is in the change log).
-- ---------------------------------------------------------------------------

create policy "managers change the SLA" on public.app_settings
  for update to authenticated
  using (key like 'tasks.sla%' and public.has_role(array['manager']::public.app_role[]))
  with check (key like 'tasks.sla%' and public.has_role(array['manager']::public.app_role[]));

-- ---------------------------------------------------------------------------
-- System admins are hidden from everyone except other system admins.
-- (Anything they do shows as "Admin".)
-- ---------------------------------------------------------------------------

drop policy "members read colleagues" on public.profiles;
create policy "members read colleagues" on public.profiles
  for select to authenticated
  using (public.is_member() and (role <> 'system_admin' or public.is_system_admin()));
