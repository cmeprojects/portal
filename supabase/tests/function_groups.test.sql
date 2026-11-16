-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 92): Function Groups list (Stage 1).

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com');

select test.ok((select string_agg(key, ',' order by sort_order) from public.function_groups) = 'management_admin,hr_workforce,care_coordination,service_delivery,finance_accounts,allied_health', 'the six function groups are there, in order');
select test.ok((select bool_and(active) from public.function_groups), 'all start active');

select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.function_groups) = 6, 'members read the list');
select test.refused($$insert into public.function_groups (key, name) values ('sneaky', 'Sneaky')$$, 'a support worker can''t add a group');
update public.function_groups set name = 'Changed' where key = 'allied_health';
reset role;
select test.ok((select name from public.function_groups where key = 'allied_health') = 'Allied Health', 'a support worker can''t change a group');

select test.act_as('owner@example.com');
set role authenticated;
insert into public.function_groups (key, name, description, sort_order) values ('quality', 'Quality & Compliance', 'Audits and quality.', 70);
update public.function_groups set name = 'Allied Health Services', description = 'Updated.' where key = 'allied_health';
update public.function_groups set active = false where key = 'quality';
select test.refused($$update public.function_groups set key = 'allied' where key = 'allied_health'$$, 'the key never changes');
select test.refused($$insert into public.function_groups (key, name) values ('dup', 'quality & compliance')$$, 'names are unique (any case)');
select test.refused($$insert into public.function_groups (key, name) values ('Bad Key', 'Bad')$$, 'keys are lower-case words');
delete from public.function_groups where key = 'quality';
reset role;
select test.ok((select name = 'Allied Health Services' and updated_by = (select id from public.profiles where email = 'owner@example.com') from public.function_groups where key = 'allied_health'), 'the system admin renames a group (who and when kept)');
select test.ok((select not active from public.function_groups where key = 'quality'), 'a group is deactivated');
select test.ok((select count(*) from public.function_groups) = 7, 'nothing is deleted');

-- Nothing else changes in Stage 1: no access comes from a group.
select test.ok(not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name in ('job_titles', 'access_grants', 'profiles') and column_name like '%function%'), 'no links to titles, grants or people yet');

\o
\echo 'All function group tests passed.'
