-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 94: puts the permission check can() back exactly as it was,
-- removes the role, group and access-level grants table and the grant_ready
-- flag. Person grants are untouched. Safe to run again.
begin;
drop table if exists public.access_baselines;
drop function if exists public.guard_access_baseline();
drop function if exists public.baseline_grant_allowed(text, text[]);
CREATE OR REPLACE FUNCTION public.can(p_module text, p_action text DEFAULT 'view'::text, p_person uuid DEFAULT NULL::uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
declare
  m record;
  v_effect text;
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
  -- Grants: the nearest level (this module, then its parents, then its category) decides.
  with recursive chain(id, depth) as (
    select m.id, 0
    union all
    select a.parent_id, c.depth + 1 from public.app_modules a join chain c on a.id = c.id where a.parent_id is not null
  ), levels as (
    select id, depth from chain
    union all
    select 'cat_' || m.category, 99
  )
  -- The nearest level with any grant decides: a restriction there for this
  -- action blocks; an allow there that includes this action allows; otherwise no.
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
       -- Given by the system admin: only while they're a Manager Administrator.
       -- Passed on: only while the person who passed it on still is.
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
  return coalesce(v_effect = 'allow', false);
end;
$function$

;
alter table public.app_modules drop column if exists grant_ready;
commit;
