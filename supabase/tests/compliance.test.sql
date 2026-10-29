-- Staff Portal · © cmeproject. All rights reserved.
--
-- Onboarding and Compliance: reading, trainings, uploads, who sees what,
-- the onboarding check on a first role, and conditional roles.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin'),
  ('lead@example.com', 'Taylor', 'team_leader'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('lead@example.com'), ('sam@example.com');
insert into public.teams (name) values ('Team A');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.item(p_title text) returns uuid language sql security definer as $$ select id from public.compliance_items where title = p_title $$;
create function test.notes(p_email text, p_kind text) returns bigint language sql security definer as $$
  select count(*) from public.notifications where user_id = test.pid(p_email) and kind = p_kind $$;
grant execute on all functions in schema test to authenticated;
update public.profiles set joined_at = null;

-- A team leader can't invite until the system admin allows it.
select test.act_as('lead@example.com');
set role authenticated;
select test.refused($$insert into public.invitations (email) values ('x@example.com')$$, 'a team leader cannot invite by default');
reset role;
update public.app_settings set value = '["staff_admin", "manager", "team_leader"]' where key = 'people.invite_roles';
select test.act_as('lead@example.com');
set role authenticated;
select test.refused($$insert into public.invitations (email, role) values ('x@example.com', 'support_worker')$$,
  'an allowed team leader still can''t invite into a role');
insert into public.invitations (email, full_name) values ('nico@example.com', 'Nico');
reset role;

-- Nico joins; the staff admin (and the inviter) are told by bell and email.
insert into auth.users (email) values ('nico@example.com');
select test.act_as('nico@example.com');
set role authenticated;
select public.mark_joined();
select public.mark_joined();
reset role;
select test.ok(test.notes('office@example.com', 'joined') = 1 and test.notes('lead@example.com', 'joined') = 1,
  'the staff admin and the inviter hear once that someone joined');
select test.ok(exists (select 1 from public.email_outbox where template = 'notice' and to_user = test.pid('office@example.com')),
  'and get an email');

-- The staff admin sets up onboarding.
select test.act_as('office@example.com');
set role authenticated;
insert into public.compliance_items (kind, title, body) values ('read', 'Code of Conduct', 'Be kind.');
insert into public.compliance_items (kind, title, link_url) values ('training', 'Manual handling', 'https://example.com/mh');
insert into public.compliance_items (kind, title, needs_expiry) values ('upload', 'Police check', true);
insert into public.compliance_items (kind, title, applies_roles) values ('upload', 'Driver''s licence', '{support_worker}');
reset role;
select test.ok(test.notes('nico@example.com', 'onboarding_item') = 3, 'a new starter is told about the items that apply to them');
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.compliance_items (kind, title) values ('read', 'x')$$,
  'a manager cannot manage Compliance by default');
reset role;

-- Nico works through it.
select test.act_as('nico@example.com');
set role authenticated;
select test.ok((select count(*) from public.compliance_status(test.pid('nico@example.com'))) = 3, 'a new starter has three items');
select public.confirm_compliance_item(test.item('Code of Conduct'));
select test.refused($$select public.submit_compliance_upload(test.item('Police check'), test.pid('sam@example.com')::text || '/x.pdf', 'x.pdf', current_date + 400)$$,
  'you can only record a file in your own folder');
select test.refused($$select public.submit_compliance_upload(test.item('Police check'), test.pid('nico@example.com')::text || '/x.pdf', 'x.pdf')$$,
  'an expiry date is needed where asked for');
select public.submit_compliance_upload(test.item('Police check'), test.pid('nico@example.com')::text || '/pc.pdf', 'pc.pdf', current_date + 400);
select test.ok((select count(*) from public.compliance_records) = 2, 'a new starter sees their own records');
reset role;
select test.ok(public.onboarding_missing(test.pid('nico@example.com')) = array['Manual handling'], 'one thing still missing');

-- Managers and team leaders see progress, not files.
select test.act_as('boss@example.com');
set role authenticated;
select test.ok((select count(*) from public.compliance_status(test.pid('nico@example.com'))) = 3, 'a manager sees someone''s progress');
select test.ok((select count(*) from public.compliance_records) = 0, 'a manager cannot see the uploaded files');
reset role;
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.compliance_status(test.pid('nico@example.com'))) = 0, 'a support worker cannot see other people''s progress');
reset role;

-- No role until onboarding is finished.
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.profiles set role = 'support_worker' where email = 'nico@example.com'$$,
  'a role can''t be given before onboarding is finished');
reset role;

-- A conditional role: the staff admin asks, with a reason and deadline.
select test.act_as('office@example.com');
set role authenticated;
select test.refused($$select public.give_conditional_role(test.pid('nico@example.com'), 'support_worker', null, '{}', '', current_date + 14)$$,
  'a reason is needed');
select test.refused($$select public.give_conditional_role(test.pid('nico@example.com'), 'support_worker', null, '{}', 'Rostered Monday', current_date - 1)$$,
  'the deadline can''t be in the past');
select public.give_conditional_role(test.pid('nico@example.com'), 'support_worker', null,
  array[(select id from public.teams where name = 'Team A')], 'Rostered Monday', current_date + 14);
