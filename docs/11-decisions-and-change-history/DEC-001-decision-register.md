# DEC-001: Decision Register

| Field | Value |
|---|---|
| Document ID | DEC-001 |
| Title | Decision Register |
| Category | 11 Decisions and change history |
| Version | 0.6 |
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
| D-009 | 27 Oct 2026 | Vehicles: no odometer photos; readings typed only. **Still the intended decision (D-037); the build conflicts with it (AUD-018).** | docs/PLAN.md (commit 698c31e) |

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


## Decisions of 16 Nov 2026 (after the foundational documents)

| ID | Date | Decision | Source |
|---|---|---|---|
| D-033 | 16 Nov 2026 | Responsibility roles: Product Owner = the owner; Technical Lead = the owner; independent Security Reviewer = to be appointed externally (unassigned); Privacy / Legal Adviser = to be appointed externally (unassigned); Provider Subject Matter Reviewer = relevant provider representative or qualified professional per document. The owner's reviews aren't independent security, legal or clinical approval. | Owner (session) |
| D-034 | 16 Nov 2026 | GOV-001 approved as the initial documentation governance framework (version 1.0), with provisional assignments and outstanding reviews recorded. All other documents stay Draft until their required reviews. | Owner (session) |
| D-035 | 16 Nov 2026 | Risk scoring: 5 × 5 likelihood and impact matrix with inherent and residual ratings, existing controls, risk owner, treatment, target date and review date. No scores without evidence or an agreed rationale; TBC otherwise. | Owner (session); RSK-001 v0.2 |
| D-036 | 16 Nov 2026 | The four modules with ineffective grants (Tasks, Staff, Teams, Clients): keep the modules and current permission behaviour; temporarily disable or clearly mark their unsupported delegation controls so administrators aren't misled; known limitation; part of the function-based access model. The control change itself needs a separate implementation approval. | Owner (session); MOD-001; RSK-04 |
| D-037 | 16 Nov 2026 | Odometer photos: D-009 remains the intended decision unless evidence shows a change. Investigate (done: AUD-018); recommend disabling uploads if not approved; no file deletion or change without separate approval. | Owner (session); AUD-018 |
| D-038 | 16 Nov 2026 | SaaS tenancy: keep one separate database per customer. Don't implement shared-database tenancy or redesign. Shared-database tenancy is a possible future option needing a separate architecture and security assessment. `org_id` is **not** an enforced security boundary. | Owner (session); ARC-001; RSK-01 |

| D-039 | 16 Nov 2026 | D-009 confirmed (no replacing decision). Approved as two separate actions: set "Odometer photo when returning" to Off on each applicable copy; prepare a separate storage-policy update preventing uploads when not approved. Plans first; no file deletion or customer data change (QA-008). | Owner (session) |
| D-040 | 16 Nov 2026 | Approved a limited Access page code change so Tasks, Staff, Teams and Clients don't present unsupported delegation as working; modules, functionality and the permission engine unchanged; plan first (QA-007). | Owner (session) |
| D-041 | 16 Nov 2026 | Risk ratings, owners and dates stay TBC until a separate assessment session; external reviewers stay unassigned; independent security and professional reviews required before live customer data; AUD-016 and Clients & Care stay open and paused. | Owner (session) |

| D-042 | 16 Nov 2026 | QA-007 approved and extended to seven modules (Tasks, Staff, Teams, Clients, Staff requests, Due dates and escalation, Request approvals): remove unsupported controls, refuse new or changed grants on the server, "Set by role" only where confirmed role-based, otherwise "Not available"; keep existing grants; no engine, database or RLS change; correct the module catalogue. QA-008 approved with the storage policy following the setting (Off: refused; Optional and Required: allowed); A1, A2 and B separate, each with tests and rollback. Order: QA-007; owner sets the setting Off on Dev and Demo; A2; B on Dev, then Demo. Local incident recorded (AUD-019), no further action. | Owner (session) |

| D-043 | 16 Nov 2026 | Vercel Function Storage reached the free limit (10 GB). Stop Vercel building the restore branches (`version-*`, `restore-*`; they stay in Git for restoring) via `vercel.json`, and push fewer, larger commits. Vercel Pro to be decided in go-live planning. | Owner (session) |

