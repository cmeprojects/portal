-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 61: puts names, staff details and settings saving back as they
-- were, and removes the staff access grants (the grants and their history are
-- deleted). Safe to run again.
begin;

-- Settings: drafts and Deploy for everyone again.
create or replace function public.save_draft(p_kind text, p_key text, p_value jsonb)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_live jsonb;
  v_value jsonb := p_value;
begin
  if p_kind = 'website' then
    -- A part of Website settings: only real columns, compared with what's live.
    if p_key not in ('landing', 'answers', 'limits') or jsonb_typeof(p_value) <> 'object' or exists (
      select 1 from jsonb_object_keys(p_value) k
       where k in ('id', 'updated_at')
          or k not in (select column_name::text from information_schema.columns where table_schema = 'public' and table_name = 'assistant_settings')
    ) then
      raise exception 'Something went wrong. Please refresh and try again.';
    end if;
    select jsonb_object_agg(k, to_jsonb(s) -> k) into v_live
      from public.assistant_settings s, jsonb_object_keys(p_value) k
     where s.id;
  else
    v_live := public.live_value(p_kind, p_key);
  end if;
  if not public.may_change(p_kind, p_key) then
    raise exception 'You don''t have permission to change this.';
  end if;
  if v_live is null then
    raise exception 'This setting doesn''t exist.';
  end if;
  if p_kind = 'feature' then
    if jsonb_typeof(p_value -> 'enabled') <> 'boolean' then
      raise exception 'Choose on or off.';
    end if;
    v_value := jsonb_build_object('enabled', p_value -> 'enabled');
  elsif p_kind = 'delegation' then
    if coalesce(p_value ->> 'mode', '') not in ('admin', 'managers', 'selected') then
      raise exception 'Choose who looks after it.';
    end if;
    v_value := jsonb_build_object(
      'mode', p_value ->> 'mode',
      'people', coalesce((
        select jsonb_agg(p.id order by p.full_name)
          from public.profiles p
         where p.active and p.role in ('manager', 'staff_admin')
           and p.id::text in (select jsonb_array_elements_text(coalesce(p_value -> 'people', '[]')))
      ), '[]'));
    if v_value ->> 'mode' = 'selected' and jsonb_array_length(v_value -> 'people') = 0 then
      raise exception 'Choose at least one manager or staff admin.';
    end if;
    if v_value ->> 'mode' <> 'selected' then
      v_value := jsonb_set(v_value, '{people}', '[]');
    end if;
  end if;

  if v_value = v_live then
    delete from public.settings_drafts where kind = p_kind and key = p_key;
    return 'unchanged';
  end if;
  insert into public.settings_drafts (kind, key, value, saved_by)
  values (p_kind, p_key, v_value, auth.uid())
  on conflict (kind, key) do update set value = excluded.value, saved_by = excluded.saved_by, saved_at = now();
  return 'saved';
end;
$$;

create or replace function public.deploy_drafts()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  d record;
  v_count integer := 0;
  v_enabled boolean;
  v_col text;
begin
  if auth.uid() is null then
    raise exception 'Please sign in first.';
  end if;
  for d in
    select * from public.settings_drafts
     where public.is_system_admin() or saved_by = auth.uid()
     order by case kind when 'feature' then 1 when 'setting' then 2 when 'website' then 3 else 4 end, key
     for update
  loop
    if not public.may_change(d.kind, d.key) then
      continue;
    end if;
    if d.kind = 'setting' then
      update public.app_settings set value = d.value, updated_at = now(), updated_by = auth.uid() where key = d.key;
    elsif d.kind = 'feature' then
      v_enabled := (d.value ->> 'enabled')::boolean;
      update public.features
         set enabled = v_enabled,
             included = case when v_enabled and premium then true else included end,
             updated_at = now(), updated_by = auth.uid()
       where key = d.key;
    elsif d.kind = 'website' then
      for v_col in select jsonb_object_keys(d.value) loop
        execute format('update public.assistant_settings set %I = (jsonb_populate_record(null::public.assistant_settings, $1)).%I where id', v_col, v_col)
          using d.value;
      end loop;
      perform public.write_audit('website_settings_changed', 'website', d.key, '{}'::jsonb);
    else
      update public.delegation_rules
         set mode = d.value ->> 'mode',
             people = coalesce((select array_agg(x::uuid) from jsonb_array_elements_text(d.value -> 'people') x), '{}'),
             updated_by = auth.uid(), updated_at = now()
       where area = d.key;
      perform public.write_audit('delegation_changed', 'area', d.key, d.value);
    end if;
    delete from public.settings_drafts where kind = d.kind and key = d.key;
    v_count := v_count + 1;
  end loop;
  if v_count > 0 then
    perform public.write_audit('settings_deployed', 'settings', 'deploy', jsonb_build_object('changes', v_count));
  end if;
  return v_count;
