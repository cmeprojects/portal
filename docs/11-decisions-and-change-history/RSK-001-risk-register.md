# RSK-001: Risk Register

| Field | Value |
|---|---|
| Document ID | RSK-001 (replaces the planned DEC-002 and SEC-006 in GOV-002) |
| Title | Risk Register |
| Category | 11 Decisions and change history (security risks also feed 04) |
| Version | 0.1 |
| Status | **Draft** |
| Owner / Reviewer / Approver | Product Owner / Security Reviewer (independent) / Product Owner, role holders not yet assigned |
| Created | 16 Nov 2026 |
| Last reviewed | TBC |
| Next review | Quarterly, and after any incident (GOV-001 §6) |
| Related | ARC-001, DB-001, MOD-001, SEC-002, DEC-001, AUD-010, AUD-016 |

**Rules used:** only risks with evidence in the repository or database are
recorded. **Likelihood and impact are TBC** unless evidence supports a
rating (no invented scores; a scoring method needs the owner's decision).
"Current controls" are only controls verified to exist. No remediation is
claimed without evidence. Responsible roles are roles, not people.

| ID | Risk | Affected area | Likelihood | Impact | Current controls (verified) | Remaining exposure | Recommended treatment | Responsible role | Status |
|---|---|---|---|---|---|---|---|---|---|
| RSK-01 | **Shared-database tenant isolation not implemented.** `org_id` exists on many tables but no RLS policy uses it. | Multi-tenant SaaS, all data | TBC (low today: one database per customer; becomes relevant if customers ever share a database) | TBC (would be high: cross-customer exposure) | Separate Supabase and Vercel project per customer; separate keys (ARC-002) | Any move to a shared database without `org_id` rules; operator error mixing keys | Decide the SaaS tenancy model; if shared, design and test `org_id` isolation before any second tenant joins a database | Product Owner; Technical Lead; Security Reviewer | Open |
| RSK-02 | **Database backup and restore not documented or tested.** Restore points cover code and undo files only. | All customer data; continuity | TBC | TBC | Undo files for every live update; code restore branches (docs/RESTORE.md); Supabase platform backups (plan-dependent, **not verified**) | Data loss or long outage without a known, tested recovery | Record each copy's Supabase backup settings; test a restore on a non-production copy; write OPS-001 | Technical Lead | Open |
| RSK-03 | **RLS documentation incomplete and unreviewed.** Current register just created (SEC-002); no independent review; combined effect per table not documented. | Security of all tables | TBC | TBC | RLS on all 93 tables; 1,132 database checks; Stage 1 evidence; round-trip tests | Wrong policy or definer function not noticed | Independent review of SEC-002 (C1, C2, C5 first); regenerate after each change | Security Reviewer; Technical Lead | Open |
| RSK-04 | **Hard-coded role checks (~180) and catalogue-only modules.** Four delegable modules (ops.tasks, people.staff, people.teams, clients.list) aren't read by any check. | Access control consistency | TBC | TBC | Role rules in pages and RLS; tests per area | Grants shown that have no effect; rules spread across many places; changes miss a place | Decide under the access model (AUD-016); meanwhile mark or hide non-effective grants (MOD-001 §6) | Technical Lead; Product Owner | Open |
| RSK-05 | **Broad SECURITY DEFINER surface.** 227 definer functions (bypass RLS), 50 executable by signed-out callers. | Database security | TBC | TBC | Fixed `search_path`; most are yes/no helpers or triggers; new definers need owner approval (D-004) | A definer function returning more than intended | Review the 50 anon-executable ones first; revoke where not needed (needs approval) | Security Reviewer; Technical Lead | Open |
| RSK-06 | **Function-based access model not implemented.** Fixed access levels; job titles carry no permissions; grants only to managers and staff admins. | Roles for case managers, intake, payroll, rostering, Allied Health | TBC | TBC | Permission engine with grants, scope, dates, pass-on; Manager Administrators | New business roles can't be given the right access without code; workarounds may over-grant | Approve and stage AUD-016 | Product Owner; Technical Lead | Open (awaiting decision D-030) |
| RSK-07 | **Sensitive client and (future) clinical information.** Client details, identifiers, emergency contacts, risk notes stored since updates 88 to 90; clinical records planned. | Privacy of clients | TBC | TBC (would be high) | People managers and system admin only for sensitive tables; team staff limited to basic record, approved locations and active alerts (tests: client_record, client_locations, client_care); change log without values | No privacy policy or data handling document (SEC-003); no retention rule for clients; clinical access model not built | Write SEC-003 with a qualified adviser; per-person access ticks for sensitive parts; assignment-based clinical access (AUD-016 §8) | Privacy / Legal Adviser; Product Owner | Open |
| RSK-08 | **Service key in server code.** 22 server files use the key that bypasses RLS. | Application security | TBC | TBC | Key only in server environment; used for named tasks (cron, invites, sign-in, delegation, contracts, reminders, assistant) | A server action using it without its own permission check | Review each use; record in SEC-002 | Security Reviewer; Technical Lead | Open |
| RSK-09 | **Third-party dependencies and integrations.** Supabase, Vercel, Anthropic (Assistant), Resend (email), 13 npm packages; data flows to Anthropic not documented. | Privacy, availability, licensing | TBC | TBC | Assistant behind a feature switch; email not configured on Dev; keys in environment variables | Personal data sent to an AI provider without a documented basis; licence obligations unknown; supplier outage | ARC-003 data flows, ARC-004 integration register, IP-002 licence register, privacy review of the Assistant | Technical Lead; Privacy / Legal Adviser | Open |
| RSK-10 | **Payroll data reads not enforced by the database.** Direct reads of bank details by people with access aren't logged; access log accepts self-written rows. | HR privacy | TBC | TBC | Explicit access needed (has_access); reveal logged by the app; TFN reveal separate tick | Unlogged reads by authorised people | Logged read function; database-side log writer (AUD-010 risks 2 and 3) | Technical Lead; Security Reviewer | Open |
| RSK-11 | **Records registers readable by every member.** | Data minimisation | TBC | TBC | Register types chosen by admins | Sensitive information put in a records register is visible to all staff | Review use; guidance or per-register visibility | Product Owner | Open |
| RSK-12 | **MFA off and email not configured on Dev.** Intentional (D-007). | Account security before go-live | TBC (Dev only today) | TBC | Owner decision; MFA switch exists; owner protection; sign-in failure limits (`sign_in_failures`) | Carrying the Dev setting into a live copy | Go-live checklist item: MFA enforcement and email set-up | Product Owner | Accepted for Dev; open for live |
| RSK-13 | **Release and environment records behind.** Version 0.1.1 covers updates 71 to 90; the hourly timer verified on Dev only. | Change control | TBC | TBC | Live-updates README records which copy has which update | Unclear what a copy runs; restore to a version harder | Decide versioning; record per-copy timer status | Technical Lead; Product Owner | Open |
| RSK-14 | **Formal reviews are developer-only so far.** All audits and reviews were prepared by the developer (an AI coding agent). | Assurance | TBC | TBC | Tests, round trips, evidence kept | Issues an independent or qualified reviewer would catch | Assign Security Reviewer and Privacy / Legal Adviser roles (GOV-001 §2) | Product Owner | Open |

## Change history

| Version | Date | Author | Change | Approved by |
|---|---|---|---|---|
| 0.1 | 16 Nov 2026 | Technical Lead (prepared by Claude) | First register, evidenced risks only | Not approved |
