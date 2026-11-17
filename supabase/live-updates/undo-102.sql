-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 102: Due dates go back to "managers always"; Request approvals
-- back to an uncatalogued HR settings rule. Copied defaults kept (no effect).
-- Safe to run again.
begin;
update public.app_modules set legacy_kind = null, legacy_area = null
 where id = 'workflows.request_rules' and legacy_kind = 'settings';
update public.app_modules set grant_ready = false where id = 'workflows.sla' and grant_ready;
drop policy if exists "managers change the SLA" on public.app_settings;
create policy "managers change the SLA" on public.app_settings
  for update to authenticated
  using (key ~~ 'tasks.sla%'::text and has_role(array['manager'::app_role]))
  with check (key ~~ 'tasks.sla%'::text and has_role(array['manager'::app_role]));
commit;
