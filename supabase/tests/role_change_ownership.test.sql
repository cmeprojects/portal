-- Staff Portal · © cmeproject. All rights reserved.
--
-- Role changes keep what people own, but don't keep powers their new role
-- doesn't have (cmeprojects).

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;
update public.features set included = true where key = 'forms';
update public.features set enabled = true where key in ('forms', 'form_builder');
update public.app_settings set value = '["staff_admin", "manager"]' where key = 'forms.maker_roles';

-- Olive (staff admin) makes a form and is chosen for People settings.
select test.act_as('office@example.com');
set role authenticated;
insert into public.forms (title) values ('Staff survey');
reset role;
insert into public.delegation_rules (area, mode, people) values ('people', 'selected', array[test.pid('office@example.com')])
on conflict (area) do update set mode = excluded.mode, people = excluded.people;
create function test.form() returns uuid language sql security definer as $$ select id from public.forms where title = 'Staff survey' $$;
grant execute on function test.form() to authenticated;
select test.act_as('office@example.com');
set role authenticated;
select test.ok(public.can_manage_form(test.form()), 'the staff admin manages the form she made');
select test.ok(public.can_admin_area('people'), 'and the People settings she was given');
reset role;

-- She becomes a team leader (not a form-maker role).
select test.act_as('owner@example.com');
set role authenticated;
update public.profiles set role = 'team_leader' where id = test.pid('office@example.com');
reset role;
select test.act_as('office@example.com');
set role authenticated;
select test.ok(public.can_manage_form(test.form()), 'after becoming a team leader she still manages the form she made');
select test.ok(not public.can_make_forms(), 'but can''t make new forms (her new role isn''t a form maker)');
select test.ok(not public.can_admin_area('people'), 'and the People settings she was given as a staff admin aren''t kept');
reset role;
select test.ok((select created_by from public.forms where id = test.form()) = test.pid('office@example.com'), 'who made the form is kept');

-- A deactivated creator's forms aren't left with nobody: the system admin manages them.
select test.act_as('owner@example.com');
set role authenticated;
update public.profiles set active = false where id = test.pid('office@example.com');
select test.ok(public.can_manage_form(test.form()), 'if the creator leaves, the system admin still manages the form');
reset role;

\o
\echo All role change ownership tests passed.
