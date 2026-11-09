# Manager dashboard, People and HR release (cmeprojects)

Staff Portal · © cmeproject · 9 November 2026 · Development copy (`dev`)

## Safety

- **Checkpoints:** `restore-before-hr` (before Part 1), `restore-before-hr-part2`, `restore-before-hr-part3` and `restore-before-hr-part4`.
- **Database updates:** 55, 56 and 57, each safe to run again and each with an undo file. The app keeps working on a copy that hasn't run them yet; the new parts simply stay hidden.

| Update | What it adds | Undo |
|---|---|---|
| 55 | HR Pack switches; staff profiles (directory card and private details) | `undo-55.sql` |
| 56 | My requests with configurable approvals, escalation, leave periods and shift changes | `undo-56.sql` |
| 57 | "Complete your profile" in onboarding (needs 55) | `undo-57.sql` |

## What was built

### Part 1: Manager dashboard
- **Clickable tiles:** Open, Overdue, Waiting for approval, Escalated and Due this week open a side panel. It lists the tasks with status, priority, person and due date, gives a quick look on hover, opens the task in the same tab, and has a **View all in Tasks** link that keeps the filter.
- **Quick actions in the side panel:**
  - Waiting for approval: **Approve**, or **Send back** with a reason.
  - Escalated: **Escalation dealt with**.
  - Every row: **Open task**.

  The database still checks that the person is allowed to act.
- **Charts:**
  - **Task status doughnut:** on track, overdue, escalated and waiting for approval. Each task is counted once (escalated first, then waiting for approval, then overdue).
  - **Open tasks by person:** flags anyone carrying far more than the average. Click a person to see their open, overdue and due-this-week tasks.
  - **Overdue by register:** click a register to see its overdue tasks, with links to the filtered list and the register.
  - **How late overdue tasks are:** 1–7 days, 8–30 days, over 30 days.
  - **Opened and closed per week**, over 8 weeks.
- **Insights:** % finished on time (last 30 days), due this week, requests waiting.
- **Tasks page filters** for every link: overdue, past due, escalated, waiting for approval, due this week, on track, by person and by register.

### Part 2: Profiles, My account and the Directory
- **Profile layout:** a business-style profile card with photo, name, preferred name, job title, department, email, work phone, role and team, and skills and qualifications.
- **Private details:** address, emergency contact, employment type, start date, employee ID and usual weekly availability. Only the person, people who manage staff, and their team leader (for availability) see these.
- **My account:** shows your card, with an edit form. **Staff directory**, for everyone: photo cards with search by name, role, team or skill.
- **Profile page:** profile, open tasks, compliance link, and their requests (for people who manage staff). Staff admins and managers edit employment details there.
- **Who can change what:** staff edit their own contact details, skills, private details and availability. Only people who manage staff change department and employment details. All changes go through the database, which enforces this.
- **Photos everywhere:** photos and names now show on tasks (looked after by, and every activity entry), requests, the directory and dashboards.
- **Complete your profile:**
  - **Who needs it:** while Staff profiles is on, everyone except the system admin needs a contact phone and an emergency contact.
  - **Where it shows:** step 1 of My onboarding, plus a reminder banner on every page until it's done.
  - **New starters:** can't be given a role until it's done.
  - **Finishing:** completing the profile last finishes onboarding straight away.

