-- Staff Portal · © cmeproject. All rights reserved.
-- Update 125: Support Worker is a role again (access level stays Standard
-- access; under Service Delivery). Staff on Standard access with no role get
-- Support Worker. Nobody's access changes. Safe to run again. Undo: undo-125.sql.
begin;
insert into public.job_titles (name, access_level, description, sort_order)
select 'Support Worker', 'support_worker',
       'Frontline support: their own tasks and shifts, and their teams'' clients'' locations, alerts and support instructions.', 5
 where not exists (select 1 from public.job_titles where lower(name) = 'support worker');
update public.job_titles set active = true where lower(name) = 'support worker' and not active;
insert into public.job_title_functions (job_title_id, function_group_id)
select j.id, g.id from public.job_titles j, public.function_groups g
 where lower(j.name) = 'support worker' and g.name = 'Service Delivery'
on conflict do nothing;
update public.profiles p set job_title_id = (select id from public.job_titles where lower(name) = 'support worker')
 where p.role = 'support_worker' and p.job_title_id is null;
update public.invitations i set job_title_id = (select id from public.job_titles where lower(name) = 'support worker')
 where i.role = 'support_worker' and i.job_title_id is null;
commit;
