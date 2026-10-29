-- Staff Portal · © cmeproject. All rights reserved.
-- Update 19: the system admin chooses who sees Registers. Safe to run again.
begin;
--
-- Who sees Registers in the menu (cmeprojects). The system admin always does;
-- staff open their own tasks from My tasks either way.

insert into public.app_settings (key, value, label, description, is_public) values
  ('tasks.registers_roles', '["team_leader", "manager", "staff_admin"]', 'Who sees Registers',
   'Besides the system admin. People without it still see and create their own tasks under Tasks.', false)
on conflict (key) do nothing;
commit;
