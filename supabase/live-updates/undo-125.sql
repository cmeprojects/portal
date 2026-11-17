-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 125: staff with the Support Worker role go back to plain
-- Standard access (no role), and the role is removed. Safe to run again.
begin;
update public.profiles set job_title_id = null where job_title_id in (select id from public.job_titles where lower(name) = 'support worker');
update public.invitations set job_title_id = null where job_title_id in (select id from public.job_titles where lower(name) = 'support worker');
delete from public.job_title_functions where job_title_id in (select id from public.job_titles where lower(name) = 'support worker');
delete from public.job_titles j where lower(j.name) = 'support worker'
   and not exists (select 1 from public.access_baselines b where b.job_title_id = j.id);
update public.job_titles set active = false where lower(name) = 'support worker';
commit;
