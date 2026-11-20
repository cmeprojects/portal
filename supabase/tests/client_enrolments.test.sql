-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 158): program enrolments.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
drop trigger if exists test_auto_enrol on public.car_clients; -- this test checks the real rules
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker'), ('cm@example.com', 'Casey', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com'), ('cm@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.cid(p text) returns uuid language sql security definer as $$ select id from public.car_clients where name = p $$;
create function test.prog(p text) returns uuid language sql security definer as $$ select id from public.client_programs where name = p $$;
create function test.loc(p text) returns uuid language sql security definer as $$ select l.id from public.client_locations l join public.car_clients c on c.id = l.client_id where c.name = p limit 1 $$;
create function test.svc(p text) returns uuid language sql security definer as $$ select id from public.client_services where label = p $$;
create function test.enr(p_client text, p_prog text) returns uuid language sql security definer as $$
  select e.id from public.client_enrolments e where e.client_id = test.cid(p_client) and e.program_id = test.prog(p_prog) order by e.created_at desc limit 1 $$;
create function test.st(p_client text, p_prog text) returns text language sql security definer as $$
  select e.status || case when e.is_main then '+main' else '' end from public.client_enrolments e where e.id = test.enr(p_client, p_prog) $$;
create function test.fb(p_client text) returns text language sql security definer as $$ select coalesce(scheme, '-') from public.car_clients where name = p_client $$;
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
insert into public.car_clients (name, status) values ('Zara', 'active'), ('Ben', 'active');
insert into public.client_locations (client_id, label, address, approved) values (test.cid('Zara'), 'Home', '1 Test St', true), (test.cid('Ben'), 'Home', '2 Test St', true);
insert into public.client_assignments (client_id, user_id) values (test.cid('Zara'), test.pid('cm@example.com'));

-- 1. Adding programs (as a manager, through the portal's rules).
select test.act_as('boss@example.com');
set role authenticated;
insert into public.client_enrolments (client_id, program_id, starts_on) values (test.cid('Zara'), test.prog('NDIS'), current_date - 30);
insert into public.client_enrolments (client_id, program_id, starts_on) values (test.cid('Zara'), test.prog('Private'), current_date - 30);
select test.refused($$insert into public.client_enrolments (client_id, program_id) values (test.cid('Zara'), test.prog('NDIS'))$$, 'the same program can''t be open twice');
select test.refused($$update public.car_clients set scheme = 'private' where name = 'Zara'$$, '"Funded by" isn''t changed directly');
insert into public.client_enrolments (client_id, program_id, starts_on) values (test.cid('Ben'), test.prog('Private'), current_date - 30);
insert into public.client_enrolments (client_id, program_id, starts_on) values (test.cid('Ben'), test.prog('Support at Home'), current_date - 30);
reset role;
select test.ok(test.st('Zara', 'NDIS') = 'active+main' and test.st('Zara', 'Private') = 'active', 'the first program is main; the second isn''t');
select test.ok(test.fb('Zara') = 'ndis', '"Funded by" follows the main program');
select test.ok((select scheme from public.client_enrolments where id = test.enr('Zara', 'NDIS')) = 'ndis', 'the scheme comes from the program');

-- 2. Programs and schemes switched off: no new use; existing records unaffected.
update public.client_programs set active = false where name = 'CHSP';
update public.client_schemes set offered = false where key = 'support_at_home';
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.client_enrolments (client_id, program_id) values (test.cid('Zara'), test.prog('CHSP'))$$, 'a switched-off program can''t be added');
select test.refused($$insert into public.client_enrolments (client_id, program_id) values (test.cid('Zara'), test.prog('Support at Home'))$$, 'a scheme the organisation doesn''t offer can''t be added');
update public.client_enrolments set status = 'paused', paused_from = current_date, pause_reason = 'Hospital' where id = test.enr('Ben', 'Support at Home');
reset role;
select test.ok(test.st('Ben', 'Support at Home') = 'paused', 'an existing enrolment in a scheme that isn''t offered can still be changed');
select test.ok(test.n('boss@example.com', $$(select count(*) from public.client_enrolments where client_id = test.cid('Ben'))$$) = 2, 'and is still read');
update public.client_schemes set offered = true where key = 'support_at_home';
update public.client_programs set active = true where name = 'CHSP';
select test.ok((select count(*) from public.audit_log where entity = 'client_scheme' and action = 'changed_client_scheme') >= 2, 'turning a scheme off and on is in the change log');

-- 3. Services need an active enrolment.
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.client_services (origin, client_id, program_id, label, description, shift_types, start_date, location_id) values ('custom', test.cid('Zara'), test.prog('Support at Home'), 'Cleaning', 'Weekly clean.', '{domestic}', current_date, test.loc('Zara'))$$, 'a service in a program they aren''t in is refused');
select test.refused($$insert into public.client_services (origin, client_id, program_id, label, description, shift_types, start_date, location_id) values ('custom', test.cid('Zara'), test.prog('NDIS'), 'Early', 'Too early.', '{domestic}', current_date - 60, test.loc('Zara'))$$, 'or starting before the program does');
insert into public.client_services (origin, client_id, program_id, label, description, shift_types, start_date, location_id)
values ('custom', test.cid('Zara'), test.prog('NDIS'), 'Home help', 'Help at home.', '{domestic}', current_date, test.loc('Zara'));
-- An open shift on day 7, before the pause.
insert into public.shifts (client_id, service_id, location_id, starts_at, ends_at, status, shift_type)
values (test.cid('Zara'), test.svc('Home help'), test.loc('Zara'), now() + interval '7 days', now() + interval '7 days 2 hours', 'draft', 'domestic');

