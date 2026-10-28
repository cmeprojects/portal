-- Staff Portal · © cmeproject. All rights reserved.
--
-- Staff admins see an overview of each register's open tasks, but not task
-- details, and can't add or set up registers.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;

select test.act_as('boss@example.com');
set role authenticated;
select public.create_task('Fix the gate', (select id from public.registries where prefix = 'MNT'), test.pid('sam@example.com'),
  p_description => 'Latch is broken', p_due_date => current_date + 3, p_details => '{}'::jsonb);
select public.create_task('Old job', (select id from public.registries where prefix = 'MNT'), test.pid('sam@example.com'));
reset role;
update public.tasks set status = 'completed' where title = 'Old job';

select test.act_as('office@example.com');
set role authenticated;
select test.ok((select count(*) from public.tasks where title = 'Fix the gate') = 0, 'a staff admin still can''t open task details');
select test.ok((select open_tasks from public.register_open_counts() where registry_id = (select id from public.registries where prefix = 'MNT')) = 1,
  'a staff admin sees the number of open tasks per register');
select test.ok((select title = 'Fix the gate' and description = 'Latch is broken' and assigned_name = 'Sam' and due_date = current_date + 3
                  from public.register_overview((select id from public.registries where prefix = 'MNT'))),
  'a staff admin sees the title, description, due date and who it''s assigned to');
select test.ok((select count(*) from public.register_overview((select id from public.registries where prefix = 'MNT'))) = 1,
  'only open tasks are listed');
select test.refused($$insert into public.registries (name, kind) values ('HR register', 'tasks')$$, 'a staff admin cannot add a register');
select test.refused($$update public.registries set name = 'Changed' where prefix = 'MNT'$$, 'a staff admin cannot set up a register');
select test.ok(not public.manages_registry((select id from public.registries where prefix = 'MNT')), 'a staff admin does not manage registers');
reset role;

select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.register_overview((select id from public.registries where prefix = 'MNT'))) = 0,
  'a support worker doesn''t get the overview');
reset role;

select test.act_as('boss@example.com');
set role authenticated;
insert into public.registries (name, kind) values ('Vehicle checks', 'tasks');
reset role;
select test.ok(exists (select 1 from public.registries where name = 'Vehicle checks'), 'a manager can still add a register');

\o
\echo 'All register overview tests passed.'
