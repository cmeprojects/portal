-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects step 4: Contracts follow the Access page, each ability its own
-- tick (view, prepare and send, sign for the employer, download), never
-- included by giving the whole HR category.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('boss2@example.com', 'Max', 'manager'), ('boss3@example.com', 'Mia', 'manager'),
  ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('boss2@example.com'), ('boss3@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.cid(p_title text) returns uuid language sql security definer as $$ select id from public.contracts where title = p_title order by version desc limit 1 $$;
grant execute on all functions in schema test to authenticated;

select test.act_as('owner@example.com');
set role authenticated;
insert into public.admin_designations (user_id, granted_by) values (test.pid('boss@example.com'), test.pid('owner@example.com')), (test.pid('boss2@example.com'), test.pid('owner@example.com')), (test.pid('boss3@example.com'), test.pid('owner@example.com'));
-- Morgan: prepare and send only. Max: view only. Mia: the whole HR category (Contracts is sensitive, so not included).
insert into public.access_grants (module_id, user_id, granted_by, actions) values ('hr.contracts', test.pid('boss@example.com'), test.pid('owner@example.com'), array['create']);
insert into public.access_grants (module_id, user_id, granted_by, actions) values ('hr.contracts', test.pid('boss2@example.com'), test.pid('owner@example.com'), array['view']);
insert into public.access_grants (module_id, user_id, granted_by) values ('cat_hr', test.pid('boss3@example.com'), test.pid('owner@example.com'));
reset role;

select test.act_as('boss@example.com');
set role authenticated;
insert into public.contracts (user_id, title, body) values (test.pid('sam@example.com'), 'Employment contract', 'Hours, pay and duties.');
select test.ok((select count(*) from public.contracts) = 1, 'prepare and send: makes a draft and sees it');
update public.contracts set status = 'awaiting_employee' where title = 'Employment contract';
select test.ok((select status from public.contracts where title = 'Employment contract') = 'awaiting_employee', 'and sends it to sign');
reset role;

select test.act_as('sam@example.com');
set role authenticated;
insert into public.contract_signatures (contract_id, party, signed_name, signature_path, consent_text, content_hash, identity_check)
  select id, 'employee', 'Sam', test.pid('sam@example.com') || '/sig.png', 'I agree to sign electronically.', content_hash, 'password' from public.contracts where title = 'Employment contract';
reset role;

select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.contract_signatures (contract_id, party, signed_name, signature_path, consent_text, content_hash, identity_check)
  select id, 'employer', 'Morgan', 'x/y.png', 'I agree to sign electronically.', content_hash, 'password' from public.contracts where title = 'Employment contract'$$, 'without the signing tick: can''t sign for the employer');
reset role;

select test.act_as('boss2@example.com');
set role authenticated;
select test.ok((select count(*) from public.contracts) = 1, 'view only: sees the contract');
select test.refused($$insert into public.contracts (user_id, title, body) values (test.pid('sam@example.com'), 'Another', 'x')$$, 'view only: can''t prepare one');
select test.refused($$update public.contracts set status = 'cancelled' where title = 'Employment contract'$$, 'view only: can''t cancel');
reset role;

select test.act_as('boss3@example.com');
set role authenticated;
select test.ok((select count(*) from public.contracts) = 0, 'the whole HR category doesn''t include Contracts (sensitive)');
reset role;

-- Max is given the signing tick as well.
select test.act_as('owner@example.com');
set role authenticated;
update public.access_grants set revoked_at = now() where module_id = 'hr.contracts' and user_id = test.pid('boss2@example.com');
insert into public.access_grants (module_id, user_id, granted_by, actions) values ('hr.contracts', test.pid('boss2@example.com'), test.pid('owner@example.com'), array['view', 'sign_for_employer']);
reset role;
select test.act_as('boss2@example.com');
set role authenticated;
insert into public.contract_signatures (contract_id, party, signed_name, signature_path, consent_text, content_hash, identity_check)
  select id, 'employer', 'Max', test.pid('sam@example.com') || '/emp.png', 'I agree to sign electronically.', content_hash, 'password' from public.contracts where title = 'Employment contract';
select test.ok((select count(*) from public.contract_signatures where party = 'employer') = 1, 'with the signing tick: signs for the employer');
reset role;

select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.contracts) = 1, 'the employee still sees their own contract');
reset role;
