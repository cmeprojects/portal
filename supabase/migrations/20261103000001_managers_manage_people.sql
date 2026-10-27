-- Staff Portal · © cmeproject. All rights reserved.
--
-- 1. Managers can use Staff & roles and Teams. Who can manage whom:
--      managers      → support workers and team leaders
--      staff admins  → also managers
--      system admins → everyone (only they manage staff admins and system admins)
-- 2. System admins can't be given tasks (to look after or to help on).

create function public.can_manage_people()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.has_role(array['manager', 'staff_admin', 'system_admin']::public.app_role[])
$$;

-- The highest role the signed-in person may give out or change.
create function public.can_manage_role(p_role public.app_role)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case public.my_role()
    when 'system_admin' then true
    when 'staff_admin' then p_role in ('support_worker', 'team_leader', 'manager')
    when 'manager' then p_role in ('support_worker', 'team_leader')
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

  -- Server-side jobs (no signed-in person) skip the people rules below.
  if actor is not null then
    if new.role is distinct from old.role
       or new.team_id is distinct from old.team_id
       or new.active is distinct from old.active then

      if not public.can_manage_people() then
        raise exception 'Only managers and admins can change roles, teams or access';
      end if;

      if new.id = actor and (new.role is distinct from old.role or not new.active) then
        raise exception 'You cannot change your own role or deactivate yourself';
      end if;

      if new.id <> actor and (not public.can_manage_role(old.role) or not public.can_manage_role(new.role)) then
        if public.my_role() = 'manager' then
          raise exception 'Managers can manage support workers and team leaders. Ask a staff admin for anything else.';
        end if;
        raise exception 'Only a system admin can manage staff admins and system admins';
      end if;
    end if;
  end if;

  -- Never leave the install without an active system admin.
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
    if public.my_role() = 'manager' then
      raise exception 'Managers can invite support workers and team leaders';
    end if;
    raise exception 'Only a system admin can invite staff admins or system admins';
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

