# GOV-002: Documentation Register

| Field | Value |
|---|---|
| Document ID | GOV-002 |
| Title | Documentation Register (master) |
| Category | 00 Governance |
| Version | 0.4 |
| Status | **Draft** |
| Owner | Product Owner (not yet assigned) |
| Reviewer / Approver | Technical Lead / Product Owner |
| Created | 16 Nov 2026 |
| Last reviewed | TBC |
| Related | GOV-001, GOV-003, DEC-001 |

## How to read this

- **Exists:** Yes (the document exists at the path), Partial (information
  exists but is spread out or incomplete; sources named), No (to be written).
- **Priority:** **Now** (needed for current development), **Before live**
  (before live customer onboarding), **Future** (optional or later).
  ★ = one of the ten foundational documents (GOV-003 section 6).
- **Owner / Reviewer / Approver:** roles, from GOV-001 section 5. Holders
  (D-033): Product Owner and Technical Lead = **the owner**; independent
  Security Reviewer and Privacy / Legal Adviser = **unassigned (external)**;
  Provider Subject Matter Reviewer = chosen per document. A document needing
  an unassigned reviewer stays Draft.
- **Version / Status:** existing documents are "unversioned (git)" and
  **Draft**: none has a recorded approval, so none is Approved. Audit and
  review reports are **Evidence** (kept unchanged).
- **Last reviewed / Next review:** **TBC** for every document (no recorded
  reviews). Review triggers: GOV-001 section 6.
- Abbreviations: PO Product Owner, TL Technical Lead, SR Security Reviewer
  (independent), PL Privacy / Legal Adviser (qualified), SME Provider Subject
  Matter Reviewer, CR qualified Clinical / Allied Health Reviewer.

## 00 Governance

| ID | Name | Purpose | Owner / Reviewer / Approver | Exists | Priority | Status | Path | Related |
|---|---|---|---|---|---|---|---|---|
| GOV-001 | Documentation Governance Framework | How documents are owned, reviewed, approved, versioned | PO / TL / PO | Yes | Now | **Approved 1.0** (16 Nov 2026, Product Owner; D-034) | docs/00-governance/GOV-001-documentation-governance-framework.md | GOV-002, GOV-003 |
| GOV-002 | Documentation Register | This register | PO / TL / PO | Yes | Now | Draft 0.1 | docs/00-governance/GOV-002-documentation-register.md | all |
| GOV-003 | Existing Documentation Assessment | What exists, what to update, retain, archive; what's missing | TL / PO / PO | Yes | Now | Draft 0.1 | docs/00-governance/GOV-003-existing-documentation-assessment.md | GOV-002 |
| GOV-004 | Handover (working notes) | Running summary of everything built, for anyone picking up the work | TL / PO / — | Yes | Now | Draft (living) | docs/HANDOVER.md | DEC-001, QA-005 |
| GOV-005 | Open items list (temporary) | Items waiting on the owner; delete when done | TL / PO / — | Yes | Now | Temporary | docs/review/TEMP-to-review.md | — |
| GOV-007 | Documentation generator | Read-only tool that writes the generated appendices of DB-001, MOD-001 and SEC-002 from the database definitions | TL / TL / PO | Yes | Now | Tool | docs/tools/generate-from-database.py | DB-001, MOD-001, SEC-002 |
| GOV-006 | Agent instructions | Repository rules for coding agents (Next.js version notice) | TL / TL / PO | Yes | Now | Draft | AGENTS.md (no CLAUDE.md in this repository) | QA-001 |

## 01 Product

