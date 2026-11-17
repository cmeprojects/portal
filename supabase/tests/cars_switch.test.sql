-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 96): Manage cars switched over to can() (Stage 3b,
-- D-049). "Who manages cars" becomes access-level defaults; nobody's access
-- changes.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('lead@example.com', 'Taylor', 'team_leader'),
  ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker'),
  ('ada@example.com', 'Ada', 'staff_admin'), ('newbie@example.com', 'Nina', 'new_starter');
insert into auth.users (email) values ('boss@example.com'), ('lead@example.com'), ('sam@example.com'), ('kim@example.com'), ('ada@example.com'), ('newbie@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.as_check(p_email text, p_sql text) returns boolean language plpgsql as $$
declare v boolean;
begin
  perform test.act_as(p_email);
  execute 'set local role authenticated';
  execute 'select ' || p_sql into v;
  execute 'reset role';
  return v;
end $$;
grant execute on all functions in schema test to authenticated;
update public.features set enabled = true where key = 'vehicles';

-- Switched over, with the setting's default (managers) copied.
select test.ok((select grant_ready from public.app_modules where id = 'ops.cars.manage'), 'Manage cars is switched over');
select test.ok((select not grant_ready from public.app_modules where id = 'ops.cars.use'), 'using a car is not (every member, unchanged)');
select test.ok((select array_agg(access_level::text) from public.access_baselines where module_id = 'ops.cars.manage' and revoked_at is null and by_system_admin) = '{manager}', 'managers copied from "Who manages cars"');

-- Same as today, role by role.
select test.ok(test.as_check('owner@example.com', 'public.can_manage_cars()'), 'system admin manages cars');
select test.ok(test.as_check('boss@example.com', 'public.can_manage_cars()'), 'manager manages cars (the setting)');
select test.ok(not test.as_check('ada@example.com', 'public.can_manage_cars()'), 'staff admin doesn''t');
select test.ok(not test.as_check('lead@example.com', 'public.can_manage_cars()'), 'team leader doesn''t');
select test.ok(not test.as_check('sam@example.com', 'public.can_manage_cars()'), 'support worker doesn''t');
select test.ok(not test.as_check('newbie@example.com', 'public.can_manage_cars()'), 'new starter doesn''t');
select test.ok(test.as_check('boss@example.com', 'public.can_see_car_reports()'), 'car managers still see the car reports');
select test.ok(not test.as_check('sam@example.com', 'public.can_see_car_reports()'), 'others don''t');
select test.ok((select array_agg(x order by x) from public.car_managers() x) = (select array_agg(id order by id) from public.profiles where email in ('owner@example.com', 'boss@example.com')), 'car notices: system admin and managers, as before');

-- Cars switched off: nobody manages them.
update public.features set enabled = false where key = 'vehicles';
select test.ok(not test.as_check('boss@example.com', 'public.can_manage_cars()'), 'Cars off: no one manages cars');
update public.features set enabled = true where key = 'vehicles';

-- A database rule that used the old check follows the new one.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.cars (name, rego) values ('Corolla', 'ABC123');
reset role;
select test.ok((select count(*) from public.cars where name = 'Corolla') = 1, 'a manager adds a car');
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$insert into public.cars (name, rego) values ('Hiace', 'XYZ789')$$, 'a support worker can''t');
reset role;

-- Changed on the Access page now.
insert into public.job_titles (name, access_level) values ('Fleet Officer', 'support_worker');
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Fleet Officer') where email = 'kim@example.com';
select test.act_as('owner@example.com');
set role authenticated;
insert into public.access_baselines (job_title_id, module_id, actions) values ((select id from public.job_titles where name = 'Fleet Officer'), 'ops.cars.manage', '{view,configure}');
reset role;
select test.ok(test.as_check('kim@example.com', 'public.can_manage_cars()'), 'a role (job title) given Manage cars manages them');
update public.app_settings set value = '["support_worker"]' where key = 'vehicles.manager_roles';
select test.ok(not test.as_check('sam@example.com', 'public.can_manage_cars()'), 'the old System setting no longer gives access');

-- Running the update again adds nothing.
\i supabase/live-updates/update-96.sql
\o /dev/null
select test.ok((select count(*) from public.access_baselines where module_id = 'ops.cars.manage' and access_level is not null and revoked_at is null) = 1, 'running it again adds nothing');

\o
