-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 124, Stage 6): Allied Health access (premium package).

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('cm@example.com', 'Casey', 'support_worker'),
  ('sam@example.com', 'Sam', 'support_worker'), ('ot@example.com', 'Olivia', 'external'), ('psy@example.com', 'Priya', 'external');
insert into auth.users (email) values ('boss@example.com'), ('cm@example.com'), ('sam@example.com'), ('ot@example.com'), ('psy@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.cid(p_name text) returns uuid language sql security definer as $$ select id from public.car_clients where name = p_name $$;
create function test.n(p_email text, p_sql text, p_aal text default 'aal2') returns bigint language plpgsql as $$
declare v bigint;
begin
  perform test.act_as(p_email, p_aal);
  execute 'set local role authenticated';
  execute 'select ' || p_sql into v;
  execute 'reset role';
  return v;
end $$;
grant execute on all functions in schema test to authenticated;
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Case Manager') where email = 'cm@example.com';
insert into public.car_clients (name) values ('Zara North'), ('Alex South');
insert into public.client_assignments (client_id, user_id) values (test.cid('Zara North'), test.pid('cm@example.com'));
insert into public.client_details (client_id, date_of_birth) values (test.cid('Zara North'), '1990-01-01'), (test.cid('Alex South'), '1991-01-01');
insert into public.client_documents (client_id, title, file_path, file_name, mime_type, size_bytes, shared_with_practitioners)
values (test.cid('Zara North'), 'Shared plan', test.cid('Zara North') || '/a.pdf', 'a.pdf', 'application/pdf', 10, true),
       (test.cid('Zara North'), 'Private', test.cid('Zara North') || '/b.pdf', 'b.pdf', 'application/pdf', 10, false);

select test.ok((select premium from public.features where key = 'allied_health'), 'Allied Health access is a premium package');
select test.ok(test.n('ot@example.com', '(select count(*) from public.car_clients)') = 0, 'a practitioner sees no clients until given access');

-- Giving access.
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$insert into public.client_external_access (client_id, user_id, ends_on, consent_on) values (test.cid('Zara North'), test.pid('ot@example.com'), current_date + 30, current_date)$$, 'other staff can''t give access');
reset role;
select test.act_as('cm@example.com');
set role authenticated;
select test.refused($$insert into public.client_external_access (client_id, user_id, ends_on, consent_on) values (test.cid('Alex South'), test.pid('ot@example.com'), current_date + 30, current_date)$$, 'a case manager can''t give access to a client they aren''t assigned');
select test.refused($$insert into public.client_external_access (client_id, user_id, ends_on, consent_on) values (test.cid('Zara North'), test.pid('ot@example.com'), current_date + 400, current_date)$$, 'at most 12 months');
select test.refused($$insert into public.client_external_access (client_id, user_id, ends_on, consent_on) values (test.cid('Zara North'), test.pid('sam@example.com'), current_date + 30, current_date)$$, 'only to practitioner (external) accounts');
insert into public.client_external_access (client_id, user_id, ends_on, consent_on, sections) values (test.cid('Zara North'), test.pid('ot@example.com'), current_date + 180, current_date, '{details,documents}');
reset role;
select test.ok((select count(*) from public.client_external_access) = 1, 'the case manager gives access to their client');

select test.ok(test.n('ot@example.com', '(select count(*) from public.car_clients)') = 1, 'the practitioner sees that client only');
select test.ok(test.n('ot@example.com', '(select count(*) from public.car_clients)', 'aal1') = 0, 'and nothing without two-factor sign-in');
select test.ok(test.n('ot@example.com', '(select count(*) from public.client_details)') = 1, 'sections given: details');
select test.ok(test.n('ot@example.com', '(select count(*) from public.client_documents)') = 1, 'only shared documents');
select test.ok(test.n('ot@example.com', '(select count(*) from public.client_funding)') = 0, 'never funding');
select test.ok(test.n('psy@example.com', '(select count(*) from public.car_clients)') = 0, 'another practitioner sees nothing');

-- Reports and notes.
select test.act_as('ot@example.com');
set role authenticated;
insert into public.client_documents (client_id, doc_type, title, file_path, file_name, mime_type, size_bytes)
values (test.cid('Zara North'), 'report', 'OT report', test.cid('Zara North') || '/c.pdf', 'c.pdf', 'application/pdf', 10);
select test.refused($$insert into public.client_documents (client_id, doc_type, title, file_path, file_name, mime_type, size_bytes) values (test.cid('Alex South'), 'report', 'X', test.cid('Alex South') || '/d.pdf', 'd.pdf', 'application/pdf', 10)$$, 'no uploads for other clients');
select test.refused($$update public.client_documents set shared_with_practitioners = true where title = 'OT report'$$, 'a practitioner can''t change documents');
insert into public.client_practitioner_notes (client_id, body) values (test.cid('Zara North'), 'Session went well.');
update public.client_practitioner_notes set body = 'Session went well. Next in two weeks.';
reset role;
select test.ok((select count(*) from public.client_documents where title = 'OT report' and uploaded_by = test.pid('ot@example.com')) = 1, 'the practitioner uploads a report');
select test.ok((select body from public.client_practitioner_notes) = 'Session went well. Next in two weeks.', 'and writes and changes their own note');
set session_replication_role = replica;
update public.client_practitioner_notes set created_at = now() - interval '2 days';
set session_replication_role = origin;
select test.act_as('ot@example.com');
set role authenticated;
select test.refused($$update public.client_practitioner_notes set body = 'changed'$$, 'notes can''t be changed after 24 hours');
reset role;
select test.ok(test.n('psy@example.com', '(select count(*) from public.client_practitioner_notes)') = 0, 'other practitioners can''t read the note');
select test.ok(test.n('cm@example.com', '(select count(*) from public.client_practitioner_notes)') = 1, 'the case manager reads it');

-- Reminders.
select set_config('request.jwt.claims', '', false);
create temp table r as select public.run_practitioner_alerts() as v;
select test.ok((select (v ->> 'given')::int from r) = 1, 'the practitioner is told access was given');
select test.ok(not has_function_privilege('authenticated', 'public.run_practitioner_alerts()', 'execute'), 'reminders run on the server only');
select test.ok((select count(*) from public.notifications where user_id = test.pid('cm@example.com') and kind = 'practitioner_note') = 1, 'the case manager hears about the note');

-- Ending, switching off, archiving.
select test.act_as('cm@example.com');
set role authenticated;
update public.client_external_access set ended_at = now();
reset role;
select test.ok(test.n('ot@example.com', '(select count(*) from public.car_clients)') = 0, 'ended access stops at once');
insert into public.client_external_access (client_id, user_id, ends_on, consent_on, given_by) values (test.cid('Zara North'), test.pid('ot@example.com'), current_date + 30, current_date, test.pid('boss@example.com'));
update public.features set enabled = false where key = 'allied_health';
select test.ok(test.n('ot@example.com', '(select count(*) from public.car_clients)') = 0, 'package off: practitioners see nothing');
update public.features set enabled = true where key = 'allied_health';
select test.ok(test.n('ot@example.com', '(select count(*) from public.car_clients)') = 1, 'package on again: access is back');
select test.act_as('boss@example.com');
update public.car_clients set status = 'discharged', archive_reason = 'other', archive_note = 'Moved away' where name = 'Zara North';
select test.ok(test.n('ot@example.com', '(select count(*) from public.client_documents)') = 0, 'archived client: practitioners see nothing');

\o
select 'All Allied Health tests passed.';
