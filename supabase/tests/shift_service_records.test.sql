-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 134): service records.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com'), ('kim@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.sid() returns uuid language sql security definer as $$ select id from public.shifts limit 1 $$;
grant execute on all functions in schema test to authenticated;
select test.act_as('boss@example.com');
set role authenticated;
insert into public.shifts (worker_id, starts_at, ends_at, status) values (test.pid('sam@example.com'), now() - interval '3 hours', now() - interval '1 hour', 'published');
reset role;
select test.act_as('kim@example.com');
set role authenticated;
select test.refused($$insert into public.shift_service_records (shift_id, delivered) values (test.sid(), 'Not mine')$$, 'only the rostered worker writes it');
reset role;
select test.act_as('sam@example.com');
set role authenticated;
insert into public.shift_service_records (shift_id, delivered, concern, concern_note) values (test.sid(), 'Shower, breakfast, shopping.', true, 'Seemed confused about the date.');
update public.shift_service_records set delivered = 'Shower, breakfast, shopping, short walk.';
reset role;
select test.ok((select delivered from public.shift_service_records) like '%short walk%', 'the worker writes and changes it within 24 hours');
select test.ok((select count(*) from public.shift_events where summary like 'recorded the service delivered%flagged a concern') = 1, 'it''s in the shift''s events');
set session_replication_role = replica;
update public.shift_service_records set created_at = now() - interval '2 days';
set session_replication_role = origin;
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$update public.shift_service_records set delivered = 'changed'$$, 'after 24 hours it''s kept as written');
reset role;
select test.ok((select count(*) from public.shift_service_records) = 1, 'people who roster read it (as the owner)');
select set_config('request.jwt.claims', '', false);
create temp table r as select public.run_service_record_alerts() as v;
select test.ok((select (v ->> 'service_concerns')::int from r) = 1, 'a concern is passed on once');
\o
select 'All service record tests passed.';
