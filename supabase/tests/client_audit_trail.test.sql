-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 155): the client audit trail.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker'), ('cm@example.com', 'Casey', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com'), ('cm@example.com');
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
-- What the trigger wrote (read as the database owner, for checking only).
create function test.last(p_action text) returns jsonb language sql security definer as $$
  select details from public.audit_log where action = p_action order by id desc limit 1 $$;
create function test.vals(p_action text) returns jsonb language sql security definer as $$
  select v.changes from public.client_audit_values v join public.audit_log a on a.id = v.audit_id where a.action = p_action order by a.id desc limit 1 $$;
grant execute on all functions in schema test to authenticated;
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Case Manager') where email = 'cm@example.com';

-- 1. Creating a client is recorded, as the person who did it, with their role.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.car_clients (name) values ('Zara North'), ('Alex South');
reset role;
select test.ok(test.last('car_clients_added') ->> 'role' = 'manager' and test.last('car_clients_added') ->> 'outcome' = 'success', 'creating a client is recorded with the role and outcome');
select test.ok((select actor_id from public.audit_log where action = 'car_clients_added' order by id desc limit 1) = test.pid('boss@example.com'), 'as the person who did it');
insert into public.client_assignments (client_id, user_id) values (test.cid('Zara North'), test.pid('cm@example.com'));
select test.ok(test.last('client_assignments_added') is not null, 'assigning staff is recorded');

-- 2. Changing details: which fields, and the before and after values.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.client_details (client_id, gender, phone) values (test.cid('Zara North'), 'female', '0412 345 678');
update public.client_details set phone = '0498 765 432' where client_id = test.cid('Zara North');
update public.client_details set phone = '0498 765 432' where client_id = test.cid('Zara North');
reset role;
select test.ok(test.last('client_details_changed') -> 'fields' = '["phone"]'::jsonb, 'the changed field is named');
select test.ok(test.vals('client_details_changed') -> 'phone' = '["0412 345 678", "0498 765 432"]'::jsonb, 'with the before and after values');
select test.ok((select count(*) from public.audit_log where action = 'client_details_changed') = 1, 'saving with no change is not recorded');
-- The portal saves details as "add, or update if it's there": that is a change, not an addition.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.client_details (client_id, gender, phone) values (test.cid('Zara North'), 'female', '0400 000 001')
on conflict (client_id) do update set phone = excluded.phone;
reset role;
select test.ok((select count(*) from public.audit_log where action = 'client_details_added') = 1 and (select count(*) from public.audit_log where action = 'client_details_changed') = 2, 'an add-or-update save is recorded once, as a change');
select test.ok(test.vals('client_details_changed') -> 'phone' = '["0498 765 432", "0400 000 001"]'::jsonb, 'with the right before and after');

-- 3. Services, care plans, locations: added, changed, removed.
insert into public.client_locations (client_id, label, address) values (test.cid('Zara North'), 'Home', '1 Test St');
insert into public.client_services (client_id, program_id, label, start_date, location_id)
select test.cid('Zara North'), p.id, 'Daily living', current_date, l.id from public.client_programs p, public.client_locations l where p.scheme = 'ndis' and l.label = 'Home' limit 1;
update public.client_services set label = 'Daily living support' where label = 'Daily living';
select test.ok(test.last('client_locations_added') is not null and test.last('client_services_added') ->> 'item' = 'Daily living', 'a location and a service added are recorded');
select test.ok(test.vals('client_services_changed') -> 'label' = '["Daily living", "Daily living support"]'::jsonb, 'a service change keeps before and after');
insert into public.client_care_plans (client_id, title) values (test.cid('Zara North'), 'Plan 1');
update public.client_care_plans set title = 'Plan one' where title = 'Plan 1';
select test.ok(test.last('client_care_plans_changed') -> 'fields' ? 'title', 'a care plan change is recorded');
delete from public.client_assignments where client_id = test.cid('Zara North') and user_id = test.pid('cm@example.com');
select test.ok(test.vals('client_assignments_removed') -> 'user_id' -> 0 is not null, 'removing an assignment is recorded, with what was removed');
insert into public.client_assignments (client_id, user_id) values (test.cid('Zara North'), test.pid('cm@example.com'));

-- 4. Documents: uploaded, replaced, archived.
insert into public.client_documents (client_id, doc_type, title, file_path, file_name, mime_type, size_bytes, version)
values (test.cid('Zara North'), 'assessment', 'OT assessment', test.cid('Zara North') || '/ot.pdf', 'ot.pdf', 'application/pdf', 100, 1);
insert into public.client_documents (client_id, doc_type, title, file_path, file_name, mime_type, size_bytes, version, replaces_id)
select client_id, doc_type, title, client_id || '/ot2.pdf', 'ot2.pdf', 'application/pdf', 100, 2, id from public.client_documents where file_name = 'ot.pdf';
update public.client_documents set archived_at = now() where file_name = 'ot.pdf';
select test.ok(test.last('client_documents_added') ->> 'item' = 'OT assessment', 'a document upload is recorded');
select test.ok(test.last('client_documents_replaced') ->> 'version' = '2', 'a new version is recorded as replaced, with the version');
select test.ok(test.last('client_documents_archived') is not null, 'archiving a document is recorded');

-- 5. Who reads the trail.
select test.ok(test.n('owner@example.com', $$(select count(*) from public.client_audit_values)$$) > 0, 'the system admin reads the before and after values');
select test.ok(test.n('boss@example.com', $$(select count(*) from public.client_audit_values)$$) = 0, 'others don''t see the values');
select test.ok(test.n('sam@example.com', $$(select count(*) from public.audit_log where entity = 'client')$$) = 0, 'a support worker sees no trail');
select test.ok(test.n('cm@example.com', $$(select count(*) from public.audit_log where entity = 'client' and entity_id = test.cid('Alex South')::text)$$) = 0, 'a case manager sees nothing about a client outside their scope');
select test.ok(test.n('cm@example.com', $$(select count(*) from public.audit_log where entity = 'client' and entity_id = test.cid('Zara North')::text)$$) > 0, 'their assigned case manager reads that client''s trail');
select test.act_as('owner@example.com');
set role authenticated;
insert into public.admin_designations (user_id, granted_by) values (test.pid('boss@example.com'), test.pid('owner@example.com'));
reset role;
select test.ok(test.n('boss@example.com', $$(select count(*) from public.audit_log where entity = 'client' and entity_id = test.cid('Alex South')::text)$$) > 0, 'a Manager Administrator reads any client''s trail');

-- 6. Nobody changes or deletes it.
select test.act_as('owner@example.com');
set role authenticated;
select test.refused($$update public.audit_log set action = 'x' where entity = 'client'$$, 'trail entries can''t be changed');
select test.refused($$delete from public.client_audit_values$$, 'or the values deleted');
reset role;
select test.ok((select count(*) from public.client_audit_values) > 0, 'the values are all still there');

-- 7. Opening the trail is recorded.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.client_staff_views (client_id, area) values (test.cid('Zara North'), 'audit_trail');
reset role;
select test.ok((select count(*) from public.client_staff_views where area = 'audit_trail') = 1, 'opening the trail is recorded');
\o
select 'All client audit trail tests passed.';
