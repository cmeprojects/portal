-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects: Administration has two items: Portal settings (one page with
-- every settings section: System settings, SLA, Request approvals, Change
-- log, Feature builder, System health, and more later) and Access (the
-- delegation page). Catalogue only; nobody's access changes.
update public.app_modules set parent_id = 'system.settings' where id in ('system.audit', 'system.builder', 'system.health');
update public.app_modules set label = 'Access' where id = 'system.access';
