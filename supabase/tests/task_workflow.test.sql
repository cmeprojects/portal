-- Staff Portal · © cmeproject. All rights reserved.
--
-- Working on tasks: status, approvals, comments, escalating, reassigning,
-- taking over and attachments.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('boss2@example.com', 'Max', 'manager'),
  ('lead@example.com', 'Taylor', 'team_leader'), ('sam@example.com', 'Sam', 'support_worker'),
  ('kim@example.com', 'Kim', 'support_worker'), ('ali@example.com', 'Ali', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('boss2@example.com'), ('lead@example.com'), ('sam@example.com'), ('kim@example.com'), ('ali@example.com');
insert into public.teams (name) values ('Team A');
insert into public.team_leaders (team_id, user_id) select t.id, p.id from public.teams t, public.profiles p where t.name = 'Team A' and p.email = 'lead@example.com';
insert into public.team_members (team_id, user_id) select t.id, p.id from public.teams t, public.profiles p where t.name = 'Team A' and p.email = 'sam@example.com';
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.tid(p_title text) returns uuid language sql security definer as $$ select id from public.tasks where title = p_title $$;
create function test.status(p_title text) returns text language sql security definer as $$ select status::text from public.tasks where title = p_title $$;
create function test.notes(p_email text, p_kind text) returns bigint language sql security definer as $$
  select count(*) from public.notifications where user_id = test.pid(p_email) and kind = p_kind $$;
grant execute on all functions in schema test to authenticated;
-- Morgan manages Maintenance, which needs approval to close.
insert into public.registry_managers (registry_id, user_id) select id, test.pid('boss@example.com') from public.registries where prefix = 'MNT';
update public.registries set requires_approval = true where prefix = 'MNT';

select test.act_as('kim@example.com');
set role authenticated;
select public.create_task('Fix tap', (select id from public.registries where prefix = 'MNT'), test.pid('sam@example.com'), p_helpers => array[test.pid('ali@example.com')]);
select public.create_task('Order gloves', (select id from public.registries where prefix = 'GEN'), test.pid('sam@example.com'));
reset role;

-- Sam works on it.
select test.act_as('sam@example.com');
set role authenticated;
select public.set_task_status(test.tid('Fix tap'), 'in_progress');
select public.add_task_comment(test.tid('Fix tap'), 'Parts ordered');
select test.refused($$select public.add_task_comment(test.tid('Fix tap'), '   ')$$, 'an empty comment is refused');
select test.ok(public.set_task_status(test.tid('Fix tap'), 'completed') = 'awaiting_approval', 'completing in an approval register waits for approval');
reset role;
select test.ok(test.notes('kim@example.com', 'task_comment') = 1 and test.notes('ali@example.com', 'task_comment') = 1, 'the others on the task hear about comments');
select test.ok(test.notes('boss@example.com', 'approval_needed') = 1, 'the register''s manager is asked to approve');
select test.ok(test.notes('boss2@example.com', 'approval_needed') = 0, 'other managers aren''t');

-- Approving.
select test.act_as('boss2@example.com');
set role authenticated;
select test.refused($$select public.set_task_status(test.tid('Fix tap'), 'completed')$$, 'a manager who doesn''t manage the register can''t approve');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$select public.set_task_status(test.tid('Fix tap'), 'in_progress', '')$$, 'sending back needs a reason');
select public.set_task_status(test.tid('Fix tap'), 'in_progress', 'Tap still drips');
reset role;
select test.ok(test.status('Fix tap') = 'in_progress' and test.notes('sam@example.com', 'sent_back') = 1, 'sent back to Sam with the reason');
select test.act_as('sam@example.com');
set role authenticated;
select public.set_task_status(test.tid('Fix tap'), 'completed');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select public.set_task_status(test.tid('Fix tap'), 'completed');
reset role;
select test.ok((select status = 'completed' and completed_at is not null from public.tasks where title = 'Fix tap'), 'approved: completed');

-- Closing and reopening.
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$select public.set_task_status(test.tid('Fix tap'), 'closed')$$, 'the person who did it can''t close it themselves');
reset role;
select test.act_as('kim@example.com');
set role authenticated;
select public.set_task_status(test.tid('Fix tap'), 'closed');
reset role;
select test.ok(test.status('Fix tap') = 'closed', 'the creator closes it');
select test.act_as('lead@example.com');
set role authenticated;
select test.refused($$select public.set_task_status(test.tid('Fix tap'), 'in_progress', '')$$, 'reopening needs a reason');
select public.set_task_status(test.tid('Fix tap'), 'in_progress', 'Leaking again');
reset role;
select test.ok(test.status('Fix tap') = 'in_progress', 'the team leader reopens it');

