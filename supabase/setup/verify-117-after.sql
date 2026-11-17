-- Staff Portal · © cmeproject. All rights reserved.
-- Check after update 117: the extra defaults for the three new roles, and how
-- many active staff hold each role. Read only.
select j.name as role, b.module_id as part, b.actions, b.scope,
       (select count(*) from public.profiles p where p.job_title_id = j.id and p.active) as active_staff_with_role
  from public.access_baselines b join public.job_titles j on j.id = b.job_title_id
 where b.revoked_at is null and b.note = 'Update 117: owner chose more default access for this role'
 order by 1, 2;
-- Expect 11 rows: Case Manager 3, Intake & Assessment Officer 3, Payroll & Rostering 5.
select count(*) as staff_admin_client_defaults_should_be_0
  from public.access_baselines where access_level = 'staff_admin' and module_id like 'clients.%' and revoked_at is null;
