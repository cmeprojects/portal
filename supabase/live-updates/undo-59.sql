-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 59: settings areas as before. Safe to run again.
begin;
create or replace function public.setting_area(p_key text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
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
$$;
delete from public.delegation_shares where area = 'hr';
delete from public.delegation_rules where area = 'hr';
alter table public.delegation_shares drop constraint if exists delegation_shares_area_check;
alter table public.delegation_shares add constraint delegation_shares_area_check
  check (area in ('branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'website', 'registers'));
alter table public.delegation_rules drop constraint if exists delegation_rules_area_check;
alter table public.delegation_rules add constraint delegation_rules_area_check
  check (area in ('branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'website', 'audit', 'registers', 'roles', 'register_setup'));
drop policy if exists "system admin changes request types" on public.request_types;
create policy "system admin changes request types" on public.request_types for update to authenticated using (public.is_system_admin()) with check (public.is_system_admin());
commit;