| ID | Name | Purpose | Owner / Reviewer / Approver | Exists | Priority | Status | Path | Related |
|---|---|---|---|---|---|---|---|---|
| PRD-001 ★ | Product Overview and Scope | What the platform is, for whom, what's in and out of scope | PO / SME / PO | Partial: README.md, BUSINESS-NOTES.md, PLAN.md | Now | — | To write | PRD-002, ARC-001 |
| PRD-002 | Product Roadmap | What's next and what's paused | PO / SME / PO | Partial: docs/TODO.md (living), PLAN.md milestones (outdated) | Now | Draft | docs/TODO.md | DEC-001 |
| PRD-003 | Requirements Register | Agreed requirements with status (proposed / built / verified) | PO / SME / PO | No (requirements are in owner briefs and plans) | Before live | — | To write | PRD-010 to PRD-014 |
| PRD-004 ★ | Function Groups, Roles and Permissions Matrix | Who can do what, by function group, role and access level | PO / SR / PO | Partial: src/lib/roles.ts (role help), AUD-016 | Now | — | To write | IAM-001, MOD-001 |
| MOD-001 ★ | Module Catalogue (was PRD-005) | Every module: parent, category, actions, sensitivity, delegable, switches, how access is decided, limitations | TL / PO / PO | Yes (+ generated appendix A) | Now | Draft 0.1 | docs/01-product/MOD-001-module-catalogue.md | PRD-004, IAM-001, SEC-002 |
| PRD-006 | Premium Features | Which features are premium | PO / TL / PO | Yes | Now | Draft | docs/PREMIUM-FEATURES.md | COM-007 |
| PRD-010 | Client Management foundation plan | Clients & Care design and owner decisions | PO / SME / PO | Yes | Now | Draft (decisions recorded; steps 1 to 5 built) | docs/roadmap/client-foundation-plan.md | AUD-013 to AUD-015, CARE-001 |
| PRD-011 | HR and Workforce roadmap | HR Pack direction | PO / SME / PO | Yes | Now | Draft | docs/roadmap/hr-and-workforce.md | AUD-010 |
| PRD-012 | Improvement requests (Nov 2026) | Review and plan of the improvement request | PO / TL / PO | Yes | Now | Draft (largely delivered) | docs/roadmap/improvements-nov-2026.md | QA-006 |
| PRD-013 | Module framework proposal | Module organisation, Manager Administrators, sidebar | TL / PO / PO | Yes | Now | Draft (steps 1 to 4 built) | docs/roadmap/module-framework-proposal.md | MOD-001, IAM-001 |
| PRD-014 | New roles plan | Case manager, intake, payroll, rostering as access levels | PO / SR / PO | Yes | Now | Draft, **likely superseded** by AUD-016 model | docs/roadmap/new-roles-plan.md | AUD-016 |

## 02 Architecture

| ID | Name | Purpose | Owner / Reviewer / Approver | Exists | Priority | Status | Path | Related |
|---|---|---|---|---|---|---|---|---|
| ARC-001 ★ | System Architecture | Components, auth, hosting, integrations, environments, customer database arrangement, gaps | TL / TL / PO | Yes | Now | Draft 0.1 | docs/02-architecture/ARC-001-system-architecture.md | ARC-002, DB-001, RSK-001 |
| ARC-002 | Tenancy and Environments | One codebase, one database per customer; copies, branches, naming. **Shared-database multi-tenancy not implemented** (org_id unused in rules) | TL / SR / PO | Yes (current model) | Now | Draft | docs/ENVIRONMENTS.md | SEC-002, COM-005 |
| ARC-003 | Data Flow Diagrams | Where personal and client data goes (browser, Vercel, Supabase, email, AI assistant) | TL / PL / PO | No | Before live | — | To write | SEC-003, ARC-004 |
| ARC-004 | Integration Register | External services and what each receives (Supabase, Vercel, Anthropic API for the Assistant, email provider when set up) | TL / PL / PO | No (dependencies in package.json; services in ENVIRONMENTS.md) | Before live | — | To write | ARC-003, IP-004 |
| ARC-005 | Performance and scalability plan | Performance stages 1 to 9 (2 to 9 deferred) | TL / TL / PO | Yes | Future | Draft | docs/roadmap/performance-and-scalability.md | AUD-005 to AUD-007 |

## 03 Database and data