-- 4. Pause: no new services; no new shifts in the pause; existing ones stay.
update public.client_enrolments set status = 'paused', paused_from = current_date + 5, paused_until = current_date + 10, pause_reason = 'Holiday' where id = test.enr('Zara', 'NDIS');
select test.refused($$insert into public.client_services (origin, client_id, program_id, label, description, shift_types, start_date, location_id) values ('custom', test.cid('Zara'), test.prog('NDIS'), 'More help', 'More.', '{domestic}', current_date, test.loc('Zara'))$$, 'a paused program takes no new services');
select test.refused($$insert into public.shifts (client_id, service_id, location_id, starts_at, ends_at, status, shift_type) values (test.cid('Zara'), test.svc('Home help'), test.loc('Zara'), now() + interval '8 days', now() + interval '8 days 2 hours', 'draft', 'domestic')$$, 'no new shift in the pause');
insert into public.shifts (client_id, service_id, location_id, starts_at, ends_at, status, shift_type, notes)
values (test.cid('Zara'), test.svc('Home help'), test.loc('Zara'), now() + interval '2 days', now() + interval '2 days 2 hours', 'draft', 'domestic', 'before the pause');
insert into public.shifts (client_id, service_id, location_id, starts_at, ends_at, status, shift_type, notes)
values (test.cid('Zara'), test.svc('Home help'), test.loc('Zara'), now() + interval '12 days', now() + interval '12 days 2 hours', 'draft', 'domestic', 'after the pause');
update public.shifts set notes = 'Bring the key' where starts_at > now() + interval '6 days' and starts_at < now() + interval '8 days';
select test.refused($$update public.shifts set starts_at = starts_at + interval '1 hour', ends_at = ends_at + interval '1 hour' where notes = 'Bring the key'$$, 'moving a shift inside the pause is refused');
reset role;
update public.client_enrolments set status = 'ended', ends_on = current_date, end_reason = 'test' where id = test.enr('Ben', 'Private');
select test.act_as('boss@example.com');
set role authenticated;
-- A client shift can't leave out the service to skip the check (needed since update 130).
select test.refused($$insert into public.shifts (client_id, location_id, starts_at, ends_at, status, shift_type) values (test.cid('Zara'), test.loc('Zara'), now() + interval '8 days', now() + interval '8 days 2 hours', 'draft', 'domestic')$$, 'a client shift can''t skip the check by leaving out the service');
insert into public.shifts (starts_at, ends_at, status, shift_type, notes) values (now() + interval '3 days', now() + interval '3 days 1 hour', 'draft', 'admin', 'internal');
reset role;
select test.ok((select count(*) from public.shifts where notes = 'Bring the key') = 1, 'a shift already rostered in the pause stays, and can still get notes');
select test.ok(exists (select 1 from public.shifts where notes = 'internal'), 'internal shifts (no client) aren''t checked');
select test.ok(test.st('Ben', 'Support at Home') = 'paused+main', 'when the main ends, a paused program becomes main if nothing is active');
select test.ok(test.fb('Ben') = 'support_at_home', 'and "Funded by" follows');

-- 5. Ending: refused while services, agreements or budgets are open; reviews don't block.
select test.act_as('boss@example.com');
set role authenticated;
update public.client_enrolments set status = 'active' where id = test.enr('Zara', 'NDIS');
insert into public.client_agreements (client_id, service_id, starts_on) values (test.cid('Zara'), test.svc('Home help'), current_date);
insert into public.client_funding (client_id, service_id, period_start, period_end, total_amount, plan_management)
values (test.cid('Zara'), test.svc('Home help'), current_date, current_date + 300, 1000, 'ndia');
insert into public.client_reviews (client_id, service_id, kind, due_on) values (test.cid('Zara'), test.svc('Home help'), 'scheduled', current_date + 30);
select test.refused($$update public.client_enrolments set status = 'ended', ends_on = current_date, end_reason = 'Moved' where id = test.enr('Zara', 'NDIS')$$, 'ending is refused while the service is open');
update public.client_services set status = 'ended', end_date = current_date where label = 'Home help';
select test.refused($$update public.client_enrolments set status = 'ended', ends_on = current_date, end_reason = 'Moved' where id = test.enr('Zara', 'NDIS')$$, 'and while the agreement is open');
update public.client_agreements set status = 'ended' where service_id = test.svc('Home help');
select test.refused($$update public.client_enrolments set status = 'ended', ends_on = current_date, end_reason = 'Moved' where id = test.enr('Zara', 'NDIS')$$, 'and while the budget runs past the end');
select test.refused($$update public.client_enrolments set status = 'ended', ends_on = current_date where id = test.enr('Zara', 'NDIS')$$, 'a reason is needed');
update public.client_funding set status = 'ended' where service_id = test.svc('Home help');
update public.client_enrolments set status = 'ended', ends_on = current_date, end_reason = 'Moved to private' where id = test.enr('Zara', 'NDIS');
select test.refused($$update public.client_enrolments set end_reason = 'changed' where id = test.enr('Zara', 'NDIS')$$, 'an ended enrolment stays as it was');
reset role;
select test.ok(test.st('Zara', 'NDIS') = 'ended' and exists (select 1 from public.client_reviews where client_id = test.cid('Zara') and status = 'open'), 'ended once they were closed; the open review didn''t block it');
select test.ok(test.st('Zara', 'Private') = 'active+main' and test.fb('Zara') = 'private', 'the other active program became main, and "Funded by" followed');
select test.ok((select count(*) from public.audit_log where entity = 'client' and entity_id = test.cid('Zara')::text and action = 'client_enrolments_changed' and details -> 'fields' ? 'is_main') >= 1, 'the promotion is in the audit trail');
select test.ok((select count(*) from public.client_services) = 1 and (select count(*) from public.client_agreements) = 1 and (select count(*) from public.client_funding) = 1, 'nothing was deleted');

