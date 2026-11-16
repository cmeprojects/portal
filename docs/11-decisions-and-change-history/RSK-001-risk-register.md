# RSK-001: Risk Register

| Field | Value |
|---|---|
| Document ID | RSK-001 (replaces the planned DEC-002 and SEC-006 in GOV-002) |
| Title | Risk Register |
| Category | 11 Decisions and change history (security risks also feed 04) |
| Version | 0.4 |
| Status | **Draft** (needs the independent Security Reviewer, not yet appointed) |
| Owner | Product Owner: the owner |
| Reviewer | Security Reviewer (independent): **unassigned, to be appointed externally** |
| Approver | Product Owner |
| Created | 16 Nov 2026 |
| Last reviewed | TBC |
| Next review | Quarterly, and after any incident (GOV-001 §6) |
| Related | ARC-001, DB-001, MOD-001, SEC-002, DEC-001 (D-035), AUD-010, AUD-016, AUD-018 |

## 1. Method (adopted by the owner, D-035)

**5 × 5 matrix.** Rating = Likelihood × Impact (1 to 25).

| Likelihood | 1 Rare | 2 Unlikely | 3 Possible | 4 Likely | 5 Almost certain |
|---|---|---|---|---|---|
| **Impact** | **1 Minimal** | **2 Minor** | **3 Moderate** | **4 Major** | **5 Severe** |

| Rating | Band |
|---|---|
| 1 to 4 | Low |
| 5 to 9 | Medium |
| 10 to 16 | High |
| 20 to 25 | Extreme |

- **Inherent** = before current controls; **residual** = with the current
  controls verified to exist.
- **A score is given only with evidence or an agreed assessment rationale**,
  written next to it. Otherwise **TBC**. Target and review dates are **TBC**
  until the owner sets them.
- Controls listed are only those verified in the code or database.
- Risk owner = the accountable role (the owner holds Product Owner and
  Technical Lead; the external reviewers are unassigned).

**Current state:** no risk has an agreed assessment rationale yet, so every
rating below is **TBC**.

## 2. Register

