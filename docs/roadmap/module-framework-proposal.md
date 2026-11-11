# Module organisation, permissions, Manager Administrators and sidebar: assessment and plan (cmeprojects)

Staff Portal · © cmeproject · 12 November 2026 · **Assessment only: nothing changed.** Restore point: `restore-before-module-framework`.

## 1. What exists today

### Module inventory (by proposed category)
| Proposed category | Existing modules → submodules (route) | Company switch (`features`) |
|---|---|---|
| **My workspace** (everyone) | Dashboard (`/`), My tasks, My onboarding, My requests, My forms, My contracts, Pay and work rights, My account, Directory, Notifications (bell) | various |
| **People & Organisation** | Staff (`/settings/staff`: invite, roles, deactivate, resend, delete starter); Teams; Roles/job titles; Directory (admin edit); Clients (`/settings/clients`) | `teams`, `roles`, `hr_profiles` |
| **HR & Workforce** | Onboarding (`/compliance`: requirements per kind [policies, training, uploads, agreements, forms], To check queue, clearance to work, overrides, Expiry list); Staff records: Staff details, **Payroll and tax** (bank, super, TFN form), **Identity and work rights** (visa, VEVO); **Contracts**; Staff requests (leave, swap, shift, availability, timesheet, HR, other) and approval rules | `hr`, `compliance` (+5 parts), `hr_requests` (+7 types) |
| **Clients & Care** | Clients (list, client teams) only | none |
| **Operations & Compliance** | Tasks (lists, new, task page, approvals, escalation); Registers (incidents, complaints, risks, maintenance… are *registers*, with set-up and templates); Cars (use, manage, app, reports); Built features (`/f/…`); Scoreboard | `tasks`, `vehicles`, `auto_escalation`, `attachments` |
| **Forms & Workflows** | Forms (maker, builder, replies, QR); Request approval rules; SLA settings; task escalation rules | `forms`, `form_builder` |
| **Reports & Insights** | Reports: Tasks, Cars, Compliance, built-feature reports, Excel exports | `reports` |
| **Website & Engagement** *(not in your list)* | Website and Assistant settings, Enquiries | `assistant` |
| **System & Configuration** | System settings (features, branding, messages, people rules, notifications, security, delegation, demo data), Staff access, Change log, Feature builder, System health, Apps (staff app, Cars app), Setup wizard | `two_factor`, `staff_app`, sign-in switches |
| **Finance & Administration** | none (future) | none |

### Today's permission model: four separate mechanisms
1. **Roles** (`app_role` enum: system admin, manager, staff admin, team leader, support worker, new starter, external). These are hard-coded in RLS helpers (`has_role`, `can_manage_people`…).
2. **Company switches** (`features`, with a parent chain and `feature_live`): a module is ON or OFF **for the whole company**, not per person.
3. **Settings delegation** (`delegation_rules` + `delegation_shares`): 13 areas. Each is "only me / all managers / selected people", and managers can share an area with staff admins. It controls **who may change settings**, not record access.
4. **Record access grants** (`access_grants`, Phase 2): per person, scoped (all / teams / people), with an end date, "may pass on", cascading removal and a history. It covers 3 areas: Staff details, Payroll and tax (+ TFN tick), Identity and work rights.

Also about 15 **role-list settings** act as permissions (for example `reports.roles`, `compliance.manager_roles`, `people.invite_roles`, `forms.maker_roles`, `vehicles.manager_roles`).

**Audit:** `audit_log` (append-only, via the existing `write_audit`), `sensitive_access_log` (Phase 3), and grant history in `access_grants`. **Scope:** teams, team leaders and job titles. There are **no locations or business units** yet.

### Problems the request correctly identifies
- Three separate lists of "areas" (features, delegation areas, access-grant areas) plus the role-list settings and `nav.ts`. **Navigation, permissions and delegation are disconnected.**
- Delegation is all-or-nothing per area (no submodule or action level), has no conditions on settings areas, and no history of previous and new values.
- Overlaps:
  - the "people" delegation area vs Staff details access;
  - "compliance" delegation vs `compliance.manager_roles`;
  - staff admins' built-in admin powers (invite, onboarding) vs delegation.
- The sidebar is hand-written (`nav.ts`), and the Settings, Change log and Staff access tabs are scattered.

## 2. Recommendations

### 2.1 One module catalogue (single source)
- **Database table `app_modules`** is the master list: `id` (for example `hr.records.payroll`), `parent_id`, `category`, `label`, `description`, `actions[]`, `sensitivity` (normal / sensitive / protected), `delegable`, `feature_key` (its company switch), `status` (active / planned).
  - It's needed in the database because RLS and the permission check must know parents and sensitivity.
  - It's seeded by migrations: **every new module is a migration row**, and it starts with **no grants**.