-- No approval needed in General; open follow-up actions block completing.
select test.act_as('sam@example.com');
set role authenticated;
select public.create_task('Count boxes', null, test.pid('kim@example.com'), p_parent_task_id => test.tid('Order gloves'));
select test.refused($$select public.set_task_status(test.tid('Order gloves'), 'completed')$$, 'open follow-up actions must be finished first');
reset role;
select test.act_as('kim@example.com');
set role authenticated;
select public.set_task_status(test.tid('Count boxes'), 'completed');
reset role;
select test.act_as('sam@example.com');
set role authenticated;
select test.ok(public.set_task_status(test.tid('Order gloves'), 'completed') = 'completed', 'no approval needed: completed straight away');
reset role;

-- Escalating.
select test.act_as('ali@example.com');
set role authenticated;
select test.refused($$select public.escalate_task(test.tid('Fix tap'), '')$$, 'escalating needs a reason');
select public.escalate_task(test.tid('Fix tap'), 'Water damage spreading');
reset role;
select test.ok(test.status('Fix tap') = 'escalated' and test.notes('boss@example.com', 'task_escalated') = 1,
  'a helper escalates; the register manager is told');
select test.ok(exists (select 1 from public.email_outbox where template = 'notice' and to_user = test.pid('boss@example.com')
                         and data ->> 'title' like 'Escalated:%'), 'and emailed');

-- Reassigning and taking over.
select test.act_as('kim@example.com');
set role authenticated;
select test.refused($$select public.reassign_task(test.tid('Fix tap'), test.pid('owner@example.com'), 'x')$$, 'a system admin can''t be given it');
select public.reassign_task(test.tid('Fix tap'), test.pid('ali@example.com'), 'Ali has the parts');
reset role;
select test.ok((select assigned_to = test.pid('ali@example.com') from public.tasks where title = 'Fix tap')
               and not exists (select 1 from public.task_helpers where task_id = test.tid('Fix tap') and user_id = test.pid('ali@example.com')),
  'reassigned to the helper, who is no longer a helper');
select test.ok(exists (select 1 from public.email_outbox where template = 'task_assigned' and to_user = test.pid('ali@example.com')),
  'the new person gets the new task email');
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$select public.take_over_task(test.tid('Fix tap'), 'mine')$$, 'a support worker can''t take over');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select public.take_over_task(test.tid('Fix tap'), 'I''ll sort it with the plumber');
reset role;
select test.ok((select assigned_to = test.pid('boss@example.com') from public.tasks where title = 'Fix tap'), 'a manager takes it over');

-- Attachments.
select test.act_as('kim@example.com');
set role authenticated;
select test.refused($$select public.add_task_attachment(test.tid('Fix tap'), 'other/x.jpg', 'x.jpg')$$, 'files go in the task''s folder');
select public.add_task_attachment(test.tid('Fix tap'), test.tid('Fix tap')::text || '/photo.jpg', 'photo.jpg', 1234);
select test.ok((select count(*) from public.task_attachments) = 1, 'people on the task see its files');
reset role;
select test.act_as('lead@example.com');
set role authenticated;
select test.ok((select count(*) from public.task_attachments) = 0, 'others can''t');
reset role;

-- Required fields are filled in before completing (the default).
select test.act_as('kim@example.com');
set role authenticated;
select public.create_task('Wet floor', (select id from public.registries where prefix = 'RSK'), test.pid('sam@example.com'));
reset role;
select test.ok(exists (select 1 from public.tasks where title = 'Wet floor'), 'a task can be created without its required fields');
select test.ok(public.task_missing_fields(test.tid('Wet floor')) @> array['Risk rating', 'Consequence of risk', 'Effectiveness of controls'],
  'the missing fields are listed');
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$select public.set_task_status(test.tid('Wet floor'), 'completed')$$, 'it can''t be completed until they''re filled in');
select public.update_task_details(test.tid('Wet floor'), 'Wet floor', '', 'medium', null, null, null,
  'Signs put up and floor dried',
  '{"risk_rating": "Medium", "consequence": "Someone could slip", "effectiveness": "Effective"}'::jsonb);
select test.ok(cardinality(public.task_missing_fields(test.tid('Wet floor'))) = 0, 'once filled in, nothing is missing');
select test.ok(public.set_task_status(test.tid('Wet floor'), 'completed') in ('completed', 'awaiting_approval'), 'then it can be completed (or sent for approval)');
reset role;

-- The Attachments switch.
update public.features set enabled = false where key = 'attachments';
select test.act_as('kim@example.com');
set role authenticated;
select test.refused($$select public.add_task_attachment(test.tid('Fix tap'), test.tid('Fix tap')::text || '/b.jpg', 'b.jpg')$$,
  'no files while Attachments is switched off');
reset role;
update public.features set enabled = true where key = 'attachments';

\o
\echo 'All task workflow tests passed.'
