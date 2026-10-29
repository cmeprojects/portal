-- Staff Portal · © cmeproject. All rights reserved.
--
-- Compliance report (cmeprojects): Reports → Compliance. Staff admins see it;
-- the system admin can let managers see it too.

insert into public.app_settings (key, value, label, description, is_public) values
  ('reports.compliance_roles', '["staff_admin"]', 'Who sees the Compliance report',
   'Besides the system admin. Tick Manager to let managers see it too.', false)
on conflict (key) do nothing;