reset role;
select test.ok((select role = 'new_starter' from public.profiles where email = 'nico@example.com'), 'nothing changes until a manager approves');
select test.ok((select (to_value -> 'missing') = '["Manual handling", "Driver''s licence"]'::jsonb from public.people_change_requests where kind = 'conditional'),
  'the request lists what''s missing for the new role');
select test.ok(test.notes('boss@example.com', 'approval_needed') = 1, 'the manager is told an approval is needed');

select test.act_as('boss@example.com');
set role authenticated;
select public.decide_change_request((select id from public.people_change_requests where kind = 'conditional'), true);
reset role;
select test.ok((select role = 'support_worker' from public.profiles where email = 'nico@example.com'), 'approved: the role is given');
select test.ok(exists (select 1 from public.team_members where user_id = test.pid('nico@example.com')), 'and the team');
select test.ok((select priority = 'medium' and due_date = current_date + 14 and assigned_to = test.pid('nico@example.com')
                  from public.tasks where title = 'Finish onboarding'),
  'a medium "Finish onboarding" task is due on the deadline');

-- Finishing onboarding closes the task and tells the staff admin.
select test.act_as('nico@example.com');
set role authenticated;
select public.confirm_compliance_item(test.item('Manual handling'));
select public.submit_compliance_upload(test.item('Driver''s licence'), test.pid('nico@example.com')::text || '/dl.jpg', 'dl.jpg');
reset role;
select test.ok((select status = 'completed' from public.tasks where title = 'Finish onboarding'), 'finishing onboarding completes the task');
select test.ok(test.notes('office@example.com', 'onboarded') = 1, 'the staff admin hears onboarding is finished');

-- Checking uploads.
select test.act_as('office@example.com');
set role authenticated;
select test.refused($$select public.review_compliance_upload((select max(id) from public.compliance_records), false, '')$$,
  'a rejected upload needs a reason');
select public.review_compliance_upload((select max(id) from public.compliance_records), false, 'The photo is blurry');
reset role;
select test.ok(test.notes('nico@example.com', 'upload_rejected') = 1, 'the person is told to upload again');
select test.ok(public.onboarding_missing(test.pid('nico@example.com')) = array['Driver''s licence'], 'a rejected upload counts as missing again');

-- A new version must be confirmed again.
select test.act_as('office@example.com');
set role authenticated;
update public.compliance_items set version = version + 1, body = 'Be kind and safe.' where title = 'Code of Conduct';
reset role;
select test.ok((select state = 'update' from public.compliance_status(test.pid('nico@example.com')) where title = 'Code of Conduct'),
  'an updated document needs confirming again');

-- Expiry reminders.
update public.compliance_records set expires_on = current_date + 10 where file_name = 'pc.pdf';
select public.run_compliance_alerts();
select public.run_compliance_alerts();
select test.ok(test.notes('nico@example.com', 'document_expiring') = 1, 'one reminder before a document expires');
update public.compliance_records set expires_on = current_date - 1 where file_name = 'pc.pdf';
select public.run_compliance_alerts();
select test.ok(test.notes('nico@example.com', 'document_expired') = 1
               and exists (select 1 from public.email_outbox where template = 'notice' and to_user = test.pid('nico@example.com')
                             and data ->> 'title' like 'Police check has expired'),
  'an expired document is a bell and an email');

-- The system admin lets managers manage Compliance.
update public.app_settings set value = '["staff_admin", "manager"]' where key = 'compliance.manager_roles';
select test.act_as('boss@example.com');
set role authenticated;
insert into public.compliance_items (kind, title) values ('read', 'Privacy policy');
reset role;
select test.ok(test.item('Privacy policy') is not null, 'with the setting on, a manager manages Compliance');

-- Uploading for someone.
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$select public.submit_compliance_upload_for(test.pid('nico@example.com'), test.item('Police check'), test.pid('nico@example.com')::text || '/x.pdf', 'x.pdf', current_date + 300)$$,
  'a support worker can''t upload for someone');
reset role;
select test.act_as('office@example.com');
set role authenticated;
select public.submit_compliance_upload_for(test.pid('nico@example.com'), test.item('Police check'), test.pid('nico@example.com')::text || '/pc2.pdf', 'pc2.pdf', current_date + 300);
reset role;
select test.ok((select status = 'accepted' and uploaded_by = test.pid('office@example.com') from public.compliance_records where file_name = 'pc2.pdf'),
  'a staff admin''s upload for someone counts as checked');
select test.ok(test.notes('nico@example.com', 'uploaded_for_you') = 1, 'the person is told');
update public.app_settings set value = '["staff_admin"]' where key = 'compliance.manager_roles';
select test.act_as('boss@example.com');
set role authenticated;
select public.submit_compliance_upload_for(test.pid('nico@example.com'), test.item('Driver''s licence'), test.pid('nico@example.com')::text || '/dl2.jpg', 'dl2.jpg');
reset role;
select test.ok((select status = 'submitted' from public.compliance_records where file_name = 'dl2.jpg'), 'a manager''s upload still gets checked');

-- Expiring: bell and email for the person.
update public.compliance_records set expires_on = current_date + 5 where file_name = 'pc2.pdf';
delete from public.email_outbox;
select public.run_compliance_alerts();
select test.ok(exists (select 1 from public.email_outbox where template = 'notice' and to_user = test.pid('nico@example.com')
                         and data ->> 'title' like 'Police check expires soon'), 'an expiring document is emailed to the person');

\o
\echo 'All compliance tests passed.'