- **Code file `src/lib/modules.ts`** holds only presentation (icon and route) keyed by the same `id`.
  - A test fails the build if the two lists don't match. So there's one list, plus a check, with no drift.
- Sidebar, Delegation Centre, search and permission checks all read the catalogue.

### 2.2 Permissions: category, module, submodule, and action
- **Generalise `access_grants`** (Phase 2 already has scope, end date, pass-on, cascade and history) into `permission_grants`:
  - `module_id`;
  - `actions[]`;
  - `effect` (allow / restrict);
  - `include_children`;
  - scope, start and end dates, pass-on (with which actions may be passed on), approval-required actions, and status (active / suspended / pending).
- The existing 3 areas become 3 modules, and existing grants are migrated 1:1.
- **Effective permission:** one function `can(module, action, person?)`, SECURITY INVOKER like `has_access` today.
  1. The system admin is always allowed.
  2. The module's company switch must be on.
  3. The **nearest explicit setting wins**, checking the node itself, then its module, then its category: a restriction blocks, an allow allows.
  4. **Sensitive or protected nodes never inherit:** they need an explicit grant on the node itself.
  5. Scope (all / teams / people) and dates are checked.
  6. A passed-on grant is valid only while its parent grant is.
- **ON / OFF / PARTIAL** is shown in the interface, worked out from the children. A submodule can be ON while its module is OFF, as an explicit grant on the submodule only.
- **Actions** (only those that make sense per module): view, create, edit, delete, configure, approve, manage access, delegate, export, download. Examples:
  - Onboarding requirements: view / configure.
  - Document verification: view / approve.
  - Contracts: view / create / sign for employer.
  - Payroll and tax: view / reveal TFN / download / delete.
- **Not every RLS policy changes at once.** The existing helpers become thin wrappers. For example, `can_admin_area('tasks')` becomes `can('ops.tasks.settings','configure')` and `has_access('payroll_tax',p)` becomes `can('hr.records.payroll','view',p)`. That way the 115 existing policies keep working, and each module is moved over and tested one at a time.

### 2.3 Manager Administrator
- **Recommended: a designation, not a new role.** A new enum role would ripple through every RLS helper and existing role check, and Manager Administrators must keep everything a Manager has.
  - Table `admin_designations` (person, granted by, start and end dates, status, note).
  - Only active **managers** can be designated. Staff admins can only receive passed-on grants.
- The designation alone grants nothing. Its **grants** define what the person administers (configure / manage access / delegate actions), within the scope and conditions the system admin sets.
- Existing managers are **not** promoted. Today's "all managers" delegations (registers, roles) become equivalent grants for current managers, so nothing changes silently.
- **Protected (system admin only, never delegable):** system admins, security and sign-in settings, the permission framework itself, feature switches and plan, deployment, secrets, the change log's integrity, removing the system admin.
  - These are marked `protected` in the catalogue and refused by `can()` for anyone else, as well as in RLS.

### 2.4 Conditions and passing on
- **Already in place:** scope (all / teams / people), end date, "may pass on", cascading removal, nobody granting themselves, nothing wider or longer than the grantor holds.
- **To add:**
  - a start date;
  - choosing which actions may be passed on;
  - suspend / resume;
  - a renewal reminder before the end date;
  - **approval-required actions:** a change waits in a queue for the system admin. This can reuse the existing drafts / Deploy mechanism, which already holds pending settings changes.
- **Locations / business units:** none exist yet. Teams stand in for now; locations are added when a module needs them.

### 2.5 Delegation Centre (replaces the Delegation tab and grows from Settings → Staff access)
- **A. Overview tiles:** Manager Administrators, delegated modules, active grants, pending approvals, expiring soon, ended or removed.
- **B. Administrative users:** each Manager Administrator with role, categories, scope, status and end date, plus Review / Edit / Suspend / Remove.
- **C. Permissions tree:** the catalogue tree (category → module → submodule).
  - Each node shows ON / OFF / PARTIAL, with an inherited / explicit / restricted / unavailable marker. Action chips are under each node.
  - Search and filter, expand and collapse, and bulk on/off per branch. Bulk never turns on sensitive nodes.
  - Reset to inherited.
- **D. Conditions:** scope, passing on, approvals, dates.
- **E. History:** who gave what to whom, the previous and new state, when, and removals and refusals.
- **Review before saving:** a plain summary ("Olive will be able to: … She won't be able to: …"), and confirmation for anything significant.

