# DB-001: Database and Data Model

| Field | Value |
|---|---|
| Document ID | DB-001 |
| Title | Database and Data Model |
| Category | 03 Database and data |
| Version | 0.1 |
| Status | **Draft** |
| Owner / Reviewer / Approver | Technical Lead / Security Reviewer (independent) / Product Owner, role holders not yet assigned |
| Created | 16 Nov 2026 |
| Last reviewed | TBC |
| Next review | On every database or RLS change (GOV-001 §6) |
| Related | ARC-001, SEC-002, MOD-001, RSK-001, QA-005 (live updates) |
| Appendix | [DB-001 appendix A: every table (generated)](DB-001-appendix-a-tables.md) |

**Source of truth:** `supabase/migrations/` (107 files). This document was
checked against a local database built from those migrations, equal to Dev
up to live update 90 (Dev itself not inspected). Counts: 93 tables (RLS on
for all), 173 foreign keys, 202 check constraints, 80 triggers, 274
functions (227 SECURITY DEFINER), 0 views. **Verified** unless marked.

## 1. Conventions (verified)

- Primary keys are `uuid` (`gen_random_uuid()`), except one-row-per-person
  tables keyed by `user_id` and the audit log (`bigint` identity).
- Most tables carry `org_id uuid default default_org_id()` (one organisation
  per database; **not used by any access rule**, ARC-001 §8).
- `created_at` / `created_by` / `updated_at` / `updated_by` set by defaults or
  guard triggers; the database sets "who" from `auth.uid()`, not the app.
- History is kept by **not deleting**: many tables have no delete rule;
  things are deactivated, ended or superseded instead.
- Times are `timestamptz`; the company time zone is the `region.timezone`
  setting (`local_today()`).

## 2. Business-critical areas and relationships

### 2.1 People and organisation

```
auth.users 1─1 profiles ─┬─ team_members ─ teams ─ team_leaders
                          ├─ job_titles (job_title_id, one per person)
                          ├─ staff_directory, staff_private, staff_birthdays (1 per person)
                          ├─ staff_bank, staff_super, staff_work_rights, staff_tax (1 per person, sensitive)
                          └─ access_grants (person grants) ; admin_designations (Manager Administrators)
```

- `profiles`: one row per sign-in (`id` = `auth.users.id`); `role`
  (`app_role` enum: new_starter, support_worker, team_leader, manager,
  staff_admin, system_admin, external), `job_title_id`, `active`, `is_owner`,
  `cleared_at` / `cleared_by`, `onboarded_at`. Guarded by
  `guard_profile_update`, `guard_owner`, `sync_title_and_role`,
  `notify_role_changed`, `tidy_teams_after_role_change`,
  `drop_delegation_on_change`.
- `job_titles`: the dynamic roles; one `access_level` each;
  `guard_job_title` stops a level changing while people hold it and logs
  changes.
- `staff_*` record tables: `guard_staff_record` (who may verify; any change
  resets verification; access log), `guard_staff_tax`, `log_record_deleted`.

### 2.2 Onboarding, compliance and contracts

