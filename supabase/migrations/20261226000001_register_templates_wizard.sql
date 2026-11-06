-- Staff Portal · © cmeproject. All rights reserved.
--
-- Register templates and the setup wizard (cmeprojects).
--   * Every copy carries a library of standard NDIS registers as templates.
--     A new copy starts with General tasks only; the system admin (or people
--     given "Adding registers") adds the ones they want, now or later.
--   * setup.completed: a new, empty copy opens the setup wizard for the
--     system admin until it's finished. Copies already in use skip it.

create table if not exists public.register_templates (
  key         text primary key,
  name        text not null,
  prefix      text not null check (prefix ~ '^[A-Z0-9]{2,6}$'),
  description text not null default '',
  kind        text not null default 'tasks' check (kind in ('tasks', 'records')),
  settings    jsonb not null default '{}'::jsonb,
  fields      jsonb not null default '[]'::jsonb,
  sort_order  int not null default 0
);

alter table public.register_templates enable row level security;
drop policy if exists "members read register templates" on public.register_templates;
create policy "members read register templates" on public.register_templates
  for select to authenticated using (public.is_member());
revoke insert, update, delete, truncate on public.register_templates from anon, authenticated;

-- The library. Wording is neutral, for any provider; everything can be changed after adding.
insert into public.register_templates (key, name, prefix, description, kind, settings, fields, sort_order) values
  ('incidents', 'Incident Register', 'INC', 'Incidents and near misses, including reportable incidents.', 'tasks',
   '{"requires_approval": true, "title_label": "Incident title", "description_label": "What happened", "show_review_date": true, "review_label": "Review date", "show_outcome": true, "outcome_label": "Actions taken", "outcome_required": true}',
   '[{"key": "incident_type", "label": "Incident type", "type": "choice", "required": true, "options": ["Injury", "Near miss", "Behaviour", "Medication", "Property damage", "Abuse or neglect", "Other"]},
     {"key": "incident_date", "label": "Date of incident", "type": "date", "required": true},
     {"key": "location", "label": "Location", "type": "text"},
     {"key": "people_involved", "label": "People involved", "type": "long_text"},
     {"key": "reportable", "label": "Reportable to the NDIS Commission", "type": "yes_no"},
     {"key": "severity", "label": "Severity", "type": "choice", "options": ["Low", "Medium", "High", "Extreme"], "option_colors": {"Low": "green", "Medium": "yellow", "High": "orange", "Extreme": "red"}}]', 10),
  ('conflict_of_interest', 'Conflict of Interest Register', 'COI', 'Declared conflicts of interest and how they are managed.', 'tasks',
   '{"requires_approval": true, "title_label": "Title", "description_label": "Description of the conflict of interest", "show_review_date": true, "review_label": "Review date", "show_outcome": true, "outcome_label": "Actions taken", "outcome_required": true}',
   '[{"key": "person_declaring", "label": "Person declaring", "type": "person", "required": true},
     {"key": "position", "label": "Position", "type": "text"},
     {"key": "conflict_with", "label": "Person or company with conflict", "type": "text", "required": true}]', 20),
  ('risks', 'Risk Management Register', 'RSK', 'Identified risks, their rating and how they are reduced.', 'tasks',
   '{"requires_approval": true, "title_label": "Task title", "description_label": "Risk description", "show_review_date": true, "review_label": "Review date", "show_outcome": true, "outcome_label": "Risk reduction strategies", "outcome_required": true}',
   '[{"key": "risk_rating", "label": "Risk rating", "type": "choice", "required": true, "options": ["Low", "Medium", "High", "Extreme"], "option_colors": {"Low": "green", "Medium": "yellow", "High": "orange", "Extreme": "red"}},
     {"key": "consequence", "label": "Consequence of risk", "type": "long_text", "required": true},
     {"key": "effectiveness", "label": "Effectiveness of controls", "type": "choice", "required": true, "options": ["Effective", "Partly effective", "Not effective", "Not yet reviewed"], "option_colors": {"Effective": "green", "Partly effective": "orange", "Not effective": "red", "Not yet reviewed": "grey"}}]', 30),
  ('maintenance', 'Maintenance and Repair Register', 'MNT', 'Repairs and upkeep of houses, equipment and cars.', 'tasks',
   '{"requires_approval": false, "title_label": "Task title", "description_label": "Repair or maintenance required", "show_review_date": true, "review_label": "Next scheduled", "show_outcome": false, "outcome_label": "Outcome"}',
   '[{"key": "triggers", "label": "Triggers", "type": "choice", "options": ["Breakdown", "Damage", "Scheduled service", "Safety check", "Complaint", "Other"]},
     {"key": "asset", "label": "Asset", "type": "asset"},
     {"key": "date_allocated", "label": "Date allocated", "type": "date"},
     {"key": "provider", "label": "Repair and maintenance provider details", "type": "long_text"},
     {"key": "date_undertaken", "label": "Date undertaken", "type": "date"}]', 40),
  ('documents', 'Document Control Register', 'DOC', 'Changes to policies, procedures and forms.', 'tasks',
   '{"requires_approval": true, "title_label": "Task title", "description_label": "Description of changes", "show_review_date": true, "review_label": "Next review", "show_outcome": false, "outcome_label": "Outcome"}',
   '[{"key": "document_title", "label": "Document title", "type": "text", "required": true},
     {"key": "version_no", "label": "Version no.", "type": "text"},
     {"key": "reason_for_change", "label": "Reason for change", "type": "long_text"},
     {"key": "new_version_no", "label": "New version no.", "type": "text"}]', 50),
  ('complaints', 'Complaints and Feedback Register', 'CFB', 'Complaints, compliments, feedback and suggestions.', 'tasks',
   '{"requires_approval": true, "title_label": "Task title", "description_label": "Report details", "show_review_date": true, "review_label": "Review date", "show_outcome": true, "outcome_label": "Outcome", "outcome_required": true}',
   '[{"key": "report_type", "label": "Report type", "type": "choice", "required": true, "options": ["Complaint", "Compliment", "Feedback", "Suggestion"]},
     {"key": "reporting_manager", "label": "Reporting manager", "type": "person"},
     {"key": "investigation", "label": "Detailed investigation", "type": "long_text"}]', 60),
  ('improvement', 'Continuous Improvement Register', 'CIR', 'Improvements to how the organisation works.', 'tasks',
   '{"requires_approval": false, "title_label": "Task title", "description_label": "Description", "show_review_date": true, "review_label": "Review date", "show_outcome": true, "outcome_label": "Actions taken", "outcome_required": true}',
   '[{"key": "source", "label": "Source of feedback", "type": "choice", "options": ["Participant", "Family or carer", "Staff", "Audit", "Incident", "Complaint", "Other"]},
     {"key": "standards", "label": "Relevant standards", "type": "multi_choice", "options": ["Rights and responsibilities", "Governance and operational management", "Provision of supports", "Support provision environment"]}]', 70),
  ('assets', 'Asset Register', 'AST', 'Equipment and other things the organisation owns.', 'records',
   '{"title_label": "Description", "description_label": "Notes", "show_review_date": false, "show_outcome": false}',
   '[{"key": "brand", "label": "Brand name", "type": "text"},
     {"key": "model", "label": "Model number", "type": "text"},
     {"key": "serial", "label": "Serial number", "type": "text"},
     {"key": "purchase_value", "label": "Purchase value", "type": "money"},
     {"key": "purchase_date", "label": "Purchase date", "type": "date"},
     {"key": "useful_life", "label": "Useful life (years)", "type": "number"},
     {"key": "current_value", "label": "Current value", "type": "money"},
     {"key": "location", "label": "Location", "type": "text"},
     {"key": "status", "label": "Status", "type": "choice", "options": ["In use", "In storage", "Being repaired", "Disposed"]}]', 80)
