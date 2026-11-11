-- Staff Portal · © cmeproject. All rights reserved.
--
-- Phase 4 (cmeprojects): contracts (statuses, locked wording, signatures in
-- order, signed copy, new versions supersede), policies for specific people,
-- and kept versions of policy wording.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin'),
  ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('sam@example.com'), ('kim@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.cid(p_title text) returns uuid language sql security definer as $$ select id from public.contracts where title = p_title order by version desc limit 1 $$;
grant execute on all functions in schema test to authenticated;
insert into public.access_grants (area, user_id, granted_by) values ('staff_details', test.pid('boss@example.com'), test.pid('owner@example.com'));

-- ---------------------------------------------------------------------------
-- Preparing and sending
-- ---------------------------------------------------------------------------
select test.act_as('office@example.com');
set role authenticated;
select test.refused($$insert into public.contracts (user_id, title, body) values (test.pid('sam@example.com'), 'Nope', 'x')$$, 'no Staff details access: can''t prepare contracts');
reset role;

select test.act_as('boss@example.com');
set role authenticated;
insert into public.contracts (user_id, title, body, status) values (test.pid('sam@example.com'), 'Employment contract', 'Hours, pay and duties.', 'fully_signed');
select test.ok((select status = 'draft' and version = 1 from public.contracts where title = 'Employment contract'), 'a new contract always starts as a draft, version 1');
update public.contracts set body = 'Hours, pay, duties and leave.' where title = 'Employment contract';
select test.refused($$insert into public.contracts (user_id, title) values (test.pid('boss@example.com'), 'My own')$$, 'nobody prepares their own contract');
reset role;

select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.contracts) = 0, 'the employee doesn''t see drafts');
reset role;

select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.contracts set status = 'awaiting_employer' where title = 'Employment contract'$$, 'steps can''t be skipped');
update public.contracts set status = 'awaiting_employee' where title = 'Employment contract';
select test.ok((select content_hash ~ '^[0-9a-f]{64}$' and sent_by = test.pid('boss@example.com') from public.contracts where title = 'Employment contract'), 'sending fixes the SHA-256 of the exact wording');
select test.refused($$update public.contracts set body = 'Changed after sending' where title = 'Employment contract'$$, 'the wording can''t change once sent');
select test.refused($$insert into public.contract_signatures (contract_id, party, signed_name, signature_path, consent_text, content_hash, identity_check)
  select id, 'employer', 'Morgan', 'x/y.png', 'I agree to sign electronically.', content_hash, 'password' from public.contracts where title = 'Employment contract'$$, 'the employer can''t sign before the employee');
reset role;

-- ---------------------------------------------------------------------------
-- Signing
-- ---------------------------------------------------------------------------
select test.act_as('kim@example.com');
set role authenticated;
select test.ok((select count(*) from public.contracts) = 0, 'colleagues see nothing');
select test.refused($$insert into public.contract_signatures (contract_id, party, signed_name, signature_path, consent_text, content_hash, identity_check)
  values (test.cid('Employment contract'), 'employee', 'Kim', 'x/y.png', 'I agree to sign electronically.', 'abc', 'password')$$, 'nobody signs someone else''s contract');
reset role;

select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$insert into public.contract_signatures (contract_id, party, signed_name, signature_path, consent_text, content_hash, identity_check)
  select id, 'employee', 'Sam', 'x/y.png', 'I agree to sign electronically.', 'not-the-hash', 'password' from public.contracts$$, 'a signature must match the exact wording sent');
insert into public.contract_signatures (contract_id, party, signed_name, signature_path, consent_text, content_hash, identity_check, ip, user_agent)
  select id, 'employee', 'Sam Worker', 'sam/sig.png', 'I agree to sign this contract electronically.', content_hash, 'password', '203.0.113.5', 'Test browser' from public.contracts;
select test.ok((select status = 'awaiting_employer' from public.contracts), 'once the employee signs, it waits for the employer');
select test.refused($$update public.contract_signatures set signed_name = 'Someone else'$$, 'signatures can''t be changed');
select test.refused($$delete from public.contract_signatures$$, 'or deleted');
select test.refused($$update public.contracts set status = 'fully_signed', signed_pdf_path = 'x.pdf', signed_pdf_hash = repeat('a', 64)$$, 'the employee can''t complete it themselves');
reset role;

select test.act_as('boss@example.com');
set role authenticated;
insert into public.contract_signatures (contract_id, party, signed_name, signature_path, consent_text, content_hash, identity_check)
  select id, 'employer', 'Morgan Manager', 'sam/boss-sig.png', 'I agree to sign this contract electronically.', content_hash, 'authenticator' from public.contracts where title = 'Employment contract';
