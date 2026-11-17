# Care block: plan for approval (cmeprojects, 17 Nov 2026)

Continues the client foundation (client-foundation-plan.md, steps 1 to 5 done:
record, locations, people, safety, services and readiness) and Stage 5
(Clients on the Access page, assigned clients, Case Manager and Intake roles).
Dev only, test data only until the privacy review (SEC-003). Each step is its
own update with tests, a before-and-after check, an undo and a short report.

## Steps (recommended order)

| Step | What it adds | Database | Sensitive? |
|---|---|---|---|
| C1 | **My clients** for staff: their teams' clients and (case managers) their assigned clients, with approved locations, current alerts and worker instructions | none (uses today's rules) | no |
| C2 | **Section switches** for the six optional sections (each organisation turns them on; data kept when off) and **communication preferences** (preferred contact, language, interpreter, accessibility needs) | small | no |
| C3 | **Client documents**: upload, type, expiry date, versions, private file storage; reminders before expiry | table + storage | yes |
| C4 | **Assessments and care plans**: goals, supports, worker instructions, review date; draft, current, archived; history kept | tables | yes |
| C5 | **Reviews**: scheduled reviews with due dates, reminders and outcome; links to the care plan | table + reminders | yes |
| C6 | **Service agreements**: per service and program, start and end, signed, with the document attached | table | yes |
| C7 | **Funding and budgets**: per service or program, amounts and periods (no invoicing) | table | yes |

Later (not in this block): progress notes and support delivery, behaviour
support, rostering against client services (with the HR block), Allied
Health access (Stage 6).

## Access (proposed defaults; changed on the Access page)

Each section is its own part of Clients, so it can be given on its own.
Staff admins have no client access by default (D-052, update 109).

| Section | Managers | Case Manager | Intake officer | Team staff |
|---|---|---|---|---|
| Documents | all clients | assigned, view and add | all clients, view and add | no |
| Care plans | all clients | assigned, view and change | all, view | worker instructions only (own teams' clients) |
| Reviews | all clients | assigned, view and change | no | no |
| Service agreements | all clients | assigned, view | all, view and change | no |
| Funding and budgets | all clients | assigned, view | no | no |
| Communication preferences | all clients | assigned, change | all, change | own teams' clients, view |

## Decisions needed

1. The order above (C1 first, as it helps staff straight away).
2. The access defaults above.
3. Client documents: allowed file types (PDF, images, Word) and size limit
   (suggest 10 MB).
4. Stay on test data until SEC-003 (privacy review) is done.

## Owner's concept for the client list (17 Nov 2026, screenshots; decisions still to come)

The owner shared a concept (layout only; their menu crossed out, not wanted):

- **Client list as a table:** search (name or NDIS number), a filter, an
  "Add client" button; columns name, NDIS number, service, plan management
  (plan-, NDIA- or self-managed), funds used (%), plan status (active, "ends
  in N days" in amber or red).
- **Click a client: a side panel** (the list stays visible), with the name,
  status chips and tabs: Overview (NDIS number, date of birth, phone, suburb,
  service, plan dates, plan management, support coordinator, care alerts as
  chips, goals), Plan budget, Progress notes, Shifts.

How it maps to this plan: Overview uses today's record (details, locations,
alerts, services) plus goals from care plans (C4); plan management, funds used
and plan dates come with funding and service agreements (C6, C7); progress
notes and shifts are the later blocks. Columns and tabs follow the Access
page (a person only sees the columns and tabs for parts they hold). Proposal:
build the table and side panel early with the columns that exist, and add
each column or tab as its step lands.

## Owner notes (17 Nov 2026)

1. **"Participant" or "Client":** every client screen uses the existing
   setting `wording.client` ("What you call the people you support", today
   "Participant" on Dev). It's in the Branding settings area, so the system
   admin can hand it to the Manager Administrator on the Access page (they set
   up their business later). Today the setting exists but client screens don't
   use it yet; the Care block makes them use it.
2. **Every step considers NDIS and Support at Home** (and Private, Other).
   Program-specific parts come from the program, not from code: each program
   has its own rules (date of birth needed already; review rules, funding
   shape, agreement wording next).
3. **C5 reviews (owner's concern): NDIS plan reviews vs Support at Home
   re-assessments.** Proposed design:
   - Each program says what its review is called and how it works: NDIS
     "Plan review" (planned, from the plan end date), Support at Home
     "Re-assessment" (scheduled, and also when the situation changes).
     Private and Other: "Review", optional.
   - **Two kinds of review per client service:** scheduled (a due date,
     from the plan end date or a set interval) and **change of situation**
     (raised any time by staff with a reason, for example hospital stay,
     carer change, decline in health; it becomes due straight away).
   - **Notices:** before a scheduled review is due (days set per program,
     e.g. 90/60/30 for NDIS plan end, 30 for Support at Home), when it's
     overdue, and immediately when a change of situation is raised. They go
     to the client's assigned case manager, else the managers; the bell and
     email, like other notices.
   - Each review records who did it, the outcome and the next due date;
     never deleted. Funding (C7) and agreements (C6) follow the same program
     rules.
