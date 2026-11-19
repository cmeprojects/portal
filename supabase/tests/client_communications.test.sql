-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 147): the client communication log.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('boss2@example.com', 'Max', 'manager'), ('sam@example.com', 'Sam', 'support_worker');
insert into public.invitations (email, full_name, role, job_title_id)
select 'pay@example.com', 'Pat', 'support_worker', id from public.job_titles where name = 'Payroll Officer';
insert into auth.users (email) values ('boss@example.com'), ('boss2@example.com'), ('sam@example.com'), ('pay@example.com');
create function test.cid() returns uuid language sql security definer as $$ select id from public.car_clients limit 1 $$;
grant execute on all functions in schema test to authenticated;
insert into public.car_clients (name, status) values ('Zara', 'active');

select test.act_as('boss@example.com');
set role authenticated;
insert into public.client_communications (client_id, method, direction, with_whom, summary, follow_up, follow_up_by)
values (test.cid(), 'phone', 'in', 'Mother (Jane)', 'Asked to move Tuesday visits to mornings.', 'Check with the roster team', current_date);
select test.ok((select count(*) from public.client_communications) = 1, 'a manager logs a call');
select test.refused($$insert into public.client_communications (client_id, method, summary, happened_at) values (test.cid(), 'email', 'x', now() + interval '2 days')$$, 'not in the future');
select test.refused($$delete from public.client_communications$$, 'entries are never deleted');
update public.client_communications set summary = 'Asked to move Tuesday visits to mornings (from 9am).';
reset role;
select test.ok((select summary from public.client_communications) like '%from 9am%', 'the author corrects it within 24 hours');

select test.act_as('boss2@example.com');
set role authenticated;
select test.refused($$update public.client_communications set summary = 'changed'$$, 'someone else can''t change what was written');
update public.client_communications set follow_up_done_at = now();
reset role;
select test.ok((select follow_up_done_by is not null from public.client_communications), 'another person marks the follow-up done (recorded who)');

set session_replication_role = replica;
update public.client_communications set created_at = now() - interval '2 days';
set session_replication_role = origin;
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.client_communications set summary = 'late change'$$, 'after 24 hours it stays as written');
reset role;

select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.client_communications) = 0, 'support workers don''t see the log');
reset role;
select test.act_as('pay@example.com');
set role authenticated;
select test.ok((select count(*) from public.client_communications) = 0, 'nor does payroll');
select test.refused($$insert into public.client_communications (client_id, method, summary) values (test.cid(), 'phone', 'x')$$, 'and they can''t write it');
reset role;
\o
select 'All communication log tests passed.';