select test.refused($$update public.contracts set status = 'fully_signed' where title = 'Employment contract'$$, 'fully signed needs the signed copy and its SHA-256');
update public.contracts set status = 'fully_signed', signed_pdf_path = test.pid('sam@example.com')::text || '/c/signed.pdf', signed_pdf_hash = repeat('b', 64) where title = 'Employment contract';
select test.ok((select status = 'fully_signed' and completed_at is not null from public.contracts where title = 'Employment contract'), 'fully signed with its signed copy');
select test.refused($$update public.contracts set signed_pdf_hash = repeat('c', 64) where title = 'Employment contract'$$, 'the signed copy can''t be swapped');
select test.refused($$update public.contracts set status = 'cancelled' where title = 'Employment contract'$$, 'a signed contract can''t be cancelled');
select test.refused($$delete from public.contracts where title = 'Employment contract'$$, 'or deleted');

-- A revised contract is a new version with a new signing process.
insert into public.contracts (user_id, title, body, supersedes) select test.pid('sam@example.com'), 'Employment contract', 'New pay rate.', id from public.contracts where title = 'Employment contract';
select test.ok((select version from public.contracts where body = 'New pay rate.') = 2, 'a revision is version 2');
select test.ok((select status from public.contracts where version = 1 and title = 'Employment contract') = 'fully_signed', 'the signed version 1 stays until version 2 is signed');
update public.contracts set status = 'awaiting_employee' where version = 2;
reset role;
select test.act_as('sam@example.com');
set role authenticated;
insert into public.contract_signatures (contract_id, party, signed_name, signature_path, consent_text, content_hash, identity_check)
  select id, 'employee', 'Sam Worker', 'sam/sig2.png', 'I agree to sign this contract electronically.', content_hash, 'password' from public.contracts where version = 2;
reset role;
select test.act_as('boss@example.com');
set role authenticated;
insert into public.contract_signatures (contract_id, party, signed_name, signature_path, consent_text, content_hash, identity_check)
  select id, 'employer', 'Morgan Manager', 'sam/boss2.png', 'I agree to sign this contract electronically.', content_hash, 'password' from public.contracts where version = 2;
update public.contracts set status = 'fully_signed', signed_pdf_path = 'x/v2.pdf', signed_pdf_hash = repeat('d', 64) where version = 2;
reset role;
select test.ok((select status from public.contracts where version = 1 and title = 'Employment contract') = 'superseded', 'signing version 2 supersedes version 1');

-- Expiry: not signed by its date.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.contracts (user_id, title, body, sign_by) values (test.pid('kim@example.com'), 'Casual agreement', 'Terms.', public.local_today() + 1);
update public.contracts set status = 'awaiting_employee' where title = 'Casual agreement';
reset role;
select set_config('request.jwt.claims', '', false);
update public.contracts set sign_by = public.local_today() - 1 where title = 'Casual agreement';
select public.run_compliance_alerts();
select test.ok((select status from public.contracts where title = 'Casual agreement') = 'expired', 'unsigned past its date: expired');

-- Signed out.
set role anon;
select test.refused($$select count(*) from public.contracts$$, 'signed out: no contracts');
select test.refused($$select count(*) from public.contract_signatures$$, 'signed out: no signatures');
reset role;

-- ---------------------------------------------------------------------------
-- Policies: specific people, and versions kept
-- ---------------------------------------------------------------------------
insert into public.compliance_items (kind, title, body, applies_people, active, created_by)
values ('read', 'Privacy policy', 'Version one wording.', array[test.pid('sam@example.com')], true, null);
select test.ok(exists (select 1 from public.compliance_status(test.pid('sam@example.com')) where title = 'Privacy policy'), 'a policy for a specific person applies to them');
select test.ok(not exists (select 1 from public.compliance_status(test.pid('kim@example.com')) where title = 'Privacy policy'), 'and not to anyone else');
update public.compliance_items set version = version + 1, body = 'Version two wording.' where title = 'Privacy policy';
select test.ok((select count(*) from public.compliance_item_versions v join public.compliance_items i on i.id = v.item_id where i.title = 'Privacy policy') = 2
  and exists (select 1 from public.compliance_item_versions where body = 'Version one wording.'), 'each version''s wording is kept');
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$update public.compliance_item_versions set body = 'x'$$, 'kept versions can''t be changed');
reset role;
