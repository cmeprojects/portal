-- Staff Portal · © cmeproject. All rights reserved.
--
-- General invites. Anyone can be invited without a role or team; they join as
-- a new starter with limited access (their account for now; trainings and
-- documents later). Staff admins give a new starter their first role straight
-- away; later role changes still need a manager's approval. New starters
-- can't create or be given tasks.

alter table public.invitations alter column role set default 'new_starter';

-- Roles (job titles) link to a real access level.
alter table public.job_titles drop constraint job_titles_access_level_check;
alter table public.job_titles add constraint job_titles_access_level_check
  check (access_level not in ('system_admin', 'new_starter'));

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
      if new.role is distinct from old.role and public.my_role() = 'staff_admin' and old.role <> 'new_starter' then
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

-- An invitation with no role makes a new starter.
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
                  inv.role, 'new_starter'::public.app_role)
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

create or replace function public.can_take_tasks(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.profiles where id = p_user_id and active and role not in ('system_admin', 'new_starter'))
$$;

create or replace function public.guard_task_people()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.my_role() = 'new_starter' then
    raise exception 'You''ll be able to use tasks once a staff admin has set up your role';
  end if;
  if tg_table_name = 'tasks' then
    if (tg_op = 'INSERT' or new.assigned_to is distinct from old.assigned_to) then
      if exists (select 1 from public.profiles where id = new.assigned_to and role = 'system_admin') then
        raise exception 'System admins can''t be given tasks. Choose someone else to look after it.';
      end if;
      if exists (select 1 from public.profiles where id = new.assigned_to and role = 'new_starter') then
        raise exception 'New starters can''t be given tasks until they have a role';
      end if;
    end if;
  elsif exists (select 1 from public.profiles where id = new.user_id and role in ('system_admin', 'new_starter')) then
    raise exception 'System admins and new starters can''t be added as helpers';
  end if;
  return new;
end;
$$;
