# Function-based access model: Stage 1 architecture assessment (cmeprojects)

16 Nov 2026. **Review only: nothing changed.** For the owner's approval.
Model asked for: Organisation → Function Groups → Roles → Individual staff
access → Effective permissions. Checked against the code and the database
(version 0.1.1, updates to 90).

## 1. Existing role and permission structure

| Layer | What exists | Where |
|---|---|---|
| **Access level** (called "role" in code) | Fixed list of 7: new starter, support worker, team leader, manager, staff admin, system admin, external. One per person (`profiles.role`). | `app_role` enum; `src/lib/roles.ts` |
| **Job title** (shown to staff as "role") | Created in the portal, no code: name, description, active, order, **one access level**. One per person (`profiles.job_title_id`). | `job_titles`; Settings → Roles |
| **Hard-coded rules** | About 180 checks name the access levels allowed (for example "manager or system admin sees every task"), in pages and RLS. | `has_role(...)`, `requireRole(...)` |
| **Module catalogue** | 64 modules (38 top level) with category, parent, actions (view, create, edit, approve, export, configure ...), sensitivity (normal, sensitive, protected), delegable, status. | `app_modules`, `src/lib/modules.ts` (kept in step by a test) |
| **Individual grants** | Per person: module (or a legacy records area), actions, **allow or restrict**, scope (all, teams, people), start and end dates, note, pass-on chain, "include sub-modules". | `access_grants`; Access page / Delegation Centre |
| **Permission engine** | `can(module, action, person)`: system admin yes; protected no; otherwise the **nearest level** with a grant (module, then parents, then category) decides, and a restriction beats an allow at that level. Sensitive modules are never inherited from a parent; modules added after a grant aren't silently included. | `public.can()` (INVOKER) |
| **Module configuration** | Feature switches (on/off per organisation, parts, premium), separate from access. | `features`, System settings |
| **Audit** | Change log for role, team, title, access and grant changes; sensitive-records log. | `audit_log`, `sensitive_access_log` |

## 2. Dynamic role creation today and its limits

- People with the **Roles** settings area (delegated by the system admin;
  Manager Administrators through the Delegation Centre) create, rename,
  reorder and deactivate job titles. The Roles page refuses "system admin"
  as a title's level; the database stops a title's level changing while
  people hold it, and logs name, level and active changes. Assigning a title
  sets the person's access level.
- Gap noted: the "not system admin" rule is only in the page, not the
  database (worth adding in stage 2).
- **Limits:** a title carries **no permissions of its own**: everything comes
  from its single access level. Two titles on the same level (for example
  "Speech pathologist" and "Physiotherapist" on support worker) can't differ.
  There's no link to a business function, and no title-level grants.

## 3. Module and sub-module configuration

`app_modules`: id, parent, category, label, actions, sensitivity, delegable,
status, plus a legacy link for older areas (records, settings). Categories
(workspace, operations, apps, people, hr, clients, workflows, insights,
engagement, system) are **menu groupings**, not business functions.
Mirrored in `src/lib/modules.ts`; a unit test fails if the two disagree.

## 4. Delegation Centre

- System admin → **Manager Administrators** (nominated, with end dates) →
  pass on what they hold to **staff admins**.
- Grants: actions, allow/restrict, scope by team or person, start/end,
  never beyond the giver's own access, sensitive parts never inherited,
  history, and revoked automatically if the giver loses their standing.
- **Limit:** grants work only for people whose access level is manager or
  staff admin (`can()` and `module_grant_allowed()` both check this). They
  can't yet be given to a role or a function, or to other access levels.

## 5. How new staff get permissions after role assignment

Onboarding → checked right to work → **cleared** (`grant_clearance`) → a
manager or staff admin gives a role (refused before clearance, update 79) →
the **access level** decides everything through the hard-coded rules. Only
managers and staff admins can also hold individual grants. Nothing is
inherited from the job title.

## 6. Do Function Groups exist?

**No.** Closest things: module categories (menu only), job titles (no
permissions) and access levels (fixed). None should be repurposed:
categories must stay menu groupings, and the enum can't be edited without code.
Function Groups need **one small table**, plus links to modules and titles.

## 7. Aligning roles with Function Groups

- Keep `job_titles` as **the** dynamic roles (no second role system).
- Add a link table: title ↔ function group (one or more; at least one
  required for new or edited titles; active groups only; logged).
- Existing titles: migrated by mapping their access level to a default group
  (for example team leader and support worker → Service Delivery; manager →
  Management & Administration; staff admin → HR & Workforce; external →
  Allied Health), for the owner to confirm before it runs.
- The **access level stays** as the safety ceiling and for the ~180 existing
  rules: a title still has one, so nothing that works today changes.

## 8. Allied Health without a second engine

- Allied Health = one Function Group; disciplines = job titles in it.
- **Baseline** (function grants): Allied Health menu and their own work only.
- **Discipline differences** (title grants): for example only Behaviour
  Support Practitioners get behaviour support plans.
- **Clinical records:** visible only for **assigned clients**, through a
  client–staff assignment with from/to dates (the same mechanism the case
  manager plan needs: "named on the client"), checked in RLS. Being in the
  function never opens every clinical record.
