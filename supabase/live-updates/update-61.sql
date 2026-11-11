-- Staff Portal · © cmeproject. All rights reserved.
-- Update 61 (Phase 2): staff access grants, names set by the office, staff
-- details need access, managers' settings save live. Safe to run again.
-- Undo: undo-61.sql. Run update 60 first.
begin;
-- cmeprojects Phase 2: permissions tidy-up.
--   1. Access grants: who may edit staff details, and (from Phase 3) see
--      payroll/tax and identity/work-rights records. Scoped (all staff, chosen
--      teams or specific people), optional expiry, "may pass on", revoking
--      also ends what was passed on. Grants are never deleted: a revoked
--      grant keeps who revoked it and when, so the table is its own history.
--   2. Names: staff can't change their own name (only when it's still blank,
--      at account set-up); the system admin, or someone granted Staff
--      details, changes names. Every name change goes in the change log.
--   3. Staff details (save_profile): employment details and other people's
--      details need a Staff details grant (or the system admin).
--   4. Settings: only the system admin keeps drafts and Deploy; anyone else's
--      saved change applies straight away, in the same transaction.
-- No new SECURITY DEFINER function: has_access, grant_allowed, the grant
-- triggers and apply_draft are SECURITY INVOKER. Existing definer functions
-- (save_profile, guard_profile_update, save_draft, deploy_drafts) are updated.

-- ---------------------------------------------------------------------------
-- 1. Access grants
-- ---------------------------------------------------------------------------

create table if not exists public.access_grants (
  id             uuid primary key default gen_random_uuid(),
  area           text not null check (area in ('staff_details', 'payroll_tax', 'identity_docs')),
  user_id        uuid not null references public.profiles (id) on delete cascade,
  scope          text not null default 'all' check (scope in ('all', 'teams', 'people')),
  scope_ids      uuid[] not null default '{}',
  can_pass_on    boolean not null default false,
  can_reveal_tfn boolean not null default false,
  expires_at     timestamptz,
  parent_id      uuid references public.access_grants (id),
  granted_by     uuid references public.profiles (id),
  note           text not null default '' check (length(note) <= 300),
  created_at     timestamptz not null default now(),
  revoked_at     timestamptz,
  revoked_by     uuid references public.profiles (id),
  check (scope = 'all' or cardinality(scope_ids) > 0),
  check (can_reveal_tfn = false or area = 'payroll_tax'),
  check (parent_id is null or can_pass_on = false)
);

-- One live grant per person and area.
create unique index if not exists access_grants_one_live
  on public.access_grants (area, user_id) where revoked_at is null;
create index if not exists access_grants_parent on public.access_grants (parent_id) where parent_id is not null;

alter table public.access_grants enable row level security;
revoke all on public.access_grants from anon;
revoke delete, truncate on public.access_grants from authenticated;
grant select, insert, update on public.access_grants to authenticated;

