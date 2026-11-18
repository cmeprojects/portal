-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 132): the shift log says "assigned" and "re-assigned".
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com'), ('kim@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;
select test.act_as('boss@example.com');
set role authenticated;
insert into public.shifts (starts_at, ends_at, status) values (date_trunc('hour', now()) + interval '30 hours', date_trunc('hour', now()) + interval '32 hours', 'draft');
update public.shifts set worker_id = test.pid('sam@example.com');
update public.shifts set worker_id = test.pid('kim@example.com');
reset role;
select test.ok(exists (select 1 from public.shift_events where summary = 'assigned this shift to Sam'), 'assigning a vacant shift says "assigned"');
select test.ok(exists (select 1 from public.shift_events where summary = 're-assigned this shift from Sam to Kim'), 'changing the worker says "re-assigned"');
\o
select 'All re-assign wording tests passed.';
