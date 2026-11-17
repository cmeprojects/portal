-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 106: removes client assignments and the "assigned clients only"
-- scope, and puts the permission check back as it was. Undo update 107 first.
-- Safe to run again.
begin;
drop table if exists public.client_assignments;
drop function if exists public.guard_client_assignment();
delete from public.access_baselines where scope = 'assigned';
alter table public.access_baselines drop constraint if exists access_baselines_scope_check;
alter table public.access_baselines add constraint access_baselines_scope_check check (scope in ('all', 'own_teams'));
CREATE OR REPLACE FUNCTION public.guard_access_baseline()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
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
  select p.role, p.active, p.job_title_id, coalesce(t.active, false) as title_active
    into v_me
    from public.profiles p left join public.job_titles t on t.id = p.job_title_id
   where p.id = auth.uid();
  if not found or not v_me.active or v_me.role in ('new_starter', 'external') then
    return false;
  end if;
  select coalesce(array_agg(jf.function_group_id), '{}') into v_groups
    from public.job_title_functions jf join public.function_groups fg on fg.id = jf.function_group_id
   where jf.job_title_id = v_me.job_title_id and fg.active and v_me.title_active;

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
       and ((b.job_title_id is not null and b.job_title_id = v_me.job_title_id and v_me.title_active)
            or (b.function_group_id is not null and b.function_group_id = any (v_groups) and m.sensitivity = 'normal')
            or (b.access_level is not null and b.access_level = v_me.role))
       and (l.depth = 0 or (m.sensitivity = 'normal' and m.added_at <= b.created_at))
       and (p_person is null or b.scope = 'all'
            or (b.scope = 'own_teams' and exists (
                  select 1 from public.team_members t2
                   where t2.user_id = p_person
                     and t2.team_id in (select tm.team_id from public.team_members tm where tm.user_id = auth.uid()
                                        union select tl.team_id from public.team_leaders tl where tl.user_id = auth.uid()))))
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
