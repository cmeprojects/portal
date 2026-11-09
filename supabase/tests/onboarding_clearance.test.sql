-- Staff Portal · © cmeproject. All rights reserved.
--
-- Onboarding, compliance and clearance to work (cmeprojects, update 58).

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan Manager', 'manager'), ('office@example.com', 'Olive Office', 'staff_admin'),
  ('new@example.com', 'Nia New', 'new_starter'), ('sam@example.com', 'Sam Worker', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('new@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function public.give_role_for_test(p uuid) returns void language plpgsql security definer set search_path = '' as $$
begin perform set_config('app.conditional_role', 'on', true); update public.profiles set role = 'support_worker' where id = p; end $$;
grant execute on all functions in schema test to authenticated;

-- Defaults were added once: the NDIS training (mandatory, certificate needed)
-- and common documents and a sample agreement, switched off.
select test.ok((select count(*) = 1 from public.compliance_items where title like 'NDIS Worker Orientation%' and before_work and certificate = 'required'), 'the NDIS orientation training is a default, needed before working');
select test.ok((select count(*) = 7 from public.compliance_items where kind = 'upload' and not active and category <> ''), 'common documents are added, switched off');
select test.ok((select count(*) = 1 from public.compliance_items where kind = 'agreement' and not active), 'a sample agreement is added, switched off');

-- Set up: only these items apply.
update public.compliance_items set active = false;
alter table public.compliance_items disable trigger compliance_items_guard;
insert into public.compliance_items (id, kind, title, body, before_work, certificate, needs_expiry, needs_number, active, sort_order) values
  ('00000000-0000-0000-0000-0000000000a1', 'read', 'Code of conduct', 'Be kind.', true, 'optional', false, false, true, 1),
  ('00000000-0000-0000-0000-0000000000a2', 'training', 'NDIS orientation', '', true, 'none', false, false, true, 2),
  ('00000000-0000-0000-0000-0000000000a3', 'upload', 'Screening check', '', true, 'optional', true, true, true, 3),
  ('00000000-0000-0000-0000-0000000000a4', 'upload', 'Driver''s licence', '', false, 'optional', false, false, true, 4),
  ('00000000-0000-0000-0000-0000000000a5', 'agreement', 'Employment agreement', 'Terms.', true, 'optional', false, false, true, 5);
alter table public.compliance_items enable trigger compliance_items_guard;
update public.registries set cleared_only = true where is_default and kind = 'tasks';

select test.ok((select certificate = 'required' from public.compliance_items where id = '00000000-0000-0000-0000-0000000000a2'), 'a mandatory training always asks for a certificate, whatever it was set to');
select test.ok(not public.can_work(test.pid('new@example.com')), 'a new starter isn''t cleared to work');
select test.ok(public.can_work(test.pid('sam@example.com')) is false, 'staff added after the update need clearing too');

-- Policies: opening is separate from acknowledging; a typed name is needed.
select test.act_as('new@example.com');
set role authenticated;
select test.refused($$select public.acknowledge_policy('00000000-0000-0000-0000-0000000000a1', 'Nia New')$$, 'can''t acknowledge a policy before opening it');
select public.open_compliance_item('00000000-0000-0000-0000-0000000000a1');
select test.refused($$select public.acknowledge_policy('00000000-0000-0000-0000-0000000000a1', 'Someone Else')$$, 'the typed name must be theirs');
select public.acknowledge_policy('00000000-0000-0000-0000-0000000000a1', '  nia   new ');
-- Training: a certificate is required, and it's then checked.
select test.refused($$select public.complete_training('00000000-0000-0000-0000-0000000000a2', current_date)$$, 'a training needing a certificate can''t be completed without one');
select test.refused($$select public.complete_training('00000000-0000-0000-0000-0000000000a2', current_date + 3, '', test.pid('new@example.com')::text || '/c.pdf', 'c.pdf')$$, 'the completion date can''t be in the future');
select public.complete_training('00000000-0000-0000-0000-0000000000a2', current_date - 1, 'NDIS Commission', test.pid('new@example.com')::text || '/c.pdf', 'c.pdf');
-- Documents: number and expiry needed; never verified on upload.
select test.refused($$select public.submit_document('00000000-0000-0000-0000-0000000000a3', test.pid('new@example.com')::text || '/s.pdf', 's.pdf', current_date + 400)$$, 'a document needing a number can''t be sent without it');
select public.submit_document('00000000-0000-0000-0000-0000000000a3', test.pid('new@example.com')::text || '/s.pdf', 's.pdf', current_date + 400, null, 'NWS-123');
-- Agreement: opened, typed name, drawn signature in their own folder.
select public.open_compliance_item('00000000-0000-0000-0000-0000000000a5');
select test.refused($$select public.sign_agreement('00000000-0000-0000-0000-0000000000a5', 'Nia New', 'someone/signature-1.png')$$, 'the signature must be their own upload');
select public.sign_agreement('00000000-0000-0000-0000-0000000000a5', 'Nia New', test.pid('new@example.com')::text || '/signature-1.png', 'iPhone');
reset role;

select test.ok((select status = 'submitted' and doc_number = 'NWS-123' from public.compliance_records where item_id = '00000000-0000-0000-0000-0000000000a3'), 'the upload is waiting to be checked, with its number');
select test.ok((select signature_path is not null and length(content_hash) = 64 and signed_name = 'Nia New' and signed_from like '%iPhone%' from public.compliance_records where item_id = '00000000-0000-0000-0000-0000000000a5'), 'the signature records the image, name, version fingerprint and device');
select test.ok((select length(content_hash) = 64 from public.compliance_records where item_id = '00000000-0000-0000-0000-0000000000a1'), 'the acknowledgement records which version was read');
select test.ok(public.onboarding_missing(test.pid('new@example.com')) = array['Driver''s licence'], 'only the licence is left for onboarding');
select test.ok(public.before_work_missing(test.pid('new@example.com')) = array['NDIS orientation', 'Screening check'], 'what''s needed before working must also be checked');
select test.ok(not public.compliance_is_verified(test.pid('new@example.com')), 'not verified while things wait to be checked');

-- Clearance: not before the checks, and only by authorised people.
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$select public.grant_clearance(test.pid('new@example.com'))$$, 'can''t clear someone before the checks are done');
reset role;
select test.act_as('office@example.com');
set role authenticated;
select public.review_compliance_upload((select id from public.compliance_records where item_id = '00000000-0000-0000-0000-0000000000a2'), true);
select public.request_replacement((select id from public.compliance_records where item_id = '00000000-0000-0000-0000-0000000000a3'), 'Blurry photo');
reset role;
select test.ok(public.onboarding_missing(test.pid('new@example.com')) @> array['Screening check'], 'a replacement request puts the document back on their list');
select test.act_as('new@example.com');
set role authenticated;
select public.submit_document('00000000-0000-0000-0000-0000000000a3', test.pid('new@example.com')::text || '/s2.pdf', 's2.pdf', current_date + 400, null, 'NWS-123');
reset role;
select test.ok((select count(*) = 2 from public.compliance_records where item_id = '00000000-0000-0000-0000-0000000000a3'), 'the history keeps both uploads');
select test.act_as('office@example.com');
set role authenticated;
select public.review_compliance_upload((select max(id) from public.compliance_records where item_id = '00000000-0000-0000-0000-0000000000a3'), true);
select test.refused($$select public.grant_clearance(test.pid('new@example.com'))$$, 'a staff admin can''t clear people unless delegated');
reset role;
select test.ok(public.before_work_missing(test.pid('new@example.com')) = '{}', 'everything needed before working is done and checked');

select test.act_as('boss@example.com');
set role authenticated;
select public.grant_clearance(test.pid('new@example.com'), 'All checks done');
reset role;
select test.ok(public.can_work(test.pid('new@example.com')), 'cleared to work');
select test.ok((select count(*) = 0 from public.tasks where assigned_to = test.pid('new@example.com')), 'a new starter isn''t given the task yet');
select test.act_as('boss@example.com');
set role authenticated;
select public.give_role_for_test(test.pid('new@example.com'));
reset role;
select test.ok((select count(*) = 1 from public.tasks where assigned_to = test.pid('new@example.com') and title = 'Finish onboarding' and due_date = public.local_today() + 7), 'once they get a role, the rest becomes a Finish onboarding task due within a week');
select test.ok((select count(*) >= 1 from public.audit_log where action = 'cleared_to_work'), 'clearance is in the change log');

-- Delegation lets staff admins clear people.
update public.app_settings set value = '["staff_admin"]' where key = 'compliance.clearance_roles';
select test.act_as('office@example.com');
set role authenticated;
select test.ok(public.can_grant_clearance(), 'a delegated staff admin can clear people');
reset role;

-- Duty restrictions and overrides.
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$select public.create_task('Visit', (select id from public.registries where is_default and kind = 'tasks' limit 1), test.pid('sam@example.com'), '', 'medium', current_date + 2)$$, 'a cleared-only register can''t be given to someone not cleared');
select test.refused($$select public.grant_work_override(test.pid('sam@example.com'), 'x', current_date + 5)$$, 'an override needs a real reason');
select test.refused($$select public.grant_work_override(test.pid('sam@example.com'), 'Short staffed tonight', current_date + 60)$$, 'an override lasts at most 30 days');
select public.grant_work_override(test.pid('sam@example.com'), 'Short staffed tonight', current_date + 5);
select public.create_task('Visit', (select id from public.registries where is_default and kind = 'tasks' limit 1), test.pid('sam@example.com'), '', 'medium', current_date + 2);
reset role;
select test.ok(public.can_work(test.pid('sam@example.com')), 'an override lets them work for now');
select test.ok((select count(*) >= 1 from public.audit_log where action = 'work_override_given'), 'overrides are in the change log');
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$select public.grant_work_override(test.pid('new@example.com'), 'I want to', current_date + 1)$$, 'support workers can''t give overrides');
select test.ok((public.work_status(test.pid('sam@example.com')) ->> 'can_work')::boolean, 'people see their own work status');
select test.ok(public.work_status(test.pid('new@example.com')) is null, 'but not other people''s');
reset role;

-- Expiry: a before-work document that expires stops someone working.
update public.compliance_records set expires_on = current_date - 1 where item_id = '00000000-0000-0000-0000-0000000000a3';
select test.ok(not public.can_work(test.pid('new@example.com')), 'an expired screening check stops them being cleared for duties');

-- Cars for cleared staff only.
update public.app_settings set value = 'true' where key = 'cars.cleared_only';
select test.ok(exists (select 1 from pg_trigger where tgname = 'guard_cleared_trips'), 'car trips are checked for clearance');
