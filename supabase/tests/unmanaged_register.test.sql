-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 83): managers can act on tasks in a register with no
-- named managers (they're the ones told about its escalations). A register
-- with named managers stays with them.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('boss2@example.com', 'Max', 'manager'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('boss2@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.tid(p_title text) returns uuid language sql security definer as $$ select id from public.tasks where title = p_title $$;
grant execute on all functions in schema test to authenticated;
delete from public.registry_managers where registry_id = (select id from public.registries where prefix = 'GEN');

select test.act_as('owner@example.com');
set role authenticated;
select public.create_task('Unmanaged', (select id from public.registries where prefix = 'GEN'), test.pid('sam@example.com'));
reset role;
update public.tasks set status = 'escalated', escalated = true where title = 'Unmanaged';

select test.act_as('boss@example.com');
set role authenticated;
select test.ok(public.can_edit_task(test.tid('Unmanaged')), 'with no named managers, a manager can act on the task');
select public.set_task_status(test.tid('Unmanaged'), 'in_progress', 'Dealt with');
select test.ok((select status = 'in_progress' from public.tasks where title = 'Unmanaged'), 'and can mark the escalation dealt with');
reset role;

-- Name Max as the register's manager: then it's his, not Morgan's.
insert into public.registry_managers (registry_id, user_id) select id, test.pid('boss2@example.com') from public.registries where prefix = 'GEN';
select test.act_as('boss@example.com');
set role authenticated;
select test.ok(not public.can_edit_task(test.tid('Unmanaged')), 'once the register has a named manager, other managers can''t');
reset role;
select test.act_as('boss2@example.com');
set role authenticated;
select test.ok(public.can_edit_task(test.tid('Unmanaged')), 'the named manager can');
reset role;
select test.act_as('sam@example.com');
set role authenticated;
select test.ok(public.can_edit_task(test.tid('Unmanaged')), 'the person it''s assigned to can, as before');
reset role;