create or replace function public.log_admin_action(p_action text, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_action = 'mfa_reset' and not public.is_system_admin() then
    raise exception 'Only a system admin can reset two-factor login';
  elsif p_action not in ('mfa_reset', 'invite_resent') or not public.can_manage_people() then
    raise exception 'Not allowed';
  end if;
  perform public.write_audit(p_action, 'profile', p_user_id::text, '{}'::jsonb);
end;
$$;

drop policy "staff admin updates people" on public.profiles;
create policy "managers and admins update people" on public.profiles
  for update to authenticated using (public.can_manage_people()) with check (public.can_manage_people());

drop policy "staff admin manages teams" on public.teams;
create policy "managers and admins manage teams" on public.teams
  for all to authenticated using (public.can_manage_people()) with check (public.can_manage_people());

drop policy "staff admin manages team leaders" on public.team_leaders;
create policy "managers and admins manage team leaders" on public.team_leaders
  for all to authenticated using (public.can_manage_people()) with check (public.can_manage_people());

drop policy "staff admin reads invitations" on public.invitations;
drop policy "staff admin creates invitations" on public.invitations;
drop policy "staff admin updates invitations" on public.invitations;
drop policy "staff admin removes pending invitations" on public.invitations;
create policy "managers and admins read invitations" on public.invitations
  for select to authenticated using (public.can_manage_people());
create policy "managers and admins create invitations" on public.invitations
  for insert to authenticated with check (public.can_manage_people());
create policy "managers and admins update invitations" on public.invitations
  for update to authenticated using (public.can_manage_people()) with check (public.can_manage_people());
create policy "managers and admins remove pending invitations" on public.invitations
  for delete to authenticated using (public.can_manage_people() and accepted_at is null);

-- ---------------------------------------------------------------------------
-- System admins can't be given tasks
-- ---------------------------------------------------------------------------

create function public.can_take_tasks(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.profiles where id = p_user_id and active and role <> 'system_admin')
$$;

create function public.guard_task_people()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_table_name = 'tasks' then
    if (tg_op = 'INSERT' or new.assigned_to is distinct from old.assigned_to)
       and exists (select 1 from public.profiles where id = new.assigned_to and role = 'system_admin') then
      raise exception 'System admins can''t be given tasks. Choose someone else to look after it.';
    end if;
  elsif exists (select 1 from public.profiles where id = new.user_id and role = 'system_admin') then
    raise exception 'System admins can''t be added as helpers';
  end if;
  return new;
end;
$$;

create trigger tasks_people_guard
  before insert or update of assigned_to on public.tasks
  for each row execute function public.guard_task_people();

create trigger task_helpers_people_guard
  before insert on public.task_helpers
  for each row execute function public.guard_task_people();

-- Helpers who can't take tasks are left off quietly when a task is created.
create or replace function public.create_task(
  p_title text,
  p_registry_id uuid,
  p_assigned_to uuid,
  p_description text default '',
  p_priority public.task_priority default 'medium',
  p_due_date date default null,
  p_helpers uuid[] default '{}',
  p_details jsonb default '{}'::jsonb,
  p_date_reported date default null,
  p_review_date date default null,
  p_parent_task_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_task_id uuid;
  v_helper uuid;
  v_manager uuid;
  v_helpers uuid[];
  v_registry public.registries;
  v_details jsonb;
begin
  if not public.is_member() then
    raise exception 'Please sign in again';
  end if;
  if not public.feature_enabled('tasks') then
    raise exception 'Tasks are switched off at the moment';
  end if;
  if coalesce(trim(p_title), '') = '' then
    raise exception 'Give the task a title';
  end if;

  if p_parent_task_id is not null then
    if not public.can_edit_task(p_parent_task_id) then
      raise exception 'You can''t add actions to this task';
    end if;
    select registry_id into p_registry_id from public.tasks where id = p_parent_task_id;
    p_details := '{}'::jsonb;
  end if;

  select * into v_registry from public.registries where id = p_registry_id and active;
  if v_registry.id is null or v_registry.kind <> 'tasks' then
    raise exception 'Choose a registry that is in use';
  end if;
  if not public.can_take_tasks(p_assigned_to) then
    raise exception 'Choose someone who can sign in to look after this task (system admins can''t be given tasks)';
  end if;

  v_details := case when p_parent_task_id is null then public.clean_details(p_registry_id, p_details) else '{}'::jsonb end;

  select coalesce(array_agg(distinct h), '{}') into v_helpers
    from unnest(coalesce(p_helpers, '{}')) h
   where h <> p_assigned_to and public.can_take_tasks(h);

  insert into public.tasks (title, description, registry_id, ref_number, priority, assigned_to, created_by,
                            due_date, details, date_reported, review_date, parent_task_id)
  values (trim(p_title), coalesce(trim(p_description), ''), p_registry_id, public.take_ref_number(p_registry_id),
          p_priority, p_assigned_to, auth.uid(), p_due_date, v_details,
          coalesce(p_date_reported, current_date), p_review_date, p_parent_task_id)
  returning id into v_task_id;

  insert into public.task_events (task_id, actor_id, type, to_value)
  values (v_task_id, auth.uid(), 'created', p_assigned_to::text);

  if p_parent_task_id is not null then
    insert into public.task_events (task_id, actor_id, type, to_value)
    values (p_parent_task_id, auth.uid(), 'action_added', v_task_id::text);
  end if;

  foreach v_helper in array v_helpers loop
    insert into public.task_helpers (task_id, user_id, added_by) values (v_task_id, v_helper, auth.uid());
    insert into public.task_events (task_id, actor_id, type, to_value)
    values (v_task_id, auth.uid(), 'helper_added', v_helper::text);
  end loop;

  perform public.queue_task_email('task_assigned', v_task_id, p_assigned_to, v_helpers);
  if p_assigned_to = auth.uid() then
    foreach v_helper in array v_helpers loop
      perform public.queue_task_email('helper_added', v_task_id, v_helper);
    end loop;
  end if;
  if p_parent_task_id is null then
    for v_manager in
      select rm.user_id from public.registry_managers rm
       where rm.registry_id = p_registry_id
         and rm.user_id <> p_assigned_to
         and not (rm.user_id = any (v_helpers))
    loop
      perform public.queue_task_email('task_created_manager', v_task_id, v_manager);
    end loop;
  end if;

  return v_task_id;
end;
$$;
