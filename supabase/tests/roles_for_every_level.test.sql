-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 126, AUD-016): the initial job titles under their Function Groups.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
create function test.roles(p_group text) returns text language sql as $$
  select string_agg(j.name, ', ' order by j.sort_order, j.name) from public.job_titles j
    join public.job_title_functions f on f.job_title_id = j.id join public.function_groups g on g.id = f.function_group_id
   where j.active and g.key = p_group $$;
select test.ok(test.roles('care_coordination') like '%Case Manager%' and test.roles('care_coordination') like '%Intake & Assessment Officer%' and test.roles('care_coordination') like '%Client Services Coordinator%', 'Care & Coordination job titles');
select test.ok(test.roles('hr_workforce') = 'Staff Administrator, Rostering Officer', 'HR & Workforce job titles');
select test.ok(test.roles('finance_accounts') = 'Payroll Officer', 'Finance & Accounts job titles');
select test.ok(test.roles('service_delivery') = 'Support Worker, Team Leader', 'Service Delivery job titles');
select test.ok(test.roles('allied_health') = 'Psychologist, Behaviour Support Practitioner, Speech Pathologist, Occupational Therapist', 'Allied Health job titles');
select test.ok(test.roles('management_admin') = 'Manager', 'Management & Administration job titles');
select test.ok(not exists (select 1 from public.function_groups where lower(name) = 'core'), 'no Core group');
select test.ok((select count(*) from public.access_baselines b join public.job_titles j on j.id = b.job_title_id where j.name = 'Payroll Officer' and b.revoked_at is null and b.module_id = 'ops.roster') = 1, 'Payroll Officer keeps its access (nobody loses any)');
select test.ok((select count(*) from public.access_baselines b join public.job_titles j on j.id = b.job_title_id where j.name = 'Rostering Officer' and b.revoked_at is null and b.module_id = 'ops.roster') = 1
  and not exists (select 1 from public.access_baselines b join public.job_titles j on j.id = b.job_title_id where j.name = 'Rostering Officer' and b.module_id = 'clients.funding'), 'Rostering Officer rosters, without funding');
\o
select 'All job title tests passed.';
