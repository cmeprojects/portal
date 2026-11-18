-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects: TEST DATA ONLY — sets the owner-chosen password "#Testview" on
-- the 10 seeded test staff (employee IDs TEST-S01 to TEST-S10). No other
-- account is touched. DEV / LOCAL ONLY: this password is in the repository,
-- so never run it on Demo, production or a customer's copy. Safe to run again.
begin;
update auth.users
   set encrypted_password = extensions.crypt('#Testview', extensions.gen_salt('bf')), updated_at = now()
 where id in (select sp.user_id from public.staff_private sp where sp.employee_id like 'TEST-S%');
commit;
select p.full_name, p.email, j.name as job_title
  from public.profiles p join public.staff_private sp on sp.user_id = p.id left join public.job_titles j on j.id = p.job_title_id
 where sp.employee_id like 'TEST-S%' order by sp.employee_id;
