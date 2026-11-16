# MOD-001: Module Catalogue

| Field | Value |
|---|---|
| Document ID | MOD-001 (replaces the planned PRD-005 in GOV-002) |
| Title | Module Catalogue |
| Category | 01 Product |
| Version | 0.3 |
| Status | **Draft** |
| Owner / Reviewer / Approver | Technical Lead / Product Owner / Product Owner, role holders not yet assigned |
| Created | 16 Nov 2026 |
| Last reviewed | TBC |
| Next review | On every new module or permission change (GOV-001 §6) |
| Related | ARC-001, DB-001, SEC-002, RSK-001, AUD-016, PRD-013 |
| Appendix | [MOD-001 appendix A: catalogue as defined (generated)](MOD-001-appendix-a-catalogue.md) |

## 1. Sources and verification (16 Nov 2026)

| Source | Result |
|---|---|
| `public.app_modules` (local database built from the migrations, updates to 90) | 54 modules + 10 category rows (`cat_*`) |
| `src/lib/modules.ts` | 54 modules; **same ids** as the database (also enforced by `scripts/check-modules.mjs`, run with lint) |
| Routes (`src/app/**/page.tsx`) | 53 of 54 module pages exist; `ops.features` points to `/f`, which has no index page (only `/f/[slug]`) |
| Permission checks (`can(...)`, `canDo(...)`, module helpers, RLS) | See §4 |

**Menu categories are not Function Groups.** The ten categories (workspace,
operations, apps, people, hr, clients, workflows, insights, engagement,
system) only group the menu. Business Function Groups don't exist yet
(AUD-016).

## 2. Catalogue fields (verified)

`id`, `parent_id` (sub-modules), `category` (menu group), `label`,
`actions` (for example view, create, edit, delete, approve, configure,
export, download, reveal_tfn, sign_for_employer), `sensitivity` (normal;
**sensitive** = never inherited from a parent, needs its own grant;
**protected** = system admin only), `delegable` (can appear on the Access
page for grants), `status`, `legacy_kind` / `legacy_area` (older areas
mapped into the engine: staff records and settings areas), `added_at`
(modules added after a grant aren't silently included in it).

Full table: appendix A (generated, every module with parent, category,
actions, sensitivity, delegable, status, legacy link, page and whether the
page exists).

## 3. Feature switch dependencies (verified in `src/lib/nav-access.ts` and pages)

Module configuration (on or off for the organisation) is separate from
access. A module is usable only when its switch is on.

| Modules | Feature switch(es) |
|---|---|
| ops.tasks, ops.registers | `tasks` |
| ops.cars.* , insights.reports.cars | `vehicles` |
| ops.features | No overall switch; each built feature has its own on/off (`custom_feature_live`) |
| ops.apps | `staff_app` |
| workspace.onboarding, hr.onboarding.* | `hr`, `compliance` and its parts |
| workspace.requests, hr.requests | `hr`, `hr_requests` and request types |
| workspace.directory | `hr`, `hr_profiles` |
| workspace.contracts, hr.contracts | No switch: shown to people with contract access, or who have been sent a contract (`nav-access.ts`) |
| workspace.forms, workflows.forms | `forms`, `form_builder` |
| insights.reports.* | `reports` |
| engagement.assistant, engagement.enquiries, engagement.website | `assistant` |
| clients.list, ops.scoreboard, people.staff, people.invite, system.* | Always on (System settings, People row); `teams` and `roles` switches for people.teams and people.roles |

## 4. How access is actually decided (verified)

| Modules | Decided by | Grants on the Access page take effect? |
|---|---|---|
| hr.records.details, hr.records.payroll, hr.records.identity | `has_access(area, person)` / `has_tfn_access` in RLS (legacy record areas) | **Yes** (sensitive ones need their own grant) |
| system.settings.* (except general), people.roles, ops.registers, ops.registers.setup, system.audit, engagement.website | `can_admin_area(area)` (legacy settings areas) | **Yes** |
| hr.onboarding(.overview, .expiry), ops.cars.*, insights.reports.* | Role rules **or** a grant + `can()` (updates 75, 76) | **Yes** (managers and staff admins only) |
| workflows.forms, ops.features, engagement.enquiries | Role rules or grant + `can()` (updates 76, 77) | **Yes** (managers and staff admins only) |
| hr.contracts | `contract_access()` per ability (update 78) | **Yes** |
| system.settings, system.settings.general, system.access, system.builder, system.health | Protected: system admin only | No (by design) |
| **ops.tasks, people.staff, people.teams, clients.list, hr.requests** | **Role rules** (`can_see_task`, `can_edit_task`, `requireRole(PEOPLE_MANAGERS)`; Staff requests: people managers and team leaders) | **No.** Delegable in the catalogue, but no check reads a grant. Since QA-007 (16 Nov 2026) the Access page shows them as **"Set by role"** with no switch, and the server refuses new or changed grants; existing grants kept unchanged |
| **workflows.sla, workflows.request_rules** | Role **and** settings area (SLA: managers and system admin, staff admins with the Tasks area; Request approvals: system admin, managers and staff admins with the HR area) | **No.** Delegable in the catalogue but under the protected System settings module, so never shown in the Access tree; since QA-007 the server refuses grants for them ("Not available") |
| ops.scoreboard, people.invite, workspace.* , ops.apps, engagement.assistant | Role rules, settings or own-data RLS | No (not delegable) |

## 5. Implementation status

- **Built and in use:** all 54 modules have screens (one page missing:
  `/f` index, §1).
- **Clients & Care:** only `clients.list` is in the catalogue. The client
  profile sections built in updates 87 to 90 (locations, details and people,
  safety, services) are **not** separate catalogue modules; access to them is
  role-based (people managers) plus RLS for team staff (SEC-002).
- **Planned, not built:** Function Groups, role (job title) grants,
  program scope, optional client sections, rostering, Allied Health modules
  (AUD-016, PRD-010).

## 6. Known access-control limitations

1. Seven delegable modules (§4) don't follow the Access page. **Known
   limitation (D-036, D-040):** modules and current permission behaviour
   unchanged; since QA-007 their delegation controls are removed ("Set by
   role" or not shown) and the server refuses new or changed grants
   (`src/lib/access-by-role.ts`); fixed properly in the function-based access
   model (RSK-04). Headings with nothing grantable (People & organisation,
   Clients & care) have no switch.
2. Module grants apply only to managers and staff admins (`can()` and
   `module_grant_allowed()`); other roles can't receive module access.
3. Most modules still rely on hard-coded role checks (~180).
4. No module has a recorded Function Group, data scope or program scope.
5. `/f` has no index page although the module points there.

## Change history

| Version | Date | Author | Change | Approved by |
|---|---|---|---|---|
| 0.1 | 16 Nov 2026 | Technical Lead (prepared by Claude) | First draft, verified against the database, `src/lib/modules.ts`, routes and checks | Not approved |
| 0.2 | 16 Nov 2026 | Technical Lead (prepared by Claude) | Decision D-036 recorded | Not approved |
| 0.3 | 16 Nov 2026 | Technical Lead (prepared by Claude) | Verified delegation status of seven modules (hr.requests was wrongly listed as not delegable); QA-007 implemented | Not approved |