| D-044 | 16 Nov 2026 | Standing rule: every piece of work updates the documents as it goes (decision register, the relevant plan or record, the register, and the "Where we are now" section in docs/HANDOVER.md), so nothing is lost if the conversation context is refreshed. | Owner (session) |

| D-045 | 16 Nov 2026 | Function-based access model approved in principle; one final focused clarification before Stage 1 (added to AUD-016). Stages: 1 Function Groups; 2 title-to-function mapping; 3 function and title grants in the existing engine; 4 module mapping and registration rules; 5 Client Management and assigned-client access; 6 later (multiple titles, program scope, Allied Health). Each stage its own migration, tests, rollback and report; behaviour unchanged until each is approved and verified. Suggested ratings for five risks only. Efficiency: reuse findings, update existing registers, smallest safe change, no scope growth. | Owner (session) |

| D-046 | 16 Nov 2026 | "Go ahead with all 3": (1) AUD-016 final clarification and the Stage 1 approach approved: build Stage 1 (Function Groups, live update 92; SQL reviewed by the owner before it runs on Dev); (2) the six suggested risk ratings approved as written (RSK-001 §3); (3) Next.js upgrade approved as its own change. | Owner (session) |

| D-047 | 17 Nov 2026 | **No band-aid: option 3 is the plan** for function-based access. Every module will ask one permission check (`can()`); today's role rules become **default grants per access level**, so nobody's access changes when a module switches over; the old side-by-side role logic is removed module by module. Stage 3 = grants table (holders: person [existing], job title, function group, access level), precedence person → job title → function group → access-level default, the Access page screens, and default grants seeded to reproduce today's rules. Stage 3b onwards = convert each module to use only `can()`, one at a time (each: its own update, tests, before/after comparison proving no access change, undo, Stage 1 speed check on changed policies). Option 1 (widening the person-only gates) is **not** used. Owner asked that this is noted in the handover. | Owner (session) |
| D-048 | 17 Nov 2026 | **Manager Administrators set role and group access within their own authority.** They can give a function group or job title access only to parts they hold with "may pass on", and only the actions they hold; their grants stop counting if they stop being a Manager Administrator; they revoke only what they gave. **Access-level defaults stay with the system admin only.** The system admin keeps full power. Added to update 94 before it was run. | Owner (session) |
| D-049 | 17 Nov 2026 | **Option A for module switch-overs:** the Access page's access-level defaults replace the "who manages" System settings. At each switch-over today's setting values are copied once into defaults; the old setting stays in the database but is no longer used or shown. Built-in fallbacks (for example "managers manage onboarding while there's no staff admin") are settled once at switch-over; a fresh install starts least-privilege (staff admins only for onboarding). Applies to every module with a "who manages" setting (cars, forms and so on). | Owner (session) |
| D-050 | 17 Nov 2026 | **No per-level ceiling (option A).** For parts switched to the one check, a job title or function group grant may give access beyond what the access level gives by default; control is by who can grant (system admin; Manager Administrators within what they hold). Hard limits kept: protected parts, new starters and externals inherit nothing, sensitive never via a group, staff records and settings areas keep their own rules. **External titles belong to Allied Health** (confirmed); new external roles such as Behavioural Therapist or Psychologist are created under it. | Owner (session) |

## Change history

| Version | Date | Author | Change | Approved by |
|---|---|---|---|---|
| 0.1 | 16 Nov 2026 | Technical Lead (prepared by Claude) | Seeded from recorded decisions | Not approved |
| 0.2 | 16 Nov 2026 | Technical Lead (prepared by Claude) | D-033 to D-038 added; D-009 note | Not approved |
| 0.3 | 16 Nov 2026 | Technical Lead (prepared by Claude) | D-039 to D-041 | Not approved |
| 0.4 | 16 Nov 2026 | Technical Lead (prepared by Claude) | D-042 | Not approved |
| 0.5 | 16 Nov 2026 | Technical Lead (prepared by Claude) | D-043 | Not approved |
| 0.6 | 17 Nov 2026 | Technical Lead (prepared by Claude) | D-044 to D-050 | Not approved |
