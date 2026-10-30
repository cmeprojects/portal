-- Staff Portal · © cmeproject. All rights reserved.
--
-- Clearer wording for who sees reports (cmeprojects), now on their own
-- Reports tab in System settings.

update public.app_settings
   set label = 'Who sees the Compliance report',
       description = 'Onboarding and compliance for everyone: what''s done, missing, expiring or expired. Besides the system admin. Tick Manager to let managers see it.'
 where key = 'reports.compliance_roles';
