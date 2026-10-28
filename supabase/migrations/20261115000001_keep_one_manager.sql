-- Staff Portal · © cmeproject. All rights reserved.
--
-- There must always be at least one active manager. When only one is left,
-- staff admins (and other managers) can't deactivate them or change their
-- role; the system admin can, if it's really needed.

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

  -- Keep at least one active manager (only the system admin can remove the last one).
  if actor is not null and not public.is_system_admin()
     and old.role = 'manager' and old.active
     and (new.role <> 'manager' or not new.active)
     and not exists (select 1 from public.profiles where role = 'manager' and active and id <> old.id) then
    raise exception 'They''re the only manager left, so they can''t be deactivated or given another role. Add another manager first.';
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

-- Refuse a staff admin's request straight away, rather than at approval.
create or replace function public.request_role_change(p_user_id uuid, p_to_role public.app_role, p_title_id uuid default null, p_reason text default '')
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
  if v_from = 'manager' and v_to <> 'manager'
     and not exists (select 1 from public.profiles where role = 'manager' and active and id <> p_user_id) then
    raise exception 'They''re the only manager left, so their role can''t change. Add another manager first.';
  end if;
  if not public.can_manage_role(v_from) or not public.can_manage_role(v_to) then
    raise exception 'Only a system admin can manage system admins';
  end if;
  return public.add_change_request('role', p_user_id, null,
    jsonb_build_object('role', v_from, 'title', v_from_title),
    jsonb_build_object('role', v_to, 'title', p_title_id), p_reason);
end;
$$;
