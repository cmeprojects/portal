-- Staff Portal · © cmeproject. All rights reserved.
--
-- Conditional roles: when the items still to do are only for new starters (or
-- other roles), the chosen role needs nothing, so it's simply given.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com');
insert into public.invitations (email, full_name) values ('kai@example.com', 'Kai'), ('ana@example.com', 'Ana'), ('bo@example.com', 'Bo'), ('cy@example.com', 'Cy');
insert into auth.users (email) values ('kai@example.com'), ('ana@example.com'), ('bo@example.com'), ('cy@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;

-- Licence is for new starters and team leaders, not support workers.
insert into public.compliance_items (kind, title, applies_roles) values ('upload', 'Licence', '{new_starter,team_leader}');
select test.ok(public.onboarding_missing(test.pid('kai@example.com')) = array['Licence'], 'the Staff page shows Licence still to do');

select test.act_as('boss@example.com');
set role authenticated;
select public.give_conditional_role(test.pid('kai@example.com'), 'team_leader', null, '{}', 'Rostered Monday', current_date + 14);
select public.give_conditional_role(test.pid('ana@example.com'), 'support_worker', null, '{}', 'Rostered Monday', current_date + 14);
reset role;
select test.ok((select role = 'team_leader' from public.profiles where email = 'kai@example.com')
               and exists (select 1 from public.tasks where title = 'Finish onboarding' and assigned_to = test.pid('kai@example.com')),
  'a role that needs Licence: given on condition, with a Finish onboarding task');
select test.ok((select role = 'support_worker' from public.profiles where email = 'ana@example.com')
               and not exists (select 1 from public.tasks where assigned_to = test.pid('ana@example.com')),
  'a role that needs nothing more: a manager just gives it, with no task');

select test.ok(public.rule_on('people.first_role_approval') and public.rule_on('people.staff_admin_role_approval'),
  'a staff admin''s role changes need approval, a first role too');
select test.act_as('office@example.com');
set role authenticated;
select test.refused($$update public.profiles set role = 'support_worker' where email = 'bo@example.com'$$,
  'a staff admin can''t give a first role directly');
reset role;
select test.act_as('office@example.com');
set role authenticated;
select public.give_conditional_role(test.pid('cy@example.com'), 'support_worker', null, '{}', 'Rostered Monday', current_date + 14);
reset role;
select test.ok((select role = 'new_starter' from public.profiles where email = 'cy@example.com')
               and exists (select 1 from public.people_change_requests where user_id = test.pid('cy@example.com') and status = 'pending'),
  'a staff admin''s conditional role always goes to a manager, even with nothing left to do');

\o
\echo All conditional role tests passed.