-- 6. No open programs left: no "Funded by", and "No active program".
select test.act_as('boss@example.com');
set role authenticated;
update public.client_enrolments set status = 'ended', ends_on = current_date, end_reason = 'Left' where id = test.enr('Zara', 'Private');
reset role;
select test.ok(test.fb('Zara') = '-' and 'No active program.' = any (public.client_gaps(test.cid('Zara'), null, null, false, null)), 'no open program: no "Funded by", and "No active program" to check');

-- 7. Adding a client with two programs.
select test.act_as('boss@example.com');
set role authenticated;
select public.create_client_full('{"name":"Ivy Two","given_name":"Ivy","family_name":"Two"}'::jsonb, '{}'::jsonb, null, 'case_manager',
                                 array[test.prog('Private'), test.prog('NDIS')], test.prog('NDIS'), current_date);
select test.refused($$select public.create_client_full('{"name":"No Program","given_name":"No","family_name":"Program"}'::jsonb, '{}'::jsonb, null, 'case_manager', '{}', null, null)$$, 'a new client needs at least one program');
reset role;
select test.ok(test.st('Ivy Two', 'NDIS') = 'active+main' and test.st('Ivy Two', 'Private') = 'active' and test.fb('Ivy Two') = 'ndis', 'both programs saved, the chosen main one is main');

-- 8. Who can change and see enrolments (direct requests).
select test.ok(test.n('sam@example.com', $$(select count(*) from public.client_enrolments)$$) = 0, 'a support worker sees no enrolments');
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$insert into public.client_enrolments (client_id, program_id) values (test.cid('Ben'), test.prog('NDIS'))$$, 'a support worker can''t add one');
reset role;
select test.ok(test.n('cm@example.com', $$(select count(*) from public.client_enrolments where client_id = test.cid('Zara'))$$) = 2, 'their Case Manager sees the assigned client''s enrolments');
select test.ok(test.n('cm@example.com', $$(select count(*) from public.client_enrolments where client_id = test.cid('Ben'))$$) = 0, 'but not another client''s');
select test.act_as('cm@example.com');
set role authenticated;
select test.refused($$insert into public.client_enrolments (client_id, program_id) values (test.cid('Ben'), test.prog('NDIS'))$$, 'and can''t add one for a client outside their scope');
update public.client_enrolments set status = 'paused', paused_from = current_date where id = test.enr('Ben', 'Support at Home');
reset role;
select test.ok((select paused_from from public.client_enrolments where id = test.enr('Ben', 'Support at Home')) = current_date, 'a change outside their scope doesn''t happen');
select test.act_as('cm@example.com');
set role authenticated;
select test.refused($$delete from public.client_enrolments$$, 'nobody deletes an enrolment');
reset role;

-- 9. Audit: one entry per change, with the values for the system admin only.
select test.ok((select count(*) from public.audit_log where entity = 'client' and entity_id = test.cid('Zara')::text and action = 'client_enrolments_added') = 2, 'adding is recorded once each');
select test.ok(test.n('owner@example.com', $$(select count(*) from public.client_audit_values v join public.audit_log a on a.id = v.audit_id where a.action like 'client_enrolments%')$$) > 0
           and test.n('boss@example.com', $$(select count(*) from public.client_audit_values)$$) = 0, 'values for the system admin only');

-- 10. Running the update again adds nothing.
create table test.before_rerun as select id, status, is_main from public.client_enrolments;
\o /dev/null
\i supabase/migrations/20270413000001_client_enrolments.sql
\o /dev/null
select test.ok((select count(*) from public.client_enrolments) = (select count(*) from test.before_rerun)
           and not exists (select id, status, is_main from public.client_enrolments except select id, status, is_main from test.before_rerun), 'running update 158 again adds and changes nothing');
\o
select 'All program enrolment tests passed.';
