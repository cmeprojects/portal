-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 125): the Support Worker role at Standard access.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
select test.ok((select count(*) from public.job_titles where lower(name) = 'support worker' and access_level = 'support_worker' and active) = 1, 'Support Worker is a role at Standard access');
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role, job_title_id)
select 'sw@example.com', 'Sam', 'support_worker', id from public.job_titles where name = 'Support Worker';
insert into auth.users (email) values ('sw@example.com');
select test.ok((select j.name from public.profiles p join public.job_titles j on j.id = p.job_title_id where p.email = 'sw@example.com') = 'Support Worker', 'staff can be given the Support Worker role');
select test.ok(exists (select 1 from public.job_title_functions f join public.function_groups g on g.id = f.function_group_id join public.job_titles j on j.id = f.job_title_id where j.name = 'Support Worker' and g.name = 'Service Delivery'), 'under the Service Delivery function');
\o
select 'All Support Worker role tests passed.';