### Part 3: My requests
- **Types:** leave (annual, personal/carer's, unpaid, long service, compassionate, other), shift swap, shift change, availability change, timesheet correction, HR or employment enquiry, and other.
- **Each request has:** a reference (REQ-0001), sent date, details, status (Pending, More info needed, Approved, Declined, Withdrawn), who's approving, comments, and full history.
- **Approvals:**
  - **Leave, swaps, shift and availability changes:** the team leader, then a manager.
  - **HR enquiries and timesheets:** a staff admin, then a manager.
  - **Other requests:** a staff admin.
  - **No team leader:** the managers approve instead.
  - **Two steps means two people:** the final approval must come from someone else when possible.
  - **Shift swaps:** the colleague accepts first.
- **Settings → Request approvals (system admin), per type:** first approver, optional second approver, who's also told, and escalation (after so many days, to whom). The scheduled job sends the escalations, once per request.
- **What approval actually changes:**
  - **Leave:** becomes a leave period.
  - **Availability change:** updates the person's weekly availability.
  - **Swaps and shift changes:** recorded for both people, ready for rostering.
- **Where it shows:**
  - a **My requests** menu item for every staff member
  - a **Waiting for me** tab for approvers
  - **All requests** for people who manage staff
  - a **Requests waiting** tile on the manager, staff admin and team leader dashboards
  - request notifications in **Settings → Notifications**

### HR Pack
- A premium package, **on by default**. Settings → Features → HR Pack has a switch for the whole pack and for every part:
  - Staff profiles and directory
  - My requests, and each of the 7 request types
  - Compliance and onboarding, and each of its 4 parts
- Switching the HR Pack off switches every part off, down to the third level. Records are kept.

### Part 4: Permissions and Save buttons
- **Role changes:** proven by a database test.
  - Creators keep managing the forms they made after a role change.
  - They can't make new ones if their new role isn't a form maker.
  - Settings delegated to them as a staff admin are **not** kept after a demotion.
  - If the creator leaves, the system admin still manages their forms.
  - Who made each record is kept.
- **Save buttons on editing forms:** greyed out until something changes, "Saving…" while working, can't be pressed twice, and greyed out again after saving.
  - **Where:** profiles, task Edit details, your name, the staff editor, register setup (4 forms), records, client teams and request approvals, on top of settings and forms (done earlier).
  - **If saving fails:** the profile and staff forms keep what was typed.
  - **Leaving with unsaved changes:** every form that tracks changes warns you first.

### Also
- **Phone numbers:** every phone field (profiles, emergency contact, website enquiry, support number) has a country picker, Australia by default. Australian numbers must be a real mobile (04…) or landline with area code; other countries are checked for length. Numbers are saved in one format, for example +61 412 345 678, and the server checks them again. The emergency contact name refuses a phone number.
- **System admin dashboard:** a branded banner with the headline numbers, and colour-coded tiles with icons.
- **Roadmap:** `docs/roadmap/hr-and-workforce.md`, with qualifications and training compliance first, then rostering.

## Tests

| Check | Result |
|---|---|
| Database tests (all files, including 5 new ones for this release) | 739 passed, 0 failed |
| New database tests | HR Pack switches and profiles 14, My requests 27, profile requirement 8, role-change ownership 7, client teams 7 |
| Browser checks of the new workflows | Board 8 of 9 (the 1 was the test clicking the middle of the doughnut), profiles and directory 16 of 17 (the 1 was missing local test data), requests and approvals 15 of 15, Save buttons 8 of 8 |
| Re-crawl, every page, every role | 662 visits, 174 unique pages, 6 roles: no errors or broken pages. Found sideways scrolling on phones on My account and profile pages (fixed and rechecked) |
| Lint, typecheck, production build | Clean |

## Not done or limits

- **Rostering:** there's no roster yet, so approved swaps and shift changes are recorded per person (`shift_changes`), ready to update a roster later.
- **Leave balances and a leave calendar:** not built (roadmap item 3).
- **Timesheet corrections:** status and comments only, as there's no timesheet module.
- **Onboarding progress bars:** "Complete your profile" is part of onboarding, but the Compliance progress bars count only documents, trainings and uploads.
- **Emails:** request emails go through the existing email system. They need the live email service and weren't delivery-tested here.
- **Offboarding:** not built. It's on the roadmap as a future HR Pack part.

## Readiness

Ready to try on Development after running updates 55, 56 and 57. The new workflows completed end to end in testing, permissions are enforced in the database and covered by tests, and existing features passed the full re-crawl.