on conflict (key) do nothing;

-- Add a register from a template (the system admin, or people given "Adding
-- registers"). Returns the new register's id; refuses if its prefix is already used.
create or replace function public.add_register_from_template(p_key text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.register_templates;
  v_id uuid;
  f jsonb;
  i int := 0;
begin
  if not public.can_admin_area('registers') then
    raise exception 'Only people the system admin chose can add registers.';
  end if;
  select * into t from public.register_templates where key = p_key;
  if t.key is null then
    raise exception 'That template doesn''t exist.';
  end if;
  if exists (select 1 from public.registries where prefix = t.prefix) then
    raise exception '% is already added (or another register uses the prefix %).', t.name, t.prefix;
  end if;

  insert into public.registries
    (name, prefix, description, kind, requires_approval, sort_order, title_label, description_label,
     show_review_date, review_label, show_outcome, outcome_label, outcome_required)
  values
    (t.name, t.prefix, t.description, t.kind,
     coalesce((t.settings ->> 'requires_approval')::boolean, false),
     coalesce((select max(sort_order) from public.registries), 0) + 10,
     coalesce(t.settings ->> 'title_label', 'Title'),
     coalesce(t.settings ->> 'description_label', 'Description'),
     coalesce((t.settings ->> 'show_review_date')::boolean, false),
     coalesce(t.settings ->> 'review_label', 'Review date'),
     coalesce((t.settings ->> 'show_outcome')::boolean, false),
     coalesce(t.settings ->> 'outcome_label', 'Outcome'),
     coalesce((t.settings ->> 'outcome_required')::boolean, false))
  returning id into v_id;

  for f in select * from jsonb_array_elements(t.fields) loop
    i := i + 10;
    insert into public.registry_fields (registry_id, key, label, type, required, options, sort_order, option_colors)
    values (v_id, f ->> 'key', f ->> 'label', f ->> 'type', coalesce((f ->> 'required')::boolean, false),
            coalesce(f -> 'options', '[]'::jsonb), i, coalesce(f -> 'option_colors', '{}'::jsonb));
  end loop;

  perform public.write_audit('register_added_from_template', 'registry', v_id::text, jsonb_build_object('template', p_key));
  return v_id;
end;
$$;

revoke execute on function public.add_register_from_template(text) from public, anon;
grant execute on function public.add_register_from_template(text) to authenticated;

-- The setup wizard: on for a brand-new copy, off for copies already in use.
insert into public.app_settings (key, value, label, description)
select 'setup.completed',
       to_jsonb(exists (select 1 from public.registries where not is_default)
                or coalesce((select value #>> '{}' from public.app_settings where key = 'brand.company_name'), 'My Company') <> 'My Company'),
       'Setup finished', 'Whether the first-time setup wizard has been completed.'
on conflict (key) do nothing;
