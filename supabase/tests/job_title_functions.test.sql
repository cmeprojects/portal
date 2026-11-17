-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 93): job titles linked to function groups (Stage 2).

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('sam@example.com');
create function test.fg(p_key text) returns uuid language sql security definer as $$ select id from public.function_groups where key = p_key $$;
create function test.jt(p_name text) returns uuid language sql security definer as $$ select id from public.job_titles where name = p_name $$;
grant execute on all functions in schema test to authenticated;
insert into public.job_titles (name, access_level) values ('Care Manager', 'manager'), ('Speech Pathologist', 'external');

select test.act_as('owner@example.com');
set role authenticated;
insert into public.job_title_functions (job_title_id, function_group_id) values (test.jt('Care Manager'), test.fg('care_coordination')), (test.jt('Care Manager'), test.fg('management_admin'));
insert into public.job_title_functions (job_title_id, function_group_id) values (test.jt('Speech Pathologist'), test.fg('allied_health'));
reset role;
select test.ok((select count(*) from public.job_title_functions where job_title_id = test.jt('Care Manager')) = 2, 'a role can belong to more than one group');

select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.job_title_functions where job_title_id in (test.jt('Care Manager'), test.jt('Speech Pathologist'))) = 3, 'members read the links');
select test.refused($$insert into public.job_title_functions (job_title_id, function_group_id) values (test.jt('Speech Pathologist'), test.fg('care_coordination'))$$, 'a support worker can''t link roles');
delete from public.job_title_functions;
reset role;
select test.ok((select count(*) from public.job_title_functions where job_title_id in (test.jt('Care Manager'), test.jt('Speech Pathologist'))) = 3, 'a support worker can''t unlink roles');

select test.act_as('owner@example.com');
set role authenticated;
select test.refused($$update public.function_groups set active = false where key = 'allied_health'$$, 'a group used by an active role can''t be deactivated');
update public.function_groups set active = false where key = 'service_delivery';
select test.refused($$insert into public.job_title_functions (job_title_id, function_group_id) values (test.jt('Care Manager'), test.fg('service_delivery'))$$, 'only active groups can be linked');
update public.job_titles set active = false where name = 'Speech Pathologist';
update public.function_groups set active = false where key = 'allied_health';
reset role;
select test.ok((select not active from public.function_groups where key = 'allied_health'), 'once its roles aren''t in use, the group can be deactivated');
select test.ok((select count(*) from public.job_title_functions where job_title_id = test.jt('Speech Pathologist')) = 1, 'deactivating a role keeps its links');
select test.act_as('owner@example.com');
set role authenticated;
delete from public.job_title_functions where job_title_id = test.jt('Care Manager') and function_group_id = test.fg('management_admin');
reset role;
select test.ok((select count(*) from public.job_title_functions where job_title_id = test.jt('Care Manager')) = 1, 'the Roles admin unlinks a group');

-- Still no access from groups in Stage 2.
select test.ok(not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name in ('access_grants', 'profiles') and column_name like '%function%'), 'no grants or people linked to groups yet');

\o
\echo 'All role function group tests passed.'
