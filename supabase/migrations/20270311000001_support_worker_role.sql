-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 125): "Support Worker" is a role again. Its access level
-- stays Standard access (renamed in update 108); it sits under the Service
-- Delivery function. Staff on Standard access with no role are given Support
-- Worker, so their role shows as Support Worker. Nobody's access changes.
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
