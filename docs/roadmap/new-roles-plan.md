# New roles: case manager, intake and assessment, payroll, rostering (cmeprojects)

Plan for approval, 15 Nov 2026. Nothing built.

## How roles work today

- An **access level** (role) decides what someone can do: new starter,
  support worker, team leader, manager, staff admin, system admin, external.
- **Job titles** sit on top (for example "Coordinator" on the team leader
  level), so most new titles need no code.
- A new **access level** is needed only when the permissions differ from every
  existing one. That's the case for all four: none of them is a centre
  manager, and none is a support worker.

## Safe by default

The portal checks roles in about 180 places, always by naming the roles that
**are** allowed. A new role is in none of those lists, so on day one it gets
only what every staff member gets (their own tasks, requests, onboarding,
directory), never manager powers by accident. Each role is then given exactly
what's agreed below, and nothing else.

## Proposed roles and default access

| Role (label) | Is | Isn't | Default access |
|---|---|---|---|
| **Case manager** | Responsible for a set of clients: sets them up and keeps their record right | A centre manager: no staff management, roles, approvals of staff, all-tasks view, reports | Clients: add clients; edit details, locations, people, safety and services **for their clients**; sees those clients' tasks. See questions 2 to 4. |
| **Intake and assessment officer** | First contact for new clients: takes referrals, sets up the new client record and does assessments | A case manager or manager: doesn't run ongoing clients | Clients: add new clients; fill in details, people, safety, locations (not approved) while the client is **to check (pending)**; read only once active. Assessments when that section is built. Can't make clients active or approve locations. |
| **Payroll officer** | Pays staff | HR or a manager | Payroll records (bank, super, tax) of all staff, read and check; TFN reveal **only if ticked** on the Access page. No client data. |
| **Rostering officer** | Plans shifts (ready for the rostering module) | A manager | Staff availability, leave and cleared-to-work status (read only); clients' approved locations, current alerts and readiness (read only). No contact details, identifiers, pay or risk notes. |

Managers, the system admin and (today) staff admins keep their current
client access.

## Delegation

Manager Administrators can already pass on what they hold to staff admins.
For client setup ("Clients" module), they'd also be able to pass it to **any
active staff member** (for example a senior support worker), with the usual
limits: only what they hold themselves, scoped to all clients or chosen
teams, with an end date if wanted, logged, and never sensitive parts unless
ticked separately.

## Build steps (each its own update, tests, round trip, approval)

1. **Roles exist** (one small update that only adds the three access levels,
   run on its own because the database needs it committed before use), plus
   labels, help text, role pickers, job titles and onboarding targeting.
   Nobody has them yet, and they grant nothing extra yet.
2. **Intake and assessment officer access** (new and pending clients).
3. **Case manager access** to clients (with the scope you choose), and the
   "case manager" field on a client if needed (question 2).
4. **Payroll officer access** to payroll records (reusing the payroll access
   rules; TFN stays its own tick).
5. **Rostering officer access** (read only, as above).
6. **Delegation** of client setup by Manager Administrators to other staff.

## Questions for the owner

1. **Names:** "Case manager", "Intake and assessment officer", "Payroll
   officer", "Rostering officer"? (Job
   titles can still be anything, for example "Roster coordinator".)
2. **Case manager scope:** (a) only clients they're named case manager on
   (a field on each client; recommended), (b) clients of their teams, or
   (c) all clients?
3. **Case manager powers:** may they make a client **Active** and **approve
   locations**, or keep those for managers as the final check?
   (Recommended: managers approve; case managers prepare.)
4. **Staff admins:** keep their current client access (they have it today),
   or remove it now that case managers exist?
5. **Payroll officer and TFN:** reveal TFN by default, or only when ticked on
   the Access page? (Recommended: only when ticked.)
6. **Rostering officer before rostering exists:** give the read-only access
   now, or create the role now and give access with the rostering module?
7. **Intake and assessment officer:** edit clients only while they're to
   check (pending), then read only (recommended), or keep editing after the
   client is active? And when the client becomes active, hand over to a named
   case manager?
