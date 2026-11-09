# HR and workforce roadmap (cmeprojects)

Staff Portal · © cmeproject · November 2026

Where the HR Pack could go next, in the order that matters most for an NDIS
and aged care provider. None of this is built yet. Each item builds on what
exists today; nothing needs rebuilding.

## What exists now (the foundations)

| Piece | Where it lives | What later modules reuse |
|---|---|---|
| HR Pack switches | `features` (`hr`, `hr_profiles`, `hr_requests`, `hr_req_*`, `compliance`) | Each new module is one more part with its own switch |
| Staff profiles | `staff_directory`, `staff_private` | Contact, employment details, skills, weekly availability |
| My requests | `requests`, `request_events`, `request_types` | Configurable approvers, two-step approval, escalation, history |
| Leave periods | `leave_periods` (from approved leave) | Leave calendar, balances, rostering |
| Shift changes | `shift_changes` (from approved swaps and changes) | Rostering |
| Compliance and onboarding | `compliance_items`, `compliance_records` | Expiry dates, uploads, checking, reminders |
| Notifications | `notify()`, bell, emails, Notifications settings | Every reminder below |
| Role dashboards | `role-dashboard.tsx` (one small piece per tile) | New tiles per module |

## Recommended order

### 1. Qualifications and training compliance (highest priority)
**Why first:** NDIS Practice Standards and aged care rules need proof of
current worker screening, First Aid, CPR, manual handling and medication
training. Lapsed checks are an audit finding and a risk to participants.

- A **qualifications library** (NDIS Worker Screening, WWCC, First Aid, CPR,
  Medication, Manual handling, Driver's licence), each with how long it lasts.
- Each person's qualifications with **expiry dates and evidence uploads**,
  checked by a staff admin (reuses compliance uploads and checking).
- **Reminders** 60, 30 and 7 days before expiry, and on the day, to the person
  and the staff admin; an **expired** flag on dashboards and the directory.
- **Required by role** (for example Medication for support workers): missing
  ones count in onboarding and the compliance report.
- Database: a `qualifications` table plus `staff_qualifications`
  (person, type, issued, expires, file, checked by). About one milestone.

### 2. Workforce availability and rostering
- A **roster** of shifts (client, location, start, end, worker), built from
  availability, leave periods and skills (only qualified, available staff are
  offered for a shift).
- Approved **swaps and shift changes update the roster directly** (today they
  are recorded in `shift_changes`, ready for this).
- **Open shifts** that staff can put their hand up for; clashes and overtime
  warnings.
- This is the biggest module (two or three milestones); integrating with an
  existing rostering system (ShiftCare, Deputy) is the alternative.

### 3. Leave calendar and balances
- A **team leave calendar** from `leave_periods`.
- **Entitlements and balances** per leave type (accruals by employment type,
  carried forward), shown on the leave request before it's sent.
- Payroll export of approved leave.

### 4. HR calendar
- One calendar of leave, training dates, qualification expiries, probation
  ends, anniversaries and review dates, filtered by team.

### 5. Onboarding and offboarding checklists
- Onboarding already exists. Add **offboarding**: return keys and cars,
  remove access (one-click deactivate with a checklist), exit interview, final
  pay request to payroll, and archiving their records.
- A switch under the HR Pack, like the other parts.

### 6. HR documents
- Contracts, position descriptions, policies and letters per person, with
  version history and staff **acknowledgements** (reuses "Read and confirm").
- Document expiry where relevant (visas).

### 7. Performance and development
- One-on-ones, annual reviews, goals and training plans, with reminders and a
  private record visible to the person, their team leader and managers.

### 8. Workforce analytics
- Availability against demand, leave trends, training compliance by team,
  turnover, and workload, as dashboard pieces for managers.

## Principles for all of them

- Each module is **a part of the HR Pack with its own switch**, on by default.
- **Permissions in the database** (row rules and functions), not just hidden
  buttons; private details stay with the person and people who manage staff.
- **Live updates with undo files**, a checkpoint branch before each, and tests
  for permissions and the main workflow.
- Reuse the existing notifications, approvals and dashboard pieces rather than
  building new ones.
