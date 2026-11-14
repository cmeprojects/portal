# Audit assessment: revised findings (cmeprojects)

Assessment of the "Engaged Care Portal: All Audit Reports" (15 Nov 2026:
Support worker, Manager, System Administrator and cross-role reports),
checked against the current code and database (version 0.1.1, updates to 79).
Review and planning only: nothing was changed, nothing deployed.
For approval before any work starts.

## Excluded by the owner (not defects, not current priorities)

| Item | Status |
|---|---|
| Email delivery not configured | Not a defect. Not prioritised now. |
| Two-factor (MFA) off | Switched off on purpose for the review. Not a defect. |
| Email queue counts differing (home 5 waiting / 2 failed, Health 7) | Deferred while email is unconfigured. |
| MFA enforcement | Future production-readiness item, not a current task. |

## 1. Confirmed defects (checked in the code and database)

| # | Finding | Checked | Severity | Fix (size) |
|---|---|---|---|---|
| D1 | **My onboarding contradicts itself.** "3 of 7 done, 4 to do" but also "Onboarding complete", "Compliance verified" and "Cleared to work". | Confirmed. The progress count includes the four pay/work-rights steps (bank, super, right to work, TFN form). "Onboarding complete" and clearance only look at the onboarding checklist (`onboarding_missing`, `before_work_missing`), which leaves those four out. | High | Needs your decision (below), then a small database update and a page change. |
| D2 | **Two identical "You're cleared to work" notices.** | Confirmed cause. Clearing someone who's already cleared isn't refused: it sends the notice again and overwrites who cleared them and when. A double-click did this before buttons greyed out (fixed 14 Nov), but the database still allows it. | Medium | Small database update: refuse a second clearance (or do nothing quietly). |
| D3 | **Excel button leads to "exports are switched off".** | Confirmed. Register pages always show the Excel panel; only the download checks the Reports switch. | Medium | Small: hide it when exports are off, or show it greyed with "Exports are switched off". |
| D4 | **Access page says payroll/identity records are "coming in the next phase".** | Confirmed. Those records have been live since update 67; the wording is out of date. | Low | Wording only. |

**Decision needed for D1:**
1. Should "Onboarding complete" include the pay and work-rights steps? (Recommended: yes, so the count and the label agree.)
2. Should **right to work** be needed **before** someone can be cleared to work? (Recommended: yes. Bank, super and TFN can stay "finish within a week".)

## 2. Usability gaps (worth fixing; no fault in the logic)

| # | Finding | Checked | Severity | Recommendation |
|---|---|---|---|---|
| U1 | Asset Register shows no "Add item" for a Manager. | By design: only the system admin, or managers named as managers of that register, add items. This register has none, and the page doesn't say why. | Medium | When the button is hidden, say who can add items and how to be added (Set up → managers). |
| U2 | New request doesn't show who approves it or how long it takes. | Confirmed. The approval routes exist (Portal settings → Request approvals) but aren't shown on the form. | Medium | Show "Goes to: Team leader, then Manager · usually within N days" under the request type. |
| U3 | Clearance isn't explained: minimum met, remaining items, override. | The data is already kept (who cleared, when, note; override reason and end date). It isn't shown together. | Medium | One clear status line on My onboarding, the person's onboarding page and the Compliance report: "Cleared by X on date (minimum met; 3 items to finish)" or "Override until date: reason". Pairs with D1. |
| U4 | Dashboard: "6 overdue" card vs chart "5 overdue + 1 escalated". | Escalated tasks are counted separately in the chart. | Low | Label it: "6 overdue (including 1 escalated)". |
| U5 | Global search for "leave" finds nothing. | Search covers pages, tasks, registers and (for managers) people. "Leave" isn't a page name. | Low | Add search words to pages (for example leave, shift, timesheet find New request). |
| U6 | "My requests and questions" (tasks) vs "My requests" (leave and shifts) can be confused. | Wording. | Low | Rename the task tab "Questions to the office", or similar. |

## 3. Checked: by design or already covered (no change recommended)

| Finding | Why no change |
|---|---|
| Managers can clear to work and give overrides | Confirmed with the owner as intended. Every clearance and override is in the change log with who, when and the note or reason (an override needs a reason). |
| Incident/risk records can be saved with blank key fields | Intentional: incidents can be logged quickly. Fields marked required must be filled before the task can be **completed** (the database refuses otherwise), so closing an incomplete record is already blocked. Stronger rules belong in the planned incident follow-up feature. |
| Clients page is a name list only | Scope decision, not a fault (see section 5). |
| Managers see Onboarding progress but not the Compliance report | Two separate settings on purpose: progress (no files) for managers and team leaders; the report for the roles chosen in settings. |
| Phone app PIN (4 numbers, signed in for 90 days) | After a set number of wrong tries the PIN is forgotten and a full sign-in is needed; the stay-signed-in days are a setting; staff can sign out other devices and the system admin can sign anyone out everywhere. |
| Change log needs reasons | Override reasons and clearance notes are already recorded and shown. |
| Broad access grants / TFN reveal on Dev | Test set-up from the Phase 2 rollout ("Kept from before"). Pass-on for payroll and identity is off unless ticked. Before go-live: review every grant (an operational task, not code). |
| 5-year keeping period | A policy choice for the owner (the setting already exists). |
| Feature-off pages visible to the system admin | Intentional: the system admin sees switched-off features with a notice so they can set them up. (For staff, D3 covers the export button.) |

## 4. Environment and data (not code)

| Finding | Status |
|---|---|
| **Hourly timer "has not run"** (reported as critical) | Set-up step not yet done on the Dev copy (moved to Sydney 11 Nov): run `supabase/setup/due-alerts-timer.sql` and add `CRON_SECRET` in Vercel (docs/SETUP.md). Bell reminders and escalations depend on it; its email part is deferred with email. **Recommend doing it on Dev now** so reminders and escalation can be tested. One existing alert step timed out on the local copy with large test data; to look at in the speed work before go-live. |
| Overdue backlog, 0% on time, one person assigned everything | Demo/test data. |
| Only one team, no job titles | Test set-up. |
| "Mama Care" name in the support worker report | The company name setting at that time (System settings → General → Name and logo). |

## 5. Product gaps (roadmap, as already agreed)

Participant records (profiles, consent, plans, goals, risks), rostering and
shifts, shift and progress notes, incident follow-up with deadlines and
sign-off (built on the Incident register), training records, a policies
library with read-and-acknowledge, and (if wanted) invoicing and plan budgets.
For each: decide whether the portal owns it or connects to an existing care
system, before building.

## Proposed order (for approval)

| Batch | Contents | Database update | Size |
|---|---|---|---|
| A: quick fixes | D2, D3, D4, U1, U4, U5, U6 | One small update (D2) | Small |
| B: onboarding and clearance | D1 and U3, after your two decisions | One update | Small to medium |
| C: request clarity | U2 | None | Small |
| D: environment | Hourly timer on Dev (you run one SQL and add one Vercel setting; I give the steps) | None from code | Small |
| Then | Next feature from section 5 (for example incident follow-up) | | |

Security requirements, development priorities and the credit-conservation
rules stay as they are. Speed stages 2 to 9 stay after the build. MFA and
email stay excluded until you decide otherwise.
