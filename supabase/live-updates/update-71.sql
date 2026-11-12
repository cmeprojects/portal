-- Staff Portal · © cmeproject. All rights reserved.
-- Update 71: "Portal settings" (System settings, SLA settings, Request
-- approvals as its sub-pages). No access changes. Safe to run again.
-- Undo: undo-71.sql. Run update 70 first.
begin;
-- cmeprojects: "Portal settings" in Administration, with its pages (System
-- settings, SLA settings, Request approvals) as hidden sub-pages. Catalogue
-- only; nobody's access changes.
update public.app_modules set label = 'Portal settings' where id = 'system.settings';
insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order)
values ('system.settings.general', 'system.settings', 'system', 'System settings', 'protected', false, 1095)
on conflict (id) do update set parent_id = excluded.parent_id, label = excluded.label, sensitivity = excluded.sensitivity;
update public.app_modules set parent_id = 'system.settings' where id in ('workflows.sla', 'workflows.request_rules');
commit;
