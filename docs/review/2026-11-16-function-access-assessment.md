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

---

## Final clarification before Stage 1 (16 Nov 2026, review only)

Owner approved the model **in principle** (D-045) and asked for this focused
clarification. It reuses the findings above; nothing was changed. One
correction to §11 (change C): grants for job titles and function groups go
in a **new table**, not new columns on `access_grants` (reason in §C2).

### C1. Permission precedence and explicit restrictions

For a module and action, `can()` decides in this order; the **first tier
that has any applicable grant decides**:

1. **Person** (existing `access_grants` rows): restriction → no; allow → yes.
2. **Job title** (the person's title): restriction → no; allow → yes.
3. **Function group** (any group of the person's title): restriction → no; allow → yes.
4. Nothing → no.

Within a tier the existing rules stay: the nearest level (module, then its
parents, then its category) decides, and at that level a restriction beats
an allow. Across several groups, a restriction in any group beats an allow.
**A person's restriction is never overridden by a title or group grant.**
A person's allow can add what their title or group doesn't give.

### C2. Grant-holder design and foreign-key integrity

- **Person grants stay exactly as they are** in `access_grants` (holder =
  `user_id`, NOT NULL; triggers `check_module_grant`, `access_grant_cascade`,
  `access_grant_revoke_only`; pass-on; scope; dates). No column or constraint
  of that table changes.
- **Title and group grants** go in one new table (Stage 3), with the same
  shape of grant: `holder_kind` ('job_title' or 'function_group'),
  `job_title_id` → `job_titles` and `function_group_id` → `function_groups`
  (exactly one set, checked), `module_id` → `app_modules`, `actions`,
  `effect` (allow / restrict), a **relative** scope ('all' or 'own teams',
  because a role can't name fixed people), `granted_by`, dates, `note`,
  `revoked_at` / `revoked_by` (revoke only, never deleted).
- Foreign keys use **ON DELETE RESTRICT**; groups and titles are deactivated,
  never deleted. A group can't be deactivated while active titles use it
  (Stage 2).
- It's still **one permission engine**: one resolver (`can()`), one Access
  page, one change log. Only the storage of the new holder types is separate,
  so the tested behaviour of person grants can't be disturbed.

### C3. The seven access levels as a safety ceiling

Title and group grants can only **add access inside modules that already
ask `can()`**. They never:
- open **protected** modules (system admin only, unchanged);
- apply to **new starters** or **external** accounts;
- override any of the ~180 hard-coded role checks or any RLS rule that
  doesn't call `can()` (those keep deciding exactly as today);
- give a **sensitive** module through a function group (see C6).

The access level therefore stays the outer limit; grants work only inside it.

### C4. Existing individual grants keep their behaviour

- Rows, triggers, pass-on rules, giver's authority, scope and dates unchanged.
- Today person grants count only for managers and staff admins; that stays.
- **Equivalence check** (in each stage's tests): with no title or group
  grants, `can()` gives the same answer as today for every existing test
  case (full suite, 1,134 checks at the last run, plus a before/after
  comparison of `can()` answers on the local data).

### C5. Module-to-function mapping is separate from granting

- **Mapping** (Stage 4, `function_group_modules`: group ↔ module) only
  says which modules a function's configuration screen offers. **It grants
  nothing.**
- **Granting** is always an explicit grant row (C2). A module mapped to a
  group gives nobody access until a grant is added and approved.

### C6. Sensitive modules and assigned-client access

- Sensitive modules (payroll, identity, contracts, client details and
  people, clinical records) are **never inherited from a parent module**
  (existing rule) and **never granted at function-group level**: only to a
  job title or a person, explicitly.
- **Assigned clients** (Stage 5): client and clinical tables check both the
  module permission **and** a client–staff assignment (client, staff member,
  role on the client, from and to dates) in RLS. A module grant alone never
  opens every client's record.

### C7. RLS and who can see grants

- New tables: RLS on. Read: the system admin; Manager Administrators (to
  configure); each member reads only the rows for **their own** title and
  groups (needed because `can()` runs as the caller). Write: the system
  admin (Manager Administrators later, within their own authority, Stage 3).
- `function_groups` (Stage 1): every member reads names; writes need the
  existing **Roles** settings area (the same people who manage job titles);
  no delete rule.

### C8. Compatibility with the hard-coded role checks

- Nothing in the ~180 role checks changes. The seven QA-007 modules stay
  "Set by role" until each is converted on purpose.
- Only modules whose checks already call `can()` (onboarding, cars, forms,
  reports, built features, enquiries, contracts, staff records, settings
  areas) and new modules can use title and group grants.
- Performance: `can()` gains two indexed lookups (title, groups); measured
  on the large local data before Stage 3 is released.

### Recommended smallest safe approach for Stage 1

- **One table, `function_groups`:** id (uuid), `key` (unique, can't change
  after creation, used by code), name, description, active, order,
  created/updated who and when. Seeded with the six groups.
- **RLS:** members read; insert and update need the Roles settings area
  (`can_admin_area('roles')`); **no delete** (deactivate instead).
- **A small INVOKER guard trigger:** keeps `key` unchanged and fills
  updated who and when. **No new SECURITY DEFINER:** changes are written to
  the change log by the server action (the existing Access page pattern).
- **Screen:** a "Function groups" section on the Roles page (list, add,
  rename, describe, deactivate) for people with the Roles area.
- **Nothing else:** no links to titles, no grants, no change to `can()`, to
  any role check or to anyone's access.
- **Delivery:** live update 92 with undo, round trip, database tests (members
  read; staff can't write; Roles-area holders can; key can't change; nothing
  deleted; six seeded), browser check, completion report.

## Stage 1 implementation record (16 Nov 2026)

Approved by the owner (D-046). **Built and tested; live update 92 waiting for
the owner to review and run on Dev.**

- Files: `supabase/migrations/20270206000001_function_groups.sql`,
  `supabase/live-updates/update-92.sql`, `undo-92.sql`,
  `supabase/tests/function_groups.test.sql`, `src/app/(portal)/settings/roles/`
  (`page.tsx`, `actions.ts` `saveFunctionGroup`, `function-group-forms.tsx`).
  Fresh install rebuilt.
- As approved: one table; members read; Roles-area holders add and change;
  no delete; key can't change; invoker guard; change log written by the
  server action (no new SECURITY DEFINER); six groups seeded. No link to
  titles, grants, `can()` or any role check: nobody's access changes.
- Tests: 12 new database checks; full suite 1,146 pass; lint, typecheck,
  unit pass; build passes; round trip on the local copy (undo matches,
  re-apply matches); browser 7 of 7 (six groups shown, add, logged, rename
  and deactivate, phone width, no errors, a support worker can't open Roles)
  plus the Roles page working before the update (section hidden).
- Rollback: `undo-92.sql` (removes the list; nothing else uses it).

- **Run on Dev by the owner, 17 Nov 2026** (update 92). Stage 1 complete.

## Stage 2 implementation record (17 Nov 2026)

Approved by the owner ("approve", 17 Nov 2026, with the starting mapping).
**Built and tested; live update 93 waiting for the owner to run on Dev.**

- Files: `supabase/migrations/20270207000001_job_title_functions.sql`,
  `supabase/live-updates/update-93.sql`, `undo-93.sql`,
  `supabase/tests/job_title_functions.test.sql`; Roles page
  (`page.tsx`, `forms.tsx`, `actions.ts`). Fresh install rebuilt.
- `job_title_functions` (role ↔ group, ON DELETE RESTRICT both ways):
  members read; Roles-area holders link and unlink; only active groups can be
  linked; a group can't be deactivated while an active role uses it;
  deactivating a role keeps its links. Existing roles linked once by access
  level (support worker and team leader: Service Delivery; manager:
  Management & Administration; staff admin: HR & Workforce; external: Allied
  Health). Roles page: tick groups on add and edit (at least one, checked in
  the browser before sending and again by the server); groups show role
  counts; changes logged (`role_function_groups_changed`). No new SECURITY
  DEFINER. No grants, no change to `can()` or any role check.
- Tests: 10 new database checks; full suite 1,156 pass; lint, typecheck,
  unit, build pass; round trip with five test roles locally (mapping exactly
  as approved; undo matches; re-apply matches); browser: a new role needs a
  group, saves with it and is logged, edit adds a second group, a role can't
  be saved with no group (nothing typed is lost), counts shown, phone width,
  no errors. Local test roles removed afterwards.
- Rollback: `undo-93.sql` (removes the links, restores the Stage 1 guard).
- **Run on Dev by the owner, 17 Nov 2026** (update 93). Stage 2 complete.

## Stage 3: architectural conflict found before building (17 Nov 2026)

Reported to the owner before any Stage 3 code (rule: stop and report).

**Finding (verified):** title and group grants would **not take effect** if
only `can()` and a new grants table were added, because two "gates" in
front of `can()` only look at person grants:

1. **Nine database helpers** used by RLS (`can_manage_cars`,
   `can_manage_compliance`, `can_make_forms`, `can_see_car_reports`,
   `can_see_enquiries`, `can_see_feature`, `can_fill_feature`,
   `can_manage_feature`, `contract_access`) call `can()` only after
   `exists (select 1 from access_grants where user_id = auth.uid() ...)`
   (a speed check added in updates 75 to 78).
2. **The app helper** `given()` (`src/lib/module-access.ts`) asks `can()`
   only for managers and staff admins (`MAY_HOLD`), so other roles' grants
   would be ignored by pages and menus.

The AUD-016 clarification (C8) missed these gates.

**Proposed resolution (for approval):** in Stage 3, also
- add one INVOKER helper, `has_any_grant()` (person grant, or a grant for
  my job title or my function groups), and use it in place of the person-only
  `exists` in the nine helpers (same functions, same SECURITY DEFINER status,
  bodies changed only at that one check);
- let `given()` ask `can()` for any active member except new starters and
  external accounts (the database still decides);
- no RLS policy text changes (policies call the helpers), so the Stage 1
  policies stay as they are.
Equivalence: with no title or group grants, every helper and page gives
today's answer (full suite plus a before/after comparison).

## Decision D-047 (17 Nov 2026): the proper fix (option 3), not option 1

The owner chose the clean end state over widening the person-only gates.

- **Holders of grants:** person (existing `access_grants`, unchanged), job
  title, function group, and **access level** (the default for everyone at
  that level, used to reproduce today's role rules).
- **Precedence:** person → job title → function group → access-level default.
  The first tier with an applicable grant decides; within a tier the nearest
  module level decides and a restriction beats an allow. A person's
  restriction is never overridden.
- **Ceiling:** protected modules stay system admin only; new starters and
  external accounts get nothing inherited; sensitive modules only to a job
  title or person (an access-level default only where today's rule already
  gives that level the access).
- **Stage 3:** the grants table, the new precedence in `can()`, the Access
  page screens, and default grants seeded to match today's role rules. No
  module is switched over in Stage 3, so no access changes.
- **Stage 3b onwards:** each module in turn drops its old role rules and asks
  only `can()`; its defaults already reproduce today's answers, proven by a
  before/after comparison for every role. Order: onboarding, cars, forms,
  reports, built features, enquiries, contracts; then the seven "Set by
  role" modules; Clients built directly on the model (Stage 5).
