-- Staff Portal · © cmeproject. All rights reserved.
--
-- People rules the system admin can switch on and off in System settings.

insert into public.app_settings (key, value, label, description, is_public) values
  ('people.staff_admin_role_approval', 'true', 'Staff admin role changes need a manager''s approval',
   'When on, a staff admin''s role changes wait for a manager to approve them.', false),
  ('people.staff_admin_team_approval', 'true', 'Staff admin team changes need a manager''s approval',
   'When on, a staff admin''s changes to who is in a team wait for a manager to approve them.', false),
  ('people.first_role_approval', 'false', 'A new starter''s first role needs approval',
   'When off, a staff admin gives a new starter their first role straight away.', false),
  ('people.general_invites_only', 'false', 'Every invite is a general invite',
   'When on, people are always invited as new starters with no role or team, and given a role afterwards. System admins can still pick a role.', false),
  ('people.new_starter_tasks', 'false', 'New starters can be given tasks',
   'When off, new starters don''t use tasks until they have a role.', false)
on conflict (key) do nothing;

create function public.rule_on(p_key text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select (value #>> '{}')::boolean from public.app_settings where key = p_key), false)
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
  if auth.uid() is not null and not public.can_manage_people() then
    raise exception 'Only managers and admins can invite people';
  end if;
  if auth.uid() is not null and not public.can_manage_role(new.role) then
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

create or replace function public.set_team(p_team_id uuid, p_members uuid[], p_leader uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_members uuid[] := coalesce(p_members, '{}');
  v_old jsonb;
begin
  if not (public.has_role(array['manager', 'system_admin']::public.app_role[])
          or (public.has_role(array['staff_admin']::public.app_role[])
              and not public.rule_on('people.staff_admin_team_approval'))) then
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

create or replace function public.can_take_tasks(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.profiles where id = p_user_id and active and role <> 'system_admin'
                 and (role <> 'new_starter' or public.rule_on('people.new_starter_tasks')))
$$;

create or replace function public.guard_task_people()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.my_role() = 'new_starter' and not public.rule_on('people.new_starter_tasks') then
    raise exception 'You''ll be able to use tasks once a staff admin has set up your role';
  end if;
  if tg_table_name = 'tasks' then
    if (tg_op = 'INSERT' or new.assigned_to is distinct from old.assigned_to) then
      if exists (select 1 from public.profiles where id = new.assigned_to and role = 'system_admin') then
        raise exception 'System admins can''t be given tasks. Choose someone else to look after it.';
      end if;
      if exists (select 1 from public.profiles where id = new.assigned_to and role = 'new_starter')
         and not public.rule_on('people.new_starter_tasks') then
        raise exception 'New starters can''t be given tasks until they have a role';
      end if;
    end if;
  elsif exists (select 1 from public.profiles where id = new.user_id and role = 'system_admin') then
    raise exception 'System admins can''t be added as helpers';
  elsif exists (select 1 from public.profiles where id = new.user_id and role = 'new_starter')
        and not public.rule_on('people.new_starter_tasks') then
    raise exception 'New starters can''t be added as helpers until they have a role';
  end if;
  return new;
end;
$$;