- Contracted access windows = the assignment's dates; the existing
  "external" access level suits contractors.

## 9. Reusable without change

Module catalogue and its test; `can()` resolution order and restriction
rules (to be extended, not replaced); grant scope, dates, pass-on, never
beyond the giver; Delegation Centre screens; Manager Administrator
standing; job titles and the Roles page; onboarding, clearance and
role-after-clearance; feature switches; change log; client teams; the
programs list; Stage 1 RLS form.

## 10. Gaps

1. No Function Groups (table, modules, baseline actions).
2. Job titles can't hold permissions.
3. Grants only to individuals, and only managers and staff admins.
4. One title per person (no multiple roles).
5. No staff program scope (client side has programs since update 85).
6. No client–staff assignment (needed by case managers and Allied Health).
7. Most existing modules are checked by hard-coded access levels, not
   `can()`: they stay as they are until each is moved over.
8. No rule yet that a new module must name its function, data scope and
   program scope before it's switched on.

## 11. Smallest safe changes (one engine)

| # | Change | Why |
|---|---|---|
| A | `function_groups` (id, key, name, description, active, order); seeded with the six; can't be deactivated while active titles use it | The new layer, central and editable |
| B | `job_title_functions` (title, group) | Roles aligned to one or more functions |
| C | **Extend `access_grants`** so a grant can be held by a person, **a job title** or **a function group** (one new "holder" field; existing rows are person grants) | Baselines and role permissions use the same grants, screens and audit: no second engine |
| D | Extend `can()` to read title and function grants, with the rules in section 12 | One resolver |
| E | `app_modules` gains data-scope and program-scope flags; each module mapped to a function (through function baseline grants) | The future-module rule |
| F | Later: `profile_job_titles` (extra titles), staff program scope, client–staff assignments | Multiple roles, programs, allied health |

No SECURITY DEFINER needed for A to E (`can()` is INVOKER; RLS on grants
gains "read the grants of your own titles and functions").

## 12. Inheritance and override rules (proposed)

For each module and action, most specific wins:
1. **Individual restriction** → no (never overridden by anything inherited).
2. **Individual allow** → yes (within the giver's authority).
3. **Job title**: restriction → no; allow → yes.
4. **Function group**: restriction → no; allow → yes.
5. Otherwise no.

Then, always: the module and its feature switch must be on; protected
modules stay system-admin only; sensitive modules are never inherited from a
parent and need their own explicit grant at some tier; data scope (teams,
people, assigned clients) and program scope narrow, never widen. With
several titles or functions, at the same tier any restriction wins, else any
allow. A role change recalculates inherited access automatically (it's
read live); individual grants stay and are logged.

Example: "Create client record" for Care Managers: a title grant (all Care
Managers) or an individual grant (one Care Manager), shown separately on the
Access page as "from role", "from function" or "individual".

## 13. How future modules and roles follow the model

- Checklist added to `docs/DEVELOPMENT-PROTOCOL.md`: id, name, description,
  function, parent, actions, sensitivity, data scope, program scope, grants,
  RLS through `can()`.
- A database test fails if any active module has no function mapping or no
  sensitivity, so a module can't ship half-registered.
- New modules start with **no grants** (nobody but the system admin);
  access arrives only when its function baseline is approved, then flows to
  everyone with that function or title. Individual grants untouched.
- A new Function Group must exist and be active before titles can use it.

## 14. RLS and data-integrity implications

- `can()` in RLS must stay cheap: wrapped `(select ...)` per Stage 1, and an
  index on grants by holder. To measure on the large test data before rollout.
- Foreign keys with restrict (titles ↔ groups; grants ↔ titles and groups);
  deactivate, never delete; history kept.
- Existing person grants keep exactly their meaning (holder = person).
- Access levels and their ~180 rules unchanged, so no existing access
  widens or narrows on day one.
- Read rules: staff can read their own titles' and functions' grants, not
  others'.

## 15. Staged plan (each stage its own update, tests, round trip, approval)

1. **Function Groups**: table, six seeded, admin screen under Roles,
   deactivation guard, audit. Tests: create, edit, can't deactivate in use.
2. **Title ↔ function**: link table, required on create and edit,
   migration of existing titles (owner confirms the mapping), audit. Tests:
   required, active only, history kept.
3. **Role and function grants**: `access_grants` holder; `can()` tiers;
   RLS on grants; Access page shows "from function / from role /
   individual"; Manager Administrators set title and function permissions
   within their authority. Tests: every precedence rule, restriction not
   overridden, sensitive not inherited, giver's authority, role change.
   Rollback: undo drops the holder column; person grants untouched.
4. **Future-module rule**: module scope flags, protocol checklist, catalogue
   test.
5. **Clients module on the model** (resumes the paused work): client
   modules mapped to Care & Coordination, case manager / intake officer as
   job titles with grants; client–staff assignment.
6. Later: multiple titles per person, staff program scope, Allied Health
   modules.

## Effect on the paused new-roles plan

`docs/roadmap/new-roles-plan.md` proposed four new fixed access levels. Under
this model, Case manager, Intake and assessment officer, Payroll and
Rostering become **job titles** in Function Groups, with permissions as
grants: no enum change and no code per role. If this assessment is
approved, that plan is replaced by stages 1 to 5 above.
