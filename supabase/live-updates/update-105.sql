-- Staff Portal · © cmeproject. All rights reserved.
-- Update 105: the parts of Clients, and the roles Case Manager, Intake & Assessment Officer,
-- Payroll & Rostering (Stage 5a). Nobody's access changes.
-- Safe to run again. Undo: undo-105.sql. Run update 104 first.
begin;
-- cmeprojects (update 105; function-based access, Stage 5a; D-045, D-047,
-- D-050, owner approved the Stage 5 recommendations 17 Nov 2026):
-- the parts of Clients, and three new roles.
--
--   * Clients is split into parts so each can be given on its own:
--     details, contacts, risk notes and services are sensitive (a role or a
--     person only, never a whole function group); locations, alerts and
--     assigning staff are normal. Nobody's access changes in this update
--     (Clients still uses the built-in rule until update 107).
--   * New roles (job titles), all at the support worker access level; their
--     extra access comes from grants on the role (update 107):
--       - Case Manager and Intake & Assessment Officer (Care & Coordination);
--       - Payroll & Rostering (HR & Workforce, Finance & Accounts).
--     Existing roles with the same name are left as they are.

insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order, actions) values
  ('clients.details', 'clients.list', 'clients', 'Client details', 'sensitive', true, 251, '{view,edit}'),
  ('clients.people', 'clients.list', 'clients', 'Contacts and support people', 'sensitive', true, 252, '{view,edit}'),
  ('clients.locations', 'clients.list', 'clients', 'Locations', 'normal', true, 253, '{view,edit}'),
  ('clients.alerts', 'clients.list', 'clients', 'Alerts', 'normal', true, 254, '{view,edit}'),
  ('clients.notes', 'clients.list', 'clients', 'Risk notes', 'sensitive', true, 255, '{view,edit}'),
  ('clients.services', 'clients.list', 'clients', 'Services', 'sensitive', true, 256, '{view,edit}'),
  ('clients.assign', 'clients.list', 'clients', 'Assigning staff', 'normal', true, 257, '{view,edit}')
on conflict (id) do nothing;

insert into public.job_titles (name, access_level, description)
select x.name, 'support_worker', x.description
  from (values
    ('Case Manager', 'Manages the clients assigned to them. Not a centre manager.'),
    ('Intake & Assessment Officer', 'Takes new clients and referrals, and assigns clients to staff.'),
    ('Payroll & Rostering', 'Payroll and rosters.')
  ) x(name, description)
 where not exists (select 1 from public.job_titles t where lower(t.name) = lower(x.name));

insert into public.job_title_functions (job_title_id, function_group_id)
select t.id, g.id
  from (values
    ('Case Manager', 'care_coordination'),
    ('Intake & Assessment Officer', 'care_coordination'),
    ('Payroll & Rostering', 'hr_workforce'),
    ('Payroll & Rostering', 'finance_accounts')
  ) x(title, group_key)
  join public.job_titles t on t.name = x.title
  join public.function_groups g on g.key = x.group_key and g.active
on conflict do nothing;
commit;
