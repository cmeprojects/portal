# HR Pack completeness and readiness (cmeprojects)

Review only, 15 Nov 2026, version 0.1.1 (updates to 82 written; Dev has
run to 80). Evidence comes from the database schema, policies and functions
on the local copy, the code, the existing tests (about 1,046 checks) and the
earlier HR and onboarding reports (docs/audit/2026-11-hr-release.md,
2026-11-onboarding.md). Nothing was changed. Email and MFA are excluded, as
agreed.

## 1. Overall assessment: **Substantially complete**

HR Pack is a reliable foundation for **staff identity, onboarding,
compliance, clearance to work and private records**. There's one employee
record (the profile) with satellite tables keyed by the same person ID, a
single credentials system (onboarding items and records) with expiry and
verification, and a clearance check other modules can call. Permissions sit
in the database (RLS and guards), with tests.

It isn't "Complete" because:
- one verified privacy gap: team leaders can read more private detail than
  intended;
- the employment lifecycle is thin (no termination date or reason, and no
  direct "reports to");
- old values of bank and super changes aren't kept;
- expiry reminders depend on the hourly timer, which isn't set up on Dev
  (not verified there);
- update 81 (onboarding rules) isn't run on Dev yet.

## 2. Completeness matrix

| Area | Current implementation | Status | Evidence | Missing or incomplete | Recommendation |
|---|---|---|---|---|---|
| **A. Employee master record** | `profiles` (name, email, role, team, job title, active, joined, deactivated, onboarded, cleared). `staff_directory` (preferred name, department, work phone, skills). `staff_private` (address, emergency contact, start date, employment type, employee ID, availability). `staff_birthdays` (day and month). Photo (`avatar_ref`). | Partial | Schema; hr_profiles and staff_photos tests | No full **date of birth** (day and month only). No **termination date or reason** (only `deactivated_at`). No direct **reports-to** (only team leaders by team). Legal name is a single `full_name`. History is only in the change log. | Add a termination date and reason. Decide whether a full DOB is needed (screening and payroll usually need it). "Reports to" is optional: team leaders may be enough. |
| **B. Employment documents** | Contracts (versions, supersede, letterhead, employee and employer signatures, content hash, signed PDF). Policies and agreements as onboarding items (`read`, `agreement`) with versions and acknowledgements (`compliance_item_versions`, `compliance_opens`). Uploads with issue and expiry dates. | Substantially complete | contracts (13), step4_contracts, compliance (27) tests | **Position descriptions** have no type of their own (they can be a `read` item targeted by job title). No general "staff document" store for ad-hoc files (warnings, letters). | Use a `read` item per job title for position descriptions (no build). An ad-hoc document store is a later phase. |
| **C. Qualifications, licences, screening** | Onboarding items with certificate, issue date, number, expiry and evidence. Targeted by role, team, job title or person. Statuses: to do, submitted, accepted, rejected, expiring, expired. Checking by compliance managers. Replacement requests. History of records per person. Expiry list and Compliance report. | Complete (reminders not verified) | compliance and onboarding_clearance (34) tests; `compliance_status` and `run_compliance_alerts` functions | Expiry **reminders** need the hourly timer (not running on Dev). No **credential type code** (items are named by the company, for example "First Aid"), which rostering will need to match. | Set up the timer on Dev, then verify the reminders. For rostering, map items to a requirement code later (no second copy). |
| **D. Onboarding and clearance** | Account set-up, My onboarding sections, checklist, profile completion, pay and work rights, TFN form, contract signing, before-work items, clearance with who, when and note, overrides with reason and end date, return for correction (reject or replacement), and the three-part status (update 81). | Complete (once update 81 is run) | onboarding_clearance, onboarding_stage_b (13), profile_requirement tests; browser tests | Update 81 isn't run on Dev. Reminders depend on the timer. | Run update 81 and set up the timer. |
| **E. Lifecycle** | Role, team and job title changes (with change-request approval where set). Leave via requests (`leave_periods`). Deactivate and reactivate. Credential renewals. Records are kept after leaving (retention setting). | Partial | role_change_ownership, my_requests tests | No termination record (date, reason, final day). No performance or probation records. No contract-change prompt on a role change. | Termination date and reason now (small). Probation and performance are later. |
| **F. Self-service and admin** | Staff edit contact, skills, private details, availability, pay records and TFN upload, and see status. Office-controlled: legal name, role, team, employment details, clearance. | Complete | hr_profiles tests; `guard_profile_update`; staff_private and records policies | None found | None |
| **G. Permissions and privacy** | RLS on every HR table. Pay, identity and TFN need explicit access (Access page), with TFN revealing as its own tick. Per-person folders in the file stores. Contracts per tick. Owner protection. | Partial | Policies read on the local copy; staff_records (20), tfn (11), access tests | **Verified:** team leaders can read the whole `staff_private` row of their team (address, emergency contact, employee ID, type, start date), although screens show only availability. Potential risks below. | Limit team leaders to availability (and possibly emergency contact). See section 4. |
| **H. Audit and integrity** | `audit_log` covers role, team, name, profile saves, deactivation, onboarding accept and reject, clearance, overrides and access changes. `sensitive_access_log` covers views, downloads, changes, checks and deletions of pay, identity and TFN records. One profile per sign-in; satellite tables are one row per person. | Partial | Triggers and policies; change log page | Old **values** of bank and super changes aren't kept (only who and when). "Profile updated" doesn't say which field. Viewing is logged by the portal's buttons, not by the database. | Keep previous bank and super values (small). Name the changed fields in the log. |

