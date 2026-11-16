# GOV-003: Existing Documentation Assessment

| Field | Value |
|---|---|
| Document ID | GOV-003 |
| Title | Existing Documentation Assessment |
| Category | 00 Governance |
| Version | 0.1 |
| Status | **Draft** |
| Owner / Reviewer / Approver | Technical Lead / Product Owner / Product Owner |
| Created | 16 Nov 2026 |
| Last reviewed | TBC |
| Related | GOV-001, GOV-002 |

## 1. What was inspected (16 Nov 2026)

76 files under `docs/`, plus `README.md`, `AGENTS.md`,
`supabase/live-updates/README.md`, `supabase/proposals/README.md`,
`supabase/setup/`, `supabase/companies/`, `package.json` and the module and
role definitions in code. Nothing in the application code links to
documentation paths, so documents can be reorganised later without code
changes (but internal links and links already shared would need updating).

## 2. Existing structure and conventions

| Area | Contents | Convention |
|---|---|---|
| `docs/*.md` (11) | Handover, setup, environments, versions, restore points, to-do, plan, business notes, premium features, development protocol, first audit | UPPER-CASE names; "(cmeprojects)" in titles; "Staff Portal · © cmeproject" line |
| `docs/audit/` (7 + evidence) | Audits and the Stage 1 RLS register, with SQL, scripts and results | `YYYY-MM-topic.md` |
| `docs/review/` (11) | Reviews, completion reports, owner packs, temporary list | `YYYY-MM-DD-topic.md` |
| `docs/roadmap/` (6) | Plans and proposals | `topic.md` |
| `docs/setup/` (1) | Dev hourly timer guide | `topic.md` |
| `docs/clients/engaged-care/` (15) | Customer documents (Word, PowerPoint, simulation) | `NN Title.docx` |
| `docs/deliverables/` (1) | New company setup guide (Word) | `NN Title.docx` |
| `supabase/live-updates/` | Numbered SQL updates with undo files and a README recording which copy has which | `update-NN.sql`, `undo-NN.sql` |

**Strengths:** dated reports, every database change numbered with an undo,
evidence kept (Stage 1), plain English, consistent attribution.
**Weaknesses:** no document IDs, owners, statuses or versions; approvals live
in chat and commit messages, not in a register; proposed and built are
sometimes mixed in plans; no single product overview, architecture or data
model document; customer documents sit beside platform documents without a
stated rule.

## 3. Status of each existing document

