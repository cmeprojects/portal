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

## Stage 3 implementation record (17 Nov 2026)

Approved by the owner (D-047; "go further, just give me a briefer").
**Built and tested; live update 94 waiting for the owner to run on Dev.**

- Files: `supabase/migrations/20270208000001_access_baselines.sql`,
  `supabase/live-updates/update-94.sql`, `undo-94.sql` (restores `can()`
  exactly as it was, taken from the database definition),
  `supabase/tests/access_baselines.test.sql`; Access page
  (`page.tsx` section, `role-group-access.tsx`, `baseline-actions.ts`).
- `access_baselines`: holder = job title, function group or access level
  (exactly one); module, actions, allow/restrict, scope (everyone's / own
  teams'); revoked, never deleted or edited; ON DELETE RESTRICT links.
  Guard: only `grant_ready` modules; never protected, settings areas or staff
  records; sensitive never to a group; system admin, new starter and
  external can't hold access-level defaults. RLS: system admin and Manager
  Administrators read all; members read their own title, groups and level;
  the system admin writes any; Manager Administrators write groups and
  roles within their authority (below, D-048).
- `can()`: person grants first (unchanged); then job title, function
  groups, access level (first tier with an applicable grant decides; nearest
  module level; restriction beats allow); only for `grant_ready` modules;
  never for new starters or external accounts.
- `app_modules.grant_ready` (new, default false): set to true when a module
  is switched over (Stage 3b onwards). **No module is switched over in this
  update, so nobody's access changes.**
- **Change from D-047's wording:** access-level defaults are seeded with each
  module's switch-over, not all in Stage 3, because many of today's rules
  come from settings (for example "who manages cars" is a list of roles
  chosen in System settings). Same end result, no access change either way.
- Tests: 25 new database checks (precedence, ceiling, sensitive, protected,
  staff records, scope, revoke-only, who reads, helpers unchanged); full
  suite 1,180 pass (proves nothing changed); round trip on the local copy
  (undo matches, re-apply matches); browser 7 of 7 (explains nothing is
  switched over; with one module marked locally for the test: a group grant
  saves, is logged, can be set back and is kept in history; phone width; no
  errors; not shown to a manager); lint, typecheck, unit, build pass.
- **Manager Administrators (D-048, added 17 Nov 2026 before update 94 was
  run):** an MA may give a function group or a job title access only to a
  part they hold themselves with "may pass on" (their own top-level allow
  grant, covering the part), and only actions they hold
  (`baseline_grant_allowed`, INVOKER). They can't set access-level defaults
  (system admin only). Their grants stop counting the moment they stop being
  an MA (checked in `can()`); `by_system_admin` is recorded at insert
  because the system admin is hidden from staff by profiles RLS. Revoke:
  the system admin, or whoever gave it. Access page: shown to MAs with
  groups and roles only, the parts and actions the database says they may
  pass on, and others' grants read-only. Tests: 34 checks in
  access_baselines (9 new); full suite 1,190 pass; round trip clean;
  browser 6 of 6 as an MA and the system admin.
- Rollback: `undo-94.sql`.
- **Next:** Stage 3b: switch over the first module (My onboarding /
  onboarding management) with defaults reproducing today's rules and a
  before/after proof for every role.

## Stage 3b implementation record: Onboarding (17 Nov 2026)

Approved by the owner (D-049, option A). **Built and tested; live update 95
waiting (run after 94).**

- Files: `supabase/migrations/20270209000001_onboarding_switch_over.sql`,
  `supabase/live-updates/update-95.sql`, `undo-95.sql`,
  `supabase/setup/verify-95-after.sql` (read only),
  `supabase/tests/onboarding_switch.test.sql`; app: `src/lib/module-access.ts`
  (onboarding checks are `can()` only), `src/lib/settings.ts` (old rule
  removed), compliance pages, menu, System settings (old control hidden).
- `hr.onboarding` and its two submodules marked `grant_ready`.
- Defaults copied once from "Who manages Compliance": each ticked role gets
  full onboarding; managers too if there's no active staff admin when it
  runs (the old fallback, settled once); managers see progress (everyone),
  team leaders see progress (own teams). A fresh install starts with staff
  admins only (least privilege). Skipped while any live access-level default
  for onboarding exists, so re-running adds nothing.
- `can_manage_compliance()` = `can('hr.onboarding', 'approve')` (same
  function, so every policy and function using it follows). `people_admins()`
  (who gets onboarding notices) = staff admins plus access levels given
  onboarding management.
- Grants added by a database update (no signed-in person) count as the
  system admin's (guard change).
- **Behaviour changes, by design:** (1) the "managers while there's no staff
  admin" rule no longer switches on and off by itself; (2) a person's own
  block on onboarding now beats their access level; (3) roles and function
  groups can now be given onboarding. Not changed in this stage:
  `compliance_status()` / `work_status()` still let managers and team leaders
  read progress data directly (also used by People); to switch with People.
- Proof: verify-95-after on the local copy: 313 people, 0 changed. Tests: 28
  new checks; older tests that relied on the setting or the automatic
  fallback updated (compliance, round3, manager_admins, access_baselines
  counts); full suite 1,218 pass; round trip clean; browser 20 of 20 (system
  admin, staff admin, manager, team leader, support worker: same pages and
  manage rights as before; System settings no longer offers the old control;
  Access page shows the copied default); lint, typecheck, build pass.
- Rollback: `undo-95.sql` (copied defaults kept but inactive).
- **Next:** Cars (`vehicles.manager_roles`), same pattern.

## Stage 3b implementation record: Cars (17 Nov 2026)

Owner: "94 and 95 done, go ahead with cars". **Built and tested; live update 96
waiting.**

- Files: `supabase/migrations/20270210000001_cars_switch_over.sql`,
  `update-96.sql`, `undo-96.sql`, `supabase/setup/verify-96-after.sql`,
  `supabase/tests/cars_switch.test.sql` (18 checks); app: `module-access.ts`
  (`managesCarsFor()` = `can('ops.cars.manage', 'configure')`), `cars.ts`
  (old rule removed), cars pages and both phone apps, System settings (old
  control hidden).
- Only `ops.cars.manage` switched; using a car and the Cars app unchanged.
- Defaults copied once from "Who manages cars" (full Manage cars per role).
- `can_manage_cars()` = Cars on and the check; `car_managers()` (notices) =
  system admin plus access levels given Manage cars. Car reports: car
  managers still see them (follows the check); "Who sees car reports"
  unchanged (reports switch later).
- Small tightening: the system admin now needs the second sign-in step
  (when MFA is required) to manage cars, like every other part.
- Older engine tests now undo the switch-overs at their start so they keep
  testing person grants on their own.
- Proof: verify-96-after on the local copy: 313 people, 0 changed; full suite
  1,236 pass; round trip clean; browser 16 of 16 (system admin and manager manage cars and see car reports; staff admin, team leader, support worker refused; old control gone; Access page shows the default); lint and typecheck pass.
- Rollback: `undo-96.sql`.

## Stage 3b implementation record: Forms and Reports (17 Nov 2026)

Owner: "96 done, go ahead with everything". **Built and tested; live updates
97 and 98 waiting.**

- Update 97: `workflows.forms` switched; defaults from "Who can make forms";
  `can_make_forms()` = system admin, or form builder on and
  `can('workflows.forms', 'create')`. Filling in forms unchanged.
- Update 98: the three reports (and their parent) switched; defaults from
  "Who sees reports" (tasks), "Who sees the compliance report" (plus managers
  if no staff admin when run; fresh install without) and "Who sees car
  reports"; `can_see_car_reports()` = car managers or the check. App report
  checks are `can()` only; the compliance report links to the Access page.
- Files: migrations `20270211000001_forms_switch_over.sql`,
  `20270212000001_reports_switch_over.sql`; `update-97/98.sql`,
  `undo-97/98.sql`; `supabase/setup/verify-98-after.sql`;
  `supabase/tests/forms_reports_switch.test.sql` (19 checks); four older
  tests moved from the settings to defaults.
- Proof: verify-98-after on the local copy, 311 people x 4 parts, 0 changed;
  full suite 1,255 pass; round trips clean; browser: reports 16 of 16 and
  forms 4 of 4 by role; lint and typecheck pass.
- Speed: the policies that use the switched helpers already call them once
  per statement (`(select helper())`, Stage 1 form), so `can()` runs once per
  query, not per row. `can_manage_form(id)` stays per row (unchanged, not
  part of these updates).

## Addendum: Stage 1A cross-check (17 Nov 2026, review only)

The owner asked to cross-check the "Stage 1A architecture clarifications"
brief against what is now built (Stages 1 to 3b, updates 92 to 98). Nothing
was changed for this addendum.

| Brief item | Status now | Finding |
|---|---|---|
| 1. Grant holder design | Built (update 94) | Separate table `access_baselines` with nullable FKs (job title, function group, access level), check "exactly one holder", ON DELETE RESTRICT, partial unique indexes (one live grant per holder and part), revoke only. `access_grants` (person grants) unchanged. Matches the brief's first option, in a separate table. **Differs from C2:** no start or end dates on role, group and level grants (not needed yet); access level added as a holder (D-047). |
| 2. Module mapping vs granting | Partly built | Title → group mapping built (`job_title_functions`, update 93). Module ownership table (`function_group_modules`) **not built** (planned Stage 4); nothing grants by mapping. New modules start with `grant_ready` false and no grants. |
| 3. Access level as a ceiling | **C3 no longer true** | For switched parts (onboarding, cars, forms, reports) a job title or group grant can give access the access level wouldn't have (tested: a support-worker title given Manage cars). Hard limits that do hold: protected parts system admin only; new starters and externals inherit nothing; sensitive parts never through a group; staff records and settings areas keep their own rules; person grants only for managers and staff admins; only the system admin, or a Manager Administrator within what they hold, can grant. **Owner decision needed:** keep it this way (governance by who can grant) or add a per-level maximum before switching the hard-coded parts. |
| 4. Existing title migration | Done (update 93, owner approved the mapping) | Titles kept their IDs, assignments and levels. **To reconfirm:** external titles were mapped to Allied Health by default; the brief says not to assume that. Changeable on the Roles page; mapping grants nothing by itself. |
| 5. RLS and resolver | Built | `can()` is INVOKER and reads grants through RLS (members read their own title, groups and level); no recursion (policies don't call `can()`); Manager Administrators limited by `baseline_grant_allowed` (INVOKER); nobody edits their own grants; person grants unchanged; no new SECURITY DEFINER (existing helpers now call `can()`); helpers run once per statement. Not done: a separate timing benchmark for 95 to 98. |
| 6. Allied Health and client assignment | Not built (Stage 5 and 6) | Agreed requirements: assignment plus permission, dated assignments, expiry removes access without deleting records. |
| 7. SaaS tenancy | Unchanged (D-038) | Separate database per customer; `org_id` present on new tables but not a security boundary. |
| 8. Stage plan | Ahead of the brief | Stages 1, 2, 3 and 3b (four parts) built; remaining: hard-coded parts, Stage 4 (module mapping, remove old role logic), 5 (clients), 6 (multiple titles, programs, Allied Health). |

**Recommendation:** no need to redo Stage 1. Before switching the hard-coded
parts, the owner decides (a) ceiling or no ceiling, (b) the external →
Allied Health default.

## Stage 3b implementation record: Staff requests (17 Nov 2026)

Owner approved the order for the parts that share the built-in people-manager
rule ("yes go ahead with that order"). **Built and tested; live update 99
waiting.**

- `hr.requests` switched. In the policies on `requests`, `leave_periods` and
  `shift_changes`, and in `request_action` (who may comment),
  `can_manage_people()` is replaced by `can('hr.requests', 'view')` (once per
  statement). `can_manage_people()` itself is unchanged (still used by Staff,
  Teams, Clients until they switch).
- Defaults: managers and staff admins, view, everyone's (today's rule).
- Unchanged: who approves (Request approvals rules), the person and their
  swap partner, team leaders seeing their team's requests, leave and shift
  changes (a team rule, not a module grant).
- App: the Staff requests page and menu use the check; team leaders keep the
  page for their team. Access page: Staff requests is grantable (removed from
  the QA-007 "set by role" list).
- Files: migration `20270213000001_staff_requests_switch_over.sql`,
  `update-99.sql`, `undo-99.sql`, `supabase/setup/verify-99-after.sql`,
  `supabase/tests/staff_requests_switch.test.sql` (12 checks).
- Proof: verify-99-after on the local copy, 313 people, 0 changed; full suite
  1,267 pass; round trip clean; browser 14 of 14 (system admin, manager,
  staff admin see all requests; team leader sees their team's; support
  worker refused); lint and typecheck pass.

## Stage 3b implementation record: Teams (17 Nov 2026)

**Built and tested; live update 100 waiting** (owner runs 99 onwards later).

- `people.teams` switched. Policies: "managers and admins manage teams"
  (teams) uses `can('people.teams', 'edit')`; "managers change team members"
  and "managers set team leaders" use the check and still exclude staff
  admins from direct writes (as before). `set_team()` uses the check; staff
  admins still send membership changes for approval while
  `people.staff_admin_team_approval` is on (a workflow rule, kept).
- Defaults: managers and staff admins, all actions.
- App: Teams page, its actions and the menu use the check; Teams is grantable
  on the Access page (removed from the QA-007 list).
- Noted, unchanged (pre-existing): `request_team_change()` doesn't check who
  asks; a manager still decides every request.
- Files: migration `20270214000001_teams_switch_over.sql`, `update-100.sql`,
  `undo-100.sql`, `supabase/setup/verify-100-after.sql`,
  `supabase/tests/teams_switch.test.sql` (14 checks).
- Proof: verify-100-after on the local copy, 313 people, 0 changed; full
  suite 1,281 pass; round trip clean; browser 10 of 10; lint and typecheck
  pass.

## Stage 3b implementation record: Staff (17 Nov 2026)

**Built and tested; live update 101 waiting.**

- `people.staff` switched. `can_manage_people()` replaced by
  `can('people.staff', 'view')` in the read policies (invitations,
  staff_private, people_change_requests, work_overrides) and
  `can('people.staff', 'edit')` in the write policies (invitations,
  profiles) and functions (`log_admin_action`, `give_conditional_role`,
  `guard_invitation`, `remove_avatar`, `guard_profile_update`).
  `compliance_status` and `work_status`: "staff managers" = Staff (view);
  "managers" = Onboarding (view) for that person (finishes update 95; team
  leaders still their team's).
- Defaults: managers and staff admins, all actions.
- Unchanged: `can_manage_role` (which roles someone may give), staff admin
  approval rules, managers decide change requests, "Who can invite", staff
  records grants (names need Staff details access), system-admin-only
  actions. `can_manage_people()` itself kept for Clients and car clients.
- Note: Staff is a normal (not sensitive) part, so it can be given to a
  whole function group; that includes private contact details
  (staff_private). Mark it sensitive later if the owner prefers roles and
  people only.
- App: Staff page, actions, menu, invite page and the People panel use the
  check; Staff grantable on the Access page.
- Files: migration `20270215000001_staff_switch_over.sql`, `update-101.sql`,
  `undo-101.sql`, `supabase/setup/verify-101-after.sql`,
  `supabase/tests/staff_switch.test.sql` (16 checks).
- Proof: verify-101-after locally, 313 people, 0 changed; full suite 1,297
  pass; round trip clean; browser 10 of 10; lint and typecheck pass.

## Stage 3b implementation record: Due dates and Request approvals (17 Nov 2026)

**Built and tested; live update 102 waiting.**

- Request approvals (`workflows.request_rules`): already decided by the HR
  settings area on the page and in the database (`can_admin_area('hr')`).
  Now catalogued as part of that settings area (`legacy_kind` settings,
  `legacy_area` hr), so `can()` gives the same answer and the Access page
  gives it with the HR settings area. No access change.
- Due dates (`workflows.sla`): "managers always" is now a grant
  (`can('workflows.sla', 'configure')`, default managers); the Tasks settings
  area still works. Policy "managers change the SLA", the SLA page, the menu
  and the setting save check use it.
- Both removed from the QA-007 "not available" list; all seven QA-007
  modules are now handled except Tasks and Clients.
- Files: migration `20270216000001_sla_request_rules_switch_over.sql`,
  `update-102.sql`, `undo-102.sql`, `supabase/setup/verify-102-after.sql`,
  `supabase/tests/sla_request_rules_switch.test.sql` (11 checks).
- Proof: verify-102-after locally, 313 people, 0 changed; full suite 1,308
  pass; round trip clean; browser 9 of 9; lint and typecheck pass.

## Stage 3b implementation record: Tasks (17 Nov 2026)

Owner chose option A (switch together with the faster task check). **Built
and tested; live update 103 waiting.**

- `ops.tasks` switched; default managers (view, everyone's tasks).
- `tasks` read policy rewritten set-based: system admin or
  `can('ops.tasks', 'view')` (once per query), or assigned / made by me, or I
  help on it, or (teams on and team leader or above) assigned to or made by
  someone in a team I lead (same as `leads_user`). `task_helpers`: own rows,
  the check, or `can_see_task`. `task_events` and `task_attachments`: follow
  the task (exists on `tasks`, through its policy). `can_see_task()` (used
  by the task functions) uses the check instead of the manager role.
- Unchanged: who may change a task (assignee, maker, team leader, register
  managers), register and approval rules, limited task roles.
- Proof: tasks and timelines compared row by row (md5 of ids) before and after
  for 11 people across every role, including team leaders and support
  workers: identical. Time per person 9 to 13 s before, 8 to 18 ms after
  (10,515 tasks, 4,537 timeline entries, local copy). Tests: 18 new; full
  suite 1,326 pass; round trip clean; lint and typecheck pass.
- Files: migration `20270217000001_tasks_switch_over.sql`, `update-103.sql`,
  `undo-103.sql`, `supabase/tests/tasks_switch.test.sql`.
- All seven QA-007 "set by role" modules are now handled except Clients
  (Stage 5).

## Stage 4 implementation record (17 Nov 2026)

Owner: "go ahead". **Built and tested; live update 104 waiting.**

- `function_group_modules` (group, part; primary key both; ON DELETE
  RESTRICT): which parts each group looks after. **Grants nothing**; a test
  proves a mapped group's people get no access from it. Members read;
  whoever looks after the Roles settings area maps and unmaps. Guard: active
  groups only; top-level parts only; never My workspace or protected parts.
- Starting mapping: Management & Administration 16 parts, HR & Workforce 8,
  Service Delivery 4, Care & Coordination 3, Finance & Accounts 2, Allied
  Health 2. Tasks and Forms are shared by several groups.
- Future-module rule (catalogue test): every active part except My
  workspace and protected parts belongs to at least one group and has a
  sensitivity and actions; a new part starts with `grant_ready` false and no
  grants, so only the system admin has it until approved.
- Screens: Roles page, each function group lists the parts it looks after
  (tick boxes, change logged); Access page lists "This group's parts" first
  for a group or role.
- Removing old role code: the role-only list (QA-007) now holds only Clients;
  every other part asks `can()`. `can_manage_people()` remains for Clients
  and car clients (Stage 5).
- Files: migration `20270218000001_function_group_modules.sql`,
  `update-104.sql`, `undo-104.sql`,
  `supabase/tests/function_group_modules.test.sql` (13 checks).
- Proof: full suite 1,339 pass; round trip clean; lint and typecheck pass.
