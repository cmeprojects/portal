# GOV-001: Documentation Governance Framework

| Field | Value |
|---|---|
| Document ID | GOV-001 |
| Title | Documentation Governance Framework |
| Category | 00 Governance |
| Version | 1.0 |
| Status | **Approved** by the Product Owner, 16 Nov 2026, as the initial framework, with provisional role assignments and outstanding reviews recorded below (D-034). Not an independent, legal or clinical review |
| Owner | Product Owner: the owner |
| Reviewer | Technical Lead: the owner |
| Approver | Product Owner |
| Created | 16 Nov 2026 |
| Last reviewed | 16 Nov 2026 (Product Owner) |
| Next review | On approval, then annually |
| Related | GOV-002 (Register), GOV-003 (Assessment), DEC-001 (Decision Register) |

## 1. Purpose

One reliable source of truth for every important aspect of cmeprojects (the
Staff and Care Operations Portal and its future SaaS offering): each
document has an ID, an accountable owner, a status, a reviewer suited to its
subject, and a change history, and stays consistent with what's actually
built. This framework governs documentation only; it changes no code,
data, permissions or production resources.

## 2. Responsibilities

One person may hold several roles.

**Role holders (provisional, D-033, 16 Nov 2026):**

| Role | Holder |
|---|---|
| Product Owner | The owner |
| Technical Lead / Developer | The owner (development work prepared by Claude) |
| Security Reviewer (independent) | **Unassigned**: to be appointed externally |
| Privacy / Legal Adviser (qualified) | **Unassigned**: to be appointed externally |
| Provider Subject Matter Reviewer | The relevant provider representative or qualified professional, chosen per document |

The owner may do initial development and documentation reviews. **These are
never presented as independent security, legal or clinical approval.**
Documents that need those reviews stay Draft (or Under Review) until the
external reviewer has reviewed them.

| Role | Responsible for |
|---|---|
| **Product Owner** | Product direction and business requirements; scope and roadmap; approves product-level decisions and documents; makes sure every document has an owner. |
| **Technical Lead / Developer** | Architecture, database, development, testing and deployment documentation; records technical decisions and changes; keeps test and release evidence. |
| **Security Reviewer** | Reviews security-sensitive design and changes: access control, RLS, tenant isolation, security risks; records findings and remediation. Must be **independent** of the developer for formal sign-off. |
| **Privacy / Legal Adviser** | Privacy, customer data handling, contracts and legal obligations; advises on Australian requirements. Must be **qualified** for formal sign-off. |
| **Provider Subject Matter Reviewer** | Reviews workflows in their professional area (for example Care Manager, HR / Staff Administrator, Rostering Coordinator, Compliance Representative, qualified Allied Health or Clinical Reviewer). |

**A coding agent's review (including Claude's) is technical preparation
only. It is never formal legal, clinical or independent security approval.**

## 3. Document lifecycle

| Status | Meaning |
|---|---|
| **Draft** | Being written or changed. May contain gaps marked TBC. |
| **Under Review** | Sent to the named reviewer; changes only through review comments. |
| **Approved** | An authorised approver has approved this version, recorded with name (or role holder), date and evidence. **Never set without that record.** |
| **Superseded** | Replaced by a newer document or version (named in the header). Kept unchanged. |
| **Retired** | No longer applies; kept for history in `docs/archive/` (or in place, marked). |

**Flow:** create (Draft) → review (Under Review) → approve (Approved, with
evidence) → change: a new version starts as Draft; the approved one stays as
it was until the new one is approved → replace (Superseded) or end (Retired).
An approved document is never changed silently: every change gets a new
version and a change history line.

## 4. Identification and versioning

### IDs

`<PREFIX>-<NNN>`, numbered in order within each category, never reused.

| Prefix | Category (folder for new documents) |
|---|---|
| GOV | 00 Governance |
| PRD | 01 Product (overview, roadmap, requirements, roles matrix) |
| MOD | 01 Product: module catalogue (MOD-001) |
| ARC | 02 Architecture (system, tenancy, data flows, integrations, performance) |
| DB | 03 Database and data |
| SEC | 04 Security and privacy (security policy, RLS register, privacy, retention, breach response, security risks) |
| IAM | 05 Access control |
| QA | 06 Development and testing (standards, testing, evidence, defects, changes, releases) |
| OPS | 07 Operations and maintenance |
| COM | 08 Customer and commercial (platform-level terms and templates) |
| CARE | 09 Care-sector requirements and workflows |
| IP | 10 IP and suppliers |
| DEC | 11 Decisions and change history |
| RSK | 11 Decisions and change history: risk register (RSK-001; security risks also feed 04) |
| AUD | 12 Audits and evidence (reviews, audits, completion reports, evidence) |
| CUS-<CODE> | Customer-level documents for one provider (for example CUS-ENG for Engaged Care); kept separate from platform documents |

Existing documents keep their current file paths; GOV-002 gives each one an
ID. New documents go in the numbered folder for their category, named
`<ID>-<short-title>.md` (for example `docs/02-architecture/ARC-001-system-architecture.md`).
Folders are created only when their first document is.

### Versions

- `0.x` = Draft or Under Review; `1.0` = first approved; `1.1` = approved
  minor change; `2.0` = approved major change.
