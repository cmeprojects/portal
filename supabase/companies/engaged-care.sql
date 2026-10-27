-- Staff Portal · © cmeproject. All rights reserved.
--
-- Company setup: Engaged Care Pty Ltd (Engaged Care Melbourne), Derrimut VIC.
-- Run once on this company's own Supabase project, after the migrations.
-- The registers match the company's SharePoint lists. Dropdown choices are
-- starting suggestions; managers can change them in each register's setup.

update public.organisation set name = 'Engaged Care Pty Ltd';

update public.app_settings set value = '"Engaged Care"' where key = 'brand.company_name';
update public.app_settings set value = '"Staff Portal"' where key = 'brand.portal_name';
update public.app_settings set value = '"/companies/engaged-care/logo.png"'      where key = 'brand.logo_url';
update public.app_settings set value = '"/companies/engaged-care/logo-mark.png"' where key = 'brand.logo_mark_url';
update public.app_settings set value = '"#134F8E"'      where key = 'brand.color_primary';
update public.app_settings set value = '"#0F2F57"'      where key = 'brand.color_dark';
update public.app_settings set value = '"#6497C8"'      where key = 'brand.color_accent';
update public.app_settings set value = '"Participant"'  where key = 'wording.client';

-- Adds a custom field to a register (used only while running this file).
create function pg_temp.field(
  p_registry text, p_key text, p_label text, p_type text,
  p_required boolean default false, p_options text[] default '{}', p_order int default 0
) returns void language sql as $$
  insert into public.registry_fields (registry_id, key, label, type, required, options, sort_order)
  select id, p_key, p_label, p_type, p_required, to_jsonb(p_options), p_order
    from public.registries where prefix = p_registry
  on conflict (registry_id, key) do nothing;
$$;

insert into public.registries
  (name, prefix, description, kind, requires_approval, sort_order, title_label, description_label,
   show_review_date, review_label, show_outcome, outcome_label)
values
  ('Conflict of Interest Register', 'COI', 'Declared conflicts of interest and how they are managed.', 'tasks',
   true, 10, 'Title', 'Description of the conflict of interest', true, 'Review date', true, 'Actions taken'),
  ('Risk Management Register', 'RSK', 'Identified risks, their rating and how they are reduced.', 'tasks',
   true, 20, 'Task title', 'Risk description', true, 'Review date', true, 'Risk reduction strategies'),
  ('Maintenance and Repair Register', 'MNT', 'Repairs and upkeep of houses, equipment and cars.', 'tasks',
   false, 30, 'Task title', 'Repair or maintenance required', true, 'Next scheduled', false, 'Outcome'),
  ('Document Control Register', 'DOC', 'Changes to policies, procedures and forms.', 'tasks',
   true, 40, 'Task title', 'Description of changes', true, 'Next review', false, 'Outcome'),
  ('Complaints and Feedback Register', 'CFB', 'Complaints, compliments, feedback and suggestions.', 'tasks',
   true, 50, 'Task title', 'Report details', true, 'Review date', true, 'Outcome'),
  ('Continuous Improvement Register', 'CIR', 'Improvements to how the company works.', 'tasks',
   false, 60, 'Task title', 'Description', true, 'Review date', true, 'Actions taken'),
  ('Asset Register', 'AST', 'Equipment and other things the company owns.', 'records',
   false, 70, 'Description', 'Notes', false, 'Review date', false, 'Outcome')
on conflict do nothing;

-- Conflict of Interest
select pg_temp.field('COI', 'person_declaring', 'Person declaring', 'person', true, '{}', 10);
select pg_temp.field('COI', 'position', 'Position', 'text', false, '{}', 20);
select pg_temp.field('COI', 'conflict_with', 'Person or company with conflict', 'text', true, '{}', 30);

-- Risk Management
select pg_temp.field('RSK', 'risk_rating', 'Risk rating', 'choice', true, '{Low,Medium,High,Extreme}', 10);
select pg_temp.field('RSK', 'consequence', 'Consequence of risk', 'long_text', false, '{}', 20);
select pg_temp.field('RSK', 'effectiveness', 'Effectiveness of controls', 'choice', false,
  '{"Effective","Partly effective","Not effective","Not yet reviewed"}', 30);

-- Maintenance and Repair
select pg_temp.field('MNT', 'triggers', 'Triggers', 'choice', false,
  '{"Breakdown","Damage","Scheduled service","Safety check","Complaint","Other"}', 10);
select pg_temp.field('MNT', 'asset', 'Asset', 'asset', false, '{}', 20);
select pg_temp.field('MNT', 'date_allocated', 'Date allocated', 'date', false, '{}', 30);
select pg_temp.field('MNT', 'provider', 'Repair and maintenance provider details', 'long_text', false, '{}', 40);
select pg_temp.field('MNT', 'date_undertaken', 'Date undertaken', 'date', false, '{}', 50);

-- Document Control
select pg_temp.field('DOC', 'document_title', 'Document title', 'text', true, '{}', 10);
select pg_temp.field('DOC', 'version_no', 'Version no.', 'text', false, '{}', 20);
select pg_temp.field('DOC', 'reason_for_change', 'Reason for change', 'long_text', false, '{}', 30);
select pg_temp.field('DOC', 'new_version_no', 'New version no.', 'text', false, '{}', 40);

-- Complaints and Feedback
select pg_temp.field('CFB', 'report_type', 'Report type', 'choice', true,
  '{"Complaint","Compliment","Feedback","Suggestion"}', 10);
select pg_temp.field('CFB', 'reporting_manager', 'Reporting manager', 'person', false, '{}', 20);
select pg_temp.field('CFB', 'investigation', 'Detailed investigation', 'long_text', false, '{}', 30);

-- Continuous Improvement
select pg_temp.field('CIR', 'source', 'Source of feedback', 'choice', false,
  '{"Participant","Family or carer","Staff","Audit","Incident","Complaint","Other"}', 10);
select pg_temp.field('CIR', 'standards', 'Relevant standards', 'multi_choice', false,
  '{"Rights and responsibilities","Governance and operational management","Provision of supports","Support provision environment"}', 20);

-- Asset Register (a records list)
select pg_temp.field('AST', 'brand', 'Brand name', 'text', false, '{}', 10);
select pg_temp.field('AST', 'model', 'Model number', 'text', false, '{}', 20);
select pg_temp.field('AST', 'serial', 'Serial number', 'text', false, '{}', 30);
select pg_temp.field('AST', 'purchase_value', 'Purchase value', 'money', false, '{}', 40);
select pg_temp.field('AST', 'purchase_date', 'Purchase date', 'date', false, '{}', 50);
select pg_temp.field('AST', 'useful_life', 'Useful life (years)', 'number', false, '{}', 60);
select pg_temp.field('AST', 'current_value', 'Current value', 'money', false, '{}', 70);
select pg_temp.field('AST', 'location', 'Location', 'text', false, '{}', 80);
select pg_temp.field('AST', 'status', 'Status', 'choice', false,
  '{"In use","In storage","Being repaired","Disposed"}', 90);
