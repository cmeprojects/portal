-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 40: the website stops being the front page, and only the
-- system admin looks after it again. Saved settings are kept. Safe to run again.
begin;
update public.app_settings set value = 'false' where key = 'website.front_page';
update public.admin_delegations set areas = array_remove(areas, 'website');
alter table public.admin_delegations drop constraint if exists admin_delegations_areas_check;
alter table public.admin_delegations add constraint admin_delegations_areas_check
  check (areas <@ array['branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'audit']);
drop policy if exists assistant_settings_read on public.assistant_settings;
create policy assistant_settings_read on public.assistant_settings for select to authenticated using (public.is_system_admin());
drop policy if exists assistant_settings_write on public.assistant_settings;
create policy assistant_settings_write on public.assistant_settings for update to authenticated
  using (public.is_system_admin()) with check (public.is_system_admin());
drop policy if exists assistant_documents_all on public.assistant_documents;
create policy assistant_documents_all on public.assistant_documents for all to authenticated
  using (public.is_system_admin()) with check (public.is_system_admin());
drop policy if exists assistant_questions_read on public.assistant_questions;
create policy assistant_questions_read on public.assistant_questions for select to authenticated using (public.is_system_admin());
commit;