| Document | Assessment |
|---|---|
| docs/HANDOVER.md | **Current but long** (375 lines). The best single summary of what's built. Keep as GOV-004 working notes; its stable parts should feed ARC-001, DB-001 and PRD-001. |
| docs/TODO.md | **Current** (living roadmap, on-hold items). PRD-002. |
| docs/PLAN.md | **Outdated** (Oct 2026 milestones; several items shown as not done are done). Its decisions are carried into DEC-001. Mark Superseded (DEC-003); retain. |
| docs/ENVIRONMENTS.md | **Current**: the tenancy model (one database per customer). ARC-002. |
| docs/SETUP.md | **Current**. OPS-006. |
| docs/VERSIONS.md | **Current but behind**: last version entry 0.1.1 (12 Nov) while development continued to update 90 under that version (by instruction). QA-006. |
| docs/RESTORE.md | **Current but partial**: code restore points and undo files only; no database backup or tested restore. Basis for OPS-001. |
| docs/DEVELOPMENT-PROTOCOL.md | **Current**: credit conservation and minimal change. Basis for QA-001. |
| docs/BUSINESS-NOTES.md | **Current**, says it isn't legal advice. COM-007. |
| docs/PREMIUM-FEATURES.md | **Current but short**. PRD-006. |
| docs/AUDIT-2026-11.md | **Historical evidence** (first client copy). AUD-001. |
| docs/audit/* | **Historical evidence**. AUD-002 to AUD-007a. The RLS register covers the Stage 1 change only, so it isn't a current register of all policies (SEC-002 gap). |
| docs/review/2026-11-* | **Evidence** of reviews and completed stages. AUD-008 to AUD-016. |
| docs/review/reviewer-brief.md | **Current** (external reviewer access). AUD-017; feeds COM-006. |
| docs/review/TEMP-to-review.md | **Temporary** by design. GOV-005; delete when done. |
| docs/roadmap/client-foundation-plan.md | **Current** (decisions recorded; steps 1 to 5 built). PRD-010. |
| docs/roadmap/hr-and-workforce.md | **Current**. PRD-011. |
| docs/roadmap/improvements-nov-2026.md | **Mostly delivered**. PRD-012; retain. |
| docs/roadmap/module-framework-proposal.md | **Partly built** (steps 1 to 4). PRD-013; the built parts should move into IAM-001. |
| docs/roadmap/new-roles-plan.md | **Likely superseded** by AUD-016 if approved. PRD-014. |
| docs/roadmap/performance-and-scalability.md | **Current, deferred** (stages 2 to 9). ARC-005. |
| docs/setup/dev-hourly-timer.md | **Current**. OPS-007. |
| docs/clients/engaged-care/* | **Customer-level**. CUS-ENG. Not reviewed for content in this task. |
| docs/deliverables/20 New company setup guide.docx | **Platform-level** guide. COM-004. |

**Duplication found:** set-up steps appear in SETUP.md, the new company
setup guide (Word) and CUS-ENG-01; release history appears in VERSIONS.md
and the live-updates README; decisions appear in PLAN.md, HANDOVER.md, plans
and review documents. Handled by pointing each to one owner document in
GOV-002, not by deleting anything.

## 4. Recommended actions (not done; for the owner's decision)

**Update (when next touched):** HANDOVER.md (point to GOV-002, trim to
working notes), VERSIONS.md (record whether 0.1.1 still covers updates 71
to 90 or a new version is due), RESTORE.md (add database backup facts once
known), DEVELOPMENT-PROTOCOL.md (add the testing standard and the
future-module checklist when approved), README.md (link GOV-002).

**Retain unchanged:** all audit and review documents, evidence folders,
customer documents, live-updates README.

**Mark superseded (retain):** PLAN.md (by DEC-001 and PRD-002);
new-roles-plan.md if AUD-016 is approved.

**Archive:** nothing yet. TEMP-to-review.md is deleted once done (its
content is temporary by design).

**Reorganising existing files into the numbered folders:** not done.
Optional, for the owner's decision; it would need every internal link and
shared link updated. New documents go into numbered folders from now on.

## 5. Missing documents needing human, professional or technical input

| Needs | Documents |
|---|---|
| **Qualified Privacy / Legal Adviser** | SEC-003 approval, SEC-004 Retention, SEC-005 Breach response, COM-001 Terms, COM-002 Data agreement, COM-003 SLA, IP-001, IP-003, CARE-005 (legal side) |
| **Independent Security Reviewer** | SEC-001 approval, SEC-002 review, OPS-005 review, tenant isolation sign-off (ARC-002) |
| **Qualified Clinical / Allied Health Reviewer** | CARE-004 |
| **Provider Subject Matter Reviewers** | CARE-001, CARE-002, CARE-003, PRD-003 |
| **Product Owner decisions** | PRD-001 scope, role holders for every responsibility, RSK-001 risk scoring method and appetite, COM-005 per customer |
| **Technical (can be drafted from the code now)** | (ARC-001, DB-001, MOD-001, SEC-002 drafted 16 Nov 2026); QA-001/QA-002, QA-003, ARC-004, IP-002 |

## 6. The ten foundational documents

| # | Document | ID | State |
|---|---|---|---|
| 1 | Product Overview and Scope | PRD-001 | Partial sources; to write (owner input on scope) |
| 2 | System Architecture | ARC-001 | **Draft written 16 Nov 2026** |
| 3 | Database and Data Model | DB-001 | **Draft written 16 Nov 2026** |
| 4 | Function Groups, Roles and Permissions Matrix | PRD-004 | Partial; waits on the AUD-016 decision |
| 5 | Module Catalogue and Dependencies | MOD-001 | **Draft written 16 Nov 2026** |
| 6 | Security and RLS Policy Register | SEC-002 | **Draft written 16 Nov 2026** (needs independent review) |
| 7 | Privacy and Data Handling | SEC-003 | Facts can be drafted; adviser review needed |
| 8 | Development and Testing Standards | QA-001 | Exists in part; extend |
| 9 | Change, Migration and Release Register | QA-005 | Exists in three parts; linked |
| 10 | Risk and Decision Register | DEC-001 / RSK-001 | Both drafted |

## Change history

| Version | Date | Author | Change | Approved by |
|---|---|---|---|---|
| 0.1 | 16 Nov 2026 | Technical Lead (prepared by Claude) | First assessment | Not approved |
