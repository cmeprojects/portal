-- Staff Portal · © cmeproject. All rights reserved.
-- Update 96: Manage cars switched over to the one permission check (Stage 3b).
-- Today's "Who manages cars" setting is copied once into access-level
-- defaults on the Access page, so nobody's access changes. Safe to run again.
-- Undo: undo-96.sql. Run update 95 first.
begin;
-- cmeprojects (update 96; function-based access, Stage 3b; decisions D-047,
-- D-049): Manage cars switched over to the one permission check `can()`.
--
--   * Who manages cars (add and change cars, purposes and clients, correct or
--     return trips for someone) now comes only from
--     `can('ops.cars.manage', 'configure')`: person grants, then job title,
--     function groups, access level. Cars must still be switched on.
--   * Today's System setting "Who manages cars" is copied once into
--     access-level defaults (full Manage cars access for each role ticked),
--     so nobody's access changes. After this it's changed on the Access page;
--     the old setting is kept but no longer used.
--   * Car managers still see the car reports (that rule follows the new
--     check). Who else sees the reports is unchanged ("Who sees car reports").
--   * Using a car and the Cars app are unchanged (every member).

update public.app_modules set grant_ready = true where id = 'ops.cars.manage' and not grant_ready;

-- Copy today's setting into access-level defaults, once (skipped while any
-- live access-level default for Manage cars exists).
do $$
begin
  if exists (select 1 from public.access_baselines
              where module_id = 'ops.cars.manage' and access_level is not null and revoked_at is null) then
    return;
  end if;
  insert into public.access_baselines (access_level, module_id, actions, scope, note)
  select distinct r, 'ops.cars.manage', '{}'::text[], 'all', 'Set at switch-over from "Who manages cars"'
    from unnest(public.setting_roles('vehicles.manager_roles')) r
   where r not in ('system_admin', 'new_starter', 'external');
end $$;

-- Who manages cars: only the one permission check now (Cars switched on).
create or replace function public.can_manage_cars()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.cars_on() and public.can('ops.cars.manage', 'configure')
$$;

-- Who gets car notices: the system admin (as before), plus everyone at an
-- access level given Manage cars on the Access page.
create or replace function public.car_managers()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select p.id from public.profiles p
   where p.active
     and (p.role = 'system_admin'
          or exists (select 1 from public.access_baselines b
                      where b.access_level = p.role and b.module_id = 'ops.cars.manage' and b.revoked_at is null
                        and b.effect = 'allow' and (cardinality(b.actions) = 0 or 'configure' = any (b.actions))
                        and (b.by_system_admin or public.is_manager_admin(b.granted_by))))
$$;
commit;