### 2.6 Sidebar (driven by the catalogue)
```
[Logo] Company           [Bell 3] [Search ⌘K]
★ Pinned (optional, your favourites)
MY WORKSPACE      Dashboard · My tasks · My onboarding · My requests · My forms · My contracts
OPERATIONS        ▸ Tasks & registers (Tasks, Registers, Templates) · Cars · Built features · Scoreboard
PEOPLE & HR       ▸ Staff · Teams · Roles · Directory · ▸ Onboarding (Requirements, To check, Expiry list) · Contracts · Staff requests · Clients
FORMS             Forms
INSIGHTS          ▸ Reports (Tasks, Cars, Compliance, …)
ADMINISTRATION    ▸ Settings (System, SLA, Request approvals, Website) · Delegation Centre · Change log · Feature builder · System health
──────────────
My account · Apps · Sign out
```
- Built from the catalogue plus one call per page (`my_modules()`, which returns the allowed module ids). Only authorised items show. A person with access to one submodule sees just that item, with its route.
- **Interface:**
  - expandable categories and modules, remembered per person in the browser;
  - a collapsed icon rail with tooltips;
  - a clear active state and unread counts;
  - search across authorised items (the existing Ctrl K palette, fed by the catalogue);
  - pinned shortcuts (browser-only to start);
  - a mobile drawer, keyboard navigation (arrow keys, Enter, Esc) and restrained animation that respects reduced motion.
- **The current section tab rows stay** for in-page switching, generated from the same catalogue (no duplicate entries).

## 3. Database changes (all new; nothing removed)
1. `app_modules`: the catalogue, seeded with roughly 45 rows covering the existing modules and submodules.
2. `permission_grants`: generalised from `access_grants` (data migrated); the old table is kept as a read-only view during the move.
3. `admin_designations`.
4. `permission_events`: history with previous and new values (or `audit_log` with a richer details field).
5. `can()`, `my_modules()`, invoker wrappers for `has_access` / `has_tfn_access` / `can_admin_area`; **no new SECURITY DEFINER** (the existing definer functions are updated only where they already call these).
6. Approval queue: reuse `settings_drafts`, or add a small `pending_admin_changes` table (your decision).

Each step is a live update with an undo, tested twice, as before.

## 4. Risks and dependencies
- **Biggest risk: moving enforcement.** About 115 RLS policies and many role-list settings. Mitigation: wrappers first (no behaviour change), then one module at a time, each with the 7-identity tests (including the new Manager Administrator).
- **Performance:** `can()` is called per row in some policies. Use `(select …)` patterns as in Stage 1, and `my_modules()` once per page for the menu.
- **Role-list settings** (who sees Reports and so on) overlap with grants. Migrate each to grants as its module moves, never silently.
- The sidebar depends only on the catalogue (step 1), so it can ship early.
- **Credits:** this is the largest change so far, so it's split into checkpoints you approve one at a time.

## 5. Phases (more efficient order)
| Phase | Contents | Database | Visible change |
|---|---|---|---|
| **1. Catalogue + sidebar** | `app_modules` seed and `modules.ts`; the new sidebar and section tabs from the catalogue, using **today's** permission checks mapped per item | small (1 table) | New sidebar; no permission changes |
| **2. Permission engine** | `permission_grants`, `can()`, inheritance, actions, `my_modules()`; migrate `access_grants` and `delegation_rules` 1:1; wrappers so existing RLS behaves the same | yes | None (same access, now one system) |
| **3. Manager Administrator + Delegation Centre** | Designation, conditions, passing on by action, suspend, start dates, history, review before save, approval queue | yes | New Delegation Centre |
| **4. Enforcement, module by module** | Settings areas → HR (records, onboarding, contracts) → forms and requests → registers and tasks → reports and exports → cars and website; replace role-list settings with grants as each moves | per module | Finer control per module |
| **5. Standard** | Module registration checklist (catalogue row, actions, sensitivity, scope, RLS, audit, tests); a build check that every route has a catalogue entry | none | Docs |

**Testing per phase:** the 14 scenarios in your request with staff, team leader, manager, staff admin, Manager Administrator, system admin and signed out. Database checks for direct calls and file access, plus browser checks for the menu and direct URLs.

## 6. Decisions needed
1. **Manager Administrator as a designation on Managers** (recommended), or a separate role?
2. **Catalogue master in the database, icons and routes in code, with a matching check** (recommended)?
3. **Categories:** add "Website & Engagement" (Website and Assistant, Enquiries) and "My workspace" (personal items), and show empty categories (Finance, most of Clients & Care) only once they have modules. OK?
4. **Approval-required admin changes:** build the queue in Phase 3, or later?
5. **Today's "all managers" delegations** (registers, roles): keep as grants for current managers at the move (recommended: no silent change)?
6. **Pinned shortcuts:** browser-only first (no database)?
7. **Approve Phase 1** (catalogue + sidebar, no permission change) to start?