- `compliance_items` (requirements, targeted by role, team, title or person)
  → `compliance_item_versions` (kept on change) → `compliance_records` (a
  person's submission, status, expiry, verification) → `compliance_alerts`
  (one per record per expiry stage). `work_overrides` (work before
  clearance, with reason and end date).
- `contracts` → `contract_signatures`; `contract_supersede` keeps one
  current version; `guard_contract`; content hash on signing.

### 2.3 Tasks, registers and records

- `registries` (registers, including the built-in General tasks) →
  `registry_fields` (custom fields), `registry_managers`.
- `tasks` (one table for all task registers; `registry_id`, `parent_task_id`
  for follow-up actions, `client_id` → `car_clients`, SLA fields) →
  `task_events` (timeline, append-only), `task_helpers`, `task_alerts`,
  `task_views`. Guards: `guard_cleared_tasks`, `guard_task_people`,
  `limited_task_guard`, `settle_escalation`.
- `records` (records-type registers, for example asset lists) →
  `record_events` (append-only).

### 2.4 Clients & Care (updates 85 to 90)

```
car_clients (client record, CL- reference, status) ─┬─ client_teams ─ teams
  ├─ client_details (1 per client, sensitive)        ├─ client_locations (approved, dates)
  ├─ client_people (emergency, representatives)      ├─ client_alerts ─ client_alert_notes (sensitive)
  └─ client_services ─ client_programs ; client_services.location_id → client_locations
Also referenced by: car_trips, custom_entries, custom_client_targets, tasks
```

- `car_clients` is the **one** client record (name kept from the Cars
  module). `client_ref` from sequence `client_ref_seq`, unique, never edited
  (`guard_client_record`, SECURITY DEFINER, writes status changes to the
  log). Clients aren't deleted (no delete rule).
- Foreign keys from the client tables added in updates 87 to 90 use **ON
  DELETE RESTRICT** (history can't be removed by deleting a client or
  program). Older links differ: `client_teams` and `custom_client_targets`
  cascade, `tasks.client_id` is set to null.
- `guard_client_location` (re-approval after address change; approver can't
  be faked); `guard_client_service` (own location, active program, readiness
  before active); `log_client_change` (change log without values).
- Readiness: `client_gaps()`, `client_service_gaps()`, `client_readiness()`
  (INVOKER, read-only).

### 2.5 Operations apps

- Cars: `cars`, `car_trips`, `car_purposes`, `car_app_pins`; triggers keep
  odometer and car status in step; `guard_cleared_trips`.
- Built features: `custom_features` → `custom_fields`, `custom_entries`,
  `custom_alerts`, `custom_alert_runs`, `custom_client_targets`.
- Forms: `forms`, questions, replies, sends (form tables in appendix A).
- Requests: `requests`, `request_types`, `leave_periods`,
  `people_change_requests`.

### 2.6 Settings, permissions and audit

- `features` (switches, parents, premium, included), `app_settings`
  (values), `settings_drafts` (saved but not deployed).
- `app_modules` (module catalogue), `access_grants`, `admin_designations`,
  `delegation_rules`, `delegation_shares`.
- `audit_log` (change log; `block_audit_changes` stops updates, deletes and
  truncation), `sensitive_access_log` (views and changes of pay, identity,
  TFN records), `notifications`, `email_outbox`, `system_heartbeat`.

## 3. Important data integrity rules (verified)

| Rule | Where |
|---|---|
| The change log and task and record timelines can't be edited or deleted | `block_audit_changes` triggers |
| Owner can't be turned off, demoted, reset or signed out | `guard_owner` (update 74) |
| Nobody changes their own role; staff admin role changes wait for a manager | `guard_profile_update`, `people_change_requests` |
| A role (other than new starter) needs clearance when compliance is on | update 79 (`role_after_clearance`) |
| Clearance needs a checked right to work; can't clear twice | `grant_clearance` (updates 80, 81) |
| Verification of pay and identity records only by someone else with access | `guard_staff_record` |
| A title's level can't change while people hold it | `guard_job_title` |
| Grants never exceed the giver's own access; revoked, never deleted | `check_module_grant`, `access_grant_revoke_only`, `access_grant_cascade` |
| Client reference permanent and unique; programs never deleted; client data never deleted | updates 85 to 90 |
| A service can't be active unless the client is ready | `guard_client_service` |
| Required register fields must be filled before a task is completed | task completion function (AUD-009 §3) |

## 4. Functions (summary; full list of SECURITY DEFINER functions in SEC-002 appendix A)

- **Permission helpers** (used in RLS): `is_member`, `is_system_admin`,
  `has_role`, `can_manage_people`, `can_manage_compliance`, `can_manage_cars`,
  `can_see_task`, `can_edit_task`, `has_access`, `has_tfn_access`,
  `can(module, action, person)`, `is_manager_admin`, `feature_enabled`,
  `feature_live`, `mfa_ok`.
- **Actions** (called by the app): `create_task`, `set_task_status`,
  `grant_clearance`, `save_profile`, `save_draft`, `deploy_drafts`,
  `team_private`, `team_clients`, `clients_to_pick`, `notify` and others.
- **Scheduled**: `run_due_alerts`, `run_compliance_alerts`, `run_car_alerts`,
  `run_feature_time_alerts`, `escalate_requests`.
- **Triggers**: 37 SECURITY DEFINER trigger functions plus INVOKER ones.

## 5. Indexes (verified count; detail not reviewed)

Indexes exist on primary keys, unique constraints and the main lookups
(for example `client_locations_client`, `client_people_client`,
`client_services_client`). A full index review is part of the deferred
performance stages (ARC-005); **not assessed here**.

## 6. Migration and update history (verified)

- `supabase/migrations/` (107 files, dated names) = fresh install;
  `supabase/install/fresh-install.sql` is generated from them and checked by
  a test.
- `supabase/live-updates/update-NN.sql` with `undo-NN.sql`: each safe to run
  twice and round-trip tested (undo matches the original; re-apply matches);
  the README records which copy has which (Dev: all via the setup SQL to
  59; 60 to 90 run, 11 to 16 Nov 2026).
- Database tests: `supabase/tests/*.test.sql` (67 files; 1,132 checks at the
  last full run, 15 Nov 2026).

## 7. Known gaps (see RSK-001)

- `org_id` present but unused by access rules (no shared-database tenancy).
- No documented database backup or tested restore.
- Column-level sensitivity isn't recorded in the schema (only in these
  documents and table design).
- 11 tables have RLS on with no policy (system-only by design; listed in
  SEC-002 appendix A).

## Change history

| Version | Date | Author | Change | Approved by |
|---|---|---|---|---|
| 0.1 | 16 Nov 2026 | Technical Lead (prepared by Claude) | First draft from migrations and the database catalogue | Not approved |
