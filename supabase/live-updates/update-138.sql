-- Staff Portal · © cmeproject. All rights reserved.
-- Update 138: program scope (AUD-016 Stage 6).
-- Safe to run again. Undo: undo-138.sql.
begin;
alter table public.profiles add column if not exists program_ids uuid[] not null default '{}';

create or replace function public.client_in_my_programs(p_client uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select p_client is not null and exists (
    select 1
      from public.client_services s
      join public.profiles p on p.id = (select auth.uid())
     where s.client_id = p_client
       and s.status in ('planned', 'active', 'on_hold')
       and s.program_id = any (p.program_ids)
       and p.active)
$$;
revoke execute on function public.client_in_my_programs(uuid) from public, anon;
grant execute on function public.client_in_my_programs(uuid) to authenticated;

alter table public.access_baselines drop constraint if exists access_baselines_scope_check;
alter table public.access_baselines add constraint access_baselines_scope_check check (scope in ('all', 'own_teams', 'assigned', 'programs'));
alter table public.access_baselines drop constraint if exists access_baselines_programs_clients_only;
alter table public.access_baselines add constraint access_baselines_programs_clients_only
  check (scope <> 'programs' or (module_id like 'clients.%' and module_id <> 'clients.assign'));

CREATE OR REPLACE FUNCTION public.guard_profile_update()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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

      if not public.can('people.staff', 'edit') then
        raise exception 'Only managers and admins can change roles, teams or access';
      end if;

      if new.id = actor and (new.role is distinct from old.role or not new.active) then
        raise exception 'You cannot change your own role or deactivate yourself';
      end if;

      if new.id <> actor and (not public.can_manage_role(old.role) or not public.can_manage_role(new.role)) then
        raise exception 'Only a system admin can manage system admins';
      end if;

      -- cmeprojects (update 79): a new starter gets another role only once
      -- cleared to work (with onboarding on); otherwise a conditional role.
      if old.role = 'new_starter' and new.role <> 'new_starter'
         and coalesce(current_setting('app.conditional_role', true), '') <> 'on'
         and public.feature_enabled('compliance') and old.cleared_at is null then
        raise exception 'They aren''t cleared to work yet. Clear them to work first (Onboarding), or give a conditional role with a deadline.';
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

  -- cmeprojects (update 137, AUD-016 Stage 6): extra job titles. Each must be an
  -- active job title at the person's own access level (the level stays the
  -- ceiling), not their main one; given by people who manage staff, never to
  -- themselves. A change of access level drops the extra titles that no longer fit.
  if new.role is distinct from old.role and cardinality(new.extra_job_title_ids) > 0 then
    new.extra_job_title_ids := coalesce((select array_agg(t.id order by t.name) from public.job_titles t
      where t.id = any (new.extra_job_title_ids) and t.access_level = new.role and t.id is distinct from new.job_title_id), '{}');
  end if;
  if new.job_title_id is not null and new.job_title_id = any (new.extra_job_title_ids) then
    new.extra_job_title_ids := array_remove(new.extra_job_title_ids, new.job_title_id);
  end if;
  if new.extra_job_title_ids is distinct from old.extra_job_title_ids then
    if actor is not null and new.role is not distinct from old.role then
      if not public.can('people.staff', 'edit', new.id) then
        raise exception 'Only people who manage staff can give extra job titles';
      end if;
      if new.id = actor then
        raise exception 'You can''t give yourself extra job titles';
      end if;
      if exists (select 1 from unnest(new.extra_job_title_ids) x(id)
                  where x.id <> all (old.extra_job_title_ids)
                    and not exists (select 1 from public.job_titles t where t.id = x.id and t.active and t.access_level = new.role)) then
        raise exception 'An extra job title must be in use and at the same access level as their main one';
      end if;
      if cardinality(new.extra_job_title_ids) > 5 then
        raise exception 'Five extra job titles at most';
      end if;
    end if;
    perform public.write_audit('extra_job_titles_changed', 'profile', new.id::text,
      jsonb_build_object('from', (select coalesce(array_agg(name order by name), '{}') from public.job_titles where id = any (old.extra_job_title_ids)),
                         'to', (select coalesce(array_agg(name order by name), '{}') from public.job_titles where id = any (new.extra_job_title_ids))));
  end if;

  -- cmeprojects (update 138, AUD-016 Stage 6): the programs a person works in
  -- (for access scoped to "clients in their programs"). Set by people who manage
  -- staff, never by yourself; only programs in use; logged.
  if new.program_ids is distinct from old.program_ids then
    if actor is not null then
      if not public.can('people.staff', 'edit', new.id) then
        raise exception 'Only people who manage staff can set someone''s programs';
      end if;
      if new.id = actor then
        raise exception 'You can''t set your own programs';
      end if;
      if exists (select 1 from unnest(new.program_ids) x(id)
                  where x.id <> all (old.program_ids)
                    and not exists (select 1 from public.client_programs c where c.id = x.id and c.active)) then
        raise exception 'Choose programs that are in use';
      end if;
    end if;
    perform public.write_audit('programs_changed', 'profile', new.id::text,
      jsonb_build_object('from', (select coalesce(array_agg(name order by name), '{}') from public.client_programs where id = any (old.program_ids)),
                         'to', (select coalesce(array_agg(name order by name), '{}') from public.client_programs where id = any (new.program_ids))));
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
$function$;