| ID | Name | Purpose | Owner / Reviewer / Approver | Exists | Priority | Status | Path | Related |
|---|---|---|---|---|---|---|---|---|
| DB-001 ★ | Database and Data Model | Business-critical tables, relationships, keys, triggers, functions, integrity rules, update history | TL / SR / PO | Yes (+ generated appendix A: every table) | Now | Draft 0.1 | docs/03-database-and-data/DB-001-database-and-data-model.md | ARC-001, SEC-002 |
| DB-002 | Company set-up files | Per-company seed (name, branding) | TL / TL / PO | Yes | Now | Code | supabase/companies/*.sql | COM-005 |
| DB-003 | Database proposals | SQL written but awaiting decisions | TL / SR / PO | Yes (none waiting) | Now | Draft | supabase/proposals/README.md | QA-005 |

## 04 Security and privacy

| ID | Name | Purpose | Owner / Reviewer / Approver | Exists | Priority | Status | Path | Related |
|---|---|---|---|---|---|---|---|---|
| SEC-001 | Security Policy | Security principles and rules for the platform | TL / SR / PO | No | Before live | — | To write | SEC-002, IAM-001 |
| SEC-002 ★ | Current RLS Policy Register | Every current policy (175 table, 24 storage), tables without policies, SECURITY DEFINER functions, concerns | TL / SR / PO | Yes (+ generated appendix A); Stage 1 register kept as evidence (AUD-007a) | Now | Draft 0.1 (needs independent review) | docs/04-security-and-privacy/SEC-002-rls-policy-register.md | DB-001, MOD-001, RSK-001 |
| SEC-003 ★ | Privacy and Data Handling | What personal and client data is held, why, who sees it, where it's stored | TL (facts) / PL / PO | Partial: CUS-ENG-07 (customer-facing overview), HR and client review documents | Now (facts) / Before live (approved) | — | To write (facts first, adviser review needed) | ARC-003, SEC-004 |
| SEC-004 | Data Retention and Disposal | How long data is kept and how it's removed (a retention setting exists) | PO / PL / PO | No | Before live | — | To write | SEC-003 |
| SEC-005 | Data Breach Response Plan | What to do if data is exposed | PO / PL / PO | No | Before live | — | To write (adviser input needed) | OPS-002 |
| SEC-006 | Security Risk Register | Merged into RSK-001 | — | — | — | Not used (see RSK-001) | — | RSK-001 |

## 05 Access control

| ID | Name | Purpose | Owner / Reviewer / Approver | Exists | Priority | Status | Path | Related |
|---|---|---|---|---|---|---|---|---|
| IAM-001 | Access Control Standard | How access is decided (`can()`, grants, levels, delegation, owner protection) | TL / SR / PO | Partial: AUD-016, PRD-013, VERSIONS 0.1.1 | Now | — | To write after AUD-016 decision | PRD-004, SEC-002 |

## 06 Development and testing

| ID | Name | Purpose | Owner / Reviewer / Approver | Exists | Priority | Status | Path | Related |
|---|---|---|---|---|---|---|---|---|
| QA-001 ★ | Development and Testing Standards | How changes are made: minimal change, live updates with undo, round trips, checks before push, credit conservation | TL / TL / PO | Partial: docs/DEVELOPMENT-PROTOCOL.md, AGENTS.md, live-updates README | Now | Draft | Extend docs/DEVELOPMENT-PROTOCOL.md | QA-002, GOV-006 |
| QA-002 | Testing Strategy | Database tests, unit tests, browser checks, round trips, UAT | TL / TL / PO | Partial: supabase/tests, CUS-ENG-10 | Now | — | Section of QA-001 | QA-003 |
| QA-003 | Test Evidence Register | Which tests prove which change | TL / TL / PO | Partial: in each AUD report and commit | Before live | — | To write | QA-005 |
| QA-004 | Defect Register | Known defects and their status | TL / PO / PO | Partial: AUD-001, AUD-002, AUD-009 | Before live | — | To write | SEC-006 |
| QA-005 ★ | Change, Migration and Release Register | Every live update (what, when run where, undo) and every release | TL / TL / PO | Yes, in parts: supabase/live-updates/README.md (updates and which copy has them), docs/VERSIONS.md (releases), docs/RESTORE.md (restore points) | Now | Draft | Keep the three; link them here | QA-006, OPS-001 |
| QA-007 | Change plan: unsupported delegation controls | Access page: Tasks, Staff, Teams, Clients (and three more found) shown as set by role | TL / TL / PO | Yes | Now | Approved and implemented 16 Nov 2026 (D-040, D-042); document Draft | docs/06-development-and-testing/QA-007-plan-unsupported-delegation-controls.md | D-036, MOD-001 |
| QA-008 | Change plan: odometer photos off | Setting Off on each copy; storage policy follows the setting; fresh installs start Off | TL / TL / PO | Yes | Now | Approved (D-042), not yet implemented | docs/06-development-and-testing/QA-008-plan-odometer-photos-off.md | D-037, AUD-018 |
| QA-006 | Release Register | Versions and their branches | TL / TL / PO | Yes | Now | Draft | docs/VERSIONS.md | QA-005 |

## 07 Operations and maintenance

| ID | Name | Purpose | Owner / Reviewer / Approver | Exists | Priority | Status | Path | Related |
|---|---|---|---|---|---|---|---|---|
| OPS-001 | Backup and Recovery Plan | Code restore points exist; database backups and a tested restore **not documented** | TL / SR / PO | Partial: docs/RESTORE.md (code and undo files only) | Before live | Draft | Extend RESTORE.md | QA-005 |
| OPS-002 | Incident Management Procedure | How incidents are handled | TL / SR / PO | No | Before live | — | To write | SEC-005 |
| OPS-003 | Business Continuity Plan | Keeping providers running if a service fails | PO / SR / PO | No | Future | — | To write | OPS-001 |
| OPS-004 | Monitoring and Maintenance | System health page, hourly timer, set-up checks | TL / TL / PO | Partial: docs/SETUP.md, docs/setup/dev-hourly-timer.md | Now | Draft | Keep; link | OPS-006 |
| OPS-005 | Privileged Access Register | Who has system admin, owner, Manager Administrator and sensitive grants on each copy | TL / SR / PO | No (kept in each database; not documented) | Before live | — | To write (no personal data in the repo: record roles and copies, list kept outside git) | IAM-001 |
| OPS-006 | Portal set-up guide | Setting up a copy for a company | TL / TL / PO | Yes | Now | Draft | docs/SETUP.md | ARC-002 |
| OPS-007 | Hourly timer guide (Dev) | Timer set-up, checks, rollback | TL / TL / PO | Yes | Now | Draft | docs/setup/dev-hourly-timer.md, supabase/setup/timer-checks.sql | OPS-004 |

## 08 Customer and commercial (platform level)

| ID | Name | Purpose | Owner / Reviewer / Approver | Exists | Priority | Status | Path | Related |
|---|---|---|---|---|---|---|---|---|
| COM-001 | SaaS Terms of Service | Platform terms for all providers | PO / PL / PO | Partial: CUS-ENG-09 (draft for one customer) | Before live | — | To write (legal input needed) | COM-002, COM-003 |
| COM-002 | Customer Data Agreement | Who owns and processes customer data | PO / PL / PO | Partial: BUSINESS-NOTES.md principles | Before live | — | To write (legal input needed) | SEC-003 |
| COM-003 | Service Level Agreement | Support and availability commitments | PO / PL / PO | Partial: CUS-ENG-09 | Before live | — | To write | OPS-002 |
| COM-004 | Customer Onboarding Guide | Setting up a new provider | TL / PO / PO | Yes (Word): docs/deliverables/20 New company setup guide.docx | Before live | Draft | Keep | OPS-006 |
| COM-005 | Customer Configuration Register | Per customer: copy, modules on, programs, function groups (no confidential data) | TL / PO / PO | Partial: ENVIRONMENTS.md copies table, companies/*.sql | Before live | — | To write | ARC-002 |
| COM-006 | Support Access Procedure | How cmeprojects staff access a customer copy (Take over, reviewer accounts) | TL / SR / PO | Partial: docs/review/reviewer-brief.md | Before live | — | To write | OPS-005 |
| COM-007 | Business notes | Agreement points, ways to buy, ownership | PO / PL / PO | Yes | Now | Draft (not legal advice) | docs/BUSINESS-NOTES.md | COM-001 |

## 09 Care-sector requirements

| ID | Name | Purpose | Owner / Reviewer / Approver | Exists | Priority | Status | Path | Related |
|---|---|---|---|---|---|---|---|---|
| CARE-001 | Care Workflow Specifications | Client intake, profile, locations, safety, services, readiness | PO / SME / PO | Partial: PRD-010, AUD-013 to AUD-015 | Now | — | To write from built steps | PRD-010 |
| CARE-002 | HR and Workforce Workflow Specifications | Onboarding, clearance, records, requests | PO / SME / PO | Partial: AUD-004, AUD-010, PRD-011 | Now | — | To write | CARE-005 |
| CARE-003 | Rostering Workflow Specifications | Rostering (not built) | PO / SME / PO | No | Future | — | To write before rostering | CARE-001 |
| CARE-004 | Clinical and Allied Health Workflow Specifications | Allied Health workflows (not built) | PO / CR / PO | No | Future | — | To write (qualified input needed) | AUD-016 |
| CARE-005 | Compliance Requirements Register | Sector obligations the platform supports (NDIS, aged care, worker screening) | PO / SME + PL / PO | No | Before live | — | To write (qualified input needed; nothing assumed) | CARE-001, CARE-002 |

## 10 IP and suppliers

| ID | Name | Purpose | Owner / Reviewer / Approver | Exists | Priority | Status | Path | Related |
|---|---|---|---|---|---|---|---|---|
| IP-001 | IP Ownership Register | What cmeproject owns (code header "© cmeproject"; BUSINESS-NOTES says code owned by cmeproject) | PO / PL / PO | No | Before live | — | To write (legal input) | COM-001 |
| IP-002 | Third-Party Software and Licence Register | Packages and licences (13 direct dependencies in package.json) | TL / PL / PO | No | Before live | — | To write | IP-001 |
| IP-003 | Contractor and Contributor Agreement Register | Who contributed and under what terms | PO / PL / PO | No | Before live | — | To write | IP-001 |
| IP-004 | Supplier Register | Supabase, Vercel, Anthropic, GitHub, email provider (TBC) | PO / PL / PO | Partial: ENVIRONMENTS.md | Before live | — | To write | ARC-004 |

## 11 Decisions and change history

| ID | Name | Purpose | Owner / Reviewer / Approver | Exists | Priority | Status | Path | Related |
|---|---|---|---|---|---|---|---|---|
| DEC-001 ★ | Decision Register | Owner decisions and approvals with date and source | PO / TL / PO | Yes (seeded from recorded decisions) | Now | Draft 0.1 | docs/11-decisions-and-change-history/DEC-001-decision-register.md | all |
| RSK-001 ★ | Risk Register (was DEC-002 / SEC-006) | Evidenced risks; 5 × 5 method, inherent and residual ratings (TBC) | PO / SR / PO | Yes | Now | Draft 0.2 | docs/11-decisions-and-change-history/RSK-001-risk-register.md | SEC-002, ARC-001 |
| DEC-003 | Early plan and decisions | First milestones and decisions (Oct 2026) | PO / — / — | Yes | — | Superseded by DEC-001 and PRD-002 (kept) | docs/PLAN.md | DEC-001 |

## 12 Audits and evidence (kept unchanged; status Evidence)

| ID | Name | Path |
|---|---|---|
| AUD-001 | Code and security audit (Nov 2026, first client copy) | docs/AUDIT-2026-11.md |
| AUD-002 | Full system audit, Development copy | docs/audit/2026-11-system-audit.md |
| AUD-003 | Manager dashboard, People and HR release | docs/audit/2026-11-hr-release.md |
| AUD-004 | Staff onboarding, compliance and clearance | docs/audit/2026-11-onboarding.md |
| AUD-005 | Performance audit: findings and proposal | docs/audit/2026-11-performance-plan.md |
| AUD-006 | Performance, RLS security and scalability review | docs/audit/2026-11-performance-review.md |
| AUD-007 | Performance Stage 1 completion report (+ evidence folder) | docs/audit/2026-11-performance-stage1.md, docs/audit/evidence/ |
| AUD-007a | RLS change register (Stage 1) | docs/audit/2026-11-rls-register.md |
| AUD-008 | cmeprojects review (12 Nov) | docs/review/2026-11-12-cmeprojects-review.md |
| AUD-009 | Audit assessment: revised findings | docs/review/2026-11-15-audit-assessment.md |
| AUD-010 | HR Pack completeness and readiness | docs/review/2026-11-15-hr-pack-readiness.md |
| AUD-011 | Team leaders and private details (update 84) | docs/review/2026-11-15-leader-private-details.md |
| AUD-012 | HR Stage A review against requirements | docs/review/2026-11-15-stage-a-review.md |
| AUD-013 | Clients step 1 (update 85) | docs/review/2026-11-15-clients-step1.md |
| AUD-014 | Clients step 1 fix (update 86) | docs/review/2026-11-15-clients-step1-fix.md |
| AUD-015 | Clients steps 2 to 5 (updates 87 to 90) | docs/review/2026-11-15-clients-steps2-5.md |
| AUD-016 | Function-based access model: Stage 1 assessment | docs/review/2026-11-16-function-access-assessment.md |
| AUD-017 | Reviewer brief (external review access) | docs/review/reviewer-brief.md |
| AUD-018 | Odometer photo storage policy: investigation | docs/12-audits-and-evidence/AUD-018-odometer-photo-investigation.md |
| AUD-019 | Incident: proposal applied to the local test database in error (restored, verified) | docs/12-audits-and-evidence/AUD-019-local-policy-applied-in-error.md |

All AUD documents are reports of work done or reviews by the developer
(Claude). **None is an independent, legal or clinical review.**

## Customer-level documents: Engaged Care (CUS-ENG)

Kept apart from platform documents (GOV-001 section 8). Word and
PowerPoint files; owner PO; status Draft unless the customer has signed.

| ID | Document | Path |
|---|---|---|
| CUS-ENG-01 | Setup guide for the system admin | docs/clients/engaged-care/01 Setup guide for the system admin.docx |
| CUS-ENG-02 | User manual | docs/clients/engaged-care/02 User manual.docx |
| CUS-ENG-03 | System admin manual | docs/clients/engaged-care/03 System admin manual.docx |
| CUS-ENG-04 | Briefer: Staff Portal overview | docs/clients/engaged-care/04 Briefer - Staff Portal overview.pptx |
| CUS-ENG-05 | Proposal: why a standalone Staff Portal | docs/clients/engaged-care/05 Proposal - why a standalone Staff Portal.docx |
| CUS-ENG-06 | Pricing and running costs | docs/clients/engaged-care/06 Pricing and running costs.docx |
| CUS-ENG-07 | Security and privacy overview | docs/clients/engaged-care/07 Security and privacy overview.docx |
| CUS-ENG-08 | Go-live plan and checklist | docs/clients/engaged-care/08 Go-live plan and checklist.docx |
| CUS-ENG-09 | Service and support terms (draft) | docs/clients/engaged-care/09 Service and support terms (draft).docx |
| CUS-ENG-10 | Test plan and UAT checklist | docs/clients/engaged-care/10 Test plan and UAT checklist.docx |
| CUS-ENG-11 | Test report: November 2026 | docs/clients/engaged-care/11 Test report - November 2026.docx |
| CUS-ENG-14 | Pricing options: ways to pay | docs/clients/engaged-care/14 Pricing options - ways to pay.docx |
| CUS-ENG-15 | Pricing: simple | docs/clients/engaged-care/15 Pricing - simple.docx |
| CUS-ENG-16 | Why a standalone portal | docs/clients/engaged-care/16 Why a standalone portal.docx |
| CUS-ENG-S1 | Simulation page | docs/clients/engaged-care/simulation/index.html |

(Numbers 12 and 13 aren't in the folder.)

## Change history

| Version | Date | Author | Change | Approved by |
|---|---|---|---|---|
| 0.1 | 16 Nov 2026 | Technical Lead (prepared by Claude) | First register: every existing document given an ID; required inventory and priorities | Not approved |
| 0.4 | 16 Nov 2026 | Technical Lead (prepared by Claude) | QA-007 and QA-008 change plans; odometer proposals in supabase/proposals | Not approved |
| 0.3 | 16 Nov 2026 | Technical Lead (prepared by Claude) | Role holders (D-033); GOV-001 approved 1.0 (D-034); RSK-001 v0.2; AUD-018 added | Not approved |
| 0.2 | 16 Nov 2026 | Technical Lead (prepared by Claude) | ARC-001, DB-001, MOD-001 (was PRD-005), SEC-002, RSK-001 (was DEC-002/SEC-006) written; GOV-007 generator; GOV-006 corrected (no CLAUDE.md in this repository) | Not approved |
