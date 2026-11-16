# QA-007: Change plan: unsupported delegation controls on the Access page

| Field | Value |
|---|---|
| Document ID | QA-007 |
| Title | Change plan: unsupported delegation controls (Tasks, Staff, Teams, Clients) |
| Category | 06 Development and testing |
| Version | 0.1 |
| Status | **Approved by the Product Owner (D-040, D-042) and implemented on 16 Nov 2026** (code only; Dev deploy on push). Document itself Draft |
| Owner / Reviewer / Approver | Technical Lead (the owner) / Technical Lead / Product Owner (the owner) |
| Created | 16 Nov 2026 |
| Related | DEC-001 D-036, MOD-001 §4 and §6, RSK-04, SEC-002 C8, AUD-016 |

## 1. What the Access page does today (verified)

- The permission tree (System settings → Access & delegation, Delegation
  Centre) lists every **delegable** module (`app_modules.delegable`) under its
  menu category (`src/app/(portal)/settings/access/page.tsx`).
- For a Manager Administrator (or a staff admin being given passed-on
  access), each module row has an **On/Off switch** and action buttons
  (`delegation-centre.tsx`, `ModuleAccessEditor`). Saving writes
  `access_grants` rows (`delegation-actions.ts`).
- Tasks, Staff, Teams and Clients already carry a small note, "Managers and
  staff admins already have this." (regex `ALREADY`), but **still show a
  working-looking switch**, and saving creates a grant that no check reads.
- Category headings (Operations, People, Clients & care) also have switches;
  a category grant passes down to these modules in the display, so the rows
  can look "On".
- **Also found:** Staff requests (`hr.requests`), Due dates and escalation
  (`workflows.sla`) and Request approvals (`workflows.request_rules`) are
  delegable and **also not read by any check**. They show "Can be set now;
  takes effect in a later update." Not covered by D-036; **owner decision
  needed** whether to include them (recommended: yes, same treatment).
  MOD-001 §4 wrongly listed `hr.requests` as not delegable; corrected with
  this plan's implementation.

## 2. Proposed change (smallest safe; UI and save action only)

No database, migration, permission engine (`can()`), module catalogue or
RLS change. Modules, pages and current role-based access unchanged.

1. **New shared list** `src/lib/access-by-role.ts`: the module ids whose
   access is still set by role (`ops.tasks`, `people.staff`,
   `people.teams`, `clients.list`, plus the three in §1 if approved), with a
   helper `byRole(id)`.
2. **Access page tree** (`delegation-centre.tsx`):
   - these rows show a grey **"Set by role"** badge instead of On/Off, **no
     switch and no action buttons**, and the line: "Managers, staff admins
     and the system admin have this through their role. It can't be given
     or removed here yet.";
   - a category heading whose delegable modules are all "set by role" (or
     settings areas, which are changed further down) gets no switch either
     (today: Operations, People, Clients & care); other categories keep theirs;
   - if a person already has an old grant on one of these modules, the row
     says "An earlier setting here has no effect; it's kept as it is.";
   - the existing `ALREADY` note is replaced by the above (one wording).
3. **Save action** (`delegation-actions.ts`): refuse a **new or changed**
   grant for a "set by role" module ("Tasks is set by role and can't be
   given here yet."), and **leave existing grants on those modules
   untouched** when other changes are saved (not revoked, not edited). No
   data changes.

Files: `src/lib/access-by-role.ts` (new), `src/app/(portal)/settings/access/delegation-centre.tsx`,
`src/app/(portal)/settings/access/delegation-actions.ts`. Docs after
implementation: MOD-001, SEC-002 C8, RSK-04, DEC-001.

## 3. Tests

- Lint, typecheck, unit (`npm run lint && npm run typecheck && npm test`).
- Database suite (`npm run test:db`): must stay unchanged (no SQL change).
- Browser (system admin and a Manager Administrator):
  - the four (or seven) rows show "Set by role", no switch, no actions;
  - Operations, People, Clients & care headings have no switch; Apps, HR and
    the others keep theirs;
  - a connected module (for example Manage cars) still switches and saves,
    and its grant row appears;
  - a person with an old grant on Tasks: the note shows, and saving another
    change leaves that grant exactly as it was (checked in `access_grants`);
  - no page errors; phone width layout.
- Server refusal: a save request including a new `ops.tasks` entry returns
  the refusal and writes nothing (checked in `access_grants`).

## 4. Rollback

Revert the one commit (code only). No database or data to restore.

## 5. Release

Its own commit and deploy to Dev; not combined with QA-008.

## 6. Implementation record (16 Nov 2026)

- Scope extended by the owner to all seven modules (D-042).
- **Labels (verified against each page's guard):** "Set by role": Tasks,
  Staff, Teams, Clients, Staff requests. "Not available": Due dates and
  escalation, Request approvals (role plus settings area). The last two sit
  under the protected System settings module, so the Access tree never showed
  them; no control existed to remove, and the server now refuses grants.
- Files: `src/lib/access-by-role.ts` (new), `src/app/(portal)/settings/access/delegation-centre.tsx`,
  `src/app/(portal)/settings/access/delegation-actions.ts`. No database,
  migration, RLS, `can()` or catalogue change.
- Headings: People & organisation and Clients & care show no switch and say
  "Nothing in this group can be given here"; Operations keeps its switch
  because Forms (in that group) follows the Access page.
- Tests: lint, typecheck, unit (54 modules match); database suite 1,132
  checks pass (unchanged); production build passes; browser 17 of 17 (each
  row's label and no switch, headings, old Tasks grant noted and untouched
  after saving another change, a connected module still saves, no new grants
  on the seven, phone width, no errors). Local test rows used for the browser
  test (a Manager Administrator and an old Tasks grant) were ended afterwards.
- **Not tested end to end:** a hand-crafted save request for a new grant on
  one of the seven (the screen can't produce one). The refusal was checked by
  reading the code path only.
- Rollback: revert the commit.
