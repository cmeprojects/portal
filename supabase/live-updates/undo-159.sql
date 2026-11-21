-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 159 (assessments). Safe to run again.
-- Removes templates, assessments and findings (their change-log entries stay)
-- and the "Assessments" and "Assessment templates" access parts.
begin;
drop table if exists public.assessment_findings;
drop table if exists public.client_assessments;
drop table if exists public.assessment_questions;
drop table if exists public.assessment_sections;
drop table if exists public.assessment_versions;
drop table if exists public.assessment_templates;
drop function if exists public.assessment_new_version(uuid);
drop function if exists public.assessment_check(uuid);
drop function if exists public.assessment_question_visible(uuid, jsonb);
drop function if exists public.assessment_answer_problem(text, jsonb, jsonb, text, jsonb);
drop function if exists public.assessment_rule_ok(jsonb, jsonb);
drop function if exists public.assessment_condition_ok(jsonb, jsonb);
drop function if exists public.guard_assessment_template();
drop function if exists public.guard_assessment_version();
drop function if exists public.guard_assessment_part();
drop function if exists public.guard_client_assessment();
drop function if exists public.sync_assessment();
drop function if exists public.guard_assessment_finding();
delete from public.client_staff_views where area = 'assessment';
alter table public.client_staff_views drop constraint if exists client_staff_views_area_check;
alter table public.client_staff_views add constraint client_staff_views_area_check check (area in ('profile', 'audit_trail'));
update public.download_log set action = 'export' where action = 'print';
alter table public.download_log drop constraint if exists download_log_action_check;
alter table public.download_log add constraint download_log_action_check check (action in ('export', 'download_link_issued', 'download_denied'));
update public.access_baselines set revoked_at = now() where module_id = 'clients.assessments' and revoked_at is null;
update public.app_modules set status = 'retired' where id in ('clients.assessments', 'system.settings.assessments')
   and (exists (select 1 from public.access_baselines b where b.module_id = app_modules.id) or exists (select 1 from public.access_grants g where g.module_id = app_modules.id));
delete from public.app_modules where id in ('clients.assessments', 'system.settings.assessments')
   and not exists (select 1 from public.access_baselines b where b.module_id = app_modules.id) and not exists (select 1 from public.access_grants g where g.module_id = app_modules.id);
commit;
