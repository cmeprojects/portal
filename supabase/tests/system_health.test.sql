-- Staff Portal · © cmeproject. All rights reserved.
--
-- System health: the system admin only.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager');
insert into auth.users (email) values ('boss@example.com');
insert into public.system_heartbeat (job, ok, detail) values ('hourly', true, '');

select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$select public.system_health()$$, 'a manager can''t see System health');
select test.refused($$select * from public.system_heartbeat$$, 'or read the timer directly');
reset role;

select test.act_as('owner@example.com');
set role authenticated;
select test.ok((public.system_health() ->> 'database_bytes')::bigint > 0, 'the system admin sees the database size');
select test.ok(public.system_health() -> 'timer' ->> 'job' = 'hourly', 'and when the hourly timer last ran');
reset role;

\o
\echo All system health tests passed.
