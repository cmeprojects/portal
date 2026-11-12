-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 73. WARNING: removes the Manager Administrator
-- nominations (module access already given stays, under the update 69 rules). Safe to run again.
begin;
-- cmeprojects: the rules for giving access, as update 69 left them.
drop policy if exists "grant within the rules" on public.access_grants;
create policy "grant within the rules" on public.access_grants
  for insert to authenticated
  with check (revoked_at is null and revoked_by is null
              and public.grant_allowed(area, user_id, scope, scope_ids, can_pass_on, can_reveal_tfn, expires_at, parent_id, granted_by));
-- can() as update 69 left it.
create or replace function public.can(p_module text, p_action text default 'view', p_person uuid default null)
returns boolean
language plpgsql
stable
security invoker
set search_path = ''
as $$
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
       and (g.parent_id is null or (gb.active and gb.role = 'manager'))
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
$$;
revoke execute on function public.can(text, text, uuid) from public, anon;
grant execute on function public.can(text, text, uuid) to authenticated;
drop function if exists public.module_grant_allowed(text, uuid, text[], text, uuid[], boolean, timestamptz, uuid, uuid);
drop table if exists public.admin_designations;
drop function if exists public.guard_admin_designation();
drop function if exists public.is_manager_admin(uuid);
commit;
