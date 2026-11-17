-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 95; function-based access, Stage 3b; decisions D-047,
-- D-049): Onboarding is the first part switched over to the one permission
-- check `can()`.
--
--   * Who manages onboarding (approve uploads, set up items, the document
--     library) and who sees onboarding progress and the expiry list now come
--     only from `can('hr.onboarding', ...)`: person grants, then job title,
--     function groups, access level.
--   * Today's rules are copied once into access-level defaults, so nobody's
--     access changes on the day (D-049, option A):
--       - each role ticked in System settings "Who manages Compliance" gets
--         full onboarding access;
--       - managers too, if there's no active staff admin when this runs (the
--         old built-in fallback, settled once; a fresh install starts with
--         staff admins only);
--       - managers see progress for everyone, team leaders for their own
--         teams (as today).
--     After this, it's changed on the Access page; the old setting is kept but
--     no longer used.
--   * Grants added by a database update (no signed-in person) count as the
--     system admin's.

-- An insert with no signed-in person (a database update run by the owner)
-- counts as the system admin's. Signed-in people always have an id.
create or replace function public.guard_access_baseline()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  m record;
begin
  if tg_op = 'UPDATE' then
    if (to_jsonb(new) - 'revoked_at' - 'revoked_by') is distinct from (to_jsonb(old) - 'revoked_at' - 'revoked_by') or old.revoked_at is not null then
      raise exception 'A grant isn''t changed: revoke it and add a new one.';
    end if;
    new.revoked_by := auth.uid();
    return new;
  end if;
  select * into m from public.app_modules where id = new.module_id;
  if not found or m.status <> 'active' or m.sensitivity = 'protected' or m.legacy_kind is not null or not m.grant_ready then
    raise exception 'That part can''t be given to a role, group or access level (yet).';
  end if;
  if new.function_group_id is not null and m.sensitivity <> 'normal' then
    raise exception 'Sensitive parts are given to a job title or a person, never to a whole function group.';
  end if;
  if new.access_level in ('system_admin', 'new_starter', 'external') then
    raise exception 'That access level can''t hold grants.';
  end if;
  new.granted_by := auth.uid();
  new.by_system_admin := public.is_system_admin() or auth.uid() is null;
  new.created_at := now();
  return new;
end;
$$;

-- Switch Onboarding over.
update public.app_modules set grant_ready = true
 where id in ('hr.onboarding', 'hr.onboarding.overview', 'hr.onboarding.expiry') and not grant_ready;

-- Copy today's rules into access-level defaults, once (skipped while any live
-- access-level default for Onboarding exists, so running again changes nothing).
do $$
declare
  v_full public.app_role[];
begin
  if exists (select 1 from public.access_baselines
              where module_id like 'hr.onboarding%' and access_level is not null and revoked_at is null) then
    return;
  end if;
  v_full := public.setting_roles('compliance.manager_roles');
  -- The old fallback (managers while there's no staff admin), settled once.
  -- A fresh install (nobody signed up yet) starts with staff admins only.
  if exists (select 1 from public.profiles where role <> 'system_admin')
     and not exists (select 1 from public.profiles where role = 'staff_admin' and active) then
    v_full := v_full || 'manager'::public.app_role;
  end if;
  insert into public.access_baselines (access_level, module_id, actions, scope, note)
  select distinct r, 'hr.onboarding', '{}'::text[], 'all', 'Set at switch-over from "Who manages Compliance"'
    from unnest(v_full) r
   where r not in ('system_admin', 'new_starter', 'external');
  if not ('manager' = any (v_full)) then
    insert into public.access_baselines (access_level, module_id, actions, scope, note)
    values ('manager', 'hr.onboarding', '{view}', 'all', 'Set at switch-over: managers see onboarding progress');
  end if;
  if not ('team_leader' = any (v_full)) then
    insert into public.access_baselines (access_level, module_id, actions, scope, note)
    values ('team_leader', 'hr.onboarding', '{view}', 'own_teams', 'Set at switch-over: team leaders see their teams'' progress');
  end if;
end $$;

-- Who manages onboarding: only the one permission check now.
create or replace function public.can_manage_compliance()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.can('hr.onboarding', 'approve')
$$;

-- Who gets onboarding notices: staff admins (as before), plus everyone at an
-- access level given onboarding management on the Access page.
create or replace function public.people_admins()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select p.id from public.profiles p
   where p.active and p.role <> 'system_admin'
     and (p.role = 'staff_admin'
          or exists (select 1 from public.access_baselines b
                      where b.access_level = p.role and b.module_id = 'hr.onboarding' and b.revoked_at is null
                        and b.effect = 'allow' and (cardinality(b.actions) = 0 or 'approve' = any (b.actions))
                        and (b.by_system_admin or public.is_manager_admin(b.granted_by))))
$$;