end;
$$;

-- Staff details: people who manage staff again.
create or replace function public.save_profile(p_user uuid, p jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  me boolean := p_user = auth.uid();
  manager boolean := public.can_manage_people() or public.is_system_admin();
  v_skills text[];
begin
  if not public.is_member() or not public.feature_enabled('hr_profiles') then
    raise exception 'Staff profiles are switched off.';
  end if;
  if not me and not manager then
    raise exception 'You can only change your own profile.';
  end if;
  if not exists (select 1 from public.profiles where id = p_user) then
    raise exception 'That person doesn''t exist.';
  end if;
  insert into public.staff_directory (user_id) values (p_user) on conflict do nothing;
  insert into public.staff_private (user_id) values (p_user) on conflict do nothing;

  if p ? 'skills' then
    select coalesce(array_agg(distinct left(trim(x), 40)) filter (where trim(x) <> ''), '{}') into v_skills
      from jsonb_array_elements_text(p -> 'skills') x;
  end if;

  -- Anyone allowed here (themselves or a people manager).
  update public.staff_directory set
    preferred_name = case when p ? 'preferred_name' then left(trim(p ->> 'preferred_name'), 60) else preferred_name end,
    work_phone     = case when p ? 'work_phone' then left(trim(p ->> 'work_phone'), 30) else work_phone end,
    skills         = case when p ? 'skills' then v_skills else staff_directory.skills end,
    updated_at     = now()
   where user_id = p_user;
  update public.staff_private set
    address         = case when p ? 'address' then left(trim(p ->> 'address'), 300) else address end,
    emergency_name  = case when p ? 'emergency_name' then left(trim(p ->> 'emergency_name'), 100) else emergency_name end,
    emergency_phone = case when p ? 'emergency_phone' then left(trim(p ->> 'emergency_phone'), 30) else emergency_phone end,
    availability    = case when p ? 'availability' and jsonb_typeof(p -> 'availability') = 'object' then p -> 'availability' else availability end,
    updated_at      = now()
   where user_id = p_user;

  -- Employment details: people managers only.
  if manager then
    update public.staff_directory set
      department = case when p ? 'department' then left(trim(p ->> 'department'), 80) else department end
     where user_id = p_user;
    update public.staff_private set
      start_date      = case when p ? 'start_date' then nullif(p ->> 'start_date', '')::date else start_date end,
      employment_type = case when p ? 'employment_type' then coalesce(p ->> 'employment_type', '') else employment_type end,
      employee_id     = case when p ? 'employee_id' then left(trim(p ->> 'employee_id'), 40) else employee_id end
     where user_id = p_user;
  elsif p ?| array['department', 'start_date', 'employment_type', 'employee_id'] then
    raise exception 'Only people who manage staff can change department and employment details.';
  end if;

  if not me then
    perform public.write_audit('profile_updated', 'profile', p_user::text, '{}'::jsonb);
  end if;
end;
$$;

-- Names: the profile guard without the name rule.
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

drop function if exists public.apply_draft(text, text);
drop table if exists public.access_grants;
drop function if exists public.has_access(text, uuid);
drop function if exists public.grant_allowed(text, uuid, text, uuid[], boolean, boolean, timestamptz, uuid, uuid);
drop function if exists public.access_grant_revoke_only();
drop function if exists public.access_grant_cascade();
commit;
