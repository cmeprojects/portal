-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 112): client documents and their expiry reminders
-- (Care block C3). File storage rules are checked on a Supabase copy.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin'),
  ('sam@example.com', 'Sam', 'support_worker'), ('cm@example.com', 'Casey', 'support_worker'), ('io@example.com', 'Ira', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('sam@example.com'), ('cm@example.com'), ('io@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.cid(p_name text) returns uuid language sql security definer as $$ select id from public.car_clients where name = p_name $$;
create function test.n(p_email text, p_sql text) returns bigint language plpgsql as $$
declare v bigint;
begin
  perform test.act_as(p_email);
  execute 'set local role authenticated';
  execute 'select ' || p_sql into v;
  execute 'reset role';
  return v;
end $$;
grant execute on all functions in schema test to authenticated;
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Case Manager') where email = 'cm@example.com';
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Intake & Assessment Officer') where email = 'io@example.com';
insert into public.teams (name) values ('North');
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'North';
insert into public.car_clients (name) values ('Zara North'), ('Alex South');
insert into public.client_teams (client_id, team_id) select test.cid('Zara North'), id from public.teams where name = 'North';

select test.ok((select sensitivity from public.app_modules where id = 'clients.documents') = 'sensitive', 'Client documents is sensitive');

-- Intake adds one; manager adds one.
select test.act_as('io@example.com');
set role authenticated;
insert into public.client_documents (client_id, title, doc_type, file_path, file_name, mime_type, size_bytes, expires_on)
values (test.cid('Zara North'), 'Consent form', 'consent', test.cid('Zara North') || '/1-consent.pdf', 'consent.pdf', 'application/pdf', 1000, current_date + 10);
select test.refused($$insert into public.client_documents (client_id, title, file_path, file_name, mime_type, size_bytes) values (test.cid('Zara North'), 'X', test.cid('Alex South') || '/2-x.pdf', 'x.pdf', 'application/pdf', 10)$$, 'a file must be in that client''s folder');
reset role;
select test.ok((select uploaded_by = test.pid('io@example.com') from public.client_documents where title = 'Consent form'), 'intake adds a document (recorded as theirs)');

-- Who sees them.
select test.ok(test.n('boss@example.com', '(select count(*) from public.client_documents)') = 1, 'manager sees it');
select test.ok(test.n('office@example.com', '(select count(*) from public.client_documents)') = 0, 'staff admin doesn''t (D-052)');
select test.ok(test.n('sam@example.com', '(select count(*) from public.client_documents)') = 0, 'team staff don''t (sensitive)');
select test.ok(test.n('cm@example.com', '(select count(*) from public.client_documents)') = 0, 'case manager without the assignment doesn''t');
select test.act_as('io@example.com');
set role authenticated;
insert into public.client_assignments (client_id, user_id) values (test.cid('Zara North'), test.pid('cm@example.com'));
reset role;
select test.ok(test.n('cm@example.com', '(select count(*) from public.client_documents)') = 1, 'assigned: the case manager sees it');

-- Versions, archiving, nothing deleted, file never changed.
select test.act_as('cm@example.com');
set role authenticated;
insert into public.client_documents (client_id, title, doc_type, file_path, file_name, mime_type, size_bytes, replaces_id)
values (test.cid('Zara North'), 'Consent form', 'consent', test.cid('Zara North') || '/3-consent-v2.pdf', 'consent-v2.pdf', 'application/pdf', 1200,
        (select id from public.client_documents where file_name = 'consent.pdf'));
update public.client_documents set archived_at = now() where file_name = 'consent.pdf';
select test.refused($$update public.client_documents set file_path = test.cid('Zara North') || '/9-other.pdf' where file_name = 'consent-v2.pdf'$$, 'a document''s file never changes');
select test.refused($$delete from public.client_documents$$, 'documents are never deleted');
reset role;
select test.ok((select version from public.client_documents where file_name = 'consent-v2.pdf') = 2, 'a new version counts up');
select test.ok((select archived_by = test.pid('cm@example.com') from public.client_documents where file_name = 'consent.pdf'), 'archiving records who');

-- Expiry reminders (the hourly timer, as the server).
update public.client_documents set expires_on = current_date + 5 where file_name = 'consent-v2.pdf';
select public.run_care_alerts();
select public.run_care_alerts();
select test.ok((select count(*) from public.notifications where kind = 'client_doc_expiring' and user_id = test.pid('cm@example.com')) = 1, 'one reminder before expiry, to the assigned care manager');
select test.ok((select count(*) from public.notifications where kind = 'client_doc_expiring' and user_id = test.pid('boss@example.com')) = 0, 'not to the managers while someone is assigned');
select test.ok((select count(*) from public.notifications where kind like 'client_doc_%' and title like '%Consent form%' and title not like '%NDIS%') >= 1, 'the reminder names the document, not its contents');
set role authenticated;
select test.refused($$select public.run_care_alerts()$$, 'staff can''t run the reminders');
reset role;

\o