-- Does the signed-in person hold a live grant for this area that covers this
-- person? The system admin always does. Reads only the caller's own grants
-- (and their own and the grantor's profile), so it runs as the caller.
create or replace function public.has_access(p_area text, p_person uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select public.mfa_ok() and (
    public.is_system_admin()
    or exists (
      select 1
        from public.access_grants g
        join public.profiles me on me.id = g.user_id
        left join public.profiles gb on gb.id = g.granted_by
       where g.user_id = auth.uid()
         and g.area = p_area
         and g.revoked_at is null
         and (g.expires_at is null or g.expires_at > now())
         and me.active and me.role in ('manager', 'staff_admin')
         -- passed on by a manager: that manager must still be an active manager
         and (g.parent_id is null or (gb.active and gb.role = 'manager'))
         and (g.scope = 'all'
              or (g.scope = 'people' and p_person = any (g.scope_ids))
              or (g.scope = 'teams' and exists (
                    select 1 from public.team_members tm
                     where tm.user_id = p_person and tm.team_id = any (g.scope_ids))))
    )
  )
$$;

revoke execute on function public.has_access(text, uuid) from public, anon;
grant execute on function public.has_access(text, uuid) to authenticated;

-- Is this new grant allowed for the signed-in person? Used by the insert rule.
create or replace function public.grant_allowed(
  p_area text, p_user uuid, p_scope text, p_scope_ids uuid[], p_pass_on boolean,
  p_tfn boolean, p_expires timestamptz, p_parent uuid, p_by uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select p_by = auth.uid() and public.mfa_ok()
     and (p_expires is null or p_expires > now())
     and (
       -- The system admin: first grants, to managers (sensitive areas) or
       -- managers and staff admins (staff details).
       (public.is_system_admin() and p_parent is null and exists (
          select 1 from public.profiles p
           where p.id = p_user and p.active
             and (p.role = 'manager' or (p_area = 'staff_details' and p.role = 'staff_admin'))))
       or
       -- A manager passing on their own grant: to a staff admin, never wider,
       -- never further, never longer.
       (public.my_role() = 'manager' and not p_pass_on and exists (
          select 1 from public.access_grants g
           where g.id = p_parent and g.user_id = auth.uid() and g.area = p_area
             and g.can_pass_on and g.revoked_at is null
             and (g.expires_at is null or g.expires_at > now())
             and (not p_tfn or g.can_reveal_tfn)
             and (g.expires_at is null or (p_expires is not null and p_expires <= g.expires_at))
             and (g.scope = 'all'
                  or (g.scope = p_scope and p_scope_ids <@ g.scope_ids)
                  or (g.scope = 'teams' and p_scope = 'people' and not exists (
                        select 1 from unnest(p_scope_ids) x
                         where not exists (select 1 from public.team_members tm where tm.user_id = x and tm.team_id = any (g.scope_ids))))))
        and exists (select 1 from public.profiles p where p.id = p_user and p.active and p.role = 'staff_admin'))
     )
$$;

revoke execute on function public.grant_allowed(text, uuid, text, uuid[], boolean, boolean, timestamptz, uuid, uuid) from public, anon;
grant execute on function public.grant_allowed(text, uuid, text, uuid[], boolean, boolean, timestamptz, uuid, uuid) to authenticated;

drop policy if exists "see your grants, ones you gave, or all (system admin)" on public.access_grants;
create policy "see your grants, ones you gave, or all (system admin)" on public.access_grants
  for select to authenticated
  using ((select public.is_system_admin()) or user_id = (select auth.uid()) or granted_by = (select auth.uid()));

drop policy if exists "grant within the rules" on public.access_grants;
create policy "grant within the rules" on public.access_grants
  for insert to authenticated
  with check (revoked_at is null and revoked_by is null
              and public.grant_allowed(area, user_id, scope, scope_ids, can_pass_on, can_reveal_tfn, expires_at, parent_id, granted_by));

-- Revoking: the system admin any grant; a manager the grants they passed on.
drop policy if exists "revoke your own grants or any (system admin)" on public.access_grants;
create policy "revoke your own grants or any (system admin)" on public.access_grants
  for update to authenticated
  using (revoked_at is null and ((select public.is_system_admin()) or granted_by = (select auth.uid())))
  with check ((select public.is_system_admin()) or granted_by = (select auth.uid()));

-- An update can only revoke: nothing else changes, and the time and person are set here.
create or replace function public.access_grant_revoke_only()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if old.revoked_at is not null then
    raise exception 'That access has already been removed.';
  end if;
  if (to_jsonb(new) - 'revoked_at' - 'revoked_by') is distinct from (to_jsonb(old) - 'revoked_at' - 'revoked_by')
     or new.revoked_at is null then
    raise exception 'Access can''t be changed, only removed. Remove it and give it again.';
  end if;
  new.revoked_at := now();
  new.revoked_by := auth.uid();
  return new;
end;
$$;

drop trigger if exists access_grants_revoke_only on public.access_grants;
create trigger access_grants_revoke_only before update on public.access_grants
  for each row execute function public.access_grant_revoke_only();

-- Revoking a grant also ends whatever was passed on from it.
create or replace function public.access_grant_cascade()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  update public.access_grants set revoked_at = now()
   where parent_id = new.id and revoked_at is null;
  return null;
end;
$$;

drop trigger if exists access_grants_cascade on public.access_grants;
create trigger access_grants_cascade after update of revoked_at on public.access_grants
  for each row when (new.revoked_at is not null and old.revoked_at is null)
  execute function public.access_grant_cascade();

revoke execute on function public.access_grant_revoke_only() from public, anon, authenticated;
revoke execute on function public.access_grant_cascade() from public, anon, authenticated;

-- Rollout (owner decision 1): everyone who edits staff details today keeps
-- doing so, visibly and revocably: active managers (may pass on) and staff
-- admins, all staff, given by the system admin. Safe to run again.
insert into public.access_grants (area, user_id, scope, can_pass_on, granted_by, note)
select 'staff_details', p.id, 'all', p.role = 'manager',
       (select a.id from public.profiles a where a.role = 'system_admin' and a.active order by a.created_at limit 1),
       'Kept from before (Phase 2 rollout)'
  from public.profiles p
 where p.active and p.role in ('manager', 'staff_admin')
   and not exists (select 1 from public.access_grants g where g.area = 'staff_details' and g.user_id = p.id and g.revoked_at is null);

-- ---------------------------------------------------------------------------
-- 2 and 3. Names and staff details
-- ---------------------------------------------------------------------------

-- Fields a person edits themselves, and fields only people with a Staff
-- details grant (or the system admin) edit, for the people their grant covers.
create or replace function public.save_profile(p_user uuid, p jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  me boolean := p_user = auth.uid();
  manager boolean := public.has_access('staff_details', p_user);
  v_skills text[];
begin
  if not public.is_member() or not public.feature_enabled('hr_profiles') then
    raise exception 'Staff profiles are switched off.';
  end if;
  if not me and not manager then
    raise exception 'You don''t have access to change this person''s details. The system admin can give you access.';
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
    raise exception 'Only people with access to staff details can change department and employment details.';
  end if;

  if not me then
    perform public.write_audit('profile_updated', 'profile', p_user::text, '{}'::jsonb);
  end if;
end;
$$;

revoke execute on function public.save_profile(uuid, jsonb) from public, anon;
grant execute on function public.save_profile(uuid, jsonb) to authenticated;

-- The profile guard, with the name rule added (section "Names").
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

  -- Names (cmeprojects Phase 2): your own only while it's still blank (account
  -- set-up); someone else's with a Staff details grant covering them, or as the
  -- system admin. System jobs (no signed-in person) aren't affected.
  if actor is not null and new.full_name is distinct from old.full_name then
    if new.id = actor and coalesce(trim(old.full_name), '') <> '' and not public.is_system_admin() then
      raise exception 'Your name is set by the office. Ask your manager or the system admin to change it.';
    end if;
    if new.id <> actor and not public.has_access('staff_details', new.id) then
      raise exception 'You don''t have access to change this person''s name. The system admin can give you access.';
    end if;
    if new.id <> actor and old.role = 'system_admin' and not public.is_system_admin() then
      raise exception 'Only a system admin can rename a system admin';
    end if;
    perform public.write_audit('name_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.full_name, 'to', new.full_name));
  end if;

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
        raise exception 'Only a system admin can manage system admins';
      end if;

      if old.role = 'new_starter' and new.role <> 'new_starter'
         and coalesce(current_setting('app.conditional_role', true), '') <> 'on'
         and cardinality(public.onboarding_missing(new.id, new.role, null)) > 0 then
        raise exception 'They haven''t finished onboarding yet. Give a conditional role with a deadline instead.';
      end if;

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

-- ---------------------------------------------------------------------------
-- 4. Settings: save applies straight away for everyone but the system admin
-- ---------------------------------------------------------------------------

-- Make one saved change live. Runs inside save_draft / deploy_drafts only
-- (nobody can call it directly).
create or replace function public.apply_draft(p_kind text, p_key text)
returns boolean
language plpgsql
security invoker
set search_path = ''
as $$
declare
  d record;
  v_enabled boolean;
  v_col text;
begin
  select * into d from public.settings_drafts where kind = p_kind and key = p_key for update;
  if not found or not public.may_change(d.kind, d.key) then
    return false;
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
  return true;
end;
$$;

revoke execute on function public.apply_draft(text, text) from public, anon, authenticated;

-- Make saved changes live: everyone's for the system admin, your own for others.
create or replace function public.deploy_drafts()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  d record;
  v_count integer := 0;
begin
  if auth.uid() is null then
    raise exception 'Please sign in first.';
  end if;
  for d in
    select kind, key from public.settings_drafts
     where public.is_system_admin() or saved_by = auth.uid()
     order by case kind when 'feature' then 1 when 'setting' then 2 when 'website' then 3 else 4 end, key
  loop
    if public.apply_draft(d.kind, d.key) then
      v_count := v_count + 1;
    end if;
  end loop;
  if v_count > 0 then
    perform public.write_audit('settings_deployed', 'settings', 'deploy', jsonb_build_object('changes', v_count));
  end if;
  return v_count;
end;
$$;

-- Save a change. The system admin's changes wait as drafts for Deploy;
-- everyone else's apply straight away in this same transaction (any error
-- leaves nothing changed). Returns 'saved', 'live' or 'unchanged'.
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

  if not public.is_system_admin() then
    if not public.apply_draft(p_kind, p_key) then
      raise exception 'Your change couldn''t be applied. Nothing was changed.';
    end if;
    perform public.write_audit('setting_changed', p_kind, p_key, jsonb_build_object('value', v_value));
    return 'live';
  end if;
  return 'saved';
end;
$$;
commit;
