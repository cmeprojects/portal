-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 55: removes the HR Pack switches and staff profiles (profile
-- details are deleted). Compliance goes back to being its own feature.
-- Safe to run again.
begin;
drop function if exists public.save_profile(uuid, jsonb);
drop table if exists public.staff_private;
drop table if exists public.staff_directory;
update public.features set parent = null where key = 'compliance' and parent = 'hr';
delete from public.features where key in ('hr_req_leave', 'hr_req_swap', 'hr_req_shift', 'hr_req_availability', 'hr_req_timesheet', 'hr_req_hr', 'hr_req_other');
delete from public.features where key in ('hr_profiles', 'hr_requests');
delete from public.features where key = 'hr';
create or replace function public.feature_live(p_key text)
returns boolean
language sql
stable
set search_path = ''
as $$
  select coalesce((
    select f.enabled and f.included
       and (f.parent is null or coalesce((select p.enabled and p.included from public.features p where p.key = f.parent), false))
      from public.features f
     where f.key = p_key
  ), false)
$$;
commit;