CREATE OR REPLACE FUNCTION public.can(p_module text, p_action text DEFAULT 'view'::text, p_person uuid DEFAULT NULL::uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
declare
  m record;
  v_me record;
  v_effect text;
  v_groups uuid[];
  v_titles uuid[];
begin
  select * into m from public.app_modules where id = p_module;
  if not found or m.status <> 'active' then
    return false;
  end if;
  if public.is_system_admin() and public.mfa_ok() then
    return true;
  end if;
  if m.sensitivity = 'protected' or not public.mfa_ok() then
    return false;
  end if;
  -- Today's rules, unchanged.
  if m.legacy_kind = 'settings' then
    return public.can_admin_area(m.legacy_area);
  end if;
  if m.legacy_kind = 'record' then
    if p_action = 'reveal_tfn' then
      return p_person is not null and public.has_tfn_access(p_person);
    end if;
    return case when p_person is null then public.holds_area(m.legacy_area) else public.has_access(m.legacy_area, p_person) end;
  end if;
  -- 1. Person grants (unchanged): the nearest level (this module, then its
  -- parents, then its category) decides.
  with recursive chain(id, depth) as (
    select m.id, 0
    union all
    select a.parent_id, c.depth + 1 from public.app_modules a join chain c on a.id = c.id where a.parent_id is not null
  ), levels as (
    select id, depth from chain
    union all
    select 'cat_' || m.category, 99
  )
  , applicable as (
    select g.effect, g.actions, l.depth
      from public.access_grants g
      join levels l on l.id = g.module_id
      join public.profiles me on me.id = g.user_id
      left join public.profiles gb on gb.id = g.granted_by
     where g.user_id = auth.uid() and g.area is null and g.revoked_at is null
       and (g.expires_at is null or g.expires_at > now())
       and (g.starts_at is null or g.starts_at <= now())
       and me.active and me.role in ('manager', 'staff_admin')
       and (case when g.parent_id is null then public.is_manager_admin(g.user_id) else (gb.active and gb.role = 'manager' and public.is_manager_admin(g.granted_by)) end)
       and (l.depth = 0 or (g.include_children and m.sensitivity = 'normal' and m.added_at <= g.created_at))
       and (p_person is null or g.scope = 'all'
            or (g.scope = 'people' and p_person = any (g.scope_ids))
            or (g.scope = 'teams' and exists (select 1 from public.team_members tm where tm.user_id = p_person and tm.team_id = any (g.scope_ids))))
  )
  select case
           when bool_or(a.effect = 'restrict' and (cardinality(a.actions) = 0 or p_action = any (a.actions))) then 'restrict'
           when bool_or(a.effect = 'allow' and (cardinality(a.actions) = 0 or p_action = any (a.actions))) then 'allow'
         end into v_effect
    from applicable a
   where a.depth = (select min(depth) from applicable);
  if v_effect is not null then
    return v_effect = 'allow';
  end if;

  -- 2 to 4. Inherited (cmeprojects Stage 3, D-047): job title, then function
  -- groups, then access level. Only for modules switched over to can().
  if not m.grant_ready then
    return false;
  end if;
  select p.role, p.active, p.job_title_id, coalesce(t.active, false) as title_active, p.extra_job_title_ids
    into v_me
    from public.profiles p left join public.job_titles t on t.id = p.job_title_id
   where p.id = auth.uid();
  if not found or not v_me.active or v_me.role in ('new_starter', 'external') then
    return false;
  end if;
  -- cmeprojects (update 137): the main job title plus any extra ones, each only
  -- while active and at the person's own access level.
  select coalesce(array_agg(t.id), '{}') into v_titles
    from public.job_titles t
   where t.active and t.access_level = v_me.role
     and ((t.id = v_me.job_title_id and v_me.title_active) or t.id = any (v_me.extra_job_title_ids));
  select coalesce(array_agg(distinct jf.function_group_id), '{}') into v_groups
    from public.job_title_functions jf join public.function_groups fg on fg.id = jf.function_group_id
   where jf.job_title_id = any (v_titles) and fg.active;

  with recursive chain(id, depth) as (
    select m.id, 0
    union all
    select a.parent_id, c.depth + 1 from public.app_modules a join chain c on a.id = c.id where a.parent_id is not null
  ), levels as (
    select id, depth from chain
    union all
    select 'cat_' || m.category, 99
  ), applicable as (
    select case when b.job_title_id is not null then 1 when b.function_group_id is not null then 2 else 3 end as tier,
           l.depth, b.effect, b.actions
      from public.access_baselines b
      join levels l on l.id = b.module_id
     where b.revoked_at is null
       -- Given by the system admin, or by someone who is still an active Manager Administrator.
       and (b.by_system_admin or public.is_manager_admin(b.granted_by))
       and ((b.job_title_id is not null and b.job_title_id = any (v_titles))
            or (b.function_group_id is not null and b.function_group_id = any (v_groups) and m.sensitivity = 'normal')
            or (b.access_level is not null and b.access_level = v_me.role))
       and (l.depth = 0 or (m.sensitivity = 'normal' and m.added_at <= b.created_at))
       and (p_person is null or b.scope = 'all'
            or (b.scope = 'own_teams' and exists (
                  select 1 from public.team_members t2
                   where t2.user_id = p_person
                     and t2.team_id in (select tm.team_id from public.team_members tm where tm.user_id = auth.uid()
                                        union select tl.team_id from public.team_leaders tl where tl.user_id = auth.uid())))
            -- cmeprojects (update 106): for client parts the person is the client.
            or (b.scope = 'own_teams' and m.category = 'clients' and exists (
                  select 1 from public.client_teams ct
                   where ct.client_id = p_person
                     and ct.team_id in (select tm.team_id from public.team_members tm where tm.user_id = auth.uid()
                                        union select tl.team_id from public.team_leaders tl where tl.user_id = auth.uid())))
            -- cmeprojects (update 138): clients with a current service in one of the person's programs.
            or (b.scope = 'programs' and m.category = 'clients' and m.id <> 'clients.assign' and public.client_in_my_programs(p_person))
            or (b.scope = 'assigned' and m.category = 'clients' and m.id <> 'clients.assign' and exists (
                  select 1 from public.client_assignments a
                   where a.client_id = p_person and a.user_id = auth.uid() and a.ended_at is null
                     and a.starts_on <= public.local_today() and (a.ends_on is null or a.ends_on >= public.local_today()))))
  ), best as (
    select * from applicable where tier = (select min(tier) from applicable)
  )
  select case
           when bool_or(a.effect = 'restrict' and (cardinality(a.actions) = 0 or p_action = any (a.actions))) then 'restrict'
           when bool_or(a.effect = 'allow' and (cardinality(a.actions) = 0 or p_action = any (a.actions))) then 'allow'
         end into v_effect
    from best a
   where a.depth = (select min(depth) from best);
  return coalesce(v_effect = 'allow', false);
end;
$function$;
commit;