| ID | Risk | Area | Inherent L×I | Existing controls (verified) | Residual L×I | Risk owner | Treatment | Target date | Review date | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| RSK-01 | **Shared-database tenant isolation not implemented; `org_id` is not an enforced security boundary.** | Multi-tenant SaaS, all data | TBC | **Decision D-038: separate database per customer retained**; separate Supabase and Vercel projects and keys per customer (ARC-002) | TBC | Product Owner | Keep the current model. Shared-database tenancy only after a separate architecture and security assessment. Never treat `org_id` as isolation | TBC | TBC | Open (accepted model; future option recorded) |
| RSK-02 | **Database backup and restore not documented or tested.** | All customer data; continuity | TBC | Undo files for every live update; code restore branches (docs/RESTORE.md). Supabase platform backups: **not verified** | TBC | Technical Lead | Record each copy's backup settings; test a restore on a non-production copy; write OPS-001 | TBC | TBC | Open |
| RSK-03 | **RLS documentation incomplete and not independently reviewed.** | Security of all tables | TBC | RLS on all 93 tables; 1,132 database checks (15 Nov 2026); Stage 1 evidence; round trips; current register SEC-002 | TBC | Technical Lead (reviewer unassigned) | Independent review of SEC-002 (C1, C2, C5 first); regenerate after each change | TBC | TBC | Open |
| RSK-04 | **Hard-coded role checks (~180); seven delegable modules whose grants have no effect** (Tasks, Staff, Teams, Clients, Staff requests, Due dates and escalation, Request approvals). | Access control | TBC | Role rules in pages and RLS; tests per area; **since QA-007 (16 Nov 2026): Access page shows them as set by role / not available with no switch, and the server refuses new or changed grants** | TBC | Technical Lead | **D-036 / D-040:** modules and permission behaviour kept; misleading controls removed (done, QA-007); fix properly in the function-based access model | TBC | TBC | Open (known limitation; interim control in place) |
| RSK-05 | **Broad SECURITY DEFINER surface:** 227 functions bypass RLS; 50 callable by signed-out callers. | Database security | TBC | Fixed `search_path`; mostly yes/no helpers and triggers; new definers need owner approval (D-004) | TBC | Technical Lead (reviewer unassigned) | Review the 50 first; revoke where not needed (separate approval) | TBC | TBC | Open |
| RSK-06 | **Function-based access model not implemented.** | New roles, Allied Health | TBC | Permission engine with grants, scope, dates, pass-on; Manager Administrators | TBC | Product Owner | Approve and stage AUD-016 (D-030) | TBC | TBC | Open (awaiting decision) |
| RSK-07 | **Sensitive client and future clinical information.** | Client privacy | TBC | Sensitive client tables limited to people managers and the system admin; team staff limited to the basic record, approved locations and active alerts (tests: client_record, client_locations, client_care); change log without values | TBC | Product Owner (Privacy / Legal Adviser unassigned) | SEC-003 with a qualified adviser; client retention rule; per-person ticks for sensitive parts; assignment-based clinical access | TBC | TBC | Open |
| RSK-08 | **Service key in 22 server files** (bypasses RLS). | Application security | TBC | Key only in the server environment, used for named tasks | TBC | Technical Lead (reviewer unassigned) | Review each use; record in SEC-002 | TBC | TBC | Open |
| RSK-09 | **Third-party dependencies and integrations;** data flows to Anthropic undocumented. | Privacy, availability, licensing | TBC | Assistant behind a switch; email not configured on Dev; keys in environment variables | TBC | Technical Lead (Privacy / Legal Adviser unassigned) | ARC-003, ARC-004, IP-002; privacy review of the Assistant | TBC | TBC | Open |
| RSK-10 | **Payroll reads not enforced by the database;** access log accepts self-written rows. | HR privacy | TBC | Explicit access (`has_access`); app logs reveals; TFN reveal separate | TBC | Technical Lead | Logged read function; database-side log writer (AUD-010) | TBC | TBC | Open |
| RSK-11 | **Records registers readable by every member.** | Data minimisation | TBC | Register types chosen by admins | TBC | Product Owner | Review use; guidance or per-register visibility | TBC | TBC | Open |
| RSK-12 | **MFA off and email not configured on Dev** (D-007). | Account security at go-live | TBC | MFA switch; owner protection; `sign_in_failures` table (sign-in limit; behaviour not re-verified here) | TBC | Product Owner | Go-live checklist: MFA enforcement and email | TBC | TBC | Accepted for Dev; open for live |
| RSK-13 | **Release and environment records behind** (0.1.1 covers updates 71 to 90; timer verified on Dev only). | Change control | TBC | Live-updates README records each copy's updates | TBC | Technical Lead | Decide versioning; record timer status per copy | TBC | TBC | Open |
| RSK-14 | **No independent, legal or clinical review yet.** Reviews so far are by the developer and the owner; the external Security Reviewer and Privacy / Legal Adviser are unassigned. | Assurance | TBC | Tests, round trips, evidence kept; GOV-001 forbids presenting these as independent approval | TBC | Product Owner | Appoint the external reviewers (D-033) | TBC | TBC | Open |
| RSK-15 | **Odometer photo uploads conflict with decision D-009.** Implemented as a setting (default Optional); the storage policy allows uploads to the driver's own folder whatever the setting. | Cars; data minimisation | TBC | Uploads limited to the driver's own folder; reading limited to the driver and car report holders; setting can be Off | TBC | Product Owner | AUD-018: if D-009 stands, set the setting to Off on each copy, then (separate approval) remove or narrow the upload policy; keep existing files | TBC | TBC | **Treated on Dev (16 Nov 2026):** setting Off, fresh installs Off, database refuses uploads while Off (update 91, verified) |
| RSK-16 | **Hosting plan limits.** Vercel free plan Function Storage reached 10 GB (16 Nov 2026); older deployments are deleted automatically. The free plan may not suit commercial use (Vercel's terms to be checked). | Hosting, go-live | TBC | Restore points are Git branches, not Vercel deployments; data is in Supabase; restore branches no longer built (D-043) | TBC | Product Owner | Decide Vercel Pro in go-live planning; keep pushes fewer and larger | TBC | TBC | Open |
| RSK-17 | **Next.js version with a known security vulnerability.** The build of 16 Nov 2026 warned that Next.js 16.4.3 is affected and recommended upgrading (details not shown in the warning). | Application security | TBC | Build still completes; RLS and server checks unchanged | TBC | Technical Lead | Upgrade Next.js as its own approved change (dependency update, full tests, Dev first) | TBC | TBC | Open (owner decision needed) |

## 3. Suggested ratings for the five priority risks (16 Nov 2026)

**SUGGESTED by the developer, NOT owner-approved.** They become approved
only when the owner agrees each one (recorded in DEC-001). All other risks
stay TBC. Scale: L = likelihood, I = impact (1 to 5); rating = L × I.

| Risk | Suggested inherent L×I | Suggested residual L×I | Rationale and evidence | Blocks Stage 1? |
|---|---|---|---|---|
| RSK-02 Backup and restore | 3 × 5 = **15 High** | 3 × 5 = **15 High** | Data loss would be severe (all customer data). No documented or tested database backup or restore (docs/RESTORE.md covers code and undo files only); Supabase backup settings not verified, so controls don't lower the rating yet. | No (Stage 1 adds a small table with an undo) |
| RSK-03 RLS not independently reviewed | 3 × 5 = **15 High** | 2 × 5 = **10 High** | RLS on all 93 tables, 1,134 database checks, Stage 1 evidence and round trips lower likelihood; impact of a wrong policy stays severe; no independent review yet. | No (Stage 1 policies are simple and tested) |
| RSK-05 Elevated (SECURITY DEFINER) functions | 3 × 5 = **15 High** | 2 × 5 = **10 High** | 227 definer functions bypass RLS; 50 callable by signed-out users (mostly yes/no helpers and triggers that return false or can't be called directly); fixed search_path; new definers need approval (D-004). Not reviewed one by one. | No (Stage 1 adds none) |
| RSK-07 Sensitive client data | 3 × 5 = **15 High** | 2 × 5 = **10 High** on Dev (test data only) | Client details, contacts and risk notes limited to people managers; staff limited by RLS (tests client_record, client_locations, client_care). No privacy document, retention rule or external review: residual would be higher with real data. | No |
| RSK-08 Service-role key usage | 3 × 5 = **15 High** | 2 × 5 = **10 High** | Key bypasses RLS; used in 22 server files for named tasks, server environment only; each use not yet reviewed against its own permission check. | No (Stage 1 doesn't use it) |
| RSK-14 No independent security review | 4 × 4 = **16 High** | 4 × 4 = **16 High** | All reviews so far are by the developer and the owner (GOV-001 forbids presenting them as independent); no control yet lowers it. Required before live customer data. | No |

No finding above shows a direct security or data-integrity risk to Stage 1.

## Change history

| Version | Date | Author | Change | Approved by |
|---|---|---|---|---|
| 0.1 | 16 Nov 2026 | Technical Lead (prepared by Claude) | First register, evidenced risks only | Not approved |
| 0.4 | 16 Nov 2026 | Technical Lead (prepared by Claude) | Suggested (not approved) ratings for RSK-02, 03, 05, 07, 08, 14; RSK-17 | Not approved |
| 0.3 | 16 Nov 2026 | Technical Lead (prepared by Claude) | RSK-16 hosting plan limits; RSK-04 interim control | Not approved |
| 0.2 | 16 Nov 2026 | Technical Lead (prepared by Claude) | 5 × 5 method (D-035); inherent and residual ratings, risk owner, treatment, target and review dates (all TBC); owner decisions D-036 to D-038 recorded; RSK-15 added | Not approved |