## 3. Data architecture

- **Authoritative employee record:** `public.profiles` (one per sign-in;
  `id` = the person). Everything else references `profiles.id`.
- **HR tables and purpose:**
  - `staff_directory`: work-facing details
  - `staff_private`: private and employment details and availability
  - `staff_birthdays`
  - `staff_bank`, `staff_super`, `staff_work_rights`, `staff_tax`: payroll
    and identity, each with explicit access
  - `compliance_items`, `compliance_item_versions`, `compliance_records`,
    `compliance_opens`, `compliance_alerts`: credentials, policies,
    training and agreements, and their history
  - `work_overrides`: work before clearance
  - `contracts`, `contract_signatures`
  - `teams`, `team_members`, `team_leaders`, `job_titles`
  - `requests`, `leave_periods`: leave and other staff requests
  - `people_change_requests`: role and team approvals
  - `access_grants`, `admin_designations`: who administers what
  - `audit_log`, `sensitive_access_log`
- **Duplicates or conflicts:** none in data. One overlap in meaning: "start
  date" is in `staff_private`, and `profiles.joined_at` is the account
  set-up date (they're different things, and the labels say so). The
  onboarding status had two definitions before update 81; update 81 aligns
  them.
- **What future modules should reference (not copy):** `profiles.id`,
  `profiles.role` and `active`, `team_members`, `job_titles`, `can_work()`,
  `compliance_status()` (current state of each credential),
  `staff_private.availability`, `leave_periods`.

## 4. Security and access

**Verified defect**
1. **Team leaders read full private rows.** The `staff_private` read rule
   lets a team leader read every column for their team members (address,
   emergency contact, employee ID, employment type, start date). The screens
   show only availability. Recommended: give team leaders availability (and,
   if wanted, the emergency contact) through a narrow view or function, not
   the whole row.

**Potential risks (need a decision or a test, not confirmed faults)**
2. **Viewing isn't enforced by the database.** People with payroll access
   can read the bank account straight from the table; the "reveal" button
   logs a view, a direct read doesn't. A database-level read-and-log function
   would close it.
3. **The access log accepts self-written rows.** Any member can add rows
   naming themselves as the actor (they can't fake someone else). That's low
   risk, but a database-side writer would be cleaner.
4. **Managers can upload into anyone's onboarding folder** (intended: "upload
   for them"), but can't read it. That's fine, if intended.
5. **Not verified here:** the Excel exports of the Compliance report respect
   the same rules as the screens (the code uses the user's own session, so
   RLS applies, but no export test exists).

Secure, with evidence: pay, identity and TFN tables and files need explicit
access; TFN revealing is its own tick; contracts follow their ticks; the
owner can't be removed; signed-out users get nothing (tests).

## 5. Priority gaps

**Critical** (before relying on HR Pack)
- Run **update 81** on Dev. Without it, "onboarding complete" and
  clearance don't follow the agreed rules.
- Fix the **team leader private-details** access. It's a privacy defect.

**High** (safe and complete HR operations)
- **Hourly timer on Dev**, then verify the expiry and onboarding reminders.
- **Termination record** (date, reason, last day) alongside deactivation.
  Rostering and payroll need the last working day.
- **Keep previous bank and super values** (who changed what, from and to).
  This is payroll fraud protection.

**Medium** (mature HR Pack)
- Name the changed fields in "profile updated" log entries.
- Read bank details through a logged database function (risk 2).
- Full date of birth, if screening and payroll need it.
- Position descriptions as job-title-targeted `read` items (set-up only).

**Future** (don't delay the next module)
- Ad-hoc staff document store (letters, warnings).
- Probation and performance reviews; recurring re-confirmations.
- Direct "reports to"; leave balances.
- Credential requirement codes for rostering eligibility (build with
  rostering).

## 6. Recommended completion plan (smallest sequence)

1. **Run update 81 and set up the timer** (owner, Dev). Reuses the existing
   functions. Test: My onboarding three parts, clearance needs a checked right
   to work, the reminder after 7 days, expiry reminders.
2. **Team leaders: availability only.** Narrow the `staff_private` read rule
   (team leaders removed), plus a small read-only function returning
   availability (and the emergency contact, if you want) for a leader's team.
   It touches one policy, so it's checked against the Stage 1 register and
   kept in that format. Test: a team leader can't select the address but sees
   availability; managers and staff admins are unchanged.
3. **Termination record.** Add the last working day and reason with
   deactivation (two columns on `staff_private` or a small table; the
   existing deactivate action fills them; logged). Test: deactivate with a
   reason, it shows on the person, and reactivating keeps the history.
4. **Bank and super history.** Extend the existing guard trigger to write the
   previous values (masked account number) into `sensitive_access_log.detail`
   on change. No new table. Test: a change records from and to (masked); only
   the system admin reads it.
5. *(Optional, Medium)* Field names in "profile updated" entries; logged read
   of bank details.

Each step is a small live update with undo, a round trip and tests, as
usual.

## 7. Readiness for Client Management

**Ready to start Client Management in parallel**, as long as steps 1 and 2
are done first or alongside. Client Management needs the staff identity,
teams and roles, which are stable. It doesn't need termination or bank
history.

**Before Care Operations Rostering:** steps 1 to 3, plus the credential
requirement codes (built with rostering). Rostering should call `can_work()`
and `compliance_status()` and read `staff_private.availability` and
`leave_periods`, with no second copy of credentials or availability.
