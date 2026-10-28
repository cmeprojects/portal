-- Staff Portal · © cmeproject. All rights reserved.
--
-- SLA: default due dates by priority (days after the date reported). Set for
-- the whole company in System settings; a register can override them.

insert into public.app_settings (key, value, label, description, is_public) values
  ('tasks.sla_days', '{"urgent": 1, "high": 3, "medium": 7, "low": 14}',
   'Default due dates (SLA)', 'Days to finish a task, by priority. New tasks get this due date unless someone picks another.', false),
  ('tasks.sla_weekdays_only', 'false',
   'Count weekdays only', 'Skip Saturdays and Sundays when working out SLA due dates.', false)
on conflict (key) do nothing;

-- A register's own SLA (null = use the company's).
alter table public.registries
  add column sla_days jsonb check (sla_days is null or jsonb_typeof(sla_days) = 'object');
