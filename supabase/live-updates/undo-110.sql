-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 110: programs back to the system admin, no schemes, no Care
-- settings area. Safe to run again.
begin;
drop policy if exists "care settings add programs" on public.client_programs;
drop policy if exists "care settings change programs" on public.client_programs;
drop policy if exists "the system admin adds programs" on public.client_programs;
create policy "the system admin adds programs" on public.client_programs as PERMISSIVE for INSERT to authenticated with check (( SELECT is_system_admin() AS is_system_admin));
drop policy if exists "the system admin changes programs" on public.client_programs;
create policy "the system admin changes programs" on public.client_programs as PERMISSIVE for UPDATE to authenticated using (( SELECT is_system_admin() AS is_system_admin)) with check (( SELECT is_system_admin() AS is_system_admin));
drop trigger if exists guard_program_scheme on public.client_programs;
drop function if exists public.guard_program_scheme();
alter table public.client_programs drop column if exists scheme;
drop table if exists public.client_schemes;
drop function if exists public.guard_client_scheme();
delete from public.delegation_rules where area = 'care';
delete from public.delegation_shares where area = 'care';
alter table public.delegation_rules drop constraint if exists delegation_rules_area_check;
alter table public.delegation_rules add constraint delegation_rules_area_check
  check (area = any (array['branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'website', 'audit', 'registers', 'roles', 'register_setup', 'hr']));
delete from public.function_group_modules where module_id = 'system.settings.care';
delete from public.app_modules where id = 'system.settings.care' and not exists (select 1 from public.access_grants where module_id = 'system.settings.care');
CREATE OR REPLACE FUNCTION public.setting_area(p_key text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
  select case
    when p_key = 'compliance.clearance_roles' then 'hr'
    when p_key = 'compliance.clearance_started' then null
    when p_key = 'cars.cleared_only' then 'vehicles'
    when p_key in ('brand.support_contact', 'brand.announcement', 'people.invite_message') then 'messages'
    when p_key like 'brand.%' or p_key like 'wording.%' then 'branding'
    when p_key like 'people.%' then 'people'
    when p_key like 'compliance.%' then 'compliance'
    when p_key like 'tasks.%' then 'tasks'
    when p_key like 'reports.%' then 'reports'
    when p_key like 'vehicles.%' then 'vehicles'
    when p_key like 'website.%' or p_key like 'assistant.%' then 'website'
    else null
  end
$function$
;
commit;
