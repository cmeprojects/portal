-- Staff Portal · © cmeproject. All rights reserved.
--
-- INSTALL OR UPDATE (cmeprojects). Safe to run again, on any copy:
--   * a brand-new, empty Supabase project: sets up everything;
--   * a copy that's already in use: adds only what's missing (each part is
--     recorded in public.install_log and skipped next time).
-- Built from every migration up to: 20270120000001_step4_forms_reports.sql
-- New copy afterwards: run a company file (supabase/companies/...), then
-- sign in: the first person to sign in becomes the system admin.

create table if not exists public.install_log (
  name       text primary key,
  applied_at timestamptz not null default now()
);
alter table public.install_log enable row level security;
revoke all on public.install_log from anon, authenticated;

-- Older copies first need two access levels added on their own (Supabase runs
-- a pasted script as one transaction, where a new access level can't be used
-- straight away). Stops with the two lines to run if they're missing.
do $roles$
begin
  if to_regtype('public.app_role') is not null and (
       not exists (select 1 from pg_enum where enumtypid = to_regtype('public.app_role') and enumlabel = 'new_starter')
    or not exists (select 1 from pg_enum where enumtypid = to_regtype('public.app_role') and enumlabel = 'external')) then
    raise exception 'First run these two lines on their own (new query, Run), then run this file again:  alter type public.app_role add value if not exists ''new_starter'';  alter type public.app_role add value if not exists ''external'';';
  end if;
end;
$roles$;

-- A copy set up before the log existed: work out how far it got (the newest
-- part whose objects are there) and record everything up to it.
do $baseline$
declare
  v_upto int := 0;
begin
  if exists (select 1 from public.install_log) or to_regclass('public.profiles') is null then
    return;
  end if;
  if v_upto = 0 and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'profiles' and column_name = 'is_owner') then v_upto := 91; end if;
  if v_upto = 0 and to_regclass('public.admin_designations') is not null then v_upto := 90; end if;
  if v_upto = 0 and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'app_modules' and column_name = 'legacy_kind') and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'app_modules' and column_name = 'legacy_area') and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'app_modules' and column_name = 'actions') and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'app_modules' and column_name = 'added_at') then v_upto := 86; end if;
  if v_upto = 0 and to_regclass('public.app_modules') is not null and to_regclass('public.pinned_items') is not null then v_upto := 85; end if;
  if v_upto = 0 and to_regclass('public.staff_tax') is not null then v_upto := 84; end if;
  if v_upto = 0 and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'contracts' and column_name = 'letterhead') then v_upto := 83; end if;
  if v_upto = 0 and to_regclass('public.staff_birthdays') is not null then v_upto := 82; end if;
  if v_upto = 0 and to_regclass('public.compliance_item_versions') is not null and to_regclass('public.contracts') is not null and to_regclass('public.contract_signatures') is not null and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'compliance_items' and column_name = 'applies_people') then v_upto := 81; end if;
  if v_upto = 0 and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'assistant_settings' and column_name = 'blocked_sites') then v_upto := 80; end if;
  if v_upto = 0 and to_regclass('public.staff_bank') is not null and to_regclass('public.staff_super') is not null and to_regclass('public.staff_work_rights') is not null and to_regclass('public.sensitive_access_log') is not null then v_upto := 79; end if;
  if v_upto = 0 and to_regclass('public.access_grants') is not null then v_upto := 78; end if;
  if v_upto = 0 and to_regclass('public.compliance_opens') is not null and to_regclass('public.work_overrides') is not null and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'compliance_status_all') and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'compliance_items' and column_name = 'category') then v_upto := 75; end if;
  if v_upto = 0 and to_regclass('public.request_types') is not null and to_regclass('public.requests') is not null and to_regclass('public.request_events') is not null and to_regclass('public.leave_periods') is not null then v_upto := 73; end if;
  if v_upto = 0 and to_regclass('public.staff_directory') is not null and to_regclass('public.staff_private') is not null then v_upto := 72; end if;
  if v_upto = 0 and to_regclass('public.client_teams') is not null and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'tasks' and column_name = 'client_id') then v_upto := 71; end if;
  if v_upto = 0 and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'profiles' and column_name = 'avatar_ref') and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'compliance_items' and column_name = 'sets_photo') then v_upto := 70; end if;
  if v_upto = 0 and to_regclass('public.register_templates') is not null then v_upto := 68; end if;
  if v_upto = 0 and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'profiles' and column_name = 'mfa_exempt') then v_upto := 65; end if;
  if v_upto = 0 and to_regclass('public.delegation_shares') is not null and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'registries' and column_name = 'create_roles') then v_upto := 64; end if;
  if v_upto = 0 and to_regclass('public.delegation_rules') is not null and to_regclass('public.settings_drafts') is not null and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'features' and column_name = 'parent') then v_upto := 63; end if;
  if v_upto = 0 and to_regclass('public.demo_records') is not null then v_upto := 60; end if;
  if v_upto = 0 and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'assistant_settings' and column_name = 'credit_aud') and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'assistant_settings' and column_name = 'credit_since') then v_upto := 57; end if;
  if v_upto = 0 and to_regclass('public.assistant_chats') is not null and to_regclass('public.assistant_messages') is not null and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'assistant_settings' and column_name = 'suggestions') and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'assistant_settings' and column_name = 'show_credits') then v_upto := 55; end if;
  if v_upto = 0 and to_regclass('public.sign_in_failures') is not null then v_upto := 54; end if;
  if v_upto = 0 and to_regclass('public.assistant_settings') is not null and to_regclass('public.assistant_documents') is not null and to_regclass('public.assistant_chunks') is not null and to_regclass('public.assistant_questions') is not null then v_upto := 53; end if;
  if v_upto = 0 and to_regclass('public.custom_alert_runs') is not null and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'custom_alerts' and column_name = 'at_hour') then v_upto := 52; end if;
  if v_upto = 0 and to_regclass('public.forms') is not null and to_regclass('public.form_questions') is not null and to_regclass('public.form_collaborators') is not null and to_regclass('public.form_recipients') is not null then v_upto := 49; end if;
  if v_upto = 0 and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'tasks' and column_name = 'escalated_to') and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'tasks' and column_name = 'escalated_by') then v_upto := 48; end if;
  if v_upto = 0 and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'custom_features' and column_name = 'in_app') and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'custom_features' and column_name = 'app_icon') and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'custom_features' and column_name = 'app_colour') then v_upto := 46; end if;
  if v_upto = 0 and to_regclass('public.custom_alerts') is not null then v_upto := 45; end if;
  if v_upto = 0 and to_regclass('public.live_signals') is not null and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'cars' and column_name = 'changed_at') then v_upto := 42; end if;
  if v_upto = 0 and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'car_trips' and column_name = 'went_to') then v_upto := 41; end if;
  if v_upto = 0 and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'custom_features' and column_name = 'managers_fix') and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'custom_features' and column_name = 'managers_targets') and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'custom_features' and column_name = 'managers_options') and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'custom_fields' and column_name = 'add_typed') then v_upto := 37; end if;
  if v_upto = 0 and to_regclass('public.custom_features') is not null and to_regclass('public.custom_fields') is not null and to_regclass('public.custom_entries') is not null and to_regclass('public.custom_client_targets') is not null then v_upto := 36; end if;
  if v_upto = 0 and to_regclass('public.email_throttle') is not null then v_upto := 35; end if;
  if v_upto = 0 and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'features' and column_name = 'premium') and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'features' and column_name = 'included') then v_upto := 33; end if;
  if v_upto = 0 and to_regclass('public.system_heartbeat') is not null and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'system_health') then v_upto := 30; end if;
  if v_upto = 0 and to_regclass('public.cars') is not null and to_regclass('public.car_clients') is not null and to_regclass('public.car_purposes') is not null and to_regclass('public.car_trips') is not null then v_upto := 29; end if;
  if v_upto = 0 and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'submit_compliance_upload_for') and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'compliance_records' and column_name = 'uploaded_by') then v_upto := 28; end if;
  if v_upto = 0 and to_regclass('public.admin_delegations') is not null and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'can_admin_area') and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'setting_area') and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'set_delegation') then v_upto := 27; end if;
  if v_upto = 0 and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'task_missing_fields') and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'registries' and column_name = 'outcome_required') then v_upto := 24; end if;
  if v_upto = 0 and to_regclass('public.task_attachments') is not null and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'can_approve_task') and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'task_people') and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'task_label') then v_upto := 22; end if;
  if v_upto = 0 and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'can_see_scoreboard') and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'staff_scoreboard') then v_upto := 20; end if;
  if v_upto = 0 and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'sees_register_overview') and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'register_open_counts') and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'register_overview') then v_upto := 19; end if;
  if v_upto = 0 and to_regclass('public.notifications') is not null and to_regclass('public.compliance_items') is not null and to_regclass('public.compliance_records') is not null and to_regclass('public.compliance_alerts') is not null then v_upto := 18; end if;
  if v_upto = 0 and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'rule_on') then v_upto := 17; end if;
  if v_upto = 0 and to_regclass('public.task_alerts') is not null and to_regclass('public.daily_runs') is not null and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'working_days_between') and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'task_managers') then v_upto := 13; end if;
  if v_upto = 0 and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'my_request_updates') and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'mark_request_updates_seen') and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'people_change_requests' and column_name = 'requester_seen_at') then v_upto := 12; end if;
  if v_upto = 0 and to_regclass('public.job_titles') is not null and to_regclass('public.team_members') is not null and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'guard_job_title') and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'sync_title_and_role') then v_upto := 11; end if;
  if v_upto = 0 and to_regclass('public.people_change_requests') is not null and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'add_change_request') and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'request_role_change') and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'request_team_change') then v_upto := 10; end if;
  if v_upto = 0 and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'registries' and column_name = 'sla_days') then v_upto := 9; end if;
  if v_upto = 0 and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'can_manage_people') and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'can_manage_role') and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'can_take_tasks') and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'guard_task_people') then v_upto := 8; end if;
  if v_upto = 0 and exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'registry_fields' and column_name = 'option_colors') then v_upto := 7; end if;
  if v_upto = 0 and to_regclass('public.task_views') is not null and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'my_new_tasks') and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'mark_task_seen') and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'mark_all_tasks_seen') then v_upto := 6; end if;
  if v_upto = 0 and to_regclass('public.registry_fields') is not null and to_regclass('public.records') is not null and to_regclass('public.record_events') is not null and exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'manages_registry') then v_upto := 4; end if;
  if v_upto = 0 and to_regclass('public.tasks') is not null and to_regclass('public.task_helpers') is not null and to_regclass('public.task_events') is not null and to_regclass('public.email_outbox') is not null then v_upto := 3; end if;
  if v_upto = 0 and to_regclass('public.organisation') is not null and to_regclass('public.app_settings') is not null and to_regclass('public.features') is not null and to_regclass('public.teams') is not null then v_upto := 1; end if;
  insert into public.install_log (name)
  select x.name from (values
    (1, '20261027000001_foundations.sql'),
    (2, '20261028000001_two_factor_switch.sql'),
    (3, '20261029000001_tasks.sql'),
    (4, '20261030000001_registers.sql'),
    (5, '20261031000001_logo_mark.sql'),
    (6, '20261101000001_task_notifications.sql'),
    (7, '20261102000001_choice_colours.sql'),
    (8, '20261103000001_managers_manage_people.sql'),
    (9, '20261104000001_sla.sql'),
    (10, '20261105000001_staff_admin_scope_and_sla_editors.sql'),
    (11, '20261106000001_teams_and_job_titles.sql'),
    (12, '20261107000001_request_notifications.sql'),
    (13, '20261108000001_due_alerts.sql'),
    (14, '20261109000001_quiet_reminders.sql'),
    (15, '20261110000001_new_starter_role.sql'),
    (16, '20261110000002_general_invites.sql'),
    (17, '20261110000003_people_rules.sql'),
    (18, '20261111000001_onboarding_and_compliance.sql'),
    (19, '20261112000001_staff_admin_register_overview.sql'),
    (20, '20261112000002_scoreboard.sql'),
    (21, '20261113000001_mfa_methods.sql'),
    (22, '20261114000001_task_workflow.sql'),
    (23, '20261115000001_keep_one_manager.sql'),
    (24, '20261116000001_required_before_completing.sql'),
    (25, '20261117000001_customisation.sql'),
    (26, '20261118000001_manager_own_tasks.sql'),
    (27, '20261119000001_delegation.sql'),
    (28, '20261120000001_upload_for_staff.sql'),
    (29, '20261121000001_cars.sql'),
    (30, '20261122000001_system_health.sql'),
    (31, '20261123000001_compliance_report.sql'),
    (32, '20261124000001_registers_menu.sql'),
    (33, '20261125000001_premium_features.sql'),
    (34, '20261126000001_weekly_recipients.sql'),
    (35, '20261127000001_sign_in_help.sql'),
    (36, '20261128000001_feature_builder.sql'),
    (37, '20261129000001_feature_manager_rights.sql'),
    (38, '20261129000002_conditional_role_nothing_left.sql'),
    (39, '20261130000001_staff_admin_role_approval.sql'),
    (40, '20261130000002_cars_app_look.sql'),
    (41, '20261130000003_car_trip_where.sql'),
    (42, '20261201000001_live_updates.sql'),
    (43, '20261202000001_compliance_report_wording.sql'),
    (44, '20261203000001_live_tasks.sql'),
    (45, '20261204000001_feature_alerts.sql'),
    (46, '20261205000001_staff_app.sql'),
    (47, '20261205000002_role_changed_notice.sql'),
    (48, '20261206000001_escalate_to.sql'),
    (49, '20261207000001_forms.sql'),
    (50, '20261208000001_forms_anonymous_choice.sql'),
    (51, '20261209000001_forms_questions.sql'),
    (52, '20261210000001_time_alerts.sql'),
    (53, '20261211000001_assistant_website.sql'),
    (54, '20261212000001_quick_fixes.sql'),
    (55, '20261213000001_website_v2.sql'),
    (56, '20261214000001_limited_tasks.sql'),
    (57, '20261215000001_website_round2.sql'),
    (58, '20261216000001_enquiry_intake.sql'),
    (59, '20261217000001_website_about_seo.sql'),
    (60, '20261218000001_demo_data.sql'),
    (61, '20261219000001_reports_premium.sql'),
    (62, '20261220000001_sign_out_devices.sql'),
    (63, '20261221000001_settings_revamp.sql'),
    (64, '20261222000001_round3.sql'),
    (65, '20261223000001_mfa_per_person.sql'),
    (66, '20261224000001_register_setup_delegation.sql'),
    (67, '20261225000001_neutral_examples.sql'),
    (68, '20261226000001_register_templates_wizard.sql'),
    (69, '20261227000001_delete_unused_registers.sql'),
    (70, '20261228000001_staff_photos.sql'),
    (71, '20261229000001_client_teams.sql'),
    (72, '20261230000001_hr_pack_profiles.sql'),
    (73, '20261231000001_my_requests.sql'),
    (74, '20270101000001_profile_requirement.sql'),
    (75, '20270102000001_onboarding_clearance.sql'),
    (76, '20270103000001_clearance_settings.sql'),
    (77, '20270104000001_rls_once_per_statement.sql'),
    (78, '20270105000001_access_grants.sql'),
    (79, '20270106000001_staff_records.sql'),
    (80, '20270107000001_assistant_internet.sql'),
    (81, '20270108000001_contracts.sql'),
    (82, '20270109000001_celebrations.sql'),
    (83, '20270110000001_contract_letterhead.sql'),
    (84, '20270111000001_tfn_records.sql'),
    (85, '20270112000001_module_catalogue.sql'),
    (86, '20270113000001_permission_engine.sql'),
    (87, '20270114000001_menu_tidy.sql'),
    (88, '20270115000001_portal_settings.sql'),
    (89, '20270116000001_admin_two_items.sql'),
    (90, '20270117000001_manager_admins.sql'),
    (91, '20270118000001_owner.sql'),
    (92, '20270119000001_step4_onboarding_cars.sql'),
    (93, '20270120000001_step4_forms_reports.sql')
  ) as x(n, name) where x.n <= v_upto
  on conflict do nothing;
end;
$baseline$;

-- ====================================================================
-- 20261027000001_foundations.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261027000001_foundations.sql') then
    return;
  end if;
  execute $m001$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Milestone 1: foundations.
-- People, roles, teams, registries, invitations, system settings, feature
-- switches and an append-only audit log. Every table has Row Level Security
-- on, so access is enforced by the database and not just the screens.
--
-- One company per install: each company has its own Supabase project.
-- The org_id column is a hidden "company" tag kept for a possible shared
-- (multi-company) version later. It is filled in automatically.

-- ---------------------------------------------------------------------------
-- Types
-- ---------------------------------------------------------------------------

create type public.app_role as enum (
  'new_starter',
  'support_worker',
  'team_leader',
  'manager',
  'staff_admin',
  'system_admin',
  'external'
);

-- ---------------------------------------------------------------------------
-- Company (one row per install)
-- ---------------------------------------------------------------------------

create table public.organisation (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  created_at timestamptz not null default now()
);

create unique index organisation_single_row on public.organisation ((true));

create function public.default_org_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select id from public.organisation limit 1
$$;

-- ---------------------------------------------------------------------------
-- Settings and feature switches (changed only by the system admin)
-- ---------------------------------------------------------------------------

create table public.app_settings (
  key         text primary key,
  value       jsonb not null,
  label       text not null,
  description text,
  -- Public settings (branding) can be read before signing in.
  is_public   boolean not null default false,
  updated_at  timestamptz not null default now(),
  updated_by  uuid references auth.users (id)
);

create table public.features (
  key         text primary key,
  label       text not null,
  description text,
  enabled     boolean not null default true,
  sort_order  int not null default 0,
  updated_at  timestamptz not null default now(),
  updated_by  uuid references auth.users (id)
);

-- ---------------------------------------------------------------------------
-- People
-- ---------------------------------------------------------------------------

create table public.teams (
  id         uuid primary key default gen_random_uuid(),
  org_id     uuid not null default public.default_org_id() references public.organisation (id),
  name       text not null,
  active     boolean not null default true,
  created_at timestamptz not null default now()
);

create unique index teams_name_unique on public.teams (lower(name));

create table public.profiles (
  id             uuid primary key references auth.users (id) on delete restrict,
  org_id         uuid not null default public.default_org_id() references public.organisation (id),
  email          text not null,
  full_name      text not null default '',
  role           public.app_role not null default 'support_worker',
  -- The team a support worker belongs to (their team leader sees their tasks).
  team_id        uuid references public.teams (id) on delete set null,
  active         boolean not null default true,
  created_at     timestamptz not null default now(),
  deactivated_at timestamptz
);

create unique index profiles_email_unique on public.profiles (lower(email));
create index profiles_team_idx on public.profiles (team_id);

create table public.team_leaders (
  team_id uuid not null references public.teams (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  primary key (team_id, user_id)
);

-- Inviting someone creates their sign-in account straight away, so
-- accepted_at is when the account was linked; whether they have signed in
-- yet comes from the sign-in system.
create table public.invitations (
  id          uuid primary key default gen_random_uuid(),
  org_id      uuid not null default public.default_org_id() references public.organisation (id),
  email       text not null,
  full_name   text not null default '',
  role        public.app_role not null default 'support_worker',
  team_id     uuid references public.teams (id) on delete set null,
  invited_by  uuid references public.profiles (id),
  created_at  timestamptz not null default now(),
  accepted_at timestamptz,
  user_id     uuid references public.profiles (id)
);

create index invitations_email_idx on public.invitations (lower(email));

-- ---------------------------------------------------------------------------
-- Registries
-- ---------------------------------------------------------------------------

create table public.registries (
  id                uuid primary key default gen_random_uuid(),
  org_id            uuid not null default public.default_org_id() references public.organisation (id),
  name              text not null,
  description       text not null default '',
  requires_approval boolean not null default false,
  active            boolean not null default true,
  sort_order        int not null default 0,
  created_at        timestamptz not null default now()
);

create unique index registries_name_unique on public.registries (lower(name));

create table public.registry_managers (
  registry_id uuid not null references public.registries (id) on delete cascade,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  primary key (registry_id, user_id)
);

-- ---------------------------------------------------------------------------
-- Audit log (append-only: nobody can edit or delete it)
-- ---------------------------------------------------------------------------

create table public.audit_log (
  id         bigint generated always as identity primary key,
  org_id     uuid default public.default_org_id() references public.organisation (id),
  actor_id   uuid,
  action     text not null,
  entity     text not null,
  entity_id  text,
  details    jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index audit_log_created_idx on public.audit_log (created_at desc);

create function public.block_audit_changes()
returns trigger
language plpgsql
as $$
begin
  raise exception 'The audit log cannot be changed or deleted';
end;
$$;

create trigger audit_log_append_only
  before update or delete on public.audit_log
  for each row execute function public.block_audit_changes();

create trigger audit_log_no_truncate
  before truncate on public.audit_log
  for each statement execute function public.block_audit_changes();

create function public.write_audit(
  p_action text,
  p_entity text,
  p_entity_id text,
  p_details jsonb default '{}'::jsonb
)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.audit_log (actor_id, action, entity, entity_id, details)
  values (auth.uid(), p_action, p_entity, p_entity_id, coalesce(p_details, '{}'::jsonb));
$$;

-- ---------------------------------------------------------------------------
-- Who is asking? (helpers used by the security rules)
-- ---------------------------------------------------------------------------

-- The signed-in person's role, or null if they are deactivated or unknown.
create function public.my_role()
returns public.app_role
language sql
stable
security definer
set search_path = ''
as $$
  select role from public.profiles where id = auth.uid() and active
$$;

-- True when the person has finished two-factor login, or does not need it.
-- System admins always need it; other roles follow the
-- "security.mfa_required_roles" setting.
create function public.mfa_ok()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
    or (
      public.my_role() is distinct from 'system_admin'
      and not coalesce(
        (select s.value ? public.my_role()::text
           from public.app_settings s
          where s.key = 'security.mfa_required_roles'),
        false
      )
    )
$$;

-- True when the signed-in person is active, has one of the roles and has
-- passed two-factor login if their role needs it.
create function public.has_role(roles public.app_role[])
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(public.my_role() = any (roles), false) and public.mfa_ok()
$$;

create function public.is_member()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.my_role() is not null and public.mfa_ok()
$$;

create function public.is_staff_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.has_role(array['staff_admin', 'system_admin']::public.app_role[])
$$;

create function public.is_system_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.has_role(array['system_admin']::public.app_role[])
$$;

-- Does the signed-in team leader lead the team that this person is in?
-- (Used by the task rules in Milestone 2.)
create function public.leads_user(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.profiles p
      join public.team_leaders tl on tl.team_id = p.team_id
     where p.id = p_user_id
       and tl.user_id = auth.uid()
  ) and public.has_role(array['team_leader', 'manager', 'system_admin']::public.app_role[])
$$;

create function public.feature_enabled(p_key text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select enabled from public.features where key = p_key), false)
$$;

-- What the app needs to know about the signed-in person, readable before
-- two-factor login so it can send them to the right step.
create function public.my_access()
returns table (role public.app_role, active boolean, mfa_required boolean, mfa_ok boolean)
language sql
stable
security definer
set search_path = ''
as $$
  select
    p.role,
    p.active,
    p.role = 'system_admin' or coalesce(
      (select s.value ? p.role::text from public.app_settings s
        where s.key = 'security.mfa_required_roles'), false),
    public.mfa_ok()
  from public.profiles p
  where p.id = auth.uid()
$$;

revoke execute on function public.my_access() from public, anon;
grant execute on function public.my_access() to authenticated;

-- ---------------------------------------------------------------------------
-- New users: a profile is created from their invitation
-- ---------------------------------------------------------------------------

create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  inv public.invitations;
  first_user boolean;
begin
  select not exists (select 1 from public.profiles) into first_user;

  select * into inv
    from public.invitations i
   where lower(i.email) = lower(new.email)
     and i.accepted_at is null
   order by i.created_at desc
   limit 1;

  insert into public.profiles (id, email, full_name, role, team_id, active)
  values (
    new.id,
    new.email,
    coalesce(nullif(inv.full_name, ''), new.raw_user_meta_data ->> 'full_name', ''),
    case
      -- The very first account in a new install becomes its system admin.
      when first_user then 'system_admin'::public.app_role
      else coalesce(inv.role, 'support_worker'::public.app_role)
    end,
    inv.team_id,
    -- Public sign-up is off, but as a second lock anyone who arrives
    -- without an invitation starts deactivated.
    first_user or inv.id is not null
  );

  if inv.id is not null then
    update public.invitations
       set accepted_at = now(), user_id = new.id
     where id = inv.id;
  end if;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Guard rails on profile changes
-- ---------------------------------------------------------------------------

create function public.guard_profile_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor uuid := auth.uid();
  actor_role public.app_role := public.my_role();
begin
  if new.id <> old.id or new.email <> old.email or new.org_id <> old.org_id then
    raise exception 'This field cannot be changed here';
  end if;

  -- Server-side jobs (no signed-in person) skip the people rules below.
  if actor is not null then
    if new.role is distinct from old.role
       or new.team_id is distinct from old.team_id
       or new.active is distinct from old.active then

      if not public.is_staff_admin() then
        raise exception 'Only a staff admin can change roles, teams or access';
      end if;

      if actor_role <> 'system_admin'
         and (old.role in ('staff_admin', 'system_admin')
              or new.role in ('staff_admin', 'system_admin')) then
        raise exception 'Only a system admin can manage staff admins and system admins';
      end if;

      if new.id = actor and (new.role is distinct from old.role or not new.active) then
        raise exception 'You cannot change your own role or deactivate yourself';
      end if;
    end if;
  end if;

  -- Never leave the install without an active system admin.
  if old.role = 'system_admin' and old.active
     and (new.role <> 'system_admin' or not new.active)
     and not exists (
       select 1 from public.profiles
        where role = 'system_admin' and active and id <> old.id
     ) then
    raise exception 'There must always be at least one active system admin';
  end if;

  if new.active and not old.active then
    new.deactivated_at := null;
  elsif not new.active and old.active then
    new.deactivated_at := now();
  end if;

  if new.role is distinct from old.role then
    perform public.write_audit('role_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.role, 'to', new.role));
  end if;
  if new.active is distinct from old.active then
    perform public.write_audit(
      case when new.active then 'reactivated' else 'deactivated' end,
      'profile', new.id::text, '{}'::jsonb);
  end if;
  if new.team_id is distinct from old.team_id then
    perform public.write_audit('team_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.team_id, 'to', new.team_id));
  end if;

  return new;
end;
$$;

create trigger profiles_guard
  before update on public.profiles
  for each row execute function public.guard_profile_update();

-- Staff admins can invite up to manager; only a system admin can invite
-- staff admins or system admins.
create function public.guard_invitation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null
     and new.role in ('staff_admin', 'system_admin')
     and public.my_role() is distinct from 'system_admin' then
    raise exception 'Only a system admin can invite staff admins or system admins';
  end if;
  new.email := lower(trim(new.email));
  if tg_op = 'INSERT' then
    new.invited_by := coalesce(new.invited_by, auth.uid());
    perform public.write_audit('invited', 'invitation', new.email,
      jsonb_build_object('role', new.role));
  end if;
  return new;
end;
$$;

create trigger invitations_guard
  before insert or update on public.invitations
  for each row execute function public.guard_invitation();

-- Settings and features record who changed them, and every change is logged.
create function public.track_setting_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.updated_at := now();
  new.updated_by := auth.uid();
  if tg_table_name = 'features' then
    if new.enabled is distinct from old.enabled then
      perform public.write_audit(
        case when new.enabled then 'feature_on' else 'feature_off' end,
        'feature', new.key, '{}'::jsonb);
    end if;
  elsif new.value is distinct from old.value then
    perform public.write_audit('setting_changed', 'setting', new.key,
      jsonb_build_object('from', old.value, 'to', new.value));
  end if;
  return new;
end;
$$;

create trigger app_settings_track
  before update on public.app_settings
  for each row execute function public.track_setting_change();

create trigger features_track
  before update on public.features
  for each row execute function public.track_setting_change();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.organisation      enable row level security;
alter table public.app_settings      enable row level security;
alter table public.features          enable row level security;
alter table public.teams             enable row level security;
alter table public.profiles          enable row level security;
alter table public.team_leaders      enable row level security;
alter table public.invitations       enable row level security;
alter table public.registries        enable row level security;
alter table public.registry_managers enable row level security;
alter table public.audit_log         enable row level security;

-- Company
create policy "members read the company" on public.organisation
  for select to authenticated using (public.is_member());
create policy "system admin edits the company" on public.organisation
  for update to authenticated using (public.is_system_admin()) with check (public.is_system_admin());

-- Settings: branding is public (shown on the sign-in page); the rest is
-- members only. Only the system admin changes anything.
create policy "anyone reads public settings" on public.app_settings
  for select to anon, authenticated using (is_public or public.is_member());
create policy "system admin edits settings" on public.app_settings
  for update to authenticated using (public.is_system_admin()) with check (public.is_system_admin());

create policy "members read features" on public.features
  for select to authenticated using (public.is_member());
-- The sign-in page needs to know which sign-in options are switched on.
create policy "anyone reads sign-in options" on public.features
  for select to anon, authenticated using (key like 'sign\_in\_%');
create policy "system admin switches features" on public.features
  for update to authenticated using (public.is_system_admin()) with check (public.is_system_admin());

-- Profiles: you can always read your own (even before two-factor login, so
-- the app knows where to send you). Members can see colleagues so they can
-- assign tasks. Changes are checked by guard_profile_update().
create policy "read own profile" on public.profiles
  for select to authenticated using (id = auth.uid());
create policy "members read colleagues" on public.profiles
  for select to authenticated using (public.is_member());
-- Allowed before two-factor login so new people can finish the welcome
-- page; guard_profile_update() stops anything but the name changing.
create policy "update own name" on public.profiles
  for update to authenticated
  using (id = auth.uid() and public.my_role() is not null)
  with check (id = auth.uid());
create policy "staff admin updates people" on public.profiles
  for update to authenticated using (public.is_staff_admin()) with check (public.is_staff_admin());

-- Teams and registries: members read, staff admins manage.
create policy "members read teams" on public.teams
  for select to authenticated using (public.is_member());
create policy "staff admin manages teams" on public.teams
  for all to authenticated using (public.is_staff_admin()) with check (public.is_staff_admin());

create policy "members read team leaders" on public.team_leaders
  for select to authenticated using (public.is_member());
create policy "staff admin manages team leaders" on public.team_leaders
  for all to authenticated using (public.is_staff_admin()) with check (public.is_staff_admin());

create policy "members read registries" on public.registries
  for select to authenticated using (public.is_member());
create policy "staff admin manages registries" on public.registries
  for all to authenticated using (public.is_staff_admin()) with check (public.is_staff_admin());

create policy "members read registry managers" on public.registry_managers
  for select to authenticated using (public.is_member());
create policy "staff admin manages registry managers" on public.registry_managers
  for all to authenticated using (public.is_staff_admin()) with check (public.is_staff_admin());

-- Invitations: staff admins only.
create policy "staff admin reads invitations" on public.invitations
  for select to authenticated using (public.is_staff_admin());
create policy "staff admin creates invitations" on public.invitations
  for insert to authenticated with check (public.is_staff_admin());
create policy "staff admin updates invitations" on public.invitations
  for update to authenticated using (public.is_staff_admin()) with check (public.is_staff_admin());
create policy "staff admin removes pending invitations" on public.invitations
  for delete to authenticated using (public.is_staff_admin() and accepted_at is null);

-- Audit log: only the system admin reads it; rows are written by the
-- database itself (write_audit) and can never be changed.
create policy "system admin reads the audit log" on public.audit_log
  for select to authenticated using (public.is_system_admin());

-- Lets the app log admin actions that happen outside the database
-- (resending an invite, resetting someone's two-factor login).
create function public.log_admin_action(p_action text, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_action = 'mfa_reset' and not public.is_system_admin() then
    raise exception 'Only a system admin can reset two-factor login';
  elsif p_action not in ('mfa_reset', 'invite_resent') or not public.is_staff_admin() then
    raise exception 'Not allowed';
  end if;
  perform public.write_audit(p_action, 'profile', p_user_id::text, '{}'::jsonb);
end;
$$;

revoke execute on function public.log_admin_action(text, uuid) from public, anon;
grant execute on function public.log_admin_action(text, uuid) to authenticated;

revoke insert, update, delete, truncate on public.audit_log from anon, authenticated;
revoke execute on function public.write_audit(text, text, text, jsonb) from public, anon, authenticated;
revoke execute on function public.handle_new_user() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Defaults for a new install
-- ---------------------------------------------------------------------------

insert into public.organisation (name) values ('My Company');

insert into public.app_settings (key, value, label, description, is_public) values
  ('brand.company_name',  '"My Company"', 'Company name', 'Shown in the menu, on the sign-in page and in emails.', true),
  ('brand.portal_name',   '"Staff Portal"', 'Portal name', 'Shown under the company name.', true),
  ('brand.logo_url',      '"/logo.svg"', 'Logo', 'Address of the logo image.', true),
  ('brand.color_primary', '"#134F8E"', 'Main colour', 'Buttons, links and highlights.', true),
  ('brand.color_dark',    '"#0F2F57"', 'Dark colour', 'Menu and headers.', true),
  ('brand.color_accent',  '"#6497C8"', 'Accent colour', 'Decoration only, never for text.', true),
  ('wording.client',      '"Client"', 'What you call the people you support', 'For example Client, Participant, Customer or Resident.', false),
  ('security.mfa_required_roles', '["team_leader", "manager", "staff_admin", "system_admin"]',
     'Roles that must use two-factor login', 'System admins always need it.', false),
  ('records.retention_years', '7', 'Keep records for (years)', 'Records older than this can be purged by a system admin.', false);

insert into public.features (key, label, description, enabled, sort_order) values
  ('tasks',               'Tasks and registries', 'Create, assign and track tasks.', true, 10),
  ('email_notifications', 'Email notifications', 'Send emails when tasks change.', true, 20),
  ('attachments',         'Attachments', 'Photos and files on tasks.', true, 30),
  ('auto_escalation',     'Auto-escalation', 'Flag overdue high-priority tasks every night.', true, 40),
  ('reports',             'Reports and exports', 'Excel and PDF reports for managers.', true, 50),
  ('vehicles',            'Vehicles and mileage', 'Trip logging and logbooks.', false, 60),
  ('sign_in_google',      'Google sign-in', 'Show "Continue with Google" on the sign-in page.', true, 70),
  ('sign_in_magic_link',  'Email sign-in link', 'Show "Email me a sign-in link" on the sign-in page.', true, 80);

$m001$;
  insert into public.install_log (name) values ('20261027000001_foundations.sql');
end;
$part$;

-- ====================================================================
-- 20261028000001_two_factor_switch.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261028000001_two_factor_switch.sql') then
    return;
  end if;
  execute $m002$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- A main switch for two-factor login. When it is off nobody is asked for a
-- code, system admins included. Only a system admin can change it, and the
-- change is recorded in the change log like every other feature switch.

insert into public.features (key, label, description, enabled, sort_order) values
  ('two_factor', 'Two-factor login',
   'Ask for a code from an authenticator app when signing in. When off, nobody is asked, including system admins.',
   true, 5)
on conflict (key) do nothing;

create or replace function public.mfa_ok()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    not public.feature_enabled('two_factor')
    or coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
    or (
      public.my_role() is distinct from 'system_admin'
      and not coalesce(
        (select s.value ? public.my_role()::text
           from public.app_settings s
          where s.key = 'security.mfa_required_roles'),
        false
      )
    )
$$;

create or replace function public.my_access()
returns table (role public.app_role, active boolean, mfa_required boolean, mfa_ok boolean)
language sql
stable
security definer
set search_path = ''
as $$
  select
    p.role,
    p.active,
    public.feature_enabled('two_factor') and (
      p.role = 'system_admin' or coalesce(
        (select s.value ? p.role::text from public.app_settings s
          where s.key = 'security.mfa_required_roles'), false)
    ),
    public.mfa_ok()
  from public.profiles p
  where p.id = auth.uid()
$$;

$m002$;
  insert into public.install_log (name) values ('20261028000001_two_factor_switch.sql');
end;
$part$;

-- ====================================================================
-- 20261029000001_tasks.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261029000001_tasks.sql') then
    return;
  end if;
  execute $m003$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Milestone 2: tasks, helpers and email notifications.
--
-- Tasks are only changed through the functions below (create_task,
-- add_task_helper). Each one checks who is asking, records what happened in
-- the task's timeline (task_events, which can never be edited) and queues
-- the emails to send (email_outbox).

-- ---------------------------------------------------------------------------
-- Types
-- ---------------------------------------------------------------------------

create type public.task_priority as enum ('low', 'medium', 'high', 'urgent');

create type public.task_status as enum (
  'assigned',
  'in_progress',
  'escalated',
  'awaiting_approval',
  'completed',
  'closed'
);

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table public.tasks (
  id           uuid primary key default gen_random_uuid(),
  org_id       uuid not null default public.default_org_id() references public.organisation (id),
  -- Short number people can quote: T-0001, T-0002, ...
  number       bigint generated always as identity unique,
  title        text not null check (length(trim(title)) between 1 and 200),
  description  text not null default '',
  registry_id  uuid not null references public.registries (id),
  priority     public.task_priority not null default 'medium',
  status       public.task_status not null default 'assigned',
  assigned_to  uuid not null references public.profiles (id),
  created_by   uuid not null references public.profiles (id),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  due_date     date,
  escalated    boolean not null default false,
  completed_at timestamptz,
  closed_at    timestamptz
);

create index tasks_assigned_idx on public.tasks (assigned_to);
create index tasks_created_by_idx on public.tasks (created_by);
create index tasks_registry_idx on public.tasks (registry_id);
create index tasks_due_idx on public.tasks (due_date);

create table public.task_helpers (
  task_id  uuid not null references public.tasks (id) on delete cascade,
  user_id  uuid not null references public.profiles (id),
  added_by uuid references public.profiles (id),
  added_at timestamptz not null default now(),
  primary key (task_id, user_id)
);

create index task_helpers_user_idx on public.task_helpers (user_id);

-- The task's timeline. Append-only: never edited or deleted.
create table public.task_events (
  id         bigint generated always as identity primary key,
  task_id    uuid not null references public.tasks (id),
  actor_id   uuid references public.profiles (id),
  type       text not null,
  from_value text,
  to_value   text,
  comment    text,
  created_at timestamptz not null default now()
);

create index task_events_task_idx on public.task_events (task_id, created_at);

create trigger task_events_append_only
  before update or delete on public.task_events
  for each row execute function public.block_audit_changes();

create trigger task_events_no_truncate
  before truncate on public.task_events
  for each statement execute function public.block_audit_changes();

-- Emails waiting to be sent. The app sends them straight away; anything
-- that fails stays here to be retried.
create table public.email_outbox (
  id         bigint generated always as identity primary key,
  to_user    uuid not null references public.profiles (id),
  cc_users   uuid[] not null default '{}',
  template   text not null,
  task_id    uuid references public.tasks (id),
  data       jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  sent_at    timestamptz,
  attempts   int not null default 0,
  last_error text
);

create index email_outbox_pending_idx on public.email_outbox (created_at) where sent_at is null;

-- ---------------------------------------------------------------------------
-- Who can see a task
-- ---------------------------------------------------------------------------

-- Support workers: tasks assigned to them, helping on, or created by them.
-- Team leaders: also tasks of the support workers in their team.
-- Managers: also every task in the registries they manage.
-- System admins: everything.
-- Records stay readable when the Tasks feature is switched off.
create function public.can_see_task(p_task_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and exists (
    select 1
      from public.tasks t
     where t.id = p_task_id
       and (
         t.assigned_to = auth.uid()
         or t.created_by = auth.uid()
         or exists (select 1 from public.task_helpers h where h.task_id = t.id and h.user_id = auth.uid())
         or public.leads_user(t.assigned_to)
         or public.leads_user(t.created_by)
         or (
           public.has_role(array['manager', 'system_admin']::public.app_role[])
           and exists (select 1 from public.registry_managers rm
                        where rm.registry_id = t.registry_id and rm.user_id = auth.uid())
         )
         or public.is_system_admin()
       )
  )
$$;

-- ---------------------------------------------------------------------------
-- Changing tasks (only through these functions)
-- ---------------------------------------------------------------------------

-- Queue a task email, unless email notifications are switched off.
create function public.queue_task_email(
  p_template text,
  p_task_id uuid,
  p_to uuid,
  p_cc uuid[] default '{}',
  p_data jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.feature_enabled('email_notifications') then
    return;
  end if;
  -- Nobody is emailed about their own action, and inactive people never are.
  if p_to = auth.uid() or not exists (select 1 from public.profiles where id = p_to and active) then
    return;
  end if;
  insert into public.email_outbox (to_user, cc_users, template, task_id, data)
  values (
    p_to,
    coalesce((select array_agg(distinct c) from unnest(p_cc) c
               join public.profiles p on p.id = c and p.active
              where c <> p_to and c <> auth.uid()), '{}'),
    p_template, p_task_id, coalesce(p_data, '{}'::jsonb)
  );
end;
$$;

create function public.create_task(
  p_title text,
  p_registry_id uuid,
  p_assigned_to uuid,
  p_description text default '',
  p_priority public.task_priority default 'medium',
  p_due_date date default null,
  p_helpers uuid[] default '{}'
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_task_id uuid;
  v_helper uuid;
  v_manager uuid;
  v_helpers uuid[];
begin
  if not public.is_member() then
    raise exception 'Please sign in again';
  end if;
  if not public.feature_enabled('tasks') then
    raise exception 'Tasks are switched off at the moment';
  end if;
  if coalesce(trim(p_title), '') = '' then
    raise exception 'Give the task a title';
  end if;
  if not exists (select 1 from public.registries where id = p_registry_id and active) then
    raise exception 'Choose a registry that is in use';
  end if;
  if not exists (select 1 from public.profiles where id = p_assigned_to and active) then
    raise exception 'Choose someone who can sign in to look after this task';
  end if;

  select coalesce(array_agg(distinct h), '{}') into v_helpers
    from unnest(coalesce(p_helpers, '{}')) h
    join public.profiles p on p.id = h and p.active
   where h <> p_assigned_to;

  insert into public.tasks (title, description, registry_id, priority, assigned_to, created_by, due_date)
  values (trim(p_title), coalesce(trim(p_description), ''), p_registry_id, p_priority,
          p_assigned_to, auth.uid(), p_due_date)
  returning id into v_task_id;

  insert into public.task_events (task_id, actor_id, type, to_value)
  values (v_task_id, auth.uid(), 'created', p_assigned_to::text);

  foreach v_helper in array v_helpers loop
    insert into public.task_helpers (task_id, user_id, added_by) values (v_task_id, v_helper, auth.uid());
    insert into public.task_events (task_id, actor_id, type, to_value)
    values (v_task_id, auth.uid(), 'helper_added', v_helper::text);
  end loop;

  -- The person looking after it, with helpers copied in.
  perform public.queue_task_email('task_assigned', v_task_id, p_assigned_to, v_helpers);
  -- If the person looking after it is also the creator, helpers still hear.
  if p_assigned_to = auth.uid() then
    foreach v_helper in array v_helpers loop
      perform public.queue_task_email('helper_added', v_task_id, v_helper);
    end loop;
  end if;
  -- Registry managers hear about every new task.
  for v_manager in
    select rm.user_id from public.registry_managers rm
     where rm.registry_id = p_registry_id
       and rm.user_id <> p_assigned_to
       and not (rm.user_id = any (v_helpers))
  loop
    perform public.queue_task_email('task_created_manager', v_task_id, v_manager);
  end loop;

  return v_task_id;
end;
$$;

-- "Tag someone to help out": anyone who can see the task can add a helper.
create function public.add_task_helper(p_task_id uuid, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.can_see_task(p_task_id) then
    raise exception 'You can''t change this task';
  end if;
  if not public.feature_enabled('tasks') then
    raise exception 'Tasks are switched off at the moment';
  end if;
  if not exists (select 1 from public.profiles where id = p_user_id and active) then
    raise exception 'Choose someone who can sign in';
  end if;
  if exists (select 1 from public.tasks where id = p_task_id and assigned_to = p_user_id) then
    raise exception 'They are already looking after this task';
  end if;
  if exists (select 1 from public.task_helpers where task_id = p_task_id and user_id = p_user_id) then
    raise exception 'They are already helping on this task';
  end if;

  insert into public.task_helpers (task_id, user_id, added_by) values (p_task_id, p_user_id, auth.uid());
  insert into public.task_events (task_id, actor_id, type, to_value)
  values (p_task_id, auth.uid(), 'helper_added', p_user_id::text);
  update public.tasks set updated_at = now() where id = p_task_id;

  perform public.queue_task_email('helper_added', p_task_id, p_user_id);
end;
$$;

-- ---------------------------------------------------------------------------
-- Row Level Security: read-only from the app; changes go through functions
-- ---------------------------------------------------------------------------

alter table public.tasks        enable row level security;
alter table public.task_helpers enable row level security;
alter table public.task_events  enable row level security;
alter table public.email_outbox enable row level security;

create policy "see tasks you have access to" on public.tasks
  for select to authenticated using (public.can_see_task(id));
create policy "see helpers on tasks you have access to" on public.task_helpers
  for select to authenticated using (public.can_see_task(task_id));
create policy "see the timeline of tasks you have access to" on public.task_events
  for select to authenticated using (public.can_see_task(task_id));
-- email_outbox: no policies, so only the server (service role) can read it.

revoke insert, update, delete, truncate on public.tasks, public.task_helpers, public.task_events, public.email_outbox
  from anon, authenticated;
revoke all on public.email_outbox from anon, authenticated;

revoke execute on function public.queue_task_email(text, uuid, uuid, uuid[], jsonb) from public, anon, authenticated;
revoke execute on function public.create_task(text, uuid, uuid, text, public.task_priority, date, uuid[]) from public, anon;
revoke execute on function public.add_task_helper(uuid, uuid) from public, anon;
grant execute on function public.create_task(text, uuid, uuid, text, public.task_priority, date, uuid[]) to authenticated;
grant execute on function public.add_task_helper(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Settings
-- ---------------------------------------------------------------------------

insert into public.app_settings (key, value, label, description, is_public) values
  ('region.timezone', '"Australia/Melbourne"', 'Time zone',
   'Used for due dates, "due this week" and "overdue". For example Australia/Melbourne or Australia/Perth.', false)
on conflict (key) do nothing;

$m003$;
  insert into public.install_log (name) values ('20261029000001_tasks.sql');
end;
$part$;

-- ====================================================================
-- 20261030000001_registers.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261030000001_registers.sql') then
    return;
  end if;
  execute $m004$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Registers: each registry has its own reference prefix, labels and custom
-- fields. All tasks still live in ONE table (public.tasks); a register page
-- is a filtered view of it, so nothing is ever copied or synced.
--
-- Registries come in two kinds:
--   tasks   – work with someone looking after it (most registers)
--   records – a list of things with no workflow (for example an asset register)

-- ---------------------------------------------------------------------------
-- Registry settings
-- ---------------------------------------------------------------------------

alter table public.registries
  add column kind text not null default 'tasks' check (kind in ('tasks', 'records')),
  add column prefix text,
  add column next_number int not null default 1,
  add column description_label text not null default 'Description',
  add column title_label text not null default 'Title',
  add column show_due_date boolean not null default true,
  add column show_review_date boolean not null default false,
  add column review_label text not null default 'Next review date',
  add column show_outcome boolean not null default false,
  add column outcome_label text not null default 'Outcome / actions taken',
  -- The built-in "General tasks" registry: can be renamed, never retired.
  add column is_default boolean not null default false,
  add column created_by uuid references public.profiles (id);

update public.registries
   set prefix = upper(left(regexp_replace(name, '[^A-Za-z]', '', 'g'), 3)) || sort_order
 where prefix is null;

alter table public.registries
  alter column prefix set not null,
  add constraint registries_prefix_format check (prefix ~ '^[A-Z0-9]{2,6}$');
create unique index registries_prefix_unique on public.registries (prefix);
create unique index registries_one_default on public.registries ((true)) where is_default;

-- Custom fields of a registry.
create table public.registry_fields (
  id          uuid primary key default gen_random_uuid(),
  registry_id uuid not null references public.registries (id) on delete cascade,
  key         text not null check (key ~ '^[a-z][a-z0-9_]{0,39}$'),
  label       text not null check (length(trim(label)) between 1 and 80),
  type        text not null check (type in (
                'text', 'long_text', 'number', 'money', 'date',
                'choice', 'multi_choice', 'yes_no', 'person', 'asset')),
  required    boolean not null default false,
  -- Choices for choice / multi_choice fields.
  options     jsonb not null default '[]'::jsonb check (jsonb_typeof(options) = 'array'),
  help        text not null default '',
  sort_order  int not null default 0,
  -- Retired fields keep their data but are no longer shown on forms.
  active      boolean not null default true,
  created_at  timestamptz not null default now(),
  unique (registry_id, key)
);

-- ---------------------------------------------------------------------------
-- Task additions
-- ---------------------------------------------------------------------------

alter table public.tasks
  add column ref_number int,
  add column details jsonb not null default '{}'::jsonb check (jsonb_typeof(details) = 'object'),
  add column date_reported date not null default current_date,
  add column review_date date,
  add column outcome text not null default '',
  -- Follow-up actions point at the task they belong to.
  add column parent_task_id uuid references public.tasks (id);

update public.tasks set ref_number = number where ref_number is null;
alter table public.tasks alter column ref_number set not null;
create unique index tasks_registry_ref_unique on public.tasks (registry_id, ref_number);
create index tasks_parent_idx on public.tasks (parent_task_id);
create index tasks_details_idx on public.tasks using gin (details);

-- ---------------------------------------------------------------------------
-- Records (for "records" registries such as an asset register)
-- ---------------------------------------------------------------------------

create table public.records (
  id          uuid primary key default gen_random_uuid(),
  org_id      uuid not null default public.default_org_id() references public.organisation (id),
  registry_id uuid not null references public.registries (id),
  ref_number  int not null,
  title       text not null check (length(trim(title)) between 1 and 200),
  details     jsonb not null default '{}'::jsonb check (jsonb_typeof(details) = 'object'),
  archived    boolean not null default false,
  created_by  uuid not null references public.profiles (id),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (registry_id, ref_number)
);

create table public.record_events (
  id         bigint generated always as identity primary key,
  record_id  uuid not null references public.records (id),
  actor_id   uuid references public.profiles (id),
  type       text not null,
  details    jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index record_events_record_idx on public.record_events (record_id, created_at);

create trigger record_events_append_only
  before update or delete on public.record_events
  for each row execute function public.block_audit_changes();

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

create function public.manages_registry(p_registry_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_staff_admin() or (
    public.has_role(array['manager', 'system_admin']::public.app_role[])
    and exists (select 1 from public.registry_managers
                 where registry_id = p_registry_id and user_id = auth.uid())
  )
$$;

-- The person looking after it, its creator, their team leader, the
-- registry's managers and system admins can change a task's details.
create function public.can_edit_task(p_task_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and exists (
    select 1 from public.tasks t
     where t.id = p_task_id
       and (
         t.assigned_to = auth.uid()
         or t.created_by = auth.uid()
         or public.leads_user(t.assigned_to)
         or (public.has_role(array['manager', 'system_admin']::public.app_role[])
             and exists (select 1 from public.registry_managers rm
                          where rm.registry_id = t.registry_id and rm.user_id = auth.uid()))
         or public.is_system_admin()
       )
  )
$$;

-- Next reference number in a registry (locks the registry row briefly).
create function public.take_ref_number(p_registry_id uuid)
returns int
language sql
security definer
set search_path = ''
as $$
  update public.registries set next_number = next_number + 1
   where id = p_registry_id
  returning next_number - 1
$$;

-- Checks custom field values against a registry's fields and returns them
-- cleaned up: unknown keys removed, empty values dropped, types checked.
-- Values of retired fields are kept from p_existing.
create function public.clean_details(p_registry_id uuid, p_details jsonb, p_existing jsonb default '{}'::jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  f public.registry_fields;
  v jsonb;
  out jsonb := '{}'::jsonb;
  item jsonb;
begin
  p_details := coalesce(p_details, '{}'::jsonb);

  for f in select * from public.registry_fields where registry_id = p_registry_id order by sort_order loop
    if not f.active then
      if p_existing ? f.key then
        out := out || jsonb_build_object(f.key, p_existing -> f.key);
      end if;
      continue;
    end if;

    v := p_details -> f.key;
    if v is null or v = 'null'::jsonb or v = '""'::jsonb or v = '[]'::jsonb then
      if f.required then
        raise exception '% is required', f.label;
      end if;
      continue;
    end if;

    case f.type
      when 'text', 'long_text' then
        if jsonb_typeof(v) <> 'string' then raise exception '% must be text', f.label; end if;
        if length(v #>> '{}') > 5000 then raise exception '% is too long', f.label; end if;
      when 'number', 'money' then
        if jsonb_typeof(v) <> 'number' then raise exception '% must be a number', f.label; end if;
      when 'date' then
        if jsonb_typeof(v) <> 'string' or (v #>> '{}') !~ '^\d{4}-\d{2}-\d{2}$' then
          raise exception '% must be a date', f.label;
        end if;
        perform (v #>> '{}')::date;
      when 'yes_no' then
        if jsonb_typeof(v) <> 'boolean' then raise exception '% must be yes or no', f.label; end if;
      when 'choice' then
        if jsonb_typeof(v) <> 'string' or not (f.options ? (v #>> '{}')) then
          raise exception 'Choose one of the options for %', f.label;
        end if;
      when 'multi_choice' then
        if jsonb_typeof(v) <> 'array' then raise exception 'Choose options for %', f.label; end if;
        for item in select * from jsonb_array_elements(v) loop
          if jsonb_typeof(item) <> 'string' or not (f.options ? (item #>> '{}')) then
            raise exception 'Choose from the options for %', f.label;
          end if;
        end loop;
      when 'person' then
        if jsonb_typeof(v) <> 'string' or not exists (
          select 1 from public.profiles where id::text = (v #>> '{}')) then
          raise exception 'Choose a person for %', f.label;
        end if;
      when 'asset' then
        if jsonb_typeof(v) <> 'string' or not exists (
          select 1 from public.records r join public.registries g on g.id = r.registry_id
           where r.id::text = (v #>> '{}') and g.kind = 'records') then
          raise exception 'Choose an item for %', f.label;
        end if;
    end case;

    out := out || jsonb_build_object(f.key, v);
  end loop;

  return out;
end;
$$;

-- ---------------------------------------------------------------------------
-- Guard rails on registries
-- ---------------------------------------------------------------------------

create function public.guard_registry()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  base text;
  n int := 1;
begin
  new.prefix := upper(trim(coalesce(new.prefix, '')));
  -- No prefix given: make one from the name's initials (Risk Management
  -- Register -> RMR), adding a number if it's already taken.
  if new.prefix = '' then
    select upper(string_agg(left(w, 1), '')) into base
      from regexp_split_to_table(regexp_replace(new.name, '[^A-Za-z0-9 ]', '', 'g'), '\s+') w
     where w <> '';
    base := left(coalesce(nullif(base, ''), 'REG'), 4);
    if length(base) < 2 then base := upper(left(regexp_replace(new.name, '[^A-Za-z]', '', 'g') || 'XX', 3)); end if;
    new.prefix := base;
    while exists (select 1 from public.registries where prefix = new.prefix and id <> new.id) loop
      n := n + 1;
      new.prefix := base || n;
    end loop;
  end if;
  if tg_op = 'INSERT' then
    new.created_by := coalesce(new.created_by, auth.uid());
    new.next_number := 1;
    new.is_default := coalesce(new.is_default, false) and auth.uid() is null;
  else
    if new.kind <> old.kind and (
         exists (select 1 from public.tasks where registry_id = old.id)
         or exists (select 1 from public.records where registry_id = old.id)) then
      raise exception 'A registry''s kind can''t change once it has entries';
    end if;
    if old.is_default and not new.active then
      raise exception 'The General tasks registry can''t be retired';
    end if;
    new.is_default := old.is_default;
    if new.next_number < old.next_number then
      new.next_number := old.next_number;
    end if;
  end if;
  return new;
end;
$$;

create trigger registries_guard
  before insert or update on public.registries
  for each row execute function public.guard_registry();

-- A manager who creates a registry becomes its manager.
create function public.add_creator_as_manager()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.my_role() = 'manager' then
    insert into public.registry_managers (registry_id, user_id) values (new.id, auth.uid())
    on conflict do nothing;
  end if;
  perform public.write_audit('registry_created', 'registry', new.id::text, jsonb_build_object('name', new.name));
  return new;
end;
$$;

create trigger registries_creator_manager
  after insert on public.registries
  for each row execute function public.add_creator_as_manager();

-- Keys of fields never change once there is data under them.
create function public.guard_registry_field()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and (new.key <> old.key or new.registry_id <> old.registry_id) then
    raise exception 'A field''s key can''t be changed';
  end if;
  if tg_op = 'UPDATE' and new.type <> old.type and (
       exists (select 1 from public.tasks where registry_id = old.registry_id and details ? old.key)
       or exists (select 1 from public.records where registry_id = old.registry_id and details ? old.key)) then
    raise exception 'A field''s type can''t change once it has been filled in. Retire it and add a new field instead.';
  end if;
  return new;
end;
$$;

create trigger registry_fields_guard
  before update on public.registry_fields
  for each row execute function public.guard_registry_field();

-- ---------------------------------------------------------------------------
-- Creating and changing tasks
-- ---------------------------------------------------------------------------

drop function public.create_task(text, uuid, uuid, text, public.task_priority, date, uuid[]);

create function public.create_task(
  p_title text,
  p_registry_id uuid,
  p_assigned_to uuid,
  p_description text default '',
  p_priority public.task_priority default 'medium',
  p_due_date date default null,
  p_helpers uuid[] default '{}',
  p_details jsonb default '{}'::jsonb,
  p_date_reported date default null,
  p_review_date date default null,
  p_parent_task_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_task_id uuid;
  v_helper uuid;
  v_manager uuid;
  v_helpers uuid[];
  v_registry public.registries;
  v_details jsonb;
begin
  if not public.is_member() then
    raise exception 'Please sign in again';
  end if;
  if not public.feature_enabled('tasks') then
    raise exception 'Tasks are switched off at the moment';
  end if;
  if coalesce(trim(p_title), '') = '' then
    raise exception 'Give the task a title';
  end if;

  -- A follow-up action belongs to the same registry as its task.
  if p_parent_task_id is not null then
    if not public.can_edit_task(p_parent_task_id) then
      raise exception 'You can''t add actions to this task';
    end if;
    select registry_id into p_registry_id from public.tasks where id = p_parent_task_id;
    p_details := '{}'::jsonb;
  end if;

  select * into v_registry from public.registries where id = p_registry_id and active;
  if v_registry.id is null or v_registry.kind <> 'tasks' then
    raise exception 'Choose a registry that is in use';
  end if;
  if not exists (select 1 from public.profiles where id = p_assigned_to and active) then
    raise exception 'Choose someone who can sign in to look after this task';
  end if;

  v_details := case when p_parent_task_id is null then public.clean_details(p_registry_id, p_details) else '{}'::jsonb end;

  select coalesce(array_agg(distinct h), '{}') into v_helpers
    from unnest(coalesce(p_helpers, '{}')) h
    join public.profiles p on p.id = h and p.active
   where h <> p_assigned_to;

  insert into public.tasks (title, description, registry_id, ref_number, priority, assigned_to, created_by,
                            due_date, details, date_reported, review_date, parent_task_id)
  values (trim(p_title), coalesce(trim(p_description), ''), p_registry_id, public.take_ref_number(p_registry_id),
          p_priority, p_assigned_to, auth.uid(), p_due_date, v_details,
          coalesce(p_date_reported, current_date), p_review_date, p_parent_task_id)
  returning id into v_task_id;

  insert into public.task_events (task_id, actor_id, type, to_value)
  values (v_task_id, auth.uid(), 'created', p_assigned_to::text);

  if p_parent_task_id is not null then
    insert into public.task_events (task_id, actor_id, type, to_value)
    values (p_parent_task_id, auth.uid(), 'action_added', v_task_id::text);
  end if;

  foreach v_helper in array v_helpers loop
    insert into public.task_helpers (task_id, user_id, added_by) values (v_task_id, v_helper, auth.uid());
    insert into public.task_events (task_id, actor_id, type, to_value)
    values (v_task_id, auth.uid(), 'helper_added', v_helper::text);
  end loop;

  perform public.queue_task_email('task_assigned', v_task_id, p_assigned_to, v_helpers);
  if p_assigned_to = auth.uid() then
    foreach v_helper in array v_helpers loop
      perform public.queue_task_email('helper_added', v_task_id, v_helper);
    end loop;
  end if;
  if p_parent_task_id is null then
    for v_manager in
      select rm.user_id from public.registry_managers rm
       where rm.registry_id = p_registry_id
         and rm.user_id <> p_assigned_to
         and not (rm.user_id = any (v_helpers))
    loop
      perform public.queue_task_email('task_created_manager', v_task_id, v_manager);
    end loop;
  end if;

  return v_task_id;
end;
$$;

-- Edit a task's details (not its status or who looks after it; those have
-- their own steps). Records which fields changed on the timeline.
create function public.update_task_details(
  p_task_id uuid,
  p_title text,
  p_description text,
  p_priority public.task_priority,
  p_due_date date,
  p_date_reported date,
  p_review_date date,
  p_outcome text,
  p_details jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.tasks;
  v_details jsonb;
  changed text[] := '{}';
  f record;
begin
  if not public.can_edit_task(p_task_id) then
    raise exception 'You can''t change this task';
  end if;
  if not public.feature_enabled('tasks') then
    raise exception 'Tasks are switched off at the moment';
  end if;
  select * into t from public.tasks where id = p_task_id for update;
  if t.status = 'closed' then
    raise exception 'This task is closed';
  end if;
  if coalesce(trim(p_title), '') = '' then
    raise exception 'Give the task a title';
  end if;

  v_details := case when t.parent_task_id is null then public.clean_details(t.registry_id, p_details, t.details) else t.details end;

  if trim(p_title) <> t.title then changed := array_append(changed, ('title')::text); end if;
  if coalesce(trim(p_description), '') <> t.description then changed := array_append(changed, ('description')::text); end if;
  if p_priority <> t.priority then changed := array_append(changed, ('priority')::text); end if;
  if p_due_date is distinct from t.due_date then changed := array_append(changed, ('due date')::text); end if;
  if coalesce(p_date_reported, t.date_reported) <> t.date_reported then changed := array_append(changed, ('date reported')::text); end if;
  if p_review_date is distinct from t.review_date then changed := array_append(changed, ('review date')::text); end if;
  if coalesce(trim(p_outcome), '') <> t.outcome then changed := array_append(changed, ('outcome')::text); end if;
  for f in select key, label from public.registry_fields where registry_id = t.registry_id order by sort_order loop
    if (v_details -> f.key) is distinct from (t.details -> f.key) then
      changed := array_append(changed, lower(f.label));
    end if;
  end loop;

  if cardinality(changed) = 0 then
    return;
  end if;

  update public.tasks
     set title = trim(p_title),
         description = coalesce(trim(p_description), ''),
         priority = p_priority,
         due_date = p_due_date,
         date_reported = coalesce(p_date_reported, t.date_reported),
         review_date = p_review_date,
         outcome = coalesce(trim(p_outcome), ''),
         details = v_details,
         updated_at = now()
   where id = p_task_id;

  insert into public.task_events (task_id, actor_id, type, comment)
  values (p_task_id, auth.uid(), 'details_changed', array_to_string(changed, ', '));
end;
$$;

-- ---------------------------------------------------------------------------
-- Creating and changing records
-- ---------------------------------------------------------------------------

create function public.create_record(p_registry_id uuid, p_title text, p_details jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
begin
  if not public.manages_registry(p_registry_id) and not public.is_system_admin() then
    raise exception 'Only this register''s managers can add to it';
  end if;
  if not exists (select 1 from public.registries where id = p_registry_id and active and kind = 'records') then
    raise exception 'Choose a register that is in use';
  end if;
  if coalesce(trim(p_title), '') = '' then
    raise exception 'Give it a name or description';
  end if;
  insert into public.records (registry_id, ref_number, title, details, created_by)
  values (p_registry_id, public.take_ref_number(p_registry_id), trim(p_title),
          public.clean_details(p_registry_id, p_details), auth.uid())
  returning id into v_id;
  insert into public.record_events (record_id, actor_id, type) values (v_id, auth.uid(), 'created');
  return v_id;
end;
$$;

create function public.update_record(p_record_id uuid, p_title text, p_details jsonb, p_archived boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.records;
  v_details jsonb;
  changed text[] := '{}';
  f record;
begin
  select * into r from public.records where id = p_record_id for update;
  if r.id is null or (not public.manages_registry(r.registry_id) and not public.is_system_admin()) then
    raise exception 'Only this register''s managers can change it';
  end if;
  if coalesce(trim(p_title), '') = '' then
    raise exception 'Give it a name or description';
  end if;
  v_details := public.clean_details(r.registry_id, p_details, r.details);
  if trim(p_title) <> r.title then changed := array_append(changed, ('name')::text); end if;
  if p_archived <> r.archived then changed := array_append(changed, (case when p_archived then 'archived' else 'restored' end)::text); end if;
  for f in select key, label from public.registry_fields where registry_id = r.registry_id order by sort_order loop
    if (v_details -> f.key) is distinct from (r.details -> f.key) then
      changed := array_append(changed, lower(f.label));
    end if;
  end loop;
  if cardinality(changed) = 0 then return; end if;
  update public.records
     set title = trim(p_title), details = v_details, archived = p_archived, updated_at = now()
   where id = p_record_id;
  insert into public.record_events (record_id, actor_id, type, details)
  values (p_record_id, auth.uid(), 'changed', jsonb_build_object('fields', to_jsonb(changed)));
end;
$$;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.registry_fields enable row level security;
alter table public.records         enable row level security;
alter table public.record_events   enable row level security;

-- Managers can create registries; managers can change the registries they
-- manage; staff admins and system admins can change any.
drop policy "staff admin manages registries" on public.registries;
create policy "managers create registries" on public.registries
  for insert to authenticated
  with check (public.is_staff_admin() or public.has_role(array['manager']::public.app_role[]));
create policy "registry managers update registries" on public.registries
  for update to authenticated
  using (public.manages_registry(id)) with check (public.manages_registry(id));

drop policy "staff admin manages registry managers" on public.registry_managers;
create policy "registry managers manage managers" on public.registry_managers
  for all to authenticated
  using (public.manages_registry(registry_id)) with check (public.manages_registry(registry_id));

create policy "members read registry fields" on public.registry_fields
  for select to authenticated using (public.is_member());
create policy "registry managers manage fields" on public.registry_fields
  for insert to authenticated with check (public.manages_registry(registry_id));
create policy "registry managers change fields" on public.registry_fields
  for update to authenticated
  using (public.manages_registry(registry_id)) with check (public.manages_registry(registry_id));
-- Fields are retired, never deleted, so their data is kept.

create policy "members read records" on public.records
  for select to authenticated using (public.is_member());
create policy "members read record history" on public.record_events
  for select to authenticated using (public.is_member());

revoke insert, update, delete, truncate on public.records, public.record_events from anon, authenticated;
revoke delete on public.registries, public.registry_fields from anon, authenticated;

revoke execute on function public.take_ref_number(uuid) from public, anon, authenticated;
revoke execute on function public.clean_details(uuid, jsonb, jsonb) from public, anon, authenticated;
revoke execute on function public.create_task(text, uuid, uuid, text, public.task_priority, date, uuid[], jsonb, date, date, uuid) from public, anon;
revoke execute on function public.update_task_details(uuid, text, text, public.task_priority, date, date, date, text, jsonb) from public, anon;
revoke execute on function public.create_record(uuid, text, jsonb) from public, anon;
revoke execute on function public.update_record(uuid, text, jsonb, boolean) from public, anon;
grant execute on function public.create_task(text, uuid, uuid, text, public.task_priority, date, uuid[], jsonb, date, date, uuid) to authenticated;
grant execute on function public.update_task_details(uuid, text, text, public.task_priority, date, date, date, text, jsonb) to authenticated;
grant execute on function public.create_record(uuid, text, jsonb) to authenticated;
grant execute on function public.update_record(uuid, text, jsonb, boolean) to authenticated;

-- ---------------------------------------------------------------------------
-- The built-in General tasks registry
-- ---------------------------------------------------------------------------

insert into public.registries (name, description, prefix, is_default, sort_order)
values ('General tasks', 'Everyday jobs that don''t belong to a register.', 'GEN', true, 0)
on conflict do nothing;

$m004$;
  insert into public.install_log (name) values ('20261030000001_registers.sql');
end;
$part$;

-- ====================================================================
-- 20261031000001_logo_mark.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261031000001_logo_mark.sql') then
    return;
  end if;
  execute $m005$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- A second, small logo for tight spaces (the menu, browser tab and phone
-- home-screen icon). The main logo is shown on the sign-in page.

insert into public.app_settings (key, value, label, description, is_public) values
  ('brand.logo_mark_url', '"/logo.svg"', 'Small logo',
   'A square version for the menu, browser tab and phone icon. Leave as the main logo if you only have one.', true)
on conflict (key) do nothing;

update public.app_settings
   set label = 'Main logo', description = 'Shown on the sign-in page and in emails.'
 where key = 'brand.logo_url';

$m005$;
  insert into public.install_log (name) values ('20261031000001_logo_mark.sql');
end;
$part$;

-- ====================================================================
-- 20261101000001_task_notifications.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261101000001_task_notifications.sql') then
    return;
  end if;
  execute $m006$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- The bell: tasks newly given to you (to look after or to help on) that you
-- haven't opened since. Opening a task, or "Mark all as seen", clears it.

create table public.task_views (
  task_id uuid not null references public.tasks (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  seen_at timestamptz not null default now(),
  primary key (task_id, user_id)
);

alter table public.task_views enable row level security;

create policy "read your own views" on public.task_views
  for select to authenticated using (user_id = auth.uid());
revoke insert, update, delete, truncate on public.task_views from anon, authenticated;

-- Tasks given to the signed-in person by someone else, not yet opened since.
create function public.my_new_tasks()
returns table (task_id uuid, kind text, actor_id uuid, at timestamptz)
language sql
stable
security definer
set search_path = ''
as $$
  select distinct on (e.task_id)
         e.task_id,
         case when e.type = 'helper_added' then 'helping' else 'assigned' end,
         e.actor_id,
         e.created_at
    from public.task_events e
    join public.tasks t on t.id = e.task_id
   where public.is_member()
     and e.to_value = auth.uid()::text
     and e.type in ('created', 'helper_added', 'reassigned')
     and e.actor_id is distinct from auth.uid()
     and t.status not in ('completed', 'closed')
     -- Still looking after it / still helping.
     and (t.assigned_to = auth.uid()
          or exists (select 1 from public.task_helpers h where h.task_id = t.id and h.user_id = auth.uid()))
     and not exists (
       select 1 from public.task_views v
        where v.task_id = e.task_id and v.user_id = auth.uid() and v.seen_at >= e.created_at)
   order by e.task_id, e.created_at desc
$$;

create function public.mark_task_seen(p_task_id uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.task_views (task_id, user_id, seen_at)
  select p_task_id, auth.uid(), now()
   where public.can_see_task(p_task_id)
  on conflict (task_id, user_id) do update set seen_at = excluded.seen_at
$$;

create function public.mark_all_tasks_seen()
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.task_views (task_id, user_id, seen_at)
  select n.task_id, auth.uid(), now() from public.my_new_tasks() n
  on conflict (task_id, user_id) do update set seen_at = excluded.seen_at
$$;

revoke execute on function public.my_new_tasks() from public, anon;
revoke execute on function public.mark_task_seen(uuid) from public, anon;
revoke execute on function public.mark_all_tasks_seen() from public, anon;
grant execute on function public.my_new_tasks() to authenticated;
grant execute on function public.mark_task_seen(uuid) to authenticated;
grant execute on function public.mark_all_tasks_seen() to authenticated;

$m006$;
  insert into public.install_log (name) values ('20261101000001_task_notifications.sql');
end;
$part$;

-- ====================================================================
-- 20261102000001_choice_colours.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261102000001_choice_colours.sql') then
    return;
  end if;
  execute $m007$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Colour-coded dropdown choices, e.g. Risk rating: Low green … Extreme red.
-- option_colors maps a choice to one of: green, yellow, orange, red, blue, grey.

alter table public.registry_fields
  add column option_colors jsonb not null default '{}'::jsonb
    check (jsonb_typeof(option_colors) = 'object');

-- Starting colours for a risk register, if there is one (managers can change them).
update public.registry_fields f
   set option_colors = '{"Low": "green", "Medium": "yellow", "High": "orange", "Extreme": "red"}'
  from public.registries r
 where r.id = f.registry_id and r.prefix = 'RSK' and f.key = 'risk_rating' and f.option_colors = '{}'::jsonb;

update public.registry_fields f
   set option_colors = '{"Effective": "green", "Partly effective": "orange", "Not effective": "red", "Not yet reviewed": "grey"}'
  from public.registries r
 where r.id = f.registry_id and r.prefix = 'RSK' and f.key = 'effectiveness' and f.option_colors = '{}'::jsonb;

$m007$;
  insert into public.install_log (name) values ('20261102000001_choice_colours.sql');
end;
$part$;

-- ====================================================================
-- 20261103000001_managers_manage_people.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261103000001_managers_manage_people.sql') then
    return;
  end if;
  execute $m008$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- 1. Managers can use Staff & roles and Teams. Who can manage whom:
--      managers      → support workers and team leaders
--      staff admins  → also managers
--      system admins → everyone (only they manage staff admins and system admins)
-- 2. System admins can't be given tasks (to look after or to help on).

create function public.can_manage_people()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.has_role(array['manager', 'staff_admin', 'system_admin']::public.app_role[])
$$;

-- The highest role the signed-in person may give out or change.
create function public.can_manage_role(p_role public.app_role)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case public.my_role()
    when 'system_admin' then true
    when 'staff_admin' then p_role in ('support_worker', 'team_leader', 'manager')
    when 'manager' then p_role in ('support_worker', 'team_leader')
    else false
  end and public.mfa_ok()
$$;

create or replace function public.guard_profile_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor uuid := auth.uid();
begin
  if new.id <> old.id or new.email <> old.email or new.org_id <> old.org_id then
    raise exception 'This field cannot be changed here';
  end if;

  -- Server-side jobs (no signed-in person) skip the people rules below.
  if actor is not null then
    if new.role is distinct from old.role
       or new.team_id is distinct from old.team_id
       or new.active is distinct from old.active then

      if not public.can_manage_people() then
        raise exception 'Only managers and admins can change roles, teams or access';
      end if;

      if new.id = actor and (new.role is distinct from old.role or not new.active) then
        raise exception 'You cannot change your own role or deactivate yourself';
      end if;

      if new.id <> actor and (not public.can_manage_role(old.role) or not public.can_manage_role(new.role)) then
        if public.my_role() = 'manager' then
          raise exception 'Managers can manage support workers and team leaders. Ask a staff admin for anything else.';
        end if;
        raise exception 'Only a system admin can manage staff admins and system admins';
      end if;
    end if;
  end if;

  -- Never leave the install without an active system admin.
  if old.role = 'system_admin' and old.active
     and (new.role <> 'system_admin' or not new.active)
     and not exists (
       select 1 from public.profiles
        where role = 'system_admin' and active and id <> old.id
     ) then
    raise exception 'There must always be at least one active system admin';
  end if;

  if new.active and not old.active then
    new.deactivated_at := null;
  elsif not new.active and old.active then
    new.deactivated_at := now();
  end if;

  if new.role is distinct from old.role then
    perform public.write_audit('role_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.role, 'to', new.role));
  end if;
  if new.active is distinct from old.active then
    perform public.write_audit(
      case when new.active then 'reactivated' else 'deactivated' end,
      'profile', new.id::text, '{}'::jsonb);
  end if;
  if new.team_id is distinct from old.team_id then
    perform public.write_audit('team_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.team_id, 'to', new.team_id));
  end if;

  return new;
end;
$$;

create or replace function public.guard_invitation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.can_manage_people() then
    raise exception 'Only managers and admins can invite people';
  end if;
  if auth.uid() is not null and not public.can_manage_role(new.role) then
    if public.my_role() = 'manager' then
      raise exception 'Managers can invite support workers and team leaders';
    end if;
    raise exception 'Only a system admin can invite staff admins or system admins';
  end if;
  new.email := lower(trim(new.email));
  if tg_op = 'INSERT' then
    new.invited_by := coalesce(new.invited_by, auth.uid());
    perform public.write_audit('invited', 'invitation', new.email,
      jsonb_build_object('role', new.role));
  end if;
  return new;
end;
$$;

create or replace function public.log_admin_action(p_action text, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_action = 'mfa_reset' and not public.is_system_admin() then
    raise exception 'Only a system admin can reset two-factor login';
  elsif p_action not in ('mfa_reset', 'invite_resent') or not public.can_manage_people() then
    raise exception 'Not allowed';
  end if;
  perform public.write_audit(p_action, 'profile', p_user_id::text, '{}'::jsonb);
end;
$$;

drop policy "staff admin updates people" on public.profiles;
create policy "managers and admins update people" on public.profiles
  for update to authenticated using (public.can_manage_people()) with check (public.can_manage_people());

drop policy "staff admin manages teams" on public.teams;
create policy "managers and admins manage teams" on public.teams
  for all to authenticated using (public.can_manage_people()) with check (public.can_manage_people());

drop policy "staff admin manages team leaders" on public.team_leaders;
create policy "managers and admins manage team leaders" on public.team_leaders
  for all to authenticated using (public.can_manage_people()) with check (public.can_manage_people());

drop policy "staff admin reads invitations" on public.invitations;
drop policy "staff admin creates invitations" on public.invitations;
drop policy "staff admin updates invitations" on public.invitations;
drop policy "staff admin removes pending invitations" on public.invitations;
create policy "managers and admins read invitations" on public.invitations
  for select to authenticated using (public.can_manage_people());
create policy "managers and admins create invitations" on public.invitations
  for insert to authenticated with check (public.can_manage_people());
create policy "managers and admins update invitations" on public.invitations
  for update to authenticated using (public.can_manage_people()) with check (public.can_manage_people());
create policy "managers and admins remove pending invitations" on public.invitations
  for delete to authenticated using (public.can_manage_people() and accepted_at is null);

-- ---------------------------------------------------------------------------
-- System admins can't be given tasks
-- ---------------------------------------------------------------------------

create function public.can_take_tasks(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.profiles where id = p_user_id and active and role <> 'system_admin')
$$;

create function public.guard_task_people()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_table_name = 'tasks' then
    if (tg_op = 'INSERT' or new.assigned_to is distinct from old.assigned_to)
       and exists (select 1 from public.profiles where id = new.assigned_to and role = 'system_admin') then
      raise exception 'System admins can''t be given tasks. Choose someone else to look after it.';
    end if;
  elsif exists (select 1 from public.profiles where id = new.user_id and role = 'system_admin') then
    raise exception 'System admins can''t be added as helpers';
  end if;
  return new;
end;
$$;

create trigger tasks_people_guard
  before insert or update of assigned_to on public.tasks
  for each row execute function public.guard_task_people();

create trigger task_helpers_people_guard
  before insert on public.task_helpers
  for each row execute function public.guard_task_people();

-- Helpers who can't take tasks are left off quietly when a task is created.
create or replace function public.create_task(
  p_title text,
  p_registry_id uuid,
  p_assigned_to uuid,
  p_description text default '',
  p_priority public.task_priority default 'medium',
  p_due_date date default null,
  p_helpers uuid[] default '{}',
  p_details jsonb default '{}'::jsonb,
  p_date_reported date default null,
  p_review_date date default null,
  p_parent_task_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_task_id uuid;
  v_helper uuid;
  v_manager uuid;
  v_helpers uuid[];
  v_registry public.registries;
  v_details jsonb;
begin
  if not public.is_member() then
    raise exception 'Please sign in again';
  end if;
  if not public.feature_enabled('tasks') then
    raise exception 'Tasks are switched off at the moment';
  end if;
  if coalesce(trim(p_title), '') = '' then
    raise exception 'Give the task a title';
  end if;

  if p_parent_task_id is not null then
    if not public.can_edit_task(p_parent_task_id) then
      raise exception 'You can''t add actions to this task';
    end if;
    select registry_id into p_registry_id from public.tasks where id = p_parent_task_id;
    p_details := '{}'::jsonb;
  end if;

  select * into v_registry from public.registries where id = p_registry_id and active;
  if v_registry.id is null or v_registry.kind <> 'tasks' then
    raise exception 'Choose a registry that is in use';
  end if;
  if not public.can_take_tasks(p_assigned_to) then
    raise exception 'Choose someone who can sign in to look after this task (system admins can''t be given tasks)';
  end if;

  v_details := case when p_parent_task_id is null then public.clean_details(p_registry_id, p_details) else '{}'::jsonb end;

  select coalesce(array_agg(distinct h), '{}') into v_helpers
    from unnest(coalesce(p_helpers, '{}')) h
   where h <> p_assigned_to and public.can_take_tasks(h);

  insert into public.tasks (title, description, registry_id, ref_number, priority, assigned_to, created_by,
                            due_date, details, date_reported, review_date, parent_task_id)
  values (trim(p_title), coalesce(trim(p_description), ''), p_registry_id, public.take_ref_number(p_registry_id),
          p_priority, p_assigned_to, auth.uid(), p_due_date, v_details,
          coalesce(p_date_reported, current_date), p_review_date, p_parent_task_id)
  returning id into v_task_id;

  insert into public.task_events (task_id, actor_id, type, to_value)
  values (v_task_id, auth.uid(), 'created', p_assigned_to::text);

  if p_parent_task_id is not null then
    insert into public.task_events (task_id, actor_id, type, to_value)
    values (p_parent_task_id, auth.uid(), 'action_added', v_task_id::text);
  end if;

  foreach v_helper in array v_helpers loop
    insert into public.task_helpers (task_id, user_id, added_by) values (v_task_id, v_helper, auth.uid());
    insert into public.task_events (task_id, actor_id, type, to_value)
    values (v_task_id, auth.uid(), 'helper_added', v_helper::text);
  end loop;

  perform public.queue_task_email('task_assigned', v_task_id, p_assigned_to, v_helpers);
  if p_assigned_to = auth.uid() then
    foreach v_helper in array v_helpers loop
      perform public.queue_task_email('helper_added', v_task_id, v_helper);
    end loop;
  end if;
  if p_parent_task_id is null then
    for v_manager in
      select rm.user_id from public.registry_managers rm
       where rm.registry_id = p_registry_id
         and rm.user_id <> p_assigned_to
         and not (rm.user_id = any (v_helpers))
    loop
      perform public.queue_task_email('task_created_manager', v_task_id, v_manager);
    end loop;
  end if;

  return v_task_id;
end;
$$;

$m008$;
  insert into public.install_log (name) values ('20261103000001_managers_manage_people.sql');
end;
$part$;

-- ====================================================================
-- 20261104000001_sla.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261104000001_sla.sql') then
    return;
  end if;
  execute $m009$
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

$m009$;
  insert into public.install_log (name) values ('20261104000001_sla.sql');
end;
$part$;

-- ====================================================================
-- 20261105000001_staff_admin_scope_and_sla_editors.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261105000001_staff_admin_scope_and_sla_editors.sql') then
    return;
  end if;
  execute $m010$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Who manages whom:
--   managers      invite any role except system admin, and change roles
--                 straight away (except system admins)
--   staff admins  (HR) invite any role except system admin and create teams;
--                 their role and team changes are requests a manager approves
--   system admins everything, and the only ones who create system admins
--   everyone      can't change their own role
-- Managers can also change the company's SLA (default due dates).

-- Can the signed-in person invite someone with this role, or manage someone
-- who has it (deactivate, change team)?
create or replace function public.can_manage_role(p_role public.app_role)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case public.my_role()
    when 'system_admin' then true
    when 'manager' then p_role <> 'system_admin'
    when 'staff_admin' then p_role <> 'system_admin'
    else false
  end and public.mfa_ok()
$$;

create or replace function public.guard_profile_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor uuid := auth.uid();
begin
  if new.id <> old.id or new.email <> old.email or new.org_id <> old.org_id then
    raise exception 'This field cannot be changed here';
  end if;

  if actor is not null then
    if new.role is distinct from old.role
       or new.team_id is distinct from old.team_id
       or new.active is distinct from old.active then

      if not public.can_manage_people() then
        raise exception 'Only managers and admins can change roles, teams or access';
      end if;

      -- Nobody promotes, demotes or deactivates themselves.
      if new.id = actor and (new.role is distinct from old.role or not new.active) then
        raise exception 'You cannot change your own role or deactivate yourself';
      end if;

      if new.id <> actor and (not public.can_manage_role(old.role) or not public.can_manage_role(new.role)) then
        raise exception 'Only a system admin can manage system admins';
      end if;

      -- A staff admin's role changes need a manager's approval first.
      -- (Managers apply approved requests as themselves, so this never blocks them.)
      if new.role is distinct from old.role and public.my_role() = 'staff_admin' then
        raise exception 'Role changes by a staff admin need a manager''s approval. Send it as a request.';
      end if;
      if new.team_id is distinct from old.team_id and public.my_role() = 'staff_admin' then
        raise exception 'Team changes by a staff admin need a manager''s approval. Send it as a request.';
      end if;
    end if;
  end if;

  if old.role = 'system_admin' and old.active
     and (new.role <> 'system_admin' or not new.active)
     and not exists (
       select 1 from public.profiles
        where role = 'system_admin' and active and id <> old.id
     ) then
    raise exception 'There must always be at least one active system admin';
  end if;

  if new.active and not old.active then
    new.deactivated_at := null;
  elsif not new.active and old.active then
    new.deactivated_at := now();
  end if;

  if new.role is distinct from old.role then
    perform public.write_audit('role_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.role, 'to', new.role));
  end if;
  if new.active is distinct from old.active then
    perform public.write_audit(
      case when new.active then 'reactivated' else 'deactivated' end,
      'profile', new.id::text, '{}'::jsonb);
  end if;
  if new.team_id is distinct from old.team_id then
    perform public.write_audit('team_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.team_id, 'to', new.team_id));
  end if;

  return new;
end;
$$;

create or replace function public.guard_invitation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.can_manage_people() then
    raise exception 'Only managers and admins can invite people';
  end if;
  if auth.uid() is not null and not public.can_manage_role(new.role) then
    raise exception 'Only a system admin can invite a system admin';
  end if;
  if auth.uid() is not null and new.team_id is not null and public.my_role() = 'staff_admin' then
    raise exception 'Add them to a team once they''ve joined; a manager approves team changes';
  end if;
  new.email := lower(trim(new.email));
  if tg_op = 'INSERT' then
    new.invited_by := coalesce(new.invited_by, auth.uid());
    perform public.write_audit('invited', 'invitation', new.email,
      jsonb_build_object('role', new.role));
  end if;
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Change requests from staff admins, approved by managers:
--   role     – change someone's role
--   team     – move someone into (or out of) a team
--   leaders  – change who leads a team
-- ---------------------------------------------------------------------------

create table public.people_change_requests (
  id            uuid primary key default gen_random_uuid(),
  kind          text not null check (kind in ('role', 'team', 'leaders')),
  user_id       uuid references public.profiles (id),
  team_id       uuid references public.teams (id) on delete cascade,
  from_value    jsonb,
  to_value      jsonb not null,
  reason        text not null default '',
  requested_by  uuid not null references public.profiles (id),
  requested_at  timestamptz not null default now(),
  status        text not null default 'pending' check (status in ('pending', 'approved', 'declined', 'withdrawn')),
  decided_by    uuid references public.profiles (id),
  decided_at    timestamptz,
  decision_note text not null default '',
  check ((kind in ('role', 'team') and user_id is not null) or (kind = 'leaders' and team_id is not null))
);

-- One request waiting per person (role, team) or per team (leaders).
create unique index people_change_requests_one_pending
  on public.people_change_requests (kind, coalesce(user_id, team_id)) where status = 'pending';

alter table public.people_change_requests enable row level security;
create policy "managers and admins see change requests" on public.people_change_requests
  for select to authenticated using (public.can_manage_people());
revoke insert, update, delete, truncate on public.people_change_requests from anon, authenticated;

-- Shared checks and bookkeeping for a new request.
create function public.add_change_request(
  p_kind text, p_user_id uuid, p_team_id uuid, p_from jsonb, p_to jsonb, p_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
begin
  if not public.has_role(array['staff_admin']::public.app_role[]) then
    raise exception 'Only staff admins send change requests; managers make changes straight away';
  end if;
  -- A new request replaces an older one still waiting.
  update public.people_change_requests
     set status = 'withdrawn', decided_by = auth.uid(), decided_at = now()
   where kind = p_kind and coalesce(user_id, team_id) = coalesce(p_user_id, p_team_id) and status = 'pending';
  insert into public.people_change_requests (kind, user_id, team_id, from_value, to_value, reason, requested_by)
  values (p_kind, p_user_id, p_team_id, p_from, p_to, coalesce(trim(p_reason), ''), auth.uid())
  returning id into v_id;
  perform public.write_audit(p_kind || '_change_requested', case when p_kind = 'leaders' then 'team' else 'profile' end,
    coalesce(p_user_id, p_team_id)::text, jsonb_build_object('from', p_from, 'to', p_to));
  return v_id;
end;
$$;

create function public.request_role_change(p_user_id uuid, p_to_role public.app_role, p_reason text default '')
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_from public.app_role;
begin
  if p_user_id = auth.uid() then
    raise exception 'You cannot change your own role';
  end if;
  select role into v_from from public.profiles where id = p_user_id and active;
  if v_from is null then
    raise exception 'Choose someone who can sign in';
  end if;
  if v_from = p_to_role then
    raise exception 'They already have that role';
  end if;
  if not public.can_manage_role(v_from) or not public.can_manage_role(p_to_role) then
    raise exception 'Only a system admin can manage system admins';
  end if;
  return public.add_change_request('role', p_user_id, null, to_jsonb(v_from), to_jsonb(p_to_role), p_reason);
end;
$$;

create function public.request_team_change(p_user_id uuid, p_team_id uuid, p_reason text default '')
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_from uuid;
  v_role public.app_role;
begin
  select team_id, role into v_from, v_role from public.profiles where id = p_user_id and active;
  if v_role is null then
    raise exception 'Choose someone who can sign in';
  end if;
  if not public.can_manage_role(v_role) then
    raise exception 'Only a system admin can manage system admins';
  end if;
  if v_from is not distinct from p_team_id then
    raise exception 'They are already in that team';
  end if;
  if p_team_id is not null and not exists (select 1 from public.teams where id = p_team_id and active) then
    raise exception 'Choose a team that is in use';
  end if;
  return public.add_change_request('team', p_user_id, null, to_jsonb(v_from), coalesce(to_jsonb(p_team_id), 'null'::jsonb), p_reason);
end;
$$;

create function public.request_team_leaders(p_team_id uuid, p_leaders uuid[], p_reason text default '')
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_from uuid[];
  v_to uuid[];
begin
  if not exists (select 1 from public.teams where id = p_team_id) then
    raise exception 'Team not found';
  end if;
  select coalesce(array_agg(user_id order by user_id), '{}') into v_from from public.team_leaders where team_id = p_team_id;
  select coalesce(array_agg(distinct x order by x), '{}') into v_to
    from unnest(coalesce(p_leaders, '{}')) x
    join public.profiles p on p.id = x and p.active and p.role in ('team_leader', 'manager');
  if v_from = v_to then
    raise exception 'Those are already the team''s leaders';
  end if;
  return public.add_change_request('leaders', null, p_team_id, to_jsonb(v_from), to_jsonb(v_to), p_reason);
end;
$$;

create function public.decide_change_request(p_request_id uuid, p_approve boolean, p_note text default '')
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.people_change_requests;
  v_leader uuid;
begin
  if not public.has_role(array['manager', 'system_admin']::public.app_role[]) then
    raise exception 'Only managers can approve these changes';
  end if;
  select * into r from public.people_change_requests where id = p_request_id for update;
  if r.id is null or r.status <> 'pending' then
    raise exception 'This request has already been dealt with';
  end if;
  if r.user_id = auth.uid() then
    raise exception 'You cannot approve a change about yourself';
  end if;

  -- Applied as the approving manager, so all the usual checks still run.
  if p_approve then
    if r.kind = 'role' then
      if (select to_jsonb(role) from public.profiles where id = r.user_id) <> r.from_value then
        raise exception 'Their role has changed since the request was made. Ask for a new request.';
      end if;
      update public.profiles set role = (r.to_value #>> '{}')::public.app_role where id = r.user_id;
    elsif r.kind = 'team' then
      update public.profiles set team_id = (r.to_value #>> '{}')::uuid where id = r.user_id;
    else
      if exists (select 1 from jsonb_array_elements_text(r.to_value) x where x::uuid = auth.uid())
         or exists (select 1 from public.team_leaders where team_id = r.team_id and user_id = auth.uid()) then
        raise exception 'You cannot approve a change to a team you lead';
      end if;
      delete from public.team_leaders where team_id = r.team_id;
      for v_leader in select x::uuid from jsonb_array_elements_text(r.to_value) x loop
        insert into public.team_leaders (team_id, user_id) values (r.team_id, v_leader) on conflict do nothing;
      end loop;
    end if;
  end if;

  update public.people_change_requests
     set status = case when p_approve then 'approved' else 'declined' end,
         decided_by = auth.uid(), decided_at = now(), decision_note = coalesce(trim(p_note), '')
   where id = p_request_id;
  perform public.write_audit(r.kind || case when p_approve then '_change_approved' else '_change_declined' end,
    case when r.kind = 'leaders' then 'team' else 'profile' end, coalesce(r.user_id, r.team_id)::text,
    jsonb_build_object('from', r.from_value, 'to', r.to_value));
end;
$$;

revoke execute on function public.add_change_request(text, uuid, uuid, jsonb, jsonb, text) from public, anon, authenticated;
revoke execute on function public.request_role_change(uuid, public.app_role, text) from public, anon;
revoke execute on function public.request_team_change(uuid, uuid, text) from public, anon;
revoke execute on function public.request_team_leaders(uuid, uuid[], text) from public, anon;
revoke execute on function public.decide_change_request(uuid, boolean, text) from public, anon;
grant execute on function public.request_role_change(uuid, public.app_role, text) to authenticated;
grant execute on function public.request_team_change(uuid, uuid, text) to authenticated;
grant execute on function public.request_team_leaders(uuid, uuid[], text) to authenticated;
grant execute on function public.decide_change_request(uuid, boolean, text) to authenticated;

-- Staff admins create and rename teams; who's in a team, and who leads it,
-- goes through a manager (above). Managers change them straight away.
drop policy "managers and admins manage team leaders" on public.team_leaders;
create policy "managers set team leaders" on public.team_leaders
  for all to authenticated
  using (public.has_role(array['manager', 'system_admin']::public.app_role[]))
  with check (public.has_role(array['manager', 'system_admin']::public.app_role[]));

-- ---------------------------------------------------------------------------
-- Managers change the SLA settings (every change is in the change log).
-- ---------------------------------------------------------------------------

create policy "managers change the SLA" on public.app_settings
  for update to authenticated
  using (key like 'tasks.sla%' and public.has_role(array['manager']::public.app_role[]))
  with check (key like 'tasks.sla%' and public.has_role(array['manager']::public.app_role[]));

-- ---------------------------------------------------------------------------
-- System admins are hidden from everyone except other system admins.
-- (Anything they do shows as "Admin".)
-- ---------------------------------------------------------------------------

drop policy "members read colleagues" on public.profiles;
create policy "members read colleagues" on public.profiles
  for select to authenticated
  using (public.is_member() and (role <> 'system_admin' or public.is_system_admin()));

$m010$;
  insert into public.install_log (name) values ('20261105000001_staff_admin_scope_and_sla_editors.sql');
end;
$part$;

-- ====================================================================
-- 20261106000001_teams_and_job_titles.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261106000001_teams_and_job_titles.sql') then
    return;
  end if;
  execute $m011$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Teams:
--   support workers can be in several teams
--   team leaders belong to (and lead) one team only
--   managers and staff admins are the Core / Management team: managers see
--   every team's tasks; staff admins (HR) manage people but not task content
-- Job titles ("roles" in the portal): managers add titles like "Nurse" or
-- "House Coordinator", each linked to an access level that decides what the
-- person can see and do.

-- ---------------------------------------------------------------------------
-- Job titles
-- ---------------------------------------------------------------------------

create table public.job_titles (
  id           uuid primary key default gen_random_uuid(),
  org_id       uuid not null default public.default_org_id() references public.organisation (id),
  name         text not null check (length(trim(name)) between 1 and 80),
  access_level public.app_role not null check (access_level <> 'system_admin'),
  description  text not null default '',
  active       boolean not null default true,
  sort_order   int not null default 0,
  created_at   timestamptz not null default now()
);

create unique index job_titles_name_unique on public.job_titles (lower(name));

alter table public.profiles add column job_title_id uuid references public.job_titles (id);
alter table public.invitations add column job_title_id uuid references public.job_titles (id);

alter table public.job_titles enable row level security;
create policy "members read job titles" on public.job_titles
  for select to authenticated using (public.is_member());
create policy "managers add job titles" on public.job_titles
  for insert to authenticated with check (public.has_role(array['manager', 'system_admin']::public.app_role[]));
create policy "managers change job titles" on public.job_titles
  for update to authenticated
  using (public.has_role(array['manager', 'system_admin']::public.app_role[]))
  with check (public.has_role(array['manager', 'system_admin']::public.app_role[]));
revoke delete on public.job_titles from anon, authenticated;

-- A title's access level can't change while people have it (move them first).
create function public.guard_job_title()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.access_level <> old.access_level
     and exists (select 1 from public.profiles where job_title_id = old.id) then
    raise exception 'People have this role, so its access level can''t change. Give them another role first.';
  end if;
  if new.access_level <> old.access_level or new.name <> old.name or new.active <> old.active then
    perform public.write_audit('job_title_changed', 'job_title', new.id::text,
      jsonb_build_object('name', new.name, 'access_level', new.access_level, 'active', new.active));
  end if;
  return new;
end;
$$;

create trigger job_titles_guard
  before update on public.job_titles
  for each row execute function public.guard_job_title();

-- A person's access level always matches their job title. Runs before the
-- people guard (triggers run in name order), so the usual permission checks
-- apply to the resulting role change.
create function public.sync_title_and_role()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_level public.app_role;
begin
  if new.job_title_id is distinct from old.job_title_id and new.job_title_id is not null then
    select access_level into v_level from public.job_titles where id = new.job_title_id and active;
    if v_level is null then
      raise exception 'Choose a role that is in use';
    end if;
    new.role := v_level;
  elsif new.role is distinct from old.role and new.job_title_id is not null
        and (select access_level from public.job_titles where id = new.job_title_id) is distinct from new.role then
    -- A plain access-level change clears a title that no longer fits.
    new.job_title_id := null;
  end if;
  return new;
end;
$$;

create trigger profiles_a_sync_title
  before update on public.profiles
  for each row execute function public.sync_title_and_role();

-- ---------------------------------------------------------------------------
-- Teams
-- ---------------------------------------------------------------------------

alter table public.teams add column is_core boolean not null default false;
create unique index teams_one_core on public.teams ((true)) where is_core;
insert into public.teams (name, is_core) values ('Management (core team)', true)
on conflict do nothing;

create table public.team_members (
  team_id  uuid not null references public.teams (id) on delete cascade,
  user_id  uuid not null references public.profiles (id) on delete cascade,
  added_at timestamptz not null default now(),
  primary key (team_id, user_id)
);

create index team_members_user_idx on public.team_members (user_id);

-- Bring across the old one-team-per-person data.
insert into public.team_members (team_id, user_id)
select p.team_id, p.id from public.profiles p
  join public.teams t on t.id = p.team_id and not t.is_core
 where p.team_id is not null and p.role in ('support_worker', 'team_leader')
on conflict do nothing;
update public.profiles set team_id = null where team_id is not null;

-- Only team leaders lead teams, and each leads one (their earliest).
delete from public.team_leaders tl
 using public.profiles p
 where p.id = tl.user_id and p.role <> 'team_leader';
delete from public.team_leaders tl
 where exists (select 1 from public.team_leaders o
                where o.user_id = tl.user_id and o.team_id::text < tl.team_id::text);
delete from public.team_members m
 using public.profiles p
 where p.id = m.user_id and p.role = 'team_leader'
   and not exists (select 1 from public.team_leaders tl where tl.user_id = m.user_id and tl.team_id = m.team_id)
   and exists (select 1 from public.team_leaders tl where tl.user_id = m.user_id);
insert into public.team_members (team_id, user_id)
select team_id, user_id from public.team_leaders on conflict do nothing;

-- A team leader leads one team.
create unique index team_leaders_one_team on public.team_leaders (user_id);

-- Who can be in a team, and the one-team rule for team leaders.
create function public.guard_team_member()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_role public.app_role;
begin
  select role into v_role from public.profiles where id = new.user_id;
  if (select is_core from public.teams where id = new.team_id) then
    raise exception 'The core team is managers and staff admins, automatically';
  end if;
  if v_role not in ('support_worker', 'team_leader') then
    raise exception 'Managers and staff admins are in the core team, which works across every team';
  end if;
  if v_role = 'team_leader' and exists (
       select 1 from public.team_members where user_id = new.user_id and team_id <> new.team_id) then
    raise exception 'A team leader can be in one team only';
  end if;
  return new;
end;
$$;

create trigger team_members_guard
  before insert on public.team_members
  for each row execute function public.guard_team_member();

create function public.guard_team_leader()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select role from public.profiles where id = new.user_id) <> 'team_leader' then
    raise exception 'Only team leaders can lead a team';
  end if;
  if (select is_core from public.teams where id = new.team_id) then
    raise exception 'The core team has no team leader';
  end if;
  -- A leader is a member of the team they lead (and of no other).
  insert into public.team_members (team_id, user_id) values (new.team_id, new.user_id) on conflict do nothing;
  return new;
end;
$$;

create trigger team_leaders_guard
  before insert on public.team_leaders
  for each row execute function public.guard_team_leader();

-- When someone's role changes, tidy up their teams.
create function public.tidy_teams_after_role_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.role is distinct from old.role then
    if new.role not in ('support_worker', 'team_leader') then
      -- Managers and staff admins move to the core team.
      delete from public.team_leaders where user_id = new.id;
      delete from public.team_members where user_id = new.id;
    elsif new.role = 'support_worker' then
      delete from public.team_leaders where user_id = new.id;
    elsif new.role = 'team_leader'
          and (select count(*) from public.team_members where user_id = new.id) > 1 then
      raise exception 'A team leader can be in one team only. Take them out of the other teams first.';
    end if;
  end if;
  return new;
end;
$$;

create trigger profiles_tidy_teams
  after update of role on public.profiles
  for each row execute function public.tidy_teams_after_role_change();

alter table public.team_members enable row level security;
create policy "members read team members" on public.team_members
  for select to authenticated using (public.is_member());
create policy "managers change team members" on public.team_members
  for all to authenticated
  using (public.has_role(array['manager', 'system_admin']::public.app_role[]))
  with check (public.has_role(array['manager', 'system_admin']::public.app_role[]));

-- Set a team's members and leader in one go (managers; staff admins send a
-- request instead, which a manager approves).
create function public.set_team(p_team_id uuid, p_members uuid[], p_leader uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_members uuid[] := coalesce(p_members, '{}');
  v_old jsonb;
begin
  if not public.has_role(array['manager', 'system_admin']::public.app_role[]) then
    raise exception 'Only managers change who is in a team. Send it as a request.';
  end if;
  if (select is_core from public.teams where id = p_team_id) then
    raise exception 'The core team is managers and staff admins, automatically';
  end if;
  if p_leader is not null and not (p_leader = any (v_members)) then
    v_members := v_members || p_leader;
  end if;
  select jsonb_build_object(
           'members', coalesce((select jsonb_agg(user_id order by user_id) from public.team_members where team_id = p_team_id), '[]'),
           'leader', (select to_jsonb(user_id) from public.team_leaders where team_id = p_team_id limit 1))
    into v_old;

  delete from public.team_leaders where team_id = p_team_id and user_id is distinct from p_leader;
  delete from public.team_members where team_id = p_team_id and not (user_id = any (v_members));
  insert into public.team_members (team_id, user_id)
  select p_team_id, m from unnest(v_members) m on conflict do nothing;
  if p_leader is not null then
    insert into public.team_leaders (team_id, user_id) values (p_team_id, p_leader) on conflict do nothing;
  end if;

  perform public.write_audit('team_changed', 'team', p_team_id::text,
    jsonb_build_object('from', v_old, 'to', jsonb_build_object('members', to_jsonb(v_members), 'leader', p_leader)));
end;
$$;

revoke execute on function public.set_team(uuid, uuid[], uuid) from public, anon;
grant execute on function public.set_team(uuid, uuid[], uuid) to authenticated;

-- Team leaders lead the people in their team.
create or replace function public.leads_user(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.team_leaders tl
      join public.team_members m on m.team_id = tl.team_id
     where tl.user_id = auth.uid()
       and m.user_id = p_user_id
  ) and public.has_role(array['team_leader', 'manager', 'system_admin']::public.app_role[])
$$;

-- Managers see every team's tasks.
create or replace function public.can_see_task(p_task_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and (
    public.has_role(array['manager', 'system_admin']::public.app_role[])
    or exists (
      select 1
        from public.tasks t
       where t.id = p_task_id
         and (
           t.assigned_to = auth.uid()
           or t.created_by = auth.uid()
           or exists (select 1 from public.task_helpers h where h.task_id = t.id and h.user_id = auth.uid())
           or public.leads_user(t.assigned_to)
           or public.leads_user(t.created_by)
         )
    )
  )
$$;

-- New people join the team (and get the title) they were invited with.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  inv public.invitations;
  first_user boolean;
  v_role public.app_role;
begin
  select not exists (select 1 from public.profiles) into first_user;

  select * into inv
    from public.invitations i
   where lower(i.email) = lower(new.email)
     and i.accepted_at is null
   order by i.created_at desc
   limit 1;

  v_role := case
    when first_user then 'system_admin'::public.app_role
    else coalesce((select access_level from public.job_titles where id = inv.job_title_id),
                  inv.role, 'support_worker'::public.app_role)
  end;

  insert into public.profiles (id, email, full_name, role, job_title_id, active)
  values (
    new.id,
    new.email,
    coalesce(nullif(inv.full_name, ''), new.raw_user_meta_data ->> 'full_name', ''),
    v_role,
    case when first_user then null else inv.job_title_id end,
    -- Public sign-up is off, but as a second lock anyone who arrives
    -- without an invitation starts deactivated.
    first_user or inv.id is not null
  );

  if inv.team_id is not null and v_role in ('support_worker', 'team_leader') then
    insert into public.team_members (team_id, user_id) values (inv.team_id, new.id) on conflict do nothing;
  end if;

  if inv.id is not null then
    update public.invitations
       set accepted_at = now(), user_id = new.id
     where id = inv.id;
  end if;

  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Change requests: role (with title) and team membership
-- ---------------------------------------------------------------------------

drop function public.request_team_change(uuid, uuid, text);
drop function public.request_team_leaders(uuid, uuid[], text);
drop function public.request_role_change(uuid, public.app_role, text);

alter table public.people_change_requests drop constraint people_change_requests_check;
alter table public.people_change_requests drop constraint people_change_requests_kind_check;
alter table public.people_change_requests
  add constraint people_change_requests_kind_check check (kind in ('role', 'team')),
  add constraint people_change_requests_target_check check (
    (kind = 'role' and user_id is not null) or (kind = 'team' and team_id is not null));

-- p_to: an access level, or a job title (which brings its own access level).
create function public.request_role_change(p_user_id uuid, p_to_role public.app_role, p_title_id uuid default null, p_reason text default '')
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_from public.app_role;
  v_from_title uuid;
  v_to public.app_role := p_to_role;
begin
  if p_user_id = auth.uid() then
    raise exception 'You cannot change your own role';
  end if;
  select role, job_title_id into v_from, v_from_title from public.profiles where id = p_user_id and active;
  if v_from is null then
    raise exception 'Choose someone who can sign in';
  end if;
  if p_title_id is not null then
    select access_level into v_to from public.job_titles where id = p_title_id and active;
    if v_to is null then raise exception 'Choose a role that is in use'; end if;
  end if;
  if v_from = v_to and v_from_title is not distinct from p_title_id then
    raise exception 'They already have that role';
  end if;
  if not public.can_manage_role(v_from) or not public.can_manage_role(v_to) then
    raise exception 'Only a system admin can manage system admins';
  end if;
  return public.add_change_request('role', p_user_id, null,
    jsonb_build_object('role', v_from, 'title', v_from_title),
    jsonb_build_object('role', v_to, 'title', p_title_id), p_reason);
end;
$$;

create function public.request_team_change(p_team_id uuid, p_members uuid[], p_leader uuid, p_reason text default '')
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_from jsonb;
  v_to jsonb;
begin
  if not exists (select 1 from public.teams where id = p_team_id and not is_core) then
    raise exception 'Choose a team (the core team is set automatically)';
  end if;
  select jsonb_build_object(
           'members', coalesce((select jsonb_agg(user_id order by user_id) from public.team_members where team_id = p_team_id), '[]'),
           'leader', (select to_jsonb(user_id) from public.team_leaders where team_id = p_team_id limit 1))
    into v_from;
  v_to := jsonb_build_object(
    'members', coalesce((select jsonb_agg(distinct m order by m) from unnest(coalesce(p_members, '{}') || coalesce(array[p_leader], '{}')) m where m is not null), '[]'),
    'leader', to_jsonb(p_leader));
  if v_from = v_to then
    raise exception 'Nothing has changed';
  end if;
  return public.add_change_request('team', null, p_team_id, v_from, v_to, p_reason);
end;
$$;

create or replace function public.add_change_request(
  p_kind text, p_user_id uuid, p_team_id uuid, p_from jsonb, p_to jsonb, p_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
begin
  if not public.has_role(array['staff_admin']::public.app_role[]) then
    raise exception 'Only staff admins send change requests; managers make changes straight away';
  end if;
  -- A new request replaces an older one still waiting.
  update public.people_change_requests
     set status = 'withdrawn', decided_by = auth.uid(), decided_at = now()
   where kind = p_kind and coalesce(user_id, team_id) = coalesce(p_user_id, p_team_id) and status = 'pending';
  insert into public.people_change_requests (kind, user_id, team_id, from_value, to_value, reason, requested_by)
  values (p_kind, p_user_id, p_team_id, p_from, p_to, coalesce(trim(p_reason), ''), auth.uid())
  returning id into v_id;
  perform public.write_audit(p_kind || '_change_requested', case when p_kind = 'team' then 'team' else 'profile' end,
    coalesce(p_user_id, p_team_id)::text, jsonb_build_object('from', p_from, 'to', p_to));
  return v_id;
end;
$$;

create or replace function public.decide_change_request(p_request_id uuid, p_approve boolean, p_note text default '')
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.people_change_requests;
  v_members uuid[];
begin
  if not public.has_role(array['manager', 'system_admin']::public.app_role[]) then
    raise exception 'Only managers can approve these changes';
  end if;
  select * into r from public.people_change_requests where id = p_request_id for update;
  if r.id is null or r.status <> 'pending' then
    raise exception 'This request has already been dealt with';
  end if;
  if r.user_id = auth.uid() then
    raise exception 'You cannot approve a change about yourself';
  end if;

  -- Applied as the approving manager, so all the usual checks still run.
  if p_approve then
    if r.kind = 'role' then
      if (select role::text from public.profiles where id = r.user_id) <> r.from_value ->> 'role' then
        raise exception 'Their role has changed since the request was made. Ask for a new request.';
      end if;
      if r.to_value ->> 'title' is not null then
        update public.profiles set job_title_id = (r.to_value ->> 'title')::uuid where id = r.user_id;
      else
        update public.profiles set role = (r.to_value ->> 'role')::public.app_role, job_title_id = null where id = r.user_id;
      end if;
    else
      select coalesce(array_agg(x::uuid), '{}') into v_members from jsonb_array_elements_text(r.to_value -> 'members') x;
      perform public.set_team(r.team_id, v_members, (r.to_value ->> 'leader')::uuid);
    end if;
  end if;

  update public.people_change_requests
     set status = case when p_approve then 'approved' else 'declined' end,
         decided_by = auth.uid(), decided_at = now(), decision_note = coalesce(trim(p_note), '')
   where id = p_request_id;
  perform public.write_audit(r.kind || case when p_approve then '_change_approved' else '_change_declined' end,
    case when r.kind = 'team' then 'team' else 'profile' end, coalesce(r.user_id, r.team_id)::text,
    jsonb_build_object('from', r.from_value, 'to', r.to_value));
end;
$$;

revoke execute on function public.request_role_change(uuid, public.app_role, uuid, text) from public, anon;
revoke execute on function public.request_team_change(uuid, uuid[], uuid, text) from public, anon;
grant execute on function public.request_role_change(uuid, public.app_role, uuid, text) to authenticated;
grant execute on function public.request_team_change(uuid, uuid[], uuid, text) to authenticated;

$m011$;
  insert into public.install_log (name) values ('20261106000001_teams_and_job_titles.sql');
end;
$part$;

-- ====================================================================
-- 20261107000001_request_notifications.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261107000001_request_notifications.sql') then
    return;
  end if;
  execute $m012$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- The bell also tells staff admins when a manager approves or declines a
-- role or team change they asked for. Opening Staff & roles or Teams, or
-- "Mark all as seen", clears it.

alter table public.people_change_requests add column requester_seen_at timestamptz;

-- Old decisions don't suddenly appear in the bell.
update public.people_change_requests set requester_seen_at = now() where status <> 'pending';

-- Decided requests the signed-in person asked for and hasn't seen yet.
create function public.my_request_updates()
returns table (
  request_id uuid,
  kind text,
  status text,
  subject text,
  change text,
  decided_by_name text,
  decided_at timestamptz,
  note text
)
language sql
stable
security definer
set search_path = ''
as $$
  select r.id,
         r.kind,
         r.status,
         case when r.kind = 'team' then coalesce(t.name, 'A team')
              else coalesce(nullif(p.full_name, ''), p.email, 'Someone') end,
         case when r.kind = 'role'
              then coalesce((select j.name from public.job_titles j where j.id = (r.to_value ->> 'title')::uuid),
                            initcap(replace(r.to_value ->> 'role', '_', ' ')))
              else 'who is in the team' end,
         -- System admins stay hidden from other staff.
         case when d.role = 'system_admin' then 'Admin' else coalesce(nullif(d.full_name, ''), d.email, 'A manager') end,
         r.decided_at,
         r.decision_note
    from public.people_change_requests r
    left join public.profiles p on p.id = r.user_id
    left join public.teams t on t.id = r.team_id
    left join public.profiles d on d.id = r.decided_by
   where public.is_member()
     and r.requested_by = auth.uid()
     and r.status in ('approved', 'declined')
     and r.requester_seen_at is null
   order by r.decided_at desc
$$;

-- p_kind: 'role', 'team', or null for all.
create function public.mark_request_updates_seen(p_kind text default null)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.people_change_requests
     set requester_seen_at = now()
   where requested_by = auth.uid()
     and status in ('approved', 'declined')
     and requester_seen_at is null
     and (p_kind is null or kind = p_kind)
$$;

revoke execute on function public.my_request_updates() from public, anon;
revoke execute on function public.mark_request_updates_seen(text) from public, anon;
grant execute on function public.my_request_updates() to authenticated;
grant execute on function public.mark_request_updates_seen(text) to authenticated;

$m012$;
  insert into public.install_log (name) values ('20261107000001_request_notifications.sql');
end;
$part$;

-- ====================================================================
-- 20261108000001_due_alerts.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261108000001_due_alerts.sql') then
    return;
  end if;
  execute $m013$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Reminders, overdue alerts and automatic escalation. A timer calls
-- run_due_alerts() every hour; each step is sent once per task and due date.
--   Reminder   N working days before it's due  → the person looking after it
--   Due today                                   → them and helpers
--   Overdue    the day after it's due           → them and their team leaders
--                                                 (managers if there's no leader)
--   Escalated  N working days overdue           → managers; the task is
--                                                 marked escalated
--   Summary    every weekday from 7am           → managers, one email listing
--                                                 everything overdue
-- Completed and closed tasks, and tasks with no due date, never alert.

insert into public.app_settings (key, value, label, description, is_public) values
  ('tasks.sla_remind_days', '1', 'Reminder before the due date (days)',
   'Remind the person looking after a task this many days before it''s due. 0 means no reminder.', false),
  ('tasks.sla_escalate_days', '3', 'Escalate after (days overdue)',
   'Tell the managers and mark a task escalated when it''s this many days overdue.', false),
  ('tasks.sla_manager_summary', 'true', 'Morning summary for managers',
   'Every weekday morning, email managers one list of everything overdue.', false)
on conflict (key) do nothing;

-- What has been sent, so nobody hears about the same step twice. A new due
-- date starts the steps again.
create table public.task_alerts (
  id         bigint generated always as identity primary key,
  task_id    uuid not null references public.tasks (id) on delete cascade,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  step       text not null check (step in ('reminder', 'due_today', 'overdue', 'escalated')),
  due_date   date not null,
  created_at timestamptz not null default now(),
  unique (task_id, user_id, step, due_date)
);

create index task_alerts_user_idx on public.task_alerts (user_id, created_at desc);

alter table public.task_alerts enable row level security;
create policy "read your own alerts" on public.task_alerts
  for select to authenticated using (user_id = auth.uid());
revoke insert, update, delete, truncate on public.task_alerts from anon, authenticated;

-- Jobs that run once a day (the morning summary).
create table public.daily_runs (
  job text not null,
  day date not null,
  ran_at timestamptz not null default now(),
  primary key (job, day)
);
alter table public.daily_runs enable row level security;
revoke all on public.daily_runs from anon, authenticated;

-- Working days after p_from up to and including p_to (negative if p_to is earlier).
create function public.working_days_between(p_from date, p_to date, p_weekdays_only boolean)
returns int
language sql
immutable
set search_path = ''
as $$
  select case
    when not p_weekdays_only then p_to - p_from
    when p_to >= p_from then (select count(*)::int from generate_series(p_from + 1, p_to, interval '1 day') d
                               where extract(isodow from d) < 6)
    else -(select count(*)::int from generate_series(p_to + 1, p_from, interval '1 day') d
            where extract(isodow from d) < 6)
  end
$$;

-- Managers for a task: its register's managers, or every manager if it has none.
create function public.task_managers(p_task_id uuid)
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  with reg as (
    select rm.user_id from public.registry_managers rm
      join public.tasks t on t.registry_id = rm.registry_id
      join public.profiles p on p.id = rm.user_id and p.active and p.role = 'manager'
     where t.id = p_task_id
  )
  select user_id from reg
  union
  select id from public.profiles where active and role = 'manager' and not exists (select 1 from reg)
$$;

-- Records an alert and, the first time only, puts it in the bell and emails it.
create function public.send_due_alert(p_task_id uuid, p_user_id uuid, p_step text, p_due date)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id bigint;
begin
  if not exists (select 1 from public.profiles where id = p_user_id and active and role <> 'system_admin') then
    return;
  end if;
  insert into public.task_alerts (task_id, user_id, step, due_date)
  values (p_task_id, p_user_id, p_step, p_due)
  on conflict do nothing
  returning id into v_id;
  if v_id is not null then
    perform public.queue_task_email('task_' || p_step, p_task_id, p_user_id);
  end if;
end;
$$;

-- p_now is only for tests; the timer always uses the real time.
create function public.run_due_alerts(p_now timestamptz default now())
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tz text := coalesce((select value #>> '{}' from public.app_settings where key = 'region.timezone'), 'Australia/Melbourne');
  v_now timestamp := p_now at time zone v_tz;
  v_today date := v_now::date;
  v_weekdays boolean := coalesce((select (value #>> '{}')::boolean from public.app_settings where key = 'tasks.sla_weekdays_only'), false);
  v_remind int := coalesce((select (value #>> '{}')::int from public.app_settings where key = 'tasks.sla_remind_days'), 1);
  v_escalate int := coalesce((select (value #>> '{}')::int from public.app_settings where key = 'tasks.sla_escalate_days'), 3);
  v_summary boolean := coalesce((select (value #>> '{}')::boolean from public.app_settings where key = 'tasks.sla_manager_summary'), true);
  v_weekend boolean := extract(isodow from v_today) >= 6;
  t record;
  v_late int;
  v_person uuid;
  v_leaders uuid[];
  v_escalated int := 0;
  v_summaries int := 0;
  v_list jsonb;
begin
  if not public.feature_enabled('tasks') then
    return jsonb_build_object('skipped', 'tasks are switched off');
  end if;
  -- With "weekdays only", nothing is sent at the weekend; Monday catches up.
  if v_weekdays and v_weekend then
    return jsonb_build_object('skipped', 'weekend');
  end if;

  for t in
    select id, assigned_to, due_date, status, escalated
      from public.tasks
     where due_date is not null
       and status not in ('completed', 'closed')
       and due_date <= v_today + greatest(v_remind, 0) + 7
  loop
    v_late := public.working_days_between(t.due_date, v_today, v_weekdays);

    if t.due_date > v_today then
      if v_remind > 0 and -v_late <= v_remind then
        perform public.send_due_alert(t.id, t.assigned_to, 'reminder', t.due_date);
      end if;
      continue;
    end if;

    if t.due_date = v_today then
      perform public.send_due_alert(t.id, t.assigned_to, 'due_today', t.due_date);
      for v_person in select user_id from public.task_helpers where task_id = t.id loop
        perform public.send_due_alert(t.id, v_person, 'due_today', t.due_date);
      end loop;
      continue;
    end if;

    -- Overdue: the person and their team leaders (managers if there are none).
    perform public.send_due_alert(t.id, t.assigned_to, 'overdue', t.due_date);
    select coalesce(array_agg(distinct tl.user_id), '{}') into v_leaders
      from public.team_members m
      join public.team_leaders tl on tl.team_id = m.team_id
      join public.profiles p on p.id = tl.user_id and p.active
     where m.user_id = t.assigned_to and tl.user_id <> t.assigned_to;
    if cardinality(v_leaders) = 0 then
      select coalesce(array_agg(m), '{}') into v_leaders from public.task_managers(t.id) m;
    end if;
    foreach v_person in array v_leaders loop
      perform public.send_due_alert(t.id, v_person, 'overdue', t.due_date);
    end loop;

    -- Still overdue: managers, and the task is marked escalated.
    if v_escalate > 0 and v_late >= v_escalate then
      if t.status <> 'escalated' then
        update public.tasks set status = 'escalated', escalated = true, updated_at = now() where id = t.id;
        insert into public.task_events (task_id, actor_id, type, from_value, to_value, comment)
        values (t.id, null, 'status_changed', t.status::text, 'escalated',
                format('Escalated automatically: %s days overdue', v_late));
        v_escalated := v_escalated + 1;
      end if;
      for v_person in select m from public.task_managers(t.id) m loop
        perform public.send_due_alert(t.id, v_person, 'escalated', t.due_date);
      end loop;
    end if;
  end loop;

  -- The morning summary, once each weekday from 7am.
  if v_summary and not v_weekend and extract(hour from v_now) >= 7 and public.feature_enabled('email_notifications') then
    insert into public.daily_runs (job, day) values ('manager_summary', v_today) on conflict do nothing;
    if found then
      select jsonb_agg(jsonb_build_object(
               'id', t2.id,
               'ref', coalesce(r.prefix, 'T') || '-' || lpad(t2.ref_number::text, 4, '0'),
               'title', t2.title,
               'registry', r.name,
               'assignee', case when p.role = 'system_admin' then 'Admin' else coalesce(nullif(p.full_name, ''), p.email) end,
               'due_date', t2.due_date,
               'days_late', public.working_days_between(t2.due_date, v_today, v_weekdays),
               'escalated', t2.status = 'escalated')
             order by t2.due_date, t2.ref_number)
        into v_list
        from public.tasks t2
        join public.registries r on r.id = t2.registry_id
        join public.profiles p on p.id = t2.assigned_to
       where t2.due_date < v_today and t2.status not in ('completed', 'closed');
      if v_list is not null then
        insert into public.email_outbox (to_user, template, data)
        select id, 'overdue_summary', jsonb_build_object('tasks', v_list, 'day', v_today)
          from public.profiles where active and role = 'manager';
        get diagnostics v_summaries = row_count;
      end if;
    end if;
  end if;

  return jsonb_build_object('today', v_today, 'escalated', v_escalated, 'summaries', v_summaries);
end;
$$;

revoke execute on function public.run_due_alerts(timestamptz) from public, anon, authenticated;
revoke execute on function public.send_due_alert(uuid, uuid, text, date) from public, anon, authenticated;
revoke execute on function public.task_managers(uuid) from public, anon, authenticated;
grant execute on function public.run_due_alerts(timestamptz) to service_role;

-- The bell: reminders and overdue alerts you haven't opened since.
create function public.my_due_alerts()
returns table (task_id uuid, step text, at timestamptz)
language sql
stable
security definer
set search_path = ''
as $$
  select distinct on (a.task_id) a.task_id, a.step, a.created_at
    from public.task_alerts a
    join public.tasks t on t.id = a.task_id
   where public.is_member()
     and a.user_id = auth.uid()
     and t.status not in ('completed', 'closed')
     and a.due_date = t.due_date
     and not exists (select 1 from public.task_views v
                      where v.task_id = a.task_id and v.user_id = auth.uid() and v.seen_at >= a.created_at)
   order by a.task_id,
            array_position(array['escalated', 'overdue', 'due_today', 'reminder'], a.step),
            a.created_at desc
$$;

create or replace function public.mark_all_tasks_seen()
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.task_views (task_id, user_id, seen_at)
  select n.task_id, auth.uid(), now() from public.my_new_tasks() n
  union
  select a.task_id, auth.uid(), now() from public.my_due_alerts() a
  on conflict (task_id, user_id) do update set seen_at = excluded.seen_at
$$;

revoke execute on function public.my_due_alerts() from public, anon;
grant execute on function public.my_due_alerts() to authenticated;

$m013$;
  insert into public.install_log (name) values ('20261108000001_due_alerts.sql');
end;
$part$;

-- ====================================================================
-- 20261109000001_quiet_reminders.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261109000001_quiet_reminders.sql') then
    return;
  end if;
  execute $m014$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- No email spam: reminders and "due today" go to the bell only. Emails are
-- sent only when a task is overdue or escalated (and the managers' summary).

create or replace function public.send_due_alert(p_task_id uuid, p_user_id uuid, p_step text, p_due date)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id bigint;
begin
  if not exists (select 1 from public.profiles where id = p_user_id and active and role <> 'system_admin') then
    return;
  end if;
  insert into public.task_alerts (task_id, user_id, step, due_date)
  values (p_task_id, p_user_id, p_step, p_due)
  on conflict do nothing
  returning id into v_id;
  if v_id is not null and p_step in ('overdue', 'escalated') then
    perform public.queue_task_email('task_' || p_step, p_task_id, p_user_id);
  end if;
end;
$$;

revoke execute on function public.send_due_alert(uuid, uuid, text, date) from public, anon, authenticated;

$m014$;
  insert into public.install_log (name) values ('20261109000001_quiet_reminders.sql');
end;
$part$;

-- ====================================================================
-- 20261110000001_new_starter_role.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261110000001_new_starter_role.sql') then
    return;
  end if;
  execute $m015$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- New starters: people who've joined with a general invite but don't have a
-- role yet. (On its own so the new value is saved before it's used.)

-- (access level already in the list above)

$m015$;
  insert into public.install_log (name) values ('20261110000001_new_starter_role.sql');
end;
$part$;

-- ====================================================================
-- 20261110000002_general_invites.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261110000002_general_invites.sql') then
    return;
  end if;
  execute $m016$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- General invites. Anyone can be invited without a role or team; they join as
-- a new starter with limited access (their account for now; trainings and
-- documents later). Staff admins give a new starter their first role straight
-- away; later role changes still need a manager's approval. New starters
-- can't create or be given tasks.

alter table public.invitations alter column role set default 'new_starter';

-- Roles (job titles) link to a real access level.
alter table public.job_titles drop constraint job_titles_access_level_check;
alter table public.job_titles add constraint job_titles_access_level_check
  check (access_level not in ('system_admin', 'new_starter'));

create or replace function public.guard_profile_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor uuid := auth.uid();
begin
  if new.id <> old.id or new.email <> old.email or new.org_id <> old.org_id then
    raise exception 'This field cannot be changed here';
  end if;

  if actor is not null then
    if new.role is distinct from old.role
       or new.team_id is distinct from old.team_id
       or new.active is distinct from old.active then

      if not public.can_manage_people() then
        raise exception 'Only managers and admins can change roles, teams or access';
      end if;

      -- Nobody promotes, demotes or deactivates themselves.
      if new.id = actor and (new.role is distinct from old.role or not new.active) then
        raise exception 'You cannot change your own role or deactivate yourself';
      end if;

      if new.id <> actor and (not public.can_manage_role(old.role) or not public.can_manage_role(new.role)) then
        raise exception 'Only a system admin can manage system admins';
      end if;

      -- A staff admin's role changes need a manager's approval first.
      -- (Managers apply approved requests as themselves, so this never blocks them.)
      -- A new starter's first role is the exception: staff admins set it straight away.
      if new.role is distinct from old.role and public.my_role() = 'staff_admin' and old.role <> 'new_starter' then
        raise exception 'Role changes by a staff admin need a manager''s approval. Send it as a request.';
      end if;
      if new.team_id is distinct from old.team_id and public.my_role() = 'staff_admin' then
        raise exception 'Team changes by a staff admin need a manager''s approval. Send it as a request.';
      end if;
    end if;
  end if;

  if old.role = 'system_admin' and old.active
     and (new.role <> 'system_admin' or not new.active)
     and not exists (
       select 1 from public.profiles
        where role = 'system_admin' and active and id <> old.id
     ) then
    raise exception 'There must always be at least one active system admin';
  end if;

  if new.active and not old.active then
    new.deactivated_at := null;
  elsif not new.active and old.active then
    new.deactivated_at := now();
  end if;

  if new.role is distinct from old.role then
    perform public.write_audit('role_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.role, 'to', new.role));
  end if;
  if new.active is distinct from old.active then
    perform public.write_audit(
      case when new.active then 'reactivated' else 'deactivated' end,
      'profile', new.id::text, '{}'::jsonb);
  end if;
  if new.team_id is distinct from old.team_id then
    perform public.write_audit('team_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.team_id, 'to', new.team_id));
  end if;

  return new;
end;
$$;

-- An invitation with no role makes a new starter.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  inv public.invitations;
  first_user boolean;
  v_role public.app_role;
begin
  select not exists (select 1 from public.profiles) into first_user;

  select * into inv
    from public.invitations i
   where lower(i.email) = lower(new.email)
     and i.accepted_at is null
   order by i.created_at desc
   limit 1;

  v_role := case
    when first_user then 'system_admin'::public.app_role
    else coalesce((select access_level from public.job_titles where id = inv.job_title_id),
                  inv.role, 'new_starter'::public.app_role)
  end;

  insert into public.profiles (id, email, full_name, role, job_title_id, active)
  values (
    new.id,
    new.email,
    coalesce(nullif(inv.full_name, ''), new.raw_user_meta_data ->> 'full_name', ''),
    v_role,
    case when first_user then null else inv.job_title_id end,
    -- Public sign-up is off, but as a second lock anyone who arrives
    -- without an invitation starts deactivated.
    first_user or inv.id is not null
  );

  if inv.team_id is not null and v_role in ('support_worker', 'team_leader') then
    insert into public.team_members (team_id, user_id) values (inv.team_id, new.id) on conflict do nothing;
  end if;

  if inv.id is not null then
    update public.invitations
       set accepted_at = now(), user_id = new.id
     where id = inv.id;
  end if;

  return new;
end;
$$;

create or replace function public.can_take_tasks(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.profiles where id = p_user_id and active and role not in ('system_admin', 'new_starter'))
$$;

create or replace function public.guard_task_people()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.my_role() = 'new_starter' then
    raise exception 'You''ll be able to use tasks once a staff admin has set up your role';
  end if;
  if tg_table_name = 'tasks' then
    if (tg_op = 'INSERT' or new.assigned_to is distinct from old.assigned_to) then
      if exists (select 1 from public.profiles where id = new.assigned_to and role = 'system_admin') then
        raise exception 'System admins can''t be given tasks. Choose someone else to look after it.';
      end if;
      if exists (select 1 from public.profiles where id = new.assigned_to and role = 'new_starter') then
        raise exception 'New starters can''t be given tasks until they have a role';
      end if;
    end if;
  elsif exists (select 1 from public.profiles where id = new.user_id and role in ('system_admin', 'new_starter')) then
    raise exception 'System admins and new starters can''t be added as helpers';
  end if;
  return new;
end;
$$;

$m016$;
  insert into public.install_log (name) values ('20261110000002_general_invites.sql');
end;
$part$;

-- ====================================================================
-- 20261110000003_people_rules.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261110000003_people_rules.sql') then
    return;
  end if;
  execute $m017$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- People rules the system admin can switch on and off in System settings.

insert into public.app_settings (key, value, label, description, is_public) values
  ('people.staff_admin_role_approval', 'true', 'Staff admin role changes need a manager''s approval',
   'When on, a staff admin''s role changes wait for a manager to approve them.', false),
  ('people.staff_admin_team_approval', 'true', 'Staff admin team changes need a manager''s approval',
   'When on, a staff admin''s changes to who is in a team wait for a manager to approve them.', false),
  ('people.first_role_approval', 'false', 'A new starter''s first role needs approval',
   'When off, a staff admin gives a new starter their first role straight away.', false),
  ('people.general_invites_only', 'false', 'Every invite is a general invite',
   'When on, people are always invited as new starters with no role or team, and given a role afterwards. System admins can still pick a role.', false),
  ('people.new_starter_tasks', 'false', 'New starters can be given tasks',
   'When off, new starters don''t use tasks until they have a role.', false)
on conflict (key) do nothing;

create function public.rule_on(p_key text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select (value #>> '{}')::boolean from public.app_settings where key = p_key), false)
$$;

create or replace function public.guard_profile_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor uuid := auth.uid();
begin
  if new.id <> old.id or new.email <> old.email or new.org_id <> old.org_id then
    raise exception 'This field cannot be changed here';
  end if;

  if actor is not null then
    if new.role is distinct from old.role
       or new.team_id is distinct from old.team_id
       or new.active is distinct from old.active then

      if not public.can_manage_people() then
        raise exception 'Only managers and admins can change roles, teams or access';
      end if;

      -- Nobody promotes, demotes or deactivates themselves.
      if new.id = actor and (new.role is distinct from old.role or not new.active) then
        raise exception 'You cannot change your own role or deactivate yourself';
      end if;

      if new.id <> actor and (not public.can_manage_role(old.role) or not public.can_manage_role(new.role)) then
        raise exception 'Only a system admin can manage system admins';
      end if;

      -- A staff admin's role changes need a manager's approval first.
      -- (Managers apply approved requests as themselves, so this never blocks them.)
      -- A new starter's first role is the exception: staff admins set it straight away.
      if new.role is distinct from old.role and public.my_role() = 'staff_admin'
         and public.rule_on('people.staff_admin_role_approval')
         and (old.role <> 'new_starter' or public.rule_on('people.first_role_approval')) then
        raise exception 'Role changes by a staff admin need a manager''s approval. Send it as a request.';
      end if;
      if new.team_id is distinct from old.team_id and public.my_role() = 'staff_admin'
         and public.rule_on('people.staff_admin_team_approval') then
        raise exception 'Team changes by a staff admin need a manager''s approval. Send it as a request.';
      end if;
    end if;
  end if;

  if old.role = 'system_admin' and old.active
     and (new.role <> 'system_admin' or not new.active)
     and not exists (
       select 1 from public.profiles
        where role = 'system_admin' and active and id <> old.id
     ) then
    raise exception 'There must always be at least one active system admin';
  end if;

  if new.active and not old.active then
    new.deactivated_at := null;
  elsif not new.active and old.active then
    new.deactivated_at := now();
  end if;

  if new.role is distinct from old.role then
    perform public.write_audit('role_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.role, 'to', new.role));
  end if;
  if new.active is distinct from old.active then
    perform public.write_audit(
      case when new.active then 'reactivated' else 'deactivated' end,
      'profile', new.id::text, '{}'::jsonb);
  end if;
  if new.team_id is distinct from old.team_id then
    perform public.write_audit('team_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.team_id, 'to', new.team_id));
  end if;

  return new;
end;
$$;

create or replace function public.guard_invitation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.can_manage_people() then
    raise exception 'Only managers and admins can invite people';
  end if;
  if auth.uid() is not null and not public.can_manage_role(new.role) then
    raise exception 'Only a system admin can invite a system admin';
  end if;
  if auth.uid() is not null and public.rule_on('people.general_invites_only')
     and new.role <> 'new_starter' and public.my_role() <> 'system_admin' then
    raise exception 'Invites are general: they join as a new starter and you set their role afterwards';
  end if;
  if auth.uid() is not null and new.team_id is not null and public.my_role() = 'staff_admin'
     and public.rule_on('people.staff_admin_team_approval') then
    raise exception 'Add them to a team once they''ve joined; a manager approves team changes';
  end if;
  new.email := lower(trim(new.email));
  if tg_op = 'INSERT' then
    new.invited_by := coalesce(new.invited_by, auth.uid());
    perform public.write_audit('invited', 'invitation', new.email,
      jsonb_build_object('role', new.role));
  end if;
  return new;
end;
$$;

create or replace function public.set_team(p_team_id uuid, p_members uuid[], p_leader uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_members uuid[] := coalesce(p_members, '{}');
  v_old jsonb;
begin
  if not (public.has_role(array['manager', 'system_admin']::public.app_role[])
          or (public.has_role(array['staff_admin']::public.app_role[])
              and not public.rule_on('people.staff_admin_team_approval'))) then
    raise exception 'Only managers change who is in a team. Send it as a request.';
  end if;
  if (select is_core from public.teams where id = p_team_id) then
    raise exception 'The core team is managers and staff admins, automatically';
  end if;
  if p_leader is not null and not (p_leader = any (v_members)) then
    v_members := v_members || p_leader;
  end if;
  select jsonb_build_object(
           'members', coalesce((select jsonb_agg(user_id order by user_id) from public.team_members where team_id = p_team_id), '[]'),
           'leader', (select to_jsonb(user_id) from public.team_leaders where team_id = p_team_id limit 1))
    into v_old;

  delete from public.team_leaders where team_id = p_team_id and user_id is distinct from p_leader;
  delete from public.team_members where team_id = p_team_id and not (user_id = any (v_members));
  insert into public.team_members (team_id, user_id)
  select p_team_id, m from unnest(v_members) m on conflict do nothing;
  if p_leader is not null then
    insert into public.team_leaders (team_id, user_id) values (p_team_id, p_leader) on conflict do nothing;
  end if;

  perform public.write_audit('team_changed', 'team', p_team_id::text,
    jsonb_build_object('from', v_old, 'to', jsonb_build_object('members', to_jsonb(v_members), 'leader', p_leader)));
end;
$$;

create or replace function public.can_take_tasks(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.profiles where id = p_user_id and active and role <> 'system_admin'
                 and (role <> 'new_starter' or public.rule_on('people.new_starter_tasks')))
$$;

create or replace function public.guard_task_people()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.my_role() = 'new_starter' and not public.rule_on('people.new_starter_tasks') then
    raise exception 'You''ll be able to use tasks once a staff admin has set up your role';
  end if;
  if tg_table_name = 'tasks' then
    if (tg_op = 'INSERT' or new.assigned_to is distinct from old.assigned_to) then
      if exists (select 1 from public.profiles where id = new.assigned_to and role = 'system_admin') then
        raise exception 'System admins can''t be given tasks. Choose someone else to look after it.';
      end if;
      if exists (select 1 from public.profiles where id = new.assigned_to and role = 'new_starter')
         and not public.rule_on('people.new_starter_tasks') then
        raise exception 'New starters can''t be given tasks until they have a role';
      end if;
    end if;
  elsif exists (select 1 from public.profiles where id = new.user_id and role = 'system_admin') then
    raise exception 'System admins can''t be added as helpers';
  elsif exists (select 1 from public.profiles where id = new.user_id and role = 'new_starter')
        and not public.rule_on('people.new_starter_tasks') then
    raise exception 'New starters can''t be added as helpers until they have a role';
  end if;
  return new;
end;
$$;

$m017$;
  insert into public.install_log (name) values ('20261110000003_people_rules.sql');
end;
$part$;

-- ====================================================================
-- 20261111000001_onboarding_and_compliance.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261111000001_onboarding_and_compliance.sql') then
    return;
  end if;
  execute $m018$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Onboarding and Compliance.
--   Everyone has "My onboarding": documents to read and confirm, trainings,
--   and documents to upload (with expiry dates). Staff admins look after
--   them in "Compliance" (the system admin can let other roles do it too).
--   Managers and team leaders see progress only, never the files.
--   A new starter gets a role once onboarding is finished, or earlier as a
--   conditional role: a reason, what's missing and a deadline, approved by a
--   manager. The person then gets a "Finish onboarding" task due that day.
-- Also: notifications for the bell (and email where it matters), who can
-- send invites, and staff admins hearing when someone joins.

-- ---------------------------------------------------------------------------
-- Settings
-- ---------------------------------------------------------------------------

insert into public.app_settings (key, value, label, description, is_public) values
  ('people.invite_roles', '["staff_admin", "manager"]', 'Who can send invites',
   'Besides the system admin. People they invite join as new starters.', false),
  ('compliance.manager_roles', '["staff_admin"]', 'Who manages Compliance',
   'Besides the system admin: who adds documents, trainings and uploads, and checks what people upload.', false),
  ('compliance.expiry_warning_days', '30', 'Expiry reminder (days before)',
   'Remind people (in the bell) this many days before an uploaded document expires.', false)
on conflict (key) do nothing;

create function public.setting_roles(p_key text)
returns public.app_role[]
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select array_agg(x::public.app_role)
                     from public.app_settings s, jsonb_array_elements_text(s.value) x
                    where s.key = p_key and jsonb_typeof(s.value) = 'array'), '{}')
$$;

create function public.can_invite()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.mfa_ok() and (public.my_role() = 'system_admin'
         or public.my_role() = any (public.setting_roles('people.invite_roles')))
$$;

create function public.can_manage_compliance()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.mfa_ok() and (public.my_role() = 'system_admin'
         or public.my_role() = any (public.setting_roles('compliance.manager_roles')))
$$;

create function public.local_today()
returns date
language sql
stable
security definer
set search_path = ''
as $$
  select (now() at time zone coalesce((select value #>> '{}' from public.app_settings where key = 'region.timezone'),
                                      'Australia/Melbourne'))::date
$$;

-- ---------------------------------------------------------------------------
-- Notifications (the bell), with an email when it matters
-- ---------------------------------------------------------------------------

create table public.notifications (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  kind       text not null,
  title      text not null,
  body       text not null default '',
  href       text not null default '/' check (href like '/%'),
  created_at timestamptz not null default now(),
  seen_at    timestamptz
);

create index notifications_user_idx on public.notifications (user_id, created_at desc) where seen_at is null;

alter table public.notifications enable row level security;
create policy "read your own notifications" on public.notifications
  for select to authenticated using (user_id = auth.uid());
revoke insert, update, delete, truncate on public.notifications from anon, authenticated;

create function public.notify(p_user uuid, p_kind text, p_title text, p_body text, p_href text, p_email boolean default false)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_user is null or not exists (select 1 from public.profiles where id = p_user and active) then
    return;
  end if;
  insert into public.notifications (user_id, kind, title, body, href)
  values (p_user, p_kind, p_title, coalesce(p_body, ''), coalesce(p_href, '/'));
  if p_email and public.feature_enabled('email_notifications') then
    insert into public.email_outbox (to_user, template, data)
    values (p_user, 'notice', jsonb_build_object('title', p_title, 'body', coalesce(p_body, ''), 'href', coalesce(p_href, '/')));
  end if;
end;
$$;

create function public.mark_notification_seen(p_id bigint)
returns text
language sql
security definer
set search_path = ''
as $$
  update public.notifications set seen_at = coalesce(seen_at, now())
   where id = p_id and user_id = auth.uid()
  returning href
$$;

create function public.mark_all_notifications_seen()
returns void
language sql
security definer
set search_path = ''
as $$
  update public.notifications set seen_at = now() where user_id = auth.uid() and seen_at is null
$$;

-- Staff admins (and whoever manages Compliance) hear about people things.
create function public.people_admins()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select id from public.profiles
   where active and (role = 'staff_admin' or role = any (public.setting_roles('compliance.manager_roles')))
     and role <> 'system_admin'
$$;

-- ---------------------------------------------------------------------------
-- Joining and onboarding dates
-- ---------------------------------------------------------------------------

alter table public.profiles add column joined_at timestamptz, add column onboarded_at timestamptz;
update public.profiles set joined_at = created_at;

-- Called when someone finishes setting up their account from the invite.
create function public.mark_joined()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  me public.profiles;
  v_admin uuid;
  v_inviter uuid;
begin
  select * into me from public.profiles where id = auth.uid();
  if me.id is null or me.joined_at is not null then
    return;
  end if;
  update public.profiles set joined_at = now() where id = me.id;
  select invited_by into v_inviter from public.invitations where user_id = me.id order by created_at desc limit 1;
  for v_admin in select a from public.people_admins() a union select v_inviter where v_inviter is not null loop
    continue when v_admin = me.id;
    perform public.notify(v_admin, 'joined',
      format('%s has joined', coalesce(nullif(me.full_name, ''), me.email)),
      'They''ve created their account. Set their role and team once onboarding is done.',
      '/settings/staff', true);
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- What people read, complete and upload
-- ---------------------------------------------------------------------------

create table public.compliance_items (
  id            uuid primary key default gen_random_uuid(),
  org_id        uuid not null default public.default_org_id() references public.organisation (id),
  kind          text not null check (kind in ('read', 'training', 'upload')),
  title         text not null check (length(trim(title)) between 1 and 200),
  description   text not null default '',
  body          text not null default '',
  link_url      text not null default '' check (link_url = '' or link_url ~* '^https?://'),
  file_path     text,
  file_name     text,
  version       int not null default 1,
  needs_expiry  boolean not null default false,
  active        boolean not null default true,
  applies_roles public.app_role[] not null default '{}',
  applies_teams uuid[] not null default '{}',
  sort_order    int not null default 0,
  created_by    uuid references public.profiles (id) default auth.uid(),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create table public.compliance_records (
  id          bigint generated always as identity primary key,
  item_id     uuid not null references public.compliance_items (id) on delete cascade,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  version     int not null,
  status      text not null check (status in ('done', 'submitted', 'accepted', 'rejected')),
  file_path   text,
  file_name   text,
  expires_on  date,
  review_note text not null default '',
  reviewed_by uuid references public.profiles (id),
  reviewed_at timestamptz,
  created_at  timestamptz not null default now()
);

create index compliance_records_user_idx on public.compliance_records (user_id, item_id, created_at desc);

-- Expiry reminders already sent.
create table public.compliance_alerts (
  record_id bigint not null references public.compliance_records (id) on delete cascade,
  step      text not null check (step in ('expiring', 'expired')),
  primary key (record_id, step)
);

alter table public.compliance_items enable row level security;
alter table public.compliance_records enable row level security;
alter table public.compliance_alerts enable row level security;

create policy "members read onboarding items" on public.compliance_items
  for select to authenticated using (public.is_member());
create policy "compliance managers add items" on public.compliance_items
  for insert to authenticated with check (public.can_manage_compliance());
create policy "compliance managers change items" on public.compliance_items
  for update to authenticated using (public.can_manage_compliance()) with check (public.can_manage_compliance());
-- Items are switched off, never deleted, so the history stays.
revoke delete, truncate on public.compliance_items from anon, authenticated;

create policy "read your own records, or as compliance manager" on public.compliance_records
  for select to authenticated using (user_id = auth.uid() or public.can_manage_compliance());
revoke insert, update, delete, truncate on public.compliance_records from anon, authenticated;
revoke all on public.compliance_alerts from anon, authenticated;

create function public.compliance_items_touch()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger compliance_items_touch
  before update on public.compliance_items
  for each row execute function public.compliance_items_touch();

-- Does an item apply to someone with this role and these teams?
create function public.compliance_applies(p_item public.compliance_items, p_role public.app_role, p_teams uuid[])
returns boolean
language sql
stable
set search_path = ''
as $$
  select p_item.active
     and (cardinality(p_item.applies_roles) = 0 or p_role = any (p_item.applies_roles))
     and (cardinality(p_item.applies_teams) = 0 or p_item.applies_teams && coalesce(p_teams, '{}'))
$$;

-- Each item's state for one person (optionally as if they had another role
-- and teams). States: done, submitted, accepted, expiring (all count as done);
-- todo, update (a newer version to confirm), rejected, expired.
create function public.compliance_status(p_user uuid, p_role public.app_role default null, p_teams uuid[] default null)
returns table (item_id uuid, kind text, title text, state text, record_id bigint, expires_on date, note text, sort_order int)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_role public.app_role;
  v_teams uuid[];
  v_warn int := coalesce((select (value #>> '{}')::int from public.app_settings where key = 'compliance.expiry_warning_days'), 30);
  v_today date := public.local_today();
begin
  if not (p_user = auth.uid() or public.can_manage_compliance() or public.can_manage_people()
          or public.has_role(array['manager']::public.app_role[]) or public.leads_user(p_user)
          or auth.uid() is null) then
    return;
  end if;
  select coalesce(p_role, p.role) into v_role from public.profiles p where p.id = p_user;
  v_teams := coalesce(p_teams, (select array_agg(team_id) from public.team_members where user_id = p_user), '{}');

  return query
  select i.id, i.kind, i.title,
         case
           when r.id is null then 'todo'
           when i.kind <> 'upload' then case when r.version >= i.version then 'done' else 'update' end
           when r.status = 'rejected' then 'rejected'
           when r.expires_on is not null and r.expires_on < v_today then 'expired'
           when r.expires_on is not null and r.expires_on <= v_today + v_warn then 'expiring'
           else r.status
         end,
         r.id, r.expires_on, coalesce(r.review_note, ''), i.sort_order
    from public.compliance_items i
    left join lateral (
      select * from public.compliance_records cr
       where cr.item_id = i.id and cr.user_id = p_user
       order by cr.created_at desc, cr.id desc limit 1
    ) r on true
   where public.compliance_applies(i, v_role, v_teams)
   order by array_position(array['read', 'training', 'upload'], i.kind), i.sort_order, i.title;
end;
$$;

-- What's still missing (titles), for a role someone might be given.
create function public.onboarding_missing(p_user uuid, p_role public.app_role default null, p_teams uuid[] default null)
returns text[]
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(array_agg(s.title order by array_position(array['read', 'training', 'upload'], s.kind), s.sort_order, s.title), '{}')
    from public.compliance_status(p_user, p_role, p_teams) s
   where s.state not in ('done', 'submitted', 'accepted', 'expiring')
$$;

-- When everything is done: note it, tell the staff admins, and finish the
-- "Finish onboarding" task if there is one.
create function public.check_onboarding_complete(p_user uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  me public.profiles;
  v_admin uuid;
  v_task uuid;
begin
  select * into me from public.profiles where id = p_user;
  if me.id is null or cardinality(public.onboarding_missing(p_user)) > 0 then
    return;
  end if;
  if me.onboarded_at is null then
    update public.profiles set onboarded_at = now() where id = p_user;
    for v_admin in select a from public.people_admins() a loop
      perform public.notify(v_admin, 'onboarded',
        format('%s has finished onboarding', coalesce(nullif(me.full_name, ''), me.email)),
        case when me.role = 'new_starter' then 'You can now give them their role and team.' else '' end,
        '/compliance?tab=progress');
    end loop;
  end if;
  for v_task in
    select r.task_id from public.people_change_requests r
      join public.tasks t on t.id = r.task_id
     where r.user_id = p_user and r.kind = 'conditional' and t.status not in ('completed', 'closed')
  loop
    update public.tasks set status = 'completed', completed_at = now(), updated_at = now() where id = v_task;
    insert into public.task_events (task_id, actor_id, type, from_value, to_value, comment)
    values (v_task, null, 'status_changed', null, 'completed', 'Onboarding finished');
  end loop;
end;
$$;

create function public.confirm_compliance_item(p_item_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  i public.compliance_items;
begin
  if not public.is_member() then
    raise exception 'Please sign in again';
  end if;
  select * into i from public.compliance_items where id = p_item_id and active;
  if i.id is null or i.kind = 'upload' then
    raise exception 'Choose something to read or a training';
  end if;
  insert into public.compliance_records (item_id, user_id, version, status)
  values (i.id, auth.uid(), i.version, 'done');
  perform public.check_onboarding_complete(auth.uid());
end;
$$;

create function public.submit_compliance_upload(p_item_id uuid, p_path text, p_name text, p_expires date default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  i public.compliance_items;
  me public.profiles;
  v_admin uuid;
begin
  if not public.is_member() then
    raise exception 'Please sign in again';
  end if;
  select * into i from public.compliance_items where id = p_item_id and active and kind = 'upload';
  if i.id is null then
    raise exception 'Uploads for this document are switched off';
  end if;
  if p_path is null or p_path not like auth.uid()::text || '/%' then
    raise exception 'Upload the file again';
  end if;
  if i.needs_expiry and p_expires is null then
    raise exception 'Enter the expiry date';
  end if;
  if p_expires is not null and p_expires < public.local_today() then
    raise exception 'This document has already expired. Upload a current one.';
  end if;
  insert into public.compliance_records (item_id, user_id, version, status, file_path, file_name, expires_on)
  values (i.id, auth.uid(), i.version, 'submitted', p_path, left(coalesce(p_name, ''), 200), p_expires);

  select * into me from public.profiles where id = auth.uid();
  for v_admin in select a from public.people_admins() a loop
    continue when v_admin = auth.uid();
    perform public.notify(v_admin, 'upload_submitted',
      format('%s uploaded %s', coalesce(nullif(me.full_name, ''), me.email), i.title),
      'Check it on the Compliance page.', '/compliance/people/' || auth.uid());
  end loop;
  perform public.check_onboarding_complete(auth.uid());
end;
$$;

create function public.review_compliance_upload(p_record_id bigint, p_accept boolean, p_note text default '')
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.compliance_records;
  v_title text;
begin
  if not public.can_manage_compliance() then
    raise exception 'Only people who manage Compliance can check uploads';
  end if;
  select * into r from public.compliance_records where id = p_record_id for update;
  if r.id is null or r.status not in ('submitted', 'accepted', 'rejected') then
    raise exception 'Upload not found';
  end if;
  if r.user_id = auth.uid() then
    raise exception 'Someone else needs to check your own documents';
  end if;
  if not p_accept and coalesce(trim(p_note), '') = '' then
    raise exception 'Say what''s wrong, so they know what to upload';
  end if;
  update public.compliance_records
     set status = case when p_accept then 'accepted' else 'rejected' end,
         review_note = coalesce(trim(p_note), ''), reviewed_by = auth.uid(), reviewed_at = now()
   where id = r.id;
  select title into v_title from public.compliance_items where id = r.item_id;
  if not p_accept then
    perform public.notify(r.user_id, 'upload_rejected', format('Please upload %s again', v_title),
      trim(p_note), '/onboarding', true);
  end if;
  perform public.write_audit(case when p_accept then 'upload_accepted' else 'upload_rejected' end,
    'compliance_record', r.id::text, jsonb_build_object('item', v_title, 'note', p_note));
end;
$$;

-- New items (or a new version to confirm) go to everyone they apply to.
create function public.compliance_item_announce()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  p record;
  v_word text := case new.kind when 'read' then 'Please read and confirm' when 'training' then 'New training' else 'Please upload' end;
begin
  if not new.active then
    return new;
  end if;
  if tg_op = 'UPDATE' and new.version = old.version and old.active then
    return new;
  end if;
  for p in
    select pr.id, pr.role, (select array_agg(team_id) from public.team_members where user_id = pr.id) teams
      from public.profiles pr
     where pr.active and pr.role <> 'system_admin'
  loop
    if public.compliance_applies(new, p.role, p.teams) then
      perform public.notify(p.id, 'onboarding_item',
        case when tg_op = 'UPDATE' and new.version > old.version then format('Updated: %s', new.title) else format('%s: %s', v_word, new.title) end,
        'It''s on your My onboarding page.', '/onboarding');
    end if;
  end loop;
  return new;
end;
$$;

create trigger compliance_items_announce
  after insert or update on public.compliance_items
  for each row execute function public.compliance_item_announce();

-- Expiring and expired documents (called by the hourly timer).
create function public.run_compliance_alerts()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  s record;
  v_n int := 0;
  v_admin uuid;
  v_name text;
begin
  for s in
    select p.id user_id, coalesce(nullif(p.full_name, ''), p.email) person, st.title, st.state, st.record_id, st.expires_on
      from public.profiles p
      cross join lateral public.compliance_status(p.id) st
     where p.active and p.role <> 'system_admin' and st.state in ('expiring', 'expired') and st.record_id is not null
  loop
    insert into public.compliance_alerts (record_id, step) values (s.record_id, s.state) on conflict do nothing;
    continue when not found;
    v_n := v_n + 1;
    -- Bell before it expires; bell and email once it has.
    perform public.notify(s.user_id, 'document_' || s.state,
      case when s.state = 'expired' then format('%s has expired', s.title) else format('%s expires soon', s.title) end,
      format('Expiry date: %s. Upload a new one on My onboarding.', to_char(s.expires_on, 'FMDD Mon YYYY')),
      '/onboarding', s.state = 'expired');
    for v_admin in select a from public.people_admins() a loop
      continue when v_admin = s.user_id;
      perform public.notify(v_admin, 'document_' || s.state,
        format('%s: %s %s', s.person, s.title, case when s.state = 'expired' then 'has expired' else 'expires soon' end),
        format('Expiry date: %s.', to_char(s.expires_on, 'FMDD Mon YYYY')),
        '/compliance/people/' || s.user_id, s.state = 'expired');
    end loop;
  end loop;
  return jsonb_build_object('document_alerts', v_n);
end;
$$;

-- ---------------------------------------------------------------------------
-- Conditional roles
-- ---------------------------------------------------------------------------

alter table public.people_change_requests add column task_id uuid references public.tasks (id);
alter table public.people_change_requests drop constraint people_change_requests_kind_check;
alter table public.people_change_requests drop constraint people_change_requests_target_check;
alter table public.people_change_requests
  add constraint people_change_requests_kind_check check (kind in ('role', 'team', 'conditional')),
  add constraint people_change_requests_target_check check (
    (kind in ('role', 'conditional') and user_id is not null) or (kind = 'team' and team_id is not null));

-- Gives the role and teams and sets the "Finish onboarding" task (as the
-- approving manager).
create function public.apply_conditional_role(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.people_change_requests;
  v_team uuid;
  v_task uuid;
  v_missing text;
begin
  select * into r from public.people_change_requests where id = p_request_id;
  if (select role from public.profiles where id = r.user_id) <> 'new_starter' then
    raise exception 'They already have a role';
  end if;
  perform set_config('app.conditional_role', 'on', true);
  if r.to_value ->> 'title' is not null then
    update public.profiles set job_title_id = (r.to_value ->> 'title')::uuid where id = r.user_id;
  else
    update public.profiles set role = (r.to_value ->> 'role')::public.app_role where id = r.user_id;
  end if;
  perform set_config('app.conditional_role', 'off', true);

  if (r.to_value ->> 'role') in ('support_worker', 'team_leader') then
    for v_team in select x::uuid from jsonb_array_elements_text(coalesce(r.to_value -> 'teams', '[]')) x loop
      insert into public.team_members (team_id, user_id) values (v_team, r.user_id) on conflict do nothing;
    end loop;
  end if;

  select string_agg('• ' || x, E'\n') into v_missing from jsonb_array_elements_text(r.to_value -> 'missing') x;
  v_task := public.create_task(
    'Finish onboarding',
    (select id from public.registries where is_default and kind = 'tasks' and active order by sort_order limit 1),
    r.user_id,
    format(E'Your role was given on condition that you finish onboarding by %s.\n\nStill to do:\n%s\n\nReason: %s',
           to_char((r.to_value ->> 'deadline')::date, 'FMDD Mon YYYY'), coalesce(v_missing, ''), r.reason),
    'medium',
    (r.to_value ->> 'deadline')::date);
  update public.people_change_requests set task_id = v_task where id = r.id;
end;
$$;

-- Managers give a conditional role straight away; staff admins ask a manager.
create function public.give_conditional_role(
  p_user_id uuid, p_role public.app_role, p_title_id uuid, p_teams uuid[], p_reason text, p_deadline date
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  me public.profiles;
  v_role public.app_role := p_role;
  v_teams uuid[] := coalesce(p_teams, '{}');
  v_missing text[];
  v_id uuid;
  v_name text;
  v_manager uuid;
  v_to jsonb;
begin
  select * into me from public.profiles where id = auth.uid();
  if not public.can_manage_people() then
    raise exception 'Only managers and staff admins give roles';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'You cannot change your own role';
  end if;
  if (select role from public.profiles where id = p_user_id and active) is distinct from 'new_starter' then
    raise exception 'Conditional roles are for new starters';
  end if;
  if p_title_id is not null then
    select access_level into v_role from public.job_titles where id = p_title_id and active;
    if v_role is null then raise exception 'Choose a role that is in use'; end if;
  end if;
  if v_role in ('new_starter', 'system_admin') or not public.can_manage_role(v_role) then
    raise exception 'Choose a role you''re allowed to give';
  end if;
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'Give a reason for the conditional role';
  end if;
  if p_deadline is null or p_deadline < public.local_today() or p_deadline > public.local_today() + 180 then
    raise exception 'Choose a deadline in the next six months';
  end if;
  if v_role not in ('support_worker', 'team_leader') then
    v_teams := '{}';
  elsif v_role = 'team_leader' and cardinality(v_teams) > 1 then
    raise exception 'A team leader can be in one team only';
  end if;
  if exists (select 1 from unnest(v_teams) t where not exists (select 1 from public.teams where id = t and active and not is_core)) then
    raise exception 'Choose teams that are in use';
  end if;

  v_missing := public.onboarding_missing(p_user_id, v_role, v_teams);
  if cardinality(v_missing) = 0 then
    raise exception 'Their onboarding is finished, so give the role in the usual way';
  end if;

  v_to := jsonb_build_object('role', v_role, 'title', p_title_id, 'teams', to_jsonb(v_teams),
                             'deadline', p_deadline, 'missing', to_jsonb(v_missing));

  if me.role in ('manager', 'system_admin') then
    insert into public.people_change_requests (kind, user_id, from_value, to_value, reason, requested_by,
                                               status, decided_by, decided_at, requester_seen_at)
    values ('conditional', p_user_id, jsonb_build_object('role', 'new_starter'), v_to, trim(p_reason), auth.uid(),
            'approved', auth.uid(), now(), now())
    returning id into v_id;
    perform public.apply_conditional_role(v_id);
    perform public.write_audit('conditional_role_given', 'profile', p_user_id::text, v_to);
    return v_id;
  end if;

  v_id := public.add_change_request('conditional', p_user_id, null, jsonb_build_object('role', 'new_starter'), v_to, p_reason);
  select coalesce(nullif(full_name, ''), email) into v_name from public.profiles where id = p_user_id;
  for v_manager in select id from public.profiles where active and role = 'manager' loop
    perform public.notify(v_manager, 'approval_needed',
      format('Conditional role for %s needs your approval', v_name),
      format('%s asks to give them a role before onboarding is finished (deadline %s).',
             coalesce(nullif(me.full_name, ''), me.email), to_char(p_deadline, 'FMDD Mon YYYY')),
      '/settings/staff', true);
  end loop;
  return v_id;
end;
$$;

revoke execute on function public.notify(uuid, text, text, text, text, boolean) from public, anon, authenticated;
revoke execute on function public.people_admins() from public, anon, authenticated;
revoke execute on function public.check_onboarding_complete(uuid) from public, anon, authenticated;
revoke execute on function public.apply_conditional_role(uuid) from public, anon, authenticated;
revoke execute on function public.run_compliance_alerts() from public, anon, authenticated;
grant execute on function public.run_compliance_alerts() to service_role;
revoke execute on function public.mark_joined() from public, anon;
revoke execute on function public.confirm_compliance_item(uuid) from public, anon;
revoke execute on function public.submit_compliance_upload(uuid, text, text, date) from public, anon;
revoke execute on function public.review_compliance_upload(bigint, boolean, text) from public, anon;
revoke execute on function public.give_conditional_role(uuid, public.app_role, uuid, uuid[], text, date) from public, anon;
revoke execute on function public.compliance_status(uuid, public.app_role, uuid[]) from public, anon;
revoke execute on function public.onboarding_missing(uuid, public.app_role, uuid[]) from public, anon;
revoke execute on function public.mark_notification_seen(bigint) from public, anon;
revoke execute on function public.mark_all_notifications_seen() from public, anon;

-- ---------------------------------------------------------------------------
-- Existing rules, updated
-- ---------------------------------------------------------------------------

create or replace function public.guard_profile_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor uuid := auth.uid();
begin
  if new.id <> old.id or new.email <> old.email or new.org_id <> old.org_id then
    raise exception 'This field cannot be changed here';
  end if;

  if actor is not null then
    if new.role is distinct from old.role
       or new.team_id is distinct from old.team_id
       or new.active is distinct from old.active then

      if not public.can_manage_people() then
        raise exception 'Only managers and admins can change roles, teams or access';
      end if;

      -- Nobody promotes, demotes or deactivates themselves.
      if new.id = actor and (new.role is distinct from old.role or not new.active) then
        raise exception 'You cannot change your own role or deactivate yourself';
      end if;

      if new.id <> actor and (not public.can_manage_role(old.role) or not public.can_manage_role(new.role)) then
        raise exception 'Only a system admin can manage system admins';
      end if;

      -- A new starter gets a role once onboarding is finished (or as a
      -- conditional role, which sets app.conditional_role while it applies).
      if old.role = 'new_starter' and new.role <> 'new_starter'
         and coalesce(current_setting('app.conditional_role', true), '') <> 'on'
         and cardinality(public.onboarding_missing(new.id, new.role, null)) > 0 then
        raise exception 'They haven''t finished onboarding yet. Give a conditional role with a deadline instead.';
      end if;

      -- A staff admin's role changes need a manager's approval first.
      -- (Managers apply approved requests as themselves, so this never blocks them.)
      -- A new starter's first role is the exception: staff admins set it straight away.
      if new.role is distinct from old.role and public.my_role() = 'staff_admin'
         and public.rule_on('people.staff_admin_role_approval')
         and (old.role <> 'new_starter' or public.rule_on('people.first_role_approval')) then
        raise exception 'Role changes by a staff admin need a manager''s approval. Send it as a request.';
      end if;
      if new.team_id is distinct from old.team_id and public.my_role() = 'staff_admin'
         and public.rule_on('people.staff_admin_team_approval') then
        raise exception 'Team changes by a staff admin need a manager''s approval. Send it as a request.';
      end if;
    end if;
  end if;

  if old.role = 'system_admin' and old.active
     and (new.role <> 'system_admin' or not new.active)
     and not exists (
       select 1 from public.profiles
        where role = 'system_admin' and active and id <> old.id
     ) then
    raise exception 'There must always be at least one active system admin';
  end if;

  if new.active and not old.active then
    new.deactivated_at := null;
  elsif not new.active and old.active then
    new.deactivated_at := now();
  end if;

  if new.role is distinct from old.role then
    perform public.write_audit('role_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.role, 'to', new.role));
  end if;
  if new.active is distinct from old.active then
    perform public.write_audit(
      case when new.active then 'reactivated' else 'deactivated' end,
      'profile', new.id::text, '{}'::jsonb);
  end if;
  if new.team_id is distinct from old.team_id then
    perform public.write_audit('team_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.team_id, 'to', new.team_id));
  end if;

  return new;
end;
$$;

create or replace function public.guard_invitation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.can_invite() then
    raise exception 'You''re not set up to send invites. Ask a staff admin.';
  end if;
  -- People who can invite but don't manage staff send general invites only.
  if auth.uid() is not null and not public.can_manage_people() and (new.role <> 'new_starter' or new.team_id is not null) then
    raise exception 'Invite them as a new starter; a staff admin sets their role later';
  end if;
  if auth.uid() is not null and public.can_manage_people() and not public.can_manage_role(new.role) then
    raise exception 'Only a system admin can invite a system admin';
  end if;
  if auth.uid() is not null and public.rule_on('people.general_invites_only')
     and new.role <> 'new_starter' and public.my_role() <> 'system_admin' then
    raise exception 'Invites are general: they join as a new starter and you set their role afterwards';
  end if;
  if auth.uid() is not null and new.team_id is not null and public.my_role() = 'staff_admin'
     and public.rule_on('people.staff_admin_team_approval') then
    raise exception 'Add them to a team once they''ve joined; a manager approves team changes';
  end if;
  new.email := lower(trim(new.email));
  if tg_op = 'INSERT' then
    new.invited_by := coalesce(new.invited_by, auth.uid());
    perform public.write_audit('invited', 'invitation', new.email,
      jsonb_build_object('role', new.role));
  end if;
  return new;
end;
$$;

create policy "inviters create general invitations" on public.invitations
  for insert to authenticated with check (public.can_invite());

create or replace function public.decide_change_request(p_request_id uuid, p_approve boolean, p_note text default '')
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.people_change_requests;
  v_members uuid[];
begin
  if not public.has_role(array['manager', 'system_admin']::public.app_role[]) then
    raise exception 'Only managers can approve these changes';
  end if;
  select * into r from public.people_change_requests where id = p_request_id for update;
  if r.id is null or r.status <> 'pending' then
    raise exception 'This request has already been dealt with';
  end if;
  if r.user_id = auth.uid() then
    raise exception 'You cannot approve a change about yourself';
  end if;

  -- Applied as the approving manager, so all the usual checks still run.
  if p_approve then
    if r.kind = 'conditional' then
      perform public.apply_conditional_role(r.id);
    elsif r.kind = 'role' then
      if (select role::text from public.profiles where id = r.user_id) <> r.from_value ->> 'role' then
        raise exception 'Their role has changed since the request was made. Ask for a new request.';
      end if;
      if r.to_value ->> 'title' is not null then
        update public.profiles set job_title_id = (r.to_value ->> 'title')::uuid where id = r.user_id;
      else
        update public.profiles set role = (r.to_value ->> 'role')::public.app_role, job_title_id = null where id = r.user_id;
      end if;
    else
      select coalesce(array_agg(x::uuid), '{}') into v_members from jsonb_array_elements_text(r.to_value -> 'members') x;
      perform public.set_team(r.team_id, v_members, (r.to_value ->> 'leader')::uuid);
    end if;
  end if;

  update public.people_change_requests
     set status = case when p_approve then 'approved' else 'declined' end,
         decided_by = auth.uid(), decided_at = now(), decision_note = coalesce(trim(p_note), '')
   where id = p_request_id;
  perform public.write_audit(r.kind || case when p_approve then '_change_approved' else '_change_declined' end,
    case when r.kind = 'team' then 'team' else 'profile' end, coalesce(r.user_id, r.team_id)::text,
    jsonb_build_object('from', r.from_value, 'to', r.to_value));
end;
$$;

create or replace function public.my_request_updates()
returns table (
  request_id uuid,
  kind text,
  status text,
  subject text,
  change text,
  decided_by_name text,
  decided_at timestamptz,
  note text
)
language sql
stable
security definer
set search_path = ''
as $$
  select r.id,
         r.kind,
         r.status,
         case when r.kind = 'team' then coalesce(t.name, 'A team')
              else coalesce(nullif(p.full_name, ''), p.email, 'Someone') end,
         case when r.kind in ('role', 'conditional')
              then coalesce((select j.name from public.job_titles j where j.id = (r.to_value ->> 'title')::uuid),
                            initcap(replace(r.to_value ->> 'role', '_', ' ')))
              else 'who is in the team' end,
         -- System admins stay hidden from other staff.
         case when d.role = 'system_admin' then 'Admin' else coalesce(nullif(d.full_name, ''), d.email, 'A manager') end,
         r.decided_at,
         r.decision_note
    from public.people_change_requests r
    left join public.profiles p on p.id = r.user_id
    left join public.teams t on t.id = r.team_id
    left join public.profiles d on d.id = r.decided_by
   where public.is_member()
     and r.requested_by = auth.uid()
     and r.status in ('approved', 'declined')
     and r.requester_seen_at is null
   order by r.decided_at desc
$$;

-- ---------------------------------------------------------------------------
-- Files (only where Supabase Storage is available)
-- ---------------------------------------------------------------------------
-- compliance-files:   what people upload, in a folder named by their id.
--                     The person and Compliance managers can open them.
-- compliance-library: policy documents and training files, for all staff.

do $storage$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  insert into storage.buckets (id, name, public, file_size_limit)
  values ('compliance-files', 'compliance-files', false, 10485760),
         ('compliance-library', 'compliance-library', false, 26214400)
  on conflict (id) do nothing;

  create policy "people upload their own documents" on storage.objects
    for insert to authenticated
    with check (bucket_id = 'compliance-files' and (storage.foldername(name))[1] = auth.uid()::text and public.is_member());
  create policy "people and compliance managers read documents" on storage.objects
    for select to authenticated
    using (bucket_id = 'compliance-files'
           and ((storage.foldername(name))[1] = auth.uid()::text or public.can_manage_compliance()));
  create policy "staff read the library" on storage.objects
    for select to authenticated using (bucket_id = 'compliance-library' and public.is_member());
  create policy "compliance managers add to the library" on storage.objects
    for insert to authenticated with check (bucket_id = 'compliance-library' and public.can_manage_compliance());
end;
$storage$;

$m018$;
  insert into public.install_log (name) values ('20261111000001_onboarding_and_compliance.sql');
end;
$part$;

-- ====================================================================
-- 20261112000001_staff_admin_register_overview.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261112000001_staff_admin_register_overview.sql') then
    return;
  end if;
  execute $m019$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Staff admins (people management) see each register's open tasks as an
-- overview: title, description, due date and who it's assigned to. They
-- can't open task details or custom fields, and they no longer add or set
-- up registers: that's managers (their own registers) and the system admin.

create or replace function public.manages_registry(p_registry_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_system_admin() or (
    public.has_role(array['manager']::public.app_role[])
    and exists (select 1 from public.registry_managers
                 where registry_id = p_registry_id and user_id = auth.uid())
  )
$$;

drop policy "managers create registries" on public.registries;
create policy "managers create registries" on public.registries
  for insert to authenticated
  with check (public.has_role(array['manager', 'system_admin']::public.app_role[]));

-- Who sees the overview: staff admins (and managers and the system admin,
-- who can see the tasks anyway).
create function public.sees_register_overview()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.has_role(array['staff_admin', 'manager', 'system_admin']::public.app_role[])
$$;

-- Open tasks per register.
create function public.register_open_counts()
returns table (registry_id uuid, open_tasks bigint)
language sql
stable
security definer
set search_path = ''
as $$
  select t.registry_id, count(*)
    from public.tasks t
   where public.sees_register_overview()
     and t.parent_task_id is null
     and t.status not in ('completed', 'closed')
   group by t.registry_id
$$;

-- A register's open tasks, without custom fields or history.
create function public.register_overview(p_registry_id uuid)
returns table (
  ref text,
  title text,
  description text,
  priority public.task_priority,
  status public.task_status,
  due_date date,
  assigned_to uuid,
  assigned_name text
)
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(r.prefix, 'T') || '-' || lpad(t.ref_number::text, 4, '0'),
         t.title, t.description, t.priority, t.status, t.due_date, t.assigned_to,
         case when p.role = 'system_admin' then 'Admin' else coalesce(nullif(p.full_name, ''), p.email) end
    from public.tasks t
    join public.registries r on r.id = t.registry_id
    join public.profiles p on p.id = t.assigned_to
   where public.sees_register_overview()
     and t.registry_id = p_registry_id
     and t.parent_task_id is null
     and t.status not in ('completed', 'closed')
   order by t.due_date nulls last, t.ref_number
$$;

revoke execute on function public.register_open_counts() from public, anon;
revoke execute on function public.register_overview(uuid) from public, anon;
grant execute on function public.register_open_counts() to authenticated;
grant execute on function public.register_overview(uuid) to authenticated;

$m019$;
  insert into public.install_log (name) values ('20261112000001_staff_admin_register_overview.sql');
end;
$part$;

-- ====================================================================
-- 20261112000002_scoreboard.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261112000002_scoreboard.sql') then
    return;
  end if;
  execute $m020$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Scoreboard: how each person is going with their tasks, so staff admins
-- can see who needs support. The system admin chooses who else can see it;
-- team leaders (if allowed) see only the team they lead.

insert into public.app_settings (key, value, label, description, is_public) values
  ('people.scoreboard_roles', '["staff_admin", "manager"]', 'Who can see the scoreboard',
   'Besides the system admin. Team leaders, if ticked, see only the team they lead.', false),
  ('people.stuck_days', '7', 'A task is stuck after (days without activity)',
   'On the scoreboard, an open task with nothing done on it for this many days counts as stuck.', false)
on conflict (key) do nothing;

create function public.can_see_scoreboard()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.mfa_ok() and (public.my_role() = 'system_admin'
         or public.my_role() = any (public.setting_roles('people.scoreboard_roles')))
$$;

create function public.staff_scoreboard(p_days int default 30)
returns table (
  user_id uuid,
  full_name text,
  role public.app_role,
  open_tasks int,
  overdue int,
  escalated int,
  stuck int,
  completed int,
  completed_on_time int,
  completed_with_due int,
  avg_days_late numeric,
  oldest_overdue date,
  onboarding_missing int
)
language sql
stable
security definer
set search_path = ''
as $$
  with params as (
    select public.local_today() as today,
           greatest(coalesce(p_days, 30), 1) as days,
           coalesce((select (value #>> '{}')::int from public.app_settings where key = 'people.stuck_days'), 7) as stuck_days
  ),
  people as (
    select p.* from public.profiles p
     where public.can_see_scoreboard()
       and p.active and p.role not in ('system_admin', 'new_starter')
       and p.id <> auth.uid()
       and (public.my_role() <> 'team_leader' or public.leads_user(p.id))
  ),
  last_activity as (
    select e.task_id, max(e.created_at) as at from public.task_events e group by e.task_id
  ),
  t as (
    select tk.*, coalesce(la.at, tk.updated_at) as last_at
      from public.tasks tk
      left join last_activity la on la.task_id = tk.id
     where tk.assigned_to in (select id from people)
  )
  select p.id,
         coalesce(nullif(p.full_name, ''), p.email),
         p.role,
         count(*) filter (where t.status not in ('completed', 'closed'))::int,
         count(*) filter (where t.status not in ('completed', 'closed') and t.due_date < pr.today)::int,
         count(*) filter (where t.status = 'escalated')::int,
         count(*) filter (where t.status not in ('completed', 'closed')
                            and t.last_at < now() - make_interval(days => pr.stuck_days))::int,
         count(*) filter (where t.completed_at >= now() - make_interval(days => pr.days))::int,
         count(*) filter (where t.completed_at >= now() - make_interval(days => pr.days)
                            and t.due_date is not null and t.completed_at::date <= t.due_date)::int,
         count(*) filter (where t.completed_at >= now() - make_interval(days => pr.days) and t.due_date is not null)::int,
         round(avg(t.completed_at::date - t.due_date) filter (where t.completed_at >= now() - make_interval(days => pr.days)
                                                               and t.due_date is not null and t.completed_at::date > t.due_date), 1),
         min(t.due_date) filter (where t.status not in ('completed', 'closed') and t.due_date < pr.today),
         cardinality(public.onboarding_missing(p.id))
    from people p
    cross join params pr
    left join t on t.assigned_to = p.id
   group by p.id, p.full_name, p.email, p.role
$$;

revoke execute on function public.staff_scoreboard(int) from public, anon;
grant execute on function public.staff_scoreboard(int) to authenticated;

$m020$;
  insert into public.install_log (name) values ('20261112000002_scoreboard.sql');
end;
$part$;

-- ====================================================================
-- 20261113000001_mfa_methods.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261113000001_mfa_methods.sql') then
    return;
  end if;
  execute $m021$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Which two-factor login methods people can use. The authenticator app is on;
-- text message (SMS) codes are off until an SMS provider is set up in
-- Supabase (it costs per message). Public so the two-factor page can read
-- them before the second step is done; they hold no secrets.

insert into public.app_settings (key, value, label, description, is_public) values
  ('security.mfa_app_enabled', 'true', 'Two-factor: authenticator app',
   'People can use an app like Google or Microsoft Authenticator. Free and the most secure.', true),
  ('security.mfa_sms_enabled', 'false', 'Two-factor: text message (SMS) code',
   'People can get a code by text message. Needs an SMS provider set up in Supabase first (it costs per message).', true)
on conflict (key) do nothing;

$m021$;
  insert into public.install_log (name) values ('20261113000001_mfa_methods.sql');
end;
$part$;

-- ====================================================================
-- 20261114000001_task_workflow.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261114000001_task_workflow.sql') then
    return;
  end if;
  execute $m022$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Working on tasks (Milestone 3): status changes, approvals, comments,
-- escalating, reassigning, taking over and attachments. Everything goes
-- through these functions, is written to the task's history, and tells the
-- right people (bell; email only where action is needed).
--   assigned → in progress → completed → closed
--   In registers that need approval, "complete" goes to awaiting approval;
--   a manager of the register approves it or sends it back with a reason.

-- Approvers: the register's managers (or every manager if it has none) and
-- the system admin, but never the person who did the work.
create function public.can_approve_task(p_task_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and exists (
    select 1 from public.tasks t
     where t.id = p_task_id
       and t.assigned_to <> auth.uid()
       and (public.is_system_admin()
            or (public.has_role(array['manager']::public.app_role[])
                and (exists (select 1 from public.registry_managers rm where rm.registry_id = t.registry_id and rm.user_id = auth.uid())
                     or not exists (select 1 from public.registry_managers rm join public.profiles p on p.id = rm.user_id and p.active
                                     where rm.registry_id = t.registry_id))))
  )
$$;

-- Everyone involved in a task (to tell them about changes).
create function public.task_people(p_task_id uuid)
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select assigned_to from public.tasks where id = p_task_id
  union select created_by from public.tasks where id = p_task_id
  union select user_id from public.task_helpers where task_id = p_task_id
$$;

create function public.task_label(p_task_id uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(r.prefix, 'T') || '-' || lpad(t.ref_number::text, 4, '0') || ' ' || t.title
    from public.tasks t join public.registries r on r.id = t.registry_id where t.id = p_task_id
$$;

create function public.my_name()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select case when role = 'system_admin' then 'Admin' else coalesce(nullif(full_name, ''), email) end
    from public.profiles where id = auth.uid()
$$;

-- Tell everyone on the task except whoever did it.
create function public.notify_task_people(p_task_id uuid, p_kind text, p_title text, p_body text, p_email boolean default false)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid;
begin
  for v_user in select u from public.task_people(p_task_id) u loop
    continue when v_user = auth.uid();
    perform public.notify(v_user, p_kind, p_title, p_body, '/tasks/' || p_task_id, p_email);
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- Status
-- ---------------------------------------------------------------------------

create function public.set_task_status(p_task_id uuid, p_status public.task_status, p_note text default '')
returns public.task_status
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.tasks;
  v_requires boolean;
  v_to public.task_status := p_status;
  v_note text := coalesce(trim(p_note), '');
  v_mine boolean;
  v_editor boolean;
  v_approver boolean;
  v_label text;
  v_user uuid;
begin
  if not public.is_member() then
    raise exception 'Please sign in again';
  end if;
  select * into t from public.tasks where id = p_task_id for update;
  if t.id is null or not public.can_see_task(p_task_id) then
    raise exception 'Task not found';
  end if;
  select requires_approval into v_requires from public.registries where id = t.registry_id;
  v_mine := t.assigned_to = auth.uid();
  v_editor := public.can_edit_task(p_task_id);
  v_approver := public.can_approve_task(p_task_id);
  v_label := public.task_label(p_task_id);

  if p_status = t.status then
    raise exception 'The task is already %', replace(t.status::text, '_', ' ');
  end if;

  if p_status = 'in_progress' then
    if t.status = 'assigned' and v_editor then
      null;
    elsif t.status = 'awaiting_approval' and v_approver then
      if v_note = '' then raise exception 'Say what still needs doing, so they know'; end if;
    elsif t.status = 'escalated' and v_editor and not v_mine then
      null; -- the escalation has been dealt with
    elsif t.status in ('completed', 'closed') and v_editor and not v_mine then
      if v_note = '' then raise exception 'Give a reason for reopening the task'; end if;
    else
      raise exception 'You can''t make this change';
    end if;

  elsif p_status = 'completed' then
    if t.status = 'awaiting_approval' then
      if not v_approver then raise exception 'A manager of this register approves it'; end if;
    elsif t.status in ('assigned', 'in_progress', 'escalated') and v_editor then
      if exists (select 1 from public.tasks a where a.parent_task_id = t.id and a.status not in ('completed', 'closed')) then
        raise exception 'Finish or close its follow-up actions first';
      end if;
      if v_requires and not v_approver then
        v_to := 'awaiting_approval';
      end if;
    else
      raise exception 'You can''t make this change';
    end if;

  elsif p_status = 'closed' then
    if t.status <> 'completed' then raise exception 'Only completed tasks can be closed'; end if;
    if not (v_editor and (not v_mine or t.created_by = auth.uid())) then
      raise exception 'The person who created it, a team leader or a manager closes it';
    end if;

  else
    raise exception 'Use Escalate to escalate a task';
  end if;

  update public.tasks
     set status = v_to,
         escalated = case when v_to = 'in_progress' and t.status = 'escalated' then false else escalated end,
         completed_at = case when v_to = 'completed' then now() when v_to = 'in_progress' then null else completed_at end,
         closed_at = case when v_to = 'closed' then now() when v_to = 'in_progress' then null else closed_at end,
         updated_at = now()
   where id = t.id;
  insert into public.task_events (task_id, actor_id, type, from_value, to_value, comment)
  values (t.id, auth.uid(), 'status_changed', t.status::text, v_to::text, nullif(v_note, ''));

  -- Who hears about it.
  if v_to = 'awaiting_approval' then
    for v_user in
      select p.id from public.profiles p
       where p.active and p.id <> auth.uid() and p.role = 'manager'
         and (exists (select 1 from public.registry_managers rm where rm.registry_id = t.registry_id and rm.user_id = p.id)
              or not exists (select 1 from public.registry_managers rm join public.profiles q on q.id = rm.user_id and q.active
                              where rm.registry_id = t.registry_id))
    loop
      perform public.notify(v_user, 'approval_needed', format('Approve: %s', v_label),
        format('%s has finished this and it needs your approval to close.', public.my_name()), '/tasks/' || t.id, true);
    end loop;
  elsif t.status = 'awaiting_approval' and v_to = 'in_progress' then
    perform public.notify(t.assigned_to, 'sent_back', format('Sent back: %s', v_label), v_note, '/tasks/' || t.id, true);
  elsif v_to = 'completed' then
    perform public.notify_task_people(t.id, 'task_completed', format('Completed: %s', v_label),
      format('by %s', public.my_name()));
  elsif v_to = 'in_progress' and t.status in ('completed', 'closed') then
    perform public.notify_task_people(t.id, 'task_reopened', format('Reopened: %s', v_label), v_note, true);
  end if;
  return v_to;
end;
$$;

-- ---------------------------------------------------------------------------
-- Comments, escalating, reassigning, taking over
-- ---------------------------------------------------------------------------

create function public.add_task_comment(p_task_id uuid, p_body text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_body text := trim(coalesce(p_body, ''));
begin
  if not public.can_see_task(p_task_id) then
    raise exception 'Task not found';
  end if;
  if v_body = '' then
    raise exception 'Write a comment first';
  end if;
  if length(v_body) > 4000 then
    raise exception 'Keep comments under 4,000 characters';
  end if;
  insert into public.task_events (task_id, actor_id, type, comment) values (p_task_id, auth.uid(), 'comment', v_body);
  update public.tasks set updated_at = now() where id = p_task_id;
  perform public.notify_task_people(p_task_id, 'task_comment',
    format('%s commented on %s', public.my_name(), public.task_label(p_task_id)), left(v_body, 160));
end;
$$;

create function public.escalate_task(p_task_id uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.tasks;
  v_user uuid;
begin
  select * into t from public.tasks where id = p_task_id for update;
  if t.id is null or not public.can_see_task(p_task_id) then
    raise exception 'Task not found';
  end if;
  if not (public.can_edit_task(p_task_id) or exists (select 1 from public.task_helpers where task_id = t.id and user_id = auth.uid())) then
    raise exception 'You can''t escalate this task';
  end if;
  if t.status in ('completed', 'closed', 'escalated') then
    raise exception 'This task can''t be escalated now';
  end if;
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'Say why it needs escalating';
  end if;
  update public.tasks set status = 'escalated', escalated = true, updated_at = now() where id = t.id;
  insert into public.task_events (task_id, actor_id, type, from_value, to_value, comment)
  values (t.id, auth.uid(), 'status_changed', t.status::text, 'escalated', trim(p_reason));
  for v_user in select m from public.task_managers(t.id) m loop
    continue when v_user = auth.uid();
    perform public.notify(v_user, 'task_escalated', format('Escalated: %s', public.task_label(t.id)),
      format('%s: %s', public.my_name(), trim(p_reason)), '/tasks/' || t.id, true);
  end loop;
end;
$$;

create function public.reassign_task(p_task_id uuid, p_to uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.tasks;
begin
  select * into t from public.tasks where id = p_task_id for update;
  if t.id is null or not public.can_edit_task(p_task_id) then
    raise exception 'You can''t reassign this task';
  end if;
  if t.status in ('completed', 'closed') then
    raise exception 'Reopen the task before reassigning it';
  end if;
  if p_to is null or p_to = t.assigned_to then
    raise exception 'Choose someone else to look after it';
  end if;
  if not public.can_take_tasks(p_to) then
    raise exception 'Choose someone who can be given tasks';
  end if;
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'Give a reason for the change';
  end if;
  update public.tasks set assigned_to = p_to, updated_at = now() where id = t.id;
  delete from public.task_helpers where task_id = t.id and user_id = p_to;
  insert into public.task_events (task_id, actor_id, type, from_value, to_value, comment)
  values (t.id, auth.uid(), 'reassigned', t.assigned_to::text, p_to::text, trim(p_reason));
  perform public.queue_task_email('task_assigned', t.id, p_to);
  if t.assigned_to <> auth.uid() then
    perform public.notify(t.assigned_to, 'task_reassigned', format('Moved to someone else: %s', public.task_label(t.id)),
      trim(p_reason), '/tasks/' || t.id);
  end if;
end;
$$;

-- Team leaders and managers take over a task themselves.
create function public.take_over_task(p_task_id uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.has_role(array['team_leader', 'manager']::public.app_role[]) then
    raise exception 'Team leaders and managers can take over tasks';
  end if;
  perform public.reassign_task(p_task_id, auth.uid(), p_reason);
end;
$$;

-- ---------------------------------------------------------------------------
-- Attachments (files live in the private "task-files" bucket, in a folder
-- named by the task id; only people who can see the task can open them)
-- ---------------------------------------------------------------------------

create table public.task_attachments (
  id          bigint generated always as identity primary key,
  task_id     uuid not null references public.tasks (id) on delete cascade,
  file_path   text not null,
  file_name   text not null,
  size_bytes  bigint,
  uploaded_by uuid not null references public.profiles (id),
  created_at  timestamptz not null default now()
);

create index task_attachments_task_idx on public.task_attachments (task_id);
alter table public.task_attachments enable row level security;
create policy "people who see the task see its files" on public.task_attachments
  for select to authenticated using (public.can_see_task(task_id));
revoke insert, update, delete, truncate on public.task_attachments from anon, authenticated;

create function public.add_task_attachment(p_task_id uuid, p_path text, p_name text, p_size bigint default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.can_see_task(p_task_id) then
    raise exception 'Task not found';
  end if;
  if p_path is null or p_path not like p_task_id::text || '/%' then
    raise exception 'Upload the file again';
  end if;
  insert into public.task_attachments (task_id, file_path, file_name, size_bytes, uploaded_by)
  values (p_task_id, p_path, left(coalesce(nullif(trim(p_name), ''), 'file'), 200), p_size, auth.uid());
  insert into public.task_events (task_id, actor_id, type, comment) values (p_task_id, auth.uid(), 'attachment_added', left(p_name, 200));
  update public.tasks set updated_at = now() where id = p_task_id;
end;
$$;

create function public.task_folder_ok(p_name text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case when split_part(p_name, '/', 1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
              then public.can_see_task(split_part(p_name, '/', 1)::uuid) else false end
$$;

do $storage$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  insert into storage.buckets (id, name, public, file_size_limit)
  values ('task-files', 'task-files', false, 10485760)
  on conflict (id) do nothing;
  create policy "people on a task add files" on storage.objects
    for insert to authenticated with check (bucket_id = 'task-files' and public.task_folder_ok(name));
  create policy "people on a task open files" on storage.objects
    for select to authenticated using (bucket_id = 'task-files' and public.task_folder_ok(name));
end;
$storage$;

revoke execute on function public.notify_task_people(uuid, text, text, text, boolean) from public, anon, authenticated;
revoke execute on function public.task_people(uuid) from public, anon, authenticated;
revoke execute on function public.set_task_status(uuid, public.task_status, text) from public, anon;
revoke execute on function public.add_task_comment(uuid, text) from public, anon;
revoke execute on function public.escalate_task(uuid, text) from public, anon;
revoke execute on function public.reassign_task(uuid, uuid, text) from public, anon;
revoke execute on function public.take_over_task(uuid, text) from public, anon;
revoke execute on function public.add_task_attachment(uuid, text, text, bigint) from public, anon;
revoke execute on function public.can_approve_task(uuid) from public, anon;
grant execute on function public.can_approve_task(uuid) to authenticated;

$m022$;
  insert into public.install_log (name) values ('20261114000001_task_workflow.sql');
end;
$part$;

-- ====================================================================
-- 20261115000001_keep_one_manager.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261115000001_keep_one_manager.sql') then
    return;
  end if;
  execute $m023$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- There must always be at least one active manager. When only one is left,
-- staff admins (and other managers) can't deactivate them or change their
-- role; the system admin can, if it's really needed.

create or replace function public.guard_profile_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor uuid := auth.uid();
begin
  if new.id <> old.id or new.email <> old.email or new.org_id <> old.org_id then
    raise exception 'This field cannot be changed here';
  end if;

  if actor is not null then
    if new.role is distinct from old.role
       or new.team_id is distinct from old.team_id
       or new.active is distinct from old.active then

      if not public.can_manage_people() then
        raise exception 'Only managers and admins can change roles, teams or access';
      end if;

      -- Nobody promotes, demotes or deactivates themselves.
      if new.id = actor and (new.role is distinct from old.role or not new.active) then
        raise exception 'You cannot change your own role or deactivate yourself';
      end if;

      if new.id <> actor and (not public.can_manage_role(old.role) or not public.can_manage_role(new.role)) then
        raise exception 'Only a system admin can manage system admins';
      end if;

      -- A new starter gets a role once onboarding is finished (or as a
      -- conditional role, which sets app.conditional_role while it applies).
      if old.role = 'new_starter' and new.role <> 'new_starter'
         and coalesce(current_setting('app.conditional_role', true), '') <> 'on'
         and cardinality(public.onboarding_missing(new.id, new.role, null)) > 0 then
        raise exception 'They haven''t finished onboarding yet. Give a conditional role with a deadline instead.';
      end if;

      -- A staff admin's role changes need a manager's approval first.
      -- (Managers apply approved requests as themselves, so this never blocks them.)
      -- A new starter's first role is the exception: staff admins set it straight away.
      if new.role is distinct from old.role and public.my_role() = 'staff_admin'
         and public.rule_on('people.staff_admin_role_approval')
         and (old.role <> 'new_starter' or public.rule_on('people.first_role_approval')) then
        raise exception 'Role changes by a staff admin need a manager''s approval. Send it as a request.';
      end if;
      if new.team_id is distinct from old.team_id and public.my_role() = 'staff_admin'
         and public.rule_on('people.staff_admin_team_approval') then
        raise exception 'Team changes by a staff admin need a manager''s approval. Send it as a request.';
      end if;
    end if;
  end if;

  -- Keep at least one active manager (only the system admin can remove the last one).
  if actor is not null and not public.is_system_admin()
     and old.role = 'manager' and old.active
     and (new.role <> 'manager' or not new.active)
     and not exists (select 1 from public.profiles where role = 'manager' and active and id <> old.id) then
    raise exception 'They''re the only manager left, so they can''t be deactivated or given another role. Add another manager first.';
  end if;

  if old.role = 'system_admin' and old.active
     and (new.role <> 'system_admin' or not new.active)
     and not exists (
       select 1 from public.profiles
        where role = 'system_admin' and active and id <> old.id
     ) then
    raise exception 'There must always be at least one active system admin';
  end if;

  if new.active and not old.active then
    new.deactivated_at := null;
  elsif not new.active and old.active then
    new.deactivated_at := now();
  end if;

  if new.role is distinct from old.role then
    perform public.write_audit('role_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.role, 'to', new.role));
  end if;
  if new.active is distinct from old.active then
    perform public.write_audit(
      case when new.active then 'reactivated' else 'deactivated' end,
      'profile', new.id::text, '{}'::jsonb);
  end if;
  if new.team_id is distinct from old.team_id then
    perform public.write_audit('team_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.team_id, 'to', new.team_id));
  end if;

  return new;
end;
$$;

-- Refuse a staff admin's request straight away, rather than at approval.
create or replace function public.request_role_change(p_user_id uuid, p_to_role public.app_role, p_title_id uuid default null, p_reason text default '')
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_from public.app_role;
  v_from_title uuid;
  v_to public.app_role := p_to_role;
begin
  if p_user_id = auth.uid() then
    raise exception 'You cannot change your own role';
  end if;
  select role, job_title_id into v_from, v_from_title from public.profiles where id = p_user_id and active;
  if v_from is null then
    raise exception 'Choose someone who can sign in';
  end if;
  if p_title_id is not null then
    select access_level into v_to from public.job_titles where id = p_title_id and active;
    if v_to is null then raise exception 'Choose a role that is in use'; end if;
  end if;
  if v_from = v_to and v_from_title is not distinct from p_title_id then
    raise exception 'They already have that role';
  end if;
  if v_from = 'manager' and v_to <> 'manager'
     and not exists (select 1 from public.profiles where role = 'manager' and active and id <> p_user_id) then
    raise exception 'They''re the only manager left, so their role can''t change. Add another manager first.';
  end if;
  if not public.can_manage_role(v_from) or not public.can_manage_role(v_to) then
    raise exception 'Only a system admin can manage system admins';
  end if;
  return public.add_change_request('role', p_user_id, null,
    jsonb_build_object('role', v_from, 'title', v_from_title),
    jsonb_build_object('role', v_to, 'title', p_title_id), p_reason);
end;
$$;

$m023$;
  insert into public.install_log (name) values ('20261115000001_keep_one_manager.sql');
end;
$part$;

-- ====================================================================
-- 20261116000001_required_before_completing.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261116000001_required_before_completing.sql') then
    return;
  end if;
  execute $m024$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Required register fields are filled in before a task is completed (or sent
-- for approval), not necessarily when it's created: the person reporting it
-- often doesn't know yet. The system admin can change this so they're needed
-- when the task is created instead. A register's outcome box (for example
-- "Risk reduction strategies") can also be needed before completing.

insert into public.app_settings (key, value, label, description, is_public) values
  ('tasks.required_fields_when', '"complete"', 'When required fields must be filled in',
   'Before completing (or sending for approval), or when the task is created and assigned.', false)
on conflict (key) do nothing;

alter table public.registries add column outcome_required boolean not null default false;
update public.registries set outcome_required = true where kind = 'tasks' and show_outcome and not is_default;

-- Risk: the consequence and how well the controls work are part of the record.
update public.registry_fields f set required = true
  from public.registries r
 where r.id = f.registry_id and r.prefix = 'RSK' and f.key in ('consequence', 'effectiveness');

create or replace function public.clean_details(p_registry_id uuid, p_details jsonb, p_existing jsonb default '{}'::jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  f public.registry_fields;
  v jsonb;
  out jsonb := '{}'::jsonb;
  item jsonb;
  v_check_required boolean;
begin
  p_details := coalesce(p_details, '{}'::jsonb);
  -- For tasks, required fields are usually checked before completing (see
  -- task_missing_fields); records always need them when saved.
  v_check_required := (select kind from public.registries where id = p_registry_id) <> 'tasks'
                      or (select value #>> '{}' from public.app_settings where key = 'tasks.required_fields_when') = 'create';

  for f in select * from public.registry_fields where registry_id = p_registry_id order by sort_order loop
    if not f.active then
      if p_existing ? f.key then
        out := out || jsonb_build_object(f.key, p_existing -> f.key);
      end if;
      continue;
    end if;

    v := p_details -> f.key;
    if v is null or v = 'null'::jsonb or v = '""'::jsonb or v = '[]'::jsonb then
      if f.required and v_check_required then
        raise exception '% is required', f.label;
      end if;
      continue;
    end if;

    case f.type
      when 'text', 'long_text' then
        if jsonb_typeof(v) <> 'string' then raise exception '% must be text', f.label; end if;
        if length(v #>> '{}') > 5000 then raise exception '% is too long', f.label; end if;
      when 'number', 'money' then
        if jsonb_typeof(v) <> 'number' then raise exception '% must be a number', f.label; end if;
      when 'date' then
        if jsonb_typeof(v) <> 'string' or (v #>> '{}') !~ '^\d{4}-\d{2}-\d{2}$' then
          raise exception '% must be a date', f.label;
        end if;
        perform (v #>> '{}')::date;
      when 'yes_no' then
        if jsonb_typeof(v) <> 'boolean' then raise exception '% must be yes or no', f.label; end if;
      when 'choice' then
        if jsonb_typeof(v) <> 'string' or not (f.options ? (v #>> '{}')) then
          raise exception 'Choose one of the options for %', f.label;
        end if;
      when 'multi_choice' then
        if jsonb_typeof(v) <> 'array' then raise exception 'Choose options for %', f.label; end if;
        for item in select * from jsonb_array_elements(v) loop
          if jsonb_typeof(item) <> 'string' or not (f.options ? (item #>> '{}')) then
            raise exception 'Choose from the options for %', f.label;
          end if;
        end loop;
      when 'person' then
        if jsonb_typeof(v) <> 'string' or not exists (
          select 1 from public.profiles where id::text = (v #>> '{}')) then
          raise exception 'Choose a person for %', f.label;
        end if;
      when 'asset' then
        if jsonb_typeof(v) <> 'string' or not exists (
          select 1 from public.records r join public.registries g on g.id = r.registry_id
           where r.id::text = (v #>> '{}') and g.kind = 'records') then
          raise exception 'Choose an item for %', f.label;
        end if;
    end case;

    out := out || jsonb_build_object(f.key, v);
  end loop;

  return out;
end;
$$;

-- What still needs filling in before a task can be completed.
create function public.task_missing_fields(p_task_id uuid)
returns text[]
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(array_agg(label order by sort_order), '{}')
    from (
      select f.label, f.sort_order
        from public.tasks t
        join public.registry_fields f on f.registry_id = t.registry_id and f.active and f.required
       where t.id = p_task_id and t.parent_task_id is null
         and (t.details -> f.key is null or t.details -> f.key in ('null'::jsonb, '""'::jsonb, '[]'::jsonb))
      union all
      select r.outcome_label, 100000
        from public.tasks t
        join public.registries r on r.id = t.registry_id
       where t.id = p_task_id and t.parent_task_id is null
         and r.show_outcome and r.outcome_required and coalesce(trim(t.outcome), '') = ''
    ) m
$$;

revoke execute on function public.task_missing_fields(uuid) from public, anon;
grant execute on function public.task_missing_fields(uuid) to authenticated;

create or replace function public.set_task_status(p_task_id uuid, p_status public.task_status, p_note text default '')
returns public.task_status
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.tasks;
  v_requires boolean;
  v_to public.task_status := p_status;
  v_note text := coalesce(trim(p_note), '');
  v_mine boolean;
  v_editor boolean;
  v_approver boolean;
  v_label text;
  v_user uuid;
begin
  if not public.is_member() then
    raise exception 'Please sign in again';
  end if;
  select * into t from public.tasks where id = p_task_id for update;
  if t.id is null or not public.can_see_task(p_task_id) then
    raise exception 'Task not found';
  end if;
  select requires_approval into v_requires from public.registries where id = t.registry_id;
  v_mine := t.assigned_to = auth.uid();
  v_editor := public.can_edit_task(p_task_id);
  v_approver := public.can_approve_task(p_task_id);
  v_label := public.task_label(p_task_id);

  if p_status = t.status then
    raise exception 'The task is already %', replace(t.status::text, '_', ' ');
  end if;

  if p_status = 'in_progress' then
    if t.status = 'assigned' and v_editor then
      null;
    elsif t.status = 'awaiting_approval' and v_approver then
      if v_note = '' then raise exception 'Say what still needs doing, so they know'; end if;
    elsif t.status = 'escalated' and v_editor and not v_mine then
      null; -- the escalation has been dealt with
    elsif t.status in ('completed', 'closed') and v_editor and not v_mine then
      if v_note = '' then raise exception 'Give a reason for reopening the task'; end if;
    else
      raise exception 'You can''t make this change';
    end if;

  elsif p_status = 'completed' then
    if t.status = 'awaiting_approval' then
      if not v_approver then raise exception 'A manager of this register approves it'; end if;
    elsif t.status in ('assigned', 'in_progress', 'escalated') and v_editor then
      if exists (select 1 from public.tasks a where a.parent_task_id = t.id and a.status not in ('completed', 'closed')) then
        raise exception 'Finish or close its follow-up actions first';
      end if;
      if cardinality(public.task_missing_fields(t.id)) > 0 then
        raise exception 'Fill these in first: %', array_to_string(public.task_missing_fields(t.id), ', ');
      end if;
      if v_requires and not v_approver then
        v_to := 'awaiting_approval';
      end if;
    else
      raise exception 'You can''t make this change';
    end if;

  elsif p_status = 'closed' then
    if t.status <> 'completed' then raise exception 'Only completed tasks can be closed'; end if;
    if not (v_editor and (not v_mine or t.created_by = auth.uid())) then
      raise exception 'The person who created it, a team leader or a manager closes it';
    end if;

  else
    raise exception 'Use Escalate to escalate a task';
  end if;

  update public.tasks
     set status = v_to,
         escalated = case when v_to = 'in_progress' and t.status = 'escalated' then false else escalated end,
         completed_at = case when v_to = 'completed' then now() when v_to = 'in_progress' then null else completed_at end,
         closed_at = case when v_to = 'closed' then now() when v_to = 'in_progress' then null else closed_at end,
         updated_at = now()
   where id = t.id;
  insert into public.task_events (task_id, actor_id, type, from_value, to_value, comment)
  values (t.id, auth.uid(), 'status_changed', t.status::text, v_to::text, nullif(v_note, ''));

  -- Who hears about it.
  if v_to = 'awaiting_approval' then
    for v_user in
      select p.id from public.profiles p
       where p.active and p.id <> auth.uid() and p.role = 'manager'
         and (exists (select 1 from public.registry_managers rm where rm.registry_id = t.registry_id and rm.user_id = p.id)
              or not exists (select 1 from public.registry_managers rm join public.profiles q on q.id = rm.user_id and q.active
                              where rm.registry_id = t.registry_id))
    loop
      perform public.notify(v_user, 'approval_needed', format('Approve: %s', v_label),
        format('%s has finished this and it needs your approval to close.', public.my_name()), '/tasks/' || t.id, true);
    end loop;
  elsif t.status = 'awaiting_approval' and v_to = 'in_progress' then
    perform public.notify(t.assigned_to, 'sent_back', format('Sent back: %s', v_label), v_note, '/tasks/' || t.id, true);
  elsif v_to = 'completed' then
    perform public.notify_task_people(t.id, 'task_completed', format('Completed: %s', v_label),
      format('by %s', public.my_name()));
  elsif v_to = 'in_progress' and t.status in ('completed', 'closed') then
    perform public.notify_task_people(t.id, 'task_reopened', format('Reopened: %s', v_label), v_note, true);
  end if;
  return v_to;
end;
$$;

$m024$;
  insert into public.install_log (name) values ('20261116000001_required_before_completing.sql');
end;
$part$;

-- ====================================================================
-- 20261117000001_customisation.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261117000001_customisation.sql') then
    return;
  end if;
  execute $m025$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- More things the system admin can set without a developer: the logo
-- (uploaded), a support contact, an announcement banner, a note in the
-- welcome invite, the time of the managers' morning summary, who sees
-- Reports, and the Attachments, Auto-escalation and Reports switches.

insert into public.app_settings (key, value, label, description, is_public) values
  ('brand.support_contact', '""', 'Support contact',
   'Shown on the sign-in and two-factor pages, for example "Need help? Call the office on 03 9000 0000". Leave blank to hide.', true),
  ('brand.announcement', '""', 'Announcement banner',
   'A short message at the top of every page for all staff. Leave blank to hide.', false),
  ('people.invite_message', '""', 'Message in the welcome invite',
   'An extra note in the welcome email, for example who to call on their first day. Leave blank to leave it out.', false),
  ('tasks.summary_hour', '7', 'Morning summary time (hour, 24-hour clock)',
   'When the managers'' weekday summary of overdue tasks is sent, for example 7 for 7 am.', false),
  ('reports.roles', '["manager"]', 'Who can see Reports',
   'Besides the system admin. Team leaders see reports for the tasks of their own team.', false)
on conflict (key) do nothing;

update public.features set description = 'Escalate tasks to managers automatically when they''re overdue for the number of days set on Due dates (SLA).'
 where key = 'auto_escalation';
update public.features set description = 'Photos and files on tasks.' where key = 'attachments';
update public.features set description = 'The Reports page, with Excel downloads.' where key = 'reports';

-- No files on tasks while Attachments is switched off.
create or replace function public.add_task_attachment(p_task_id uuid, p_path text, p_name text, p_size bigint default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.feature_enabled('attachments') then
    raise exception 'Attachments are switched off';
  end if;
  if not public.can_see_task(p_task_id) then
    raise exception 'Task not found';
  end if;
  if p_path is null or p_path not like p_task_id::text || '/%' then
    raise exception 'Upload the file again';
  end if;
  insert into public.task_attachments (task_id, file_path, file_name, size_bytes, uploaded_by)
  values (p_task_id, p_path, left(coalesce(nullif(trim(p_name), ''), 'file'), 200), p_size, auth.uid());
  insert into public.task_events (task_id, actor_id, type, comment) values (p_task_id, auth.uid(), 'attachment_added', left(p_name, 200));
  update public.tasks set updated_at = now() where id = p_task_id;
end;
$$;

create or replace function public.run_due_alerts(p_now timestamptz default now())
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tz text := coalesce((select value #>> '{}' from public.app_settings where key = 'region.timezone'), 'Australia/Melbourne');
  v_now timestamp := p_now at time zone v_tz;
  v_today date := v_now::date;
  v_weekdays boolean := coalesce((select (value #>> '{}')::boolean from public.app_settings where key = 'tasks.sla_weekdays_only'), false);
  v_remind int := coalesce((select (value #>> '{}')::int from public.app_settings where key = 'tasks.sla_remind_days'), 1);
  v_escalate int := coalesce((select (value #>> '{}')::int from public.app_settings where key = 'tasks.sla_escalate_days'), 3);
  v_summary boolean := coalesce((select (value #>> '{}')::boolean from public.app_settings where key = 'tasks.sla_manager_summary'), true);
  v_summary_hour int := coalesce((select (value #>> '{}')::int from public.app_settings where key = 'tasks.summary_hour'), 7);
  v_weekend boolean := extract(isodow from v_today) >= 6;
  t record;
  v_late int;
  v_person uuid;
  v_leaders uuid[];
  v_escalated int := 0;
  v_summaries int := 0;
  v_list jsonb;
begin
  if not public.feature_enabled('tasks') then
    return jsonb_build_object('skipped', 'tasks are switched off');
  end if;
  -- With "weekdays only", nothing is sent at the weekend; Monday catches up.
  if v_weekdays and v_weekend then
    return jsonb_build_object('skipped', 'weekend');
  end if;

  for t in
    select id, assigned_to, due_date, status, escalated
      from public.tasks
     where due_date is not null
       and status not in ('completed', 'closed')
       and due_date <= v_today + greatest(v_remind, 0) + 7
  loop
    v_late := public.working_days_between(t.due_date, v_today, v_weekdays);

    if t.due_date > v_today then
      if v_remind > 0 and -v_late <= v_remind then
        perform public.send_due_alert(t.id, t.assigned_to, 'reminder', t.due_date);
      end if;
      continue;
    end if;

    if t.due_date = v_today then
      perform public.send_due_alert(t.id, t.assigned_to, 'due_today', t.due_date);
      for v_person in select user_id from public.task_helpers where task_id = t.id loop
        perform public.send_due_alert(t.id, v_person, 'due_today', t.due_date);
      end loop;
      continue;
    end if;

    -- Overdue: the person and their team leaders (managers if there are none).
    perform public.send_due_alert(t.id, t.assigned_to, 'overdue', t.due_date);
    select coalesce(array_agg(distinct tl.user_id), '{}') into v_leaders
      from public.team_members m
      join public.team_leaders tl on tl.team_id = m.team_id
      join public.profiles p on p.id = tl.user_id and p.active
     where m.user_id = t.assigned_to and tl.user_id <> t.assigned_to;
    if cardinality(v_leaders) = 0 then
      select coalesce(array_agg(m), '{}') into v_leaders from public.task_managers(t.id) m;
    end if;
    foreach v_person in array v_leaders loop
      perform public.send_due_alert(t.id, v_person, 'overdue', t.due_date);
    end loop;

    -- Still overdue: managers, and the task is marked escalated.
    if v_escalate > 0 and v_late >= v_escalate and public.feature_enabled('auto_escalation') then
      if t.status <> 'escalated' then
        update public.tasks set status = 'escalated', escalated = true, updated_at = now() where id = t.id;
        insert into public.task_events (task_id, actor_id, type, from_value, to_value, comment)
        values (t.id, null, 'status_changed', t.status::text, 'escalated',
                format('Escalated automatically: %s days overdue', v_late));
        v_escalated := v_escalated + 1;
      end if;
      for v_person in select m from public.task_managers(t.id) m loop
        perform public.send_due_alert(t.id, v_person, 'escalated', t.due_date);
      end loop;
    end if;
  end loop;

  -- The morning summary, once each weekday from 7am.
  if v_summary and not v_weekend and extract(hour from v_now) >= v_summary_hour and public.feature_enabled('email_notifications') then
    insert into public.daily_runs (job, day) values ('manager_summary', v_today) on conflict do nothing;
    if found then
      select jsonb_agg(jsonb_build_object(
               'id', t2.id,
               'ref', coalesce(r.prefix, 'T') || '-' || lpad(t2.ref_number::text, 4, '0'),
               'title', t2.title,
               'registry', r.name,
               'assignee', case when p.role = 'system_admin' then 'Admin' else coalesce(nullif(p.full_name, ''), p.email) end,
               'due_date', t2.due_date,
               'days_late', public.working_days_between(t2.due_date, v_today, v_weekdays),
               'escalated', t2.status = 'escalated')
             order by t2.due_date, t2.ref_number)
        into v_list
        from public.tasks t2
        join public.registries r on r.id = t2.registry_id
        join public.profiles p on p.id = t2.assigned_to
       where t2.due_date < v_today and t2.status not in ('completed', 'closed');
      if v_list is not null then
        insert into public.email_outbox (to_user, template, data)
        select id, 'overdue_summary', jsonb_build_object('tasks', v_list, 'day', v_today)
          from public.profiles where active and role = 'manager';
        get diagnostics v_summaries = row_count;
      end if;
    end if;
  end if;

  return jsonb_build_object('today', v_today, 'escalated', v_escalated, 'summaries', v_summaries);
end;
$$;

revoke execute on function public.run_due_alerts(timestamptz) from public, anon, authenticated;
grant execute on function public.run_due_alerts(timestamptz) to service_role;

-- Logos: a public bucket (the sign-in page and emails show them); only the
-- system admin uploads.
do $storage$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values ('branding', 'branding', true, 2097152, array['image/png', 'image/jpeg', 'image/svg+xml', 'image/webp'])
  on conflict (id) do nothing;
  create policy "system admin uploads logos" on storage.objects
    for insert to authenticated with check (bucket_id = 'branding' and public.is_system_admin());
end;
$storage$;

$m025$;
  insert into public.install_log (name) values ('20261117000001_customisation.sql');
end;
$part$;

-- ====================================================================
-- 20261118000001_manager_own_tasks.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261118000001_manager_own_tasks.sql') then
    return;
  end if;
  execute $m026$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Managers' own tasks don't need approval: a manager completing a task they
-- look after closes it directly (the page asks them to confirm). Tasks of
-- theirs already waiting for approval can be approved by them. Approval
-- requests go to the register's managers, or to every other manager when
-- the register's only manager is the one who sent it.

create or replace function public.can_approve_task(p_task_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and exists (
    select 1 from public.tasks t
     where t.id = p_task_id
       -- Nobody approves their own work, except managers (their own tasks don't need approval).
       and (t.assigned_to <> auth.uid() or public.has_role(array['manager']::public.app_role[]))
       and (public.is_system_admin()
            or (public.has_role(array['manager']::public.app_role[])
                and (exists (select 1 from public.registry_managers rm where rm.registry_id = t.registry_id and rm.user_id = auth.uid())
                     or not exists (select 1 from public.registry_managers rm join public.profiles p on p.id = rm.user_id and p.active
                                     where rm.registry_id = t.registry_id))))
  )
$$;

create or replace function public.set_task_status(p_task_id uuid, p_status public.task_status, p_note text default '')
returns public.task_status
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.tasks;
  v_requires boolean;
  v_to public.task_status := p_status;
  v_note text := coalesce(trim(p_note), '');
  v_mine boolean;
  v_editor boolean;
  v_approver boolean;
  v_label text;
  v_user uuid;
begin
  if not public.is_member() then
    raise exception 'Please sign in again';
  end if;
  select * into t from public.tasks where id = p_task_id for update;
  if t.id is null or not public.can_see_task(p_task_id) then
    raise exception 'Task not found';
  end if;
  select requires_approval into v_requires from public.registries where id = t.registry_id;
  v_mine := t.assigned_to = auth.uid();
  v_editor := public.can_edit_task(p_task_id);
  v_approver := public.can_approve_task(p_task_id);
  v_label := public.task_label(p_task_id);

  if p_status = t.status then
    raise exception 'The task is already %', replace(t.status::text, '_', ' ');
  end if;

  if p_status = 'in_progress' then
    if t.status = 'assigned' and v_editor then
      null;
    elsif t.status = 'awaiting_approval' and v_approver then
      if v_note = '' then raise exception 'Say what still needs doing, so they know'; end if;
    elsif t.status = 'escalated' and v_editor and not v_mine then
      null; -- the escalation has been dealt with
    elsif t.status in ('completed', 'closed') and v_editor and not v_mine then
      if v_note = '' then raise exception 'Give a reason for reopening the task'; end if;
    else
      raise exception 'You can''t make this change';
    end if;

  elsif p_status = 'completed' then
    if t.status = 'awaiting_approval' then
      if not v_approver then raise exception 'A manager of this register approves it'; end if;
    elsif t.status in ('assigned', 'in_progress', 'escalated') and v_editor then
      if exists (select 1 from public.tasks a where a.parent_task_id = t.id and a.status not in ('completed', 'closed')) then
        raise exception 'Finish or close its follow-up actions first';
      end if;
      if cardinality(public.task_missing_fields(t.id)) > 0 then
        raise exception 'Fill these in first: %', array_to_string(public.task_missing_fields(t.id), ', ');
      end if;
      -- A manager finishing their own task closes it without an approval step.
      if v_requires and not v_approver
         and not (v_mine and public.has_role(array['manager']::public.app_role[])) then
        v_to := 'awaiting_approval';
      end if;
    else
      raise exception 'You can''t make this change';
    end if;

  elsif p_status = 'closed' then
    if t.status <> 'completed' then raise exception 'Only completed tasks can be closed'; end if;
    if not (v_editor and (not v_mine or t.created_by = auth.uid())) then
      raise exception 'The person who created it, a team leader or a manager closes it';
    end if;

  else
    raise exception 'Use Escalate to escalate a task';
  end if;

  update public.tasks
     set status = v_to,
         escalated = case when v_to = 'in_progress' and t.status = 'escalated' then false else escalated end,
         completed_at = case when v_to = 'completed' then now() when v_to = 'in_progress' then null else completed_at end,
         closed_at = case when v_to = 'closed' then now() when v_to = 'in_progress' then null else closed_at end,
         updated_at = now()
   where id = t.id;
  insert into public.task_events (task_id, actor_id, type, from_value, to_value, comment)
  values (t.id, auth.uid(), 'status_changed', t.status::text, v_to::text, nullif(v_note, ''));

  -- Who hears about it.
  if v_to = 'awaiting_approval' then
    -- The register's managers; if none (other than whoever sent it), every other manager.
    for v_user in
      with reg as (
        select p.id from public.profiles p
          join public.registry_managers rm on rm.user_id = p.id and rm.registry_id = t.registry_id
         where p.active and p.role = 'manager' and p.id <> auth.uid()
      )
      select id from reg
      union
      select p.id from public.profiles p
       where p.active and p.role = 'manager' and p.id <> auth.uid() and not exists (select 1 from reg)
    loop
      perform public.notify(v_user, 'approval_needed', format('Approve: %s', v_label),
        format('%s has finished this and it needs your approval to close.', public.my_name()), '/tasks/' || t.id, true);
    end loop;
  elsif t.status = 'awaiting_approval' and v_to = 'in_progress' then
    perform public.notify(t.assigned_to, 'sent_back', format('Sent back: %s', v_label), v_note, '/tasks/' || t.id, true);
  elsif v_to = 'completed' then
    perform public.notify_task_people(t.id, 'task_completed', format('Completed: %s', v_label),
      format('by %s', public.my_name()));
  elsif v_to = 'in_progress' and t.status in ('completed', 'closed') then
    perform public.notify_task_people(t.id, 'task_reopened', format('Reopened: %s', v_label), v_note, true);
  end if;
  return v_to;
end;
$$;

-- Sign people out after a period without activity (0 = never).
insert into public.app_settings (key, value, label, description, is_public) values
  ('security.idle_minutes', '30', 'Sign out after (minutes without activity)',
   'People are signed out after this long without using the portal, even if they closed the browser. 0 means never.', false)
on conflict (key) do nothing;

$m026$;
  insert into public.install_log (name) values ('20261118000001_manager_own_tasks.sql');
end;
$part$;

-- ====================================================================
-- 20261119000001_delegation.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261119000001_delegation.sql') then
    return;
  end if;
  execute $m027$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Delegation: the system admin lets a named manager look after some areas
-- of System settings. Never delegated: Security, Features, General (region
-- and record keeping), making system admins, and Delegation itself.
--   branding    company name, logos, colours, wording
--   messages    support contact, announcement, invite note
--   people      people rules
--   compliance  Compliance settings
--   tasks       task settings (due dates, reminders, required fields)
--   reports     who can see Reports
--   audit       read the change log

create table public.admin_delegations (
  user_id    uuid primary key references public.profiles (id) on delete cascade,
  areas      text[] not null default '{}'
             check (areas <@ array['branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'audit']),
  granted_by uuid references public.profiles (id),
  granted_at timestamptz not null default now()
);

alter table public.admin_delegations enable row level security;
create policy "system admin and the delegate read delegations" on public.admin_delegations
  for select to authenticated using (public.is_system_admin() or user_id = auth.uid());
revoke insert, update, delete, truncate on public.admin_delegations from anon, authenticated;

-- Can the signed-in person look after this area of System settings?
create function public.can_admin_area(p_area text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.mfa_ok() and (
    public.is_system_admin()
    or (p_area is not null and public.my_role() = 'manager'
        and exists (select 1 from public.admin_delegations d where d.user_id = auth.uid() and p_area = any (d.areas)))
  )
$$;

-- Which area a setting belongs to (null = system admin only).
create function public.setting_area(p_key text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when p_key in ('brand.support_contact', 'brand.announcement', 'people.invite_message') then 'messages'
    when p_key like 'brand.%' or p_key like 'wording.%' then 'branding'
    when p_key like 'people.%' then 'people'
    when p_key like 'compliance.%' then 'compliance'
    when p_key like 'tasks.%' then 'tasks'
    when p_key like 'reports.%' then 'reports'
    else null
  end
$$;

create policy "delegated managers edit their settings" on public.app_settings
  for update to authenticated
  using (public.can_admin_area(public.setting_area(key)))
  with check (public.can_admin_area(public.setting_area(key)));

create policy "delegated managers read the change log" on public.audit_log
  for select to authenticated using (public.can_admin_area('audit'));

-- Set (or clear, with no areas) what a manager looks after.
create function public.set_delegation(p_user_id uuid, p_areas text[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_areas text[] := coalesce((select array_agg(distinct a order by a) from unnest(coalesce(p_areas, '{}')) a), '{}');
begin
  if not public.is_system_admin() or not public.mfa_ok() then
    raise exception 'Only the system admin delegates';
  end if;
  if cardinality(v_areas) > 0
     and not exists (select 1 from public.profiles where id = p_user_id and role = 'manager' and active) then
    raise exception 'Only active managers can be given areas to look after';
  end if;
  if cardinality(v_areas) = 0 then
    delete from public.admin_delegations where user_id = p_user_id;
  else
    insert into public.admin_delegations (user_id, areas, granted_by)
    values (p_user_id, v_areas, auth.uid())
    on conflict (user_id) do update set areas = excluded.areas, granted_by = excluded.granted_by, granted_at = now();
  end if;
  perform public.write_audit('delegation_changed', 'profile', p_user_id::text, jsonb_build_object('areas', to_jsonb(v_areas)));
end;
$$;

revoke execute on function public.set_delegation(uuid, text[]) from public, anon;
grant execute on function public.set_delegation(uuid, text[]) to authenticated;

-- Someone who stops being an active manager loses their delegated areas.
create function public.drop_delegation_on_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.role <> 'manager' or not new.active then
    delete from public.admin_delegations where user_id = new.id;
  end if;
  return new;
end;
$$;

create trigger profiles_drop_delegation
  after update of role, active on public.profiles
  for each row execute function public.drop_delegation_on_change();

-- Delegated managers with Branding can upload logos.
do $storage$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  create policy "delegated managers upload logos" on storage.objects
    for insert to authenticated with check (bucket_id = 'branding' and public.can_admin_area('branding'));
end;
$storage$;

$m027$;
  insert into public.install_log (name) values ('20261119000001_delegation.sql');
end;
$part$;

-- ====================================================================
-- 20261120000001_upload_for_staff.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261120000001_upload_for_staff.sql') then
    return;
  end if;
  execute $m028$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Uploading for someone, and expiry reminders by email.
--   Staff admins (anyone who manages Compliance) and managers can upload a
--   document on a person's behalf. A Compliance manager's upload counts as
--   checked; a manager's goes to a staff admin to check, as usual.
--   The person now gets an email (as well as the bell) when a document is
--   about to expire, not only once it has.

alter table public.compliance_records add column uploaded_by uuid references public.profiles (id) default auth.uid();
update public.compliance_records set uploaded_by = user_id where uploaded_by is null;

create function public.submit_compliance_upload_for(p_user_id uuid, p_item_id uuid, p_path text, p_name text, p_expires date default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  i public.compliance_items;
  v_checker boolean := public.can_manage_compliance();
  v_name text;
  v_admin uuid;
begin
  if not (v_checker or (public.has_role(array['manager']::public.app_role[]) and public.mfa_ok())) then
    raise exception 'Only staff admins and managers can upload for someone else';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'Upload your own documents on My onboarding';
  end if;
  if not exists (select 1 from public.profiles where id = p_user_id and active) then
    raise exception 'Choose someone who can sign in';
  end if;
  select * into i from public.compliance_items where id = p_item_id and active and kind = 'upload';
  if i.id is null then
    raise exception 'Uploads for this document are switched off';
  end if;
  if p_path is null or p_path not like p_user_id::text || '/%' then
    raise exception 'Upload the file again';
  end if;
  if i.needs_expiry and p_expires is null then
    raise exception 'Enter the expiry date';
  end if;
  if p_expires is not null and p_expires < public.local_today() then
    raise exception 'This document has already expired. Upload a current one.';
  end if;

  insert into public.compliance_records (item_id, user_id, version, status, file_path, file_name, expires_on,
                                         uploaded_by, reviewed_by, reviewed_at)
  values (i.id, p_user_id, i.version, case when v_checker then 'accepted' else 'submitted' end,
          p_path, left(coalesce(p_name, ''), 200), p_expires, auth.uid(),
          case when v_checker then auth.uid() end, case when v_checker then now() end);

  perform public.notify(p_user_id, 'uploaded_for_you', format('%s uploaded your %s', public.my_name(), i.title),
    'You don''t need to upload it yourself.', '/onboarding');
  if not v_checker then
    select coalesce(nullif(full_name, ''), email) into v_name from public.profiles where id = p_user_id;
    for v_admin in select a from public.people_admins() a loop
      continue when v_admin = auth.uid();
      perform public.notify(v_admin, 'upload_submitted', format('%s uploaded %s for %s', public.my_name(), i.title, v_name),
        'Check it on the Compliance page.', '/compliance/people/' || p_user_id);
    end loop;
  end if;
  perform public.write_audit('uploaded_for_someone', 'profile', p_user_id::text, jsonb_build_object('item', i.title));
  perform public.check_onboarding_complete(p_user_id);
end;
$$;

revoke execute on function public.submit_compliance_upload_for(uuid, uuid, text, text, date) from public, anon;
grant execute on function public.submit_compliance_upload_for(uuid, uuid, text, text, date) to authenticated;

create or replace function public.run_compliance_alerts()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  s record;
  v_n int := 0;
  v_admin uuid;
  v_name text;
begin
  for s in
    select p.id user_id, coalesce(nullif(p.full_name, ''), p.email) person, st.title, st.state, st.record_id, st.expires_on
      from public.profiles p
      cross join lateral public.compliance_status(p.id) st
     where p.active and p.role <> 'system_admin' and st.state in ('expiring', 'expired') and st.record_id is not null
  loop
    insert into public.compliance_alerts (record_id, step) values (s.record_id, s.state) on conflict do nothing;
    continue when not found;
    v_n := v_n + 1;
    -- The person: bell and email, both before it expires and once it has.
    perform public.notify(s.user_id, 'document_' || s.state,
      case when s.state = 'expired' then format('%s has expired', s.title) else format('%s expires soon', s.title) end,
      format('Expiry date: %s. Upload a new copy on My onboarding.', to_char(s.expires_on, 'FMDD Mon YYYY')),
      '/onboarding', true);
    for v_admin in select a from public.people_admins() a loop
      continue when v_admin = s.user_id;
      perform public.notify(v_admin, 'document_' || s.state,
        format('%s: %s %s', s.person, s.title, case when s.state = 'expired' then 'has expired' else 'expires soon' end),
        format('Expiry date: %s.', to_char(s.expires_on, 'FMDD Mon YYYY')),
        '/compliance/people/' || s.user_id, s.state = 'expired');
    end loop;
  end loop;
  return jsonb_build_object('document_alerts', v_n);
end;
$$;

revoke execute on function public.run_compliance_alerts() from public, anon, authenticated;
grant execute on function public.run_compliance_alerts() to service_role;

-- Staff admins and managers can put files in a person's folder.
do $storage$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  create policy "staff admins and managers upload for staff" on storage.objects
    for insert to authenticated
    with check (bucket_id = 'compliance-files'
                and (public.can_manage_compliance() or (public.has_role(array['manager']::public.app_role[]) and public.mfa_ok())));
end;
$storage$;

$m028$;
  insert into public.install_log (name) values ('20261120000001_upload_for_staff.sql');
end;
$part$;

-- ====================================================================
-- 20261121000001_cars.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261121000001_cars.sql') then
    return;
  end if;
  execute $m029$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Company cars (cmeprojects): staff start a trip (car, purpose, client, start
-- odometer) and return it (end odometer). The driver is whoever is signed in,
-- and the times are recorded by the database. Starting and returning can be
-- undone for a few minutes; after that only a car manager can correct a trip,
-- with a reason, and the change log keeps both versions.
--
-- Car managers (managers by default) add cars, clients and purposes of use.
-- Reminders: the driver at night if a car is still out, car managers the next
-- morning, rego and service coming up, and a weekly mileage report.

-- ---------------------------------------------------------------------------
-- Switch, settings and who does what
-- ---------------------------------------------------------------------------

update public.features
   set label = 'Cars', description = 'Company cars: staff start and return trips, with mileage reports.', enabled = true
 where key = 'vehicles';

insert into public.app_settings (key, value, label, description, is_public) values
  ('vehicles.manager_roles', '["manager"]', 'Who manages cars',
   'Add and switch off cars, clients and purposes of use, and correct trips. The system admin always can.', false),
  ('vehicles.report_roles', '["manager"]', 'Who sees car reports',
   'The car use log and mileage reports, for all cars and staff. Everyone sees their own trips.', false),
  ('vehicles.client_field', '"optional"', 'Client on each trip',
   'Off hides the client list, Optional lets staff leave it blank, Required makes them choose one. Car managers can change this on Manage cars → Clients.', false),
  ('vehicles.odo_photo', '"optional"', 'Odometer photo when returning',
   'Off, Optional or Required.', false),
  ('vehicles.undo_minutes', '10', 'Time to undo a start or return (minutes)',
   'After this, only a car manager can correct a trip.', false),
  ('vehicles.reminder_hour', '20', 'Car still out reminder (hour, 24-hour clock)',
   'The driver gets a reminder at this time if they haven''t returned the car. Car managers are told the next morning.', false),
  ('vehicles.app_days', '90', 'Stay signed in on the Cars app (days)',
   'Staff unlock the Cars app with their PIN until then, then sign in again.', false)
on conflict (key) do nothing;

alter table public.admin_delegations drop constraint if exists admin_delegations_areas_check;
alter table public.admin_delegations add constraint admin_delegations_areas_check
  check (areas <@ array['branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'audit']);

create or replace function public.setting_area(p_key text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when p_key in ('brand.support_contact', 'brand.announcement', 'people.invite_message') then 'messages'
    when p_key like 'brand.%' or p_key like 'wording.%' then 'branding'
    when p_key like 'people.%' then 'people'
    when p_key like 'compliance.%' then 'compliance'
    when p_key like 'tasks.%' then 'tasks'
    when p_key like 'reports.%' then 'reports'
    when p_key like 'vehicles.%' then 'vehicles'
    else null
  end
$$;

create function public.cars_on()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.feature_enabled('vehicles') and public.is_member() and public.my_role() <> 'new_starter'
$$;

create function public.can_manage_cars()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.cars_on()
     and (public.my_role() = 'system_admin' or public.my_role() = any (public.setting_roles('vehicles.manager_roles')))
$$;

create function public.can_see_car_reports()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.can_manage_cars()
      or (public.cars_on() and public.my_role() = any (public.setting_roles('vehicles.report_roles')))
$$;

create function public.car_setting(p_key text, p_default text)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select value #>> '{}' from public.app_settings where key = p_key), p_default)
$$;

-- ---------------------------------------------------------------------------
-- Cars, clients and purposes
-- ---------------------------------------------------------------------------

create table public.cars (
  id               uuid primary key default gen_random_uuid(),
  org_id           uuid not null default public.default_org_id() references public.organisation (id),
  name             text not null check (length(trim(name)) between 1 and 80),
  rego             text not null check (length(trim(rego)) between 1 and 12),
  car_type         text not null default '' check (length(car_type) <= 60),
  colour           text not null default '' check (length(colour) <= 40),
  -- The last known reading: set when the car is added, then by each return.
  odometer         int not null default 0 check (odometer between 0 and 2000000),
  rego_expires     date,
  service_due_date date,
  service_due_km   int check (service_due_km between 0 and 2000000),
  photo_path       text,
  notes            text not null default '' check (length(notes) <= 1000),
  active           boolean not null default true,
  -- Reminders already sent (so each is sent once).
  rego_alerted     date,
  service_alerted  text,
  created_by       uuid references public.profiles (id) default auth.uid(),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create unique index cars_rego_unique on public.cars (org_id, upper(replace(rego, ' ', '')));

create table public.car_clients (
  id         uuid primary key default gen_random_uuid(),
  org_id     uuid not null default public.default_org_id() references public.organisation (id),
  name       text not null check (length(trim(name)) between 1 and 80),
  reference  text not null default '' check (length(reference) <= 60),
  active     boolean not null default true,
  created_by uuid references public.profiles (id) default auth.uid(),
  created_at timestamptz not null default now()
);

create table public.car_purposes (
  id         uuid primary key default gen_random_uuid(),
  org_id     uuid not null default public.default_org_id() references public.organisation (id),
  name       text not null check (length(trim(name)) between 1 and 60),
  active     boolean not null default true,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);
create unique index car_purposes_name_unique on public.car_purposes (org_id, lower(trim(name)));

insert into public.car_purposes (name, sort_order) values
  ('Client transport', 10), ('Community access', 20), ('Shopping with a client', 30),
  ('Medical appointment', 40), ('Office errand', 50), ('Other', 90);

alter table public.cars enable row level security;
alter table public.car_clients enable row level security;
alter table public.car_purposes enable row level security;

create policy "staff see cars" on public.cars for select to authenticated using (public.cars_on());
create policy "car managers add cars" on public.cars for insert to authenticated with check (public.can_manage_cars());
create policy "car managers change cars" on public.cars for update to authenticated
  using (public.can_manage_cars()) with check (public.can_manage_cars());

-- Staff choose clients through car_client_options(), which shows names only.
create policy "car managers see clients" on public.car_clients for select to authenticated using (public.can_manage_cars());
create policy "car managers add clients" on public.car_clients for insert to authenticated with check (public.can_manage_cars());
create policy "car managers change clients" on public.car_clients for update to authenticated
  using (public.can_manage_cars()) with check (public.can_manage_cars());

-- Car managers set whether trips have a client (the other car settings stay
-- with the system admin, or a manager they delegate Cars to).
create policy "car managers set the client field" on public.app_settings
  for update to authenticated
  using (key = 'vehicles.client_field' and public.can_manage_cars())
  with check (key = 'vehicles.client_field' and public.can_manage_cars()
              and value #>> '{}' in ('off', 'optional', 'required'));

create policy "staff see purposes" on public.car_purposes for select to authenticated using (public.cars_on());
create policy "car managers add purposes" on public.car_purposes for insert to authenticated with check (public.can_manage_cars());
create policy "car managers change purposes" on public.car_purposes for update to authenticated
  using (public.can_manage_cars()) with check (public.can_manage_cars());

-- Nothing is deleted: cars, clients and purposes are switched off instead.
revoke delete, truncate on public.cars, public.car_clients, public.car_purposes from anon, authenticated;

-- Changes to cars, clients and purposes go in the change log.
create function public.log_car_setup()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.write_audit(
    case when tg_op = 'INSERT' then 'added' else 'changed' end || '_' || tg_argv[0],
    tg_argv[0], new.id::text,
    case when tg_op = 'INSERT' then to_jsonb(new) else jsonb_build_object('before', to_jsonb(old), 'after', to_jsonb(new)) end);
  return new;
end;
$$;

create function public.touch_car()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger cars_touch before update on public.cars for each row execute function public.touch_car();
create trigger cars_log after insert or update of name, rego, car_type, colour, rego_expires, service_due_date,
  service_due_km, notes, active on public.cars for each row execute function public.log_car_setup('car');
create trigger car_clients_log after insert or update on public.car_clients for each row execute function public.log_car_setup('car_client');
create trigger car_purposes_log after insert or update on public.car_purposes for each row execute function public.log_car_setup('car_purpose');

-- ---------------------------------------------------------------------------
-- Trips
-- ---------------------------------------------------------------------------

create table public.car_trips (
  id              bigint generated always as identity primary key,
  org_id          uuid not null default public.default_org_id() references public.organisation (id),
  car_id          uuid not null references public.cars (id),
  driver_id       uuid not null references public.profiles (id),
  purpose         text not null check (length(purpose) between 1 and 60),
  details         text not null default '' check (length(details) <= 300),
  -- The client's name at the time, so history reads the same if it changes.
  client_id       uuid references public.car_clients (id),
  client_name     text not null default '',
  started_at      timestamptz not null default now(),
  start_odo       int not null check (start_odo between 0 and 2000000),
  -- How far the car went between the last return and this start (not logged).
  gap_km          int not null default 0,
  returned_at     timestamptz,
  end_odo         int check (end_odo between 0 and 2000000),
  km              int generated always as (end_odo - start_odo) stored,
  returned_by     uuid references public.profiles (id),
  return_note     text not null default '' check (length(return_note) <= 300),
  odo_photo_path  text,
  reminded_at     timestamptz,
  managers_told_at timestamptz,
  corrected_at    timestamptz,
  check (end_odo is null or end_odo >= start_odo),
  check ((returned_at is null) = (end_odo is null))
);
-- One trip at a time per car, and per driver.
create unique index car_trips_one_per_car on public.car_trips (car_id) where returned_at is null;
create unique index car_trips_one_per_driver on public.car_trips (driver_id) where returned_at is null;
create index car_trips_started on public.car_trips (started_at desc);

alter table public.car_trips enable row level security;
create policy "drivers see their trips, reports see all" on public.car_trips for select to authenticated
  using (public.cars_on() and (driver_id = auth.uid() or public.can_see_car_reports()));
-- Trips change only through the functions below.
revoke insert, update, delete, truncate on public.car_trips from anon, authenticated;

-- Which cars are free, who has the others, and the suggested start reading.
create function public.car_board()
returns table (id uuid, name text, rego text, car_type text, colour text, odometer int,
               trip_id bigint, driver_id uuid, driver_name text, started_at timestamptz)
language sql
stable
security definer
set search_path = ''
as $$
  select c.id, c.name, c.rego, c.car_type, c.colour, c.odometer,
         t.id, t.driver_id,
         case when p.role = 'system_admin' then 'Admin' else coalesce(nullif(p.full_name, ''), p.email) end,
         t.started_at
    from public.cars c
    left join public.car_trips t on t.car_id = c.id and t.returned_at is null
    left join public.profiles p on p.id = t.driver_id
   where public.cars_on() and c.active
   order by c.name, c.rego
$$;

-- Client names for the list on Start (no reference numbers).
create function public.car_client_options()
returns table (id uuid, name text)
language sql
stable
security definer
set search_path = ''
as $$
  select id, name from public.car_clients
   where public.cars_on() and active and public.car_setting('vehicles.client_field', 'optional') <> 'off'
   order by lower(name)
$$;

create function public.start_car_trip(p_car_id uuid, p_purpose_id uuid, p_client_id uuid, p_start_odo int, p_details text default '')
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  c public.cars;
  v_purpose text;
  v_client text := '';
  v_mode text := public.car_setting('vehicles.client_field', 'optional');
  v_id bigint;
begin
  if not public.cars_on() then
    raise exception 'Cars are switched off, or you can''t use them yet';
  end if;
  select * into c from public.cars where id = p_car_id and active for update;
  if c.id is null then
    raise exception 'Choose a car';
  end if;
  if exists (select 1 from public.car_trips where car_id = c.id and returned_at is null) then
    raise exception 'Someone else has this car out. Choose another one.';
  end if;
  if exists (select 1 from public.car_trips where driver_id = auth.uid() and returned_at is null) then
    raise exception 'Return the car you have out first';
  end if;
  select name into v_purpose from public.car_purposes where id = p_purpose_id and active;
  if v_purpose is null then
    raise exception 'Choose the purpose of the trip';
  end if;
  if v_purpose = 'Other' and coalesce(trim(p_details), '') = '' then
    raise exception 'Say what the trip is for';
  end if;
  if v_mode <> 'off' and p_client_id is not null then
    select name into v_client from public.car_clients where id = p_client_id and active;
    if v_client is null then
      raise exception 'Choose a client from the list';
    end if;
  end if;
  if v_mode = 'required' and coalesce(v_client, '') = '' then
    raise exception 'Choose the client';
  end if;
  if p_start_odo is null or p_start_odo < 0 then
    raise exception 'Enter the odometer reading';
  end if;
  if p_start_odo < c.odometer then
    raise exception 'That''s lower than the last reading for this car (% km). Check the dashboard.', c.odometer;
  end if;
  if p_start_odo > c.odometer + 5000 then
    raise exception 'That''s over 5,000 km more than the last reading (% km). Check the dashboard.', c.odometer;
  end if;

  insert into public.car_trips (car_id, driver_id, purpose, details, client_id, client_name, start_odo, gap_km)
  values (c.id, auth.uid(), v_purpose, left(coalesce(trim(p_details), ''), 300),
          case when v_mode <> 'off' then p_client_id end, coalesce(v_client, ''), p_start_odo, p_start_odo - c.odometer)
  returning id into v_id;
  return v_id;
end;
$$;

-- Undo a start (wrong car, pressed too early): the trip is removed.
create function public.undo_car_start(p_trip_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.car_trips;
begin
  select * into t from public.car_trips where id = p_trip_id for update;
  if t.id is null or t.driver_id <> auth.uid() or not public.cars_on() then
    raise exception 'Trip not found';
  end if;
  if t.returned_at is not null then
    raise exception 'This car has been returned. Undo the return first.';
  end if;
  if t.started_at < now() - make_interval(mins => public.car_setting('vehicles.undo_minutes', '10')::int) then
    raise exception 'It''s too late to undo. Return the car instead, or ask a car manager to fix the trip.';
  end if;
  delete from public.car_trips where id = t.id;
  perform public.write_audit('car_start_undone', 'car_trip', t.id::text, to_jsonb(t));
end;
$$;

-- Return a car. A car manager can return it for the driver, with a reason.
create function public.return_car_trip(p_trip_id bigint, p_end_odo int, p_photo_path text default null, p_note text default '')
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.car_trips;
  v_photo text := public.car_setting('vehicles.odo_photo', 'optional');
  v_for_someone boolean;
begin
  select * into t from public.car_trips where id = p_trip_id for update;
  if t.id is null or not public.cars_on() then
    raise exception 'Trip not found';
  end if;
  v_for_someone := t.driver_id <> auth.uid();
  if v_for_someone and not public.can_manage_cars() then
    raise exception 'Trip not found';
  end if;
  if t.returned_at is not null then
    raise exception 'This car has already been returned';
  end if;
  if v_for_someone and coalesce(trim(p_note), '') = '' then
    raise exception 'Say why you''re returning it for them';
  end if;
  if p_end_odo is null then
    raise exception 'Enter the odometer reading';
  end if;
  if p_end_odo < t.start_odo then
    raise exception 'That''s lower than the start reading (% km). Check the dashboard.', t.start_odo;
  end if;
  if p_end_odo > t.start_odo + 3000 then
    raise exception 'That''s over 3,000 km for one trip. Check the reading.';
  end if;
  if p_photo_path is not null and p_photo_path not like t.driver_id::text || '/%' and p_photo_path not like auth.uid()::text || '/%' then
    raise exception 'Upload the photo again';
  end if;
  if v_photo = 'required' and p_photo_path is null and not v_for_someone then
    raise exception 'Add a photo of the odometer';
  end if;

  update public.car_trips
     set returned_at = now(), end_odo = p_end_odo, returned_by = auth.uid(),
         return_note = left(coalesce(trim(p_note), ''), 300),
         odo_photo_path = case when v_photo = 'off' then null else p_photo_path end
   where id = t.id;
  update public.cars set odometer = greatest(odometer, p_end_odo) where id = t.car_id;

  if v_for_someone then
    perform public.notify(t.driver_id, 'car_returned_for_you',
      format('%s returned the %s for you', public.my_name(), (select name from public.cars where id = t.car_id)),
      coalesce(nullif(trim(p_note), ''), ''), '/cars');
    perform public.write_audit('car_returned_for_someone', 'car_trip', t.id::text,
      jsonb_build_object('driver', t.driver_id, 'end_odo', p_end_odo, 'note', p_note));
  end if;
  return p_end_odo - t.start_odo;
end;
$$;

-- Undo a return (wrong reading, pressed too early): the trip is open again.
create function public.undo_car_return(p_trip_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.car_trips;
begin
  select * into t from public.car_trips where id = p_trip_id for update;
  if t.id is null or not public.cars_on() or coalesce(t.returned_by, t.driver_id) <> auth.uid() then
    raise exception 'Trip not found';
  end if;
  if t.returned_at is null then
    raise exception 'This car hasn''t been returned';
  end if;
  if t.returned_at < now() - make_interval(mins => public.car_setting('vehicles.undo_minutes', '10')::int) then
    raise exception 'It''s too late to undo. Ask a car manager to fix the trip.';
  end if;
  if exists (select 1 from public.car_trips where car_id = t.car_id and id <> t.id and started_at > t.started_at) then
    raise exception 'Someone has taken this car since. Ask a car manager to fix the trip.';
  end if;
  if exists (select 1 from public.car_trips where driver_id = t.driver_id and returned_at is null) then
    raise exception 'Return the car you have out first';
  end if;
  update public.car_trips
     set returned_at = null, end_odo = null, returned_by = null, return_note = '', odo_photo_path = null
   where id = t.id;
  update public.cars
     set odometer = greatest(t.start_odo, coalesce((select max(end_odo) from public.car_trips where car_id = t.car_id and id <> t.id), 0))
   where id = t.car_id;
  perform public.write_audit('car_return_undone', 'car_trip', t.id::text, to_jsonb(t));
end;
$$;

-- A car manager fixes a trip after the undo time, with a reason.
create function public.correct_car_trip(p_trip_id bigint, p_start_odo int, p_end_odo int, p_purpose text, p_client_id uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.car_trips;
  n public.car_trips;
  v_client text := '';
begin
  if not public.can_manage_cars() then
    raise exception 'Only car managers can fix trips';
  end if;
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'Say why the trip is being changed';
  end if;
  select * into t from public.car_trips where id = p_trip_id for update;
  if t.id is null then
    raise exception 'Trip not found';
  end if;
  if p_start_odo is null or p_start_odo < 0 or (p_end_odo is not null and p_end_odo < p_start_odo) then
    raise exception 'The end reading can''t be lower than the start';
  end if;
  if (t.returned_at is null) <> (p_end_odo is null) then
    raise exception using message = case when t.returned_at is null then 'Return the car to add an end reading' else 'Enter the end reading' end;
  end if;
  if coalesce(trim(p_purpose), '') = '' then
    raise exception 'Enter the purpose';
  end if;
  if p_client_id is not null then
    select name into v_client from public.car_clients where id = p_client_id;
  end if;
  update public.car_trips
     set start_odo = p_start_odo, end_odo = p_end_odo, purpose = left(trim(p_purpose), 60),
         client_id = p_client_id, client_name = coalesce(v_client, ''), corrected_at = now()
   where id = t.id
  returning * into n;
  update public.cars
     set odometer = greatest(odometer, coalesce(p_end_odo, p_start_odo))
   where id = t.car_id;
  perform public.write_audit('car_trip_corrected', 'car_trip', t.id::text,
    jsonb_build_object('reason', trim(p_reason), 'before', to_jsonb(t), 'after', to_jsonb(n)));
end;
$$;

revoke execute on function public.cars_on() from public, anon;
revoke execute on function public.can_manage_cars() from public, anon;
revoke execute on function public.can_see_car_reports() from public, anon;
revoke execute on function public.car_setting(text, text) from public, anon;
revoke execute on function public.car_board() from public, anon;
revoke execute on function public.car_client_options() from public, anon;
revoke execute on function public.start_car_trip(uuid, uuid, uuid, int, text) from public, anon;
revoke execute on function public.undo_car_start(bigint) from public, anon;
revoke execute on function public.return_car_trip(bigint, int, text, text) from public, anon;
revoke execute on function public.undo_car_return(bigint) from public, anon;
revoke execute on function public.correct_car_trip(bigint, int, int, text, uuid, text) from public, anon;
revoke execute on function public.log_car_setup() from public, anon, authenticated;
grant execute on function public.cars_on(), public.can_manage_cars(), public.can_see_car_reports(), public.car_board(),
  public.car_client_options(), public.start_car_trip(uuid, uuid, uuid, int, text), public.undo_car_start(bigint),
  public.return_car_trip(bigint, int, text, text), public.undo_car_return(bigint),
  public.correct_car_trip(bigint, int, int, text, uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Cars app PIN (checked by the website; never readable from the browser)
-- ---------------------------------------------------------------------------

create table public.car_app_pins (
  user_id     uuid primary key references public.profiles (id) on delete cascade,
  pin_hash    text not null,
  failed      int not null default 0,
  updated_at  timestamptz not null default now()
);
alter table public.car_app_pins enable row level security;
revoke all on public.car_app_pins from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Reminders and the weekly mileage report (run every hour with the others)
-- ---------------------------------------------------------------------------

create function public.car_managers()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select id from public.profiles
   where active and (role = 'system_admin' or role = any (public.setting_roles('vehicles.manager_roles')))
$$;

create function public.run_car_alerts(p_now timestamptz default now())
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tz text := coalesce((select value #>> '{}' from public.app_settings where key = 'region.timezone'), 'Australia/Melbourne');
  v_now timestamp := p_now at time zone v_tz;
  v_today date := v_now::date;
  v_hour int := extract(hour from v_now);
  v_remind_hour int := public.car_setting('vehicles.reminder_hour', '20')::int;
  v_morning int := coalesce((select (value #>> '{}')::int from public.app_settings where key = 'tasks.summary_hour'), 7);
  t record;
  c record;
  v_person uuid;
  v_reminders int := 0;
  v_told int := 0;
  v_cars int := 0;
  v_weekly int := 0;
begin
  if not public.feature_enabled('vehicles') then
    return jsonb_build_object('cars', 'off');
  end if;

  -- The driver, in the evening, if the car is still out.
  if v_hour >= v_remind_hour then
    for t in
      select tr.id, tr.driver_id, ca.name from public.car_trips tr join public.cars ca on ca.id = tr.car_id
       where tr.returned_at is null and tr.reminded_at is null
    loop
      perform public.notify(t.driver_id, 'car_still_out', format('You still have the %s out', t.name),
        'Return it in the Cars app when you''ve finished with it.', '/cars');
      update public.car_trips set reminded_at = p_now where id = t.id;
      v_reminders := v_reminders + 1;
    end loop;
  end if;

  -- Car managers, the next morning, for cars out since before today.
  if v_hour >= v_morning then
    for t in
      select tr.id, tr.driver_id, tr.started_at, ca.name, ca.rego,
             case when p.role = 'system_admin' then 'Admin' else coalesce(nullif(p.full_name, ''), p.email) end driver
        from public.car_trips tr
        join public.cars ca on ca.id = tr.car_id
        join public.profiles p on p.id = tr.driver_id
       where tr.returned_at is null and tr.managers_told_at is null
         and (tr.started_at at time zone v_tz)::date < v_today
    loop
      for v_person in select public.car_managers() loop
        continue when v_person = t.driver_id;
        perform public.notify(v_person, 'car_not_returned',
          format('%s (%s) hasn''t been returned', t.name, t.rego),
          format('%s took it on %s. You can return it for them on the Cars page.', t.driver,
                 to_char(t.started_at at time zone v_tz, 'Dy DD Mon, FMHH12:MI am')),
          '/cars/manage', true);
      end loop;
      update public.car_trips set managers_told_at = p_now where id = t.id;
      v_told := v_told + 1;
    end loop;

    -- Rego expiring within 30 days, and service coming up (by date or within 500 km).
    for c in
      select * from public.cars
       where active and rego_expires is not null and rego_expires <= v_today + 30
         and rego_alerted is distinct from rego_expires
    loop
      for v_person in select public.car_managers() loop
        perform public.notify(v_person, 'car_rego',
          format('Rego for %s (%s) %s %s', c.name, c.rego, case when c.rego_expires < v_today then 'expired on' else 'is due' end,
                 to_char(c.rego_expires, 'FMDD Mon YYYY')),
          'Update the date on the car once it''s renewed.', '/cars/manage', c.rego_expires < v_today);
      end loop;
      update public.cars set rego_alerted = c.rego_expires where id = c.id;
      v_cars := v_cars + 1;
    end loop;
    for c in
      select *, coalesce(service_due_date::text, '') || '/' || coalesce(service_due_km::text, '') as due_key
        from public.cars
       where active and ((service_due_date is not null and service_due_date <= v_today + 14)
                         or (service_due_km is not null and odometer >= service_due_km - 500))
         and service_alerted is distinct from (coalesce(service_due_date::text, '') || '/' || coalesce(service_due_km::text, ''))
    loop
      for v_person in select public.car_managers() loop
        perform public.notify(v_person, 'car_service', format('%s (%s) is due for a service', c.name, c.rego),
          concat_ws(' · ', case when c.service_due_date is not null then 'By ' || to_char(c.service_due_date, 'FMDD Mon YYYY') end,
                    case when c.service_due_km is not null then 'At ' || to_char(c.service_due_km, 'FM999,999,999') || ' km (now ' ||
                         to_char(c.odometer, 'FM999,999,999') || ' km)' end),
          '/cars/manage');
      end loop;
      update public.cars set service_alerted = c.due_key where id = c.id;
      v_cars := v_cars + 1;
    end loop;

    -- Monday: last week's mileage report is ready.
    if extract(isodow from v_today) = 1 then
      insert into public.daily_runs (job, day) values ('car_weekly', v_today) on conflict do nothing;
      if found and exists (select 1 from public.car_trips
                            where (started_at at time zone v_tz)::date between v_today - 7 and v_today - 1) then
        for v_person in
          select id from public.profiles
           where active and (role in ('manager', 'system_admin') or role = any (public.setting_roles('vehicles.report_roles')))
        loop
          perform public.notify(v_person, 'car_weekly',
            format('Mileage report: %s to %s', to_char(v_today - 7, 'FMDD Mon'), to_char(v_today - 1, 'FMDD Mon YYYY')),
            'Last week''s car use and mileage, ready to download.',
            '/reports/cars?from=' || (v_today - 7)::text || '&to=' || (v_today - 1)::text, true);
          v_weekly := v_weekly + 1;
        end loop;
      end if;
    end if;
  end if;

  return jsonb_build_object('car_reminders', v_reminders, 'cars_not_returned', v_told, 'car_notices', v_cars, 'car_weekly', v_weekly);
end;
$$;

revoke execute on function public.car_managers() from public, anon, authenticated;
revoke execute on function public.run_car_alerts(timestamptz) from public, anon, authenticated;
grant execute on function public.run_car_alerts(timestamptz) to service_role;

-- ---------------------------------------------------------------------------
-- Files: car photos (car managers) and odometer photos (the driver)
-- ---------------------------------------------------------------------------

do $storage$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  insert into storage.buckets (id, name, public) values ('car-files', 'car-files', false) on conflict (id) do nothing;
  create policy "drivers upload odometer photos" on storage.objects
    for insert to authenticated
    with check (bucket_id = 'car-files' and public.cars_on() and (storage.foldername(name))[1] = auth.uid()::text);
  create policy "car managers upload car photos" on storage.objects
    for insert to authenticated
    with check (bucket_id = 'car-files' and public.can_manage_cars() and (storage.foldername(name))[1] = 'cars');
  create policy "car files are seen by the driver and car reports" on storage.objects
    for select to authenticated
    using (bucket_id = 'car-files' and public.cars_on()
           and ((storage.foldername(name))[1] in ('cars', auth.uid()::text) or public.can_see_car_reports()));
end;
$storage$;

$m029$;
  insert into public.install_log (name) values ('20261121000001_cars.sql');
end;
$part$;

-- ====================================================================
-- 20261122000001_system_health.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261122000001_system_health.sql') then
    return;
  end if;
  execute $m030$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- System health (cmeprojects, system admin only): how full the database and
-- file storage are for the Supabase plan, whether the hourly timer is
-- running, and whether emails are going out.

insert into public.app_settings (key, value, label, description, is_public) values
  ('system.hosting_plan', '"free"', 'Supabase plan',
   'Free or Pro, so System health shows how full the database and file storage are.', false)
on conflict (key) do nothing;

-- The hourly timer writes here each time it runs (with the service key).
create table public.system_heartbeat (
  job      text primary key,
  ran_at   timestamptz not null default now(),
  ok       boolean not null default true,
  detail   text not null default ''
);
alter table public.system_heartbeat enable row level security;
revoke all on public.system_heartbeat from anon, authenticated;

create function public.system_health()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_files jsonb := '[]'::jsonb;
begin
  if not public.is_system_admin() then
    raise exception 'Only the system admin can see System health' using errcode = 'insufficient_privilege';
  end if;
  -- File storage (Supabase keeps each file's size with it), by bucket.
  if to_regclass('storage.objects') is not null then
    execute $q$select coalesce(jsonb_agg(jsonb_build_object('bucket', bucket_id, 'files', n, 'bytes', b) order by b desc), '[]'::jsonb)
                 from (select bucket_id, count(*) n, coalesce(sum((metadata ->> 'size')::bigint), 0) b
                         from storage.objects group by bucket_id) s$q$
      into v_files;
  end if;
  return jsonb_build_object(
    'database_bytes', pg_database_size(current_database()),
    'files', v_files,
    'people_active', (select count(*) from public.profiles where active and role <> 'system_admin'),
    'people_total', (select count(*) from public.profiles),
    'tasks_open', (select count(*) from public.tasks where status not in ('completed', 'closed')),
    'tasks_total', (select count(*) from public.tasks),
    'trips_total', (select count(*) from public.car_trips),
    'cars_active', (select count(*) from public.cars where active),
    'emails_waiting', (select count(*) from public.email_outbox where sent_at is null and attempts < 5),
    'emails_failed', (select count(*) from public.email_outbox where sent_at is null and attempts >= 5),
    'emails_sent_week', (select count(*) from public.email_outbox where sent_at > now() - interval '7 days'),
    'oldest_waiting', (select min(created_at) from public.email_outbox where sent_at is null and attempts < 5),
    'last_error', (select last_error from public.email_outbox where last_error is not null order by id desc limit 1),
    'timer', (select to_jsonb(h) from public.system_heartbeat h where job = 'hourly')
  );
end;
$$;
revoke all on function public.system_health() from public, anon;
grant execute on function public.system_health() to authenticated;

$m030$;
  insert into public.install_log (name) values ('20261122000001_system_health.sql');
end;
$part$;

-- ====================================================================
-- 20261123000001_compliance_report.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261123000001_compliance_report.sql') then
    return;
  end if;
  execute $m031$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Compliance report (cmeprojects): Reports → Compliance. Staff admins see it;
-- the system admin can let managers see it too.

insert into public.app_settings (key, value, label, description, is_public) values
  ('reports.compliance_roles', '["staff_admin"]', 'Who sees the Compliance report',
   'Besides the system admin. Tick Manager to let managers see it too.', false)
on conflict (key) do nothing;

$m031$;
  insert into public.install_log (name) values ('20261123000001_compliance_report.sql');
end;
$part$;

-- ====================================================================
-- 20261124000001_registers_menu.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261124000001_registers_menu.sql') then
    return;
  end if;
  execute $m032$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Who sees Registers in the menu (cmeprojects). The system admin always does;
-- staff open their own tasks from My tasks either way.

insert into public.app_settings (key, value, label, description, is_public) values
  ('tasks.registers_roles', '["team_leader", "manager", "staff_admin"]', 'Who sees Registers',
   'Besides the system admin. People without it still see and create their own tasks under Tasks.', false)
on conflict (key) do nothing;

$m032$;
  insert into public.install_log (name) values ('20261124000001_registers_menu.sql');
end;
$part$;

-- ====================================================================
-- 20261125000001_premium_features.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261125000001_premium_features.sql') then
    return;
  end if;
  execute $m033$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Premium features (cmeprojects). Some features are paid add-ons, marked
-- Premium. The system admin (cmeproject) switches them on for a company that
-- has them in its plan; nobody else can. Cars is the first.

alter table public.features add column if not exists premium boolean not null default false;
alter table public.features add column if not exists included boolean not null default true;
update public.features set premium = true where key = 'vehicles';

-- A feature only works if it's switched on and included in the plan.
create or replace function public.feature_enabled(p_key text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select enabled and included from public.features where key = p_key), false)
$$;

-- Only the system admin decides what's included (from System settings →
-- Features, or the SQL Editor); no one else can change it.
create or replace function public.guard_feature_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.is_system_admin()
     and (new.premium is distinct from old.premium or new.included is distinct from old.included) then
    raise exception 'Only the system admin can change what''s included in the plan';
  end if;
  if new.enabled and not new.included and not old.enabled then
    raise exception '% isn''t included in the plan.', new.label;
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_feature_change() from public, anon, authenticated;

drop trigger if exists features_guard on public.features;
create trigger features_guard before update on public.features for each row execute function public.guard_feature_change();

$m033$;
  insert into public.install_log (name) values ('20261125000001_premium_features.sql');
end;
$part$;

-- ====================================================================
-- 20261126000001_weekly_recipients.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261126000001_weekly_recipients.sql') then
    return;
  end if;
  execute $m034$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Weekly mileage report recipients (cmeprojects): the system admin ticks which
-- managers get Monday's report (bell, and email once emails are set up).
-- To start with, every current manager is ticked.

insert into public.app_settings (key, value, label, description, is_public)
select 'vehicles.weekly_recipients',
       coalesce((select jsonb_agg(id order by full_name) from public.profiles where active and role = 'manager'), '[]'::jsonb),
       'Who gets the weekly mileage report',
       'Every Monday morning: last week''s car use and mileage, by bell and email. Tick the managers who should get it.',
       false
on conflict (key) do nothing;

create or replace function public.run_car_alerts(p_now timestamptz default now())
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tz text := coalesce((select value #>> '{}' from public.app_settings where key = 'region.timezone'), 'Australia/Melbourne');
  v_now timestamp := p_now at time zone v_tz;
  v_today date := v_now::date;
  v_hour int := extract(hour from v_now);
  v_remind_hour int := public.car_setting('vehicles.reminder_hour', '20')::int;
  v_morning int := coalesce((select (value #>> '{}')::int from public.app_settings where key = 'tasks.summary_hour'), 7);
  t record;
  c record;
  v_person uuid;
  v_reminders int := 0;
  v_told int := 0;
  v_cars int := 0;
  v_weekly int := 0;
begin
  if not public.feature_enabled('vehicles') then
    return jsonb_build_object('cars', 'off');
  end if;

  -- The driver, in the evening, if the car is still out.
  if v_hour >= v_remind_hour then
    for t in
      select tr.id, tr.driver_id, ca.name from public.car_trips tr join public.cars ca on ca.id = tr.car_id
       where tr.returned_at is null and tr.reminded_at is null
    loop
      perform public.notify(t.driver_id, 'car_still_out', format('You still have the %s out', t.name),
        'Return it in the Cars app when you''ve finished with it.', '/cars');
      update public.car_trips set reminded_at = p_now where id = t.id;
      v_reminders := v_reminders + 1;
    end loop;
  end if;

  -- Car managers, the next morning, for cars out since before today.
  if v_hour >= v_morning then
    for t in
      select tr.id, tr.driver_id, tr.started_at, ca.name, ca.rego,
             case when p.role = 'system_admin' then 'Admin' else coalesce(nullif(p.full_name, ''), p.email) end driver
        from public.car_trips tr
        join public.cars ca on ca.id = tr.car_id
        join public.profiles p on p.id = tr.driver_id
       where tr.returned_at is null and tr.managers_told_at is null
         and (tr.started_at at time zone v_tz)::date < v_today
    loop
      for v_person in select public.car_managers() loop
        continue when v_person = t.driver_id;
        perform public.notify(v_person, 'car_not_returned',
          format('%s (%s) hasn''t been returned', t.name, t.rego),
          format('%s took it on %s. You can return it for them on the Cars page.', t.driver,
                 to_char(t.started_at at time zone v_tz, 'Dy DD Mon, FMHH12:MI am')),
          '/cars/manage', true);
      end loop;
      update public.car_trips set managers_told_at = p_now where id = t.id;
      v_told := v_told + 1;
    end loop;

    -- Rego expiring within 30 days, and service coming up (by date or within 500 km).
    for c in
      select * from public.cars
       where active and rego_expires is not null and rego_expires <= v_today + 30
         and rego_alerted is distinct from rego_expires
    loop
      for v_person in select public.car_managers() loop
        perform public.notify(v_person, 'car_rego',
          format('Rego for %s (%s) %s %s', c.name, c.rego, case when c.rego_expires < v_today then 'expired on' else 'is due' end,
                 to_char(c.rego_expires, 'FMDD Mon YYYY')),
          'Update the date on the car once it''s renewed.', '/cars/manage', c.rego_expires < v_today);
      end loop;
      update public.cars set rego_alerted = c.rego_expires where id = c.id;
      v_cars := v_cars + 1;
    end loop;
    for c in
      select *, coalesce(service_due_date::text, '') || '/' || coalesce(service_due_km::text, '') as due_key
        from public.cars
       where active and ((service_due_date is not null and service_due_date <= v_today + 14)
                         or (service_due_km is not null and odometer >= service_due_km - 500))
         and service_alerted is distinct from (coalesce(service_due_date::text, '') || '/' || coalesce(service_due_km::text, ''))
    loop
      for v_person in select public.car_managers() loop
        perform public.notify(v_person, 'car_service', format('%s (%s) is due for a service', c.name, c.rego),
          concat_ws(' · ', case when c.service_due_date is not null then 'By ' || to_char(c.service_due_date, 'FMDD Mon YYYY') end,
                    case when c.service_due_km is not null then 'At ' || to_char(c.service_due_km, 'FM999,999,999') || ' km (now ' ||
                         to_char(c.odometer, 'FM999,999,999') || ' km)' end),
          '/cars/manage');
      end loop;
      update public.cars set service_alerted = c.due_key where id = c.id;
      v_cars := v_cars + 1;
    end loop;

    -- Monday: last week's mileage report is ready.
    if extract(isodow from v_today) = 1 then
      insert into public.daily_runs (job, day) values ('car_weekly', v_today) on conflict do nothing;
      if found and exists (select 1 from public.car_trips
                            where (started_at at time zone v_tz)::date between v_today - 7 and v_today - 1) then
        -- Only the people the system admin chose (System settings → Cars).
        for v_person in
          select p.id from public.profiles p
           where p.active
             and p.id::text in (select jsonb_array_elements_text(s.value) from public.app_settings s
                                 where s.key = 'vehicles.weekly_recipients' and jsonb_typeof(s.value) = 'array')
        loop
          perform public.notify(v_person, 'car_weekly',
            format('Mileage report: %s to %s', to_char(v_today - 7, 'FMDD Mon'), to_char(v_today - 1, 'FMDD Mon YYYY')),
            'Last week''s car use and mileage, ready to download.',
            '/reports/cars?from=' || (v_today - 7)::text || '&to=' || (v_today - 1)::text, true);
          v_weekly := v_weekly + 1;
        end loop;
      end if;
    end if;
  end if;

  return jsonb_build_object('car_reminders', v_reminders, 'cars_not_returned', v_told, 'car_notices', v_cars, 'car_weekly', v_weekly);
end;
$$;

revoke execute on function public.run_car_alerts(timestamptz) from public, anon, authenticated;
grant execute on function public.run_car_alerts(timestamptz) to service_role;

$m034$;
  insert into public.install_log (name) values ('20261126000001_weekly_recipients.sql');
end;
$part$;

-- ====================================================================
-- 20261127000001_sign_in_help.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261127000001_sign_in_help.sql') then
    return;
  end if;
  execute $m035$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Helping someone sign in (cmeprojects): on Staff & roles, the system admin
-- (and the roles they choose) can email a person a password reset link,
-- reset their two-factor login, and clear their Cars app PIN. No one can do
-- this for themselves here, and only the system admin can do it for a
-- system admin. Password reset emails are limited to one every 2 minutes per
-- address.

insert into public.app_settings (key, value, label, description, is_public) values
  ('people.access_reset_roles', '[]', 'Who can help staff sign in',
   'Besides the system admin: send a password reset link, reset two-factor login and clear the Cars app PIN (on Staff & roles).', false)
on conflict (key) do nothing;

create or replace function public.can_help_sign_in(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.mfa_ok()
     and p_user is distinct from auth.uid()
     and exists (select 1 from public.profiles where id = p_user)
     and (public.my_role() = 'system_admin'
          or (public.my_role() = any (public.setting_roles('people.access_reset_roles'))
              and (select role from public.profiles where id = p_user) <> 'system_admin'))
$$;
revoke execute on function public.can_help_sign_in(uuid) from public, anon;
grant execute on function public.can_help_sign_in(uuid) to authenticated;

create or replace function public.log_admin_action(p_action text, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_action in ('mfa_reset', 'password_reset_sent', 'pin_cleared') then
    if not public.can_help_sign_in(p_user_id) then
      raise exception 'You can''t do this for them. Ask the system admin.';
    end if;
  elsif p_action <> 'invite_resent' or not public.can_manage_people() then
    raise exception 'Not allowed';
  end if;
  perform public.write_audit(p_action, 'profile', p_user_id::text, '{}'::jsonb);
end;
$$;

-- When password reset emails were last sent (by the website, with the service key).
create table if not exists public.email_throttle (
  key     text primary key,
  sent_at timestamptz not null default now()
);
alter table public.email_throttle enable row level security;
revoke all on public.email_throttle from anon, authenticated;

$m035$;
  insert into public.install_log (name) values ('20261127000001_sign_in_help.sql');
end;
$part$;

-- ====================================================================
-- 20261128000001_feature_builder.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261128000001_feature_builder.sql') then
    return;
  end if;
  execute $m036$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Feature builder (cmeprojects). The system admin builds features (for
-- example a Fluid intake chart): a form of fields staff fill in, recorded with
-- the date, time and the signed-in person. A feature is a draft until it's
-- published, and each one is a premium add-on the system admin includes in
-- the company's package or not. Entries are never deleted (staff can undo
-- their own for a few minutes); switching a feature off hides it and keeps
-- its entries.
--
-- The client list (car_clients) becomes the company's client list for every
-- feature, managed by managers, staff admins and the system admin.

-- ---------------------------------------------------------------------------
-- Clients for everyone
-- ---------------------------------------------------------------------------

create or replace function public.client_options()
returns table (id uuid, name text)
language sql
stable
security definer
set search_path = ''
as $$
  select id, name from public.car_clients
   where public.is_member() and public.my_role() <> 'new_starter' and active
   order by lower(name)
$$;
revoke execute on function public.client_options() from public, anon;
grant execute on function public.client_options() to authenticated;

drop policy if exists "people managers see clients" on public.car_clients;
create policy "people managers see clients" on public.car_clients for select to authenticated using (public.can_manage_people());
drop policy if exists "people managers add clients" on public.car_clients;
create policy "people managers add clients" on public.car_clients for insert to authenticated with check (public.can_manage_people());
drop policy if exists "people managers change clients" on public.car_clients;
create policy "people managers change clients" on public.car_clients for update to authenticated
  using (public.can_manage_people()) with check (public.can_manage_people());

-- ---------------------------------------------------------------------------
-- Features, fields, entries and targets
-- ---------------------------------------------------------------------------

create table if not exists public.custom_features (
  id             uuid primary key default gen_random_uuid(),
  org_id         uuid not null default public.default_org_id() references public.organisation (id),
  slug           text not null unique check (slug ~ '^[a-z0-9][a-z0-9-]{1,39}$'),
  name           text not null check (length(trim(name)) between 1 and 60),
  menu_label     text not null check (length(trim(menu_label)) between 1 and 30),
  description    text not null default '' check (length(description) <= 300),
  status         text not null default 'draft' check (status in ('draft', 'published')),
  -- In this company's package (premium add-on).
  enabled        boolean not null default true,
  fill_roles     public.app_role[] not null default '{support_worker,team_leader}',
  see_roles      public.app_role[] not null default '{team_leader,manager}',
  undo_minutes   int not null default 10 check (undo_minutes between 0 and 1440),
  record_team    boolean not null default true,
  -- Daily totals: add up this number field, per this client field.
  total_field    uuid,
  group_field    uuid,
  default_target numeric check (default_target is null or default_target >= 0),
  sort_order     int not null default 100,
  created_by     uuid references public.profiles (id) default auth.uid(),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  published_at   timestamptz
);

create table if not exists public.custom_fields (
  id          uuid primary key default gen_random_uuid(),
  feature_id  uuid not null references public.custom_features (id) on delete cascade,
  label       text not null check (length(trim(label)) between 1 and 80),
  type        text not null check (type in ('text', 'long', 'number', 'choice', 'multi', 'yesno', 'date', 'time', 'client', 'staff', 'photo')),
  required    boolean not null default false,
  help        text not null default '' check (length(help) <= 200),
  unit        text not null default '' check (length(unit) <= 12),
  min_value   numeric,
  max_value   numeric,
  options     jsonb not null default '[]' check (jsonb_typeof(options) = 'array'),
  allow_other boolean not null default false,
  quick       jsonb not null default '[]' check (jsonb_typeof(quick) = 'array'),
  sort_order  int not null default 0,
  -- Removed from the form; old entries keep their answers.
  archived    boolean not null default false,
  created_at  timestamptz not null default now()
);
create index if not exists custom_fields_feature on public.custom_fields (feature_id, sort_order);

create table if not exists public.custom_entries (
  id           bigint generated always as identity primary key,
  org_id       uuid not null default public.default_org_id() references public.organisation (id),
  feature_id   uuid not null references public.custom_features (id),
  data         jsonb not null default '{}' check (jsonb_typeof(data) = 'object'),
  client_id    uuid references public.car_clients (id),
  client_name  text not null default '',
  team_names   text not null default '',
  created_by   uuid not null references public.profiles (id) default auth.uid(),
  created_at   timestamptz not null default now(),
  corrected_at timestamptz
);
create index if not exists custom_entries_feature on public.custom_entries (feature_id, created_at desc);
create index if not exists custom_entries_client on public.custom_entries (feature_id, client_id, created_at desc);

-- A daily target for each client (e.g. 1,500 ml), or the feature's default.
create table if not exists public.custom_client_targets (
  feature_id uuid not null references public.custom_features (id) on delete cascade,
  client_id  uuid not null references public.car_clients (id) on delete cascade,
  target     numeric not null check (target >= 0),
  primary key (feature_id, client_id)
);

-- ---------------------------------------------------------------------------
-- Who can do what
-- ---------------------------------------------------------------------------

create or replace function public.can_build_features()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_system_admin() and public.mfa_ok()
$$;

create or replace function public.custom_feature_live(p_feature uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select status = 'published' and enabled from public.custom_features where id = p_feature), false)
$$;

create or replace function public.can_fill_feature(p_feature uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and public.custom_feature_live(p_feature)
     and (public.my_role() = 'system_admin'
          or exists (select 1 from public.custom_features where id = p_feature and public.my_role() = any (fill_roles)))
$$;

create or replace function public.can_see_feature(p_feature uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and public.custom_feature_live(p_feature)
     and (public.my_role() = 'system_admin'
          or exists (select 1 from public.custom_features where id = p_feature and public.my_role() = any (see_roles)))
$$;

-- Your own entries; everyone's for those who see the feature (team leaders:
-- the people in the team they lead); all of them for the builder.
create or replace function public.sees_custom_entry(p_feature uuid, p_by uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_by = auth.uid()
      or public.can_build_features()
      or (public.can_see_feature(p_feature) and (public.my_role() <> 'team_leader' or public.leads_user(p_by)))
$$;

alter table public.custom_features enable row level security;
alter table public.custom_fields enable row level security;
alter table public.custom_entries enable row level security;
alter table public.custom_client_targets enable row level security;

drop policy if exists "staff see live features, the builder sees all" on public.custom_features;
create policy "staff see live features, the builder sees all" on public.custom_features for select to authenticated
  using (public.can_build_features() or (public.is_member() and status = 'published' and enabled));
drop policy if exists "the builder adds features" on public.custom_features;
create policy "the builder adds features" on public.custom_features for insert to authenticated with check (public.can_build_features());
drop policy if exists "the builder changes features" on public.custom_features;
create policy "the builder changes features" on public.custom_features for update to authenticated
  using (public.can_build_features()) with check (public.can_build_features());
drop policy if exists "the builder removes unused drafts" on public.custom_features;
create policy "the builder removes unused drafts" on public.custom_features for delete to authenticated
  using (public.can_build_features() and status = 'draft'
         and not exists (select 1 from public.custom_entries e where e.feature_id = custom_features.id));

drop policy if exists "fields follow their feature" on public.custom_fields;
create policy "fields follow their feature" on public.custom_fields for select to authenticated
  using (public.can_build_features() or (public.is_member() and public.custom_feature_live(feature_id)));
drop policy if exists "the builder adds fields" on public.custom_fields;
create policy "the builder adds fields" on public.custom_fields for insert to authenticated with check (public.can_build_features());
drop policy if exists "the builder changes fields" on public.custom_fields;
create policy "the builder changes fields" on public.custom_fields for update to authenticated
  using (public.can_build_features()) with check (public.can_build_features());
drop policy if exists "the builder removes unused fields" on public.custom_fields;
create policy "the builder removes unused fields" on public.custom_fields for delete to authenticated
  using (public.can_build_features()
         and not exists (select 1 from public.custom_entries e where e.feature_id = custom_fields.feature_id and e.data ? custom_fields.id::text));

drop policy if exists "entries are seen by who may see them" on public.custom_entries;
create policy "entries are seen by who may see them" on public.custom_entries for select to authenticated
  using (public.sees_custom_entry(feature_id, created_by));
-- Entries change only through the functions below.
revoke insert, update, delete, truncate on public.custom_entries from anon, authenticated;

drop policy if exists "targets follow their feature" on public.custom_client_targets;
create policy "targets follow their feature" on public.custom_client_targets for select to authenticated
  using (public.can_build_features() or (public.is_member() and public.custom_feature_live(feature_id)));
drop policy if exists "the builder sets targets" on public.custom_client_targets;
create policy "the builder sets targets" on public.custom_client_targets for all to authenticated
  using (public.can_build_features()) with check (public.can_build_features());

-- Changes to features and fields go in the change log.
create or replace function public.log_feature_setup()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.write_audit(
    lower(tg_op) || '_' || tg_argv[0], tg_argv[0],
    coalesce(new.id, old.id)::text,
    case when tg_op = 'UPDATE' then jsonb_build_object('before', to_jsonb(old), 'after', to_jsonb(new))
         else to_jsonb(coalesce(new, old)) end);
  return coalesce(new, old);
end;
$$;
revoke execute on function public.log_feature_setup() from public, anon, authenticated;

drop trigger if exists custom_features_log on public.custom_features;
create trigger custom_features_log after insert or update or delete on public.custom_features
  for each row execute function public.log_feature_setup('custom_feature');
drop trigger if exists custom_fields_log on public.custom_fields;
create trigger custom_fields_log after insert or update or delete on public.custom_fields
  for each row execute function public.log_feature_setup('custom_field');

-- ---------------------------------------------------------------------------
-- Filling in and undoing
-- ---------------------------------------------------------------------------

create or replace function public.submit_custom_entry(p_feature uuid, p_data jsonb)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  f record;
  v text;
  n numeric;
  v_clean jsonb := '{}'::jsonb;
  v_client uuid;
  v_client_name text := '';
  v_id bigint;
begin
  if not public.can_fill_feature(p_feature) then
    raise exception 'You can''t fill this in';
  end if;
  if p_data is null or jsonb_typeof(p_data) <> 'object' then
    raise exception 'Fill in the form';
  end if;

  for f in select * from public.custom_fields where feature_id = p_feature and not archived order by sort_order loop
    if f.type = 'multi' then
      if jsonb_typeof(p_data -> f.id::text) = 'array' and jsonb_array_length(p_data -> f.id::text) > 0 then
        if not f.allow_other and exists (select 1 from jsonb_array_elements_text(p_data -> f.id::text) x where not f.options ? x) then
          raise exception '%: choose from the list', f.label;
        end if;
        v_clean := v_clean || jsonb_build_object(f.id::text, p_data -> f.id::text);
      elsif f.required then
        raise exception '%: choose at least one', f.label;
      end if;
      continue;
    end if;

    v := nullif(trim(p_data ->> f.id::text), '');
    if v is null then
      if f.required then
        raise exception '%: this is needed', f.label;
      end if;
      continue;
    end if;
    if length(v) > (case when f.type = 'long' then 2000 else 200 end) then
      raise exception '%: that''s too long', f.label;
    end if;

    case f.type
      when 'number' then
        begin
          n := v::numeric;
        exception when others then
          raise exception '%: enter a number', f.label;
        end;
        if f.min_value is not null and n < f.min_value then
          raise exception '%: the smallest allowed is %', f.label, f.min_value;
        end if;
        if f.max_value is not null and n > f.max_value then
          raise exception '%: the largest allowed is %', f.label, f.max_value;
        end if;
        v_clean := v_clean || jsonb_build_object(f.id::text, n);
        continue;
      when 'choice' then
        if not f.allow_other and not f.options ? v then
          raise exception '%: choose from the list', f.label;
        end if;
      when 'yesno' then
        if v not in ('Yes', 'No') then
          raise exception '%: choose Yes or No', f.label;
        end if;
      when 'date' then
        if v !~ '^\d{4}-\d{2}-\d{2}$' then
          raise exception '%: enter a date', f.label;
        end if;
      when 'time' then
        if v !~ '^\d{2}:\d{2}$' then
          raise exception '%: enter a time', f.label;
        end if;
      when 'client' then
        select id, name into v_client, v_client_name from public.car_clients where id::text = v and active;
        if v_client is null then
          raise exception '%: choose from the list', f.label;
        end if;
      when 'staff' then
        if not exists (select 1 from public.profiles where id::text = v and active) then
          raise exception '%: choose from the list', f.label;
        end if;
      when 'photo' then
        if v not like auth.uid()::text || '/%' then
          raise exception '%: upload the photo again', f.label;
        end if;
      else
        null;
    end case;
    v_clean := v_clean || jsonb_build_object(f.id::text, v);
  end loop;

  insert into public.custom_entries (feature_id, data, client_id, client_name, team_names)
  values (p_feature, v_clean, v_client, coalesce(v_client_name, ''),
          case when (select record_team from public.custom_features where id = p_feature)
               then coalesce((select string_agg(t.name, ', ' order by t.name) from public.team_members m join public.teams t on t.id = m.team_id
                               where m.user_id = auth.uid()), '')
               else '' end)
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.undo_custom_entry(p_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  e public.custom_entries;
begin
  select * into e from public.custom_entries where id = p_id for update;
  if e.id is null or e.created_by <> auth.uid() then
    raise exception 'Entry not found';
  end if;
  if e.created_at < now() - make_interval(mins => (select undo_minutes from public.custom_features where id = e.feature_id)) then
    raise exception 'It''s too late to undo. Ask a manager to fix it.';
  end if;
  delete from public.custom_entries where id = e.id;
  perform public.write_audit('custom_entry_undone', 'custom_entry', e.id::text, to_jsonb(e));
end;
$$;

-- Today's entries for one client (from everyone), for the "today so far" box
-- staff see after saving, so they know the client's total, not only their own.
create or replace function public.custom_client_today(p_feature uuid, p_client uuid)
returns table (id bigint, created_at timestamptz, data jsonb, by_name text, mine boolean)
language sql
stable
security definer
set search_path = ''
as $$
  select e.id, e.created_at, e.data, split_part(coalesce(nullif(p.full_name, ''), p.email), ' ', 1), e.created_by = auth.uid()
    from public.custom_entries e
    join public.profiles p on p.id = e.created_by
   where e.feature_id = p_feature and e.client_id = p_client
     and (public.can_fill_feature(p_feature) or public.can_see_feature(p_feature))
     and (e.created_at at time zone coalesce((select value #>> '{}' from public.app_settings where key = 'region.timezone'), 'Australia/Melbourne'))::date
         = public.local_today()
   order by e.created_at desc
$$;
revoke execute on function public.custom_client_today(uuid, uuid) from public, anon;
grant execute on function public.custom_client_today(uuid, uuid) to authenticated;

revoke execute on function public.can_build_features(), public.custom_feature_live(uuid), public.can_fill_feature(uuid),
  public.can_see_feature(uuid), public.sees_custom_entry(uuid, uuid), public.submit_custom_entry(uuid, jsonb),
  public.undo_custom_entry(bigint) from public, anon;
grant execute on function public.can_build_features(), public.custom_feature_live(uuid), public.can_fill_feature(uuid),
  public.can_see_feature(uuid), public.sees_custom_entry(uuid, uuid), public.submit_custom_entry(uuid, jsonb),
  public.undo_custom_entry(bigint) to authenticated;

-- ---------------------------------------------------------------------------
-- Photos on entries
-- ---------------------------------------------------------------------------

do $storage$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  insert into storage.buckets (id, name, public) values ('feature-files', 'feature-files', false) on conflict (id) do nothing;
  drop policy if exists "staff upload feature photos" on storage.objects;
  create policy "staff upload feature photos" on storage.objects
    for insert to authenticated
    with check (bucket_id = 'feature-files' and public.is_member() and (storage.foldername(name))[1] = auth.uid()::text);
  drop policy if exists "feature photos are seen with their entries" on storage.objects;
  create policy "feature photos are seen with their entries" on storage.objects
    for select to authenticated
    using (bucket_id = 'feature-files' and public.is_member()
           and ((storage.foldername(name))[1] = auth.uid()::text
                or exists (select 1 from public.custom_entries e
                            where e.data::text like '%' || storage.objects.name || '%'
                              and public.sees_custom_entry(e.feature_id, e.created_by))));
end;
$storage$;

$m036$;
  insert into public.install_log (name) values ('20261128000001_feature_builder.sql');
end;
$part$;

-- ====================================================================
-- 20261129000001_feature_manager_rights.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261129000001_feature_manager_rights.sql') then
    return;
  end if;
  execute $m037$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Feature builder (cmeprojects): what managers may change. For each feature
-- the system admin ticks whether managers can
--   * fix entries (after the undo time, with a reason; the change log keeps
--     the before and after),
--   * set each client's daily target, and
--   * change the drop-down options.
-- Plus, per drop-down: an answer staff type that isn't in the list joins the
-- list for everyone next time.

alter table public.custom_features add column if not exists managers_fix boolean not null default false;
alter table public.custom_features add column if not exists managers_targets boolean not null default false;
alter table public.custom_features add column if not exists managers_options boolean not null default false;
alter table public.custom_fields add column if not exists add_typed boolean not null default false;
alter table public.custom_entries add column if not exists corrected_by uuid references public.profiles (id);
alter table public.custom_entries add column if not exists correction_reason text not null default '';

-- The system admin always; managers when the feature allows it.
create or replace function public.can_manage_feature(p_feature uuid, p_what text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.can_build_features()
      or (public.is_member() and public.mfa_ok() and public.my_role() = 'manager' and public.custom_feature_live(p_feature)
          and exists (select 1 from public.custom_features
                       where id = p_feature
                         and case p_what when 'fix' then managers_fix when 'targets' then managers_targets
                                         when 'options' then managers_options else false end))
$$;

-- Managers who fix entries see them all.
create or replace function public.sees_custom_entry(p_feature uuid, p_by uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_by = auth.uid()
      or public.can_build_features()
      or public.can_manage_feature(p_feature, 'fix')
      or (public.can_see_feature(p_feature) and (public.my_role() <> 'team_leader' or public.leads_user(p_by)))
$$;

-- Checks every answer and returns the cleaned entry. p_old is the entry being
-- fixed (its photos are kept as they are). Typed answers join the list when
-- the field says so.
create or replace function public.clean_custom_entry(p_feature uuid, p_data jsonb, p_old jsonb default null)
returns table (clean jsonb, client_id uuid, client_name text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  f record;
  v text;
  n numeric;
  v_clean jsonb := '{}'::jsonb;
  v_client uuid;
  v_client_name text := '';
  v_new text[];
begin
  if p_data is null or jsonb_typeof(p_data) <> 'object' then
    raise exception 'Fill in the form';
  end if;

  for f in select * from public.custom_fields where feature_id = p_feature and not archived order by sort_order loop
    if f.type = 'multi' then
      if jsonb_typeof(p_data -> f.id::text) = 'array' and jsonb_array_length(p_data -> f.id::text) > 0 then
        select array_agg(x) into v_new from jsonb_array_elements_text(p_data -> f.id::text) x where not f.options ? x;
        if v_new is not null and not f.allow_other then
          raise exception '%: choose from the list', f.label;
        end if;
        if v_new is not null and f.add_typed then
          update public.custom_fields
             set options = options || (select coalesce(jsonb_agg(t), '[]') from unnest(v_new) t
                                         where length(trim(t)) between 1 and 80
                                           and not exists (select 1 from jsonb_array_elements_text(options) o where lower(o) = lower(trim(t))))
           where id = f.id and jsonb_array_length(options) < 60;
        end if;
        v_clean := v_clean || jsonb_build_object(f.id::text, p_data -> f.id::text);
      elsif f.required then
        raise exception '%: choose at least one', f.label;
      end if;
      continue;
    end if;

    v := nullif(trim(p_data ->> f.id::text), '');
    if v is null then
      if f.required then
        raise exception '%: this is needed', f.label;
      end if;
      continue;
    end if;
    if length(v) > (case when f.type = 'long' then 2000 else 200 end) then
      raise exception '%: that''s too long', f.label;
    end if;

    case f.type
      when 'number' then
        begin
          n := v::numeric;
        exception when others then
          raise exception '%: enter a number', f.label;
        end;
        if f.min_value is not null and n < f.min_value then
          raise exception '%: the smallest allowed is %', f.label, f.min_value;
        end if;
        if f.max_value is not null and n > f.max_value then
          raise exception '%: the largest allowed is %', f.label, f.max_value;
        end if;
        v_clean := v_clean || jsonb_build_object(f.id::text, n);
        continue;
      when 'choice' then
        if not f.options ? v then
          if not f.allow_other then
            raise exception '%: choose from the list', f.label;
          end if;
          if f.add_typed and length(v) <= 80 then
            update public.custom_fields set options = options || to_jsonb(v)
             where id = f.id and jsonb_array_length(options) < 60
               and not exists (select 1 from jsonb_array_elements_text(options) o where lower(o) = lower(v));
          end if;
        end if;
      when 'yesno' then
        if v not in ('Yes', 'No') then
          raise exception '%: choose Yes or No', f.label;
        end if;
      when 'date' then
        if v !~ '^\d{4}-\d{2}-\d{2}$' then
          raise exception '%: enter a date', f.label;
        end if;
      when 'time' then
        if v !~ '^\d{2}:\d{2}$' then
          raise exception '%: enter a time', f.label;
        end if;
      when 'client' then
        select c.id, c.name into v_client, v_client_name from public.car_clients c where c.id::text = v and c.active;
        if v_client is null then
          raise exception '%: choose from the list', f.label;
        end if;
      when 'staff' then
        if not exists (select 1 from public.profiles where id::text = v and active) then
          raise exception '%: choose from the list', f.label;
        end if;
      when 'photo' then
        if v not like auth.uid()::text || '/%' and v is distinct from (p_old ->> f.id::text) then
          raise exception '%: upload the photo again', f.label;
        end if;
      else
        null;
    end case;
    v_clean := v_clean || jsonb_build_object(f.id::text, v);
  end loop;

  return query select v_clean, v_client, coalesce(v_client_name, '');
end;
$$;
revoke execute on function public.clean_custom_entry(uuid, jsonb, jsonb) from public, anon, authenticated;

create or replace function public.submit_custom_entry(p_feature uuid, p_data jsonb)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  c record;
  v_id bigint;
begin
  if not public.can_fill_feature(p_feature) then
    raise exception 'You can''t fill this in';
  end if;
  select * into c from public.clean_custom_entry(p_feature, p_data);

  insert into public.custom_entries (feature_id, data, client_id, client_name, team_names)
  values (p_feature, c.clean, c.client_id, c.client_name,
          case when (select record_team from public.custom_features where id = p_feature)
               then coalesce((select string_agg(t.name, ', ' order by t.name) from public.team_members m join public.teams t on t.id = m.team_id
                               where m.user_id = auth.uid()), '')
               else '' end)
  returning id into v_id;
  return v_id;
end;
$$;

-- Fix an entry: the new answers are checked like a new one, and the change
-- log keeps what it was, what it is now, and why.
create or replace function public.correct_custom_entry(p_id bigint, p_data jsonb, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  e public.custom_entries;
  c record;
begin
  select * into e from public.custom_entries where id = p_id for update;
  if e.id is null or not public.can_manage_feature(e.feature_id, 'fix') then
    raise exception 'You can''t fix this entry';
  end if;
  if length(trim(coalesce(p_reason, ''))) < 3 then
    raise exception 'Say why it''s being changed';
  end if;
  select * into c from public.clean_custom_entry(e.feature_id, p_data, e.data);
  if c.clean = e.data then
    raise exception 'Nothing was changed';
  end if;
  update public.custom_entries
     set data = c.clean, client_id = c.client_id, client_name = c.client_name,
         corrected_at = now(), corrected_by = auth.uid(), correction_reason = left(trim(p_reason), 300)
   where id = e.id;
  perform public.write_audit('custom_entry_fixed', 'custom_entry', e.id::text,
    jsonb_build_object('before', e.data, 'after', c.clean, 'reason', left(trim(p_reason), 300)));
end;
$$;

-- Daily targets: the default for everyone and each client's own.
-- p_targets is {client id: target or null}; null takes a client's own target away.
create or replace function public.set_custom_targets(p_feature uuid, p_default numeric, p_targets jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  k text;
  v jsonb;
begin
  if not public.can_manage_feature(p_feature, 'targets') then
    raise exception 'You can''t change these targets';
  end if;
  if p_default is not null and p_default < 0 then
    raise exception 'A target can''t be below zero';
  end if;
  update public.custom_features set default_target = p_default where id = p_feature;
  for k, v in select * from jsonb_each(coalesce(p_targets, '{}')) loop
    if jsonb_typeof(v) = 'number' and (v #>> '{}')::numeric >= 0 then
      insert into public.custom_client_targets (feature_id, client_id, target)
      select p_feature, id, (v #>> '{}')::numeric from public.car_clients where id::text = k
      on conflict (feature_id, client_id) do update set target = excluded.target;
    else
      delete from public.custom_client_targets where feature_id = p_feature and client_id::text = k;
    end if;
  end loop;
  perform public.write_audit('custom_targets_set', 'custom_feature', p_feature::text,
    jsonb_build_object('default', p_default, 'targets', p_targets));
end;
$$;

-- A drop-down's options (managers when allowed; the change log keeps the old list).
create or replace function public.set_custom_field_options(p_field uuid, p_options jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  f public.custom_fields;
  v_list jsonb;
begin
  select * into f from public.custom_fields where id = p_field and not archived;
  if f.id is null or f.type not in ('choice', 'multi') or not public.can_manage_feature(f.feature_id, 'options') then
    raise exception 'You can''t change this list';
  end if;
  if jsonb_typeof(p_options) <> 'array' then
    raise exception 'Give a list of options';
  end if;
  select coalesce(jsonb_agg(o order by n), '[]') into v_list
    from (select distinct on (lower(trim(x))) trim(x) o, n
            from jsonb_array_elements_text(p_options) with ordinality t(x, n)
           where length(trim(x)) between 1 and 80
           order by lower(trim(x)), n) d;
  if jsonb_array_length(v_list) > 60 then
    raise exception 'Keep the list to 60 options';
  end if;
  if jsonb_array_length(v_list) = 0 and not f.allow_other then
    raise exception 'Keep at least one option';
  end if;
  update public.custom_fields set options = v_list where id = f.id;
end;
$$;

revoke execute on function public.can_manage_feature(uuid, text), public.correct_custom_entry(bigint, jsonb, text),
  public.set_custom_targets(uuid, numeric, jsonb), public.set_custom_field_options(uuid, jsonb) from public, anon;
grant execute on function public.can_manage_feature(uuid, text), public.correct_custom_entry(bigint, jsonb, text),
  public.set_custom_targets(uuid, numeric, jsonb), public.set_custom_field_options(uuid, jsonb) to authenticated;

$m037$;
  insert into public.install_log (name) values ('20261129000001_feature_manager_rights.sql');
end;
$part$;

-- ====================================================================
-- 20261129000002_conditional_role_nothing_left.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261129000002_conditional_role_nothing_left.sql') then
    return;
  end if;
  execute $m038$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Conditional roles (cmeprojects): when nothing is left to do for the chosen
-- role (the items still to do are for new starters or other roles only),
-- "Give conditional role" simply gives the role, with no onboarding task.
-- Managers always give it straight away; staff admins do too in that case,
-- unless the company's rule says a first role needs a manager's approval.

create or replace function public.apply_conditional_role(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.people_change_requests;
  v_team uuid;
  v_task uuid;
  v_missing text;
begin
  select * into r from public.people_change_requests where id = p_request_id;
  if (select role from public.profiles where id = r.user_id) <> 'new_starter' then
    raise exception 'They already have a role';
  end if;
  perform set_config('app.conditional_role', 'on', true);
  if r.to_value ->> 'title' is not null then
    update public.profiles set job_title_id = (r.to_value ->> 'title')::uuid where id = r.user_id;
  else
    update public.profiles set role = (r.to_value ->> 'role')::public.app_role where id = r.user_id;
  end if;
  perform set_config('app.conditional_role', 'off', true);

  if (r.to_value ->> 'role') in ('support_worker', 'team_leader') then
    for v_team in select x::uuid from jsonb_array_elements_text(coalesce(r.to_value -> 'teams', '[]')) x loop
      insert into public.team_members (team_id, user_id) values (v_team, r.user_id) on conflict do nothing;
    end loop;
  end if;

  -- Nothing left to do for this role: just the role, no task.
  if jsonb_array_length(coalesce(r.to_value -> 'missing', '[]')) = 0 then
    return;
  end if;
  select string_agg('• ' || x, E'\n') into v_missing from jsonb_array_elements_text(r.to_value -> 'missing') x;
  v_task := public.create_task(
    'Finish onboarding',
    (select id from public.registries where is_default and kind = 'tasks' and active order by sort_order limit 1),
    r.user_id,
    format(E'Your role was given on condition that you finish onboarding by %s.\n\nStill to do:\n%s\n\nReason: %s',
           to_char((r.to_value ->> 'deadline')::date, 'FMDD Mon YYYY'), coalesce(v_missing, ''), r.reason),
    'medium',
    (r.to_value ->> 'deadline')::date);
  update public.people_change_requests set task_id = v_task where id = r.id;
end;
$$;

-- Managers give a conditional role straight away; staff admins ask a manager.
create or replace function public.give_conditional_role(
  p_user_id uuid, p_role public.app_role, p_title_id uuid, p_teams uuid[], p_reason text, p_deadline date
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  me public.profiles;
  v_role public.app_role := p_role;
  v_teams uuid[] := coalesce(p_teams, '{}');
  v_missing text[];
  v_id uuid;
  v_name text;
  v_manager uuid;
  v_to jsonb;
begin
  select * into me from public.profiles where id = auth.uid();
  if not public.can_manage_people() then
    raise exception 'Only managers and staff admins give roles';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'You cannot change your own role';
  end if;
  if (select role from public.profiles where id = p_user_id and active) is distinct from 'new_starter' then
    raise exception 'Conditional roles are for new starters';
  end if;
  if p_title_id is not null then
    select access_level into v_role from public.job_titles where id = p_title_id and active;
    if v_role is null then raise exception 'Choose a role that is in use'; end if;
  end if;
  if v_role in ('new_starter', 'system_admin') or not public.can_manage_role(v_role) then
    raise exception 'Choose a role you''re allowed to give';
  end if;
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'Give a reason for the conditional role';
  end if;
  if p_deadline is null or p_deadline < public.local_today() or p_deadline > public.local_today() + 180 then
    raise exception 'Choose a deadline in the next six months';
  end if;
  if v_role not in ('support_worker', 'team_leader') then
    v_teams := '{}';
  elsif v_role = 'team_leader' and cardinality(v_teams) > 1 then
    raise exception 'A team leader can be in one team only';
  end if;
  if exists (select 1 from unnest(v_teams) t where not exists (select 1 from public.teams where id = t and active and not is_core)) then
    raise exception 'Choose teams that are in use';
  end if;

  -- What's missing for the chosen role. Items only for new starters (or other
  -- roles) don't count, so this can be nothing even when the Staff page shows
  -- items still to do.
  v_missing := public.onboarding_missing(p_user_id, v_role, v_teams);

  v_to := jsonb_build_object('role', v_role, 'title', p_title_id, 'teams', to_jsonb(v_teams),
                             'deadline', p_deadline, 'missing', to_jsonb(v_missing));

  -- Managers give it straight away; so do staff admins when nothing is left
  -- for that role and a first role doesn't need approval.
  if me.role in ('manager', 'system_admin')
     or (cardinality(v_missing) = 0 and not public.rule_on('people.first_role_approval')) then
    insert into public.people_change_requests (kind, user_id, from_value, to_value, reason, requested_by,
                                               status, decided_by, decided_at, requester_seen_at)
    values ('conditional', p_user_id, jsonb_build_object('role', 'new_starter'), v_to, trim(p_reason), auth.uid(),
            'approved', auth.uid(), now(), now())
    returning id into v_id;
    perform public.apply_conditional_role(v_id);
    perform public.write_audit('conditional_role_given', 'profile', p_user_id::text, v_to);
    return v_id;
  end if;

  v_id := public.add_change_request('conditional', p_user_id, null, jsonb_build_object('role', 'new_starter'), v_to, p_reason);
  select coalesce(nullif(full_name, ''), email) into v_name from public.profiles where id = p_user_id;
  for v_manager in select id from public.profiles where active and role = 'manager' loop
    perform public.notify(v_manager, 'approval_needed',
      format('Conditional role for %s needs your approval', v_name),
      format('%s asks to give them a role before onboarding is finished (deadline %s).',
             coalesce(nullif(me.full_name, ''), me.email), to_char(p_deadline, 'FMDD Mon YYYY')),
      '/settings/staff', true);
  end loop;
  return v_id;
end;
$$;

$m038$;
  insert into public.install_log (name) values ('20261129000002_conditional_role_nothing_left.sql');
end;
$part$;

-- ====================================================================
-- 20261130000001_staff_admin_role_approval.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261130000001_staff_admin_role_approval.sql') then
    return;
  end if;
  execute $m039$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Role changes by a staff admin always need a manager's approval
-- (cmeprojects): conditional roles, and a new starter's first role too.

update public.app_settings set value = 'true'
 where key in ('people.staff_admin_role_approval', 'people.first_role_approval');

-- Managers give a conditional role straight away; staff admins ask a manager.
create or replace function public.give_conditional_role(
  p_user_id uuid, p_role public.app_role, p_title_id uuid, p_teams uuid[], p_reason text, p_deadline date
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  me public.profiles;
  v_role public.app_role := p_role;
  v_teams uuid[] := coalesce(p_teams, '{}');
  v_missing text[];
  v_id uuid;
  v_name text;
  v_manager uuid;
  v_to jsonb;
begin
  select * into me from public.profiles where id = auth.uid();
  if not public.can_manage_people() then
    raise exception 'Only managers and staff admins give roles';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'You cannot change your own role';
  end if;
  if (select role from public.profiles where id = p_user_id and active) is distinct from 'new_starter' then
    raise exception 'Conditional roles are for new starters';
  end if;
  if p_title_id is not null then
    select access_level into v_role from public.job_titles where id = p_title_id and active;
    if v_role is null then raise exception 'Choose a role that is in use'; end if;
  end if;
  if v_role in ('new_starter', 'system_admin') or not public.can_manage_role(v_role) then
    raise exception 'Choose a role you''re allowed to give';
  end if;
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'Give a reason for the conditional role';
  end if;
  if p_deadline is null or p_deadline < public.local_today() or p_deadline > public.local_today() + 180 then
    raise exception 'Choose a deadline in the next six months';
  end if;
  if v_role not in ('support_worker', 'team_leader') then
    v_teams := '{}';
  elsif v_role = 'team_leader' and cardinality(v_teams) > 1 then
    raise exception 'A team leader can be in one team only';
  end if;
  if exists (select 1 from unnest(v_teams) t where not exists (select 1 from public.teams where id = t and active and not is_core)) then
    raise exception 'Choose teams that are in use';
  end if;

  -- What's missing for the chosen role. Items only for new starters (or other
  -- roles) don't count, so this can be nothing even when the Staff page shows
  -- items still to do.
  v_missing := public.onboarding_missing(p_user_id, v_role, v_teams);

  v_to := jsonb_build_object('role', v_role, 'title', p_title_id, 'teams', to_jsonb(v_teams),
                             'deadline', p_deadline, 'missing', to_jsonb(v_missing));

  -- Managers give it straight away; a staff admin's always goes to a manager.
  if me.role in ('manager', 'system_admin') then
    insert into public.people_change_requests (kind, user_id, from_value, to_value, reason, requested_by,
                                               status, decided_by, decided_at, requester_seen_at)
    values ('conditional', p_user_id, jsonb_build_object('role', 'new_starter'), v_to, trim(p_reason), auth.uid(),
            'approved', auth.uid(), now(), now())
    returning id into v_id;
    perform public.apply_conditional_role(v_id);
    perform public.write_audit('conditional_role_given', 'profile', p_user_id::text, v_to);
    return v_id;
  end if;

  v_id := public.add_change_request('conditional', p_user_id, null, jsonb_build_object('role', 'new_starter'), v_to, p_reason);
  select coalesce(nullif(full_name, ''), email) into v_name from public.profiles where id = p_user_id;
  for v_manager in select id from public.profiles where active and role = 'manager' loop
    perform public.notify(v_manager, 'approval_needed',
      format('Conditional role for %s needs your approval', v_name),
      format('%s asks to give them a role before onboarding is finished (deadline %s).',
             coalesce(nullif(me.full_name, ''), me.email), to_char(p_deadline, 'FMDD Mon YYYY')),
      '/settings/staff', true);
  end loop;
  return v_id;
end;
$$;

$m039$;
  insert into public.install_log (name) values ('20261130000001_staff_admin_role_approval.sql');
end;
$part$;

-- ====================================================================
-- 20261130000002_cars_app_look.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261130000002_cars_app_look.sql') then
    return;
  end if;
  execute $m040$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- The Cars app on staff phones (cmeprojects): the name under its icon, and
-- which picture is the icon. Public, because a phone reads them when it
-- installs the app, before anyone signs in. The icon is "car", "mark" (the
-- small logo), "logo" or the address of an uploaded picture.

insert into public.app_settings (key, value, label, description, is_public) values
  ('vehicles.app_name', '"Cars"', 'Cars app name on the phone',
   'The name under the icon on staff phones. Keep it short (about 12 letters), for example EC Cars.', true),
  ('vehicles.app_icon', '"car"', 'Cars app icon',
   'The picture on staff phones'' home screens. Tap one to use it, or upload your own. Phones that already have the app may need it added again to show a new icon.', true),
  -- Pictures uploaded as icons, kept as choices until deleted.
  ('vehicles.app_icon_uploads', '[]', 'Uploaded icons', 'Pictures uploaded for the Cars app icon.', true)
on conflict (key) do nothing;

$m040$;
  insert into public.install_log (name) values ('20261130000002_cars_app_look.sql');
end;
$part$;

-- ====================================================================
-- 20261130000003_car_trip_where.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261130000003_car_trip_where.sql') then
    return;
  end if;
  execute $m041$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Cars (cmeprojects): staff say where they went when they return a car
-- (optional), instead of giving details when they start. "What's it for?"
-- stays on Start for the purpose Other.

alter table public.car_trips add column if not exists went_to text not null default '';

drop function if exists public.return_car_trip(bigint, int, text, text);

-- Return a car, with where it went (optional). A car manager can return it
-- for the driver, with a reason.
create or replace function public.return_car_trip(p_trip_id bigint, p_end_odo int, p_photo_path text default null, p_note text default '', p_where text default '')
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.car_trips;
  v_photo text := public.car_setting('vehicles.odo_photo', 'optional');
  v_for_someone boolean;
begin
  select * into t from public.car_trips where id = p_trip_id for update;
  if t.id is null or not public.cars_on() then
    raise exception 'Trip not found';
  end if;
  v_for_someone := t.driver_id <> auth.uid();
  if v_for_someone and not public.can_manage_cars() then
    raise exception 'Trip not found';
  end if;
  if t.returned_at is not null then
    raise exception 'This car has already been returned';
  end if;
  if v_for_someone and coalesce(trim(p_note), '') = '' then
    raise exception 'Say why you''re returning it for them';
  end if;
  if p_end_odo is null then
    raise exception 'Enter the odometer reading';
  end if;
  if p_end_odo < t.start_odo then
    raise exception 'That''s lower than the start reading (% km). Check the dashboard.', t.start_odo;
  end if;
  if p_end_odo > t.start_odo + 3000 then
    raise exception 'That''s over 3,000 km for one trip. Check the reading.';
  end if;
  if p_photo_path is not null and p_photo_path not like t.driver_id::text || '/%' and p_photo_path not like auth.uid()::text || '/%' then
    raise exception 'Upload the photo again';
  end if;
  if v_photo = 'required' and p_photo_path is null and not v_for_someone then
    raise exception 'Add a photo of the odometer';
  end if;

  update public.car_trips
     set returned_at = now(), end_odo = p_end_odo, returned_by = auth.uid(),
         return_note = left(coalesce(trim(p_note), ''), 300),
         went_to = left(coalesce(trim(p_where), ''), 300),
         odo_photo_path = case when v_photo = 'off' then null else p_photo_path end
   where id = t.id;
  update public.cars set odometer = greatest(odometer, p_end_odo) where id = t.car_id;

  if v_for_someone then
    perform public.notify(t.driver_id, 'car_returned_for_you',
      format('%s returned the %s for you', public.my_name(), (select name from public.cars where id = t.car_id)),
      coalesce(nullif(trim(p_note), ''), ''), '/cars');
    perform public.write_audit('car_returned_for_someone', 'car_trip', t.id::text,
      jsonb_build_object('driver', t.driver_id, 'end_odo', p_end_odo, 'note', p_note));
  end if;
  return p_end_odo - t.start_odo;
end;
$$;

-- Undo a return (wrong reading, pressed too early): the trip is open again.
create or replace function public.undo_car_return(p_trip_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.car_trips;
begin
  select * into t from public.car_trips where id = p_trip_id for update;
  if t.id is null or not public.cars_on() or coalesce(t.returned_by, t.driver_id) <> auth.uid() then
    raise exception 'Trip not found';
  end if;
  if t.returned_at is null then
    raise exception 'This car hasn''t been returned';
  end if;
  if t.returned_at < now() - make_interval(mins => public.car_setting('vehicles.undo_minutes', '10')::int) then
    raise exception 'It''s too late to undo. Ask a car manager to fix the trip.';
  end if;
  if exists (select 1 from public.car_trips where car_id = t.car_id and id <> t.id and started_at > t.started_at) then
    raise exception 'Someone has taken this car since. Ask a car manager to fix the trip.';
  end if;
  if exists (select 1 from public.car_trips where driver_id = t.driver_id and returned_at is null) then
    raise exception 'Return the car you have out first';
  end if;
  update public.car_trips
     set returned_at = null, end_odo = null, returned_by = null, return_note = '', went_to = '', odo_photo_path = null
   where id = t.id;
  update public.cars
     set odometer = greatest(t.start_odo, coalesce((select max(end_odo) from public.car_trips where car_id = t.car_id and id <> t.id), 0))
   where id = t.car_id;
  perform public.write_audit('car_return_undone', 'car_trip', t.id::text, to_jsonb(t));
end;
$$;

revoke execute on function public.return_car_trip(bigint, int, text, text, text) from public, anon;
grant execute on function public.return_car_trip(bigint, int, text, text, text) to authenticated;

$m041$;
  insert into public.install_log (name) values ('20261130000003_car_trip_where.sql');
end;
$part$;

-- ====================================================================
-- 20261201000001_live_updates.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261201000001_live_updates.sql') then
    return;
  end if;
  execute $m042$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Live updates (cmeprojects): open pages refresh themselves when something
-- they show changes. Supabase sends a change only to people allowed to see
-- that row. Staff can't see other people's trips, so each car gets a
-- "last changed" time, touched whenever one of its trips changes, which
-- everyone who uses Cars can see.

alter table public.cars add column if not exists changed_at timestamptz not null default now();

create or replace function public.touch_car_from_trip()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.cars set changed_at = now() where id = coalesce(new.car_id, old.car_id);
  return coalesce(new, old);
end;
$$;
revoke execute on function public.touch_car_from_trip() from public, anon, authenticated;

drop trigger if exists car_trips_touch_car on public.car_trips;
create trigger car_trips_touch_car after insert or update or delete on public.car_trips
  for each row execute function public.touch_car_from_trip();

-- A "something changed" signal everyone signed in can see, for changes they
-- otherwise couldn't (a built feature switched off is hidden from staff, so
-- they'd never hear that it changed).
create table if not exists public.live_signals (
  topic      text primary key,
  changed_at timestamptz not null default now()
);
alter table public.live_signals enable row level security;
drop policy if exists "members see signals" on public.live_signals;
create policy "members see signals" on public.live_signals for select to authenticated using (public.is_member());
revoke insert, update, delete, truncate on public.live_signals from anon, authenticated;

create or replace function public.signal_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.live_signals (topic) values (tg_argv[0])
  on conflict (topic) do update set changed_at = now();
  return null;
end;
$$;
revoke execute on function public.signal_change() from public, anon, authenticated;

drop trigger if exists custom_features_signal on public.custom_features;
create trigger custom_features_signal after insert or update or delete on public.custom_features
  for each statement execute function public.signal_change('features');

-- The tables open pages listen to.
do $live$
declare
  t text;
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    return;
  end if;
  foreach t in array array['cars', 'car_trips', 'custom_entries', 'custom_fields', 'app_settings', 'features', 'notifications', 'live_signals'] loop
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end;
$live$;

$m042$;
  insert into public.install_log (name) values ('20261201000001_live_updates.sql');
end;
$part$;

-- ====================================================================
-- 20261202000001_compliance_report_wording.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261202000001_compliance_report_wording.sql') then
    return;
  end if;
  execute $m043$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Clearer wording for who sees reports (cmeprojects), now on their own
-- Reports tab in System settings.

update public.app_settings
   set label = 'Who sees the Compliance report',
       description = 'Onboarding and compliance for everyone: what''s done, missing, expiring or expired. Besides the system admin. Tick Manager to let managers see it.'
 where key = 'reports.compliance_roles';

$m043$;
  insert into public.install_log (name) values ('20261202000001_compliance_report_wording.sql');
end;
$part$;

-- ====================================================================
-- 20261203000001_live_tasks.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261203000001_live_tasks.sql') then
    return;
  end if;
  execute $m044$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Live updates for tasks (cmeprojects): the bell, task lists and an open task
-- update by themselves when a task is created, assigned or changes, and when
-- a role change request is sent or decided.

do $live$
declare
  t text;
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    return;
  end if;
  foreach t in array array['tasks', 'task_events', 'people_change_requests'] loop
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end;
$live$;

$m044$;
  insert into public.install_log (name) values ('20261203000001_live_tasks.sql');
end;
$part$;

-- ====================================================================
-- 20261204000001_feature_alerts.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261204000001_feature_alerts.sql') then
    return;
  end if;
  execute $m045$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Feature builder alerts (cmeprojects). The system admin adds rules to a
-- feature: when an entry is saved (or fixed) and matches, chosen people are
-- told straight away by the bell, email, or both. Managers by default.
--
-- What sets an alert off:
--   any          every new entry
--   choice       a drop-down or yes/no answer is a given value
--   above/below  a number is above or below a limit
--   total_over   a client's daily total goes over their target (a restriction)
--   total_met    a client's daily total reaches their target (a goal)

create table if not exists public.custom_alerts (
  id             uuid primary key default gen_random_uuid(),
  feature_id     uuid not null references public.custom_features (id) on delete cascade,
  name           text not null default '' check (length(name) <= 80),
  when_kind      text not null default 'any' check (when_kind in ('any', 'choice', 'above', 'below', 'total_over', 'total_met')),
  field_id       uuid references public.custom_fields (id) on delete cascade,
  match_text     text not null default '' check (length(match_text) <= 80),
  limit_value    numeric,
  notify_roles   public.app_role[] not null default '{manager}',
  notify_leader  boolean not null default false,
  notify_people  uuid[] not null default '{}',
  by_bell        boolean not null default true,
  by_email       boolean not null default false,
  on_fix         boolean not null default false,
  message        text not null default '' check (length(message) <= 200),
  active         boolean not null default true,
  created_at     timestamptz not null default now()
);
create index if not exists custom_alerts_feature on public.custom_alerts (feature_id);

alter table public.custom_alerts enable row level security;
drop policy if exists "the builder manages alerts" on public.custom_alerts;
create policy "the builder manages alerts" on public.custom_alerts for all to authenticated
  using (public.can_build_features()) with check (public.can_build_features());

drop trigger if exists custom_alerts_log on public.custom_alerts;
create trigger custom_alerts_log after insert or update or delete on public.custom_alerts
  for each row execute function public.log_feature_setup('custom_alert');

-- A client's total for the entry's day, with or without this entry.
create or replace function public.custom_day_total(p_entry public.custom_entries, p_with boolean)
returns numeric
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(sum((e.data ->> f.total_field::text)::numeric), 0)
    from public.custom_entries e
    join public.custom_features f on f.id = e.feature_id
   where e.feature_id = p_entry.feature_id
     and e.client_id = p_entry.client_id
     and (p_with or e.id <> p_entry.id)
     and jsonb_typeof(e.data -> f.total_field::text) = 'number'
     and (e.created_at at time zone coalesce((select value #>> '{}' from public.app_settings where key = 'region.timezone'), 'Australia/Melbourne'))::date
       = (p_entry.created_at at time zone coalesce((select value #>> '{}' from public.app_settings where key = 'region.timezone'), 'Australia/Melbourne'))::date
$$;
revoke execute on function public.custom_day_total(public.custom_entries, boolean) from public, anon, authenticated;

-- Runs after an entry is saved or fixed: tells people for each matching alert.
create or replace function public.fire_custom_alerts()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  feat public.custom_features;
  a public.custom_alerts;
  v_fixed boolean := tg_op = 'UPDATE';
  v_answer text;
  v_num numeric;
  v_target numeric;
  v_before numeric;
  v_after numeric;
  v_unit text;
  v_staff text;
  v_title text;
  v_body text;
  v_user uuid;
  v_detail text;
begin
  if v_fixed and new.data is not distinct from old.data then
    return new;
  end if;
  select * into feat from public.custom_features where id = new.feature_id;
  if not (feat.status = 'published' and feat.enabled) then
    return new;
  end if;
  select coalesce(nullif(full_name, ''), email) into v_staff from public.profiles where id = new.created_by;
  select unit into v_unit from public.custom_fields where id = feat.total_field;

  for a in select * from public.custom_alerts where feature_id = new.feature_id and active and (not v_fixed or on_fix) loop
    v_detail := '';
    v_answer := case when a.field_id is null then null
                     when jsonb_typeof(new.data -> a.field_id::text) = 'array'
                       then (select string_agg(x, ', ') from jsonb_array_elements_text(new.data -> a.field_id::text) x)
                     else new.data ->> a.field_id::text end;

    if a.when_kind = 'choice' then
      if v_answer is null or not (lower(v_answer) = lower(a.match_text)
             or (jsonb_typeof(new.data -> a.field_id::text) = 'array'
                 and exists (select 1 from jsonb_array_elements_text(new.data -> a.field_id::text) x where lower(x) = lower(a.match_text)))) then
        continue;
      end if;
      v_detail := format('%s: %s', (select label from public.custom_fields where id = a.field_id), a.match_text);
    elsif a.when_kind in ('above', 'below') then
      begin
        v_num := v_answer::numeric;
      exception when others then
        continue;
      end;
      if v_num is null or a.limit_value is null
         or (a.when_kind = 'above' and v_num <= a.limit_value)
         or (a.when_kind = 'below' and v_num >= a.limit_value) then
        continue;
      end if;
      select format('%s: %s%s', label, rtrim(to_char(v_num, 'FM999G999G990D##'), '.'), case when unit <> '' then ' ' || unit else '' end)
        into v_detail from public.custom_fields where id = a.field_id;
    elsif a.when_kind in ('total_over', 'total_met') then
      if new.client_id is null or feat.total_field is null then
        continue;
      end if;
      v_target := coalesce((select target from public.custom_client_targets where feature_id = feat.id and client_id = new.client_id), feat.default_target);
      if v_target is null then
        continue;
      end if;
      v_after := public.custom_day_total(new, true);
      v_before := case when v_fixed then v_after - coalesce((new.data ->> feat.total_field::text)::numeric, 0)
                                               + coalesce((old.data ->> feat.total_field::text)::numeric, 0)
                       else public.custom_day_total(new, false) end;
      -- Only when the total crosses the line, so it's one alert a day.
      if (a.when_kind = 'total_over' and not (v_after > v_target and v_before <= v_target))
         or (a.when_kind = 'total_met' and not (v_after >= v_target and v_before < v_target)) then
        continue;
      end if;
      v_detail := format('%s is at %s of %s%s today', new.client_name, trim(to_char(v_after, 'FM999G999G990')),
                         trim(to_char(v_target, 'FM999G999G990')), case when v_unit <> '' then ' ' || v_unit else '' end);
    end if;

    v_title := coalesce(nullif(trim(replace(replace(replace(a.message, '{client}', new.client_name), '{staff}', v_staff), '{feature}', feat.name)), ''),
                        format('%s: %s', feat.name, coalesce(nullif(a.name, ''), case when a.when_kind = 'any' then 'new entry' else v_detail end)));
    v_body := concat_ws(' · ',
                        nullif(v_detail, ''),
                        nullif(case when a.when_kind in ('total_over', 'total_met') then '' else new.client_name end, ''),
                        format('%s by %s', case when v_fixed then 'Fixed' else 'Entered' end, v_staff));

    for v_user in
      select p.id from public.profiles p
       where p.active and p.id <> coalesce(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
         and (p.role = any (a.notify_roles)
              or p.id = any (a.notify_people)
              or (a.notify_leader and exists (select 1 from public.team_leaders l join public.team_members m on m.team_id = l.team_id
                                               where m.user_id = new.created_by and l.user_id = p.id)))
    loop
      if a.by_bell then
        insert into public.notifications (user_id, kind, title, body, href)
        values (v_user, 'feature_alert', left(v_title, 200), v_body, '/f/' || feat.slug);
      end if;
      if a.by_email and public.feature_enabled('email_notifications') then
        insert into public.email_outbox (to_user, template, data)
        values (v_user, 'notice', jsonb_build_object('title', left(v_title, 200), 'body', v_body, 'href', '/f/' || feat.slug));
      end if;
    end loop;
  end loop;
  return new;
end;
$$;
revoke execute on function public.fire_custom_alerts() from public, anon, authenticated;

drop trigger if exists custom_entries_alerts on public.custom_entries;
create trigger custom_entries_alerts after insert or update of data on public.custom_entries
  for each row execute function public.fire_custom_alerts();

$m045$;
  insert into public.install_log (name) values ('20261204000001_feature_alerts.sql');
end;
$part$;

-- ====================================================================
-- 20261205000001_staff_app.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261205000001_staff_app.sql') then
    return;
  end if;
  execute $m046$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- The Staff app (cmeprojects): one phone app holding the features the system
-- admin chooses (built features, and Cars if they like), with its own name
-- and icon. A premium add-on, off until the system admin switches it on. The
-- Cars app carries on as its own app; the system admin can switch that off
-- when Cars lives in the Staff app instead.

insert into public.features (key, label, description, enabled, sort_order, premium, included) values
  ('staff_app', 'Staff app',
   'One phone app for staff with the features you choose: built features like Fluid intake, and Cars if you like.',
   false, 76, true, false)
on conflict (key) do nothing;

-- Shown on phones before anyone signs in, so public.
insert into public.app_settings (key, value, label, description, is_public) values
  ('staff_app.name', '"Staff"', 'Staff app name on the phone',
   'The name under the icon on staff phones. Keep it short (about 12 letters), for example EC Staff.', true),
  ('staff_app.icon', '"car"', 'Staff app icon',
   'The picture on staff phones'' home screens. Tap one to use it, or upload your own.', true),
  ('staff_app.icon_uploads', '[]', 'Uploaded Staff app icons', 'Pictures uploaded for the Staff app icon.', true),
  ('staff_app.cars', 'false', 'Cars in the Staff app',
   'Show Cars as an icon inside the Staff app.', true),
  ('vehicles.separate_app', 'true', 'Separate Cars app',
   'Keep the Cars app as its own app. Turn off if Cars is in the Staff app and you want only one app.', true)
on conflict (key) do nothing;

-- Each built feature: in the Staff app or not, and its icon there.
alter table public.custom_features add column if not exists in_app boolean not null default true;
alter table public.custom_features add column if not exists app_icon text not null default 'clipboard' check (length(app_icon) <= 20);
alter table public.custom_features add column if not exists app_colour text not null default '#134f8e' check (app_colour ~ '^#[0-9a-fA-F]{6}$');

$m046$;
  insert into public.install_log (name) values ('20261205000001_staff_app.sql');
end;
$part$;

-- ====================================================================
-- 20261205000002_role_changed_notice.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261205000002_role_changed_notice.sql') then
    return;
  end if;
  execute $m047$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- When someone's role changes, they're told (cmeprojects): a note in their
-- bell, and a banner at the top of the portal. Their menu updates by itself.
-- Someone whose account is turned off is signed out of any open page.

create or replace function public.notify_role_changed()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_label text := case new.role
    when 'support_worker' then 'Support worker' when 'team_leader' then 'Team leader' when 'manager' then 'Manager'
    when 'staff_admin' then 'Staff admin' when 'system_admin' then 'System admin' else 'New starter' end;
  v_title text := (select name from public.job_titles where id = new.job_title_id);
begin
  if new.active and new.role is distinct from old.role then
    perform public.notify(new.id, 'role_changed',
      format('Your role is now %s', coalesce(v_title, v_label)),
      'Your menu has been updated to show what you can use now.', '/', false);
  end if;
  return new;
end;
$$;
revoke execute on function public.notify_role_changed() from public, anon, authenticated;

drop trigger if exists profiles_role_changed on public.profiles;
create trigger profiles_role_changed after update of role on public.profiles
  for each row execute function public.notify_role_changed();

-- A role change or a deactivated account refreshes open pages straight away
-- (a deactivated person's page then signs them out). Anyone signed in can see
-- these signals: they only say that something changed, not what.
drop policy if exists "members see signals" on public.live_signals;
drop policy if exists "signed-in people see signals" on public.live_signals;
create policy "signed-in people see signals" on public.live_signals for select to authenticated using (true);

drop trigger if exists profiles_access_signal on public.profiles;
create trigger profiles_access_signal after update of role, active on public.profiles
  for each statement execute function public.signal_change('people');

$m047$;
  insert into public.install_log (name) values ('20261205000002_role_changed_notice.sql');
end;
$part$;

-- ====================================================================
-- 20261206000001_escalate_to.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261206000001_escalate_to.sql') then
    return;
  end if;
  execute $m048$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Escalating to the right person (cmeprojects). A support worker escalates a
-- task to their team leader or to a manager; team leaders and staff admins
-- escalate straight to a manager. It shows in "Needs your attention" for
-- whoever it went to, who can add a helper, take it over or reassign it.
-- Reassigning or taking over an escalated task deals with the escalation.

alter table public.tasks add column if not exists escalated_to text check (escalated_to in ('team_leader', 'manager'));
alter table public.tasks add column if not exists escalated_by uuid references public.profiles (id);

-- The team leaders of the people looking after a task (or of whoever escalated it).
create or replace function public.task_team_leaders(p_task_id uuid, p_also uuid default null)
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select distinct l.user_id
    from public.tasks t
    join public.team_members m on m.user_id in (t.assigned_to, coalesce(p_also, t.assigned_to))
    join public.team_leaders l on l.team_id = m.team_id
    join public.profiles p on p.id = l.user_id and p.active
   where t.id = p_task_id
$$;
revoke execute on function public.task_team_leaders(uuid, uuid) from public, anon, authenticated;

drop function if exists public.escalate_task(uuid, text);
create or replace function public.escalate_task(p_task_id uuid, p_reason text, p_to text default 'manager')
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.tasks;
  v_to text := 'manager';
  v_user uuid;
  v_told int := 0;
begin
  select * into t from public.tasks where id = p_task_id for update;
  if t.id is null or not public.can_see_task(p_task_id) then
    raise exception 'Task not found';
  end if;
  if not (public.can_edit_task(p_task_id) or exists (select 1 from public.task_helpers where task_id = t.id and user_id = auth.uid())) then
    raise exception 'You can''t escalate this task';
  end if;
  if t.status in ('completed', 'closed', 'escalated') then
    raise exception 'This task can''t be escalated now';
  end if;
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'Say why it needs escalating';
  end if;
  -- Only support workers can send it to a team leader (if they have one).
  if p_to = 'team_leader' and public.my_role() = 'support_worker'
     and exists (select 1 from public.task_team_leaders(t.id, auth.uid()) x where x <> auth.uid()) then
    v_to := 'team_leader';
  end if;

  update public.tasks set status = 'escalated', escalated = true, escalated_to = v_to, escalated_by = auth.uid(), updated_at = now() where id = t.id;
  insert into public.task_events (task_id, actor_id, type, from_value, to_value, comment)
  values (t.id, auth.uid(), 'status_changed', t.status::text, 'escalated',
          trim(p_reason) || case when v_to = 'team_leader' then ' (to the team leader)' else ' (to a manager)' end);

  for v_user in
    select x from public.task_team_leaders(t.id, auth.uid()) x where v_to = 'team_leader'
    union
    select m from public.task_managers(t.id) m where v_to = 'manager'
  loop
    continue when v_user = auth.uid();
    perform public.notify(v_user, 'task_escalated', format('Escalated to you: %s', public.task_label(t.id)),
      format('%s: %s', public.my_name(), trim(p_reason)), '/tasks/' || t.id, true);
    v_told := v_told + 1;
  end loop;
  return v_to;
end;
$$;
revoke execute on function public.escalate_task(uuid, text, text) from public, anon;
grant execute on function public.escalate_task(uuid, text, text) to authenticated;

-- Dealt with: once it's no longer escalated, forget who it went to. Moving it
-- to someone else (reassign or take over) deals with the escalation.
create or replace function public.settle_escalation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if old.status = 'escalated' and new.status = 'escalated' and new.assigned_to is distinct from old.assigned_to then
    new.status := 'assigned';
    new.escalated := false;
  end if;
  if new.status <> 'escalated' then
    new.escalated_to := null;
  elsif old.status <> 'escalated' and new.escalated_to is null then
    -- Escalated by the overnight check: managers look at it.
    new.escalated_to := 'manager';
  end if;
  return new;
end;
$$;

drop trigger if exists tasks_settle_escalation on public.tasks;
create trigger tasks_settle_escalation before update on public.tasks
  for each row execute function public.settle_escalation();

$m048$;
  insert into public.install_log (name) values ('20261206000001_escalate_to.sql');
end;
$part$;

-- ====================================================================
-- 20261207000001_forms.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261207000001_forms.sql') then
    return;
  end if;
  execute $m049$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Forms (cmeprojects, premium). Managers and/or staff admins (the system
-- admin chooses) make simple forms: a title, a note and questions. They try
-- them out, publish, and send them to people, a team or everyone (bell and
-- email, with an optional due date), or make them a Compliance item. Each
-- form has a link and a QR code. Only the person who made a form, and anyone
-- they share it with, can change it or see its replies.

insert into public.features (key, label, description, enabled, sort_order, premium, included) values
  ('forms', 'Forms',
   'Managers and staff admins make forms, send them to staff or put them in Compliance, and see the replies.',
   false, 78, true, false)
on conflict (key) do nothing;

insert into public.app_settings (key, value, label, description, is_public) values
  ('forms.maker_roles', '["manager"]', 'Who can make forms',
   'Besides the system admin. They see Forms in the menu with + New form.', false)
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- Forms, questions, who it's shared with and sent to, and replies
-- ---------------------------------------------------------------------------

create table if not exists public.forms (
  id             uuid primary key default gen_random_uuid(),
  org_id         uuid not null default public.default_org_id() references public.organisation (id),
  title          text not null check (length(trim(title)) between 1 and 120),
  intro          text not null default '' check (length(intro) <= 2000),
  status         text not null default 'draft' check (status in ('draft', 'published')),
  -- Turned off: hidden from staff, replies kept.
  enabled        boolean not null default true,
  -- Once per person, or as many times as needed (e.g. an incident form).
  repeatable     boolean not null default false,
  anonymous      boolean not null default false,
  show_header    boolean not null default true,
  show_contact   boolean not null default true,
  notify_creator boolean not null default false,
  due_date       date,
  closes_on      date,
  created_by     uuid not null references public.profiles (id) default auth.uid(),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  published_at   timestamptz
);

create table if not exists public.form_questions (
  id         uuid primary key default gen_random_uuid(),
  form_id    uuid not null references public.forms (id) on delete cascade,
  label      text not null check (length(trim(label)) between 1 and 300),
  type       text not null check (type in ('text', 'long', 'choice', 'multi', 'yesno', 'date', 'number', 'file', 'signature')),
  required   boolean not null default false,
  help       text not null default '' check (length(help) <= 300),
  options    jsonb not null default '[]' check (jsonb_typeof(options) = 'array'),
  sort_order int not null default 0,
  -- Taken off the form: old replies keep their answers.
  archived   boolean not null default false
);
create index if not exists form_questions_form on public.form_questions (form_id, sort_order);

create table if not exists public.form_collaborators (
  form_id uuid not null references public.forms (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  primary key (form_id, user_id)
);

create table if not exists public.form_recipients (
  form_id     uuid not null references public.forms (id) on delete cascade,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  sent_at     timestamptz not null default now(),
  reminded_at timestamptz,
  primary key (form_id, user_id)
);

-- Who has filled it in (kept even for anonymous forms, so "still to do" works).
create table if not exists public.form_completions (
  form_id uuid not null references public.forms (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  done_at timestamptz not null default now(),
  primary key (form_id, user_id)
);

create table if not exists public.form_responses (
  id           bigint generated always as identity primary key,
  form_id      uuid not null references public.forms (id) on delete cascade,
  -- Empty for anonymous forms once sent.
  user_id      uuid references public.profiles (id) on delete set null,
  answers      jsonb not null default '{}' check (jsonb_typeof(answers) = 'object'),
  status       text not null default 'submitted' check (status in ('draft', 'submitted')),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  submitted_at timestamptz
);
create index if not exists form_responses_form on public.form_responses (form_id, submitted_at desc);
-- One saved draft per person per form.
create unique index if not exists form_responses_one_draft on public.form_responses (form_id, user_id) where status = 'draft';

-- A form can be a Compliance item: staff fill it in as part of onboarding.
alter table public.compliance_items add column if not exists form_id uuid references public.forms (id) on delete set null;
alter table public.compliance_items drop constraint if exists compliance_items_kind_check;
alter table public.compliance_items add constraint compliance_items_kind_check check (kind in ('read', 'training', 'upload', 'form'));

-- ---------------------------------------------------------------------------
-- Who can do what
-- ---------------------------------------------------------------------------

create or replace function public.can_make_forms()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and public.feature_enabled('forms')
     and (public.is_system_admin()
          or public.my_role()::text in (select jsonb_array_elements_text(coalesce(
               (select value from public.app_settings where key = 'forms.maker_roles'), '[]'))))
$$;

create or replace function public.can_manage_form(p_form uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and public.feature_enabled('forms') and (
    public.is_system_admin()
    or exists (select 1 from public.forms where id = p_form and created_by = auth.uid())
    or exists (select 1 from public.form_collaborators where form_id = p_form and user_id = auth.uid()))
$$;

create or replace function public.can_fill_form(p_form uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and public.feature_enabled('forms') and exists (
    select 1 from public.forms f
     where f.id = p_form and f.status = 'published' and f.enabled
       and (f.closes_on is null or f.closes_on >= public.local_today()))
$$;

alter table public.forms enable row level security;
alter table public.form_questions enable row level security;
alter table public.form_collaborators enable row level security;
alter table public.form_recipients enable row level security;
alter table public.form_completions enable row level security;
alter table public.form_responses enable row level security;

drop policy if exists "forms are seen by their managers, or to fill in" on public.forms;
create policy "forms are seen by their managers, or to fill in" on public.forms for select to authenticated
  using ((created_by = auth.uid() and public.is_member()) or public.can_manage_form(id) or public.can_fill_form(id));
drop policy if exists "form makers add forms" on public.forms;
create policy "form makers add forms" on public.forms for insert to authenticated
  with check (public.can_make_forms() and created_by = auth.uid());
drop policy if exists "form managers change forms" on public.forms;
create policy "form managers change forms" on public.forms for update to authenticated
  using (public.can_manage_form(id)) with check (public.can_manage_form(id));
drop policy if exists "form managers delete forms" on public.forms;
create policy "form managers delete forms" on public.forms for delete to authenticated using (public.can_manage_form(id));

drop policy if exists "questions follow their form" on public.form_questions;
create policy "questions follow their form" on public.form_questions for select to authenticated
  using (public.can_manage_form(form_id) or public.can_fill_form(form_id));
drop policy if exists "form managers change questions" on public.form_questions;
create policy "form managers change questions" on public.form_questions for all to authenticated
  using (public.can_manage_form(form_id)) with check (public.can_manage_form(form_id));

drop policy if exists "collaborators are seen with the form" on public.form_collaborators;
create policy "collaborators are seen with the form" on public.form_collaborators for select to authenticated
  using (public.can_manage_form(form_id));
drop policy if exists "the form's maker shares it" on public.form_collaborators;
create policy "the form's maker shares it" on public.form_collaborators for all to authenticated
  using (public.is_system_admin() or exists (select 1 from public.forms where id = form_id and created_by = auth.uid()))
  with check (public.is_system_admin() or exists (select 1 from public.forms where id = form_id and created_by = auth.uid()));

drop policy if exists "recipients see their own, managers all" on public.form_recipients;
create policy "recipients see their own, managers all" on public.form_recipients for select to authenticated
  using (user_id = auth.uid() or public.can_manage_form(form_id));
drop policy if exists "completions: your own, or the form's managers" on public.form_completions;
create policy "completions: your own, or the form's managers" on public.form_completions for select to authenticated
  using (user_id = auth.uid() or public.can_manage_form(form_id));
drop policy if exists "replies: your own, or the form's managers" on public.form_responses;
create policy "replies: your own, or the form's managers" on public.form_responses for select to authenticated
  using (user_id = auth.uid() or (status = 'submitted' and public.can_manage_form(form_id)));
-- Sending, replying and completions only through the functions below.
revoke insert, update, delete, truncate on public.form_recipients, public.form_completions, public.form_responses from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Filling in
-- ---------------------------------------------------------------------------

-- Save a reply (p_send = false keeps it as a draft to finish later).
create or replace function public.submit_form_response(p_form uuid, p_answers jsonb, p_send boolean default true)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  f public.forms;
  q record;
  v text;
  v_clean jsonb := '{}'::jsonb;
  v_id bigint;
  v_item uuid;
begin
  if not public.can_fill_form(p_form) then
    raise exception 'This form isn''t open';
  end if;
  select * into f from public.forms where id = p_form;
  if not f.repeatable and exists (select 1 from public.form_completions where form_id = f.id and user_id = auth.uid()) then
    raise exception 'You''ve already filled this in';
  end if;
  if p_answers is null or jsonb_typeof(p_answers) <> 'object' then
    raise exception 'Fill in the form';
  end if;

  for q in select * from public.form_questions where form_id = f.id and not archived order by sort_order loop
    if q.type = 'multi' then
      if jsonb_typeof(p_answers -> q.id::text) = 'array' and jsonb_array_length(p_answers -> q.id::text) > 0 then
        if exists (select 1 from jsonb_array_elements_text(p_answers -> q.id::text) x where not q.options ? x) then
          raise exception '%: choose from the list', q.label;
        end if;
        v_clean := v_clean || jsonb_build_object(q.id::text, p_answers -> q.id::text);
      elsif q.required and p_send then
        raise exception '%: choose at least one', q.label;
      end if;
      continue;
    end if;
    v := nullif(trim(p_answers ->> q.id::text), '');
    if v is null then
      if q.required and p_send then
        raise exception '%: this is needed', q.label;
      end if;
      continue;
    end if;
    if length(v) > (case when q.type = 'long' then 5000 else 300 end) then
      raise exception '%: that''s too long', q.label;
    end if;
    if q.type = 'choice' and not q.options ? v then
      raise exception '%: choose from the list', q.label;
    elsif q.type = 'yesno' and v not in ('Yes', 'No') then
      raise exception '%: choose Yes or No', q.label;
    elsif q.type = 'date' and v !~ '^\d{4}-\d{2}-\d{2}$' then
      raise exception '%: enter a date', q.label;
    elsif q.type = 'number' and v !~ '^-?\d+(\.\d+)?$' then
      raise exception '%: enter a number', q.label;
    elsif q.type = 'file' and v not like auth.uid()::text || '/%' then
      raise exception '%: upload the file again', q.label;
    end if;
    v_clean := v_clean || jsonb_build_object(q.id::text, v);
  end loop;

  -- Their saved draft becomes this reply (or stays a draft).
  select id into v_id from public.form_responses where form_id = f.id and user_id = auth.uid() and status = 'draft';
  if v_id is not null then
    update public.form_responses
       set answers = v_clean, updated_at = now(),
           status = case when p_send then 'submitted' else 'draft' end,
           submitted_at = case when p_send then now() end,
           user_id = case when p_send and f.anonymous then null else user_id end
     where id = v_id;
  else
    insert into public.form_responses (form_id, user_id, answers, status, submitted_at)
    values (f.id, case when p_send and f.anonymous then null else auth.uid() end, v_clean,
            case when p_send then 'submitted' else 'draft' end, case when p_send then now() end)
    returning id into v_id;
  end if;

  if p_send then
    insert into public.form_completions (form_id, user_id) values (f.id, auth.uid())
    on conflict (form_id, user_id) do update set done_at = now();
    -- Part of Compliance: it counts as done.
    for v_item in select id from public.compliance_items where form_id = f.id and active loop
      insert into public.compliance_records (item_id, user_id, version, status)
      select v_item, auth.uid(), version, 'done' from public.compliance_items where id = v_item;
    end loop;
    if f.notify_creator and f.created_by <> auth.uid() then
      perform public.notify(f.created_by, 'form_reply', format('New reply: %s', f.title),
        case when f.anonymous then 'Someone sent a reply.' else format('%s sent a reply.', public.my_name()) end,
        '/forms/' || f.id || '/replies', false);
    end if;
  end if;
  return v_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Publishing, sending, reminding and Compliance
-- ---------------------------------------------------------------------------

-- Send to people, a team or everyone: bell and email, with the due date.
create or replace function public.send_form(p_form uuid, p_users uuid[], p_team uuid default null, p_everyone boolean default false)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  f public.forms;
  v_user uuid;
  v_count int := 0;
begin
  if not public.can_manage_form(p_form) then
    raise exception 'You can''t send this form';
  end if;
  select * into f from public.forms where id = p_form;
  if f.status <> 'published' or not f.enabled then
    raise exception 'Publish the form first';
  end if;
  for v_user in
    select p.id from public.profiles p
     where p.active and p.role <> 'system_admin'
       and (p_everyone
            or p.id = any (coalesce(p_users, '{}'))
            or (p_team is not null and exists (select 1 from public.team_members m where m.team_id = p_team and m.user_id = p.id)))
  loop
    insert into public.form_recipients (form_id, user_id) values (f.id, v_user)
    on conflict (form_id, user_id) do update set sent_at = now();
    perform public.notify(v_user, 'form_sent', format('Please fill in: %s', f.title),
      case when f.due_date is not null then format('Due %s. From %s.', to_char(f.due_date, 'FMDD Mon YYYY'), public.my_name())
           else format('From %s.', public.my_name()) end,
      '/forms/' || f.id, true);
    v_count := v_count + 1;
  end loop;
  perform public.write_audit('form_sent', 'form', f.id::text, jsonb_build_object('people', v_count));
  return v_count;
end;
$$;

-- A reminder to those it was sent to who haven't filled it in.
create or replace function public.remind_form(p_form uuid)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  f public.forms;
  v_user uuid;
  v_count int := 0;
begin
  if not public.can_manage_form(p_form) then
    raise exception 'You can''t remind people about this form';
  end if;
  select * into f from public.forms where id = p_form;
  for v_user in
    select r.user_id from public.form_recipients r
     where r.form_id = f.id
       and not exists (select 1 from public.form_completions c where c.form_id = f.id and c.user_id = r.user_id)
  loop
    perform public.notify(v_user, 'form_sent', format('Reminder: %s', f.title),
      case when f.due_date is not null then format('Please fill it in by %s.', to_char(f.due_date, 'FMDD Mon YYYY')) else 'Please fill it in.' end,
      '/forms/' || f.id, true);
    update public.form_recipients set reminded_at = now() where form_id = f.id and user_id = v_user;
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

-- Put the form in Compliance for these roles and teams (everyone if both empty).
create or replace function public.form_to_compliance(p_form uuid, p_roles public.app_role[], p_teams uuid[])
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  f public.forms;
  v_item uuid;
begin
  if not public.can_manage_form(p_form) then
    raise exception 'You can''t change this form';
  end if;
  select * into f from public.forms where id = p_form;
  if f.status <> 'published' or not f.enabled then
    raise exception 'Publish the form first';
  end if;
  select id into v_item from public.compliance_items where form_id = f.id;
  if v_item is null then
    insert into public.compliance_items (kind, title, description, form_id, applies_roles, applies_teams, sort_order)
    values ('form', f.title, left(f.intro, 300), f.id, coalesce(p_roles, '{}'), coalesce(p_teams, '{}'), 200)
    returning id into v_item;
  else
    update public.compliance_items
       set title = f.title, applies_roles = coalesce(p_roles, '{}'), applies_teams = coalesce(p_teams, '{}'), active = true, updated_at = now()
     where id = v_item;
  end if;
  return v_item;
end;
$$;

create or replace function public.form_out_of_compliance(p_form uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.can_manage_form(p_form) then
    raise exception 'You can''t change this form';
  end if;
  update public.compliance_items set active = false, updated_at = now() where form_id = p_form;
end;
$$;

-- Names of the people a form's managers may see in its report (staff names only).
create or replace function public.form_people(p_form uuid)
returns table (id uuid, name text, email text, role public.app_role)
language sql
stable
security definer
set search_path = ''
as $$
  select p.id, coalesce(nullif(p.full_name, ''), p.email), p.email, p.role
    from public.profiles p
   where public.can_manage_form(p_form) and p.active and p.role <> 'system_admin'
   order by 2
$$;

-- Who made the form, for "Questions? Contact …" at the bottom.
create or replace function public.form_contact(p_form uuid)
returns table (name text, email text)
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(nullif(p.full_name, ''), p.email), p.email
    from public.forms f join public.profiles p on p.id = f.created_by
   where f.id = p_form and (public.can_fill_form(p_form) or public.can_manage_form(p_form))
$$;

revoke execute on function public.can_make_forms(), public.can_manage_form(uuid), public.can_fill_form(uuid),
  public.submit_form_response(uuid, jsonb, boolean), public.send_form(uuid, uuid[], uuid, boolean), public.remind_form(uuid),
  public.form_to_compliance(uuid, public.app_role[], uuid[]), public.form_out_of_compliance(uuid),
  public.form_people(uuid), public.form_contact(uuid) from public, anon;
grant execute on function public.can_make_forms(), public.can_manage_form(uuid), public.can_fill_form(uuid),
  public.submit_form_response(uuid, jsonb, boolean), public.send_form(uuid, uuid[], uuid, boolean), public.remind_form(uuid),
  public.form_to_compliance(uuid, public.app_role[], uuid[]), public.form_out_of_compliance(uuid),
  public.form_people(uuid), public.form_contact(uuid) to authenticated;

-- Changes to forms and questions go in the change log.
drop trigger if exists forms_log on public.forms;
create trigger forms_log after insert or update or delete on public.forms
  for each row execute function public.log_feature_setup('form');

-- Files and photos attached to replies.
do $storage$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  insert into storage.buckets (id, name, public) values ('form-files', 'form-files', false) on conflict (id) do nothing;
  drop policy if exists "staff upload form files" on storage.objects;
  create policy "staff upload form files" on storage.objects
    for insert to authenticated
    with check (bucket_id = 'form-files' and public.is_member() and (storage.foldername(name))[1] = auth.uid()::text);
  drop policy if exists "form files are seen with their replies" on storage.objects;
  create policy "form files are seen with their replies" on storage.objects
    for select to authenticated
    using (bucket_id = 'form-files' and public.is_member()
           and ((storage.foldername(name))[1] = auth.uid()::text
                or exists (select 1 from public.form_responses r
                            where r.answers::text like '%' || storage.objects.name || '%'
                              and public.can_manage_form(r.form_id))));
end;
$storage$;

-- New replies and sends show up straight away on open pages.
do $live$
declare
  t text;
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    return;
  end if;
  foreach t in array array['forms', 'form_responses', 'form_completions'] loop
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end;
$live$;

$m049$;
  insert into public.install_log (name) values ('20261207000001_forms.sql');
end;
$part$;

-- ====================================================================
-- 20261208000001_forms_anonymous_choice.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261208000001_forms_anonymous_choice.sql') then
    return;
  end if;
  execute $m050$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Forms (cmeprojects): instead of a whole form being anonymous, a form can
-- allow it, and each person chooses: they tick "Answer anonymously" and their
-- name isn't kept with their answers. (forms.anonymous now means "allowed".)

comment on column public.forms.anonymous is 'People may tick "Answer anonymously" on this form.';

drop function if exists public.submit_form_response(uuid, jsonb, boolean);

-- Save a reply (p_send = false keeps it as a draft to finish later). If the
-- form allows it and they ticked "Answer anonymously", their name isn't kept
-- with the answers (only that they've done it).
create or replace function public.submit_form_response(p_form uuid, p_answers jsonb, p_send boolean default true, p_anonymous boolean default false)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  f public.forms;
  q record;
  v text;
  v_clean jsonb := '{}'::jsonb;
  v_id bigint;
  v_item uuid;
  v_anon boolean;
begin
  if not public.can_fill_form(p_form) then
    raise exception 'This form isn''t open';
  end if;
  select * into f from public.forms where id = p_form;
  v_anon := f.anonymous and coalesce(p_anonymous, false);
  if not f.repeatable and exists (select 1 from public.form_completions where form_id = f.id and user_id = auth.uid()) then
    raise exception 'You''ve already filled this in';
  end if;
  if p_answers is null or jsonb_typeof(p_answers) <> 'object' then
    raise exception 'Fill in the form';
  end if;

  for q in select * from public.form_questions where form_id = f.id and not archived order by sort_order loop
    if q.type = 'multi' then
      if jsonb_typeof(p_answers -> q.id::text) = 'array' and jsonb_array_length(p_answers -> q.id::text) > 0 then
        if exists (select 1 from jsonb_array_elements_text(p_answers -> q.id::text) x where not q.options ? x) then
          raise exception '%: choose from the list', q.label;
        end if;
        v_clean := v_clean || jsonb_build_object(q.id::text, p_answers -> q.id::text);
      elsif q.required and p_send then
        raise exception '%: choose at least one', q.label;
      end if;
      continue;
    end if;
    v := nullif(trim(p_answers ->> q.id::text), '');
    if v is null then
      if q.required and p_send then
        raise exception '%: this is needed', q.label;
      end if;
      continue;
    end if;
    if length(v) > (case when q.type = 'long' then 5000 else 300 end) then
      raise exception '%: that''s too long', q.label;
    end if;
    if q.type = 'choice' and not q.options ? v then
      raise exception '%: choose from the list', q.label;
    elsif q.type = 'yesno' and v not in ('Yes', 'No') then
      raise exception '%: choose Yes or No', q.label;
    elsif q.type = 'date' and v !~ '^\d{4}-\d{2}-\d{2}$' then
      raise exception '%: enter a date', q.label;
    elsif q.type = 'number' and v !~ '^-?\d+(\.\d+)?$' then
      raise exception '%: enter a number', q.label;
    elsif q.type = 'file' and v not like auth.uid()::text || '/%' then
      raise exception '%: upload the file again', q.label;
    end if;
    v_clean := v_clean || jsonb_build_object(q.id::text, v);
  end loop;

  -- Their saved draft becomes this reply (or stays a draft).
  select id into v_id from public.form_responses where form_id = f.id and user_id = auth.uid() and status = 'draft';
  if v_id is not null then
    update public.form_responses
       set answers = v_clean, updated_at = now(),
           status = case when p_send then 'submitted' else 'draft' end,
           submitted_at = case when p_send then now() end,
           user_id = case when p_send and v_anon then null else user_id end
     where id = v_id;
  else
    insert into public.form_responses (form_id, user_id, answers, status, submitted_at)
    values (f.id, case when p_send and v_anon then null else auth.uid() end, v_clean,
            case when p_send then 'submitted' else 'draft' end, case when p_send then now() end)
    returning id into v_id;
  end if;

  if p_send then
    insert into public.form_completions (form_id, user_id) values (f.id, auth.uid())
    on conflict (form_id, user_id) do update set done_at = now();
    -- Part of Compliance: it counts as done.
    for v_item in select id from public.compliance_items where form_id = f.id and active loop
      insert into public.compliance_records (item_id, user_id, version, status)
      select v_item, auth.uid(), version, 'done' from public.compliance_items where id = v_item;
    end loop;
    if f.notify_creator and f.created_by <> auth.uid() then
      perform public.notify(f.created_by, 'form_reply', format('New reply: %s', f.title),
        case when v_anon then 'Someone sent a reply anonymously.' else format('%s sent a reply.', public.my_name()) end,
        '/forms/' || f.id || '/replies', false);
    end if;
  end if;
  return v_id;
end;
$$;

revoke execute on function public.submit_form_response(uuid, jsonb, boolean, boolean) from public, anon;
grant execute on function public.submit_form_response(uuid, jsonb, boolean, boolean) to authenticated;

$m050$;
  insert into public.install_log (name) values ('20261208000001_forms_anonymous_choice.sql');
end;
$part$;

-- ====================================================================
-- 20261209000001_forms_questions.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261209000001_forms_questions.sql') then
    return;
  end if;
  execute $m051$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Forms (cmeprojects):
--   * A form put in Compliance is announced as "Please fill in: …" (not
--     "Please upload") and the note opens the form.
--   * "Ask a question" on a form: it becomes a task for the person who made
--     the form (General tasks), or a bell note and email if a task can't be
--     made (for example the asker is a new starter).

create or replace function public.compliance_item_announce()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  p record;
  v_word text := case new.kind when 'read' then 'Please read and confirm' when 'training' then 'New training' when 'form' then 'Please fill in' else 'Please upload' end;
begin
  if not new.active then
    return new;
  end if;
  if tg_op = 'UPDATE' and new.version = old.version and old.active then
    return new;
  end if;
  for p in
    select pr.id, pr.role, (select array_agg(team_id) from public.team_members where user_id = pr.id) teams
      from public.profiles pr
     where pr.active and pr.role <> 'system_admin'
  loop
    if public.compliance_applies(new, p.role, p.teams) then
      perform public.notify(p.id, 'onboarding_item',
        case when tg_op = 'UPDATE' and new.version > old.version then format('Updated: %s', new.title) else format('%s: %s', v_word, new.title) end,
        case when new.kind = 'form' then 'A form to fill in. It''s also on your My onboarding page.' else 'It''s on your My onboarding page.' end,
        case when new.kind = 'form' and new.form_id is not null then '/forms/' || new.form_id else '/onboarding' end);
    end if;
  end loop;
  return new;
end;
$$;

create or replace function public.ask_form_question(p_form uuid, p_question text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  f public.forms;
  v_task uuid;
  v_q text := left(trim(coalesce(p_question, '')), 2000);
begin
  if not (public.can_fill_form(p_form) or public.can_manage_form(p_form)) then
    raise exception 'Form not found';
  end if;
  if length(v_q) < 3 then
    raise exception 'Type your question';
  end if;
  select * into f from public.forms where id = p_form;
  if f.created_by = auth.uid() then
    raise exception 'This is your own form';
  end if;
  begin
    v_task := public.create_task(
      left(format('Question about the form: %s', f.title), 200),
      (select id from public.registries where is_default and kind = 'tasks' and active order by sort_order limit 1),
      f.created_by,
      format(E'%s\n\nAsked by %s from the form "%s".', v_q, public.my_name(), f.title),
      'medium');
    return 'task';
  exception when others then
    perform public.notify(f.created_by, 'form_question', format('Question about the form: %s', f.title),
      format('%s asks: %s', public.my_name(), v_q), '/forms/' || f.id || '/replies', true);
    return 'note';
  end;
end;
$$;
revoke execute on function public.ask_form_question(uuid, text) from public, anon;
grant execute on function public.ask_form_question(uuid, text) to authenticated;

$m051$;
  insert into public.install_log (name) values ('20261209000001_forms_questions.sql');
end;
$part$;

-- ====================================================================
-- 20261210000001_time_alerts.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261210000001_time_alerts.sql') then
    return;
  end if;
  execute $m052$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Time-based alerts for built features (cmeprojects). Checked every hour:
--   total_under_by  by a set time, a client's daily total is still under
--                   their target (e.g. under 1,500 ml at 6 pm)
--   no_entry_by     by a set time, nothing has been entered today
--                   (e.g. Fridge temps not done by 10 am)
-- They start switched off: the system admin sets the conditions and turns
-- each one on. Each runs once a day at most.

alter table public.custom_alerts drop constraint if exists custom_alerts_when_kind_check;
alter table public.custom_alerts add constraint custom_alerts_when_kind_check
  check (when_kind in ('any', 'choice', 'above', 'below', 'total_over', 'total_met', 'total_under_by', 'no_entry_by'));
alter table public.custom_alerts add column if not exists at_hour int check (at_hour between 0 and 23);

-- Which days a time alert has already run.
create table if not exists public.custom_alert_runs (
  alert_id uuid not null references public.custom_alerts (id) on delete cascade,
  day      date not null,
  primary key (alert_id, day)
);
alter table public.custom_alert_runs enable row level security;
revoke all on public.custom_alert_runs from anon, authenticated;

create or replace function public.run_feature_time_alerts()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tz text := coalesce((select value #>> '{}' from public.app_settings where key = 'region.timezone'), 'Australia/Melbourne');
  v_hour int := extract(hour from now() at time zone v_tz)::int;
  v_today date := (now() at time zone v_tz)::date;
  a public.custom_alerts;
  feat public.custom_features;
  v_unit text;
  v_lines text;
  v_title text;
  v_when text;
  v_user uuid;
  v_sent int := 0;
begin
  for a in
    select * from public.custom_alerts
     where active and when_kind in ('total_under_by', 'no_entry_by') and at_hour is not null and at_hour <= v_hour
  loop
    select * into feat from public.custom_features where id = a.feature_id;
    continue when not (feat.status = 'published' and feat.enabled);
    insert into public.custom_alert_runs (alert_id, day) values (a.id, v_today) on conflict do nothing;
    continue when not found;
    v_when := to_char(make_time(a.at_hour, 0, 0), 'FMHH12 am');
    v_lines := null;

    if a.when_kind = 'no_entry_by' then
      continue when exists (select 1 from public.custom_entries e
                             where e.feature_id = feat.id and (e.created_at at time zone v_tz)::date = v_today);
      v_title := format('%s: nothing entered yet today (%s)', feat.name, v_when);
      v_lines := 'No one has filled it in today.';
    else
      continue when feat.total_field is null;
      select unit into v_unit from public.custom_fields where id = feat.total_field;
      -- Clients with a target (their own, or the one for everyone) who are under it.
      select string_agg(format('%s: %s of %s%s', c.name, trim(to_char(t.total, 'FM999G999G990')), trim(to_char(t.target, 'FM999G999G990')),
                               case when coalesce(v_unit, '') <> '' then ' ' || v_unit else '' end), E'\n' order by c.name)
        into v_lines
        from public.car_clients c
        cross join lateral (
          select coalesce((select target from public.custom_client_targets where feature_id = feat.id and client_id = c.id), feat.default_target) target,
                 coalesce((select sum((e.data ->> feat.total_field::text)::numeric) from public.custom_entries e
                            where e.feature_id = feat.id and e.client_id = c.id
                              and jsonb_typeof(e.data -> feat.total_field::text) = 'number'
                              and (e.created_at at time zone v_tz)::date = v_today), 0) total
        ) t
       where c.active and t.target is not null and t.total < t.target;
      continue when v_lines is null;
      v_title := format('%s: under target at %s', feat.name, v_when);
    end if;

    v_title := coalesce(nullif(trim(replace(a.message, '{feature}', feat.name)), ''), v_title);
    for v_user in
      select p.id from public.profiles p
       where p.active and (p.role = any (a.notify_roles) or p.id = any (a.notify_people))
    loop
      if a.by_bell then
        insert into public.notifications (user_id, kind, title, body, href)
        values (v_user, 'feature_alert', left(v_title, 200), v_lines, '/reports/f/' || feat.slug || '?report=daily&range=today');
      end if;
      if a.by_email and public.feature_enabled('email_notifications') then
        insert into public.email_outbox (to_user, template, data)
        values (v_user, 'notice', jsonb_build_object('title', left(v_title, 200), 'body', v_lines, 'href', '/reports/f/' || feat.slug || '?report=daily&range=today'));
      end if;
      v_sent := v_sent + 1;
    end loop;
  end loop;
  return jsonb_build_object('time_alerts_sent', v_sent);
end;
$$;
revoke execute on function public.run_feature_time_alerts() from public, anon, authenticated;
grant execute on function public.run_feature_time_alerts() to service_role;

-- Runs after an entry is saved or fixed: tells people for each matching alert
-- (time-based alerts are checked by the hourly timer instead).
create or replace function public.fire_custom_alerts()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  feat public.custom_features;
  a public.custom_alerts;
  v_fixed boolean := tg_op = 'UPDATE';
  v_answer text;
  v_num numeric;
  v_target numeric;
  v_before numeric;
  v_after numeric;
  v_unit text;
  v_staff text;
  v_title text;
  v_body text;
  v_user uuid;
  v_detail text;
begin
  if v_fixed and new.data is not distinct from old.data then
    return new;
  end if;
  select * into feat from public.custom_features where id = new.feature_id;
  if not (feat.status = 'published' and feat.enabled) then
    return new;
  end if;
  select coalesce(nullif(full_name, ''), email) into v_staff from public.profiles where id = new.created_by;
  select unit into v_unit from public.custom_fields where id = feat.total_field;

  for a in select * from public.custom_alerts where feature_id = new.feature_id and active and (not v_fixed or on_fix)
                 and when_kind not in ('total_under_by', 'no_entry_by') loop
    v_detail := '';
    v_answer := case when a.field_id is null then null
                     when jsonb_typeof(new.data -> a.field_id::text) = 'array'
                       then (select string_agg(x, ', ') from jsonb_array_elements_text(new.data -> a.field_id::text) x)
                     else new.data ->> a.field_id::text end;

    if a.when_kind = 'choice' then
      if v_answer is null or not (lower(v_answer) = lower(a.match_text)
             or (jsonb_typeof(new.data -> a.field_id::text) = 'array'
                 and exists (select 1 from jsonb_array_elements_text(new.data -> a.field_id::text) x where lower(x) = lower(a.match_text)))) then
        continue;
      end if;
      v_detail := format('%s: %s', (select label from public.custom_fields where id = a.field_id), a.match_text);
    elsif a.when_kind in ('above', 'below') then
      begin
        v_num := v_answer::numeric;
      exception when others then
        continue;
      end;
      if v_num is null or a.limit_value is null
         or (a.when_kind = 'above' and v_num <= a.limit_value)
         or (a.when_kind = 'below' and v_num >= a.limit_value) then
        continue;
      end if;
      select format('%s: %s%s', label, rtrim(to_char(v_num, 'FM999G999G990D##'), '.'), case when unit <> '' then ' ' || unit else '' end)
        into v_detail from public.custom_fields where id = a.field_id;
    elsif a.when_kind in ('total_over', 'total_met') then
      if new.client_id is null or feat.total_field is null then
        continue;
      end if;
      v_target := coalesce((select target from public.custom_client_targets where feature_id = feat.id and client_id = new.client_id), feat.default_target);
      if v_target is null then
        continue;
      end if;
      v_after := public.custom_day_total(new, true);
      v_before := case when v_fixed then v_after - coalesce((new.data ->> feat.total_field::text)::numeric, 0)
                                               + coalesce((old.data ->> feat.total_field::text)::numeric, 0)
                       else public.custom_day_total(new, false) end;
      -- Only when the total crosses the line, so it's one alert a day.
      if (a.when_kind = 'total_over' and not (v_after > v_target and v_before <= v_target))
         or (a.when_kind = 'total_met' and not (v_after >= v_target and v_before < v_target)) then
        continue;
      end if;
      v_detail := format('%s is at %s of %s%s today', new.client_name, trim(to_char(v_after, 'FM999G999G990')),
                         trim(to_char(v_target, 'FM999G999G990')), case when v_unit <> '' then ' ' || v_unit else '' end);
    end if;

    v_title := coalesce(nullif(trim(replace(replace(replace(a.message, '{client}', new.client_name), '{staff}', v_staff), '{feature}', feat.name)), ''),
                        format('%s: %s', feat.name, coalesce(nullif(a.name, ''), case when a.when_kind = 'any' then 'new entry' else v_detail end)));
    v_body := concat_ws(' · ',
                        nullif(v_detail, ''),
                        nullif(case when a.when_kind in ('total_over', 'total_met') then '' else new.client_name end, ''),
                        format('%s by %s', case when v_fixed then 'Fixed' else 'Entered' end, v_staff));

    for v_user in
      select p.id from public.profiles p
       where p.active and p.id <> coalesce(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
         and (p.role = any (a.notify_roles)
              or p.id = any (a.notify_people)
              or (a.notify_leader and exists (select 1 from public.team_leaders l join public.team_members m on m.team_id = l.team_id
                                               where m.user_id = new.created_by and l.user_id = p.id)))
    loop
      if a.by_bell then
        insert into public.notifications (user_id, kind, title, body, href)
        values (v_user, 'feature_alert', left(v_title, 200), v_body, '/f/' || feat.slug);
      end if;
      if a.by_email and public.feature_enabled('email_notifications') then
        insert into public.email_outbox (to_user, template, data)
        values (v_user, 'notice', jsonb_build_object('title', left(v_title, 200), 'body', v_body, 'href', '/f/' || feat.slug));
      end if;
    end loop;
  end loop;
  return new;
end;
$$;

$m052$;
  insert into public.install_log (name) values ('20261210000001_time_alerts.sql');
end;
$part$;

-- ====================================================================
-- 20261211000001_assistant_website.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261211000001_assistant_website.sql') then
    return;
  end if;
  execute $m053$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Website and Assistant (cmeprojects): a public "ask anything" page that
-- answers only from documents the system admin uploads, and catches new
-- customer enquiries. A premium add-on, off until switched on.
--
--   assistant_settings   one row: wording, model and monthly limit
--   assistant_documents  what the system admin uploaded, and who may get
--                        answers from it (public / staff / managers)
--   assistant_chunks     those documents cut into searchable pieces
--   assistant_questions  a log of questions (no names), to find gaps
--   website_enquiries    people who left their details (the funnel)
--
-- The public pages talk to the database only through the server (service
-- role); the portal reads these as the signed-in person, so Row Level
-- Security decides who sees what.

insert into public.features (key, label, description, enabled, sort_order, premium, included) values
  ('assistant', 'Website and Assistant',
   'A public website where anyone can ask questions and get answers from your own documents, and leave their details to be called back. The system admin manages the documents; managers follow up the enquiries.',
   false, 79, true, false)
on conflict (key) do nothing;

create table if not exists public.assistant_settings (
  id             boolean primary key default true check (id),
  model          text not null default 'haiku' check (model in ('haiku', 'sonnet')),
  heading        text not null default 'How can we help today?',
  intro          text not null default 'Ask anything about our services, the NDIS or our policies. Answers come from our own documents, with the source shown.',
  disclaimer     text not null default 'General information only, not official NDIS advice.',
  fallback       text not null default 'I can''t find that in our documents. Please call us or leave your details and we''ll call you.',
  phone          text not null default '',
  offer_call     boolean not null default true,
  log_questions  boolean not null default true,
  monthly_limit_aud numeric(8,2) not null default 50 check (monthly_limit_aud >= 0),
  hourly_limit   int not null default 60 check (hourly_limit between 1 and 500),
  updated_at     timestamptz not null default now()
);
insert into public.assistant_settings default values on conflict do nothing;

create table if not exists public.assistant_documents (
  id         uuid primary key default gen_random_uuid(),
  title      text not null check (length(title) between 1 and 200),
  audience   text not null default 'public' check (audience in ('public', 'staff', 'managers')),
  body       text not null,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.assistant_chunks (
  id          bigint generated always as identity primary key,
  document_id uuid not null references public.assistant_documents (id) on delete cascade,
  position    int not null,
  content     text not null,
  fts         tsvector generated always as (to_tsvector('english', content)) stored
);
create index if not exists assistant_chunks_fts on public.assistant_chunks using gin (fts);
create index if not exists assistant_chunks_doc on public.assistant_chunks (document_id);

create table if not exists public.assistant_questions (
  id         bigint generated always as identity primary key,
  question   text not null,
  audience   text not null,
  answered   boolean not null,
  sources    text[] not null default '{}',
  cost_usd   numeric(10,6) not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists assistant_questions_when on public.assistant_questions (created_at desc);

create table if not exists public.website_enquiries (
  id         uuid primary key default gen_random_uuid(),
  full_name  text not null check (length(full_name) between 1 and 120),
  phone      text not null check (length(phone) between 6 and 40),
  email      text not null default '',
  suburb     text not null default '',
  support_for text not null default '',
  has_plan   text not null default '',
  managed_by text not null default '',
  needs      text[] not null default '{}',
  best_time  text not null default '',
  heard_from text not null default '',
  message    text not null default '',
  asked      text not null default '',
  source     text not null default 'form' check (source in ('form', 'chat')),
  status     text not null default 'new' check (status in ('new', 'called', 'meeting', 'client', 'closed')),
  note       text not null default '',
  consent    boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists website_enquiries_when on public.website_enquiries (created_at desc);

alter table public.assistant_settings  enable row level security;
alter table public.assistant_documents enable row level security;
alter table public.assistant_chunks    enable row level security;
alter table public.assistant_questions enable row level security;
alter table public.website_enquiries   enable row level security;

-- Nothing is open to the public through the database: the website's server
-- uses the service role. Signed-in people only get what their role allows.
revoke all on public.assistant_settings, public.assistant_documents, public.assistant_chunks,
  public.assistant_questions, public.website_enquiries from anon;
revoke all on public.assistant_chunks, public.assistant_questions from authenticated;
grant select on public.assistant_questions to authenticated;
grant select, insert, update, delete on public.assistant_documents to authenticated;
grant select, update on public.assistant_settings to authenticated;
grant select, update on public.website_enquiries to authenticated;

drop policy if exists assistant_settings_read on public.assistant_settings;
create policy assistant_settings_read on public.assistant_settings
  for select to authenticated using (public.is_system_admin());
drop policy if exists assistant_settings_write on public.assistant_settings;
create policy assistant_settings_write on public.assistant_settings
  for update to authenticated using (public.is_system_admin()) with check (public.is_system_admin());

drop policy if exists assistant_documents_all on public.assistant_documents;
create policy assistant_documents_all on public.assistant_documents
  for all to authenticated using (public.is_system_admin()) with check (public.is_system_admin());

drop policy if exists assistant_questions_read on public.assistant_questions;
create policy assistant_questions_read on public.assistant_questions
  for select to authenticated using (public.is_system_admin());

drop policy if exists website_enquiries_read on public.website_enquiries;
create policy website_enquiries_read on public.website_enquiries
  for select to authenticated using (public.has_role(array['manager', 'system_admin']::public.app_role[]));
drop policy if exists website_enquiries_update on public.website_enquiries;
create policy website_enquiries_update on public.website_enquiries
  for update to authenticated
  using (public.has_role(array['manager', 'system_admin']::public.app_role[]))
  with check (public.has_role(array['manager', 'system_admin']::public.app_role[]));

-- The system admin only changes the wording and limits (the guard is the
-- policy above); a plain update keeps the time fresh.
create or replace function public.assistant_touch() returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end $$;
drop trigger if exists assistant_settings_touch on public.assistant_settings;
create trigger assistant_settings_touch before update on public.assistant_settings
  for each row execute function public.assistant_touch();
drop trigger if exists website_enquiries_touch on public.website_enquiries;
create trigger website_enquiries_touch before update on public.website_enquiries
  for each row execute function public.assistant_touch();

-- Cuts a document into pieces of about 900 characters, on paragraph breaks,
-- and makes them searchable. Called by the server after an upload.
create or replace function public.assistant_index(p_document uuid)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_body text;
  v_piece text := '';
  v_para text;
  v_pos int := 0;
begin
  if not public.is_system_admin() then
    raise exception 'Only the system admin can do this' using errcode = '42501';
  end if;
  select body into v_body from public.assistant_documents where id = p_document;
  if v_body is null then return 0; end if;
  delete from public.assistant_chunks where document_id = p_document;
  foreach v_para in array regexp_split_to_array(v_body, E'\\n\\s*\\n') loop
    v_para := btrim(v_para);
    continue when v_para = '';
    -- A very long paragraph is split further.
    while length(v_para) > 1400 loop
      if v_piece <> '' then
        v_pos := v_pos + 1;
        insert into public.assistant_chunks (document_id, position, content) values (p_document, v_pos, v_piece);
        v_piece := '';
      end if;
      v_pos := v_pos + 1;
      insert into public.assistant_chunks (document_id, position, content) values (p_document, v_pos, left(v_para, 1200));
      v_para := substr(v_para, 1201);
    end loop;
    if length(v_piece) + length(v_para) > 900 and v_piece <> '' then
      v_pos := v_pos + 1;
      insert into public.assistant_chunks (document_id, position, content) values (p_document, v_pos, v_piece);
      v_piece := '';
    end if;
    v_piece := case when v_piece = '' then v_para else v_piece || E'\n\n' || v_para end;
  end loop;
  if v_piece <> '' then
    v_pos := v_pos + 1;
    insert into public.assistant_chunks (document_id, position, content) values (p_document, v_pos, v_piece);
  end if;
  return v_pos;
end $$;
revoke all on function public.assistant_index(uuid) from public, anon;
grant execute on function public.assistant_index(uuid) to authenticated;

-- The best matching pieces for a question, only from documents this kind of
-- visitor may use. Only the website's server (service role) can call this.
create or replace function public.assistant_search(p_query text, p_audiences text[], p_limit int default 5)
returns table (document_id uuid, title text, content text, rank real)
language sql
stable
security definer
set search_path = ''
as $$
  with q as (select websearch_to_tsquery('english', p_query) as tsq)
  select d.id, d.title, c.content, ts_rank_cd(c.fts, q.tsq) as rank
  from public.assistant_chunks c
  join public.assistant_documents d on d.id = c.document_id, q
  where d.audience = any (p_audiences) and c.fts @@ q.tsq
  order by rank desc
  limit greatest(1, least(p_limit, 10))
$$;
revoke all on function public.assistant_search(text, text[], int) from public, anon, authenticated;
grant execute on function public.assistant_search(text, text[], int) to service_role;

-- Questions asked this hour (for the limit) and money spent this month (AUD).
create or replace function public.assistant_usage()
returns table (this_month_usd numeric, last_hour bigint)
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select sum(cost_usd) from public.assistant_questions where created_at >= date_trunc('month', now())), 0),
         (select count(*) from public.assistant_questions where created_at >= now() - interval '1 hour')
$$;
revoke all on function public.assistant_usage() from public, anon, authenticated;
grant execute on function public.assistant_usage() to service_role;

-- Counts for the portal dashboard and menu: new enquiries.
create or replace function public.new_enquiry_count()
returns bigint
language sql
stable
security definer
set search_path = ''
as $$
  select case when public.has_role(array['manager', 'system_admin']::public.app_role[])
    then (select count(*) from public.website_enquiries where status = 'new') else 0 end
$$;
revoke all on function public.new_enquiry_count() from public, anon;
grant execute on function public.new_enquiry_count() to authenticated;

-- A new enquiry also tells the managers by the bell.
create or replace function public.website_enquiry_notify() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.notifications (user_id, kind, title, body, href)
  select p.id, 'website_enquiry', 'New enquiry: ' || new.full_name,
         'Phone ' || new.phone || '. Call them back.', '/enquiries'
  from public.profiles p where p.active and p.role in ('manager', 'system_admin');
  return new;
end $$;

drop trigger if exists website_enquiry_notify on public.website_enquiries;
create trigger website_enquiry_notify after insert on public.website_enquiries
  for each row execute function public.website_enquiry_notify();

$m053$;
  insert into public.install_log (name) values ('20261211000001_assistant_website.sql');
end;
$part$;

-- ====================================================================
-- 20261212000001_quick_fixes.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261212000001_quick_fixes.sql') then
    return;
  end if;
  execute $m054$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Quick fixes (cmeprojects):
--   * Forms "To fill in": forms sent to me, in Compliance for my role or
--     team, or open to everyone (not sent to anyone in particular).
--   * Who sees website enquiries is a System setting (managers by default).
--   * Five wrong passwords lock that email out for 15 minutes.
--   * Compliance becomes a premium add-on (on for companies already using it);
--     while it's off, nothing can be added to Compliance.
--   * Any built feature nobody has used yet can be deleted (not only drafts).
--   * Open pages hear about role changes straight away.

-- Forms to fill in ------------------------------------------------------------
create or replace function public.my_forms_to_fill()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select f.id from public.forms f
   where public.can_fill_form(f.id)
     and (exists (select 1 from public.form_recipients r where r.form_id = f.id and r.user_id = auth.uid())
          or exists (select 1 from public.compliance_items i
                      where i.form_id = f.id and i.active
                        and (cardinality(i.applies_roles) = 0 or public.my_role() = any (i.applies_roles))
                        and (cardinality(i.applies_teams) = 0 or exists (
                              select 1 from public.team_members m where m.user_id = auth.uid() and m.team_id = any (i.applies_teams))))
          or (not exists (select 1 from public.form_recipients r where r.form_id = f.id)
              and not exists (select 1 from public.compliance_items i where i.form_id = f.id)))
$$;
revoke all on function public.my_forms_to_fill() from public, anon;
grant execute on function public.my_forms_to_fill() to authenticated;

-- Who sees enquiries ----------------------------------------------------------
insert into public.app_settings (key, value, label, description, is_public) values
  ('assistant.enquiry_roles', '["manager"]', 'Who sees website enquiries',
   'Besides the system admin. They see Enquiries in the menu and get a bell note for each new one.', false)
on conflict (key) do nothing;

create or replace function public.can_see_enquiries()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and (public.is_system_admin()
    or public.my_role()::text in (select jsonb_array_elements_text(coalesce(
         (select value from public.app_settings where key = 'assistant.enquiry_roles'), '[]'))))
$$;
revoke all on function public.can_see_enquiries() from public, anon;
grant execute on function public.can_see_enquiries() to authenticated;

drop policy if exists website_enquiries_read on public.website_enquiries;
create policy website_enquiries_read on public.website_enquiries
  for select to authenticated using (public.can_see_enquiries());
drop policy if exists website_enquiries_update on public.website_enquiries;
create policy website_enquiries_update on public.website_enquiries
  for update to authenticated using (public.can_see_enquiries()) with check (public.can_see_enquiries());

create or replace function public.new_enquiry_count()
returns bigint
language sql
stable
security definer
set search_path = ''
as $$
  select case when public.can_see_enquiries() then (select count(*) from public.website_enquiries where status = 'new') else 0 end
$$;

create or replace function public.website_enquiry_notify() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.notifications (user_id, kind, title, body, href)
  select p.id, 'website_enquiry', 'New enquiry: ' || new.full_name, 'Phone ' || new.phone || '. Call them back.', '/enquiries'
    from public.profiles p
   where p.active and (p.role = 'system_admin' or p.role::text in (select jsonb_array_elements_text(coalesce(
           (select value from public.app_settings where key = 'assistant.enquiry_roles'), '[]'))));
  return new;
end $$;

-- Five wrong passwords: locked for 15 minutes ---------------------------------
create table if not exists public.sign_in_failures (
  email        text primary key,
  failed       int not null default 0,
  locked_until timestamptz,
  updated_at   timestamptz not null default now()
);
alter table public.sign_in_failures enable row level security;
revoke all on public.sign_in_failures from anon, authenticated;

-- 'check': minutes still locked (0 = free); 'fail': count a wrong password;
-- 'ok': signed in, start again. Only the server (service role) calls it.
create or replace function public.sign_in_guard(p_email text, p_event text)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row public.sign_in_failures;
  v_email text := lower(btrim(p_email));
begin
  select * into v_row from public.sign_in_failures where email = v_email;
  if p_event = 'ok' then
    delete from public.sign_in_failures where email = v_email;
    return 0;
  end if;
  if v_row.locked_until is not null and v_row.locked_until > now() then
    return ceil(extract(epoch from v_row.locked_until - now()) / 60)::int;
  end if;
  if p_event = 'fail' then
    insert into public.sign_in_failures as s (email, failed, updated_at) values (v_email, 1, now())
    on conflict (email) do update
      set failed = case when s.locked_until is not null and s.locked_until <= now() then 1 else s.failed + 1 end,
          locked_until = case when s.locked_until is not null and s.locked_until <= now() then null else s.locked_until end,
          updated_at = now()
    returning * into v_row;
    if v_row.failed >= 5 then
      update public.sign_in_failures set locked_until = now() + interval '15 minutes', failed = 0 where email = v_email;
      return 15;
    end if;
  end if;
  return 0;
end $$;
revoke all on function public.sign_in_guard(text, text) from public, anon, authenticated;
grant execute on function public.sign_in_guard(text, text) to service_role;

-- Compliance as a premium add-on ----------------------------------------------
insert into public.features (key, label, description, enabled, sort_order, premium, included) values
  ('compliance', 'Compliance (staff management)',
   'Onboarding, documents to read, trainings, uploads with expiry dates, and the Compliance report.',
   true, 40, true, true)
on conflict (key) do nothing;

create or replace function public.compliance_items_guard() returns trigger language plpgsql set search_path = '' as $$
begin
  if not public.feature_enabled('compliance') then
    raise exception 'Compliance is switched off' using errcode = '42501';
  end if;
  return new;
end $$;
drop trigger if exists compliance_items_guard on public.compliance_items;
create trigger compliance_items_guard before insert on public.compliance_items
  for each row execute function public.compliance_items_guard();

-- Delete any built feature nobody has used -----------------------------------
drop policy if exists "the builder removes unused drafts" on public.custom_features;
drop policy if exists "the builder removes unused features" on public.custom_features;
create policy "the builder removes unused features" on public.custom_features for delete to authenticated
  using (public.can_build_features()
         and not exists (select 1 from public.custom_entries e where e.feature_id = custom_features.id));

-- Role changes are heard straight away ----------------------------------------
do $live$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'profiles') then
    alter publication supabase_realtime add table public.profiles;
  end if;
end;
$live$;

$m054$;
  insert into public.install_log (name) values ('20261212000001_quick_fixes.sql');
end;
$part$;

-- ====================================================================
-- 20261213000001_website_v2.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261213000001_website_v2.sql') then
    return;
  end if;
  execute $m055$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Website and Assistant, version 2 (cmeprojects):
--   * Chat history for signed-in staff (each person sees only their own).
--   * The website can be the front page (a public setting the sign-in
--     check reads before anyone signs in).
--   * Suggested questions and credits are set in Website settings.
--   * Where the assistant looks, per group: documents, listed websites, or both.
--   * Reading scanned PDFs and photos costs a little; it counts towards the
--     monthly limit.

alter table public.assistant_settings add column if not exists suggestions text[] not null
  default array['What services do you offer?', 'What''s your cancellation policy?', 'How do I start with you?', 'How does NDIS funding work?'];
alter table public.assistant_settings add column if not exists show_credits boolean not null default true;
alter table public.assistant_settings add column if not exists scope_public text not null default 'documents';
alter table public.assistant_settings add column if not exists scope_staff text not null default 'documents';
alter table public.assistant_settings add column if not exists scope_managers text not null default 'documents';
alter table public.assistant_settings add column if not exists trusted_sites text[] not null
  default array['ndis.gov.au', 'ndiscommission.gov.au', 'legislation.gov.au'];
alter table public.assistant_settings drop constraint if exists assistant_settings_scope_check;
alter table public.assistant_settings add constraint assistant_settings_scope_check check (
  scope_public in ('documents', 'web', 'both') and scope_staff in ('documents', 'web', 'both') and scope_managers in ('documents', 'web', 'both')
  and cardinality(trusted_sites) <= 30 and cardinality(suggestions) <= 8);

alter table public.assistant_documents add column if not exists read_cost_usd numeric(10,6) not null default 0;

-- The front-page switch is public (it is read before signing in).
insert into public.app_settings (key, value, label, description, is_public) values
  ('website.front_page', 'false', 'Website is the front page',
   'Visitors who aren''t signed in see the website first; staff sign in from there.', true)
on conflict (key) do nothing;

-- Spending this month includes reading scanned documents.
create or replace function public.assistant_usage()
returns table (this_month_usd numeric, last_hour bigint)
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select sum(cost_usd) from public.assistant_questions where created_at >= date_trunc('month', now())), 0)
       + coalesce((select sum(read_cost_usd) from public.assistant_documents where created_at >= date_trunc('month', now())), 0),
         (select count(*) from public.assistant_questions where created_at >= now() - interval '1 hour')
$$;

-- Chat history -----------------------------------------------------------------
create table if not exists public.assistant_chats (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  title      text not null default 'New chat' check (length(title) <= 120),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists assistant_chats_user on public.assistant_chats (user_id, updated_at desc);

create table if not exists public.assistant_messages (
  id         bigint generated always as identity primary key,
  chat_id    uuid not null references public.assistant_chats (id) on delete cascade,
  question   text not null check (length(question) <= 500),
  answer     text not null,
  sources    jsonb not null default '[]',
  answered   boolean not null default true,
  created_at timestamptz not null default now()
);
create index if not exists assistant_messages_chat on public.assistant_messages (chat_id, id);

alter table public.assistant_chats enable row level security;
alter table public.assistant_messages enable row level security;
revoke all on public.assistant_chats, public.assistant_messages from anon;
grant select, insert, update, delete on public.assistant_chats to authenticated;
grant select, insert, delete on public.assistant_messages to authenticated;

drop policy if exists assistant_chats_own on public.assistant_chats;
create policy assistant_chats_own on public.assistant_chats for all to authenticated
  using (user_id = auth.uid() and public.is_member()) with check (user_id = auth.uid() and public.is_member());
drop policy if exists assistant_messages_own on public.assistant_messages;
create policy assistant_messages_own on public.assistant_messages for all to authenticated
  using (exists (select 1 from public.assistant_chats c where c.id = chat_id and c.user_id = auth.uid()))
  with check (exists (select 1 from public.assistant_chats c where c.id = chat_id and c.user_id = auth.uid()));

-- A new message brings its chat to the top of the list.
create or replace function public.assistant_chat_touch() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  update public.assistant_chats set updated_at = now() where id = new.chat_id;
  return new;
end $$;
drop trigger if exists assistant_messages_touch on public.assistant_messages;
create trigger assistant_messages_touch after insert on public.assistant_messages
  for each row execute function public.assistant_chat_touch();

$m055$;
  insert into public.install_log (name) values ('20261213000001_website_v2.sql');
end;
$part$;

-- ====================================================================
-- 20261214000001_limited_tasks.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261214000001_limited_tasks.sql') then
    return;
  end if;
  execute $m056$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Limited tasks (cmeprojects): some roles (support workers by default) may
-- only raise General tasks and questions themselves. Tasks made for them by
-- the portal (alerts, form questions) aren't affected.

insert into public.app_settings (key, value, label, description, is_public) values
  ('tasks.limited_roles', '["support_worker"]', 'Who can only raise General tasks and questions',
   'They don''t see the other registers in New task. They follow what they raised in My tasks → My requests and questions.', false)
on conflict (key) do nothing;

create or replace function public.limited_task_guard() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  -- Only a person creating a task themselves (not a task made by another rule).
  if pg_trigger_depth() = 1 and new.created_by = auth.uid()
     and public.my_role()::text in (select jsonb_array_elements_text(coalesce(
           (select value from public.app_settings where key = 'tasks.limited_roles'), '[]')))
     and not exists (select 1 from public.registries r where r.id = new.registry_id and r.is_default) then
    raise exception 'You can raise General tasks and questions only' using errcode = '42501';
  end if;
  return new;
end $$;
drop trigger if exists limited_task_guard on public.tasks;
create trigger limited_task_guard before insert on public.tasks
  for each row execute function public.limited_task_guard();

$m056$;
  insert into public.install_log (name) values ('20261214000001_limited_tasks.sql');
end;
$part$;

-- ====================================================================
-- 20261215000001_website_round2.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261215000001_website_round2.sql') then
    return;
  end if;
  execute $m057$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Website, round 2 (cmeprojects):
--   * The system admin can hand "Website" (where the Assistant looks, and
--     its documents) to a manager, like the other System settings areas.
--   * The website's own logo (blank = the portal's), and the words shown
--     while the website is switched off.
--   * Credit bought for the AI, so Website settings can show what's left.
--   * The website becomes the front page.

alter table public.admin_delegations drop constraint if exists admin_delegations_areas_check;
alter table public.admin_delegations add constraint admin_delegations_areas_check
  check (areas <@ array['branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'audit', 'website']);

create or replace function public.setting_area(p_key text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when p_key in ('brand.support_contact', 'brand.announcement', 'people.invite_message') then 'messages'
    when p_key like 'brand.%' or p_key like 'wording.%' then 'branding'
    when p_key like 'people.%' then 'people'
    when p_key like 'compliance.%' then 'compliance'
    when p_key like 'tasks.%' then 'tasks'
    when p_key like 'reports.%' then 'reports'
    when p_key like 'vehicles.%' then 'vehicles'
    when p_key like 'website.%' or p_key like 'assistant.%' then 'website'
    else null
  end
$$;

insert into public.app_settings (key, value, label, description, is_public) values
  ('website.logo_url', '""', 'Website logo', 'Leave empty to use the portal''s logo.', true),
  ('website.closed_title', '"Our website is coming soon"', 'Heading while the website is off', 'Shown when Website and Assistant is switched off.', true),
  ('website.closed_text', '"In the meantime, please call us, or sign in if you''re part of the team."', 'Words while the website is off', 'Shown under that heading.', true)
on conflict (key) do nothing;
update public.app_settings set value = 'true' where key = 'website.front_page';

alter table public.assistant_settings add column if not exists credit_aud numeric(8,2) not null default 0 check (credit_aud >= 0);
alter table public.assistant_settings add column if not exists credit_since date;

-- Website settings and documents: the system admin, or a manager given "Website".
drop policy if exists assistant_settings_read on public.assistant_settings;
create policy assistant_settings_read on public.assistant_settings
  for select to authenticated using (public.can_admin_area('website'));
drop policy if exists assistant_settings_write on public.assistant_settings;
create policy assistant_settings_write on public.assistant_settings
  for update to authenticated using (public.can_admin_area('website')) with check (public.can_admin_area('website'));
drop policy if exists assistant_documents_all on public.assistant_documents;
create policy assistant_documents_all on public.assistant_documents
  for all to authenticated using (public.can_admin_area('website')) with check (public.can_admin_area('website'));
drop policy if exists assistant_questions_read on public.assistant_questions;
create policy assistant_questions_read on public.assistant_questions
  for select to authenticated using (public.can_admin_area('website'));

-- Indexing a document: the same people.
create or replace function public.assistant_index(p_document uuid)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_body text;
  v_piece text := '';
  v_para text;
  v_pos int := 0;
begin
  if not public.can_admin_area('website') then
    raise exception 'Only the system admin (or a manager given Website) can do this' using errcode = '42501';
  end if;
  select body into v_body from public.assistant_documents where id = p_document;
  if v_body is null then return 0; end if;
  delete from public.assistant_chunks where document_id = p_document;
  foreach v_para in array regexp_split_to_array(v_body, E'\\n\\s*\\n') loop
    v_para := btrim(v_para);
    continue when v_para = '';
    -- A very long paragraph is split further.
    while length(v_para) > 1400 loop
      if v_piece <> '' then
        v_pos := v_pos + 1;
        insert into public.assistant_chunks (document_id, position, content) values (p_document, v_pos, v_piece);
        v_piece := '';
      end if;
      v_pos := v_pos + 1;
      insert into public.assistant_chunks (document_id, position, content) values (p_document, v_pos, left(v_para, 1200));
      v_para := substr(v_para, 1201);
    end loop;
    if length(v_piece) + length(v_para) > 900 and v_piece <> '' then
      v_pos := v_pos + 1;
      insert into public.assistant_chunks (document_id, position, content) values (p_document, v_pos, v_piece);
      v_piece := '';
    end if;
    v_piece := case when v_piece = '' then v_para else v_piece || E'\n\n' || v_para end;
  end loop;
  if v_piece <> '' then
    v_pos := v_pos + 1;
    insert into public.assistant_chunks (document_id, position, content) values (p_document, v_pos, v_piece);
  end if;
  return v_pos;
end $$;
revoke all on function public.assistant_index(uuid) from public, anon;
grant execute on function public.assistant_index(uuid) to authenticated;

-- Questions from forms are tagged "Staff question" too.
create or replace function public.ask_form_question(p_form uuid, p_question text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  f public.forms;
  v_task uuid;
  v_q text := left(trim(coalesce(p_question, '')), 2000);
begin
  if not (public.can_fill_form(p_form) or public.can_manage_form(p_form)) then
    raise exception 'Form not found';
  end if;
  if length(v_q) < 3 then
    raise exception 'Type your question';
  end if;
  select * into f from public.forms where id = p_form;
  if f.created_by = auth.uid() then
    raise exception 'This is your own form';
  end if;
  begin
    v_task := public.create_task(
      left(format('Staff question: about the form %s', f.title), 200),
      (select id from public.registries where is_default and kind = 'tasks' and active order by sort_order limit 1),
      f.created_by,
      format(E'%s\n\nAsked by %s from the form "%s".', v_q, public.my_name(), f.title),
      'medium');
    return 'task';
  exception when others then
    perform public.notify(f.created_by, 'form_question', format('Staff question: about the form %s', f.title),
      format('%s asks: %s', public.my_name(), v_q), '/forms/' || f.id || '/replies', true);
    return 'note';
  end;
end;
$$;

$m057$;
  insert into public.install_log (name) values ('20261215000001_website_round2.sql');
end;
$part$;

-- ====================================================================
-- 20261216000001_enquiry_intake.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261216000001_enquiry_intake.sql') then
    return;
  end if;
  execute $m058$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Enquiry intake (cmeprojects): each new website enquiry becomes a "Call
-- back" task for the intake person (staff admins to start with; the system
-- admin can change who), due the next business day: weekends and public
-- holidays don't count. They get the bell straight away and an email once
-- emails are switched on.

insert into public.app_settings (key, value, label, description, is_public) values
  ('assistant.intake_roles', '["staff_admin"]', 'Who calls back new enquiries',
   'Each new enquiry becomes a Call back task for one of them (whoever has the fewest open), due the next business day.', false),
  ('tasks.public_holidays', '["2026-12-25 Christmas Day", "2026-12-28 Boxing Day (observed)", "2027-01-01 New Year''s Day", "2027-01-26 Australia Day", "2027-03-08 Labour Day", "2027-03-26 Good Friday", "2027-03-27 Easter Saturday", "2027-03-29 Easter Monday", "2027-06-14 King''s Birthday", "2027-11-02 Melbourne Cup", "2027-12-27 Christmas Day (observed)", "2027-12-28 Boxing Day (observed)"]',
   'Public holidays', 'One per line: the date (YYYY-MM-DD), then its name. These don''t count as business days (Victoria to start with; add the Grand Final Friday each year).', false)
on conflict (key) do nothing;

-- The next business day after a date: not a weekend, not a listed holiday.
create or replace function public.next_business_day(p_from date)
returns date
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  d date := p_from + 1;
  v_holidays date[];
begin
  select coalesce(array_agg(left(h, 10)::date), '{}') into v_holidays
    from jsonb_array_elements_text(coalesce((select value from public.app_settings where key = 'tasks.public_holidays'), '[]')) h
   where h ~ '^\d{4}-\d{2}-\d{2}';
  while extract(isodow from d) in (6, 7) or d = any (v_holidays) loop
    d := d + 1;
  end loop;
  return d;
end $$;

create or replace function public.website_enquiry_notify() returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_intake uuid;
  v_registry uuid;
  v_task uuid;
begin
  -- The people who see enquiries get the bell.
  insert into public.notifications (user_id, kind, title, body, href)
  select p.id, 'website_enquiry', 'New enquiry: ' || new.full_name, 'Phone ' || new.phone || '. Call them back.', '/enquiries'
    from public.profiles p
   where p.active and (p.role = 'system_admin' or p.role::text in (select jsonb_array_elements_text(coalesce(
           (select value from public.app_settings where key = 'assistant.enquiry_roles'), '[]'))));

  -- A Call back task for the intake person with the fewest open ones.
  select p.id into v_intake
    from public.profiles p
   where p.active and p.role::text in (select jsonb_array_elements_text(coalesce(
           (select value from public.app_settings where key = 'assistant.intake_roles'), '[]')))
   order by (select count(*) from public.tasks t where t.assigned_to = p.id and t.title like 'Call back: %'
              and t.status not in ('completed', 'closed')), p.full_name
   limit 1;
  select id into v_registry from public.registries where is_default and kind = 'tasks' and active order by sort_order limit 1;
  if v_intake is null or v_registry is null then
    return new;
  end if;

  insert into public.tasks (title, description, registry_id, ref_number, priority, assigned_to, created_by, due_date, details, date_reported)
  values (left('Call back: ' || new.full_name, 200),
          concat_ws(E'\n', 'New enquiry from the website. Please call them back by the due date.', '',
            'Phone: ' || new.phone,
            nullif('Email: ' || new.email, 'Email: '),
            nullif('Suburb: ' || new.suburb, 'Suburb: '),
            nullif('Support is for: ' || new.support_for, 'Support is for: '),
            nullif('NDIS plan: ' || concat_ws(', ', nullif(new.has_plan, ''), nullif(new.managed_by, '')), 'NDIS plan: '),
            nullif('Looking for: ' || array_to_string(new.needs, ', '), 'Looking for: '),
            nullif('Best time to call: ' || new.best_time, 'Best time to call: '),
            nullif('They asked the assistant: ' || new.asked, 'They asked the assistant: '),
            nullif('Message: ' || new.message, 'Message: ')),
          v_registry, public.take_ref_number(v_registry), 'high', v_intake, v_intake,
          public.next_business_day(public.local_today()), '{}'::jsonb, public.local_today())
  returning id into v_task;
  insert into public.task_events (task_id, actor_id, type, to_value) values (v_task, null, 'created', v_intake::text);
  perform public.queue_task_email('task_assigned', v_task, v_intake);
  insert into public.notifications (user_id, kind, title, body, href)
  values (v_intake, 'task_assigned', 'Call back: ' || new.full_name, 'A new enquiry from the website. Due the next business day.', '/tasks/' || v_task);
  return new;
end $$;

$m058$;
  insert into public.install_log (name) values ('20261216000001_enquiry_intake.sql');
end;
$part$;

-- ====================================================================
-- 20261217000001_website_about_seo.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261217000001_website_about_seo.sql') then
    return;
  end if;
  execute $m059$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Website: the About page, phone numbers and search-engine settings
-- (cmeprojects). All are words the public website shows, so they're public
-- settings; only the system admin (or a manager given "Website") changes them.

insert into public.app_settings (key, value, label, description, is_public) values
  ('website.staff_phone', '""', 'Number staff call when the Assistant can''t help',
   'Signed-in staff see "Can''t find an answer? Contact your manager" with this number.', true),
  ('website.about_intro', '""', 'About us', 'A short introduction to the company for the About page.', true),
  ('website.mission', '""', 'Our mission', 'Shown on the About page.', true),
  ('website.vision', '""', 'Our vision', 'Shown on the About page.', true),
  ('website.services', '[]', 'Our services', 'One per line, shown on the About page.', true),
  ('website.site_url', '""', 'Website address', 'The address people use, for example https://yourcompany.com.au. Used by search engines.', true),
  ('website.seo_title', '""', 'Title in search results', 'About 50 to 60 characters, for example: Your Company | NDIS support services in your area.', true),
  ('website.seo_description', '""', 'Description in search results', 'About 150 characters: who you are, what you do and where.', true)
on conflict (key) do nothing;

-- Security tidy-up (code audit): task_label() is only used inside other
-- database functions. Nobody should call it directly (it would show a task's
-- title to anyone who knew its ID).
revoke execute on function public.task_label(uuid) from public, anon, authenticated;

$m059$;
  insert into public.install_log (name) values ('20261217000001_website_about_seo.sql');
end;
$part$;

-- ====================================================================
-- 20261218000001_demo_data.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261218000001_demo_data.sql') then
    return;
  end if;
  execute $m060$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Demo data tools for the system admin (cmeprojects): load a fresh set of
-- sample records to show the portal, delete just those sample records, or
-- clear every task to start again. Each sample record is listed in
-- demo_records, so deleting them never touches real work.

create table if not exists public.demo_records (
  table_name text not null check (table_name in ('tasks', 'website_enquiries')),
  row_id     uuid not null,
  primary key (table_name, row_id)
);
alter table public.demo_records enable row level security;
revoke all on public.demo_records from anon, authenticated;

-- Removes the given tasks and everything hanging off them. Task history is
-- normally append-only; its guard is lifted for this delete only.
create or replace function public.delete_tasks_completely(p_ids uuid[])
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count int;
begin
  if not public.is_system_admin() then
    raise exception 'Only the system admin can do this' using errcode = '42501';
  end if;
  if coalesce(cardinality(p_ids), 0) = 0 then
    return 0;
  end if;
  update public.tasks set parent_task_id = null where parent_task_id = any (p_ids);
  update public.people_change_requests set task_id = null where task_id = any (p_ids);
  delete from public.notifications where href in (select '/tasks/' || unnest(p_ids)::text);
  delete from public.email_outbox where task_id = any (p_ids);
  alter table public.task_events disable trigger task_events_append_only;
  delete from public.task_events where task_id = any (p_ids);
  alter table public.task_events enable trigger task_events_append_only;
  delete from public.tasks where id = any (p_ids);
  get diagnostics v_count = row_count;
  delete from public.demo_records where table_name = 'tasks' and row_id = any (p_ids);
  return v_count;
end $$;
revoke all on function public.delete_tasks_completely(uuid[]) from public, anon, authenticated;

-- Every task, sample or real. The system admin types DELETE to confirm in the portal.
create or replace function public.demo_clear_all_tasks()
returns int
language sql
security definer
set search_path = ''
as $$
  select public.delete_tasks_completely(coalesce((select array_agg(id) from public.tasks), '{}'))
$$;
revoke all on function public.demo_clear_all_tasks() from public, anon;
grant execute on function public.demo_clear_all_tasks() to authenticated;

-- Only the sample records loaded by demo_load().
create or replace function public.demo_clear()
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tasks int;
  v_enquiries int;
begin
  if not public.is_system_admin() then
    raise exception 'Only the system admin can do this' using errcode = '42501';
  end if;
  v_tasks := public.delete_tasks_completely(coalesce((select array_agg(row_id) from public.demo_records where table_name = 'tasks'), '{}'));
  delete from public.notifications n using public.website_enquiries e, public.demo_records d
   where d.table_name = 'website_enquiries' and d.row_id = e.id and n.kind = 'website_enquiry' and n.title = 'New enquiry: ' || e.full_name;
  delete from public.website_enquiries where id in (select row_id from public.demo_records where table_name = 'website_enquiries');
  get diagnostics v_enquiries = row_count;
  delete from public.demo_records where table_name = 'website_enquiries';
  return v_tasks + v_enquiries;
end $$;
revoke all on function public.demo_clear() from public, anon;
grant execute on function public.demo_clear() to authenticated;

-- A fresh set of sample records: 12 tasks across the registers, in different
-- states, given to the active staff in turn, plus 3 website enquiries (each
-- makes its own Call back task). No emails go out for them.
create or replace function public.demo_load()
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_people uuid[];
  v_general uuid;
  v_task uuid;
  v_enquiry uuid;
  v_today date := public.local_today();
  v_count int := 0;
  i int := 0;
  r record;
begin
  if not public.is_system_admin() then
    raise exception 'Only the system admin can do this' using errcode = '42501';
  end if;
  select array_agg(id order by full_name) into v_people
    from public.profiles where active and role not in ('system_admin', 'new_starter');
  select id into v_general from public.registries where is_default and kind = 'tasks' and active order by sort_order limit 1;
  if v_people is null or v_general is null then
    raise exception 'Add at least one active staff member first';
  end if;

  for r in
    select * from (values
      ('Fall in the lounge: follow up with family', 'incident', 'urgent', 'in_progress', -1, 'Client slipped near the lounge door at 3 pm. Check the floor mats and call the family.'),
      ('Medication missed: morning dose', 'incident', 'high', 'assigned', 0, 'Morning dose not signed for. Check with the support worker and the pharmacy pack.'),
      ('Replace smoke alarm battery: Unit 4', 'maint', 'low', 'assigned', 5, 'Beeping since Tuesday.'),
      ('Fix the back gate latch', 'maint', 'medium', 'completed', -3, 'Gate doesn''t close by itself.'),
      ('Wet floor near the kitchen: risk review', 'risk', 'medium', 'assigned', 7, 'Slippery after mopping. Review signage and mopping times.'),
      ('Car service due: Corolla 1AB 2CD', 'general', 'medium', 'assigned', 3, 'Book the 60,000 km service.'),
      ('Order gloves and hand sanitiser', 'general', 'low', 'completed', -2, 'Monthly order for all houses.'),
      ('Roster: cover for Saturday afternoon', 'general', 'high', 'in_progress', 1, 'Need cover for 2 pm to 8 pm.'),
      ('Staff question: can I swap my Saturday shift?', 'general', 'medium', 'assigned', 2, 'Swap with Lee for Sunday. Is that OK?'),
      ('Update the emergency contacts list', 'general', 'medium', 'escalated', -2, 'Two numbers are out of date.'),
      ('Client review meeting: plan goals', 'general', 'high', 'assigned', 4, 'Prepare notes for the plan review.'),
      ('First aid certificate renewals', 'general', 'medium', 'assigned', 10, 'Three certificates expire next month.')
    ) as t(title, kind, priority, status, due_in, description)
  loop
    i := i + 1;
    insert into public.tasks (title, description, registry_id, ref_number, priority, assigned_to, created_by, due_date, details, date_reported, status, completed_at)
    select r.title, r.description, reg.id, public.take_ref_number(reg.id), r.priority::public.task_priority,
           v_people[1 + (i % cardinality(v_people))], auth.uid(), v_today + r.due_in, '{}'::jsonb, v_today - 2,
           r.status::public.task_status, case when r.status = 'completed' then now() - interval '1 day' end
      from (select coalesce(
              (select id from public.registries where kind = 'tasks' and active and not is_default
                 and name ilike case r.kind when 'incident' then '%incident%' when 'maint' then '%mainten%' when 'risk' then '%risk%' else '-' end
               order by sort_order limit 1),
              v_general) as id) reg
    returning id into v_task;
    insert into public.task_events (task_id, actor_id, type, to_value) values (v_task, auth.uid(), 'created', null);
    insert into public.demo_records values ('tasks', v_task);
    v_count := v_count + 1;
  end loop;

  for r in
    select * from (values
      ('Jordan Sample', '0412 345 678', 'jordan@example.com', 'Sampleton 3000', 'Me', array['Community access'], 'What''s your cancellation policy?'),
      ('Priya Test', '0400 111 222', '', 'Testville 3011', 'A family member', array['Daily living support'], ''),
      ('Alex Example', '03 9000 1234', 'alex@example.com', 'Exampleburg 3121', 'Someone I support (coordinator)', array['Supported independent living'], 'How do I start with you?')
    ) as e(full_name, phone, email, suburb, support_for, needs, asked)
  loop
    insert into public.website_enquiries (full_name, phone, email, suburb, support_for, needs, asked, source, consent)
    values (r.full_name, r.phone, r.email, r.suburb, r.support_for, r.needs, r.asked, case when r.asked = '' then 'form' else 'chat' end, true)
    returning id into v_enquiry;
    insert into public.demo_records values ('website_enquiries', v_enquiry);
    -- The Call back task it made is a sample too.
    insert into public.demo_records
    select 'tasks', t.id from public.tasks t where t.title = 'Call back: ' || r.full_name
       and not exists (select 1 from public.demo_records d where d.table_name = 'tasks' and d.row_id = t.id)
    on conflict do nothing;
    v_count := v_count + 1;
  end loop;

  -- Sample records don't send emails.
  delete from public.email_outbox where task_id in (select row_id from public.demo_records where table_name = 'tasks');
  return v_count;
end $$;
revoke all on function public.demo_load() from public, anon;
grant execute on function public.demo_load() to authenticated;

$m060$;
  insert into public.install_log (name) values ('20261218000001_demo_data.sql');
end;
$part$;

-- ====================================================================
-- 20261219000001_reports_premium.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261219000001_reports_premium.sql') then
    return;
  end if;
  execute $m061$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Reports and exports becomes a premium add-on (cmeprojects): the Reports
-- pages and every Excel download. It stays on for companies already using it.

update public.features
   set label = 'Reports and exports',
       description = 'The Reports pages (tasks, compliance, cars, built features) and every Excel download.',
       premium = true,
       included = true
 where key = 'reports';

$m061$;
  insert into public.install_log (name) values ('20261219000001_reports_premium.sql');
end;
$part$;

-- ====================================================================
-- 20261220000001_sign_out_devices.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261220000001_sign_out_devices.sql') then
    return;
  end if;
  execute $m062$
-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects: signing out other devices.
--   * Anyone: sign out their own other devices (phones, other computers).
--   * The system admin: sign a person out everywhere, or everyone except themselves.
-- Removing a sign-in session also removes its refresh tokens, and the portal
-- checks its session still exists, so a signed-out device stops within a minute.

-- Is the session this request came from still there?
create or replace function public.my_session_active()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when coalesce(auth.jwt() ->> 'session_id', '') = '' then true
    else exists (
      select 1 from auth.sessions s
       where s.id = (auth.jwt() ->> 'session_id')::uuid and s.user_id = auth.uid()
    )
  end
$$;

-- Sign out my other devices; this one stays signed in.
create or replace function public.sign_out_my_other_devices()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer;
begin
  if auth.uid() is null then
    raise exception 'Please sign in first.';
  end if;
  delete from auth.sessions
   where user_id = auth.uid()
     and id is distinct from nullif(auth.jwt() ->> 'session_id', '')::uuid;
  get diagnostics v_count = row_count;
  perform public.write_audit('signed_out_other_devices', 'profile', auth.uid()::text, jsonb_build_object('devices', v_count));
  return v_count;
end;
$$;

-- System admin: sign one person out of every device.
create or replace function public.sign_out_everywhere(p_user_id uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer;
begin
  if not public.is_system_admin() then
    raise exception 'Only the system admin can do this.';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'To sign yourself out of other devices, use My account.';
  end if;
  delete from auth.sessions where user_id = p_user_id;
  get diagnostics v_count = row_count;
  perform public.write_audit('signed_out_everywhere', 'profile', p_user_id::text, jsonb_build_object('devices', v_count));
  return v_count;
end;
$$;

-- System admin: sign everyone out (for example after a lost phone or a
-- security worry). The admin's own current device stays signed in.
create or replace function public.sign_out_everyone()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer;
begin
  if not public.is_system_admin() then
    raise exception 'Only the system admin can do this.';
  end if;
  delete from auth.sessions
   where id is distinct from nullif(auth.jwt() ->> 'session_id', '')::uuid;
  get diagnostics v_count = row_count;
  perform public.write_audit('signed_out_everyone', 'system', 'everyone', jsonb_build_object('devices', v_count));
  return v_count;
end;
$$;

revoke execute on function public.my_session_active() from public, anon;
revoke execute on function public.sign_out_my_other_devices() from public, anon;
revoke execute on function public.sign_out_everywhere(uuid) from public, anon;
revoke execute on function public.sign_out_everyone() from public, anon;
grant execute on function public.my_session_active() to authenticated;
grant execute on function public.sign_out_my_other_devices() to authenticated;
grant execute on function public.sign_out_everywhere(uuid) to authenticated;
grant execute on function public.sign_out_everyone() to authenticated;

$m062$;
  insert into public.install_log (name) values ('20261220000001_sign_out_devices.sql');
end;
$part$;

-- ====================================================================
-- 20261221000001_settings_revamp.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261221000001_settings_revamp.sql') then
    return;
  end if;
  execute $m063$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Settings revamp (cmeprojects):
--   1. Feature parts: Teams, Roles, Form builder and the Compliance parts can
--      be switched off on their own. A part only works while its feature is on.
--   2. Delegation per area: only the system admin, all managers, or selected
--      managers and staff admins. Today's delegations carry over.
--      New areas: adding registers, and roles (job titles).
--   3. Save, then deploy: settings, feature switches and delegation are
--      saved as drafts and go live together when deployed.
--   4. Notifications: bell and email can be switched off per notification,
--      and nothing is sent for a feature that's off.
--   5. The website is the front page only while the Assistant is on.
-- Everything starts at today's behaviour.

-- ---------------------------------------------------------------------------
-- 1. Feature parts
-- ---------------------------------------------------------------------------

alter table public.features add column if not exists parent text references public.features (key);

insert into public.features (key, label, description, enabled, sort_order, premium, included, parent) values
  ('teams', 'Teams', 'Teams and team leaders. Off: team leaders work like support workers; teams are kept.', true, 300, false, true, null),
  ('roles', 'Roles (job titles)', 'Job titles linked to access levels. Off: people get an access level only; job titles are kept.', true, 301, false, true, null),
  ('form_builder', 'Form builder', 'Making and changing forms. Off: published forms still work and can be filled in.', true, 310, false, true, 'forms'),
  ('compliance_read', 'Read and confirm', 'Documents staff read and confirm.', true, 320, false, true, 'compliance'),
  ('compliance_training', 'Trainings', 'Trainings staff complete.', true, 321, false, true, 'compliance'),
  ('compliance_upload', 'Documents to upload', 'Certificates and checks staff upload, with expiry dates.', true, 322, false, true, 'compliance'),
  ('compliance_forms', 'Forms in onboarding', 'Forms that are part of onboarding (needs Forms on too).', true, 323, false, true, 'compliance')
on conflict (key) do nothing;

-- A feature works if it's on and included, and so is the feature it's part of.
create or replace function public.feature_enabled(p_key text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((
    select f.enabled and f.included
       and (f.parent is null or coalesce((select p.enabled and p.included from public.features p where p.key = f.parent), false))
      from public.features f
     where f.key = p_key
  ), false)
$$;

-- Compliance items only count while their part is on (so a switched-off part
-- never holds up anyone's onboarding).
create or replace function public.compliance_applies(p_item public.compliance_items, p_role public.app_role, p_teams uuid[])
returns boolean
language sql
stable
set search_path = ''
as $$
  select p_item.active
     and public.feature_enabled(case p_item.kind when 'form' then 'compliance_forms' else 'compliance_' || p_item.kind end)
     and (p_item.kind <> 'form' or public.feature_enabled('forms'))
     and (cardinality(p_item.applies_roles) = 0 or p_role = any (p_item.applies_roles))
     and (cardinality(p_item.applies_teams) = 0 or p_item.applies_teams && coalesce(p_teams, '{}'))
$$;

-- Teams off: team leaders don't see their team's work (they work like support workers).
create or replace function public.leads_user(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.feature_enabled('teams') and exists (
    select 1
      from public.team_leaders tl
      join public.team_members m on m.team_id = tl.team_id
     where tl.user_id = auth.uid()
       and m.user_id = p_user_id
  ) and public.has_role(array['team_leader', 'manager', 'system_admin']::public.app_role[])
$$;

-- Form builder off: only the system admin makes forms (published ones still work).
create or replace function public.can_make_forms()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and public.feature_enabled('forms')
     and (public.is_system_admin()
          or (public.feature_enabled('form_builder')
              and public.my_role()::text in (select jsonb_array_elements_text(coalesce(
                    (select value from public.app_settings where key = 'forms.maker_roles'), '[]')))))
$$;

-- ---------------------------------------------------------------------------
-- 2. Delegation per area
-- ---------------------------------------------------------------------------

create table if not exists public.delegation_rules (
  area       text primary key
             check (area in ('branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'website', 'audit', 'registers', 'roles')),
  -- admin: only the system admin. managers: every manager. selected: the people listed (managers or staff admins).
  mode       text not null default 'admin' check (mode in ('admin', 'managers', 'selected')),
  people     uuid[] not null default '{}',
  updated_by uuid references public.profiles (id),
  updated_at timestamptz not null default now()
);

alter table public.delegation_rules enable row level security;
drop policy if exists "members read delegation" on public.delegation_rules;
create policy "members read delegation" on public.delegation_rules
  for select to authenticated using (public.is_member());
revoke insert, update, delete, truncate on public.delegation_rules from anon, authenticated;

-- Carry over today's delegations (named managers per area).
insert into public.delegation_rules (area, mode, people)
select a.area,
       case when count(d.user_id) > 0 then 'selected' else 'admin' end,
       coalesce(array_agg(d.user_id) filter (where d.user_id is not null), '{}')
  from unnest(array['branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'website', 'audit']) as a(area)
  left join public.admin_delegations d on a.area = any (d.areas)
 group by a.area
on conflict (area) do nothing;

-- Today every manager adds registers and job titles: keep that.
insert into public.delegation_rules (area, mode) values ('registers', 'managers'), ('roles', 'managers')
on conflict (area) do nothing;

-- Can the signed-in person look after this area?
create or replace function public.can_admin_area(p_area text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.mfa_ok() and (
    public.is_system_admin()
    or (p_area is not null and exists (
      select 1
        from public.delegation_rules r
        join public.profiles p on p.id = auth.uid()
       where r.area = p_area
         and p.active
         and ((r.mode = 'managers' and p.role = 'manager')
              or (r.mode = 'selected' and p.id = any (r.people) and p.role in ('manager', 'staff_admin')))
    ))
  )
$$;

-- The areas the signed-in person looks after.
create or replace function public.my_admin_areas()
returns text[]
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(array_agg(r.area order by r.area), '{}')
    from public.delegation_rules r
   where public.can_admin_area(r.area)
$$;

-- The older per-manager call still works: it now updates the per-area rules.
create or replace function public.set_delegation(p_user_id uuid, p_areas text[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_areas text[] := coalesce((select array_agg(distinct a order by a) from unnest(coalesce(p_areas, '{}')) a), '{}');
begin
  if not public.is_system_admin() or not public.mfa_ok() then
    raise exception 'Only the system admin delegates';
  end if;
  if cardinality(v_areas) > 0
     and not exists (select 1 from public.profiles where id = p_user_id and role in ('manager', 'staff_admin') and active) then
    raise exception 'Only active managers and staff admins can be given areas to look after';
  end if;
  if exists (select 1 from unnest(v_areas) a where a not in (select area from public.delegation_rules)) then
    raise exception 'That area can''t be delegated';
  end if;
  update public.delegation_rules r
     set people = array_append(array_remove(r.people, p_user_id), p_user_id),
         mode = case when r.mode = 'managers' then 'managers' else 'selected' end,
         updated_by = auth.uid(), updated_at = now()
   where r.area = any (v_areas);
  update public.delegation_rules r
     set people = array_remove(r.people, p_user_id),
         mode = case when r.mode = 'selected' and cardinality(array_remove(r.people, p_user_id)) = 0 then 'admin' else r.mode end,
         updated_by = auth.uid(), updated_at = now()
   where not (r.area = any (v_areas)) and p_user_id = any (r.people);
  perform public.write_audit('delegation_changed', 'profile', p_user_id::text, jsonb_build_object('areas', to_jsonb(v_areas)));
end;
$$;

-- Adding registers and job titles follow their delegation.
drop policy if exists "managers create registries" on public.registries;
drop policy if exists "delegated people create registries" on public.registries;
create policy "delegated people create registries" on public.registries
  for insert to authenticated with check (public.can_admin_area('registers'));

drop policy if exists "managers add job titles" on public.job_titles;
drop policy if exists "managers change job titles" on public.job_titles;
drop policy if exists "delegated people add job titles" on public.job_titles;
drop policy if exists "delegated people change job titles" on public.job_titles;
create policy "delegated people add job titles" on public.job_titles
  for insert to authenticated with check (public.can_admin_area('roles'));
create policy "delegated people change job titles" on public.job_titles
  for update to authenticated using (public.can_admin_area('roles')) with check (public.can_admin_area('roles'));

-- ---------------------------------------------------------------------------
-- 3. Save, then deploy
-- ---------------------------------------------------------------------------

create table if not exists public.settings_drafts (
  kind     text not null check (kind in ('setting', 'feature', 'delegation', 'website')),
  key      text not null,
  value    jsonb not null,
  saved_by uuid not null references public.profiles (id) on delete cascade,
  saved_at timestamptz not null default now(),
  primary key (kind, key)
);

alter table public.settings_drafts enable row level security;
drop policy if exists "see your drafts, the system admin sees all" on public.settings_drafts;
create policy "see your drafts, the system admin sees all" on public.settings_drafts
  for select to authenticated using (public.is_system_admin() or saved_by = auth.uid());
revoke insert, update, delete, truncate on public.settings_drafts from anon, authenticated;

-- May the signed-in person change this?
create or replace function public.may_change(p_kind text, p_key text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case p_kind
    when 'setting' then public.can_admin_area(public.setting_area(p_key))
                        or (p_key like 'tasks.sla%' and public.my_role() = 'manager' and public.mfa_ok())
                        or (public.is_system_admin() and public.mfa_ok())
    -- Website settings: the system admin; "where it looks for answers" can be delegated.
    when 'website' then (public.is_system_admin() and public.mfa_ok()) or (p_key = 'answers' and public.can_admin_area('website'))
    else public.is_system_admin() and public.mfa_ok()
  end
$$;

-- The live value of something, in the same shape as its draft.
create or replace function public.live_value(p_kind text, p_key text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select case p_kind
    when 'setting' then (select value from public.app_settings where key = p_key)
    when 'feature' then (select jsonb_build_object('enabled', enabled) from public.features where key = p_key)
    when 'delegation' then (select jsonb_build_object('mode', mode, 'people', to_jsonb(people)) from public.delegation_rules where area = p_key)
  end
$$;

-- Save a change as a draft. Saving the live value again removes the draft.
-- Returns 'saved' or 'unchanged'.
create or replace function public.save_draft(p_kind text, p_key text, p_value jsonb)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_live jsonb;
  v_value jsonb := p_value;
begin
  if p_kind = 'website' then
    -- A part of Website settings: only real columns, compared with what's live.
    if p_key not in ('landing', 'answers', 'limits') or jsonb_typeof(p_value) <> 'object' or exists (
      select 1 from jsonb_object_keys(p_value) k
       where k in ('id', 'updated_at')
          or k not in (select column_name::text from information_schema.columns where table_schema = 'public' and table_name = 'assistant_settings')
    ) then
      raise exception 'Something went wrong. Please refresh and try again.';
    end if;
    select jsonb_object_agg(k, to_jsonb(s) -> k) into v_live
      from public.assistant_settings s, jsonb_object_keys(p_value) k
     where s.id;
  else
    v_live := public.live_value(p_kind, p_key);
  end if;
  if not public.may_change(p_kind, p_key) then
    raise exception 'You don''t have permission to change this.';
  end if;
  if v_live is null then
    raise exception 'This setting doesn''t exist.';
  end if;
  if p_kind = 'feature' then
    if jsonb_typeof(p_value -> 'enabled') <> 'boolean' then
      raise exception 'Choose on or off.';
    end if;
    v_value := jsonb_build_object('enabled', p_value -> 'enabled');
  elsif p_kind = 'delegation' then
    if coalesce(p_value ->> 'mode', '') not in ('admin', 'managers', 'selected') then
      raise exception 'Choose who looks after it.';
    end if;
    v_value := jsonb_build_object(
      'mode', p_value ->> 'mode',
      'people', coalesce((
        select jsonb_agg(p.id order by p.full_name)
          from public.profiles p
         where p.active and p.role in ('manager', 'staff_admin')
           and p.id::text in (select jsonb_array_elements_text(coalesce(p_value -> 'people', '[]')))
      ), '[]'));
    if v_value ->> 'mode' = 'selected' and jsonb_array_length(v_value -> 'people') = 0 then
      raise exception 'Choose at least one manager or staff admin.';
    end if;
    if v_value ->> 'mode' <> 'selected' then
      v_value := jsonb_set(v_value, '{people}', '[]');
    end if;
  end if;

  if v_value = v_live then
    delete from public.settings_drafts where kind = p_kind and key = p_key;
    return 'unchanged';
  end if;
  insert into public.settings_drafts (kind, key, value, saved_by)
  values (p_kind, p_key, v_value, auth.uid())
  on conflict (kind, key) do update set value = excluded.value, saved_by = excluded.saved_by, saved_at = now();
  return 'saved';
end;
$$;

-- Make saved changes live: everyone's for the system admin, your own for others.
create or replace function public.deploy_drafts()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  d record;
  v_count integer := 0;
  v_enabled boolean;
  v_col text;
begin
  if auth.uid() is null then
    raise exception 'Please sign in first.';
  end if;
  for d in
    select * from public.settings_drafts
     where public.is_system_admin() or saved_by = auth.uid()
     order by case kind when 'feature' then 1 when 'setting' then 2 when 'website' then 3 else 4 end, key
     for update
  loop
    if not public.may_change(d.kind, d.key) then
      continue;
    end if;
    if d.kind = 'setting' then
      update public.app_settings set value = d.value, updated_at = now(), updated_by = auth.uid() where key = d.key;
    elsif d.kind = 'feature' then
      v_enabled := (d.value ->> 'enabled')::boolean;
      update public.features
         set enabled = v_enabled,
             included = case when v_enabled and premium then true else included end,
             updated_at = now(), updated_by = auth.uid()
       where key = d.key;
    elsif d.kind = 'website' then
      for v_col in select jsonb_object_keys(d.value) loop
        execute format('update public.assistant_settings set %I = (jsonb_populate_record(null::public.assistant_settings, $1)).%I where id', v_col, v_col)
          using d.value;
      end loop;
      perform public.write_audit('website_settings_changed', 'website', d.key, '{}'::jsonb);
    else
      update public.delegation_rules
         set mode = d.value ->> 'mode',
             people = coalesce((select array_agg(x::uuid) from jsonb_array_elements_text(d.value -> 'people') x), '{}'),
             updated_by = auth.uid(), updated_at = now()
       where area = d.key;
      perform public.write_audit('delegation_changed', 'area', d.key, d.value);
    end if;
    delete from public.settings_drafts where kind = d.kind and key = d.key;
    v_count := v_count + 1;
  end loop;
  if v_count > 0 then
    perform public.write_audit('settings_deployed', 'settings', 'deploy', jsonb_build_object('changes', v_count));
  end if;
  return v_count;
end;
$$;

-- Throw away saved changes: everyone's for the system admin, your own for others.
create or replace function public.discard_drafts()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer;
begin
  delete from public.settings_drafts where public.is_system_admin() or saved_by = auth.uid();
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. Notifications: bell and email per notification
-- ---------------------------------------------------------------------------

insert into public.app_settings (key, value, label, description) values
  ('notify.channels', '{}', 'Notifications', 'Bell and email for each notification. Anything not listed is on.')
on conflict (key) do nothing;

-- Which feature a notification belongs to (null: always allowed).
create or replace function public.notification_feature(p_code text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when p_code like 'car\_%' then 'vehicles'
    when p_code like 'form\_%' then 'forms'
    when p_code in ('document_expiring', 'document_expired', 'onboarding_item', 'upload_submitted', 'upload_rejected', 'uploaded_for_you', 'onboarded') then 'compliance'
    when p_code = 'website_enquiry' then 'assistant'
    else null
  end
$$;

-- Is this channel on for this notification? (Anything not set is on.)
create or replace function public.notification_on(p_code text, p_channel text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (public.notification_feature(p_code) is null or public.feature_enabled(public.notification_feature(p_code)))
     and coalesce(((select value from public.app_settings where key = 'notify.channels') -> p_code ->> p_channel)::boolean, true)
$$;

create or replace function public.filter_notification()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.notification_on(new.kind, 'bell') then
    return null;
  end if;
  return new;
end;
$$;

drop trigger if exists notifications_filter on public.notifications;
create trigger notifications_filter
  before insert on public.notifications
  for each row execute function public.filter_notification();

create or replace function public.filter_email()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.notification_on(case when new.template = 'notice' then coalesce(new.data ->> 'kind', 'notice') else new.template end, 'email') then
    return null;
  end if;
  return new;
end;
$$;

drop trigger if exists email_outbox_filter on public.email_outbox;
create trigger email_outbox_filter
  before insert on public.email_outbox
  for each row execute function public.filter_email();

-- notify() also records which notification an email is, so it can be filtered.
create or replace function public.notify(p_user uuid, p_kind text, p_title text, p_body text, p_href text, p_email boolean default false)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_user is null or not exists (select 1 from public.profiles where id = p_user and active) then
    return;
  end if;
  insert into public.notifications (user_id, kind, title, body, href)
  values (p_user, p_kind, p_title, coalesce(p_body, ''), coalesce(p_href, '/'));
  if p_email and public.feature_enabled('email_notifications') then
    insert into public.email_outbox (to_user, template, data)
    values (p_user, 'notice', jsonb_build_object('title', p_title, 'body', coalesce(p_body, ''), 'href', coalesce(p_href, '/'), 'kind', p_kind));
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- 5. The website is the front page only while the Assistant is on
-- ---------------------------------------------------------------------------

create or replace function public.website_front_page()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.feature_enabled('assistant')
     and coalesce((select value = 'true'::jsonb from public.app_settings where key = 'website.front_page'), false)
$$;

-- ---------------------------------------------------------------------------
-- Permissions
-- ---------------------------------------------------------------------------

revoke execute on function public.my_admin_areas() from public, anon;
revoke execute on function public.may_change(text, text) from public, anon;
revoke execute on function public.live_value(text, text) from public, anon, authenticated;
revoke execute on function public.save_draft(text, text, jsonb) from public, anon;
revoke execute on function public.deploy_drafts() from public, anon;
revoke execute on function public.discard_drafts() from public, anon;
revoke execute on function public.notification_on(text, text) from public, anon, authenticated;
revoke execute on function public.filter_notification() from public, anon, authenticated;
revoke execute on function public.filter_email() from public, anon, authenticated;
grant execute on function public.my_admin_areas() to authenticated;
grant execute on function public.may_change(text, text) to authenticated;
grant execute on function public.save_draft(text, text, jsonb) to authenticated;
grant execute on function public.deploy_drafts() to authenticated;
grant execute on function public.discard_drafts() to authenticated;
grant execute on function public.website_front_page() to anon, authenticated;

$m063$;
  insert into public.install_log (name) values ('20261221000001_settings_revamp.sql');
end;
$part$;

-- ====================================================================
-- 20261222000001_round3.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261222000001_round3.sql') then
    return;
  end if;
  execute $m064$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Round 3 (cmeprojects):
--   1. The system admin is never affected by feature switches (except
--      two-factor login, emails and auto-escalation, which apply to everyone).
--   2. A new access level for later: External contractor (allied health),
--      with no permissions yet.
--   3. Each register can say who may create tasks in it.
--   4. The weekly mileage report: which day, from what time, and what period.
--   5. A manager can share areas the system admin gave them with staff admins.
--   6. With no active staff admin, managers look after Compliance.

-- ---------------------------------------------------------------------------
-- 2. External contractor (allied health): a new access level, no permissions yet
-- ---------------------------------------------------------------------------

-- (access level already in the list above)

-- ---------------------------------------------------------------------------
-- 1. Feature switches never lock the system admin out
-- ---------------------------------------------------------------------------

-- What's actually switched on (for everyone, the system admin included).
create or replace function public.feature_live(p_key text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((
    select f.enabled and f.included
       and (f.parent is null or coalesce((select p.enabled and p.included from public.features p where p.key = f.parent), false))
      from public.features f
     where f.key = p_key
  ), false)
$$;

-- Whether the signed-in person can use a feature: the system admin always
-- can (so switching something off never locks them out), except for
-- two-factor login, emails and auto-escalation.
create or replace function public.feature_enabled(p_key text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when p_key in ('two_factor', 'email_notifications', 'auto_escalation') then public.feature_live(p_key)
    else public.feature_live(p_key) or public.is_system_admin()
  end
$$;

-- These follow what's really switched on, whoever is signed in.
create or replace function public.compliance_applies(p_item public.compliance_items, p_role public.app_role, p_teams uuid[])
returns boolean
language sql
stable
set search_path = ''
as $$
  select p_item.active
     and public.feature_live(case p_item.kind when 'form' then 'compliance_forms' else 'compliance_' || p_item.kind end)
     and (p_item.kind <> 'form' or public.feature_live('forms'))
     and (cardinality(p_item.applies_roles) = 0 or p_role = any (p_item.applies_roles))
     and (cardinality(p_item.applies_teams) = 0 or p_item.applies_teams && coalesce(p_teams, '{}'))
$$;

create or replace function public.leads_user(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.feature_live('teams') and exists (
    select 1
      from public.team_leaders tl
      join public.team_members m on m.team_id = tl.team_id
     where tl.user_id = auth.uid()
       and m.user_id = p_user_id
  ) and public.has_role(array['team_leader', 'manager', 'system_admin']::public.app_role[])
$$;

create or replace function public.notification_on(p_code text, p_channel text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (public.notification_feature(p_code) is null or public.feature_live(public.notification_feature(p_code)))
     and coalesce(((select value from public.app_settings where key = 'notify.channels') -> p_code ->> p_channel)::boolean, true)
$$;

-- Emails: nothing goes out while Emails is off, whoever triggered it.
create or replace function public.filter_email()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.feature_live('email_notifications')
     or not public.notification_on(case when new.template = 'notice' then coalesce(new.data ->> 'kind', 'notice') else new.template end, 'email') then
    return null;
  end if;
  return new;
end;
$$;

create or replace function public.website_front_page()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.feature_live('assistant')
     and coalesce((select value = 'true'::jsonb from public.app_settings where key = 'website.front_page'), false)
$$;

-- External contractors have no permissions yet: they aren't "members".
create or replace function public.is_member()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.my_role() is not null and public.my_role()::text <> 'external' and public.mfa_ok()
$$;

-- ---------------------------------------------------------------------------
-- 3. Who may create tasks in each register (empty: as before)
-- ---------------------------------------------------------------------------

alter table public.registries add column if not exists create_roles text[] not null default '{}';

create or replace function public.limited_task_guard() returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_roles text[] := (select create_roles from public.registries where id = new.registry_id);
begin
  -- Only a person creating a task themselves (not a task made by another rule).
  if pg_trigger_depth() = 1 and new.created_by = auth.uid() and not public.is_system_admin() then
    if cardinality(coalesce(v_roles, '{}')) > 0 then
      -- The register's own list decides (its managers set it).
      if not (public.my_role()::text = any (v_roles))
         and not exists (select 1 from public.registry_managers rm where rm.registry_id = new.registry_id and rm.user_id = auth.uid()) then
        raise exception 'This register only takes new tasks from chosen roles' using errcode = '42501';
      end if;
    elsif public.my_role()::text in (select jsonb_array_elements_text(coalesce(
           (select value from public.app_settings where key = 'tasks.limited_roles'), '[]')))
       and not exists (select 1 from public.registries r where r.id = new.registry_id and r.is_default) then
      raise exception 'You can raise General tasks and questions only' using errcode = '42501';
    end if;
  end if;
  return new;
end $$;

-- ---------------------------------------------------------------------------
-- 4. The weekly mileage report: day, time and period
-- ---------------------------------------------------------------------------

insert into public.app_settings (key, value, label, description) values
  ('vehicles.weekly_day', '1', 'Weekly mileage report: which day', 'The day the report is sent.'),
  ('vehicles.weekly_hour', '7', 'Weekly mileage report: from what hour', 'The hour of the day (0 to 23) it''s sent, in your time zone.'),
  ('vehicles.weekly_period', '"last_7_days"', 'Weekly mileage report: what it covers', 'The days the report covers.')
on conflict (key) do nothing;

create or replace function public.run_car_alerts(p_now timestamptz default now())
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_wday int;
  v_whour int;
  v_period text;
  v_from date;
  v_to date;
  v_tz text := coalesce((select value #>> '{}' from public.app_settings where key = 'region.timezone'), 'Australia/Melbourne');
  v_now timestamp := p_now at time zone v_tz;
  v_today date := v_now::date;
  v_hour int := extract(hour from v_now);
  v_remind_hour int := public.car_setting('vehicles.reminder_hour', '20')::int;
  v_morning int := coalesce((select (value #>> '{}')::int from public.app_settings where key = 'tasks.summary_hour'), 7);
  t record;
  c record;
  v_person uuid;
  v_reminders int := 0;
  v_told int := 0;
  v_cars int := 0;
  v_weekly int := 0;
begin
  if not public.feature_enabled('vehicles') then
    return jsonb_build_object('cars', 'off');
  end if;

  -- The driver, in the evening, if the car is still out.
  if v_hour >= v_remind_hour then
    for t in
      select tr.id, tr.driver_id, ca.name from public.car_trips tr join public.cars ca on ca.id = tr.car_id
       where tr.returned_at is null and tr.reminded_at is null
    loop
      perform public.notify(t.driver_id, 'car_still_out', format('You still have the %s out', t.name),
        'Return it in the Cars app when you''ve finished with it.', '/cars');
      update public.car_trips set reminded_at = p_now where id = t.id;
      v_reminders := v_reminders + 1;
    end loop;
  end if;

  -- Car managers, the next morning, for cars out since before today.
  if v_hour >= v_morning then
    for t in
      select tr.id, tr.driver_id, tr.started_at, ca.name, ca.rego,
             case when p.role = 'system_admin' then 'Admin' else coalesce(nullif(p.full_name, ''), p.email) end driver
        from public.car_trips tr
        join public.cars ca on ca.id = tr.car_id
        join public.profiles p on p.id = tr.driver_id
       where tr.returned_at is null and tr.managers_told_at is null
         and (tr.started_at at time zone v_tz)::date < v_today
    loop
      for v_person in select public.car_managers() loop
        continue when v_person = t.driver_id;
        perform public.notify(v_person, 'car_not_returned',
          format('%s (%s) hasn''t been returned', t.name, t.rego),
          format('%s took it on %s. You can return it for them on the Cars page.', t.driver,
                 to_char(t.started_at at time zone v_tz, 'Dy DD Mon, FMHH12:MI am')),
          '/cars/manage', true);
      end loop;
      update public.car_trips set managers_told_at = p_now where id = t.id;
      v_told := v_told + 1;
    end loop;

    -- Rego expiring within 30 days, and service coming up (by date or within 500 km).
    for c in
      select * from public.cars
       where active and rego_expires is not null and rego_expires <= v_today + 30
         and rego_alerted is distinct from rego_expires
    loop
      for v_person in select public.car_managers() loop
        perform public.notify(v_person, 'car_rego',
          format('Rego for %s (%s) %s %s', c.name, c.rego, case when c.rego_expires < v_today then 'expired on' else 'is due' end,
                 to_char(c.rego_expires, 'FMDD Mon YYYY')),
          'Update the date on the car once it''s renewed.', '/cars/manage', c.rego_expires < v_today);
      end loop;
      update public.cars set rego_alerted = c.rego_expires where id = c.id;
      v_cars := v_cars + 1;
    end loop;
    for c in
      select *, coalesce(service_due_date::text, '') || '/' || coalesce(service_due_km::text, '') as due_key
        from public.cars
       where active and ((service_due_date is not null and service_due_date <= v_today + 14)
                         or (service_due_km is not null and odometer >= service_due_km - 500))
         and service_alerted is distinct from (coalesce(service_due_date::text, '') || '/' || coalesce(service_due_km::text, ''))
    loop
      for v_person in select public.car_managers() loop
        perform public.notify(v_person, 'car_service', format('%s (%s) is due for a service', c.name, c.rego),
          concat_ws(' · ', case when c.service_due_date is not null then 'By ' || to_char(c.service_due_date, 'FMDD Mon YYYY') end,
                    case when c.service_due_km is not null then 'At ' || to_char(c.service_due_km, 'FM999,999,999') || ' km (now ' ||
                         to_char(c.odometer, 'FM999,999,999') || ' km)' end),
          '/cars/manage');
      end loop;
      update public.cars set service_alerted = c.due_key where id = c.id;
      v_cars := v_cars + 1;
    end loop;

  end if;

  -- The weekly mileage report (cmeprojects): on the chosen day, from the
  -- chosen hour, covering the chosen period.
  v_wday := coalesce((select (value #>> '{}')::int from public.app_settings where key = 'vehicles.weekly_day'), 1);
  v_whour := coalesce((select (value #>> '{}')::int from public.app_settings where key = 'vehicles.weekly_hour'), 0);
  v_period := coalesce((select value #>> '{}' from public.app_settings where key = 'vehicles.weekly_period'), 'last_7_days');
  v_from := case v_period
              when 'last_14_days' then v_today - 14
              when 'previous_week' then v_today - (extract(isodow from v_today)::int - 1) - 7
              when 'month_to_date' then date_trunc('month', v_today - 1)::date
              else v_today - 7
            end;
  v_to := case v_period when 'previous_week' then v_today - extract(isodow from v_today)::int else v_today - 1 end;
  if extract(isodow from v_today) = v_wday and v_hour >= v_whour then
    insert into public.daily_runs (job, day) values ('car_weekly', v_today) on conflict do nothing;
    if found and exists (select 1 from public.car_trips
                          where (started_at at time zone v_tz)::date between v_from and v_to) then
      -- Only the people chosen in Settings → Cars.
      for v_person in
        select p.id from public.profiles p
         where p.active
           and p.id::text in (select jsonb_array_elements_text(s.value) from public.app_settings s
                               where s.key = 'vehicles.weekly_recipients' and jsonb_typeof(s.value) = 'array')
      loop
        perform public.notify(v_person, 'car_weekly',
          format('Mileage report: %s to %s', to_char(v_from, 'FMDD Mon'), to_char(v_to, 'FMDD Mon YYYY')),
          'Car use and mileage, ready to download.',
          '/reports/cars?from=' || v_from::text || '&to=' || v_to::text, true);
        v_weekly := v_weekly + 1;
      end loop;
    end if;
  end if;

  return jsonb_build_object('car_reminders', v_reminders, 'cars_not_returned', v_told, 'car_notices', v_cars, 'car_weekly', v_weekly);
end;
$$;

-- ---------------------------------------------------------------------------
-- 5. Managers share their areas with staff admins
-- ---------------------------------------------------------------------------

create table if not exists public.delegation_shares (
  area      text not null check (area in ('branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'website', 'registers')),
  user_id   uuid not null references public.profiles (id) on delete cascade,
  shared_by uuid not null references public.profiles (id) on delete cascade,
  shared_at timestamptz not null default now(),
  primary key (area, user_id)
);

alter table public.delegation_shares enable row level security;
drop policy if exists "members read shares" on public.delegation_shares;
create policy "members read shares" on public.delegation_shares
  for select to authenticated using (public.is_member());
revoke insert, update, delete, truncate on public.delegation_shares from anon, authenticated;

-- Can the signed-in person look after this area? The system admin; people
-- the Delegation tab names; and staff admins a delegated manager shared it with.
create or replace function public.can_admin_area(p_area text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.mfa_ok() and (
    public.is_system_admin()
    or (p_area is not null and exists (
      select 1
        from public.delegation_rules r
        join public.profiles p on p.id = auth.uid()
       where r.area = p_area
         and p.active
         and ((r.mode = 'managers' and p.role = 'manager')
              or (r.mode = 'selected' and p.id = any (r.people) and p.role in ('manager', 'staff_admin')))
    ))
    or (p_area is not null and exists (
      select 1
        from public.delegation_shares s
        join public.profiles me on me.id = auth.uid()
        join public.profiles sp on sp.id = s.shared_by
        join public.delegation_rules r on r.area = s.area
       where s.area = p_area and s.user_id = auth.uid()
         and me.active and me.role = 'staff_admin'
         and sp.active and sp.role = 'manager'
         and (r.mode = 'managers' or (r.mode = 'selected' and sp.id = any (r.people)))
    ))
  )
$$;

-- A delegated manager shares (or stops sharing) an area with a staff admin.
create or replace function public.share_area(p_area text, p_user uuid, p_on boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.my_role() <> 'manager' or not public.can_admin_area(p_area) then
    raise exception 'Only a manager who looks after this area can share it.';
  end if;
  if p_area not in ('branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'website', 'registers') then
    raise exception 'This area can''t be shared.';
  end if;
  if p_on then
    if not exists (select 1 from public.profiles where id = p_user and active and role = 'staff_admin') then
      raise exception 'Areas can only be shared with active staff admins.';
    end if;
    insert into public.delegation_shares (area, user_id, shared_by) values (p_area, p_user, auth.uid())
    on conflict (area, user_id) do update set shared_by = excluded.shared_by, shared_at = now();
  else
    delete from public.delegation_shares where area = p_area and user_id = p_user;
  end if;
  perform public.write_audit(case when p_on then 'area_shared' else 'area_unshared' end, 'profile', p_user::text, jsonb_build_object('area', p_area));
end;
$$;

revoke execute on function public.share_area(text, uuid, boolean) from public, anon;
grant execute on function public.share_area(text, uuid, boolean) to authenticated;
revoke execute on function public.feature_live(text) from public, anon;
grant execute on function public.feature_live(text) to authenticated;

-- ---------------------------------------------------------------------------
-- 6. No active staff admin: managers look after Compliance
-- ---------------------------------------------------------------------------

create or replace function public.can_manage_compliance()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.mfa_ok() and (public.my_role() = 'system_admin'
         or public.my_role() = any (public.setting_roles('compliance.manager_roles'))
         or (public.my_role() = 'manager'
             and not exists (select 1 from public.profiles where role = 'staff_admin' and active)))
$$;

$m064$;
  insert into public.install_log (name) values ('20261222000001_round3.sql');
end;
$part$;

-- ====================================================================
-- 20261223000001_mfa_per_person.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261223000001_mfa_per_person.sql') then
    return;
  end if;
  execute $m065$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Two-factor login per person (cmeprojects): besides choosing which roles need
-- it, the system admin can let one person off (for example someone without a
-- smartphone). System admins always need it.

alter table public.profiles add column if not exists mfa_exempt boolean not null default false;

-- Only the system admin changes it, and never for a system admin.
create or replace function public.guard_mfa_exempt()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.mfa_exempt is distinct from old.mfa_exempt then
    if auth.uid() is not null and not public.is_system_admin() then
      raise exception 'Only the system admin can change two-factor login for a person.';
    end if;
  end if;
  if new.mfa_exempt and new.role = 'system_admin' then
    new.mfa_exempt := false;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_guard_mfa_exempt on public.profiles;
create trigger profiles_guard_mfa_exempt
  before update on public.profiles
  for each row execute function public.guard_mfa_exempt();

-- Signed in well enough? Two-factor is needed by system admins, and by the
-- chosen roles unless the system admin let this person off.
create or replace function public.mfa_ok()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    not public.feature_enabled('two_factor')
    or coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
    or (
      public.my_role() is distinct from 'system_admin'
      and (
        coalesce((select p.mfa_exempt from public.profiles p where p.id = auth.uid()), false)
        or not coalesce(
          (select s.value ? public.my_role()::text
             from public.app_settings s
            where s.key = 'security.mfa_required_roles'),
          false
        )
      )
    )
$$;

create or replace function public.my_access()
returns table (role public.app_role, active boolean, mfa_required boolean, mfa_ok boolean)
language sql
stable
security definer
set search_path = ''
as $$
  select
    p.role,
    p.active,
    public.feature_enabled('two_factor') and (
      p.role = 'system_admin' or (not p.mfa_exempt and coalesce(
        (select s.value ? p.role::text from public.app_settings s
          where s.key = 'security.mfa_required_roles'), false))
    ),
    public.mfa_ok()
  from public.profiles p
  where p.id = auth.uid()
$$;

-- The system admin lets a person off two-factor login, or asks for it again.
create or replace function public.set_mfa_exempt(p_user_id uuid, p_exempt boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_system_admin() or not public.mfa_ok() then
    raise exception 'Only the system admin can change two-factor login for a person.';
  end if;
  if exists (select 1 from public.profiles where id = p_user_id and role = 'system_admin') then
    raise exception 'System admins always need two-factor login.';
  end if;
  update public.profiles set mfa_exempt = p_exempt where id = p_user_id;
  perform public.write_audit(case when p_exempt then 'mfa_exempted' else 'mfa_required_again' end, 'profile', p_user_id::text, '{}'::jsonb);
end;
$$;

revoke execute on function public.set_mfa_exempt(uuid, boolean) from public, anon;
grant execute on function public.set_mfa_exempt(uuid, boolean) to authenticated;
revoke execute on function public.guard_mfa_exempt() from public, anon, authenticated;

$m065$;
  insert into public.install_log (name) values ('20261223000001_mfa_per_person.sql');
end;
$part$;

-- ====================================================================
-- 20261224000001_register_setup_delegation.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261224000001_register_setup_delegation.sql') then
    return;
  end if;
  execute $m066$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- "Setting up registers" delegation (cmeprojects): the system admin lets all
-- managers, or chosen managers and staff admins, change every register's
-- settings, fields and managers, not only the registers they manage.
-- Starts with the system admin only, so nothing changes until it's given.
-- Seeing or approving a register's tasks doesn't change.

alter table public.delegation_rules drop constraint if exists delegation_rules_area_check;
alter table public.delegation_rules add constraint delegation_rules_area_check
  check (area in ('branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'website', 'audit', 'registers', 'roles', 'register_setup'));
insert into public.delegation_rules (area, mode) values ('register_setup', 'admin') on conflict (area) do nothing;

-- Can the signed-in person set up this register?
create or replace function public.can_setup_registry(p_registry_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.manages_registry(p_registry_id) or public.can_admin_area('register_setup')
$$;

revoke execute on function public.can_setup_registry(uuid) from public, anon;
grant execute on function public.can_setup_registry(uuid) to authenticated;

drop policy if exists "registry managers update registries" on public.registries;
create policy "registry managers update registries" on public.registries
  for update to authenticated
  using (public.can_setup_registry(id)) with check (public.can_setup_registry(id));

drop policy if exists "registry managers manage managers" on public.registry_managers;
create policy "registry managers manage managers" on public.registry_managers
  for all to authenticated
  using (public.can_setup_registry(registry_id)) with check (public.can_setup_registry(registry_id));

drop policy if exists "registry managers manage fields" on public.registry_fields;
create policy "registry managers manage fields" on public.registry_fields
  for insert to authenticated with check (public.can_setup_registry(registry_id));
drop policy if exists "registry managers change fields" on public.registry_fields;
create policy "registry managers change fields" on public.registry_fields
  for update to authenticated
  using (public.can_setup_registry(registry_id)) with check (public.can_setup_registry(registry_id));

$m066$;
  insert into public.install_log (name) values ('20261224000001_register_setup_delegation.sql');
end;
$part$;

-- ====================================================================
-- 20261225000001_neutral_examples.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261225000001_neutral_examples.sql') then
    return;
  end if;
  execute $m067$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Neutral examples (cmeprojects): setting descriptions no longer name a client,
-- so a fresh copy for any company shows nothing from another.

update public.app_settings
   set description = 'The address people use, for example https://yourcompany.com.au. Used by search engines.'
 where key = 'website.site_url';
update public.app_settings
   set description = 'About 50 to 60 characters, for example: Your Company | NDIS support services in your area.'
 where key = 'website.seo_title';

$m067$;
  insert into public.install_log (name) values ('20261225000001_neutral_examples.sql');
end;
$part$;

-- ====================================================================
-- 20261226000001_register_templates_wizard.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261226000001_register_templates_wizard.sql') then
    return;
  end if;
  execute $m068$
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

$m068$;
  insert into public.install_log (name) values ('20261226000001_register_templates_wizard.sql');
end;
$part$;

-- ====================================================================
-- 20261227000001_delete_unused_registers.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261227000001_delete_unused_registers.sql') then
    return;
  end if;
  execute $m069$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Deleting registers (cmeprojects): only a register that has never been used
-- (no tasks, no items) can be deleted, by the system admin or people given
-- "Adding registers". A register that's been used is turned off instead (its
-- history stays, for audits). General tasks can't be deleted.

create or replace function public.delete_unused_registry(p_registry_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.registries;
begin
  if not public.can_admin_area('registers') then
    raise exception 'Only people the system admin chose can delete registers.';
  end if;
  select * into r from public.registries where id = p_registry_id;
  if r.id is null then
    raise exception 'That register doesn''t exist.';
  end if;
  if r.is_default then
    raise exception 'General tasks can''t be deleted.';
  end if;
  if exists (select 1 from public.tasks where registry_id = r.id) or exists (select 1 from public.records where registry_id = r.id) then
    raise exception '% has been used, so it can''t be deleted. Turn it off instead: its history is kept.', r.name;
  end if;
  delete from public.registries where id = r.id;
  perform public.write_audit('register_deleted', 'registry', r.id::text, jsonb_build_object('name', r.name, 'prefix', r.prefix));
end;
$$;

revoke execute on function public.delete_unused_registry(uuid) from public, anon;
grant execute on function public.delete_unused_registry(uuid) to authenticated;

$m069$;
  insert into public.install_log (name) values ('20261227000001_delete_unused_registers.sql');
end;
$part$;

-- ====================================================================
-- 20261228000001_staff_photos.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261228000001_staff_photos.sql') then
    return;
  end if;
  execute $m070$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Staff photos (cmeprojects).
--   * Each person can have a profile photo, shown instead of their initials.
--   * They upload it in My account, or through the "Profile photo" item in My
--     onboarding (an upload item marked sets_photo).
--   * Photos are private: only signed-in staff see them (the app signs short
--     links after checking who's asking). Never on the website or in exports.
--   * A person can only point their photo at their own files; staff admins
--     (people who manage people) can remove anyone's photo.

alter table public.profiles add column if not exists avatar_ref text;
alter table public.compliance_items add column if not exists sets_photo boolean not null default false;

-- Private storage for photos, in a folder named by each person's id.
do $$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values ('avatars', 'avatars', false, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
  on conflict (id) do nothing;

  drop policy if exists "people upload their own photo" on storage.objects;
  create policy "people upload their own photo" on storage.objects for insert to authenticated
    with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text and public.is_member());
  drop policy if exists "people read their own photo" on storage.objects;
  create policy "people read their own photo" on storage.objects for select to authenticated
    using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
  drop policy if exists "people remove their own photo" on storage.objects;
  create policy "people remove their own photo" on storage.objects for delete to authenticated
    using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
end;
$$;

-- avatar_ref only changes through the functions below (which check it points
-- at the person's own files), never by editing the profile directly.
create or replace function public.guard_avatar_ref()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.avatar_ref is distinct from old.avatar_ref
     and coalesce(current_setting('portal.avatar_ok', true), '') <> 'on' then
    raise exception 'Change the photo from My account.';
  end if;
  return new;
end;
$$;

drop trigger if exists guard_avatar_ref on public.profiles;
create trigger guard_avatar_ref before update of avatar_ref on public.profiles
  for each row execute function public.guard_avatar_ref();

-- Set my photo to a file I uploaded to the avatars store.
create or replace function public.set_my_avatar(p_ref text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null or not public.is_member() then
    raise exception 'Sign in first.';
  end if;
  if p_ref is null or p_ref !~ ('^avatars/' || auth.uid()::text || '/[A-Za-z0-9._-]+$') then
    raise exception 'Choose a photo and wait for it to upload.';
  end if;
  perform set_config('portal.avatar_ok', 'on', true);
  update public.profiles set avatar_ref = p_ref where id = auth.uid();
end;
$$;

-- Remove a photo: your own, or anyone's if you manage people.
create or replace function public.remove_avatar(p_user uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_user is distinct from auth.uid() and not (public.can_manage_people() or public.is_system_admin()) then
    raise exception 'Only you, or people who manage staff, can remove this photo.';
  end if;
  perform set_config('portal.avatar_ok', 'on', true);
  update public.profiles set avatar_ref = null where id = p_user;
  perform public.write_audit('photo_removed', 'profile', p_user::text, '{}'::jsonb);
end;
$$;

revoke execute on function public.set_my_avatar(text) from public, anon;
revoke execute on function public.remove_avatar(uuid) from public, anon;
grant execute on function public.set_my_avatar(text) to authenticated;
grant execute on function public.remove_avatar(uuid) to authenticated;

-- An onboarding upload marked sets_photo becomes the person's photo when they
-- send it, and stops being it if it's sent back.
create or replace function public.photo_from_onboarding()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ref text;
begin
  if new.file_path is null or not exists (select 1 from public.compliance_items where id = new.item_id and sets_photo) then
    return new;
  end if;
  -- Only the person's own folder (uploads are stored as <their id>/...).
  if new.file_path !~ ('^' || new.user_id::text || '/') then
    return new;
  end if;
  v_ref := 'compliance-files/' || new.file_path;
  perform set_config('portal.avatar_ok', 'on', true);
  if new.status in ('submitted', 'accepted') then
    -- Doesn't replace a photo they chose themselves in My account.
    update public.profiles set avatar_ref = v_ref
     where id = new.user_id and (avatar_ref is null or avatar_ref like 'compliance-files/%');
  elsif new.status = 'rejected' then
    update public.profiles set avatar_ref = null where id = new.user_id and avatar_ref = v_ref;
  end if;
  return new;
end;
$$;

drop trigger if exists photo_from_onboarding on public.compliance_records;
create trigger photo_from_onboarding after insert or update of status, file_path on public.compliance_records
  for each row execute function public.photo_from_onboarding();

-- The default onboarding upload: a profile photo (once per copy; staff admins
-- can edit it or switch it off in Compliance → Uploads).
-- (The "Compliance is switched off" check is paused for this one insert, so the
-- update also runs when Compliance is off or the HR Pack is set up first.)
alter table public.compliance_items disable trigger compliance_items_guard;
insert into public.compliance_items (kind, title, description, sets_photo, active, sort_order, created_by)
select 'upload', 'Profile photo',
       'A clear, recent photo of your face, like a passport photo. It''s shown next to your name in the portal, only to signed-in staff.',
       true, true, 5, null
where not exists (select 1 from public.compliance_items where sets_photo);
alter table public.compliance_items enable trigger compliance_items_guard;

$m070$;
  insert into public.install_log (name) values ('20261228000001_staff_photos.sql');
end;
$part$;

-- ====================================================================
-- 20261229000001_client_teams.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261229000001_client_teams.sql') then
    return;
  end if;
  execute $m071$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Clients, teams and tasks (cmeprojects).
--   * People who manage staff say which team(s) look after each client.
--   * A task can name the client it's about (optional).
--   * Team leaders see the clients their team looks after, with their open
--     tasks, on their dashboard. Staff only ever see client names, never more.

create table if not exists public.client_teams (
  client_id uuid not null references public.car_clients (id) on delete cascade,
  team_id   uuid not null references public.teams (id) on delete cascade,
  primary key (client_id, team_id)
);

alter table public.client_teams enable row level security;
drop policy if exists "members see which team looks after which client" on public.client_teams;
create policy "members see which team looks after which client" on public.client_teams
  for select to authenticated using (public.is_member());
drop policy if exists "people managers link clients to teams" on public.client_teams;
create policy "people managers link clients to teams" on public.client_teams
  for insert to authenticated with check (public.can_manage_people());
drop policy if exists "people managers unlink clients from teams" on public.client_teams;
create policy "people managers unlink clients from teams" on public.client_teams
  for delete to authenticated using (public.can_manage_people());
revoke update, truncate on public.client_teams from anon, authenticated;

alter table public.tasks add column if not exists client_id uuid references public.car_clients (id) on delete set null;
create index if not exists tasks_client on public.tasks (client_id) where client_id is not null;

-- Client names to pick from on a task (names only, like the Cars app).
create or replace function public.clients_to_pick()
returns table (id uuid, name text)
language sql
stable
security definer
set search_path = ''
as $$
  select c.id, c.name from public.car_clients c
   where c.active and public.is_member()
   order by c.name;
$$;

-- Set (or clear) the client a task is about: anyone who can work on the task.
create or replace function public.set_task_client(p_task uuid, p_client uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.can_edit_task(p_task) then
    raise exception 'Only people working on this task can change its client.';
  end if;
  if p_client is not null and not exists (select 1 from public.car_clients where id = p_client and active) then
    raise exception 'Choose a client from the list.';
  end if;
  update public.tasks set client_id = p_client where id = p_task;
end;
$$;

-- The client's name on a task, for anyone who can see the task.
create or replace function public.task_client(p_task uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select c.name from public.tasks t join public.car_clients c on c.id = t.client_id
   where t.id = p_task and public.can_see_task(p_task);
$$;

-- A team leader's clients: the clients their team(s) look after, with how
-- many of their tasks are open and overdue.
create or replace function public.my_team_clients()
returns table (client_id uuid, client_name text, team_name text, open_tasks bigint, overdue_tasks bigint)
language sql
stable
security definer
set search_path = ''
as $$
  select c.id, c.name, string_agg(distinct tm.name, ', '),
         (select count(*) from public.tasks t where t.client_id = c.id and t.status not in ('completed', 'closed')),
         (select count(*) from public.tasks t where t.client_id = c.id and t.status not in ('completed', 'closed') and t.due_date < current_date)
    from public.team_leaders tl
    join public.client_teams ct on ct.team_id = tl.team_id
    join public.car_clients c on c.id = ct.client_id and c.active
    join public.teams tm on tm.id = tl.team_id
   where tl.user_id = auth.uid()
   group by c.id, c.name
   order by c.name;
$$;

revoke execute on function public.clients_to_pick() from public, anon;
revoke execute on function public.set_task_client(uuid, uuid) from public, anon;
revoke execute on function public.task_client(uuid) from public, anon;
revoke execute on function public.my_team_clients() from public, anon;
grant execute on function public.clients_to_pick() to authenticated;
grant execute on function public.set_task_client(uuid, uuid) to authenticated;
grant execute on function public.task_client(uuid) to authenticated;
grant execute on function public.my_team_clients() to authenticated;

$m071$;
  insert into public.install_log (name) values ('20261229000001_client_teams.sql');
end;
$part$;

-- ====================================================================
-- 20261230000001_hr_pack_profiles.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261230000001_hr_pack_profiles.sql') then
    return;
  end if;
  execute $m072$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- HR Pack and staff profiles (cmeprojects).
--   * HR Pack: a premium package, on by default. Its parts can each be switched
--     off: Staff profiles and directory, My requests (and each request type),
--     and Compliance and onboarding (which keeps its own parts). Switching the
--     HR Pack off switches all of them off.
--   * A part counts as on only while every level above it is on.
--   * Staff profiles: a directory card everyone can see (preferred name,
--     department, work phone, skills) and private details only the person and
--     people who manage staff can see (address, emergency contact, employee
--     details, availability). All changes go through the functions below.

-- ---------------------------------------------------------------------------
-- HR Pack switches
-- ---------------------------------------------------------------------------

insert into public.features (key, label, description, enabled, sort_order, premium, included, parent) values
  ('hr', 'HR Pack', 'Staff profiles and directory, My requests and approvals, and Compliance and onboarding.', true, 39, true, true, null),
  ('hr_profiles', 'Staff profiles and directory', 'Professional profiles (photo, preferred name, department, contact, skills, availability) and a staff directory.', true, 330, false, true, 'hr'),
  ('hr_requests', 'My requests', 'Staff send requests (leave, shift swaps, availability and more) and track them; approvers approve or decline.', true, 340, false, true, 'hr'),
  ('hr_req_leave', 'Leave requests', 'Annual, personal/carer''s, unpaid, long service, compassionate and other leave.', true, 341, false, true, 'hr_requests'),
  ('hr_req_swap', 'Shift swap requests', 'Swap a shift with a colleague (they accept first).', true, 342, false, true, 'hr_requests'),
  ('hr_req_shift', 'Shift change requests', 'Ask to change a shift.', true, 343, false, true, 'hr_requests'),
  ('hr_req_availability', 'Availability changes', 'Change your regular weekly availability.', true, 344, false, true, 'hr_requests'),
  ('hr_req_timesheet', 'Timesheet corrections', 'Correct the times on a timesheet.', true, 345, false, true, 'hr_requests'),
  ('hr_req_hr', 'HR and employment enquiries', 'Questions about pay, contracts and employment.', true, 346, false, true, 'hr_requests'),
  ('hr_req_other', 'Other requests', 'Anything else.', true, 347, false, true, 'hr_requests')
on conflict (key) do nothing;

-- Compliance and onboarding becomes part of the HR Pack.
update public.features set parent = 'hr' where key = 'compliance' and parent is null;

-- On only while it and every level above it are on (and included).
create or replace function public.feature_live(p_key text)
returns boolean
language sql
stable
set search_path = ''
as $$
  with recursive chain as (
    select f.key, f.parent, (f.enabled and f.included) as on_, 1 as depth from public.features f where f.key = p_key
    union all
    select p.key, p.parent, (p.enabled and p.included), c.depth + 1
      from public.features p join chain c on p.key = c.parent
     where c.depth < 6
  )
  select coalesce(bool_and(on_), false) and exists (select 1 from chain) from chain
$$;

-- ---------------------------------------------------------------------------
-- Staff profiles
-- ---------------------------------------------------------------------------

create table if not exists public.staff_directory (
  user_id        uuid primary key references public.profiles (id) on delete cascade,
  preferred_name text not null default '' check (length(preferred_name) <= 60),
  department     text not null default '' check (length(department) <= 80),
  work_phone     text not null default '' check (length(work_phone) <= 30),
  skills         text[] not null default '{}',
  updated_at     timestamptz not null default now()
);

create table if not exists public.staff_private (
  user_id         uuid primary key references public.profiles (id) on delete cascade,
  address         text not null default '' check (length(address) <= 300),
  emergency_name  text not null default '' check (length(emergency_name) <= 100),
  emergency_phone text not null default '' check (length(emergency_phone) <= 30),
  start_date      date,
  employment_type text not null default '' check (employment_type in ('', 'full_time', 'part_time', 'casual', 'contractor')),
  employee_id     text not null default '' check (length(employee_id) <= 40),
  -- Weekly availability, for example {"mon": ["am", "pm"], "tue": [], ...}
  availability    jsonb not null default '{}'::jsonb,
  updated_at      timestamptz not null default now()
);

alter table public.staff_directory enable row level security;
alter table public.staff_private enable row level security;

-- Everyone in the company sees the directory card while profiles are on.
drop policy if exists "members see the staff directory" on public.staff_directory;
create policy "members see the staff directory" on public.staff_directory
  for select to authenticated using (public.is_member() and public.feature_enabled('hr_profiles'));

-- Private details: the person, people who manage staff, and the system admin.
-- Team leaders also see their team members' availability (for rostering later).
drop policy if exists "the person and people managers see private details" on public.staff_private;
create policy "the person and people managers see private details" on public.staff_private
  for select to authenticated using (
    public.feature_enabled('hr_profiles') and (
      user_id = auth.uid() or public.can_manage_people() or public.is_system_admin()
      or exists (
        select 1 from public.team_leaders tl join public.team_members tm on tm.team_id = tl.team_id
         where tl.user_id = auth.uid() and tm.user_id = staff_private.user_id)));

revoke insert, update, delete, truncate on public.staff_directory, public.staff_private from anon, authenticated;
grant select on public.staff_directory, public.staff_private to authenticated;

-- Fields a person edits themselves, and fields only people managers edit.
create or replace function public.save_profile(p_user uuid, p jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  me boolean := p_user = auth.uid();
  manager boolean := public.can_manage_people() or public.is_system_admin();
  v_skills text[];
begin
  if not public.is_member() or not public.feature_enabled('hr_profiles') then
    raise exception 'Staff profiles are switched off.';
  end if;
  if not me and not manager then
    raise exception 'You can only change your own profile.';
  end if;
  if not exists (select 1 from public.profiles where id = p_user) then
    raise exception 'That person doesn''t exist.';
  end if;
  insert into public.staff_directory (user_id) values (p_user) on conflict do nothing;
  insert into public.staff_private (user_id) values (p_user) on conflict do nothing;

  if p ? 'skills' then
    select coalesce(array_agg(distinct left(trim(x), 40)) filter (where trim(x) <> ''), '{}') into v_skills
      from jsonb_array_elements_text(p -> 'skills') x;
  end if;

  -- Anyone allowed here (themselves or a people manager).
  update public.staff_directory set
    preferred_name = case when p ? 'preferred_name' then left(trim(p ->> 'preferred_name'), 60) else preferred_name end,
    work_phone     = case when p ? 'work_phone' then left(trim(p ->> 'work_phone'), 30) else work_phone end,
    skills         = case when p ? 'skills' then v_skills else staff_directory.skills end,
    updated_at     = now()
   where user_id = p_user;
  update public.staff_private set
    address         = case when p ? 'address' then left(trim(p ->> 'address'), 300) else address end,
    emergency_name  = case when p ? 'emergency_name' then left(trim(p ->> 'emergency_name'), 100) else emergency_name end,
    emergency_phone = case when p ? 'emergency_phone' then left(trim(p ->> 'emergency_phone'), 30) else emergency_phone end,
    availability    = case when p ? 'availability' and jsonb_typeof(p -> 'availability') = 'object' then p -> 'availability' else availability end,
    updated_at      = now()
   where user_id = p_user;

  -- Employment details: people managers only.
  if manager then
    update public.staff_directory set
      department = case when p ? 'department' then left(trim(p ->> 'department'), 80) else department end
     where user_id = p_user;
    update public.staff_private set
      start_date      = case when p ? 'start_date' then nullif(p ->> 'start_date', '')::date else start_date end,
      employment_type = case when p ? 'employment_type' then coalesce(p ->> 'employment_type', '') else employment_type end,
      employee_id     = case when p ? 'employee_id' then left(trim(p ->> 'employee_id'), 40) else employee_id end
     where user_id = p_user;
  elsif p ?| array['department', 'start_date', 'employment_type', 'employee_id'] then
    raise exception 'Only people who manage staff can change department and employment details.';
  end if;

  if not me then
    perform public.write_audit('profile_updated', 'profile', p_user::text, '{}'::jsonb);
  end if;
end;
$$;

revoke execute on function public.save_profile(uuid, jsonb) from public, anon;
grant execute on function public.save_profile(uuid, jsonb) to authenticated;

$m072$;
  insert into public.install_log (name) values ('20261230000001_hr_pack_profiles.sql');
end;
$part$;

-- ====================================================================
-- 20261231000001_my_requests.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20261231000001_my_requests.sql') then
    return;
  end if;
  execute $m073$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- My requests (cmeprojects, HR Pack).
--   * Staff send requests (leave, shift swap, shift change, availability,
--     timesheet, HR enquiry, other), each with a reference (REQ-0001), a
--     status, comments and a full history.
--   * Who approves each type is set by the system admin: a first approver,
--     an optional second approver, who's told, and who hears about it if
--     nobody acts within so many days. Approvers are roles ("team_leader" is
--     the requester's own team leader) and/or chosen people.
--   * Approving changes real records, not just the status: leave becomes a
--     leave period, an availability change updates the weekly availability,
--     and swaps and shift changes are recorded per person (ready for rostering).

create table if not exists public.request_types (
  key             text primary key,
  label           text not null,
  feature_key     text not null,
  first_approvers text[] not null default '{}',
  second_approvers text[] not null default '{}',
  notify          text[] not null default '{}',
  escalate_days   int not null default 3 check (escalate_days between 0 and 60),
  escalate_to     text[] not null default '{manager}',
  sort_order      int not null default 0
);

insert into public.request_types (key, label, feature_key, first_approvers, second_approvers, sort_order) values
  ('leave', 'Leave', 'hr_req_leave', '{team_leader}', '{manager}', 10),
  ('swap', 'Shift swap', 'hr_req_swap', '{team_leader}', '{manager}', 20),
  ('shift', 'Shift change', 'hr_req_shift', '{team_leader}', '{manager}', 30),
  ('availability', 'Availability change', 'hr_req_availability', '{team_leader}', '{manager}', 40),
  ('timesheet', 'Timesheet correction', 'hr_req_timesheet', '{staff_admin}', '{manager}', 50),
  ('hr', 'HR or employment enquiry', 'hr_req_hr', '{staff_admin}', '{manager}', 60),
  ('other', 'Other request', 'hr_req_other', '{staff_admin}', '{}', 70)
on conflict (key) do nothing;

create table if not exists public.requests (
  id          uuid primary key default gen_random_uuid(),
  ref_number  bigint generated always as identity,
  type        text not null references public.request_types (key),
  requester   uuid not null references public.profiles (id) on delete cascade,
  status      text not null default 'pending' check (status in ('pending', 'info_needed', 'approved', 'declined', 'withdrawn')),
  stage       int not null default 1 check (stage in (1, 2)),
  subject     text not null default '' check (length(subject) <= 200),
  details     jsonb not null default '{}'::jsonb,
  start_date  date,
  end_date    date,
  swap_with   uuid references public.profiles (id) on delete set null,
  partner_ok  boolean,
  escalated_at timestamptz,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  decided_at  timestamptz,
  check (end_date is null or start_date is null or end_date >= start_date)
);
create index if not exists requests_requester on public.requests (requester, created_at desc);
create index if not exists requests_open on public.requests (status) where status in ('pending', 'info_needed');

create table if not exists public.request_events (
  id         bigint generated always as identity primary key,
  request_id uuid not null references public.requests (id) on delete cascade,
  actor      uuid references public.profiles (id) on delete set null,
  type       text not null,
  comment    text not null default '',
  created_at timestamptz not null default now()
);
create index if not exists request_events_request on public.request_events (request_id, id);

-- What approval changes.
create table if not exists public.leave_periods (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  request_id uuid references public.requests (id) on delete set null,
  leave_type text not null,
  start_date date not null,
  end_date   date not null,
  created_at timestamptz not null default now()
);
create table if not exists public.shift_changes (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  request_id uuid references public.requests (id) on delete set null,
  on_date    date,
  change     text not null,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Who approves
-- ---------------------------------------------------------------------------

-- The people a list like {team_leader, manager, user:<id>} means for one requester.
create or replace function public.resolve_people(p_list text[], p_requester uuid)
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select distinct id from (
    select tl.user_id as id
      from public.team_leaders tl join public.team_members tm on tm.team_id = tl.team_id
     where 'team_leader' = any (p_list) and tm.user_id = p_requester
    union
    select p.id from public.profiles p
     where p.active and p.role::text = any (p_list) and p.role::text <> 'team_leader'
    union
    select substr(x, 6)::uuid from unnest(p_list) x where x like 'user:%'
  ) s
  where id is not null and id <> p_requester
    and exists (select 1 from public.profiles q where q.id = s.id and q.active);
$$;

-- Who acts on a request at its current stage. With no team leader (or a team
-- leader asking for themselves), the step falls to the managers.
create or replace function public.request_approvers(p_request uuid)
returns setof uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  r public.requests;
  t public.request_types;
  list text[];
begin
  select * into r from public.requests where id = p_request;
  select * into t from public.request_types where key = r.type;
  list := case when r.stage = 1 then t.first_approvers else t.second_approvers end;
  return query select * from public.resolve_people(list, r.requester);
  if not found then
    return query select * from public.resolve_people('{manager}', r.requester);
  end if;
end;
$$;

create or replace function public.can_act_on_request(p_request uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and (public.is_system_admin() or exists (select 1 from public.request_approvers(p_request) a where a = auth.uid()))
$$;

-- ---------------------------------------------------------------------------
-- Who sees what
-- ---------------------------------------------------------------------------

alter table public.request_types enable row level security;
alter table public.requests enable row level security;
alter table public.request_events enable row level security;
alter table public.leave_periods enable row level security;
alter table public.shift_changes enable row level security;

drop policy if exists "members read request types" on public.request_types;
create policy "members read request types" on public.request_types for select to authenticated using (public.is_member());
drop policy if exists "system admin changes request types" on public.request_types;
create policy "system admin changes request types" on public.request_types for update to authenticated using (public.is_system_admin()) with check (public.is_system_admin());

drop policy if exists "people involved see a request" on public.requests;
create policy "people involved see a request" on public.requests for select to authenticated using (
  public.feature_enabled('hr_requests') and (
    requester = auth.uid() or swap_with = auth.uid() or public.can_manage_people() or public.is_system_admin()
    or public.can_act_on_request(id)));
drop policy if exists "people involved see its history" on public.request_events;
create policy "people involved see its history" on public.request_events for select to authenticated using (
  exists (select 1 from public.requests r where r.id = request_id));
drop policy if exists "the person and people managers see leave" on public.leave_periods;
create policy "the person and people managers see leave" on public.leave_periods for select to authenticated using (
  user_id = auth.uid() or public.can_manage_people() or public.is_system_admin()
  or exists (select 1 from public.team_leaders tl join public.team_members tm on tm.team_id = tl.team_id where tl.user_id = auth.uid() and tm.user_id = leave_periods.user_id));
drop policy if exists "the person and people managers see shift changes" on public.shift_changes;
create policy "the person and people managers see shift changes" on public.shift_changes for select to authenticated using (
  user_id = auth.uid() or public.can_manage_people() or public.is_system_admin()
  or exists (select 1 from public.team_leaders tl join public.team_members tm on tm.team_id = tl.team_id where tl.user_id = auth.uid() and tm.user_id = shift_changes.user_id));

revoke insert, update, delete, truncate on public.requests, public.request_events, public.leave_periods, public.shift_changes from anon, authenticated;
revoke insert, delete, truncate on public.request_types from anon, authenticated;
grant select on public.request_types, public.requests, public.request_events, public.leave_periods, public.shift_changes to authenticated;
grant update (first_approvers, second_approvers, notify, escalate_days, escalate_to) on public.request_types to authenticated;

-- ---------------------------------------------------------------------------
-- Sending and acting on requests
-- ---------------------------------------------------------------------------

create or replace function public.request_ref(p_request uuid)
returns text language sql stable set search_path = '' as $$
  select 'REQ-' || lpad(ref_number::text, 4, '0') from public.requests where id = p_request
$$;

-- Tell a list of people (bell, and email when the type allows).
create or replace function public.notify_many(p_people uuid[], p_kind text, p_title text, p_body text, p_href text)
returns void language plpgsql security definer set search_path = '' as $$
declare u uuid;
begin
  foreach u in array coalesce(p_people, '{}') loop
    perform public.notify(u, p_kind, p_title, p_body, p_href, true);
  end loop;
end;
$$;

create or replace function public.submit_request(p_type text, p_subject text, p_details jsonb, p_start date, p_end date, p_swap_with uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.request_types;
  v_id uuid;
  v_ref text;
  who text;
begin
  select * into t from public.request_types where key = p_type;
  if t.key is null then raise exception 'Choose a request type.'; end if;
  if not public.is_member() or not public.feature_live(t.feature_key) then
    raise exception '% requests are switched off.', t.label;
  end if;
  if public.is_system_admin() then raise exception 'The system admin doesn''t send requests.'; end if;
  if p_end is not null and p_start is not null and p_end < p_start then raise exception 'The end date is before the start date.'; end if;
  if p_type in ('leave', 'availability') and p_start is null then raise exception 'Choose the start date.'; end if;
  if p_type = 'swap' and p_swap_with is null then raise exception 'Choose who you''re swapping with.'; end if;
  if p_swap_with = auth.uid() then raise exception 'You can''t swap with yourself.'; end if;

  insert into public.requests (type, requester, subject, details, start_date, end_date, swap_with)
  values (p_type, auth.uid(), left(coalesce(trim(p_subject), ''), 200), coalesce(p_details, '{}'), p_start, coalesce(p_end, p_start), p_swap_with)
  returning id into v_id;
  insert into public.request_events (request_id, actor, type) values (v_id, auth.uid(), 'submitted');
  v_ref := public.request_ref(v_id);
  select coalesce(nullif(full_name, ''), email) into who from public.profiles where id = auth.uid();

  if p_type = 'swap' then
    perform public.notify(p_swap_with, 'request_partner', who || ' wants to swap a shift with you', v_ref || ': accept or decline it first.', '/requests/' || v_id, true);
  else
    perform public.notify_many(array(select public.request_approvers(v_id)), 'request_submitted', t.label || ' request from ' || who, v_ref || ' is waiting for you.', '/requests/' || v_id);
  end if;
  perform public.notify_many(array(select public.resolve_people(t.notify, auth.uid())), 'request_submitted', t.label || ' request from ' || who, v_ref || ' (for your information).', '/requests/' || v_id);
  return v_id;
end;
$$;

-- What approval changes in the person's records.
create or replace function public.apply_request(p_request uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare r public.requests;
begin
  select * into r from public.requests where id = p_request;
  if r.type = 'leave' then
    insert into public.leave_periods (user_id, request_id, leave_type, start_date, end_date)
    values (r.requester, r.id, coalesce(r.details ->> 'leave_type', 'other'), r.start_date, coalesce(r.end_date, r.start_date));
  elsif r.type = 'availability' and jsonb_typeof(r.details -> 'availability') = 'object' then
    insert into public.staff_private (user_id) values (r.requester) on conflict do nothing;
    update public.staff_private set availability = r.details -> 'availability', updated_at = now() where user_id = r.requester;
  elsif r.type = 'swap' then
    insert into public.shift_changes (user_id, request_id, on_date, change) values
      (r.requester, r.id, r.start_date, 'Swapped: ' || coalesce(r.details ->> 'my_shift', '') || ' with ' || coalesce((select coalesce(nullif(full_name, ''), email) from public.profiles where id = r.swap_with), 'a colleague')),
      (r.swap_with, r.id, r.start_date, 'Swapped: takes ' || coalesce(r.details ->> 'my_shift', '') || ' from ' || coalesce((select coalesce(nullif(full_name, ''), email) from public.profiles where id = r.requester), 'a colleague'));
  elsif r.type = 'shift' then
    insert into public.shift_changes (user_id, request_id, on_date, change)
    values (r.requester, r.id, r.start_date, 'Changed: ' || coalesce(r.details ->> 'current_shift', '') || ' → ' || coalesce(r.details ->> 'new_shift', ''));
  end if;
end;
$$;

create or replace function public.request_action(p_request uuid, p_action text, p_comment text default '')
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.requests;
  t public.request_types;
  v_ref text;
  note text := left(coalesce(trim(p_comment), ''), 2000);
  title text;
begin
  select * into r from public.requests where id = p_request for update;
  if r.id is null then raise exception 'That request doesn''t exist.'; end if;
  select * into t from public.request_types where key = r.type;
  v_ref := public.request_ref(r.id);
  title := t.label || ' request ' || v_ref;
  if not public.feature_live('hr_requests') then raise exception 'My requests are switched off.'; end if;

  if p_action = 'comment' then
    if note = '' then raise exception 'Write a comment first.'; end if;
    if not (r.requester = auth.uid() or r.swap_with = auth.uid() or public.can_act_on_request(r.id) or public.can_manage_people()) then
      raise exception 'You can''t comment on this request.';
    end if;
    insert into public.request_events (request_id, actor, type, comment) values (r.id, auth.uid(), 'comment', note);
    -- A reply from the person answers "more information needed".
    if r.requester = auth.uid() and r.status = 'info_needed' then
      update public.requests set status = 'pending', updated_at = now() where id = r.id;
      perform public.notify_many(array(select public.request_approvers(r.id)), 'request_submitted', title || ' has more information', note, '/requests/' || r.id);
    elsif r.requester <> auth.uid() then
      perform public.notify(r.requester, 'request_decided', 'New comment on ' || title, note, '/requests/' || r.id, false);
    end if;
    return 'Comment added.';
  end if;

  if p_action = 'withdraw' then
    if r.requester <> auth.uid() then raise exception 'Only the person who sent it can withdraw it.'; end if;
    if r.status not in ('pending', 'info_needed') then raise exception 'It''s already been decided.'; end if;
    update public.requests set status = 'withdrawn', updated_at = now(), decided_at = now() where id = r.id;
    insert into public.request_events (request_id, actor, type, comment) values (r.id, auth.uid(), 'withdrawn', note);
    return 'Request withdrawn.';
  end if;

  if p_action in ('partner_accept', 'partner_decline') then
    if r.swap_with is distinct from auth.uid() then raise exception 'Only the person asked to swap can answer this.'; end if;
    if r.partner_ok is not null or r.status <> 'pending' then raise exception 'You''ve already answered.'; end if;
    if p_action = 'partner_accept' then
      update public.requests set partner_ok = true, updated_at = now() where id = r.id;
      insert into public.request_events (request_id, actor, type, comment) values (r.id, auth.uid(), 'partner_accepted', note);
      perform public.notify_many(array(select public.request_approvers(r.id)), 'request_submitted', title || ' is ready to approve', 'Both people agreed to the swap.', '/requests/' || r.id);
      perform public.notify(r.requester, 'request_decided', 'Your swap was accepted', v_ref || ' now goes for approval.', '/requests/' || r.id, false);
      return 'Thanks. It now goes for approval.';
    end if;
    update public.requests set partner_ok = false, status = 'declined', updated_at = now(), decided_at = now() where id = r.id;
    insert into public.request_events (request_id, actor, type, comment) values (r.id, auth.uid(), 'partner_declined', note);
    perform public.notify(r.requester, 'request_decided', 'Your swap was declined', coalesce(nullif(note, ''), v_ref), '/requests/' || r.id, true);
    return 'Swap declined.';
  end if;

  -- Approver actions
  if not public.can_act_on_request(r.id) then raise exception 'You''re not an approver for this request.'; end if;
  if r.status not in ('pending', 'info_needed') then raise exception 'It''s already been decided.'; end if;
  if r.type = 'swap' and r.partner_ok is not true then raise exception 'Wait until the other person accepts the swap.'; end if;

  if p_action = 'info' then
    if note = '' then raise exception 'Say what information you need.'; end if;
    update public.requests set status = 'info_needed', updated_at = now() where id = r.id;
    insert into public.request_events (request_id, actor, type, comment) values (r.id, auth.uid(), 'info_requested', note);
    perform public.notify(r.requester, 'request_decided', 'More information needed for ' || title, note, '/requests/' || r.id, true);
    return 'Asked for more information.';
  elsif p_action = 'decline' then
    if note = '' then raise exception 'Give a reason for declining.'; end if;
    update public.requests set status = 'declined', updated_at = now(), decided_at = now() where id = r.id;
    insert into public.request_events (request_id, actor, type, comment) values (r.id, auth.uid(), 'declined', note);
    perform public.notify(r.requester, 'request_decided', title || ' was declined', note, '/requests/' || r.id, true);
    return 'Request declined.';
  elsif p_action = 'approve' then
    -- Two-step approval means two people, unless nobody else can give the final one.
    if r.stage = 2 and not public.is_system_admin()
       and exists (select 1 from public.request_events where request_id = r.id and type = 'approved_first' and actor = auth.uid())
       and exists (select 1 from public.request_approvers(r.id) a where a <> auth.uid()) then
      raise exception 'You gave the first approval. Someone else needs to give the final one.';
    end if;
    if r.stage = 1 and cardinality(t.second_approvers) > 0 and exists (select 1 from public.resolve_people(t.second_approvers, r.requester)) then
      update public.requests set stage = 2, status = 'pending', updated_at = now(), escalated_at = null where id = r.id;
      insert into public.request_events (request_id, actor, type, comment) values (r.id, auth.uid(), 'approved_first', note);
      perform public.notify_many(array(select public.request_approvers(r.id)), 'request_submitted', title || ' needs final approval', 'First approval done.', '/requests/' || r.id);
      perform public.notify(r.requester, 'request_decided', title || ': first approval done', 'It now goes for final approval.', '/requests/' || r.id, false);
      return 'Approved. It now goes for final approval.';
    end if;
    update public.requests set status = 'approved', updated_at = now(), decided_at = now() where id = r.id;
    insert into public.request_events (request_id, actor, type, comment) values (r.id, auth.uid(), 'approved', note);
    perform public.apply_request(r.id);
    perform public.notify(r.requester, 'request_decided', title || ' was approved', coalesce(nullif(note, ''), 'Approved.'), '/requests/' || r.id, true);
    if r.swap_with is not null then
      perform public.notify(r.swap_with, 'request_decided', 'The shift swap ' || v_ref || ' was approved', '', '/requests/' || r.id, true);
    end if;
    return 'Request approved.';
  end if;
  raise exception 'Unknown action.';
end;
$$;

-- Requests nobody has acted on within the set days go to the escalation list
-- (once per stage). Run by the scheduled job.
create or replace function public.escalate_requests()
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare r record; n int := 0;
begin
  for r in
    select q.*, t.label, t.escalate_to, t.escalate_days from public.requests q join public.request_types t on t.key = q.type
     where q.status = 'pending' and q.escalated_at is null and t.escalate_days > 0
       and q.updated_at < now() - make_interval(days => t.escalate_days)
       and (q.type <> 'swap' or q.partner_ok is true)
  loop
    update public.requests set escalated_at = now() where id = r.id;
    insert into public.request_events (request_id, type, comment) values (r.id, 'escalated', 'Nobody acted within ' || r.escalate_days || ' days.');
    perform public.notify_many(array(select public.resolve_people(r.escalate_to, r.requester)), 'request_escalated', r.label || ' request ' || public.request_ref(r.id) || ' is waiting', 'Nobody has acted on it for ' || r.escalate_days || ' days.', '/requests/' || r.id);
    n := n + 1;
  end loop;
  return n;
end;
$$;

revoke execute on function public.resolve_people(text[], uuid), public.request_approvers(uuid), public.can_act_on_request(uuid), public.request_ref(uuid),
  public.notify_many(uuid[], text, text, text, text), public.submit_request(text, text, jsonb, date, date, uuid), public.apply_request(uuid),
  public.request_action(uuid, text, text), public.escalate_requests() from public, anon;
grant execute on function public.can_act_on_request(uuid), public.request_ref(uuid), public.submit_request(text, text, jsonb, date, date, uuid),
  public.request_action(uuid, text, text), public.request_approvers(uuid) to authenticated;
grant execute on function public.escalate_requests() to service_role;

$m073$;
  insert into public.install_log (name) values ('20261231000001_my_requests.sql');
end;
$part$;

-- ====================================================================
-- 20270101000001_profile_requirement.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20270101000001_profile_requirement.sql') then
    return;
  end if;
  execute $m074$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Complete your profile (cmeprojects, HR Pack).
--   * While Staff profiles is on, everyone (except the system admin) needs a
--     complete profile: a contact phone and an emergency contact.
--   * It's part of onboarding: new starters can't be given a role until it's
--     done, and it shows in My onboarding with the other items.
--   * Saving a profile re-checks onboarding, so finishing the profile last
--     completes onboarding straight away.

create or replace function public.profile_complete(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select d.work_phone <> '' from public.staff_directory d where d.user_id = p_user), false)
     and coalesce((select pr.emergency_name <> '' and pr.emergency_phone <> '' from public.staff_private pr where pr.user_id = p_user), false)
$$;

create or replace function public.profile_required(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.feature_live('hr_profiles')
     and coalesce((select p.role::text not in ('system_admin', 'external') from public.profiles p where p.id = p_user), false)
     and not public.profile_complete(p_user)
$$;

create or replace function public.onboarding_missing(p_user uuid, p_role public.app_role default null, p_teams uuid[] default null)
returns text[]
language sql
stable
security definer
set search_path = ''
as $$
  select (case when public.profile_required(p_user) then array['Complete your profile'] else '{}'::text[] end)
      || coalesce((select array_agg(s.title order by array_position(array['read', 'training', 'upload'], s.kind), s.sort_order, s.title)
                     from public.compliance_status(p_user, p_role, p_teams) s
                    where s.state not in ('done', 'submitted', 'accepted', 'expiring')), '{}')
$$;

create or replace function public.profile_saved_check_onboarding()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.check_onboarding_complete(new.user_id);
  return new;
end;
$$;

drop trigger if exists profile_saved_check_onboarding on public.staff_directory;
create trigger profile_saved_check_onboarding after insert or update on public.staff_directory
  for each row execute function public.profile_saved_check_onboarding();
drop trigger if exists profile_saved_check_onboarding on public.staff_private;
create trigger profile_saved_check_onboarding after insert or update on public.staff_private
  for each row execute function public.profile_saved_check_onboarding();

revoke execute on function public.profile_complete(uuid), public.profile_required(uuid) from public, anon;
grant execute on function public.profile_complete(uuid), public.profile_required(uuid) to authenticated;

$m074$;
  insert into public.install_log (name) values ('20270101000001_profile_requirement.sql');
end;
$part$;

-- ====================================================================
-- 20270102000001_onboarding_clearance.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20270102000001_onboarding_clearance.sql') then
    return;
  end if;
  execute $m075$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Onboarding, compliance and clearance to work (cmeprojects, HR Pack).
--   * Three separate statuses: Onboarding complete (everything done or sent),
--     Compliance verified (every document and certificate checked) and Cleared
--     to work (granted by a manager, or a staff admin if delegated).
--   * Items marked "needed before working" must be done and verified before
--     someone can be cleared. The rest goes into a "Finish onboarding" task due
--     within their first week.
--   * Authorised overrides let someone work before that, with a reason and an
--     end date. Everything is in the change log.
--   * Registers can be "cleared staff only", and so can using a car: the
--     database refuses to give those tasks or trips to anyone not cleared.
--   * Documents get a category, issue date and number, and can be sent back
--     for replacement. Policies record opening and acknowledgement (typed name)
--     separately; trainings record a completion date, provider and certificate;
--     employment agreements are signed (drawn signature plus typed name, with
--     the exact version's fingerprint, time and device).
-- Uploading never marks anything as verified.

-- Items ----------------------------------------------------------------------
alter table public.compliance_items drop constraint if exists compliance_items_kind_check;
alter table public.compliance_items add constraint compliance_items_kind_check
  check (kind in ('read', 'training', 'upload', 'form', 'agreement'));
alter table public.compliance_items add column if not exists category text not null default '';
alter table public.compliance_items drop constraint if exists compliance_items_category_check;
alter table public.compliance_items add constraint compliance_items_category_check
  check (category in ('', 'qualification', 'certificate', 'screening', 'licence', 'insurance', 'identity', 'other'));
alter table public.compliance_items add column if not exists before_work boolean not null default false;
alter table public.compliance_items add column if not exists applies_titles uuid[] not null default '{}';
alter table public.compliance_items add column if not exists needs_issue_date boolean not null default false;
alter table public.compliance_items add column if not exists needs_number boolean not null default false;
-- Trainings: is a certificate needed (it's then checked like a document)?
alter table public.compliance_items add column if not exists certificate text not null default 'optional';
alter table public.compliance_items drop constraint if exists compliance_items_certificate_check;
alter table public.compliance_items add constraint compliance_items_certificate_check check (certificate in ('none', 'optional', 'required'));

-- Records --------------------------------------------------------------------
alter table public.compliance_records drop constraint if exists compliance_records_status_check;
alter table public.compliance_records add constraint compliance_records_status_check
  check (status in ('done', 'submitted', 'accepted', 'rejected', 'replace_requested'));
alter table public.compliance_records add column if not exists issued_on date;
alter table public.compliance_records add column if not exists doc_number text not null default '';
alter table public.compliance_records add column if not exists completed_on date;
alter table public.compliance_records add column if not exists provider text not null default '';
alter table public.compliance_records add column if not exists signed_name text not null default '';
alter table public.compliance_records add column if not exists signature_path text;
alter table public.compliance_records add column if not exists content_hash text not null default '';
alter table public.compliance_records add column if not exists signed_from text not null default '';

-- When a policy (or agreement) was opened, per version. Separate from acknowledging it.
create table if not exists public.compliance_opens (
  item_id   uuid not null references public.compliance_items (id) on delete cascade,
  user_id   uuid not null references public.profiles (id) on delete cascade,
  version   int not null,
  opened_at timestamptz not null default now(),
  primary key (item_id, user_id, version)
);
alter table public.compliance_opens enable row level security;
drop policy if exists "people see their own opens; compliance managers see all" on public.compliance_opens;
create policy "people see their own opens; compliance managers see all" on public.compliance_opens for select to authenticated
  using (user_id = auth.uid() or public.can_manage_compliance());

-- Statuses on the person -------------------------------------------------------
alter table public.profiles add column if not exists compliance_verified_at timestamptz;
alter table public.profiles add column if not exists cleared_at timestamptz;
alter table public.profiles add column if not exists cleared_by uuid references public.profiles (id);

create table if not exists public.work_overrides (
  id          bigint generated always as identity primary key,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  reason      text not null check (length(trim(reason)) between 3 and 500),
  until_date  date not null,
  granted_by  uuid not null references public.profiles (id),
  created_at  timestamptz not null default now(),
  ended_at    timestamptz,
  ended_by    uuid references public.profiles (id)
);
create index if not exists work_overrides_user_idx on public.work_overrides (user_id, until_date desc);
alter table public.work_overrides enable row level security;
drop policy if exists "the person and people who manage staff see overrides" on public.work_overrides;
create policy "the person and people who manage staff see overrides" on public.work_overrides for select to authenticated
  using (user_id = auth.uid() or public.can_manage_compliance() or public.can_manage_people()
         or public.has_role(array['manager']::public.app_role[]) or public.leads_user(user_id));

-- Registers: cleared staff only.
alter table public.registries add column if not exists cleared_only boolean not null default false;

-- Agreements are a Compliance part of their own (on by default, HR Pack).
insert into public.features (key, label, description, enabled, sort_order, premium, included, parent) values
  ('compliance_agreement', 'Employment agreements', 'Staff read and sign their employment agreement on screen.', true, 324, false, true, 'compliance')
on conflict (key) do nothing;

-- Settings: who besides managers clears people to work, and cars for cleared staff only.
insert into public.app_settings (key, value, label, description, is_public) values
  ('compliance.clearance_roles', '[]', 'Who can clear people to work',
   'Besides managers and the system admin. Tick staff admins to let them clear people and give overrides.', false),
  ('cars.cleared_only', 'false', 'Cars: cleared staff only',
   'Only staff cleared to work (or with an override) can start a trip.', false)
on conflict (key) do nothing;

-- Who may clear people to work: managers and the system admin, plus staff
-- admins when delegated (Settings: compliance.clearance_roles).
create or replace function public.can_grant_clearance()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.mfa_ok() and (public.my_role() in ('system_admin', 'manager')
         or (public.my_role() = 'staff_admin' and 'staff_admin' = any (public.setting_roles('compliance.clearance_roles'))))
$$;

-- A mandatory training (needed before working) always asks for a certificate.
create or replace function public.mandatory_training_needs_certificate()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.kind = 'training' and new.before_work then
    new.certificate := 'required';
  end if;
  return new;
end;
$$;
drop trigger if exists mandatory_training_needs_certificate on public.compliance_items;
create trigger mandatory_training_needs_certificate before insert or update on public.compliance_items
  for each row execute function public.mandatory_training_needs_certificate();
update public.compliance_items set certificate = 'required' where kind = 'training' and before_work and certificate <> 'required';

-- Which items apply: role, team and now job title.
create or replace function public.compliance_applies(p_item public.compliance_items, p_role public.app_role, p_teams uuid[], p_title uuid)
returns boolean
language sql
stable
set search_path = ''
as $$
  select public.compliance_applies(p_item, p_role, p_teams)
     and (cardinality(p_item.applies_titles) = 0 or p_title = any (p_item.applies_titles))
$$;

-- Everything that applies to a person, and where each is up to.
-- Internal (no permission check): used by the clearance rules, which must
-- give the same answer whoever is asking. Not callable by staff.
drop function if exists public.compliance_status_all(uuid, public.app_role, uuid[]);
create function public.compliance_status_all(p_user uuid, p_role public.app_role default null, p_teams uuid[] default null)
returns table (item_id uuid, kind text, title text, state text, record_id bigint, expires_on date, note text, sort_order int,
               before_work boolean, category text, needs_check boolean)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_role public.app_role;
  v_title uuid;
  v_teams uuid[];
  v_warn int := coalesce((select (value #>> '{}')::int from public.app_settings where key = 'compliance.expiry_warning_days'), 30);
  v_today date := public.local_today();
begin
  select coalesce(p_role, p.role), p.job_title_id into v_role, v_title from public.profiles p where p.id = p_user;
  v_teams := coalesce(p_teams, (select array_agg(team_id) from public.team_members where user_id = p_user), '{}');

  return query
  select i.id, i.kind, i.title,
         case
           when r.id is null then 'todo'
           -- Policies, agreements and forms: done for the current version.
           when i.kind in ('read', 'agreement', 'form') then case when r.version >= i.version then 'done' else 'update' end
           when r.status in ('rejected', 'replace_requested') then r.status
           when r.expires_on is not null and r.expires_on < v_today then 'expired'
           when r.expires_on is not null and r.expires_on <= v_today + v_warn then 'expiring'
           when i.kind = 'training' and r.status = 'done' and r.version < i.version then 'update'
           else r.status
         end,
         r.id, r.expires_on, coalesce(r.review_note, ''), i.sort_order,
         i.before_work, i.category,
         -- Has a file someone must check (uploads, and trainings with a certificate).
         (i.kind = 'upload' or (i.kind = 'training' and r.file_path is not null) or (i.kind = 'training' and (i.certificate = 'required' or i.before_work)))
    from public.compliance_items i
    left join lateral (
      select * from public.compliance_records cr
       where cr.item_id = i.id and cr.user_id = p_user
       order by cr.created_at desc, cr.id desc limit 1
    ) r on true
   where public.compliance_applies(i, v_role, v_teams, v_title)
   order by array_position(array['read', 'training', 'upload', 'agreement', 'form'], i.kind), i.sort_order, i.title;
end;
$$;
drop function if exists public.compliance_status(uuid, public.app_role, uuid[]);
create function public.compliance_status(p_user uuid, p_role public.app_role default null, p_teams uuid[] default null)
returns table (item_id uuid, kind text, title text, state text, record_id bigint, expires_on date, note text, sort_order int,
               before_work boolean, category text, needs_check boolean)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not (p_user = auth.uid() or public.can_manage_compliance() or public.can_manage_people()
          or public.has_role(array['manager']::public.app_role[]) or public.leads_user(p_user)
          or auth.uid() is null) then
    return;
  end if;
  return query select * from public.compliance_status_all(p_user, p_role, p_teams);
end;
$$;
revoke execute on function public.compliance_status_all(uuid, public.app_role, uuid[]) from public, anon, authenticated;
revoke execute on function public.compliance_status(uuid, public.app_role, uuid[]) from public, anon;
grant execute on function public.compliance_status(uuid, public.app_role, uuid[]) to authenticated;

-- Still to do before onboarding is complete (submitted counts: it's been sent).
create or replace function public.onboarding_missing(p_user uuid, p_role public.app_role default null, p_teams uuid[] default null)
returns text[]
language sql
stable
security definer
set search_path = ''
as $$
  select (case when public.profile_required(p_user) then array['Complete your profile'] else '{}'::text[] end)
      || coalesce((select array_agg(s.title order by array_position(array['read', 'training', 'upload', 'agreement', 'form'], s.kind), s.sort_order, s.title)
                     from public.compliance_status(p_user, p_role, p_teams) s
                    where s.state not in ('done', 'submitted', 'accepted', 'expiring')), '{}')
$$;

-- Needed before working and not yet done AND checked (titles).
create or replace function public.before_work_missing(p_user uuid)
returns text[]
language sql
stable
security definer
set search_path = ''
as $$
  select (case when public.profile_required(p_user) then array['Complete your profile'] else '{}'::text[] end)
      || coalesce((select array_agg(s.title order by s.sort_order, s.title)
                     from public.compliance_status_all(p_user) s
                    where s.before_work
                      and not (s.state in ('accepted', 'expiring') or (s.state = 'done' and not s.needs_check))), '{}')
$$;

-- Everything sent has been checked: no file waiting, rejected, expired or missing.
create or replace function public.compliance_is_verified(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select not public.profile_required(p_user)
     and not exists (select 1 from public.compliance_status_all(p_user) s where s.state not in ('done', 'submitted', 'accepted', 'expiring'))
     and not exists (select 1 from public.compliance_status_all(p_user) s where s.needs_check and s.state not in ('accepted', 'expiring'))
$$;

-- An override in force today.
create or replace function public.active_override(p_user uuid)
returns public.work_overrides
language sql
stable
security definer
set search_path = ''
as $$
  select o.* from public.work_overrides o
   where o.user_id = p_user and o.ended_at is null and o.until_date >= public.local_today()
   order by o.until_date desc limit 1
$$;

-- Can this person be given cleared-only duties? Cleared, and nothing needed
-- before working has since expired; or an override is in force.
create or replace function public.can_work(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (public.active_override(p_user)).id is not null
      or coalesce((select p.cleared_at is not null from public.profiles p where p.id = p_user), false)
         and cardinality(public.before_work_missing(p_user)) = 0
$$;

-- The three statuses, for the screens.
create or replace function public.work_status(p_user uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  p public.profiles;
  o public.work_overrides;
begin
  if not (p_user = auth.uid() or public.can_manage_compliance() or public.can_manage_people()
          or public.has_role(array['manager']::public.app_role[]) or public.leads_user(p_user)) then
    return null;
  end if;
  select * into p from public.profiles where id = p_user;
  o := public.active_override(p_user);
  return jsonb_build_object(
    'onboarding_complete', p.onboarded_at is not null and cardinality(public.onboarding_missing(p_user)) = 0,
    'onboarded_at', p.onboarded_at,
    'compliance_verified', public.compliance_is_verified(p_user),
    'cleared', p.cleared_at is not null,
    'cleared_at', p.cleared_at,
    'cleared_by', (select coalesce(nullif(full_name, ''), email) from public.profiles where id = p.cleared_by),
    'before_work_missing', to_jsonb(public.before_work_missing(p_user)),
    'can_work', public.can_work(p_user),
    'override', case when o.id is null then null else jsonb_build_object('id', o.id, 'reason', o.reason, 'until', o.until_date,
                  'by', (select coalesce(nullif(full_name, ''), email) from public.profiles where id = o.granted_by)) end);
end;
$$;

-- Keep "compliance verified" on the person up to date when records change.
create or replace function public.refresh_compliance_verified(p_user uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.compliance_is_verified(p_user) then
    update public.profiles set compliance_verified_at = coalesce(compliance_verified_at, now()) where id = p_user and compliance_verified_at is null;
  else
    update public.profiles set compliance_verified_at = null where id = p_user and compliance_verified_at is not null;
  end if;
end;
$$;

create or replace function public.compliance_record_changed()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.refresh_compliance_verified(new.user_id);
  return new;
end;
$$;
drop trigger if exists compliance_record_changed on public.compliance_records;
create trigger compliance_record_changed after insert or update on public.compliance_records
  for each row execute function public.compliance_record_changed();

-- Opening a policy or agreement (before acknowledging it).
create or replace function public.open_compliance_item(p_item_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  i public.compliance_items;
begin
  if not public.is_member() then
    raise exception 'Please sign in again';
  end if;
  select * into i from public.compliance_items where id = p_item_id and active;
  if i.id is null then
    raise exception 'That item isn''t available';
  end if;
  insert into public.compliance_opens (item_id, user_id, version) values (i.id, auth.uid(), i.version) on conflict do nothing;
end;
$$;

-- Acknowledge a policy: opened first, then a tick and their full name.
create or replace function public.acknowledge_policy(p_item_id uuid, p_name text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  i public.compliance_items;
  v_me text;
begin
  if not public.is_member() then
    raise exception 'Please sign in again';
  end if;
  select * into i from public.compliance_items where id = p_item_id and active and kind = 'read';
  if i.id is null then
    raise exception 'Choose a policy to acknowledge';
  end if;
  if not exists (select 1 from public.compliance_opens where item_id = i.id and user_id = auth.uid() and version = i.version) then
    raise exception 'Open and read the policy first';
  end if;
  select full_name into v_me from public.profiles where id = auth.uid();
  if lower(regexp_replace(trim(coalesce(p_name, '')), '\s+', ' ', 'g')) <> lower(regexp_replace(trim(coalesce(v_me, '')), '\s+', ' ', 'g')) then
    raise exception 'Type your full name exactly as it is on your account (%)', v_me;
  end if;
  insert into public.compliance_records (item_id, user_id, version, status, signed_name, content_hash)
  values (i.id, auth.uid(), i.version, 'done', trim(p_name),
          encode(sha256(convert_to(i.title || E'\n' || i.body || E'\n' || coalesce(i.file_path, '') || E'\n' || i.link_url, 'UTF8')), 'hex'));
  perform public.check_onboarding_complete(auth.uid());
end;
$$;

-- Complete a training: the date, provider, and a certificate (checked like a document).
create or replace function public.complete_training(p_item_id uuid, p_completed_on date, p_provider text default '',
                                                    p_path text default null, p_name text default null, p_expires date default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  i public.compliance_items;
  me public.profiles;
  v_admin uuid;
begin
  if not public.is_member() then
    raise exception 'Please sign in again';
  end if;
  select * into i from public.compliance_items where id = p_item_id and active and kind = 'training';
  if i.id is null then
    raise exception 'Choose a training';
  end if;
  if p_completed_on is null or p_completed_on > public.local_today() then
    raise exception 'Enter the date you completed it (not in the future)';
  end if;
  -- Mandatory trainings (needed before working) always need a certificate.
  if (i.certificate = 'required' or i.before_work) and p_path is null then
    raise exception 'Upload your certificate to complete this training';
  end if;
  if p_path is not null and p_path not like auth.uid()::text || '/%' then
    raise exception 'Upload the certificate again';
  end if;
  if i.needs_expiry and p_path is not null and p_expires is null then
    raise exception 'Enter the certificate''s expiry date';
  end if;
  if p_expires is not null and p_expires < public.local_today() then
    raise exception 'This certificate has already expired';
  end if;
  insert into public.compliance_records (item_id, user_id, version, status, completed_on, provider, file_path, file_name, expires_on)
  values (i.id, auth.uid(), i.version, case when p_path is null then 'done' else 'submitted' end, p_completed_on,
          left(trim(coalesce(p_provider, '')), 120), p_path, left(coalesce(p_name, ''), 200), p_expires);
  if p_path is not null then
    select * into me from public.profiles where id = auth.uid();
    for v_admin in select a from public.people_admins() a loop
      continue when v_admin = auth.uid();
      perform public.notify(v_admin, 'upload_submitted',
        format('%s sent a certificate for %s', coalesce(nullif(me.full_name, ''), me.email), i.title),
        'Check it in People → Onboarding.', '/compliance/people/' || auth.uid());
    end loop;
  end if;
  perform public.check_onboarding_complete(auth.uid());
end;
$$;

-- Upload a document with its details. Never verified on upload.
create or replace function public.submit_document(p_item_id uuid, p_path text, p_name text, p_expires date default null,
                                                  p_issued date default null, p_number text default '')
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  i public.compliance_items;
  v_id bigint;
begin
  select * into i from public.compliance_items where id = p_item_id and active and kind = 'upload';
  if i.id is null then
    raise exception 'Uploads for this document are switched off';
  end if;
  if i.needs_issue_date and p_issued is null then
    raise exception 'Enter the issue date';
  end if;
  if p_issued is not null and p_issued > public.local_today() then
    raise exception 'The issue date can''t be in the future';
  end if;
  if i.needs_number and coalesce(trim(p_number), '') = '' then
    raise exception 'Enter the document or card number';
  end if;
  perform public.submit_compliance_upload(p_item_id, p_path, p_name, p_expires);
  select id into v_id from public.compliance_records where item_id = i.id and user_id = auth.uid() order by id desc limit 1;
  update public.compliance_records set issued_on = p_issued, doc_number = left(trim(coalesce(p_number, '')), 60) where id = v_id;
end;
$$;

-- Sign an employment agreement: drawn signature (an image they uploaded to
-- their own folder) and their full name typed. Records the exact version.
create or replace function public.sign_agreement(p_item_id uuid, p_name text, p_signature_path text, p_device text default '')
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  i public.compliance_items;
  v_me text;
  v_ip text := coalesce(nullif(split_part(coalesce((nullif(current_setting('request.headers', true), '')::json ->> 'x-forwarded-for'), ''), ',', 1), ''), '');
begin
  if not public.is_member() then
    raise exception 'Please sign in again';
  end if;
  select * into i from public.compliance_items where id = p_item_id and active and kind = 'agreement';
  if i.id is null then
    raise exception 'Choose an agreement to sign';
  end if;
  if not exists (select 1 from public.compliance_opens where item_id = i.id and user_id = auth.uid() and version = i.version) then
    raise exception 'Open and read the agreement first';
  end if;
  select full_name into v_me from public.profiles where id = auth.uid();
  if lower(regexp_replace(trim(coalesce(p_name, '')), '\s+', ' ', 'g')) <> lower(regexp_replace(trim(coalesce(v_me, '')), '\s+', ' ', 'g')) then
    raise exception 'Type your full name exactly as it is on your account (%)', v_me;
  end if;
  if p_signature_path is null or p_signature_path !~ ('^' || auth.uid()::text || '/signature-[A-Za-z0-9._-]+\.png$') then
    raise exception 'Draw your signature, then sign again';
  end if;
  insert into public.compliance_records (item_id, user_id, version, status, signed_name, signature_path, content_hash, signed_from)
  values (i.id, auth.uid(), i.version, 'done', trim(p_name), p_signature_path,
          encode(sha256(convert_to(i.title || E'\n' || i.body || E'\n' || coalesce(i.file_path, '') || E'\n' || i.link_url, 'UTF8')), 'hex'),
          left(trim(concat_ws(' · ', nullif(v_ip, ''), nullif(trim(coalesce(p_device, '')), ''))), 300));
  perform public.write_audit('agreement_signed', 'compliance_item', i.id::text, jsonb_build_object('item', i.title, 'version', i.version));
  perform public.check_onboarding_complete(auth.uid());
end;
$$;

-- Checking documents: accept, reject (with a reason) or ask for a replacement.
create or replace function public.review_compliance_upload(p_record_id bigint, p_accept boolean, p_note text default '')
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.compliance_records;
  v_title text;
begin
  if not public.can_manage_compliance() then
    raise exception 'Only people who manage Compliance can check uploads';
  end if;
  select * into r from public.compliance_records where id = p_record_id for update;
  if r.id is null or r.file_path is null or r.status not in ('submitted', 'accepted', 'rejected', 'replace_requested') then
    raise exception 'Upload not found';
  end if;
  if r.user_id = auth.uid() then
    raise exception 'Someone else needs to check your own documents';
  end if;
  if not p_accept and coalesce(trim(p_note), '') = '' then
    raise exception 'Say what''s wrong, so they know what to upload';
  end if;
  update public.compliance_records
     set status = case when p_accept then 'accepted' else 'rejected' end,
         review_note = coalesce(trim(p_note), ''), reviewed_by = auth.uid(), reviewed_at = now()
   where id = r.id;
  select title into v_title from public.compliance_items where id = r.item_id;
  if not p_accept then
    perform public.notify(r.user_id, 'upload_rejected', format('Please upload %s again', v_title),
      trim(p_note), '/onboarding', true);
  end if;
  perform public.write_audit(case when p_accept then 'upload_accepted' else 'upload_rejected' end,
    'compliance_record', r.id::text, jsonb_build_object('item', v_title, 'note', p_note));
end;
$$;

create or replace function public.request_replacement(p_record_id bigint, p_note text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.compliance_records;
  v_title text;
begin
  if not public.can_manage_compliance() then
    raise exception 'Only people who manage Compliance can ask for a replacement';
  end if;
  if coalesce(trim(p_note), '') = '' then
    raise exception 'Say why a new one is needed';
  end if;
  select * into r from public.compliance_records where id = p_record_id for update;
  if r.id is null or r.file_path is null then
    raise exception 'Document not found';
  end if;
  update public.compliance_records
     set status = 'replace_requested', review_note = trim(p_note), reviewed_by = auth.uid(), reviewed_at = now()
   where id = r.id;
  select title into v_title from public.compliance_items where id = r.item_id;
  perform public.notify(r.user_id, 'upload_rejected', format('Please upload a new %s', v_title), trim(p_note), '/onboarding', true);
  perform public.write_audit('upload_replacement_requested', 'compliance_record', r.id::text, jsonb_build_object('item', v_title, 'note', p_note));
end;
$$;

-- The "Finish onboarding" task for what's left after clearance, due within a
-- week. New starters can't be given tasks, so theirs is made when they get a role.
create or replace function public.finish_onboarding_task(p_user uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_rest text[] := public.onboarding_missing(p_user);
begin
  if cardinality(v_rest) = 0 or not public.can_take_tasks(p_user)
     or (select cleared_at is null from public.profiles where id = p_user)
     or exists (select 1 from public.tasks t where t.assigned_to = p_user and t.title = 'Finish onboarding' and t.status not in ('completed', 'closed')) then
    return;
  end if;
  perform public.create_task(
    'Finish onboarding',
    (select id from public.registries where is_default and kind = 'tasks' and active order by sort_order limit 1),
    p_user,
    format(E'You''re cleared to work. Please finish the rest of your onboarding by %s.\n\nStill to do:\n%s\n\nOpen My onboarding to finish them.',
           to_char(public.local_today() + 7, 'FMDD Mon YYYY'),
           (select string_agg('• ' || x, E'\n') from unnest(v_rest) x)),
    'medium', public.local_today() + 7);
end;
$$;

create or replace function public.role_given_finish_onboarding()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.role = 'new_starter' and new.role <> 'new_starter' and new.cleared_at is not null then
    perform public.finish_onboarding_task(new.id);
  end if;
  return new;
end;
$$;
drop trigger if exists role_given_finish_onboarding on public.profiles;
create trigger role_given_finish_onboarding after update of role on public.profiles
  for each row execute function public.role_given_finish_onboarding();
revoke execute on function public.finish_onboarding_task(uuid) from public, anon, authenticated;

-- Clear someone to work. Everything needed before working must be done and
-- checked. Anything else left goes into a "Finish onboarding" task due within
-- a week (on the default General tasks register).
create or replace function public.grant_clearance(p_user uuid, p_note text default '')
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  p public.profiles;
  v_missing text[];
  v_rest text[];
begin
  if not public.can_grant_clearance() then
    raise exception 'Only managers (or staff admins they''ve delegated to) can clear people to work';
  end if;
  select * into p from public.profiles where id = p_user;
  if p.id is null or not p.active then
    raise exception 'Person not found';
  end if;
  if p_user = auth.uid() then
    raise exception 'Someone else needs to clear you to work';
  end if;
  v_missing := public.before_work_missing(p_user);
  if cardinality(v_missing) > 0 then
    raise exception 'Still needed before working: %. Finish and check these first, or give an override.', array_to_string(v_missing, ', ');
  end if;
  update public.profiles set cleared_at = now(), cleared_by = auth.uid() where id = p_user;
  v_rest := public.onboarding_missing(p_user);
  perform public.finish_onboarding_task(p_user);
  perform public.notify(p_user, 'cleared_to_work', 'You''re cleared to work',
    case when cardinality(v_rest) > 0 then 'Please finish the rest of your onboarding within a week.' else '' end, '/onboarding', true);
  perform public.write_audit('cleared_to_work', 'profile', p_user::text, jsonb_build_object('note', p_note, 'still_to_do', v_rest));
end;
$$;

create or replace function public.revoke_clearance(p_user uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.can_grant_clearance() then
    raise exception 'Only managers (or staff admins they''ve delegated to) can change clearance';
  end if;
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'Give a reason';
  end if;
  update public.profiles set cleared_at = null, cleared_by = null where id = p_user and cleared_at is not null;
  perform public.write_audit('clearance_removed', 'profile', p_user::text, jsonb_build_object('reason', trim(p_reason)));
end;
$$;

-- Let someone work before they're cleared, when really needed: a reason and
-- an end date (up to 30 days).
create or replace function public.grant_work_override(p_user uuid, p_reason text, p_until date)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id bigint;
begin
  if not public.can_grant_clearance() then
    raise exception 'Only managers (or staff admins they''ve delegated to) can give an override';
  end if;
  if p_user = auth.uid() then
    raise exception 'Someone else needs to give you an override';
  end if;
  if coalesce(length(trim(p_reason)), 0) < 3 then
    raise exception 'Give a reason for the override';
  end if;
  if p_until is null or p_until < public.local_today() or p_until > public.local_today() + 30 then
    raise exception 'Choose an end date within the next 30 days';
  end if;
  update public.work_overrides set ended_at = now(), ended_by = auth.uid() where user_id = p_user and ended_at is null;
  insert into public.work_overrides (user_id, reason, until_date, granted_by) values (p_user, trim(p_reason), p_until, auth.uid())
  returning id into v_id;
  perform public.notify(p_user, 'cleared_to_work', 'You can start work for now',
    format('Until %s. Please finish your onboarding.', to_char(p_until, 'FMDD Mon YYYY')), '/onboarding', true);
  perform public.write_audit('work_override_given', 'profile', p_user::text, jsonb_build_object('reason', trim(p_reason), 'until', p_until));
  return v_id;
end;
$$;

create or replace function public.end_work_override(p_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  o public.work_overrides;
begin
  if not public.can_grant_clearance() then
    raise exception 'Only managers (or staff admins they''ve delegated to) can end an override';
  end if;
  update public.work_overrides set ended_at = now(), ended_by = auth.uid() where id = p_id and ended_at is null returning * into o;
  if o.id is not null then
    perform public.write_audit('work_override_ended', 'profile', o.user_id::text, jsonb_build_object('reason', o.reason));
  end if;
end;
$$;

-- Duty restrictions ----------------------------------------------------------
create or replace function public.guard_cleared_tasks()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.assigned_to is not null
     and (tg_op = 'INSERT' or new.assigned_to is distinct from old.assigned_to)
     and exists (select 1 from public.registries r where r.id = new.registry_id and r.cleared_only)
     and not public.can_work(new.assigned_to) then
    raise exception 'This register is for cleared staff only, and % isn''t cleared to work yet',
      (select coalesce(nullif(full_name, ''), email) from public.profiles where id = new.assigned_to);
  end if;
  return new;
end;
$$;
drop trigger if exists guard_cleared_tasks on public.tasks;
create trigger guard_cleared_tasks before insert or update of assigned_to, registry_id on public.tasks
  for each row execute function public.guard_cleared_tasks();

create or replace function public.guard_cleared_trips()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if coalesce((select (value #>> '{}')::boolean from public.app_settings where key = 'cars.cleared_only'), false)
     and not public.can_work(new.driver_id) then
    raise exception 'Only staff cleared to work can use the cars';
  end if;
  return new;
end;
$$;
drop trigger if exists guard_cleared_trips on public.car_trips;
create trigger guard_cleared_trips before insert on public.car_trips
  for each row execute function public.guard_cleared_trips();

-- Grants -----------------------------------------------------------------------
revoke execute on function public.can_grant_clearance(), public.before_work_missing(uuid), public.compliance_is_verified(uuid),
  public.active_override(uuid), public.can_work(uuid), public.work_status(uuid), public.refresh_compliance_verified(uuid),
  public.open_compliance_item(uuid), public.acknowledge_policy(uuid, text),
  public.complete_training(uuid, date, text, text, text, date), public.submit_document(uuid, text, text, date, date, text),
  public.sign_agreement(uuid, text, text, text), public.request_replacement(bigint, text),
  public.grant_clearance(uuid, text), public.revoke_clearance(uuid, text), public.grant_work_override(uuid, text, date),
  public.end_work_override(bigint) from public, anon;
revoke execute on function public.refresh_compliance_verified(uuid), public.before_work_missing(uuid), public.compliance_is_verified(uuid),
  public.can_work(uuid), public.active_override(uuid) from authenticated;
grant execute on function public.can_grant_clearance(), public.work_status(uuid),
  public.open_compliance_item(uuid), public.acknowledge_policy(uuid, text),
  public.complete_training(uuid, date, text, text, text, date), public.submit_document(uuid, text, text, date, date, text),
  public.sign_agreement(uuid, text, text, text), public.request_replacement(bigint, text),
  public.grant_clearance(uuid, text), public.revoke_clearance(uuid, text), public.grant_work_override(uuid, text, date),
  public.end_work_override(bigint) to authenticated;

-- People already working before this update count as cleared, so nobody is
-- suddenly blocked. New starters from now on need clearing.
-- (Once only, so running this again never re-clears someone.)
do $$
begin
  if not exists (select 1 from public.app_settings where key = 'compliance.clearance_started') then
    update public.profiles set cleared_at = now()
     where active and role not in ('new_starter', 'external') and cleared_at is null;
    insert into public.app_settings (key, value, label, description, is_public)
    values ('compliance.clearance_started', to_jsonb(now()::text), 'Clearance to work started',
            'When clearance to work began on this copy. Staff working before then were counted as cleared.', false);
  end if;
end;
$$;

-- Defaults (once per copy). Paused guard as in update 53, so this also runs
-- when Compliance is switched off.
alter table public.compliance_items disable trigger compliance_items_guard;
-- Mandatory training: the NDIS Commission's free Worker Orientation Module.
insert into public.compliance_items (kind, title, description, link_url, before_work, certificate, active, sort_order, created_by)
select 'training', 'NDIS Worker Orientation Module: Quality, Safety and You',
       'The free online module from the NDIS Quality and Safeguards Commission (about 90 minutes). Complete it, then upload your certificate.',
       'https://training.ndiscommission.gov.au/', true, 'required', true, 10, null
where not exists (select 1 from public.compliance_items where title like 'NDIS Worker Orientation Module%');
-- Common documents, switched off until the company chooses them.
insert into public.compliance_items (kind, title, description, category, needs_expiry, needs_number, needs_issue_date, before_work, active, sort_order, created_by)
select v.kind, v.title, v.description, v.category, v.needs_expiry, v.needs_number, v.needs_issue_date, v.before_work, false, v.sort_order, null
  from (values
    ('upload', 'NDIS Worker Screening Check', 'Your NDIS Worker Screening clearance letter or card.', 'screening', true, true, false, true, 20),
    ('upload', 'Working with Children Check', 'Your Working with Children Check card or letter.', 'screening', true, true, false, true, 21),
    ('upload', 'National Police Check', 'A National Police Certificate issued in the last 3 years.', 'screening', false, false, true, true, 22),
    ('upload', 'First Aid and CPR certificate', 'HLTAID011 Provide First Aid (CPR is renewed every year).', 'certificate', true, false, true, false, 23),
    ('upload', 'Driver''s licence', 'Front and back of your current licence.', 'licence', true, true, false, false, 24),
    ('upload', 'Comprehensive car insurance', 'If you use your own car for work.', 'insurance', true, false, false, false, 25),
    ('upload', 'Qualification (Certificate III or IV)', 'For example Certificate III in Individual Support.', 'qualification', false, false, true, false, 26)
  ) as v(kind, title, description, category, needs_expiry, needs_number, needs_issue_date, before_work, sort_order)
 where not exists (select 1 from public.compliance_items c where c.title = v.title);
-- A sample employment agreement, switched off until the company adds its own.
insert into public.compliance_items (kind, title, description, body, before_work, active, sort_order, created_by)
select 'agreement', 'Employment agreement',
       'Read your employment agreement, then sign it on screen.',
       E'SAMPLE ONLY: replace this with your company''s employment agreement before switching it on.\n\nThis agreement is between the company and the employee named below. It covers the position, hours, pay, duties, confidentiality, and the company''s policies and procedures.',
       true, false, 30, null
where not exists (select 1 from public.compliance_items where kind = 'agreement');
alter table public.compliance_items enable trigger compliance_items_guard;

$m075$;
  insert into public.install_log (name) values ('20270102000001_onboarding_clearance.sql');
end;
$part$;

-- ====================================================================
-- 20270103000001_clearance_settings.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20270103000001_clearance_settings.sql') then
    return;
  end if;
  execute $m076$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- HR Pack delegation and clearance settings (cmeprojects).
--   * A new delegation area, HR Pack: request approvals (who approves each
--     request type, escalation) and who can clear people to work. The system
--     admin hands it to managers (or chosen people) on the Delegation tab, and
--     a delegated manager can share it with a staff admin.
--   * "Who can clear people to work" is no longer part of Compliance settings,
--     so delegated Compliance settings alone can't grant clearance powers.
--   * "Cars: cleared staff only" sits with the other Cars settings.

create or replace function public.setting_area(p_key text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when p_key = 'compliance.clearance_roles' then 'hr'
    when p_key = 'compliance.clearance_started' then null
    when p_key = 'cars.cleared_only' then 'vehicles'
    when p_key in ('brand.support_contact', 'brand.announcement', 'people.invite_message') then 'messages'
    when p_key like 'brand.%' or p_key like 'wording.%' then 'branding'
    when p_key like 'people.%' then 'people'
    when p_key like 'compliance.%' then 'compliance'
    when p_key like 'tasks.%' then 'tasks'
    when p_key like 'reports.%' then 'reports'
    when p_key like 'vehicles.%' then 'vehicles'
    when p_key like 'website.%' or p_key like 'assistant.%' then 'website'
    else null
  end
$$;

alter table public.delegation_rules drop constraint if exists delegation_rules_area_check;
alter table public.delegation_rules add constraint delegation_rules_area_check
  check (area in ('branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'website', 'audit', 'registers', 'roles', 'register_setup', 'hr'));
insert into public.delegation_rules (area, mode) values ('hr', 'admin') on conflict (area) do nothing;

alter table public.delegation_shares drop constraint if exists delegation_shares_area_check;
alter table public.delegation_shares add constraint delegation_shares_area_check
  check (area in ('branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'website', 'registers', 'hr'));

-- A delegated manager shares (or stops sharing) an area with a staff admin (HR Pack added).
create or replace function public.share_area(p_area text, p_user uuid, p_on boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.my_role() <> 'manager' or not public.can_admin_area(p_area) then
    raise exception 'Only a manager who looks after this area can share it.';
  end if;
  if p_area not in ('branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'website', 'registers', 'hr') then
    raise exception 'This area can''t be shared.';
  end if;
  if p_on then
    if not exists (select 1 from public.profiles where id = p_user and active and role = 'staff_admin') then
      raise exception 'Areas can only be shared with active staff admins.';
    end if;
    insert into public.delegation_shares (area, user_id, shared_by) values (p_area, p_user, auth.uid())
    on conflict (area, user_id) do update set shared_by = excluded.shared_by, shared_at = now();
  else
    delete from public.delegation_shares where area = p_area and user_id = p_user;
  end if;
  perform public.write_audit(case when p_on then 'area_shared' else 'area_unshared' end, 'profile', p_user::text, jsonb_build_object('area', p_area));
end;
$$;

-- Request approvals: the system admin, or whoever looks after HR Pack.
drop policy if exists "system admin changes request types" on public.request_types;
create policy "system admin changes request types" on public.request_types for update to authenticated
  using (public.can_admin_area('hr')) with check (public.can_admin_area('hr'));

$m076$;
  insert into public.install_log (name) values ('20270103000001_clearance_settings.sql');
end;
$part$;

-- ====================================================================
-- 20270104000001_rls_once_per_statement.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20270104000001_rls_once_per_statement.sql') then
    return;
  end if;
  execute $m077$
-- Staff Portal · © cmeproject. All rights reserved.
--
-- Security rules checked once per statement (cmeprojects, performance stage 1, RLS pattern A).
--   * 94 row-level security policies called functions that don't depend on the
--     row (auth.uid(), is_member(), has_role(...) and others) directly, so
--     Postgres ran them once for EVERY row. Each such call is now wrapped as
--     (select ...), which Postgres runs once per statement.
--   * Every wrapped function is STABLE and its arguments are fixed values, so
--     each policy's condition is unchanged: same rows, same permissions.
--   * Row-dependent checks (can_see_task(id), leads_user(...), and others) are
--     unchanged. No policy is added, removed or loosened.
-- Reviewed in docs/audit/2026-11-rls-register.md. Undo: undo-60.sql.

alter policy "system admin and the delegate read delegations" on public.admin_delegations
  using (((select public.is_system_admin()) OR (user_id = (select auth.uid()))));

alter policy "anyone reads public settings" on public.app_settings
  using ((is_public OR (select public.is_member())));

alter policy "car managers set the client field" on public.app_settings
  using (((key = 'vehicles.client_field'::text) AND (select public.can_manage_cars())))
  with check (((key = 'vehicles.client_field'::text) AND (select public.can_manage_cars()) AND ((value #>> '{}'::text[]) = ANY (ARRAY['off'::text, 'optional'::text, 'required'::text]))));

alter policy "system admin edits settings" on public.app_settings
  using ((select public.is_system_admin()))
  with check ((select public.is_system_admin()));

alter policy "assistant_chats_own" on public.assistant_chats
  using (((user_id = (select auth.uid())) AND (select public.is_member())))
  with check (((user_id = (select auth.uid())) AND (select public.is_member())));

alter policy "assistant_documents_all" on public.assistant_documents
  using ((select public.can_admin_area('website'::text)))
  with check ((select public.can_admin_area('website'::text)));

alter policy "assistant_messages_own" on public.assistant_messages
  using ((EXISTS ( SELECT 1
   FROM assistant_chats c
  WHERE ((c.id = assistant_messages.chat_id) AND (c.user_id = (select auth.uid()))))))
  with check ((EXISTS ( SELECT 1
   FROM assistant_chats c
  WHERE ((c.id = assistant_messages.chat_id) AND (c.user_id = (select auth.uid()))))));

alter policy "assistant_questions_read" on public.assistant_questions
  using ((select public.can_admin_area('website'::text)));

alter policy "assistant_settings_read" on public.assistant_settings
  using ((select public.can_admin_area('website'::text)));

alter policy "assistant_settings_write" on public.assistant_settings
  using ((select public.can_admin_area('website'::text)))
  with check ((select public.can_admin_area('website'::text)));

alter policy "delegated managers read the change log" on public.audit_log
  using ((select public.can_admin_area('audit'::text)));

alter policy "system admin reads the audit log" on public.audit_log
  using ((select public.is_system_admin()));

alter policy "car managers add clients" on public.car_clients
  with check ((select public.can_manage_cars()));

alter policy "car managers change clients" on public.car_clients
  using ((select public.can_manage_cars()))
  with check ((select public.can_manage_cars()));

alter policy "car managers see clients" on public.car_clients
  using ((select public.can_manage_cars()));

alter policy "people managers add clients" on public.car_clients
  with check ((select public.can_manage_people()));

alter policy "people managers change clients" on public.car_clients
  using ((select public.can_manage_people()))
  with check ((select public.can_manage_people()));

alter policy "people managers see clients" on public.car_clients
  using ((select public.can_manage_people()));

alter policy "car managers add purposes" on public.car_purposes
  with check ((select public.can_manage_cars()));

alter policy "car managers change purposes" on public.car_purposes
  using ((select public.can_manage_cars()))
  with check ((select public.can_manage_cars()));

alter policy "staff see purposes" on public.car_purposes
  using ((select public.cars_on()));

alter policy "drivers see their trips, reports see all" on public.car_trips
  using (((select public.cars_on()) AND ((driver_id = (select auth.uid())) OR (select public.can_see_car_reports()))));

alter policy "car managers add cars" on public.cars
  with check ((select public.can_manage_cars()));

alter policy "car managers change cars" on public.cars
  using ((select public.can_manage_cars()))
  with check ((select public.can_manage_cars()));

alter policy "staff see cars" on public.cars
  using ((select public.cars_on()));

alter policy "members see which team looks after which client" on public.client_teams
  using ((select public.is_member()));

alter policy "people managers link clients to teams" on public.client_teams
  with check ((select public.can_manage_people()));

alter policy "people managers unlink clients from teams" on public.client_teams
  using ((select public.can_manage_people()));

alter policy "compliance managers add items" on public.compliance_items
  with check ((select public.can_manage_compliance()));

alter policy "compliance managers change items" on public.compliance_items
  using ((select public.can_manage_compliance()))
  with check ((select public.can_manage_compliance()));

alter policy "members read onboarding items" on public.compliance_items
  using ((select public.is_member()));

alter policy "people see their own opens; compliance managers see all" on public.compliance_opens
  using (((user_id = (select auth.uid())) OR (select public.can_manage_compliance())));

alter policy "read your own records, or as compliance manager" on public.compliance_records
  using (((user_id = (select auth.uid())) OR (select public.can_manage_compliance())));

alter policy "the builder manages alerts" on public.custom_alerts
  using ((select public.can_build_features()))
  with check ((select public.can_build_features()));

alter policy "targets follow their feature" on public.custom_client_targets
  using (((select public.can_build_features()) OR ((select public.is_member()) AND public.custom_feature_live(feature_id))));

alter policy "the builder sets targets" on public.custom_client_targets
  using ((select public.can_build_features()))
  with check ((select public.can_build_features()));

alter policy "staff see live features, the builder sees all" on public.custom_features
  using (((select public.can_build_features()) OR ((select public.is_member()) AND (status = 'published'::text) AND enabled)));

alter policy "the builder adds features" on public.custom_features
  with check ((select public.can_build_features()));

alter policy "the builder changes features" on public.custom_features
  using ((select public.can_build_features()))
  with check ((select public.can_build_features()));

alter policy "the builder removes unused features" on public.custom_features
  using (((select public.can_build_features()) AND (NOT (EXISTS ( SELECT 1
   FROM custom_entries e
  WHERE (e.feature_id = custom_features.id))))));

alter policy "fields follow their feature" on public.custom_fields
  using (((select public.can_build_features()) OR ((select public.is_member()) AND public.custom_feature_live(feature_id))));

alter policy "the builder adds fields" on public.custom_fields
  with check ((select public.can_build_features()));

alter policy "the builder changes fields" on public.custom_fields
  using ((select public.can_build_features()))
  with check ((select public.can_build_features()));

alter policy "the builder removes unused fields" on public.custom_fields
  using (((select public.can_build_features()) AND (NOT (EXISTS ( SELECT 1
   FROM custom_entries e
  WHERE ((e.feature_id = custom_fields.feature_id) AND (e.data ? (custom_fields.id)::text)))))));

alter policy "members read delegation" on public.delegation_rules
  using ((select public.is_member()));

alter policy "members read shares" on public.delegation_shares
  using ((select public.is_member()));

alter policy "members read features" on public.features
  using ((select public.is_member()));

alter policy "system admin switches features" on public.features
  using ((select public.is_system_admin()))
  with check ((select public.is_system_admin()));

alter policy "the form's maker shares it" on public.form_collaborators
  using (((select public.is_system_admin()) OR (EXISTS ( SELECT 1
   FROM forms
  WHERE ((forms.id = form_collaborators.form_id) AND (forms.created_by = (select auth.uid())))))))
  with check (((select public.is_system_admin()) OR (EXISTS ( SELECT 1
   FROM forms
  WHERE ((forms.id = form_collaborators.form_id) AND (forms.created_by = (select auth.uid())))))));

alter policy "completions: your own, or the form's managers" on public.form_completions
  using (((user_id = (select auth.uid())) OR public.can_manage_form(form_id)));

alter policy "recipients see their own, managers all" on public.form_recipients
  using (((user_id = (select auth.uid())) OR public.can_manage_form(form_id)));

alter policy "replies: your own, or the form's managers" on public.form_responses
  using (((user_id = (select auth.uid())) OR ((status = 'submitted'::text) AND public.can_manage_form(form_id))));

alter policy "form makers add forms" on public.forms
  with check (((select public.can_make_forms()) AND (created_by = (select auth.uid()))));

alter policy "forms are seen by their managers, or to fill in" on public.forms
  using ((((created_by = (select auth.uid())) AND (select public.is_member())) OR public.can_manage_form(id) OR public.can_fill_form(id)));

alter policy "inviters create general invitations" on public.invitations
  with check ((select public.can_invite()));

alter policy "managers and admins create invitations" on public.invitations
  with check ((select public.can_manage_people()));

alter policy "managers and admins read invitations" on public.invitations
  using ((select public.can_manage_people()));

alter policy "managers and admins remove pending invitations" on public.invitations
  using (((select public.can_manage_people()) AND (accepted_at IS NULL)));

alter policy "managers and admins update invitations" on public.invitations
  using ((select public.can_manage_people()))
  with check ((select public.can_manage_people()));

alter policy "delegated people add job titles" on public.job_titles
  with check ((select public.can_admin_area('roles'::text)));

alter policy "delegated people change job titles" on public.job_titles
  using ((select public.can_admin_area('roles'::text)))
  with check ((select public.can_admin_area('roles'::text)));

alter policy "members read job titles" on public.job_titles
  using ((select public.is_member()));

alter policy "the person and people managers see leave" on public.leave_periods
  using (((user_id = (select auth.uid())) OR (select public.can_manage_people()) OR (select public.is_system_admin()) OR (EXISTS ( SELECT 1
   FROM (team_leaders tl
     JOIN team_members tm ON ((tm.team_id = tl.team_id)))
  WHERE ((tl.user_id = (select auth.uid())) AND (tm.user_id = leave_periods.user_id))))));

alter policy "read your own notifications" on public.notifications
  using ((user_id = (select auth.uid())));

alter policy "members read the company" on public.organisation
  using ((select public.is_member()));

alter policy "system admin edits the company" on public.organisation
  using ((select public.is_system_admin()))
  with check ((select public.is_system_admin()));

alter policy "managers and admins see change requests" on public.people_change_requests
  using ((select public.can_manage_people()));

alter policy "managers and admins update people" on public.profiles
  using ((select public.can_manage_people()))
  with check ((select public.can_manage_people()));

alter policy "members read colleagues" on public.profiles
  using (((select public.is_member()) AND ((role <> 'system_admin'::app_role) OR (select public.is_system_admin()))));

alter policy "read own profile" on public.profiles
  using ((id = (select auth.uid())));

alter policy "update own name" on public.profiles
  using (((id = (select auth.uid())) AND ((select public.my_role()) IS NOT NULL)))
  with check ((id = (select auth.uid())));

alter policy "members read record history" on public.record_events
  using ((select public.is_member()));

alter policy "members read records" on public.records
  using ((select public.is_member()));

alter policy "members read register templates" on public.register_templates
  using ((select public.is_member()));

alter policy "delegated people create registries" on public.registries
  with check ((select public.can_admin_area('registers'::text)));

alter policy "members read registries" on public.registries
  using ((select public.is_member()));

alter policy "members read registry fields" on public.registry_fields
  using ((select public.is_member()));

alter policy "members read registry managers" on public.registry_managers
  using ((select public.is_member()));

alter policy "members read request types" on public.request_types
  using ((select public.is_member()));

alter policy "system admin changes request types" on public.request_types
  using ((select public.can_admin_area('hr'::text)))
  with check ((select public.can_admin_area('hr'::text)));

alter policy "people involved see a request" on public.requests
  using (((select public.feature_enabled('hr_requests'::text)) AND ((requester = (select auth.uid())) OR (swap_with = (select auth.uid())) OR (select public.can_manage_people()) OR (select public.is_system_admin()) OR public.can_act_on_request(id))));

alter policy "see your drafts, the system admin sees all" on public.settings_drafts
  using (((select public.is_system_admin()) OR (saved_by = (select auth.uid()))));

alter policy "the person and people managers see shift changes" on public.shift_changes
  using (((user_id = (select auth.uid())) OR (select public.can_manage_people()) OR (select public.is_system_admin()) OR (EXISTS ( SELECT 1
   FROM (team_leaders tl
     JOIN team_members tm ON ((tm.team_id = tl.team_id)))
  WHERE ((tl.user_id = (select auth.uid())) AND (tm.user_id = shift_changes.user_id))))));

alter policy "members see the staff directory" on public.staff_directory
  using (((select public.is_member()) AND (select public.feature_enabled('hr_profiles'::text))));

alter policy "the person and people managers see private details" on public.staff_private
  using (((select public.feature_enabled('hr_profiles'::text)) AND ((user_id = (select auth.uid())) OR (select public.can_manage_people()) OR (select public.is_system_admin()) OR (EXISTS ( SELECT 1
   FROM (team_leaders tl
     JOIN team_members tm ON ((tm.team_id = tl.team_id)))
  WHERE ((tl.user_id = (select auth.uid())) AND (tm.user_id = staff_private.user_id)))))));

alter policy "read your own alerts" on public.task_alerts
  using ((user_id = (select auth.uid())));

alter policy "read your own views" on public.task_views
  using ((user_id = (select auth.uid())));

alter policy "members read team leaders" on public.team_leaders
  using ((select public.is_member()));

alter policy "members read team members" on public.team_members
  using ((select public.is_member()));

alter policy "managers and admins manage teams" on public.teams
  using ((select public.can_manage_people()))
  with check ((select public.can_manage_people()));

alter policy "members read teams" on public.teams
  using ((select public.is_member()));

alter policy "website_enquiries_read" on public.website_enquiries
  using ((select public.can_see_enquiries()));

alter policy "website_enquiries_update" on public.website_enquiries
  using ((select public.can_see_enquiries()))
  with check ((select public.can_see_enquiries()));

alter policy "the person and people who manage staff see overrides" on public.work_overrides
  using (((user_id = (select auth.uid())) OR (select public.can_manage_compliance()) OR (select public.can_manage_people()) OR public.has_role(ARRAY['manager'::app_role]) OR public.leads_user(user_id)));

$m077$;
  insert into public.install_log (name) values ('20270104000001_rls_once_per_statement.sql');
end;
$part$;

-- ====================================================================
-- 20270105000001_access_grants.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20270105000001_access_grants.sql') then
    return;
  end if;
  execute $m078$
-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects Phase 2: permissions tidy-up.
--   1. Access grants: who may edit staff details, and (from Phase 3) see
--      payroll/tax and identity/work-rights records. Scoped (all staff, chosen
--      teams or specific people), optional expiry, "may pass on", revoking
--      also ends what was passed on. Grants are never deleted: a revoked
--      grant keeps who revoked it and when, so the table is its own history.
--   2. Names: staff can't change their own name (only when it's still blank,
--      at account set-up); the system admin, or someone granted Staff
--      details, changes names. Every name change goes in the change log.
--   3. Staff details (save_profile): employment details and other people's
--      details need a Staff details grant (or the system admin).
--   4. Settings: only the system admin keeps drafts and Deploy; anyone else's
--      saved change applies straight away, in the same transaction.
-- No new SECURITY DEFINER function: has_access, grant_allowed, the grant
-- triggers and apply_draft are SECURITY INVOKER. Existing definer functions
-- (save_profile, guard_profile_update, save_draft, deploy_drafts) are updated.

-- ---------------------------------------------------------------------------
-- 1. Access grants
-- ---------------------------------------------------------------------------

create table if not exists public.access_grants (
  id             uuid primary key default gen_random_uuid(),
  area           text not null check (area in ('staff_details', 'payroll_tax', 'identity_docs')),
  user_id        uuid not null references public.profiles (id) on delete cascade,
  scope          text not null default 'all' check (scope in ('all', 'teams', 'people')),
  scope_ids      uuid[] not null default '{}',
  can_pass_on    boolean not null default false,
  can_reveal_tfn boolean not null default false,
  expires_at     timestamptz,
  parent_id      uuid references public.access_grants (id),
  granted_by     uuid references public.profiles (id),
  note           text not null default '' check (length(note) <= 300),
  created_at     timestamptz not null default now(),
  revoked_at     timestamptz,
  revoked_by     uuid references public.profiles (id),
  check (scope = 'all' or cardinality(scope_ids) > 0),
  check (can_reveal_tfn = false or area = 'payroll_tax'),
  check (parent_id is null or can_pass_on = false)
);

-- One live grant per person and area.
create unique index if not exists access_grants_one_live
  on public.access_grants (area, user_id) where revoked_at is null;
create index if not exists access_grants_parent on public.access_grants (parent_id) where parent_id is not null;

alter table public.access_grants enable row level security;
revoke all on public.access_grants from anon;
revoke delete, truncate on public.access_grants from authenticated;
grant select, insert, update on public.access_grants to authenticated;

-- Does the signed-in person hold a live grant for this area that covers this
-- person? The system admin always does. Reads only the caller's own grants
-- (and their own and the grantor's profile), so it runs as the caller.
create or replace function public.has_access(p_area text, p_person uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select public.mfa_ok() and (
    public.is_system_admin()
    or exists (
      select 1
        from public.access_grants g
        join public.profiles me on me.id = g.user_id
        left join public.profiles gb on gb.id = g.granted_by
       where g.user_id = auth.uid()
         and g.area = p_area
         and g.revoked_at is null
         and (g.expires_at is null or g.expires_at > now())
         and me.active and me.role in ('manager', 'staff_admin')
         -- passed on by a manager: that manager must still be an active manager
         and (g.parent_id is null or (gb.active and gb.role = 'manager'))
         and (g.scope = 'all'
              or (g.scope = 'people' and p_person = any (g.scope_ids))
              or (g.scope = 'teams' and exists (
                    select 1 from public.team_members tm
                     where tm.user_id = p_person and tm.team_id = any (g.scope_ids))))
    )
  )
$$;

revoke execute on function public.has_access(text, uuid) from public, anon;
grant execute on function public.has_access(text, uuid) to authenticated;

-- Is this new grant allowed for the signed-in person? Used by the insert rule.
create or replace function public.grant_allowed(
  p_area text, p_user uuid, p_scope text, p_scope_ids uuid[], p_pass_on boolean,
  p_tfn boolean, p_expires timestamptz, p_parent uuid, p_by uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select p_by = auth.uid() and public.mfa_ok()
     and (p_expires is null or p_expires > now())
     and (
       -- The system admin: first grants, to managers (sensitive areas) or
       -- managers and staff admins (staff details).
       (public.is_system_admin() and p_parent is null and exists (
          select 1 from public.profiles p
           where p.id = p_user and p.active
             and (p.role = 'manager' or (p_area = 'staff_details' and p.role = 'staff_admin'))))
       or
       -- A manager passing on their own grant: to a staff admin, never wider,
       -- never further, never longer.
       (public.my_role() = 'manager' and not p_pass_on and exists (
          select 1 from public.access_grants g
           where g.id = p_parent and g.user_id = auth.uid() and g.area = p_area
             and g.can_pass_on and g.revoked_at is null
             and (g.expires_at is null or g.expires_at > now())
             and (not p_tfn or g.can_reveal_tfn)
             and (g.expires_at is null or (p_expires is not null and p_expires <= g.expires_at))
             and (g.scope = 'all'
                  or (g.scope = p_scope and p_scope_ids <@ g.scope_ids)
                  or (g.scope = 'teams' and p_scope = 'people' and not exists (
                        select 1 from unnest(p_scope_ids) x
                         where not exists (select 1 from public.team_members tm where tm.user_id = x and tm.team_id = any (g.scope_ids))))))
        and exists (select 1 from public.profiles p where p.id = p_user and p.active and p.role = 'staff_admin'))
     )
$$;

revoke execute on function public.grant_allowed(text, uuid, text, uuid[], boolean, boolean, timestamptz, uuid, uuid) from public, anon;
grant execute on function public.grant_allowed(text, uuid, text, uuid[], boolean, boolean, timestamptz, uuid, uuid) to authenticated;

drop policy if exists "see your grants, ones you gave, or all (system admin)" on public.access_grants;
create policy "see your grants, ones you gave, or all (system admin)" on public.access_grants
  for select to authenticated
  using ((select public.is_system_admin()) or user_id = (select auth.uid()) or granted_by = (select auth.uid()));

drop policy if exists "grant within the rules" on public.access_grants;
create policy "grant within the rules" on public.access_grants
  for insert to authenticated
  with check (revoked_at is null and revoked_by is null
              and public.grant_allowed(area, user_id, scope, scope_ids, can_pass_on, can_reveal_tfn, expires_at, parent_id, granted_by));

-- Revoking: the system admin any grant; a manager the grants they passed on.
drop policy if exists "revoke your own grants or any (system admin)" on public.access_grants;
create policy "revoke your own grants or any (system admin)" on public.access_grants
  for update to authenticated
  using (revoked_at is null and ((select public.is_system_admin()) or granted_by = (select auth.uid())))
  with check ((select public.is_system_admin()) or granted_by = (select auth.uid()));

-- An update can only revoke: nothing else changes, and the time and person are set here.
create or replace function public.access_grant_revoke_only()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if old.revoked_at is not null then
    raise exception 'That access has already been removed.';
  end if;
  if (to_jsonb(new) - 'revoked_at' - 'revoked_by') is distinct from (to_jsonb(old) - 'revoked_at' - 'revoked_by')
     or new.revoked_at is null then
    raise exception 'Access can''t be changed, only removed. Remove it and give it again.';
  end if;
  new.revoked_at := now();
  new.revoked_by := auth.uid();
  return new;
end;
$$;

drop trigger if exists access_grants_revoke_only on public.access_grants;
create trigger access_grants_revoke_only before update on public.access_grants
  for each row execute function public.access_grant_revoke_only();

-- Revoking a grant also ends whatever was passed on from it.
create or replace function public.access_grant_cascade()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  update public.access_grants set revoked_at = now()
   where parent_id = new.id and revoked_at is null;
  return null;
end;
$$;

drop trigger if exists access_grants_cascade on public.access_grants;
create trigger access_grants_cascade after update of revoked_at on public.access_grants
  for each row when (new.revoked_at is not null and old.revoked_at is null)
  execute function public.access_grant_cascade();

revoke execute on function public.access_grant_revoke_only() from public, anon, authenticated;
revoke execute on function public.access_grant_cascade() from public, anon, authenticated;

-- Rollout (owner decision 1): everyone who edits staff details today keeps
-- doing so, visibly and revocably: active managers (may pass on) and staff
-- admins, all staff, given by the system admin. Safe to run again.
insert into public.access_grants (area, user_id, scope, can_pass_on, granted_by, note)
select 'staff_details', p.id, 'all', p.role = 'manager',
       (select a.id from public.profiles a where a.role = 'system_admin' and a.active order by a.created_at limit 1),
       'Kept from before (Phase 2 rollout)'
  from public.profiles p
 where p.active and p.role in ('manager', 'staff_admin')
   and not exists (select 1 from public.access_grants g where g.area = 'staff_details' and g.user_id = p.id and g.revoked_at is null);

-- ---------------------------------------------------------------------------
-- 2 and 3. Names and staff details
-- ---------------------------------------------------------------------------

-- Fields a person edits themselves, and fields only people with a Staff
-- details grant (or the system admin) edit, for the people their grant covers.
create or replace function public.save_profile(p_user uuid, p jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  me boolean := p_user = auth.uid();
  manager boolean := public.has_access('staff_details', p_user);
  v_skills text[];
begin
  if not public.is_member() or not public.feature_enabled('hr_profiles') then
    raise exception 'Staff profiles are switched off.';
  end if;
  if not me and not manager then
    raise exception 'You don''t have access to change this person''s details. The system admin can give you access.';
  end if;
  if not exists (select 1 from public.profiles where id = p_user) then
    raise exception 'That person doesn''t exist.';
  end if;
  insert into public.staff_directory (user_id) values (p_user) on conflict do nothing;
  insert into public.staff_private (user_id) values (p_user) on conflict do nothing;

  if p ? 'skills' then
    select coalesce(array_agg(distinct left(trim(x), 40)) filter (where trim(x) <> ''), '{}') into v_skills
      from jsonb_array_elements_text(p -> 'skills') x;
  end if;

  update public.staff_directory set
    preferred_name = case when p ? 'preferred_name' then left(trim(p ->> 'preferred_name'), 60) else preferred_name end,
    work_phone     = case when p ? 'work_phone' then left(trim(p ->> 'work_phone'), 30) else work_phone end,
    skills         = case when p ? 'skills' then v_skills else staff_directory.skills end,
    updated_at     = now()
   where user_id = p_user;
  update public.staff_private set
    address         = case when p ? 'address' then left(trim(p ->> 'address'), 300) else address end,
    emergency_name  = case when p ? 'emergency_name' then left(trim(p ->> 'emergency_name'), 100) else emergency_name end,
    emergency_phone = case when p ? 'emergency_phone' then left(trim(p ->> 'emergency_phone'), 30) else emergency_phone end,
    availability    = case when p ? 'availability' and jsonb_typeof(p -> 'availability') = 'object' then p -> 'availability' else availability end,
    updated_at      = now()
   where user_id = p_user;

  if manager then
    update public.staff_directory set
      department = case when p ? 'department' then left(trim(p ->> 'department'), 80) else department end
     where user_id = p_user;
    update public.staff_private set
      start_date      = case when p ? 'start_date' then nullif(p ->> 'start_date', '')::date else start_date end,
      employment_type = case when p ? 'employment_type' then coalesce(p ->> 'employment_type', '') else employment_type end,
      employee_id     = case when p ? 'employee_id' then left(trim(p ->> 'employee_id'), 40) else employee_id end
     where user_id = p_user;
  elsif p ?| array['department', 'start_date', 'employment_type', 'employee_id'] then
    raise exception 'Only people with access to staff details can change department and employment details.';
  end if;

  if not me then
    perform public.write_audit('profile_updated', 'profile', p_user::text, '{}'::jsonb);
  end if;
end;
$$;

revoke execute on function public.save_profile(uuid, jsonb) from public, anon;
grant execute on function public.save_profile(uuid, jsonb) to authenticated;

-- The profile guard, with the name rule added (section "Names").
create or replace function public.guard_profile_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor uuid := auth.uid();
begin
  if new.id <> old.id or new.email <> old.email or new.org_id <> old.org_id then
    raise exception 'This field cannot be changed here';
  end if;

  -- Names (cmeprojects Phase 2): your own only while it's still blank (account
  -- set-up); someone else's with a Staff details grant covering them, or as the
  -- system admin. System jobs (no signed-in person) aren't affected.
  if actor is not null and new.full_name is distinct from old.full_name then
    if new.id = actor and coalesce(trim(old.full_name), '') <> '' and not public.is_system_admin() then
      raise exception 'Your name is set by the office. Ask your manager or the system admin to change it.';
    end if;
    if new.id <> actor and not public.has_access('staff_details', new.id) then
      raise exception 'You don''t have access to change this person''s name. The system admin can give you access.';
    end if;
    if new.id <> actor and old.role = 'system_admin' and not public.is_system_admin() then
      raise exception 'Only a system admin can rename a system admin';
    end if;
    perform public.write_audit('name_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.full_name, 'to', new.full_name));
  end if;

  if actor is not null then
    if new.role is distinct from old.role
       or new.team_id is distinct from old.team_id
       or new.active is distinct from old.active then

      if not public.can_manage_people() then
        raise exception 'Only managers and admins can change roles, teams or access';
      end if;

      if new.id = actor and (new.role is distinct from old.role or not new.active) then
        raise exception 'You cannot change your own role or deactivate yourself';
      end if;

      if new.id <> actor and (not public.can_manage_role(old.role) or not public.can_manage_role(new.role)) then
        raise exception 'Only a system admin can manage system admins';
      end if;

      if old.role = 'new_starter' and new.role <> 'new_starter'
         and coalesce(current_setting('app.conditional_role', true), '') <> 'on'
         and cardinality(public.onboarding_missing(new.id, new.role, null)) > 0 then
        raise exception 'They haven''t finished onboarding yet. Give a conditional role with a deadline instead.';
      end if;

      if new.role is distinct from old.role and public.my_role() = 'staff_admin'
         and public.rule_on('people.staff_admin_role_approval')
         and (old.role <> 'new_starter' or public.rule_on('people.first_role_approval')) then
        raise exception 'Role changes by a staff admin need a manager''s approval. Send it as a request.';
      end if;
      if new.team_id is distinct from old.team_id and public.my_role() = 'staff_admin'
         and public.rule_on('people.staff_admin_team_approval') then
        raise exception 'Team changes by a staff admin need a manager''s approval. Send it as a request.';
      end if;
    end if;
  end if;

  if actor is not null and not public.is_system_admin()
     and old.role = 'manager' and old.active
     and (new.role <> 'manager' or not new.active)
     and not exists (select 1 from public.profiles where role = 'manager' and active and id <> old.id) then
    raise exception 'They''re the only manager left, so they can''t be deactivated or given another role. Add another manager first.';
  end if;

  if old.role = 'system_admin' and old.active
     and (new.role <> 'system_admin' or not new.active)
     and not exists (
       select 1 from public.profiles
        where role = 'system_admin' and active and id <> old.id
     ) then
    raise exception 'There must always be at least one active system admin';
  end if;

  if new.active and not old.active then
    new.deactivated_at := null;
  elsif not new.active and old.active then
    new.deactivated_at := now();
  end if;

  if new.role is distinct from old.role then
    perform public.write_audit('role_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.role, 'to', new.role));
  end if;
  if new.active is distinct from old.active then
    perform public.write_audit(
      case when new.active then 'reactivated' else 'deactivated' end,
      'profile', new.id::text, '{}'::jsonb);
  end if;
  if new.team_id is distinct from old.team_id then
    perform public.write_audit('team_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.team_id, 'to', new.team_id));
  end if;

  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. Settings: save applies straight away for everyone but the system admin
-- ---------------------------------------------------------------------------

-- Make one saved change live. Runs inside save_draft / deploy_drafts only
-- (nobody can call it directly).
create or replace function public.apply_draft(p_kind text, p_key text)
returns boolean
language plpgsql
security invoker
set search_path = ''
as $$
declare
  d record;
  v_enabled boolean;
  v_col text;
begin
  select * into d from public.settings_drafts where kind = p_kind and key = p_key for update;
  if not found or not public.may_change(d.kind, d.key) then
    return false;
  end if;
  if d.kind = 'setting' then
    update public.app_settings set value = d.value, updated_at = now(), updated_by = auth.uid() where key = d.key;
  elsif d.kind = 'feature' then
    v_enabled := (d.value ->> 'enabled')::boolean;
    update public.features
       set enabled = v_enabled,
           included = case when v_enabled and premium then true else included end,
           updated_at = now(), updated_by = auth.uid()
     where key = d.key;
  elsif d.kind = 'website' then
    for v_col in select jsonb_object_keys(d.value) loop
      execute format('update public.assistant_settings set %I = (jsonb_populate_record(null::public.assistant_settings, $1)).%I where id', v_col, v_col)
        using d.value;
    end loop;
    perform public.write_audit('website_settings_changed', 'website', d.key, '{}'::jsonb);
  else
    update public.delegation_rules
       set mode = d.value ->> 'mode',
           people = coalesce((select array_agg(x::uuid) from jsonb_array_elements_text(d.value -> 'people') x), '{}'),
           updated_by = auth.uid(), updated_at = now()
     where area = d.key;
    perform public.write_audit('delegation_changed', 'area', d.key, d.value);
  end if;
  delete from public.settings_drafts where kind = d.kind and key = d.key;
  return true;
end;
$$;

revoke execute on function public.apply_draft(text, text) from public, anon, authenticated;

-- Make saved changes live: everyone's for the system admin, your own for others.
create or replace function public.deploy_drafts()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  d record;
  v_count integer := 0;
begin
  if auth.uid() is null then
    raise exception 'Please sign in first.';
  end if;
  for d in
    select kind, key from public.settings_drafts
     where public.is_system_admin() or saved_by = auth.uid()
     order by case kind when 'feature' then 1 when 'setting' then 2 when 'website' then 3 else 4 end, key
  loop
    if public.apply_draft(d.kind, d.key) then
      v_count := v_count + 1;
    end if;
  end loop;
  if v_count > 0 then
    perform public.write_audit('settings_deployed', 'settings', 'deploy', jsonb_build_object('changes', v_count));
  end if;
  return v_count;
end;
$$;

-- Save a change. The system admin's changes wait as drafts for Deploy;
-- everyone else's apply straight away in this same transaction (any error
-- leaves nothing changed). Returns 'saved', 'live' or 'unchanged'.
create or replace function public.save_draft(p_kind text, p_key text, p_value jsonb)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_live jsonb;
  v_value jsonb := p_value;
begin
  if p_kind = 'website' then
    if p_key not in ('landing', 'answers', 'limits') or jsonb_typeof(p_value) <> 'object' or exists (
      select 1 from jsonb_object_keys(p_value) k
       where k in ('id', 'updated_at')
          or k not in (select column_name::text from information_schema.columns where table_schema = 'public' and table_name = 'assistant_settings')
    ) then
      raise exception 'Something went wrong. Please refresh and try again.';
    end if;
    select jsonb_object_agg(k, to_jsonb(s) -> k) into v_live
      from public.assistant_settings s, jsonb_object_keys(p_value) k
     where s.id;
  else
    v_live := public.live_value(p_kind, p_key);
  end if;
  if not public.may_change(p_kind, p_key) then
    raise exception 'You don''t have permission to change this.';
  end if;
  if v_live is null then
    raise exception 'This setting doesn''t exist.';
  end if;
  if p_kind = 'feature' then
    if jsonb_typeof(p_value -> 'enabled') <> 'boolean' then
      raise exception 'Choose on or off.';
    end if;
    v_value := jsonb_build_object('enabled', p_value -> 'enabled');
  elsif p_kind = 'delegation' then
    if coalesce(p_value ->> 'mode', '') not in ('admin', 'managers', 'selected') then
      raise exception 'Choose who looks after it.';
    end if;
    v_value := jsonb_build_object(
      'mode', p_value ->> 'mode',
      'people', coalesce((
        select jsonb_agg(p.id order by p.full_name)
          from public.profiles p
         where p.active and p.role in ('manager', 'staff_admin')
           and p.id::text in (select jsonb_array_elements_text(coalesce(p_value -> 'people', '[]')))
      ), '[]'));
    if v_value ->> 'mode' = 'selected' and jsonb_array_length(v_value -> 'people') = 0 then
      raise exception 'Choose at least one manager or staff admin.';
    end if;
    if v_value ->> 'mode' <> 'selected' then
      v_value := jsonb_set(v_value, '{people}', '[]');
    end if;
  end if;

  if v_value = v_live then
    delete from public.settings_drafts where kind = p_kind and key = p_key;
    return 'unchanged';
  end if;
  insert into public.settings_drafts (kind, key, value, saved_by)
  values (p_kind, p_key, v_value, auth.uid())
  on conflict (kind, key) do update set value = excluded.value, saved_by = excluded.saved_by, saved_at = now();

  if not public.is_system_admin() then
    if not public.apply_draft(p_kind, p_key) then
      raise exception 'Your change couldn''t be applied. Nothing was changed.';
    end if;
    perform public.write_audit('setting_changed', p_kind, p_key, jsonb_build_object('value', v_value));
    return 'live';
  end if;
  return 'saved';
end;
$$;

$m078$;
  insert into public.install_log (name) values ('20270105000001_access_grants.sql');
end;
$part$;

-- ====================================================================
-- 20270106000001_staff_records.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20270106000001_staff_records.sql') then
    return;
  end if;
  execute $m079$
-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects Phase 3: staff records.
--   1. First Aid, CPR and Life saving as separate default onboarding items
--      (switched off until the company chooses them).
--   2. Expiry reminders in stages: 60, 30 and 7 days before, on the day, and
--      once expired, to the person and the people who manage onboarding.
--      Visa expiry too, to the person and those with Identity and work
--      rights access covering them.
--   3. Sensitive records: bank details and super (Payroll and tax access),
--      work rights and visa (Identity and work rights access). Readable and
--      changeable only by the person and people whose access covers them
--      (has_access, Phase 2). Never in the directory, dashboards,
--      notifications or reports.
--   4. A record of access: every change is logged by the database; views,
--      reveals and downloads are logged by the app before anything is shown.
--   5. A separate private file store for these documents.
-- Tax file numbers are NOT collected yet (waiting on the accountant/ATO review).
-- No new SECURITY DEFINER function (run_compliance_alerts is updated).

-- ---------------------------------------------------------------------------
-- 1. Default certificate items
-- ---------------------------------------------------------------------------
alter table public.compliance_items disable trigger compliance_items_guard;
insert into public.compliance_items (kind, title, description, category, needs_expiry, needs_number, needs_issue_date, before_work, active, sort_order, created_by)
select v.kind, v.title, v.description, 'certificate', true, false, true, false, false, v.sort_order, null
  from (values
    ('upload', 'First Aid certificate', 'HLTAID011 Provide First Aid (usually renewed every 3 years).', 27),
    ('upload', 'CPR certificate', 'HLTAID009 Provide cardiopulmonary resuscitation (renewed every year).', 28),
    ('upload', 'Life saving certificate', 'For example a Bronze Medallion or pool lifeguard certificate, if your work needs it.', 29)
  ) as v(kind, title, description, sort_order)
 where not exists (select 1 from public.compliance_items c where c.title = v.title);
alter table public.compliance_items enable trigger compliance_items_guard;

-- ---------------------------------------------------------------------------
-- 2. Staged expiry reminders
-- ---------------------------------------------------------------------------
alter table public.compliance_alerts drop constraint if exists compliance_alerts_step_check;
alter table public.compliance_alerts add constraint compliance_alerts_step_check
  check (step in ('expiring', 'expired', 'd60', 'd30', 'd7', 'today'));

-- Which reminder is due for something that expires on p_expires (null: none yet).
create or replace function public.expiry_stage(p_expires date)
returns text
language sql
stable
security invoker
set search_path = ''
as $$
  select case
    when p_expires is null then null
    when p_expires < public.local_today() then 'expired'
    when p_expires = public.local_today() then 'today'
    when p_expires - public.local_today() <= 7 then 'd7'
    when p_expires - public.local_today() <= 30 then 'd30'
    when p_expires - public.local_today() <= 60 then 'd60'
  end
$$;

-- ---------------------------------------------------------------------------
-- 3. Sensitive records
-- ---------------------------------------------------------------------------
create table if not exists public.staff_bank (
  user_id        uuid primary key references public.profiles (id) on delete cascade,
  account_name   text not null default '' check (length(account_name) <= 100),
  bsb            text not null default '' check (bsb = '' or bsb ~ '^\d{3}-\d{3}$'),
  account_number text not null default '' check (account_number = '' or account_number ~ '^\d{5,9}$'),
  updated_at     timestamptz not null default now(),
  updated_by     uuid references public.profiles (id),
  verified_at    timestamptz,
  verified_by    uuid references public.profiles (id)
);

create table if not exists public.staff_super (
  user_id       uuid primary key references public.profiles (id) on delete cascade,
  fund_name     text not null default '' check (length(fund_name) <= 120),
  fund_abn      text not null default '' check (fund_abn = '' or fund_abn ~ '^\d{11}$'),
  usi           text not null default '' check (length(usi) <= 20),
  member_number text not null default '' check (length(member_number) <= 30),
  choice_doc    text not null default '' check (length(choice_doc) <= 300),
  choice_name   text not null default '' check (length(choice_name) <= 200),
  updated_at    timestamptz not null default now(),
  updated_by    uuid references public.profiles (id),
  verified_at   timestamptz,
  verified_by   uuid references public.profiles (id)
);

create table if not exists public.staff_work_rights (
  user_id         uuid primary key references public.profiles (id) on delete cascade,
  status          text not null default '' check (status in ('', 'citizen', 'permanent_resident', 'nz_citizen', 'visa')),
  visa_subclass   text not null default '' check (length(visa_subclass) <= 20),
  visa_conditions text not null default '' check (length(visa_conditions) <= 500),
  visa_expiry     date,
  vevo_checked_on date,
  visa_doc        text not null default '' check (length(visa_doc) <= 300),
  visa_doc_name   text not null default '' check (length(visa_doc_name) <= 200),
  vevo_doc        text not null default '' check (length(vevo_doc) <= 300),
  vevo_doc_name   text not null default '' check (length(vevo_doc_name) <= 200),
  updated_at      timestamptz not null default now(),
  updated_by      uuid references public.profiles (id),
  verified_at     timestamptz,
  verified_by     uuid references public.profiles (id),
  check (status <> 'visa' or visa_subclass <> '')
);

-- Which access area each table belongs to.
create or replace function public.record_area(p_table text)
returns text
language sql
immutable
security invoker
set search_path = ''
as $$
  select case p_table when 'staff_bank' then 'payroll_tax' when 'staff_super' then 'payroll_tax' when 'staff_work_rights' then 'identity_docs' end
$$;

-- The record of access: who did what to whose sensitive record, and when.
create table if not exists public.sensitive_access_log (
  id         bigint generated always as identity primary key,
  at         timestamptz not null default now(),
  actor_id   uuid default auth.uid() references public.profiles (id) on delete set null,
  subject_id uuid references public.profiles (id) on delete set null,
  area       text not null check (area in ('payroll_tax', 'identity_docs')),
  action     text not null check (action in ('view', 'reveal', 'download', 'upload', 'change', 'verify', 'refused')),
  detail     text not null default '' check (length(detail) <= 200)
);
create index if not exists sensitive_access_log_subject on public.sensitive_access_log (subject_id, at desc);

alter table public.staff_bank enable row level security;
alter table public.staff_super enable row level security;
alter table public.staff_work_rights enable row level security;
alter table public.sensitive_access_log enable row level security;
revoke all on public.staff_bank, public.staff_super, public.staff_work_rights, public.sensitive_access_log from anon;
revoke delete, truncate on public.staff_bank, public.staff_super, public.staff_work_rights from authenticated;
grant select, insert, update on public.staff_bank, public.staff_super, public.staff_work_rights to authenticated;
revoke update, delete, truncate on public.sensitive_access_log from authenticated;
grant select, insert on public.sensitive_access_log to authenticated;

do $$
declare
  t text;
begin
  foreach t in array array['staff_bank', 'staff_super', 'staff_work_rights'] loop
    execute format('drop policy if exists "the person and people with access" on public.%I', t);
    execute format($p$create policy "the person and people with access" on public.%I for all to authenticated
      using ((select public.is_member()) and (user_id = (select auth.uid()) or public.has_access(%L, user_id)))
      with check ((select public.is_member()) and (user_id = (select auth.uid()) or public.has_access(%L, user_id)))$p$,
      t, public.record_area(t), public.record_area(t));
  end loop;
end;
$$;

-- Log entries: written as yourself only; read by the system admin.
drop policy if exists "log your own actions" on public.sensitive_access_log;
create policy "log your own actions" on public.sensitive_access_log for insert to authenticated
  with check (actor_id = (select auth.uid()) and (select public.is_member()));
drop policy if exists "the system admin reads the access log" on public.sensitive_access_log;
create policy "the system admin reads the access log" on public.sensitive_access_log for select to authenticated
  using ((select public.is_system_admin()));

-- Every change: who and when is set here; a person's own change needs
-- checking again; only someone with access (never the person) verifies; and
-- the change goes in the access log. Runs as the person making the change.
create or replace function public.guard_staff_record()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_area text := public.record_area(tg_table_name);
  v_by uuid := auth.uid();
  v_checker boolean := v_by is not null and v_by <> new.user_id and public.has_access(v_area, new.user_id);
  v_verify boolean;
begin
  if v_by is null then
    return new; -- system jobs
  end if;
  v_verify := new.verified_at is not null and (tg_op = 'INSERT' or new.verified_at is distinct from old.verified_at);
  if v_verify and not v_checker then
    raise exception 'Only someone with access to this record (not the person themselves) can mark it checked.';
  end if;
  new.updated_at := now();
  new.updated_by := v_by;
  if v_verify then
    new.verified_at := now();
    new.verified_by := v_by;
  elsif tg_op = 'UPDATE' and (to_jsonb(new) - 'verified_at' - 'verified_by' - 'updated_at' - 'updated_by')
                         is distinct from (to_jsonb(old) - 'verified_at' - 'verified_by' - 'updated_at' - 'updated_by') then
    -- Any change to the details means it needs checking again.
    new.verified_at := null;
    new.verified_by := null;
  end if;
  insert into public.sensitive_access_log (actor_id, subject_id, area, action, detail)
  values (v_by, new.user_id, v_area, case when v_verify then 'verify' else 'change' end,
          case tg_table_name when 'staff_bank' then 'Bank details' when 'staff_super' then 'Super' else 'Work rights' end);
  return new;
end;
$$;

revoke execute on function public.guard_staff_record() from public, anon, authenticated;

do $$
declare
  t text;
begin
  foreach t in array array['staff_bank', 'staff_super', 'staff_work_rights'] loop
    execute format('drop trigger if exists guard_staff_record on public.%I', t);
    execute format('create trigger guard_staff_record before insert or update on public.%I for each row execute function public.guard_staff_record()', t);
  end loop;
end;
$$;

revoke execute on function public.record_area(text) from public, anon;
grant execute on function public.record_area(text) to authenticated;
revoke execute on function public.expiry_stage(date) from public, anon;
grant execute on function public.expiry_stage(date) to authenticated;

-- ---------------------------------------------------------------------------
-- 5. Private file store: <area>/<person id>/<file>
-- ---------------------------------------------------------------------------
do $$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values ('staff-records', 'staff-records', false, 10485760,
          array['application/pdf', 'image/jpeg', 'image/png', 'image/webp', 'application/msword',
                'application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
  on conflict (id) do nothing;

  drop policy if exists "staff records: the person and people with access read" on storage.objects;
  create policy "staff records: the person and people with access read" on storage.objects for select to authenticated
    using (bucket_id = 'staff-records' and (storage.foldername(name))[1] in ('payroll_tax', 'identity_docs')
           and ((storage.foldername(name))[2] = (select auth.uid())::text
                or public.has_access((storage.foldername(name))[1], ((storage.foldername(name))[2])::uuid)));
  drop policy if exists "staff records: the person and people with access upload" on storage.objects;
  create policy "staff records: the person and people with access upload" on storage.objects for insert to authenticated
    with check (bucket_id = 'staff-records' and (select public.is_member()) and (storage.foldername(name))[1] in ('payroll_tax', 'identity_docs')
           and ((storage.foldername(name))[2] = (select auth.uid())::text
                or public.has_access((storage.foldername(name))[1], ((storage.foldername(name))[2])::uuid)));
  -- No update or delete: a new copy is a new file, the old one stays.
end;
$$;

-- ---------------------------------------------------------------------------
-- 2 (continued). The daily reminders, in stages, plus visa expiry.
-- ---------------------------------------------------------------------------
create table if not exists public.work_rights_alerts (
  user_id    uuid not null references public.profiles (id) on delete cascade,
  expires_on date not null,
  step       text not null check (step in ('d60', 'd30', 'd7', 'today', 'expired')),
  sent_at    timestamptz not null default now(),
  primary key (user_id, expires_on, step)
);
alter table public.work_rights_alerts enable row level security;
revoke all on public.work_rights_alerts from anon, authenticated;

create or replace function public.run_compliance_alerts()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  s record;
  v_n int := 0;
  v_v int := 0;
  v_admin uuid;
  v_stage text;
  v_when text;
begin
  -- Documents and certificates: the latest record of each item that has an expiry date.
  for s in
    select p.id user_id, coalesce(nullif(p.full_name, ''), p.email) person, st.title, st.record_id, st.expires_on
      from public.profiles p
      cross join lateral public.compliance_status(p.id) st
     where p.active and p.role <> 'system_admin' and st.record_id is not null and st.expires_on is not null
       and st.expires_on <= public.local_today() + 60
  loop
    v_stage := public.expiry_stage(s.expires_on);
    continue when v_stage is null;
    insert into public.compliance_alerts (record_id, step) values (s.record_id, v_stage) on conflict do nothing;
    continue when not found;
    v_n := v_n + 1;
    v_when := case v_stage when 'expired' then 'has expired' when 'today' then 'expires today'
                           else format('expires in %s days', s.expires_on - public.local_today()) end;
    perform public.notify(s.user_id, case when v_stage = 'expired' then 'document_expired' else 'document_expiring' end,
      format('%s %s', s.title, v_when),
      format('Expiry date: %s. Upload a new copy on My onboarding.', to_char(s.expires_on, 'FMDD Mon YYYY')),
      '/onboarding', v_stage in ('expired', 'today', 'd7', 'd30'));
    for v_admin in select a from public.people_admins() a loop
      continue when v_admin = s.user_id;
      perform public.notify(v_admin, case when v_stage = 'expired' then 'document_expired' else 'document_expiring' end,
        format('%s: %s %s', s.person, s.title, v_when),
        format('Expiry date: %s.', to_char(s.expires_on, 'FMDD Mon YYYY')),
        '/compliance/expiry', v_stage in ('expired', 'today'));
    end loop;
  end loop;

  -- Visas: the person, and people with Identity and work rights access that covers them.
  for s in
    select w.user_id, coalesce(nullif(p.full_name, ''), p.email) person, w.visa_expiry expires_on
      from public.staff_work_rights w join public.profiles p on p.id = w.user_id
     where p.active and w.status = 'visa' and w.visa_expiry is not null and w.visa_expiry <= public.local_today() + 60
  loop
    v_stage := public.expiry_stage(s.expires_on);
    continue when v_stage is null;
    insert into public.work_rights_alerts (user_id, expires_on, step) values (s.user_id, s.expires_on, v_stage) on conflict do nothing;
    continue when not found;
    v_v := v_v + 1;
    v_when := case v_stage when 'expired' then 'has expired' when 'today' then 'expires today'
                           else format('expires in %s days', s.expires_on - public.local_today()) end;
    -- No visa details in the message: just that it needs attention.
    perform public.notify(s.user_id, case when v_stage = 'expired' then 'document_expired' else 'document_expiring' end,
      format('Your visa %s', v_when), 'Please update your work rights in My account.', '/account/records', true);
    for v_admin in
      select distinct g.user_id
        from public.access_grants g join public.profiles a on a.id = g.user_id
       where g.area = 'identity_docs' and g.revoked_at is null and (g.expires_at is null or g.expires_at > now())
         and a.active and a.role in ('manager', 'staff_admin') and g.user_id <> s.user_id
         and (g.scope = 'all' or (g.scope = 'people' and s.user_id = any (g.scope_ids))
              or (g.scope = 'teams' and exists (select 1 from public.team_members tm where tm.user_id = s.user_id and tm.team_id = any (g.scope_ids))))
    loop
      perform public.notify(v_admin, case when v_stage = 'expired' then 'document_expired' else 'document_expiring' end,
        format('%s: work rights %s', s.person, v_when), 'Open their record to check.', '/people?p=' || s.user_id, v_stage in ('expired', 'today'));
    end loop;
  end loop;
  return jsonb_build_object('document_alerts', v_n, 'visa_alerts', v_v);
end;
$$;

$m079$;
  insert into public.install_log (name) values ('20270106000001_staff_records.sql');
end;
$part$;

-- ====================================================================
-- 20270107000001_assistant_internet.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20270107000001_assistant_internet.sql') then
    return;
  end if;
  execute $m080$
-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects: the website Assistant can also search the whole internet.
-- For each audience (public, staff, managers) the system admin chooses:
--   documents       our documents only
--   web             listed websites only
--   both            our documents, then listed websites
--   docs_web        our documents, then the whole internet
--   docs_sites_web  our documents, then listed websites, then the whole internet
--   sites_web       listed websites, then the whole internet
--   internet        the whole internet only
-- Plus websites it must never use when searching the whole internet.

alter table public.assistant_settings add column if not exists blocked_sites text[] not null default '{}';

do $$
declare
  c text;
begin
  for c in
    select conname from pg_constraint
     where conrelid = 'public.assistant_settings'::regclass and contype = 'c'
       and pg_get_constraintdef(oid) like '%scope_public%'
  loop
    execute format('alter table public.assistant_settings drop constraint %I', c);
  end loop;
end;
$$;

alter table public.assistant_settings add constraint assistant_settings_scope_check check (
  scope_public in ('documents', 'web', 'both', 'docs_web', 'docs_sites_web', 'sites_web', 'internet')
  and scope_staff in ('documents', 'web', 'both', 'docs_web', 'docs_sites_web', 'sites_web', 'internet')
  and scope_managers in ('documents', 'web', 'both', 'docs_web', 'docs_sites_web', 'sites_web', 'internet')
  and cardinality(trusted_sites) <= 30
  and cardinality(suggestions) <= 8
  and cardinality(blocked_sites) <= 30
);

$m080$;
  insert into public.install_log (name) values ('20270107000001_assistant_internet.sql');
end;
$part$;

-- ====================================================================
-- 20270108000001_contracts.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20270108000001_contracts.sql') then
    return;
  end if;
  execute $m081$
-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects Phase 4: agreements, policies and employment contracts.
--   1. Policies and agreements can go to specific people (as well as roles,
--      teams and positions), and every earlier version's wording is kept.
--   2. Employment contracts: one per person per version, with statuses
--      Draft → Awaiting employee signature → Awaiting employer signature →
--      Fully signed, or Cancelled / Expired / Superseded. A revised contract is
--      a new contract (new version) with a new signing process; the old one is
--      never changed and is marked Superseded once the new one is signed.
--   3. Signatures: the signer, typed name, drawn signature, consent wording,
--      how their identity was re-checked, IP, device, time (server), and the
--      SHA-256 of the exact wording signed. Never changed or deleted.
--   4. The final signed PDF (with an audit page) and its SHA-256 are stored
--      in a private 'contracts' store; signed contracts can't be changed.
--   Who prepares, sends and countersigns: people with Staff details access
--   covering the employee (or the system admin), never the employee.
-- No new SECURITY DEFINER function. compliance_status_all, the item
-- announcement trigger and run_compliance_alerts (existing) are updated.

-- ---------------------------------------------------------------------------
-- 1. Specific people, and version history
-- ---------------------------------------------------------------------------
alter table public.compliance_items add column if not exists applies_people uuid[] not null default '{}';

create or replace function public.compliance_status_all(p_user uuid, p_role app_role DEFAULT NULL::app_role, p_teams uuid[] DEFAULT NULL::uuid[])
 RETURNS TABLE(item_id uuid, kind text, title text, state text, record_id bigint, expires_on date, note text, sort_order integer, before_work boolean, category text, needs_check boolean)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_role public.app_role;
  v_title uuid;
  v_teams uuid[];
  v_warn int := coalesce((select (value #>> '{}')::int from public.app_settings where key = 'compliance.expiry_warning_days'), 30);
  v_today date := public.local_today();
begin
  select coalesce(p_role, p.role), p.job_title_id into v_role, v_title from public.profiles p where p.id = p_user;
  v_teams := coalesce(p_teams, (select array_agg(team_id) from public.team_members where user_id = p_user), '{}');

  return query
  select i.id, i.kind, i.title,
         case
           when r.id is null then 'todo'
           -- Policies, agreements and forms: done for the current version.
           when i.kind in ('read', 'agreement', 'form') then case when r.version >= i.version then 'done' else 'update' end
           when r.status in ('rejected', 'replace_requested') then r.status
           when r.expires_on is not null and r.expires_on < v_today then 'expired'
           when r.expires_on is not null and r.expires_on <= v_today + v_warn then 'expiring'
           when i.kind = 'training' and r.status = 'done' and r.version < i.version then 'update'
           else r.status
         end,
         r.id, r.expires_on, coalesce(r.review_note, ''), i.sort_order,
         i.before_work, i.category,
         -- Has a file someone must check (uploads, and trainings with a certificate).
         (i.kind = 'upload' or (i.kind = 'training' and r.file_path is not null) or (i.kind = 'training' and (i.certificate = 'required' or i.before_work)))
    from public.compliance_items i
    left join lateral (
      select * from public.compliance_records cr
       where cr.item_id = i.id and cr.user_id = p_user
       order by cr.created_at desc, cr.id desc limit 1
    ) r on true
   where public.compliance_applies(i, v_role, v_teams, v_title)
     -- cmeprojects Phase 4: or only the chosen people.
     and (cardinality(i.applies_people) = 0 or p_user = any (i.applies_people))
   order by array_position(array['read', 'training', 'upload', 'agreement', 'form'], i.kind), i.sort_order, i.title;
end;
$function$;

create or replace function public.compliance_item_announce()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  p record;
  v_word text := case new.kind when 'read' then 'Please read and confirm' when 'training' then 'New training' when 'form' then 'Please fill in' else 'Please upload' end;
begin
  if not new.active then
    return new;
  end if;
  if tg_op = 'UPDATE' and new.version = old.version and old.active then
    return new;
  end if;
  for p in
    select pr.id, pr.role, (select array_agg(team_id) from public.team_members where user_id = pr.id) teams
      from public.profiles pr
     where pr.active and pr.role <> 'system_admin'
  loop
    if public.compliance_applies(new, p.role, p.teams)
       and (cardinality(new.applies_people) = 0 or p.id = any (new.applies_people)) then
      perform public.notify(p.id, 'onboarding_item',
        case when tg_op = 'UPDATE' and new.version > old.version then format('Updated: %s', new.title) else format('%s: %s', v_word, new.title) end,
        case when new.kind = 'form' then 'A form to fill in. It''s also on your My onboarding page.' else 'It''s on your My onboarding page.' end,
        case when new.kind = 'form' and new.form_id is not null then '/forms/' || new.form_id else '/onboarding' end);
    end if;
  end loop;
  return new;
end;
$function$;


create table if not exists public.compliance_item_versions (
  id           bigint generated always as identity primary key,
  item_id      uuid not null references public.compliance_items (id) on delete cascade,
  version      int not null,
  title        text not null,
  body         text not null default '',
  link_url     text,
  content_hash text not null,
  saved_at     timestamptz not null default now(),
  saved_by     uuid references public.profiles (id) on delete set null,
  unique (item_id, version)
);
alter table public.compliance_item_versions enable row level security;
revoke all on public.compliance_item_versions from anon;
revoke update, delete, truncate on public.compliance_item_versions from authenticated;
grant select, insert on public.compliance_item_versions to authenticated;
drop policy if exists "members read earlier versions" on public.compliance_item_versions;
create policy "members read earlier versions" on public.compliance_item_versions for select to authenticated
  using ((select public.is_member()));
drop policy if exists "compliance managers keep versions" on public.compliance_item_versions;
create policy "compliance managers keep versions" on public.compliance_item_versions for insert to authenticated
  with check ((select public.can_manage_compliance()) or (select public.is_system_admin()));

-- Each version's wording is kept as it was when that version went out.
create or replace function public.keep_item_version()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.kind in ('read', 'agreement') and (tg_op = 'INSERT' or new.version is distinct from old.version or new.body is distinct from old.body) then
    insert into public.compliance_item_versions (item_id, version, title, body, link_url, content_hash, saved_by)
    values (new.id, new.version, new.title, coalesce(new.body, ''), new.link_url,
            encode(sha256(convert_to(new.title || E'\n' || coalesce(new.body, ''), 'UTF8')), 'hex'), auth.uid())
    on conflict (item_id, version) do nothing;
  end if;
  return null;
end;
$$;
revoke execute on function public.keep_item_version() from public, anon, authenticated;
drop trigger if exists keep_item_version on public.compliance_items;
create trigger keep_item_version after insert or update on public.compliance_items
  for each row execute function public.keep_item_version();
-- The current wording of existing policies and agreements, once.
insert into public.compliance_item_versions (item_id, version, title, body, link_url, content_hash)
select i.id, i.version, i.title, coalesce(i.body, ''), i.link_url, encode(sha256(convert_to(i.title || E'\n' || coalesce(i.body, ''), 'UTF8')), 'hex')
  from public.compliance_items i
 where i.kind in ('read', 'agreement')
on conflict (item_id, version) do nothing;

-- ---------------------------------------------------------------------------
-- 2. Employment contracts
-- ---------------------------------------------------------------------------
create table if not exists public.contracts (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references public.profiles (id) on delete cascade,
  title           text not null check (length(title) between 2 and 200),
  body            text not null default '' check (length(body) <= 100000),
  version         int not null default 1 check (version >= 1),
  supersedes      uuid references public.contracts (id),
  status          text not null default 'draft'
                  check (status in ('draft', 'awaiting_employee', 'awaiting_employer', 'fully_signed', 'cancelled', 'expired', 'superseded')),
  sign_by         date,
  content_hash    text not null default '',
  sent_at         timestamptz,
  sent_by         uuid references public.profiles (id) on delete set null,
  signed_pdf_path text not null default '',
  signed_pdf_hash text not null default '',
  completed_at    timestamptz,
  created_by      uuid default auth.uid() references public.profiles (id) on delete set null,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index if not exists contracts_user on public.contracts (user_id, created_at desc);

create table if not exists public.contract_signatures (
  id             bigint generated always as identity primary key,
  contract_id    uuid not null references public.contracts (id) on delete cascade,
  party          text not null check (party in ('employee', 'employer')),
  signer_id      uuid not null default auth.uid() references public.profiles (id),
  signed_name    text not null check (length(trim(signed_name)) between 2 and 120),
  signature_path text not null check (length(signature_path) between 1 and 300),
  consent_text   text not null check (length(consent_text) between 10 and 1000),
  content_hash   text not null,
  identity_check text not null check (identity_check in ('password', 'authenticator')),
  ip             text not null default '' check (length(ip) <= 64),
  user_agent     text not null default '' check (length(user_agent) <= 300),
  signed_at      timestamptz not null default now(),
  unique (contract_id, party)
);

alter table public.contracts enable row level security;
alter table public.contract_signatures enable row level security;
revoke all on public.contracts, public.contract_signatures from anon;
revoke truncate on public.contracts from authenticated;
revoke update, delete, truncate on public.contract_signatures from authenticated;
grant select, insert, update, delete on public.contracts to authenticated;
grant select, insert on public.contract_signatures to authenticated;

-- The employee sees their own (not drafts); people with Staff details access covering them see all.
drop policy if exists "contracts: the employee and people with access" on public.contracts;
create policy "contracts: the employee and people with access" on public.contracts for select to authenticated
  using ((select public.is_member()) and ((user_id = (select auth.uid()) and status <> 'draft') or public.has_access('staff_details', user_id)));
drop policy if exists "contracts: people with access prepare them" on public.contracts;
create policy "contracts: people with access prepare them" on public.contracts for insert to authenticated
  with check ((select public.is_member()) and status = 'draft' and user_id <> (select auth.uid()) and public.has_access('staff_details', user_id));
drop policy if exists "contracts: people with access, or the employee signing" on public.contracts;
create policy "contracts: people with access, or the employee signing" on public.contracts for update to authenticated
  using ((select public.is_member()) and ((user_id <> (select auth.uid()) and public.has_access('staff_details', user_id)) or (user_id = (select auth.uid()) and status = 'awaiting_employee')))
  with check ((select public.is_member()) and ((user_id <> (select auth.uid()) and public.has_access('staff_details', user_id)) or user_id = (select auth.uid())));
drop policy if exists "contracts: drafts can be deleted" on public.contracts;
create policy "contracts: drafts can be deleted" on public.contracts for delete to authenticated
  using (status = 'draft' and user_id <> (select auth.uid()) and public.has_access('staff_details', user_id));

drop policy if exists "signatures follow their contract" on public.contract_signatures;
create policy "signatures follow their contract" on public.contract_signatures for select to authenticated
  using (exists (select 1 from public.contracts c where c.id = contract_id));
drop policy if exists "sign as yourself, at the right step" on public.contract_signatures;
create policy "sign as yourself, at the right step" on public.contract_signatures for insert to authenticated
  with check (
    signer_id = (select auth.uid()) and (select public.is_member())
    and exists (
      select 1 from public.contracts c
       where c.id = contract_id and c.content_hash = contract_signatures.content_hash
         and ((party = 'employee' and c.user_id = (select auth.uid()) and c.status = 'awaiting_employee'
               and (c.sign_by is null or c.sign_by >= public.local_today()))
              or (party = 'employer' and c.user_id <> (select auth.uid()) and c.status = 'awaiting_employer'
                  and public.has_access('staff_details', c.user_id)))));

-- What can change, and when. Runs as the person making the change.
create or replace function public.guard_contract()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_by uuid := auth.uid();
  v_holder boolean;
begin
  if tg_op = 'INSERT' then
    new.status := 'draft';
    new.created_by := v_by;
    new.content_hash := '';
    new.signed_pdf_path := '';
    new.signed_pdf_hash := '';
    new.sent_at := null;
    new.sent_by := null;
    new.completed_at := null;
    if new.supersedes is not null then
      if not exists (select 1 from public.contracts o where o.id = new.supersedes and o.user_id = new.user_id) then
        raise exception 'A new version must be for the same person.';
      end if;
      new.version := (select max(version) + 1 from public.contracts where id = new.supersedes or supersedes = new.supersedes);
    else
      new.version := 1;
    end if;
    return new;
  end if;

  new.updated_at := now();
  if v_by is null then
    return new; -- the daily job (expiring unsigned contracts)
  end if;
  v_holder := new.user_id <> v_by and public.has_access('staff_details', new.user_id);

  -- Once sent, the wording and who it's for never change.
  if old.status <> 'draft' and (new.title is distinct from old.title or new.body is distinct from old.body or new.user_id is distinct from old.user_id
      or new.version is distinct from old.version or new.supersedes is distinct from old.supersedes or new.content_hash is distinct from old.content_hash
      or new.sign_by is distinct from old.sign_by) then
    raise exception 'A sent contract can''t be changed. Make a new version instead.';
  end if;
  if new.signed_pdf_path is distinct from old.signed_pdf_path or new.signed_pdf_hash is distinct from old.signed_pdf_hash then
    if not (old.status = 'awaiting_employer' and new.status = 'fully_signed' and v_holder and old.signed_pdf_path = '') then
      raise exception 'The signed copy can only be added when the contract is fully signed.';
    end if;
  end if;

  if new.status is distinct from old.status then
    if old.status = 'draft' and new.status = 'awaiting_employee' and v_holder then
      new.content_hash := encode(sha256(convert_to(new.title || E'\n' || new.body, 'UTF8')), 'hex');
      new.sent_at := now();
      new.sent_by := v_by;
    elsif old.status in ('draft', 'awaiting_employee', 'awaiting_employer') and new.status = 'cancelled' and v_holder then
      null;
    elsif old.status = 'awaiting_employee' and new.status = 'expired' and v_holder and new.sign_by < public.local_today() then
      null;
    elsif old.status = 'awaiting_employee' and new.status = 'awaiting_employer'
          and exists (select 1 from public.contract_signatures s where s.contract_id = new.id and s.party = 'employee' and s.content_hash = new.content_hash) then
      null;
    elsif old.status = 'awaiting_employer' and new.status = 'fully_signed' and v_holder
          and new.signed_pdf_path <> '' and new.signed_pdf_hash ~ '^[0-9a-f]{64}$'
          and exists (select 1 from public.contract_signatures s where s.contract_id = new.id and s.party = 'employer' and s.content_hash = new.content_hash) then
      new.completed_at := now();
    elsif old.status = 'fully_signed' and new.status = 'superseded' and v_holder
          and exists (select 1 from public.contracts n where n.supersedes = new.id and n.status = 'fully_signed') then
      null;
    else
      raise exception 'That step isn''t allowed for this contract right now.';
    end if;
  elsif old.status <> 'draft' and (to_jsonb(new) - 'updated_at') is distinct from (to_jsonb(old) - 'updated_at') then
    raise exception 'A sent contract can''t be changed. Make a new version instead.';
  end if;
  if old.status = 'draft' and not v_holder then
    raise exception 'You don''t have access to prepare contracts for this person.';
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_contract() from public, anon, authenticated;
drop trigger if exists guard_contract on public.contracts;
create trigger guard_contract before insert or update on public.contracts
  for each row execute function public.guard_contract();

-- When a new version is fully signed, the one it replaces is marked superseded.
create or replace function public.contract_supersede()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.status = 'fully_signed' and old.status <> 'fully_signed' and new.supersedes is not null then
    update public.contracts set status = 'superseded'
     where id = new.supersedes and status = 'fully_signed';
    update public.contracts set status = 'cancelled'
     where id = new.supersedes and status in ('draft', 'awaiting_employee', 'awaiting_employer');
  end if;
  return null;
end;
$$;
revoke execute on function public.contract_supersede() from public, anon, authenticated;
drop trigger if exists contract_supersede on public.contracts;
create trigger contract_supersede after update of status on public.contracts
  for each row execute function public.contract_supersede();

-- The employee signing moves it on to the employer.
create or replace function public.contract_signed()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.party = 'employee' then
    update public.contracts set status = 'awaiting_employer' where id = new.contract_id and status = 'awaiting_employee';
  end if;
  return null;
end;
$$;
revoke execute on function public.contract_signed() from public, anon, authenticated;
drop trigger if exists contract_signed on public.contract_signatures;
create trigger contract_signed after insert on public.contract_signatures
  for each row execute function public.contract_signed();

-- ---------------------------------------------------------------------------
-- 4. Private store for signatures and signed copies: <person>/<contract>/<file>
-- ---------------------------------------------------------------------------
do $$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values ('contracts', 'contracts', false, 10485760, array['application/pdf', 'image/png'])
  on conflict (id) do nothing;
  drop policy if exists "contracts: the employee and people with access read" on storage.objects;
  create policy "contracts: the employee and people with access read" on storage.objects for select to authenticated
    using (bucket_id = 'contracts' and ((storage.foldername(name))[1] = (select auth.uid())::text
           or public.has_access('staff_details', ((storage.foldername(name))[1])::uuid)));
  drop policy if exists "contracts: the employee and people with access add files" on storage.objects;
  create policy "contracts: the employee and people with access add files" on storage.objects for insert to authenticated
    with check (bucket_id = 'contracts' and (select public.is_member()) and ((storage.foldername(name))[1] = (select auth.uid())::text
           or public.has_access('staff_details', ((storage.foldername(name))[1])::uuid)));
  -- No update or delete: signed files never change.
end;
$$;

-- ---------------------------------------------------------------------------
-- The daily job also expires contracts not signed by their date.
-- ---------------------------------------------------------------------------
create or replace function public.run_compliance_alerts()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  s record;
  v_n int := 0;
  v_v int := 0;
  v_admin uuid;
  v_stage text;
  v_when text;
begin
  -- cmeprojects Phase 4: contracts not signed by their "sign by" date expire.
  update public.contracts set status = 'expired'
   where status = 'awaiting_employee' and sign_by is not null and sign_by < public.local_today();
  -- Documents and certificates: the latest record of each item that has an expiry date.
  for s in
    select p.id user_id, coalesce(nullif(p.full_name, ''), p.email) person, st.title, st.record_id, st.expires_on
      from public.profiles p
      cross join lateral public.compliance_status(p.id) st
     where p.active and p.role <> 'system_admin' and st.record_id is not null and st.expires_on is not null
       and st.expires_on <= public.local_today() + 60
  loop
    v_stage := public.expiry_stage(s.expires_on);
    continue when v_stage is null;
    insert into public.compliance_alerts (record_id, step) values (s.record_id, v_stage) on conflict do nothing;
    continue when not found;
    v_n := v_n + 1;
    v_when := case v_stage when 'expired' then 'has expired' when 'today' then 'expires today'
                           else format('expires in %s days', s.expires_on - public.local_today()) end;
    perform public.notify(s.user_id, case when v_stage = 'expired' then 'document_expired' else 'document_expiring' end,
      format('%s %s', s.title, v_when),
      format('Expiry date: %s. Upload a new copy on My onboarding.', to_char(s.expires_on, 'FMDD Mon YYYY')),
      '/onboarding', v_stage in ('expired', 'today', 'd7', 'd30'));
    for v_admin in select a from public.people_admins() a loop
      continue when v_admin = s.user_id;
      perform public.notify(v_admin, case when v_stage = 'expired' then 'document_expired' else 'document_expiring' end,
        format('%s: %s %s', s.person, s.title, v_when),
        format('Expiry date: %s.', to_char(s.expires_on, 'FMDD Mon YYYY')),
        '/compliance/expiry', v_stage in ('expired', 'today'));
    end loop;
  end loop;

  -- Visas: the person, and people with Identity and work rights access that covers them.
  for s in
    select w.user_id, coalesce(nullif(p.full_name, ''), p.email) person, w.visa_expiry expires_on
      from public.staff_work_rights w join public.profiles p on p.id = w.user_id
     where p.active and w.status = 'visa' and w.visa_expiry is not null and w.visa_expiry <= public.local_today() + 60
  loop
    v_stage := public.expiry_stage(s.expires_on);
    continue when v_stage is null;
    insert into public.work_rights_alerts (user_id, expires_on, step) values (s.user_id, s.expires_on, v_stage) on conflict do nothing;
    continue when not found;
    v_v := v_v + 1;
    v_when := case v_stage when 'expired' then 'has expired' when 'today' then 'expires today'
                           else format('expires in %s days', s.expires_on - public.local_today()) end;
    -- No visa details in the message: just that it needs attention.
    perform public.notify(s.user_id, case when v_stage = 'expired' then 'document_expired' else 'document_expiring' end,
      format('Your visa %s', v_when), 'Please update your work rights in My account.', '/account/records', true);
    for v_admin in
      select distinct g.user_id
        from public.access_grants g join public.profiles a on a.id = g.user_id
       where g.area = 'identity_docs' and g.revoked_at is null and (g.expires_at is null or g.expires_at > now())
         and a.active and a.role in ('manager', 'staff_admin') and g.user_id <> s.user_id
         and (g.scope = 'all' or (g.scope = 'people' and s.user_id = any (g.scope_ids))
              or (g.scope = 'teams' and exists (select 1 from public.team_members tm where tm.user_id = s.user_id and tm.team_id = any (g.scope_ids))))
    loop
      perform public.notify(v_admin, case when v_stage = 'expired' then 'document_expired' else 'document_expiring' end,
        format('%s: work rights %s', s.person, v_when), 'Open their record to check.', '/people?p=' || s.user_id, v_stage in ('expired', 'today'));
    end loop;
  end loop;
  return jsonb_build_object('document_alerts', v_n, 'visa_alerts', v_v);
end;
$$;

$m081$;
  insert into public.install_log (name) values ('20270108000001_contracts.sql');
end;
$part$;

-- ====================================================================
-- 20270109000001_celebrations.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20270109000001_celebrations.sql') then
    return;
  end if;
  execute $m082$
-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects Phase 5: birthdays and work anniversaries.
--   * Birthdays: day and month only (the year is never asked or stored, so no
--     age can be shown or worked out). Shown to colleagues only when the person
--     chooses "Show my birthday" (off by default); they can change it any time.
--   * Only active staff appear.
--   * Work anniversaries use the commencement date (staff_private.start_date),
--     which keeps its existing privacy: the person and people who manage
--     staff see it. No change there.
-- No new SECURITY DEFINER function.

create table if not exists public.staff_birthdays (
  user_id   uuid primary key references public.profiles (id) on delete cascade,
  month     int not null check (month between 1 and 12),
  day       int not null check (day between 1 and 31),
  show      boolean not null default false,
  updated_at timestamptz not null default now(),
  check ((month, day) not in ((2, 30), (2, 31), (4, 31), (6, 31), (9, 31), (11, 31)))
);
alter table public.staff_birthdays enable row level security;
revoke all on public.staff_birthdays from anon;
revoke truncate on public.staff_birthdays from authenticated;
grant select, insert, update, delete on public.staff_birthdays to authenticated;

-- Your own always; colleagues' only when shown and they're active.
drop policy if exists "birthdays: your own, or shown by active colleagues" on public.staff_birthdays;
create policy "birthdays: your own, or shown by active colleagues" on public.staff_birthdays for select to authenticated
  using ((select public.is_member()) and (user_id = (select auth.uid())
         or (show and exists (select 1 from public.profiles p where p.id = staff_birthdays.user_id and p.active))));
drop policy if exists "birthdays: only your own" on public.staff_birthdays;
create policy "birthdays: only your own" on public.staff_birthdays for all to authenticated
  using (user_id = (select auth.uid()) and (select public.is_member()))
  with check (user_id = (select auth.uid()) and (select public.is_member()));

$m082$;
  insert into public.install_log (name) values ('20270109000001_celebrations.sql');
end;
$part$;

-- ====================================================================
-- 20270110000001_contract_letterhead.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20270110000001_contract_letterhead.sql') then
    return;
  end if;
  execute $m083$
-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects: each contract can carry the company logo and letterhead on
-- every page of the signed copy (on by default; chosen while it's a draft).
alter table public.contracts add column if not exists letterhead boolean not null default true;

$m083$;
  insert into public.install_log (name) values ('20270110000001_contract_letterhead.sql');
end;
$part$;

-- ====================================================================
-- 20270111000001_tfn_records.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20270111000001_tfn_records.sql') then
    return;
  end if;
  execute $m084$
-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects: tax file number declaration and record keeping (owner's
-- answers, 12 Nov 2026).
--   * No TFN number is stored. Staff upload their completed TFN declaration
--     form in onboarding; a staff admin or manager sends it to the ATO
--     themselves and records the date it was sent.
--   * Only the system admin and people with Payroll and tax access that
--     includes "can reveal TFN" (covering that person) can open it. Every
--     open, change and deletion is logged.
--   * A blank TFN declaration form can be uploaded by the system admin for
--     staff to download.
--   * Keeping records: "Keep private records for N years after someone
--     leaves" (5 by default, changeable); the system admin sees whose records
--     are past it and deletes them by hand (also any single TFN form).
-- No new SECURITY DEFINER function.

-- Who may open TFN declarations for this person.
create or replace function public.has_tfn_access(p_person uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select public.mfa_ok() and (
    public.is_system_admin()
    or (public.has_access('payroll_tax', p_person) and exists (
          select 1 from public.access_grants g
           where g.user_id = auth.uid() and g.area = 'payroll_tax' and g.can_reveal_tfn
             and g.revoked_at is null and (g.expires_at is null or g.expires_at > now())))
  )
$$;
revoke execute on function public.has_tfn_access(uuid) from public, anon;
grant execute on function public.has_tfn_access(uuid) to authenticated;

create table if not exists public.staff_tax (
  user_id      uuid primary key references public.profiles (id) on delete cascade,
  form_path    text not null default '' check (length(form_path) <= 300),
  form_name    text not null default '' check (length(form_name) <= 200),
  uploaded_at  timestamptz,
  lodged_on    date,
  lodged_by    uuid references public.profiles (id) on delete set null,
  updated_at   timestamptz not null default now(),
  updated_by   uuid references public.profiles (id) on delete set null,
  verified_at  timestamptz,
  verified_by  uuid references public.profiles (id) on delete set null
);
alter table public.staff_tax enable row level security;
revoke all on public.staff_tax from anon;
revoke truncate on public.staff_tax from authenticated;
grant select, insert, update, delete on public.staff_tax to authenticated;

drop policy if exists "tax: the person and people allowed to open TFN forms" on public.staff_tax;
create policy "tax: the person and people allowed to open TFN forms" on public.staff_tax for select to authenticated
  using ((select public.is_member()) and (user_id = (select auth.uid()) or public.has_tfn_access(user_id)));
drop policy if exists "tax: the person uploads theirs" on public.staff_tax;
create policy "tax: the person uploads theirs" on public.staff_tax for insert to authenticated
  with check ((select public.is_member()) and (user_id = (select auth.uid()) or public.has_tfn_access(user_id)));
drop policy if exists "tax: the person or people allowed" on public.staff_tax;
create policy "tax: the person or people allowed" on public.staff_tax for update to authenticated
  using ((select public.is_member()) and (user_id = (select auth.uid()) or public.has_tfn_access(user_id)))
  with check ((select public.is_member()) and (user_id = (select auth.uid()) or public.has_tfn_access(user_id)));
drop policy if exists "tax: people allowed delete" on public.staff_tax;
create policy "tax: people allowed delete" on public.staff_tax for delete to authenticated
  using (user_id <> (select auth.uid()) and public.has_tfn_access(user_id));

-- Log actions now include deleting records.
alter table public.sensitive_access_log drop constraint if exists sensitive_access_log_action_check;
alter table public.sensitive_access_log add constraint sensitive_access_log_action_check
  check (action in ('view', 'reveal', 'download', 'upload', 'change', 'verify', 'refused', 'delete', 'lodged'));

-- Checks on every change: who and when; only allowed people check it or
-- record that it was sent to the ATO (never the person themselves); a new
-- upload clears both; logged.
create or replace function public.guard_staff_tax()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_by uuid := auth.uid();
  v_checker boolean;
begin
  if v_by is null then
    return coalesce(new, old);
  end if;
  if tg_op = 'DELETE' then
    insert into public.sensitive_access_log (actor_id, subject_id, area, action, detail) values (v_by, old.user_id, 'payroll_tax', 'delete', 'TFN declaration');
    return old;
  end if;
  v_checker := v_by <> new.user_id and public.has_tfn_access(new.user_id);
  if (tg_op = 'INSERT' and (new.verified_at is not null or new.lodged_on is not null))
     or (tg_op = 'UPDATE' and (new.verified_at is distinct from old.verified_at or new.lodged_on is distinct from old.lodged_on)) then
    if not v_checker and (new.verified_at is not null or new.lodged_on is not null) then
      raise exception 'Only the person handling payroll (not the staff member) can mark this checked or sent to the ATO.';
    end if;
  end if;
  new.updated_at := now();
  new.updated_by := v_by;
  if tg_op = 'INSERT' or new.form_path is distinct from old.form_path then
    new.uploaded_at := now();
    if tg_op = 'UPDATE' then
      new.verified_at := null; new.verified_by := null; new.lodged_on := null; new.lodged_by := null;
    end if;
    insert into public.sensitive_access_log (actor_id, subject_id, area, action, detail) values (v_by, new.user_id, 'payroll_tax', 'upload', 'TFN declaration');
  end if;
  if new.verified_at is not null and (tg_op = 'INSERT' or old.verified_at is null) then
    new.verified_at := now(); new.verified_by := v_by;
    insert into public.sensitive_access_log (actor_id, subject_id, area, action, detail) values (v_by, new.user_id, 'payroll_tax', 'verify', 'TFN declaration');
  end if;
  if new.lodged_on is not null and (tg_op = 'INSERT' or old.lodged_on is distinct from new.lodged_on) then
    new.lodged_by := v_by;
    insert into public.sensitive_access_log (actor_id, subject_id, area, action, detail) values (v_by, new.user_id, 'payroll_tax', 'lodged', format('TFN declaration sent to the ATO on %s', new.lodged_on));
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_staff_tax() from public, anon, authenticated;
drop trigger if exists guard_staff_tax on public.staff_tax;
create trigger guard_staff_tax before insert or update or delete on public.staff_tax
  for each row execute function public.guard_staff_tax();

-- Does the signed-in person hold live access of this kind (any scope)?
create or replace function public.holds_area(p_area text)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select public.is_system_admin() or exists (
    select 1 from public.access_grants g join public.profiles me on me.id = g.user_id
     where g.user_id = auth.uid() and g.area = p_area and g.revoked_at is null
       and (g.expires_at is null or g.expires_at > now()) and me.active and me.role in ('manager', 'staff_admin'))
$$;
revoke execute on function public.holds_area(text) from public, anon;
grant execute on function public.holds_area(text) to authenticated;

-- ---------------------------------------------------------------------------
-- Files: tax/<person>/... for TFN forms (TFN access only); templates/ for the
-- blank form (everyone reads, the system admin adds). People allowed delete
-- (manual deletion and the retention clean-up).
-- ---------------------------------------------------------------------------
do $$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  drop policy if exists "staff records: the person and people with access read" on storage.objects;
  create policy "staff records: the person and people with access read" on storage.objects for select to authenticated
    using (bucket_id = 'staff-records' and (
      ((storage.foldername(name))[1] in ('payroll_tax', 'identity_docs')
       and ((storage.foldername(name))[2] = (select auth.uid())::text
            or public.has_access((storage.foldername(name))[1], ((storage.foldername(name))[2])::uuid)))
      or ((storage.foldername(name))[1] = 'tax'
          and ((storage.foldername(name))[2] = (select auth.uid())::text or public.has_tfn_access(((storage.foldername(name))[2])::uuid)))
      or ((storage.foldername(name))[1] = 'templates' and (select public.is_member()))));
  drop policy if exists "staff records: the person and people with access upload" on storage.objects;
  create policy "staff records: the person and people with access upload" on storage.objects for insert to authenticated
    with check (bucket_id = 'staff-records' and (select public.is_member()) and (
      ((storage.foldername(name))[1] in ('payroll_tax', 'identity_docs')
       and ((storage.foldername(name))[2] = (select auth.uid())::text
            or public.has_access((storage.foldername(name))[1], ((storage.foldername(name))[2])::uuid)))
      or ((storage.foldername(name))[1] = 'tax'
          and ((storage.foldername(name))[2] = (select auth.uid())::text or public.has_tfn_access(((storage.foldername(name))[2])::uuid)))
      or ((storage.foldername(name))[1] = 'templates' and ((select public.is_system_admin()) or (select public.holds_area('payroll_tax'))))));
  drop policy if exists "staff records: deleted by people allowed" on storage.objects;
  create policy "staff records: deleted by people allowed" on storage.objects for delete to authenticated
    using (bucket_id = 'staff-records' and (
      (select public.is_system_admin())
      or ((storage.foldername(name))[1] = 'tax' and (storage.foldername(name))[2] <> (select auth.uid())::text
          and public.has_tfn_access(((storage.foldername(name))[2])::uuid))));
end;
$$;

-- ---------------------------------------------------------------------------
-- Keeping records
-- ---------------------------------------------------------------------------
insert into public.app_settings (key, value, label, description, is_public)
values ('records.private_retention_years', '5', 'Keep private staff records after someone leaves (years)',
        'Bank, super, work rights and TFN declarations of people who have left are listed for deletion after this many years. The system admin deletes them.', false)
on conflict (key) do nothing;
insert into public.app_settings (key, value, label, description, is_public)
values ('records.tfn_template', '""', 'Blank TFN declaration form', 'Where the blank form staff can download is stored. Set by the system admin, or a manager or staff admin with Payroll and tax access.', false)
on conflict (key) do nothing;

-- The system admin can delete a leaver's other private records (bank, super,
-- work rights). The Phase 3 rule covered every action; it's split so that
-- people with access read, add and change, and only the system admin deletes.
grant delete on public.staff_bank, public.staff_super, public.staff_work_rights to authenticated;
do $$
declare
  t text;
begin
  foreach t in array array['staff_bank', 'staff_super', 'staff_work_rights'] loop
    execute format('drop policy if exists "the person and people with access" on public.%I', t);
    execute format('drop policy if exists "records: the person and people with access read" on public.%I', t);
    execute format($p$create policy "records: the person and people with access read" on public.%I for select to authenticated
      using ((select public.is_member()) and (user_id = (select auth.uid()) or public.has_access(%L, user_id)))$p$, t, public.record_area(t));
    execute format('drop policy if exists "records: the person and people with access add" on public.%I', t);
    execute format($p$create policy "records: the person and people with access add" on public.%I for insert to authenticated
      with check ((select public.is_member()) and (user_id = (select auth.uid()) or public.has_access(%L, user_id)))$p$, t, public.record_area(t));
    execute format('drop policy if exists "records: the person and people with access change" on public.%I', t);
    execute format($p$create policy "records: the person and people with access change" on public.%I for update to authenticated
      using ((select public.is_member()) and (user_id = (select auth.uid()) or public.has_access(%L, user_id)))
      with check ((select public.is_member()) and (user_id = (select auth.uid()) or public.has_access(%L, user_id)))$p$, t, public.record_area(t), public.record_area(t));
    execute format('drop policy if exists "the system admin deletes records" on public.%I', t);
    execute format('create policy "the system admin deletes records" on public.%I for delete to authenticated using ((select public.is_system_admin()) and user_id <> (select auth.uid()))', t);
  end loop;
end;
$$;

-- Log each deletion of those too.
create or replace function public.log_record_deleted()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if auth.uid() is not null then
    insert into public.sensitive_access_log (actor_id, subject_id, area, action, detail)
    values (auth.uid(), old.user_id, public.record_area(tg_table_name), 'delete',
            case tg_table_name when 'staff_bank' then 'Bank details' when 'staff_super' then 'Super' else 'Work rights' end);
  end if;
  return old;
end;
$$;
revoke execute on function public.log_record_deleted() from public, anon, authenticated;
do $$
declare
  t text;
begin
  foreach t in array array['staff_bank', 'staff_super', 'staff_work_rights'] loop
    execute format('drop trigger if exists log_record_deleted on public.%I', t);
    execute format('create trigger log_record_deleted after delete on public.%I for each row execute function public.log_record_deleted()', t);
  end loop;
end;
$$;

-- The blank form's location can be set by the system admin or Payroll and tax holders.
drop policy if exists "payroll holders set the TFN form template" on public.app_settings;
create policy "payroll holders set the TFN form template" on public.app_settings for update to authenticated
  using (key = 'records.tfn_template' and (select public.holds_area('payroll_tax')))
  with check (key = 'records.tfn_template' and (select public.holds_area('payroll_tax')) and jsonb_typeof(value) = 'string');

$m084$;
  insert into public.install_log (name) values ('20270111000001_tfn_records.sql');
end;
$part$;

-- ====================================================================
-- 20270112000001_module_catalogue.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20270112000001_module_catalogue.sql') then
    return;
  end if;
  execute $m085$
-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects step 1 (module framework): the module catalogue, and pinned
-- shortcuts that follow each person across devices.
--   * app_modules: every module and submodule (id, parent, category, label,
--     sensitivity, delegable, status). The same ids are in src/lib/modules.ts
--     (scripts/check-modules.mjs checks they match). It grants nothing: menus
--     still follow today's permissions; delegation builds on it later.
--   * pinned_items: each person's own shortcuts (only they see and change them).
-- No new SECURITY DEFINER function.

create table if not exists public.app_modules (
  id          text primary key check (id ~ '^[a-z_]+(\.[a-z_]+)*$'),
  parent_id   text references public.app_modules (id),
  category    text not null check (category in ('workspace', 'operations', 'people', 'hr', 'clients', 'workflows', 'insights', 'engagement', 'system')),
  label       text not null,
  sensitivity text not null default 'normal' check (sensitivity in ('normal', 'sensitive', 'protected')),
  delegable   boolean not null default false,
  status      text not null default 'active' check (status in ('active', 'planned', 'retired')),
  sort_order  int not null default 0
);
alter table public.app_modules enable row level security;
revoke all on public.app_modules from anon;
revoke insert, update, delete, truncate on public.app_modules from authenticated;
grant select on public.app_modules to authenticated;
drop policy if exists "members read the module catalogue" on public.app_modules;
create policy "members read the module catalogue" on public.app_modules for select to authenticated using ((select public.is_member()));

insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order) values
  ('workspace.dashboard', null, 'workspace', 'Dashboard', 'normal', false, 10),
  ('workspace.onboarding', null, 'workspace', 'My onboarding', 'normal', false, 20),
  ('workspace.requests', null, 'workspace', 'My requests', 'normal', false, 30),
  ('workspace.forms', null, 'workspace', 'My forms', 'normal', false, 40),
  ('workspace.contracts', null, 'workspace', 'My contracts', 'normal', false, 50),
  ('workspace.directory', null, 'workspace', 'Directory', 'normal', false, 60),
  ('ops.tasks', null, 'operations', 'Tasks', 'normal', true, 70),
  ('ops.registers', null, 'operations', 'Registers', 'normal', true, 80),
  ('ops.cars', null, 'operations', 'Cars', 'normal', true, 90),
  ('ops.cars.use', 'ops.cars', 'operations', 'Use a car', 'normal', false, 100),
  ('ops.cars.manage', 'ops.cars', 'operations', 'Manage cars', 'normal', false, 110),
  ('ops.cars.app', 'ops.cars', 'operations', 'Get the app', 'normal', false, 120),
  ('ops.features', null, 'operations', 'Built features', 'normal', true, 130),
  ('ops.scoreboard', null, 'operations', 'Scoreboard', 'normal', false, 140),
  ('ops.apps', null, 'operations', 'Apps', 'normal', false, 150),
  ('people.staff', null, 'people', 'Staff', 'normal', true, 160),
  ('people.invite', null, 'people', 'Invite staff', 'normal', false, 170),
  ('people.teams', null, 'people', 'Teams', 'normal', true, 180),
  ('people.roles', null, 'people', 'Roles', 'normal', true, 190),
  ('hr.onboarding', null, 'hr', 'Onboarding', 'normal', true, 200),
  ('hr.onboarding.overview', 'hr.onboarding', 'hr', 'Overview and checks', 'normal', false, 210),
  ('hr.onboarding.expiry', 'hr.onboarding', 'hr', 'Expiry list', 'normal', false, 220),
  ('hr.contracts', null, 'hr', 'Contracts', 'sensitive', true, 230),
  ('hr.requests', null, 'hr', 'Staff requests', 'normal', true, 240),
  ('clients.list', null, 'clients', 'Clients', 'normal', true, 250),
  ('workflows.forms', null, 'workflows', 'Forms', 'normal', true, 260),
  ('workflows.request_rules', null, 'workflows', 'Request approvals', 'normal', true, 270),
  ('workflows.sla', null, 'workflows', 'SLA settings', 'normal', true, 280),
  ('insights.reports', null, 'insights', 'Reports', 'normal', true, 290),
  ('insights.reports.tasks', 'insights.reports', 'insights', 'Tasks', 'normal', false, 300),
  ('insights.reports.cars', 'insights.reports', 'insights', 'Cars', 'normal', false, 310),
  ('insights.reports.compliance', 'insights.reports', 'insights', 'Compliance', 'normal', false, 320),
  ('engagement.assistant', null, 'engagement', 'Assistant', 'normal', false, 330),
  ('engagement.enquiries', null, 'engagement', 'Enquiries', 'normal', true, 340),
  ('engagement.website', null, 'engagement', 'Website settings', 'normal', true, 350),
  ('system.settings', null, 'system', 'System settings', 'protected', false, 360),
  ('system.access', null, 'system', 'Staff access', 'protected', false, 370),
  ('system.audit', null, 'system', 'Change log', 'normal', true, 380),
  ('system.builder', null, 'system', 'Feature builder', 'protected', false, 390),
  ('system.health', null, 'system', 'System health', 'protected', false, 400)
on conflict (id) do update set parent_id = excluded.parent_id, category = excluded.category, label = excluded.label,
  sensitivity = excluded.sensitivity, delegable = excluded.delegable, sort_order = excluded.sort_order;

create table if not exists public.pinned_items (
  user_id    uuid not null references public.profiles (id) on delete cascade,
  href       text not null check (href ~ '^/[A-Za-z0-9/_?=&.-]*$' and length(href) <= 200),
  label      text not null check (length(label) between 1 and 60),
  position   int not null default 0,
  created_at timestamptz not null default now(),
  primary key (user_id, href)
);
alter table public.pinned_items enable row level security;
revoke all on public.pinned_items from anon;
revoke truncate on public.pinned_items from authenticated;
grant select, insert, update, delete on public.pinned_items to authenticated;
drop policy if exists "your own pinned shortcuts" on public.pinned_items;
create policy "your own pinned shortcuts" on public.pinned_items for all to authenticated
  using (user_id = (select auth.uid()) and (select public.is_member()))
  with check (user_id = (select auth.uid()) and (select public.is_member()));

$m085$;
  insert into public.install_log (name) values ('20270112000001_module_catalogue.sql');
end;
$part$;

-- ====================================================================
-- 20270113000001_permission_engine.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20270113000001_permission_engine.sql') then
    return;
  end if;
  execute $m086$
-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects module framework step 2: one permission check for everything.
--   * can(module, action, person) answers "may the signed-in person do this?"
--     - the system admin: always (protected modules: only the system admin);
--     - modules already covered by today's rules answer from those rules
--       exactly (settings areas → can_admin_area; staff records → has_access,
--       TFN → has_tfn_access), so nobody's access changes;
--     - everything else: grants on the module, its parent or its category,
--       the nearest one winning; a "restrict" grant blocks; sensitive modules
--       never inherit (they need their own grant); actions can be limited;
--       scope (all / teams / people), start and end dates apply; a module
--       added after the grant was given is not covered by it.
--   * my_modules(): the modules the signed-in person can view (for menus).
--   * Grants (access_grants) gain: module, actions, effect (allow/restrict),
--     include children, start date. Existing grants get their module filled in.
--   * Categories are in the catalogue too (cat_*), so a whole category can be granted.
-- Nothing in existing security rules changes, so pages do no extra work.
-- No new SECURITY DEFINER function.

-- 1. Catalogue: categories, permission-only modules, and the link to today's rules.
alter table public.app_modules add column if not exists legacy_kind text check (legacy_kind in ('settings', 'record'));
alter table public.app_modules add column if not exists legacy_area text;
alter table public.app_modules add column if not exists actions text[] not null default array['view'];
-- When a module was added: access given to a parent or category before then
-- doesn't reach it (new modules are never given to anyone automatically).
alter table public.app_modules add column if not exists added_at timestamptz not null default now();

insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order) values
  ('cat_workspace', null, 'workspace', 'My workspace', 'normal', false, 0),
  ('cat_operations', null, 'operations', 'Operations', 'normal', true, 1),
  ('cat_people', null, 'people', 'People & organisation', 'normal', true, 2),
  ('cat_hr', null, 'hr', 'HR & workforce', 'normal', true, 3),
  ('cat_clients', null, 'clients', 'Clients & care', 'normal', true, 4),
  ('cat_workflows', null, 'workflows', 'Forms & workflows', 'normal', true, 5),
  ('cat_insights', null, 'insights', 'Reports & insights', 'normal', true, 6),
  ('cat_engagement', null, 'engagement', 'Website & engagement', 'normal', true, 7),
  ('cat_system', null, 'system', 'Administration', 'normal', false, 8)
on conflict (id) do update set label = excluded.label, delegable = excluded.delegable, sort_order = excluded.sort_order;

insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order) values
  ('hr.records', null, 'hr', 'Staff records', 'normal', true, 1010),
  ('hr.records.details', 'hr.records', 'hr', 'Staff details', 'normal', true, 1020),
  ('hr.records.payroll', 'hr.records', 'hr', 'Payroll and tax (bank, super, TFN)', 'sensitive', true, 1030),
  ('hr.records.identity', 'hr.records', 'hr', 'Identity and work rights', 'sensitive', true, 1040),
  ('system.settings.branding', 'system.settings', 'system', 'Branding', 'normal', true, 1050),
  ('system.settings.messages', 'system.settings', 'system', 'Messages', 'normal', true, 1060),
  ('system.settings.people', 'system.settings', 'system', 'People rules', 'normal', true, 1070),
  ('system.settings.compliance', 'system.settings', 'system', 'Compliance settings', 'normal', true, 1080),
  ('system.settings.tasks', 'system.settings', 'system', 'Task settings', 'normal', true, 1090),
  ('system.settings.reports', 'system.settings', 'system', 'Who can see reports', 'normal', true, 1100),
  ('system.settings.vehicles', 'system.settings', 'system', 'Car settings', 'normal', true, 1110),
  ('system.settings.hr', 'system.settings', 'system', 'HR Pack settings', 'normal', true, 1120),
  ('ops.registers.setup', 'ops.registers', 'operations', 'Set up any register', 'normal', true, 1130)
on conflict (id) do update set parent_id = excluded.parent_id, category = excluded.category, label = excluded.label,
  sensitivity = excluded.sensitivity, delegable = excluded.delegable, sort_order = excluded.sort_order;

update public.app_modules set legacy_kind = 'settings', legacy_area = 'branding' where id = 'system.settings.branding';
update public.app_modules set legacy_kind = 'settings', legacy_area = 'messages' where id = 'system.settings.messages';
update public.app_modules set legacy_kind = 'settings', legacy_area = 'people' where id = 'system.settings.people';
update public.app_modules set legacy_kind = 'settings', legacy_area = 'compliance' where id = 'system.settings.compliance';
update public.app_modules set legacy_kind = 'settings', legacy_area = 'tasks' where id = 'system.settings.tasks';
update public.app_modules set legacy_kind = 'settings', legacy_area = 'reports' where id = 'system.settings.reports';
update public.app_modules set legacy_kind = 'settings', legacy_area = 'vehicles' where id = 'system.settings.vehicles';
update public.app_modules set legacy_kind = 'settings', legacy_area = 'hr' where id = 'system.settings.hr';
update public.app_modules set legacy_kind = 'settings', legacy_area = 'website' where id = 'engagement.website';
update public.app_modules set legacy_kind = 'settings', legacy_area = 'audit' where id = 'system.audit';
update public.app_modules set legacy_kind = 'settings', legacy_area = 'registers' where id = 'ops.registers';
update public.app_modules set legacy_kind = 'settings', legacy_area = 'register_setup' where id = 'ops.registers.setup';
update public.app_modules set legacy_kind = 'settings', legacy_area = 'roles' where id = 'people.roles';
update public.app_modules set legacy_kind = 'record', legacy_area = 'staff_details' where id = 'hr.records.details';
update public.app_modules set legacy_kind = 'record', legacy_area = 'payroll_tax' where id = 'hr.records.payroll';
update public.app_modules set legacy_kind = 'record', legacy_area = 'identity_docs' where id = 'hr.records.identity';

-- Submodules of delegable modules can be given on their own.
update public.app_modules c set delegable = true
  from public.app_modules p
 where c.parent_id = p.id and p.delegable and c.sensitivity <> 'protected' and not c.delegable;

-- What each module allows (view is always first).
update public.app_modules set actions = array['view', 'create', 'edit', 'delete', 'configure', 'export'] where id in ('ops.tasks', 'ops.registers', 'ops.features');
update public.app_modules set actions = array['view', 'configure'] where legacy_kind = 'settings' or id like 'system.settings%';
update public.app_modules set actions = array['view', 'edit'] where id in ('hr.records', 'hr.records.details', 'people.staff', 'people.teams', 'people.roles', 'clients.list');
update public.app_modules set actions = array['view', 'edit', 'download', 'reveal_tfn', 'delete'] where id = 'hr.records.payroll';
update public.app_modules set actions = array['view', 'edit', 'download', 'delete'] where id = 'hr.records.identity';
update public.app_modules set actions = array['view', 'create', 'sign_for_employer', 'download'] where id = 'hr.contracts';
update public.app_modules set actions = array['view', 'configure', 'approve', 'export'] where id in ('hr.onboarding', 'hr.onboarding.overview', 'hr.onboarding.expiry');
update public.app_modules set actions = array['view', 'approve', 'configure'] where id in ('hr.requests', 'workflows.request_rules');
update public.app_modules set actions = array['view', 'create', 'edit', 'delete', 'export'] where id = 'workflows.forms';
update public.app_modules set actions = array['view', 'export'] where id like 'insights.%';
update public.app_modules set actions = array['view', 'configure'] where id in ('workflows.sla', 'engagement.website', 'engagement.enquiries', 'ops.cars', 'ops.cars.manage');

-- 2. Grants: which module, which actions, allow or restrict, children, start date.
alter table public.access_grants alter column area drop not null;
alter table public.access_grants add column if not exists module_id text references public.app_modules (id);
alter table public.access_grants add column if not exists actions text[] not null default '{}';
alter table public.access_grants add column if not exists effect text not null default 'allow' check (effect in ('allow', 'restrict'));
alter table public.access_grants add column if not exists include_children boolean not null default true;
alter table public.access_grants add column if not exists starts_at timestamptz;
alter table public.access_grants drop constraint if exists access_grants_area_or_module;
alter table public.access_grants add constraint access_grants_area_or_module check (area is not null or module_id is not null);
-- (the "can only be removed" guard is paused for this one-off fill-in)
alter table public.access_grants disable trigger access_grants_revoke_only;
alter table public.access_grants disable trigger access_grants_cascade;
update public.access_grants g set module_id = m.id
  from public.app_modules m
 where g.module_id is null and m.legacy_kind = 'record' and m.legacy_area = g.area;
alter table public.access_grants enable trigger access_grants_revoke_only;
alter table public.access_grants enable trigger access_grants_cascade;
create unique index if not exists access_grants_one_live_module
  on public.access_grants (module_id, user_id) where revoked_at is null and area is null;
create index if not exists access_grants_user_module on public.access_grants (user_id, module_id) where revoked_at is null;

-- New module grants: an active, delegable, non-protected module; real actions only.
create or replace function public.check_module_grant()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  m record;
begin
  if new.module_id is null or new.area is not null then
    return new;
  end if;
  select * into m from public.app_modules where id = new.module_id;
  if not found or m.status <> 'active' then
    raise exception 'That module doesn''t exist.';
  end if;
  if m.sensitivity = 'protected' or not m.delegable then
    raise exception 'That part of the portal can''t be delegated.';
  end if;
  if m.legacy_kind is not null then
    raise exception 'That part is still managed on its existing page (Staff access or Delegation).';
  end if;
  if exists (select 1 from unnest(new.actions) a where a <> all (m.actions)) then
    raise exception 'One of those actions doesn''t apply to this module.';
  end if;
  return new;
end;
$$;
revoke execute on function public.check_module_grant() from public, anon, authenticated;
drop trigger if exists check_module_grant on public.access_grants;
create trigger check_module_grant before insert on public.access_grants
  for each row execute function public.check_module_grant();

-- 3. The one check.
create or replace function public.can(p_module text, p_action text default 'view', p_person uuid default null)
returns boolean
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  m record;
  v_effect text;
begin
  select * into m from public.app_modules where id = p_module;
  if not found or m.status <> 'active' then
    return false;
  end if;
  if public.is_system_admin() and public.mfa_ok() then
    return true;
  end if;
  if m.sensitivity = 'protected' or not public.mfa_ok() then
    return false;
  end if;
  -- Today's rules, unchanged.
  if m.legacy_kind = 'settings' then
    return public.can_admin_area(m.legacy_area);
  end if;
  if m.legacy_kind = 'record' then
    if p_action = 'reveal_tfn' then
      return p_person is not null and public.has_tfn_access(p_person);
    end if;
    return case when p_person is null then public.holds_area(m.legacy_area) else public.has_access(m.legacy_area, p_person) end;
  end if;
  -- Grants: the nearest level (this module, then its parents, then its category) decides.
  with recursive chain(id, depth) as (
    select m.id, 0
    union all
    select a.parent_id, c.depth + 1 from public.app_modules a join chain c on a.id = c.id where a.parent_id is not null
  ), levels as (
    select id, depth from chain
    union all
    select 'cat_' || m.category, 99
  )
  -- The nearest level with any grant decides: a restriction there for this
  -- action blocks; an allow there that includes this action allows; otherwise no.
  , applicable as (
    select g.effect, g.actions, l.depth
      from public.access_grants g
      join levels l on l.id = g.module_id
      join public.profiles me on me.id = g.user_id
      left join public.profiles gb on gb.id = g.granted_by
     where g.user_id = auth.uid() and g.area is null and g.revoked_at is null
       and (g.expires_at is null or g.expires_at > now())
       and (g.starts_at is null or g.starts_at <= now())
       and me.active and me.role in ('manager', 'staff_admin')
       and (g.parent_id is null or (gb.active and gb.role = 'manager'))
       and (l.depth = 0 or (g.include_children and m.sensitivity = 'normal' and m.added_at <= g.created_at))
       and (p_person is null or g.scope = 'all'
            or (g.scope = 'people' and p_person = any (g.scope_ids))
            or (g.scope = 'teams' and exists (select 1 from public.team_members tm where tm.user_id = p_person and tm.team_id = any (g.scope_ids))))
  )
  select case
           when bool_or(a.effect = 'restrict' and (cardinality(a.actions) = 0 or p_action = any (a.actions))) then 'restrict'
           when bool_or(a.effect = 'allow' and (cardinality(a.actions) = 0 or p_action = any (a.actions))) then 'allow'
         end into v_effect
    from applicable a
   where a.depth = (select min(depth) from applicable);
  return coalesce(v_effect = 'allow', false);
end;
$$;
revoke execute on function public.can(text, text, uuid) from public, anon;
grant execute on function public.can(text, text, uuid) to authenticated;

-- 4. The modules the signed-in person can view.
create or replace function public.my_modules()
returns setof text
language sql
stable
security invoker
set search_path = ''
as $$
  select id from public.app_modules where id not like 'cat\_%' and public.can(id, 'view')
$$;
revoke execute on function public.my_modules() from public, anon;
grant execute on function public.my_modules() to authenticated;

$m086$;
  insert into public.install_log (name) values ('20270113000001_permission_engine.sql');
end;
$part$;

-- ====================================================================
-- 20270114000001_menu_tidy.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20270114000001_menu_tidy.sql') then
    return;
  end if;
  execute $m087$
-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects: menu tidy-up (owner's choices). Catalogue groups only; nobody's
-- access changes.
--   * New "Apps" group: Cars (one item; Use / Manage / Get the app are tabs on
--     its page), Phone apps, and every feature built in the Feature builder.
--   * Forms moves to Operations; SLA settings and Request approvals to
--     Administration; Staff access is now "Access & delegation".
alter table public.app_modules drop constraint if exists app_modules_category_check;
alter table public.app_modules add constraint app_modules_category_check
  check (category in ('workspace', 'operations', 'apps', 'people', 'hr', 'clients', 'workflows', 'insights', 'engagement', 'system'));

insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order)
values ('cat_apps', null, 'apps', 'Apps', 'normal', true, 2)
on conflict (id) do update set label = excluded.label;

update public.app_modules set category = 'apps' where id in ('ops.cars', 'ops.cars.use', 'ops.cars.manage', 'ops.cars.app', 'ops.apps', 'ops.features');
update public.app_modules set label = 'Phone apps' where id = 'ops.apps';
update public.app_modules set category = 'operations' where id = 'workflows.forms';
update public.app_modules set category = 'system' where id in ('workflows.request_rules', 'workflows.sla');
update public.app_modules set label = 'Access & delegation' where id = 'system.access';

$m087$;
  insert into public.install_log (name) values ('20270114000001_menu_tidy.sql');
end;
$part$;

-- ====================================================================
-- 20270115000001_portal_settings.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20270115000001_portal_settings.sql') then
    return;
  end if;
  execute $m088$
-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects: "Portal settings" in Administration, with its pages (System
-- settings, SLA settings, Request approvals) as hidden sub-pages. Catalogue
-- only; nobody's access changes.
update public.app_modules set label = 'Portal settings' where id = 'system.settings';
insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order)
values ('system.settings.general', 'system.settings', 'system', 'System settings', 'protected', false, 1095)
on conflict (id) do update set parent_id = excluded.parent_id, label = excluded.label, sensitivity = excluded.sensitivity;
update public.app_modules set parent_id = 'system.settings' where id in ('workflows.sla', 'workflows.request_rules');

$m088$;
  insert into public.install_log (name) values ('20270115000001_portal_settings.sql');
end;
$part$;

-- ====================================================================
-- 20270116000001_admin_two_items.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20270116000001_admin_two_items.sql') then
    return;
  end if;
  execute $m089$
-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects: Administration has two items: Portal settings (one page with
-- every settings section: System settings, SLA, Request approvals, Change
-- log, Feature builder, System health, and more later) and Access (the
-- delegation page). Catalogue only; nobody's access changes.
update public.app_modules set parent_id = 'system.settings' where id in ('system.audit', 'system.builder', 'system.health');
update public.app_modules set label = 'Access' where id = 'system.access';

$m089$;
  insert into public.install_log (name) values ('20270116000001_admin_two_items.sql');
end;
$part$;

-- ====================================================================
-- 20270117000001_manager_admins.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20270117000001_manager_admins.sql') then
    return;
  end if;
  execute $m090$
-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects module framework step 3: Manager Administrators.
--   * The system admin nominates managers as Manager Administrators (not all
--     managers). Each nomination can have a start and end date, a note, and
--     be suspended, resumed or ended; it's never deleted (it's the history).
--   * Admin access to modules (category, module, submodule, actions) goes only
--     to a nominated manager. A Manager Administrator can pass access on to a
--     staff admin only when allowed ("may pass on"), never wider (same module
--     or one inside it, same or fewer actions, same or narrower scope, ending
--     no later), and never further.
--   * Access only works while the nomination is active: suspending or ending
--     it stops their access and everything they passed on, straight away.
--   * Ending a nomination also removes their module access (recorded).
-- No new SECURITY DEFINER function.

create table if not exists public.admin_designations (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  status      text not null default 'active' check (status in ('active', 'suspended', 'ended')),
  starts_at   timestamptz not null default now(),
  expires_at  timestamptz,
  note        text not null default '' check (length(note) <= 300),
  granted_by  uuid references public.profiles (id) on delete set null,
  created_at  timestamptz not null default now(),
  changed_at  timestamptz,
  changed_by  uuid references public.profiles (id) on delete set null,
  check (expires_at is null or expires_at > starts_at)
);
create unique index if not exists admin_designations_one_open on public.admin_designations (user_id) where status <> 'ended';
alter table public.admin_designations enable row level security;
revoke all on public.admin_designations from anon;
revoke delete, truncate on public.admin_designations from authenticated;
grant select, insert, update on public.admin_designations to authenticated;

-- Who is a Manager Administrator isn't private: members can see it.
drop policy if exists "members see who is a Manager Administrator" on public.admin_designations;
create policy "members see who is a Manager Administrator" on public.admin_designations for select to authenticated
  using ((select public.is_member()));
drop policy if exists "the system admin nominates" on public.admin_designations;
create policy "the system admin nominates" on public.admin_designations for insert to authenticated
  with check ((select public.is_system_admin()) and (select public.mfa_ok()) and granted_by = (select auth.uid()) and status = 'active'
              and exists (select 1 from public.profiles p where p.id = user_id and p.active and p.role = 'manager'));
drop policy if exists "the system admin changes nominations" on public.admin_designations;
create policy "the system admin changes nominations" on public.admin_designations for update to authenticated
  using ((select public.is_system_admin()) and status <> 'ended')
  with check ((select public.is_system_admin()));

-- Only status and end date change; ended is final; who and when are recorded.
-- Ending also removes their module access (and what they passed on).
create or replace function public.guard_admin_designation()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if (to_jsonb(new) - 'status' - 'expires_at' - 'note' - 'changed_at' - 'changed_by') is distinct from (to_jsonb(old) - 'status' - 'expires_at' - 'note' - 'changed_at' - 'changed_by') then
    raise exception 'Only the status, end date and note of a nomination can change.';
  end if;
  new.changed_at := now();
  new.changed_by := auth.uid();
  if new.status = 'ended' and old.status <> 'ended' then
    update public.access_grants set revoked_at = now()
     where user_id = new.user_id and area is null and revoked_at is null;
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_admin_designation() from public, anon, authenticated;
drop trigger if exists guard_admin_designation on public.admin_designations;
create trigger guard_admin_designation before update on public.admin_designations
  for each row execute function public.guard_admin_designation();

-- Is this person a Manager Administrator right now?
create or replace function public.is_manager_admin(p_user uuid default auth.uid())
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select exists (
    select 1 from public.admin_designations d join public.profiles p on p.id = d.user_id
     where d.user_id = p_user and d.status = 'active' and d.starts_at <= now()
       and (d.expires_at is null or d.expires_at > now()) and p.active and p.role = 'manager')
$$;
revoke execute on function public.is_manager_admin(uuid) from public, anon;
grant execute on function public.is_manager_admin(uuid) to authenticated;

-- May this module grant be given? (Grants for staff records keep their own rules.)
create or replace function public.module_grant_allowed(
  p_module text, p_user uuid, p_actions text[], p_scope text, p_scope_ids uuid[],
  p_pass_on boolean, p_expires timestamptz, p_parent uuid, p_by uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select p_by = auth.uid() and p_user <> auth.uid() and public.mfa_ok()
     and (p_expires is null or p_expires > now())
     and (
       -- The system admin: to a Manager Administrator.
       (public.is_system_admin() and p_parent is null and public.is_manager_admin(p_user))
       or
       -- A Manager Administrator passing on their own access to a staff admin.
       (public.is_manager_admin() and not p_pass_on
        and exists (select 1 from public.profiles p where p.id = p_user and p.active and p.role = 'staff_admin')
        and exists (
          with recursive up(id) as (
            select p_module
            union all
            select m.parent_id from public.app_modules m join up on m.id = up.id where m.parent_id is not null
          )
          select 1 from public.access_grants g, public.app_modules target
           where target.id = p_module and g.id = p_parent and g.user_id = auth.uid() and g.area is null
             and g.can_pass_on and g.effect = 'allow' and g.revoked_at is null
             and (g.expires_at is null or g.expires_at > now()) and (g.starts_at is null or g.starts_at <= now())
             -- the same module, or one inside it (sensitive ones only on their own)
             and (g.module_id = p_module
                  or (target.sensitivity = 'normal' and g.include_children
                      and (g.module_id in (select id from up) or g.module_id = 'cat_' || target.category)))
             and (cardinality(g.actions) = 0 or (cardinality(p_actions) > 0 and p_actions <@ g.actions))
             and (g.expires_at is null or (p_expires is not null and p_expires <= g.expires_at))
             and (g.scope = 'all' or (g.scope = p_scope and p_scope_ids <@ g.scope_ids)))
       )
     )
$$;
revoke execute on function public.module_grant_allowed(text, uuid, text[], text, uuid[], boolean, timestamptz, uuid, uuid) from public, anon;
grant execute on function public.module_grant_allowed(text, uuid, text[], text, uuid[], boolean, timestamptz, uuid, uuid) to authenticated;

drop policy if exists "grant within the rules" on public.access_grants;
create policy "grant within the rules" on public.access_grants
  for insert to authenticated
  with check (revoked_at is null and revoked_by is null and (
    (area is not null and public.grant_allowed(area, user_id, scope, scope_ids, can_pass_on, can_reveal_tfn, expires_at, parent_id, granted_by))
    or (area is null and public.module_grant_allowed(module_id, user_id, actions, scope, scope_ids, can_pass_on, expires_at, parent_id, granted_by))));

-- The check, now also requiring an active nomination.
create or replace function public.can(p_module text, p_action text DEFAULT 'view'::text, p_person uuid DEFAULT NULL::uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
declare
  m record;
  v_effect text;
begin
  select * into m from public.app_modules where id = p_module;
  if not found or m.status <> 'active' then
    return false;
  end if;
  if public.is_system_admin() and public.mfa_ok() then
    return true;
  end if;
  if m.sensitivity = 'protected' or not public.mfa_ok() then
    return false;
  end if;
  -- Today's rules, unchanged.
  if m.legacy_kind = 'settings' then
    return public.can_admin_area(m.legacy_area);
  end if;
  if m.legacy_kind = 'record' then
    if p_action = 'reveal_tfn' then
      return p_person is not null and public.has_tfn_access(p_person);
    end if;
    return case when p_person is null then public.holds_area(m.legacy_area) else public.has_access(m.legacy_area, p_person) end;
  end if;
  -- Grants: the nearest level (this module, then its parents, then its category) decides.
  with recursive chain(id, depth) as (
    select m.id, 0
    union all
    select a.parent_id, c.depth + 1 from public.app_modules a join chain c on a.id = c.id where a.parent_id is not null
  ), levels as (
    select id, depth from chain
    union all
    select 'cat_' || m.category, 99
  )
  -- The nearest level with any grant decides: a restriction there for this
  -- action blocks; an allow there that includes this action allows; otherwise no.
  , applicable as (
    select g.effect, g.actions, l.depth
      from public.access_grants g
      join levels l on l.id = g.module_id
      join public.profiles me on me.id = g.user_id
      left join public.profiles gb on gb.id = g.granted_by
     where g.user_id = auth.uid() and g.area is null and g.revoked_at is null
       and (g.expires_at is null or g.expires_at > now())
       and (g.starts_at is null or g.starts_at <= now())
       and me.active and me.role in ('manager', 'staff_admin')
       -- Given by the system admin: only while they're a Manager Administrator.
       -- Passed on: only while the person who passed it on still is.
       and (case when g.parent_id is null then public.is_manager_admin(g.user_id) else (gb.active and gb.role = 'manager' and public.is_manager_admin(g.granted_by)) end)
       and (l.depth = 0 or (g.include_children and m.sensitivity = 'normal' and m.added_at <= g.created_at))
       and (p_person is null or g.scope = 'all'
            or (g.scope = 'people' and p_person = any (g.scope_ids))
            or (g.scope = 'teams' and exists (select 1 from public.team_members tm where tm.user_id = p_person and tm.team_id = any (g.scope_ids))))
  )
  select case
           when bool_or(a.effect = 'restrict' and (cardinality(a.actions) = 0 or p_action = any (a.actions))) then 'restrict'
           when bool_or(a.effect = 'allow' and (cardinality(a.actions) = 0 or p_action = any (a.actions))) then 'allow'
         end into v_effect
    from applicable a
   where a.depth = (select min(depth) from applicable);
  return coalesce(v_effect = 'allow', false);
end;
$function$;

$m090$;
  insert into public.install_log (name) values ('20270117000001_manager_admins.sql');
end;
$part$;

-- ====================================================================
-- 20270118000001_owner.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20270118000001_owner.sql') then
    return;
  end if;
  execute $m091$
-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects: the owner. One system admin (the business owner) whose account
-- no other system admin can change: nobody else can turn it off, change its
-- role, name, email or two-factor rules, reset its two-factor or password,
-- clear its car PIN, or sign it out. "Sign out everyone" leaves the owner
-- signed in. The owner is set only in the database (SQL editor), never from
-- the portal. This lets the owner add other system admins (for example an
-- outside reviewer) without the risk of being locked out.
-- No new SECURITY DEFINER function (three existing ones gain the owner check).

alter table public.profiles add column if not exists is_owner boolean not null default false;
create unique index if not exists profiles_one_owner on public.profiles ((true)) where is_owner;

-- The first active system admin becomes the owner (if there's none yet).
update public.profiles set is_owner = true
 where id = (select id from public.profiles where role = 'system_admin' and active order by created_at limit 1)
   and not exists (select 1 from public.profiles where is_owner);

create or replace function public.guard_owner()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if auth.uid() is null then
    return new; -- the SQL editor and the portal's own jobs
  end if;
  if new.is_owner is distinct from old.is_owner then
    raise exception 'The owner can only be changed in the database (SQL editor).';
  end if;
  if old.is_owner and auth.uid() <> old.id
     and (new.role is distinct from old.role or new.active is distinct from old.active
          or new.mfa_exempt is distinct from old.mfa_exempt or new.email is distinct from old.email
          or new.full_name is distinct from old.full_name) then
    raise exception 'This is the owner''s account. Only the owner can change it.';
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_owner() from public, anon, authenticated;
drop trigger if exists profiles_guard_owner on public.profiles;
create trigger profiles_guard_owner before update on public.profiles
  for each row execute function public.guard_owner();

-- Reset two-factor, password links and car PINs: never for the owner (by others).
CREATE OR REPLACE FUNCTION public.can_help_sign_in(p_user uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.mfa_ok()
     and p_user is distinct from auth.uid()
     and exists (select 1 from public.profiles where id = p_user and not is_owner)
     and (public.my_role() = 'system_admin'
          or (public.my_role() = any (public.setting_roles('people.access_reset_roles'))
              and (select role from public.profiles where id = p_user) <> 'system_admin'))
$function$;

-- Signing one person out: never the owner.
CREATE OR REPLACE FUNCTION public.sign_out_everywhere(p_user_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_count integer;
begin
  if not public.is_system_admin() then
    raise exception 'Only the system admin can do this.';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'To sign yourself out of other devices, use My account.';
  end if;
  if exists (select 1 from public.profiles where id = p_user_id and is_owner) then
    raise exception 'This is the owner''s account. Only the owner can change it.';
  end if;
  delete from auth.sessions where user_id = p_user_id;
  get diagnostics v_count = row_count;
  perform public.write_audit('signed_out_everywhere', 'profile', p_user_id::text, jsonb_build_object('devices', v_count));
  return v_count;
end;
$function$;

-- Signing everyone out: the owner stays signed in.
CREATE OR REPLACE FUNCTION public.sign_out_everyone()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_count integer;
begin
  if not public.is_system_admin() then
    raise exception 'Only the system admin can do this.';
  end if;
  delete from auth.sessions
   where id is distinct from nullif(auth.jwt() ->> 'session_id', '')::uuid
     -- cmeprojects: the owner stays signed in (unless the owner does this).
     and (user_id not in (select id from public.profiles where is_owner)
          or exists (select 1 from public.profiles where id = auth.uid() and is_owner));
  get diagnostics v_count = row_count;
  perform public.write_audit('signed_out_everyone', 'system', 'everyone', jsonb_build_object('devices', v_count));
  return v_count;
end;
$function$;

$m091$;
  insert into public.install_log (name) values ('20270118000001_owner.sql');
end;
$part$;

-- ====================================================================
-- 20270119000001_step4_onboarding_cars.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20270119000001_step4_onboarding_cars.sql') then
    return;
  end if;
  execute $m092$
-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects module framework step 4 (first modules): Onboarding and Cars
-- follow the Access page too. Approving uploads and setting up onboarding is
-- allowed by the existing role rules OR by "Onboarding: approve" given on the
-- Access page; managing cars by the role rules OR "Manage cars: set up".
-- Nobody loses access. People with no admin access given skip the extra check
-- straight away (one index lookup), so pages stay as fast.
-- No new SECURITY DEFINER function (two existing ones gain the extra rule).

CREATE OR REPLACE FUNCTION public.can_manage_compliance()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.mfa_ok() and (public.my_role() = 'system_admin'
         or public.my_role() = any (public.setting_roles('compliance.manager_roles'))
         or (public.my_role() = 'manager'
             and not exists (select 1 from public.profiles where role = 'staff_admin' and active))
         -- cmeprojects step 4: or given Onboarding (approve) on the Access page.
         or (exists (select 1 from public.access_grants g where g.user_id = auth.uid() and g.area is null and g.revoked_at is null)
              and public.can('hr.onboarding', 'approve')))
$function$;

CREATE OR REPLACE FUNCTION public.can_manage_cars()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.cars_on()
     and (public.my_role() = 'system_admin' or public.my_role() = any (public.setting_roles('vehicles.manager_roles'))
          -- cmeprojects step 4: or given Manage cars (set up) on the Access page.
          or (exists (select 1 from public.access_grants g where g.user_id = auth.uid() and g.area is null and g.revoked_at is null)
              and public.can('ops.cars.manage', 'configure')))
$function$;

$m092$;
  insert into public.install_log (name) values ('20270119000001_step4_onboarding_cars.sql');
end;
$part$;

-- ====================================================================
-- 20270120000001_step4_forms_reports.sql
-- ====================================================================
do $part$
begin
  if exists (select 1 from public.install_log where name = '20270120000001_step4_forms_reports.sql') then
    return;
  end if;
  execute $m093$
-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects module framework step 4 (second batch): Forms and the Cars
-- report follow the Access page as well as the role rules (the Tasks and
-- Onboarding reports are checked by the pages; their data already follows the
-- task and onboarding rules). Nobody loses access; people with no admin access
-- given skip the extra check straight away.
-- No new SECURITY DEFINER function (two existing ones gain the extra rule).

CREATE OR REPLACE FUNCTION public.can_make_forms()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.is_member() and public.feature_enabled('forms')
     and (public.is_system_admin()
          or (public.feature_enabled('form_builder')
              and public.my_role()::text in (select jsonb_array_elements_text(coalesce(
                    (select value from public.app_settings where key = 'forms.maker_roles'), '[]'))))
              -- cmeprojects step 4: or given Forms (create) on the Access page.
              or (public.feature_enabled('form_builder') and (exists (select 1 from public.access_grants g where g.user_id = auth.uid() and g.area is null and g.revoked_at is null)
                   and public.can('workflows.forms', 'create'))))
$function$;

CREATE OR REPLACE FUNCTION public.can_see_car_reports()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.can_manage_cars()
      or (public.cars_on() and public.my_role() = any (public.setting_roles('vehicles.report_roles')))
      -- cmeprojects step 4: or given the Cars report on the Access page.
      or (public.cars_on() and (exists (select 1 from public.access_grants g where g.user_id = auth.uid() and g.area is null and g.revoked_at is null)
                   and public.can('insights.reports.cars', 'view')))
$function$;

$m093$;
  insert into public.install_log (name) values ('20270120000001_step4_forms_reports.sql');
end;
$part$;
