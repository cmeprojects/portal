# DEC-001: Decision Register

| Field | Value |
|---|---|
| Document ID | DEC-001 |
| Title | Decision Register |
| Category | 11 Decisions and change history |
| Version | 0.1 |
| Status | **Draft** |
| Owner / Reviewer / Approver | Product Owner / Technical Lead / Product Owner |
| Created | 16 Nov 2026 |
| Last reviewed | TBC |
| Related | GOV-001, GOV-002, PRD-002, QA-005 |

Records product, technical and security decisions **made by the owner** (or
standing rules they set), with the source. Seeded only from decisions already
written in the repository or given by the owner in development sessions;
"Owner (session)" means the owner's instruction in a development session,
also reflected in the commit or document named. Nothing here is a legal,
clinical or independent security approval. New decisions are added at the
end with the next number.

## Standing rules

| ID | Date | Decision | Source |
|---|---|---|---|
| D-001 | Oct 2026 | One codebase; each company has its own Supabase project and website (no shared database). | docs/PLAN.md; docs/ENVIRONMENTS.md |
| D-002 | Nov 2026 | Work on the Development copy only; no production changes. The owner runs every live database update themselves; links are given, SQL isn't pasted in chat. | Owner (session); supabase/live-updates/README.md |
| D-003 | Nov 2026 | Every live update is safe to run twice, has an undo file, and is round-trip tested before it's offered. | Owner (session); docs/DEVELOPMENT-PROTOCOL.md |
| D-004 | Nov 2026 | No new SECURITY DEFINER functions without the owner's explicit approval; prefer INVOKER. | Owner (session) |
| D-005 | Nov 2026 | Credit-conservation and minimal-change rules; reuse what works; don't touch unrelated modules, permissions, RLS or database structures. | docs/DEVELOPMENT-PROTOCOL.md; owner (session) |
| D-006 | Nov 2026 | Performance stages 2 to 9 deferred until the build is finished; the completed Stage 1 RLS work is preserved. | Owner (session); docs/TODO.md |
| D-007 | 15 Nov 2026 | Email delivery and two-factor (MFA) are intentionally not configured on Dev; not defects. Email queue discrepancies deferred; MFA enforcement is a future production-readiness item. | Owner (session); AUD-009 |
| D-008 | Nov 2026 | Plain Australian English; AUD; Australia/Sydney time; commit messages start "cmeprojects:". | Owner (session) |
| D-009 | Oct 2026 | Vehicles: no odometer photos; readings typed only. | docs/PLAN.md |

## Product and access decisions

| ID | Date | Decision | Source |
|---|---|---|---|
| D-010 | Nov 2026 | The owner account can't be turned off, demoted, reset or signed out by anyone else (update 74). | supabase/live-updates/update-74.sql |
| D-011 | Nov 2026 | Manager Administrators: nominated managers who pass on access they hold (update 73); modules follow the Access page (updates 75 to 78), contracts one tick per ability. | Updates 73 to 78; PRD-013 |
| D-012 | 15 Nov 2026 | Onboarding: "complete" includes all seven items; a checked right to work is required before clearance; bank, super and TFN within 7 days with one reminder; clearance is never removed automatically (update 81). | Owner (session); AUD-009; update 81 |
| D-013 | 15 Nov 2026 | Managers can clear to work and give overrides (logged with notes and reasons). | AUD-009 section 3 |
| D-014 | 15 Nov 2026 | Incident and risk records can be saved with blank fields; required fields are enforced before completion. | AUD-009 section 3 |
| D-015 | 15 Nov 2026 | An escalation is raised once per missed due date (update 82). | Update 82 |
| D-016 | 15 Nov 2026 | Managers can act on tasks in registers with no named managers, such as General tasks (update 83). | Owner (session); update 83 |
| D-017 | 15 Nov 2026 | Team leaders see availability and work anniversaries only; emergency contacts behind a system admin switch (off by default); SECURITY DEFINER `team_private()` approved (update 84). | Owner (session); AUD-011 |
| D-018 | 15 Nov 2026 | A premium pack inside another pack (Compliance in HR Pack) has its own switch and doesn't turn on with the outer pack. | Owner (session); commit 990afb5 |
| D-019 | 15 Nov 2026 | HR order: Stage A (update 81, team leader privacy, timer) before Stage B (termination record, bank and super history); Client Management not delayed for lower-priority HR items. | Owner (session); AUD-012 |
| D-020 | 15 Nov 2026 | Client references `CL-00001`: sequential, made by the database, unique, permanent, never reused. | Owner (session); PRD-010 |
| D-021 | 15 Nov 2026 | Date of birth required for NDIS and Support at Home; for other programs only when needed; privacy-restricted. | Owner (session); PRD-010 |
| D-022 | 15 Nov 2026 | Programs list edited by the system admin; add or deactivate, never delete once used. | Owner (session); PRD-010 |
| D-023 | 15 Nov 2026 | Support workers see basic details, approved service locations and essential safety alerts for their own teams' clients only; enforced by RLS. | Owner (session); PRD-010 |
| D-024 | 15 Nov 2026 | Existing Dev clients: references in alphabetical order; statuses not all set to active (they start pending, to be checked). | Owner (session); PRD-010; AUD-013 |
| D-025 | 15 Nov 2026 | All six optional client sections stay in development scope; "optional" means each organisation chooses to switch them on. Core client information can't be switched off. | Owner (session); PRD-010 |
| D-026 | 15 Nov 2026 | Client steps 1 to 5 approved and run on Dev (updates 85 to 90), including the SECURITY DEFINER triggers `guard_client_record`, `guard_client_location`, `log_client_change` and the function `team_clients()`. | Owner (session); AUD-013 to AUD-015; live-updates README |
| D-027 | 15 Nov 2026 | Who sets up clients: managers, case managers and the system admin by default; Manager Administrators can delegate it. | Owner (session); PRD-014 |
| D-028 | 16 Nov 2026 | New business roles wanted: case manager (not a centre manager), intake and assessment officer, payroll, rostering. Design pending (see D-030). | Owner (session); PRD-014 |
| D-029 | 16 Nov 2026 | Clients & Care paused; the plan is kept (docs/TODO.md "ON HOLD"). | Owner (session) |
| D-030 | 16 Nov 2026 | Function-based access model requested (Organisation → Function Groups → Roles → Individual access); Stage 1 assessment only, **awaiting approval**. | Owner (session); AUD-016 |
| D-031 | 16 Nov 2026 | Documentation governance framework requested (this register, GOV-001 to GOV-003); documentation only. | Owner (session); GOV-001 |
| D-032 | 16 Nov 2026 | Five code-verifiable foundational documents requested with the IDs ARC-001, DB-001, MOD-001, SEC-002, RSK-001 (MOD and RSK prefixes added to GOV-001). Documentation only. | Owner (session); GOV-002 v0.2 |

## Change history

| Version | Date | Author | Change | Approved by |
|---|---|---|---|---|
| 0.1 | 16 Nov 2026 | Technical Lead (prepared by Claude) | Seeded from recorded decisions | Not approved |