- Documents without a header today are "unversioned (git history)" until
  they're brought under control.
- Git history is the full record; the change history table records each
  version's reason.

### Header (every controlled document)

Document ID, Title, Category, Version, Status, Owner, Reviewer, Approver,
Created, Last reviewed, Next review (if applicable), Related documents, then
at the end a **Change history** table: Version, Date, Author (role), Change,
Approved by (or "not approved").

Dates are written like 16 Nov 2026. Australian English throughout.

## 5. Review and approval matrix

| Document type | Prepares | Reviews | Approves | Evidence kept |
|---|---|---|---|---|
| Product overview, roadmap, requirements | Product Owner (Technical Lead drafts) | Provider Subject Matter Reviewer | Product Owner | Review notes, decision entries (DEC-001) |
| Architecture, database, integrations | Technical Lead | Technical Lead (peer if available) | Product Owner | Diagrams, schema references, tests |
| RLS, tenant isolation, access control | Technical Lead | **Independent** Security Reviewer | Product Owner after security review | RLS register, test results, findings |
| Privacy, retention, breach response, customer agreements | Technical Lead / Product Owner (facts) | **Qualified** Privacy / Legal Adviser | Product Owner on adviser's advice | Adviser's written advice |
| Care, HR and rostering workflows | Technical Lead / Product Owner | Relevant Provider Subject Matter Reviewer | Product Owner | Review notes, UAT results |
| Clinical and Allied Health workflows | Technical Lead / Product Owner | **Qualified** Clinical / Allied Health Reviewer | Product Owner on reviewer's advice | Reviewer's written notes |
| Development standards, testing, releases | Technical Lead | Technical Lead | Product Owner | Test output, release entries |
| Operations (backup, incidents, continuity, privileged access) | Technical Lead | Security Reviewer (privileged access) | Product Owner | Restore tests, access reviews |
| Audits and completion reports (AUD) | Whoever performed the work | Product Owner | Not approved; they're evidence | The report itself, kept unchanged |

## 6. Review schedule (recommended internal intervals, not statutory deadlines)

| Trigger | Review |
|---|---|
| Significant feature change | Affected requirements, architecture and technical documents |
| New module | Module catalogue, permissions, dependencies, security review |
| Role or permission change | Roles matrix, access control, RLS register |
| New tenant / customer | Tenancy architecture, customer configuration |
| Database or RLS change | Database documentation, security review, test evidence |
| New integration | Integration register, data flows, privacy review |
| Every release | Change log, test evidence, release register |
| Quarterly | Security risks, privileged access, open defects, customer configurations |
| Six-monthly | Backup and recovery, privacy arrangements, business continuity |
| Annually | Core policies, agreements, regulatory requirements |
| Security or privacy incident | Incident, risk and response documents |

Earlier reviews whenever circumstances need them.

## 7. Maintenance rules

1. Update the existing document when a change affects it.
2. Don't create a new document when the information belongs in an existing one.
3. Record material decisions and their reasons in DEC-001.
4. Keep historical versions and audit evidence; never delete evidence.
5. Never silently change an approved document.
6. Record who reviewed and approved, and when.
7. Mark unverified information clearly ("Not verified").
8. Keep **implemented** separate from **proposed** (every document says which).
9. Link documents to modules, live updates (migrations), tests and evidence.
10. A task isn't complete just because a document was written.
11. Before changing a document that describes built functionality, verify the
    functionality (code, database or test) first.

## 8. Platform and customer documentation (SaaS)

- **Platform-level** (docs/ numbered folders): core architecture, security
  and permission framework, database and tenant isolation, platform
  administration, shared releases and maintenance, product ownership and
  licensing.
- **Customer-level** (`docs/clients/<customer>/`, IDs `CUS-<CODE>-NNN`):
  organisation details and branding, enabled modules and programs, function
  groups and roles, customer-specific workflows and configuration, customer
  data handling and support arrangements. Never copied into platform
  documents; customer data never goes in documentation at all.
- **Current tenancy (verified 16 Nov 2026):** one codebase, **one separate
  database and website per customer** (docs/ENVIRONMENTS.md). Tables carry
  an `org_id`, but no access rule uses it: there is **no shared-database
  multi-tenancy** and it must not be described as implemented. Recorded as
  a gap in GOV-002 (ARC-002).

## 9. How this applies to Claude's work

- Every review or completion report Claude writes is registered as AUD-NNN,
  status Draft / evidence, never Approved.
- Plans needing approval are PRD (or IAM, CARE) documents in Draft until the
  owner approves; the approval is recorded in DEC-001 with the date and the
  owner's words.
- GOV-002 is updated in the same commit as any new or changed document.

## Change history

| Version | Date | Author | Change | Approved by |
|---|---|---|---|---|
| 0.1 | 16 Nov 2026 | Technical Lead (prepared by Claude) | First draft | Not approved |
| 0.2 | 16 Nov 2026 | Technical Lead (prepared by Claude) | Added MOD and RSK prefixes (owner's document IDs, D-032) | Not approved |
| 1.0 | 16 Nov 2026 | Technical Lead (prepared by Claude) | Role holders recorded (provisional); approved as the initial framework | **Product Owner, 16 Nov 2026** (owner's written decision in session; D-034) |
