# Stage 1: summary of the 94 changed policies (cmeprojects)

Staff Portal · © cmeproject. Each row lists the calls that are now evaluated once per statement (wrapped as `(select …)`). The row-dependent checks listed are **unchanged**. Full original and proposed text, with apply and rollback SQL: `docs/audit/2026-11-rls-register.md`.

| # | Table | Policy | Operation | Now evaluated once per statement | Row-dependent checks (unchanged) |
|---|---|---|---|---|---|
| 1 | `admin_delegations` | system admin and the delegate read delegations | SELECT | `auth.uid()`, `is_system_admin()` | none |
| 2 | `app_settings` | anyone reads public settings | SELECT | `is_member()` | none |
| 3 | `app_settings` | car managers set the client field | UPDATE | `can_manage_cars()` | none |
| 4 | `app_settings` | system admin edits settings | UPDATE | `is_system_admin()` | none |
| 5 | `assistant_chats` | assistant_chats_own | ALL | `auth.uid()`, `is_member()` | none |
| 6 | `assistant_documents` | assistant_documents_all | ALL | `can_admin_area('website'::text)` | none |
| 7 | `assistant_messages` | assistant_messages_own | ALL | `auth.uid()` | none |
| 8 | `assistant_questions` | assistant_questions_read | SELECT | `can_admin_area('website'::text)` | none |
| 9 | `assistant_settings` | assistant_settings_read | SELECT | `can_admin_area('website'::text)` | none |
| 10 | `assistant_settings` | assistant_settings_write | UPDATE | `can_admin_area('website'::text)` | none |
| 11 | `audit_log` | delegated managers read the change log | SELECT | `can_admin_area('audit'::text)` | none |
| 12 | `audit_log` | system admin reads the audit log | SELECT | `is_system_admin()` | none |
| 13 | `car_clients` | car managers add clients | INSERT | `can_manage_cars()` | none |
| 14 | `car_clients` | car managers change clients | UPDATE | `can_manage_cars()` | none |
| 15 | `car_clients` | car managers see clients | SELECT | `can_manage_cars()` | none |
| 16 | `car_clients` | people managers add clients | INSERT | `can_manage_people()` | none |
| 17 | `car_clients` | people managers change clients | UPDATE | `can_manage_people()` | none |
| 18 | `car_clients` | people managers see clients | SELECT | `can_manage_people()` | none |
| 19 | `car_purposes` | car managers add purposes | INSERT | `can_manage_cars()` | none |
| 20 | `car_purposes` | car managers change purposes | UPDATE | `can_manage_cars()` | none |
| 21 | `car_purposes` | staff see purposes | SELECT | `cars_on()` | none |
| 22 | `car_trips` | drivers see their trips, reports see all | SELECT | `auth.uid()`, `can_see_car_reports()`, `cars_on()` | none |
| 23 | `cars` | car managers add cars | INSERT | `can_manage_cars()` | none |
| 24 | `cars` | car managers change cars | UPDATE | `can_manage_cars()` | none |
| 25 | `cars` | staff see cars | SELECT | `cars_on()` | none |
| 26 | `client_teams` | members see which team looks after which client | SELECT | `is_member()` | none |
| 27 | `client_teams` | people managers link clients to teams | INSERT | `can_manage_people()` | none |
| 28 | `client_teams` | people managers unlink clients from teams | DELETE | `can_manage_people()` | none |
| 29 | `compliance_items` | compliance managers add items | INSERT | `can_manage_compliance()` | none |
| 30 | `compliance_items` | compliance managers change items | UPDATE | `can_manage_compliance()` | none |
| 31 | `compliance_items` | members read onboarding items | SELECT | `is_member()` | none |
| 32 | `compliance_opens` | people see their own opens; compliance managers see all | SELECT | `auth.uid()`, `can_manage_compliance()` | none |
| 33 | `compliance_records` | read your own records, or as compliance manager | SELECT | `auth.uid()`, `can_manage_compliance()` | none |
| 34 | `custom_alerts` | the builder manages alerts | ALL | `can_build_features()` | none |
| 35 | `custom_client_targets` | targets follow their feature | SELECT | `can_build_features()`, `is_member()` | `custom_feature_live(feature_id)` |
| 36 | `custom_client_targets` | the builder sets targets | ALL | `can_build_features()` | none |
| 37 | `custom_features` | staff see live features, the builder sees all | SELECT | `can_build_features()`, `is_member()` | none |
| 38 | `custom_features` | the builder adds features | INSERT | `can_build_features()` | none |
| 39 | `custom_features` | the builder changes features | UPDATE | `can_build_features()` | none |
| 40 | `custom_features` | the builder removes unused features | DELETE | `can_build_features()` | none |
| 41 | `custom_fields` | fields follow their feature | SELECT | `can_build_features()`, `is_member()` | `custom_feature_live(feature_id)` |
| 42 | `custom_fields` | the builder adds fields | INSERT | `can_build_features()` | none |
| 43 | `custom_fields` | the builder changes fields | UPDATE | `can_build_features()` | none |
| 44 | `custom_fields` | the builder removes unused fields | DELETE | `can_build_features()` | none |
| 45 | `delegation_rules` | members read delegation | SELECT | `is_member()` | none |
| 46 | `delegation_shares` | members read shares | SELECT | `is_member()` | none |
| 47 | `features` | members read features | SELECT | `is_member()` | none |
| 48 | `features` | system admin switches features | UPDATE | `is_system_admin()` | none |
| 49 | `form_collaborators` | the form's maker shares it | ALL | `auth.uid()`, `is_system_admin()` | none |
| 50 | `form_completions` | completions: your own, or the form's managers | SELECT | `auth.uid()` | `can_manage_form(form_id)` |
| 51 | `form_recipients` | recipients see their own, managers all | SELECT | `auth.uid()` | `can_manage_form(form_id)` |
| 52 | `form_responses` | replies: your own, or the form's managers | SELECT | `auth.uid()` | `can_manage_form(form_id)` |
| 53 | `forms` | form makers add forms | INSERT | `auth.uid()`, `can_make_forms()` | none |
| 54 | `forms` | forms are seen by their managers, or to fill in | SELECT | `auth.uid()`, `is_member()` | `can_fill_form(id)`, `can_manage_form(id)` |
| 55 | `invitations` | inviters create general invitations | INSERT | `can_invite()` | none |
| 56 | `invitations` | managers and admins create invitations | INSERT | `can_manage_people()` | none |
| 57 | `invitations` | managers and admins read invitations | SELECT | `can_manage_people()` | none |
| 58 | `invitations` | managers and admins remove pending invitations | DELETE | `can_manage_people()` | none |
| 59 | `invitations` | managers and admins update invitations | UPDATE | `can_manage_people()` | none |
| 60 | `job_titles` | delegated people add job titles | INSERT | `can_admin_area('roles'::text)` | none |
| 61 | `job_titles` | delegated people change job titles | UPDATE | `can_admin_area('roles'::text)` | none |
| 62 | `job_titles` | members read job titles | SELECT | `is_member()` | none |
| 63 | `leave_periods` | the person and people managers see leave | SELECT | `auth.uid()`, `can_manage_people()`, `is_system_admin()` | none |
| 64 | `notifications` | read your own notifications | SELECT | `auth.uid()` | none |
| 65 | `organisation` | members read the company | SELECT | `is_member()` | none |
| 66 | `organisation` | system admin edits the company | UPDATE | `is_system_admin()` | none |
| 67 | `people_change_requests` | managers and admins see change requests | SELECT | `can_manage_people()` | none |
| 68 | `profiles` | managers and admins update people | UPDATE | `can_manage_people()` | none |
| 69 | `profiles` | members read colleagues | SELECT | `is_member()`, `is_system_admin()` | none |
| 70 | `profiles` | read own profile | SELECT | `auth.uid()` | none |
| 71 | `profiles` | update own name | UPDATE | `auth.uid()`, `my_role()` | none |
| 72 | `record_events` | members read record history | SELECT | `is_member()` | none |
| 73 | `records` | members read records | SELECT | `is_member()` | none |
| 74 | `register_templates` | members read register templates | SELECT | `is_member()` | none |
| 75 | `registries` | delegated people create registries | INSERT | `can_admin_area('registers'::text)` | none |
| 76 | `registries` | members read registries | SELECT | `is_member()` | none |
| 77 | `registry_fields` | members read registry fields | SELECT | `is_member()` | none |
| 78 | `registry_managers` | members read registry managers | SELECT | `is_member()` | none |
| 79 | `request_types` | members read request types | SELECT | `is_member()` | none |
| 80 | `request_types` | system admin changes request types | UPDATE | `can_admin_area('hr'::text)` | none |
| 81 | `requests` | people involved see a request | SELECT | `auth.uid()`, `can_manage_people()`, `feature_enabled('hr_requests'::text)`, `is_system_admin()` | `can_act_on_request(id)` |
| 82 | `settings_drafts` | see your drafts, the system admin sees all | SELECT | `auth.uid()`, `is_system_admin()` | none |
| 83 | `shift_changes` | the person and people managers see shift changes | SELECT | `auth.uid()`, `can_manage_people()`, `is_system_admin()` | none |
| 84 | `staff_directory` | members see the staff directory | SELECT | `feature_enabled('hr_profiles'::text)`, `is_member()` | none |
| 85 | `staff_private` | the person and people managers see private details | SELECT | `auth.uid()`, `can_manage_people()`, `feature_enabled('hr_profiles'::text)`, `is_system_admin()` | none |
| 86 | `task_alerts` | read your own alerts | SELECT | `auth.uid()` | none |
| 87 | `task_views` | read your own views | SELECT | `auth.uid()` | none |
| 88 | `team_leaders` | members read team leaders | SELECT | `is_member()` | none |
| 89 | `team_members` | members read team members | SELECT | `is_member()` | none |
| 90 | `teams` | managers and admins manage teams | ALL | `can_manage_people()` | none |
| 91 | `teams` | members read teams | SELECT | `is_member()` | none |
| 92 | `website_enquiries` | website_enquiries_read | SELECT | `can_see_enquiries()` | none |
| 93 | `website_enquiries` | website_enquiries_update | UPDATE | `can_see_enquiries()` | none |
| 94 | `work_overrides` | the person and people who manage staff see overrides | SELECT | `auth.uid()`, `can_manage_compliance()`, `can_manage_people()` | `has_role(ARRAY['manager'::app_role])`, `leads_user(user_id)` |
