-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 63: back to documents / listed websites only. Groups set to an
-- internet choice go back to the nearest older one. Safe to run again.
begin;
update public.assistant_settings set
  scope_public   = case when scope_public in ('docs_web', 'docs_sites_web') then 'both' when scope_public in ('sites_web', 'internet') then 'web' else scope_public end,
  scope_staff    = case when scope_staff in ('docs_web', 'docs_sites_web') then 'both' when scope_staff in ('sites_web', 'internet') then 'web' else scope_staff end,
  scope_managers = case when scope_managers in ('docs_web', 'docs_sites_web') then 'both' when scope_managers in ('sites_web', 'internet') then 'web' else scope_managers end;
alter table public.assistant_settings drop constraint if exists assistant_settings_scope_check;
alter table public.assistant_settings drop column if exists blocked_sites;
alter table public.assistant_settings add constraint assistant_settings_scope_check check (
  scope_public in ('documents', 'web', 'both') and scope_staff in ('documents', 'web', 'both') and scope_managers in ('documents', 'web', 'both')
  and cardinality(trusted_sites) <= 30 and cardinality(suggestions) <= 8);
commit;
