-- Staff Portal · © cmeproject. All rights reserved.
-- Update 73: Manager Administrators (nominated managers) and passing access on.
-- Safe to run again. Undo: undo-73.sql. Run update 72 first.
begin;
-- cmeprojects module framework step 3: Manager Administrators.
--   * The system admin nominates managers as Manager Administrators (not all
--     managers). Each nomination can have a start and end date, a note, and
--     be suspended, resumed or ended; it's never deleted (it's the history).
--   * Admin access to modules (category, module, submodule, actions) goes only
--     to a nominated manager. A Manager Administrator can pass access on to a
--     staff admin only when allowed ("may pass on"), never wider (same module
--     or one inside it, same or fewer actions, same or narrower scope, ending
--     no later), and never further.
--   * Access only works while the nomination is active: suspending or ending
--     it stops their access and everything they passed on, straight away.
--   * Ending a nomination also removes their module access (recorded).
-- No new SECURITY DEFINER function.

create table if not exists public.admin_designations (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  status      text not null default 'active' check (status in ('active', 'suspended', 'ended')),
  starts_at   timestamptz not null default now(),
  expires_at  timestamptz,
  note        text not null default '' check (length(note) <= 300),
  granted_by  uuid references public.profiles (id) on delete set null,
  created_at  timestamptz not null default now(),
  changed_at  timestamptz,
  changed_by  uuid references public.profiles (id) on delete set null,
  check (expires_at is null or expires_at > starts_at)
);
create unique index if not exists admin_designations_one_open on public.admin_designations (user_id) where status <> 'ended';
alter table public.admin_designations enable row level security;
revoke all on public.admin_designations from anon;
revoke delete, truncate on public.admin_designations from authenticated;
grant select, insert, update on public.admin_designations to authenticated;

-- Who is a Manager Administrator isn't private: members can see it.
drop policy if exists "members see who is a Manager Administrator" on public.admin_designations;
create policy "members see who is a Manager Administrator" on public.admin_designations for select to authenticated
  using ((select public.is_member()));
drop policy if exists "the system admin nominates" on public.admin_designations;
create policy "the system admin nominates" on public.admin_designations for insert to authenticated
  with check ((select public.is_system_admin()) and (select public.mfa_ok()) and granted_by = (select auth.uid()) and status = 'active'
              and exists (select 1 from public.profiles p where p.id = user_id and p.active and p.role = 'manager'));
drop policy if exists "the system admin changes nominations" on public.admin_designations;
create policy "the system admin changes nominations" on public.admin_designations for update to authenticated
  using ((select public.is_system_admin()) and status <> 'ended')
  with check ((select public.is_system_admin()));

-- Only status and end date change; ended is final; who and when are recorded.
-- Ending also removes their module access (and what they passed on).
create or replace function public.guard_admin_designation()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if (to_jsonb(new) - 'status' - 'expires_at' - 'note' - 'changed_at' - 'changed_by') is distinct from (to_jsonb(old) - 'status' - 'expires_at' - 'note' - 'changed_at' - 'changed_by') then
    raise exception 'Only the status, end date and note of a nomination can change.';
  end if;
  new.changed_at := now();
  new.changed_by := auth.uid();
  if new.status = 'ended' and old.status <> 'ended' then
    update public.access_grants set revoked_at = now()
     where user_id = new.user_id and area is null and revoked_at is null;
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_admin_designation() from public, anon, authenticated;
drop trigger if exists guard_admin_designation on public.admin_designations;
create trigger guard_admin_designation before update on public.admin_designations
  for each row execute function public.guard_admin_designation();

-- Is this person a Manager Administrator right now?
create or replace function public.is_manager_admin(p_user uuid default auth.uid())
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select exists (
    select 1 from public.admin_designations d join public.profiles p on p.id = d.user_id
     where d.user_id = p_user and d.status = 'active' and d.starts_at <= now()
       and (d.expires_at is null or d.expires_at > now()) and p.active and p.role = 'manager')
$$;
revoke execute on function public.is_manager_admin(uuid) from public, anon;
grant execute on function public.is_manager_admin(uuid) to authenticated;

-- May this module grant be given? (Grants for staff records keep their own rules.)
create or replace function public.module_grant_allowed(
  p_module text, p_user uuid, p_actions text[], p_scope text, p_scope_ids uuid[],
  p_pass_on boolean, p_expires timestamptz, p_parent uuid, p_by uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select p_by = auth.uid() and p_user <> auth.uid() and public.mfa_ok()
     and (p_expires is null or p_expires > now())
     and (
       -- The system admin: to a Manager Administrator.
       (public.is_system_admin() and p_parent is null and public.is_manager_admin(p_user))
       or
       -- A Manager Administrator passing on their own access to a staff admin.
       (public.is_manager_admin() and not p_pass_on
        and exists (select 1 from public.profiles p where p.id = p_user and p.active and p.role = 'staff_admin')
        and exists (
          with recursive up(id) as (
            select p_module
            union all
            select m.parent_id from public.app_modules m join up on m.id = up.id where m.parent_id is not null
          )
          select 1 from public.access_grants g, public.app_modules target
           where target.id = p_module and g.id = p_parent and g.user_id = auth.uid() and g.area is null
             and g.can_pass_on and g.effect = 'allow' and g.revoked_at is null
             and (g.expires_at is null or g.expires_at > now()) and (g.starts_at is null or g.starts_at <= now())
             -- the same module, or one inside it (sensitive ones only on their own)
             and (g.module_id = p_module
                  or (target.sensitivity = 'normal' and g.include_children
                      and (g.module_id in (select id from up) or g.module_id = 'cat_' || target.category)))
             and (cardinality(g.actions) = 0 or (cardinality(p_actions) > 0 and p_actions <@ g.actions))
             and (g.expires_at is null or (p_expires is not null and p_expires <= g.expires_at))
             and (g.scope = 'all' or (g.scope = p_scope and p_scope_ids <@ g.scope_ids)))
       )
     )
$$;
revoke execute on function public.module_grant_allowed(text, uuid, text[], text, uuid[], boolean, timestamptz, uuid, uuid) from public, anon;
grant execute on function public.module_grant_allowed(text, uuid, text[], text, uuid[], boolean, timestamptz, uuid, uuid) to authenticated;

drop policy if exists "grant within the rules" on public.access_grants;
create policy "grant within the rules" on public.access_grants
  for insert to authenticated
  with check (revoked_at is null and revoked_by is null and (
    (area is not null and public.grant_allowed(area, user_id, scope, scope_ids, can_pass_on, can_reveal_tfn, expires_at, parent_id, granted_by))
    or (area is null and public.module_grant_allowed(module_id, user_id, actions, scope, scope_ids, can_pass_on, expires_at, parent_id, granted_by))));

-- The check, now also requiring an active nomination.
create or replace function public.can(p_module text, p_action text DEFAULT 'view'::text, p_person uuid DEFAULT NULL::uuid)
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
$function$;
commit;
