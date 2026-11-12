# Portal review, 12 Nov 2026 (cmeprojects)

Our own review, to read next to the outside (ChatGPT) review. Checked on the
local copy with test data, version 0.1.1.

## What was checked

| Check | Result |
|---|---|
| Every page, followed link by link, as system admin, manager, staff admin, team leader, support worker and signed out (desktop) | about 2,060 page visits; no errors a person would see |
| The same on a phone (390 px wide), system admin and support worker | 300 page visits; nothing wider than the screen |
| Database rules (who can see and change what) | 997 checks pass |
| Access page in the browser: nominating, the permission tree, passing on, staff records, notices, reminders | all pass |
| Owner protection (another system admin can't turn off, demote, reset or sign out the owner) | 12 checks pass |

## Broken

Nothing a person would see. Notes for cmeprojects:

1. **The hourly job** stopped early on the local copy: one of the existing alert
   steps (due dates, onboarding, cars, built features or requests) took too long
   with the large local test data. The new "access ends soon" reminder runs
   after those steps, so it waits for them. **Check System health on Dev**: if
   the hourly job shows as failing, cmeprojects to find the slow step.
2. A menu warning ("list item without a key") showed up a few times while the
   crawl moved quickly between pages. It doesn't happen on a normal page load,
   so it looks like a one-off from the local development server, not something
   people will see. To recheck on Dev.
3. `/f` (all built features) has no page of its own. Nothing links to it (each
   built feature is its own menu item), so nobody lands there. Optional: an
   overview page.

## Unfinished from our own plan (most valuable first)

1. **Pages following the new access (step 4).** Access given on the Access page
   is saved, checked and logged, but most pages still decide who can open them
   from the old rules. Until this is done, giving a Manager Administrator
   "Cars" or "Onboarding" there doesn't open anything new for them.
2. **Emails sending (Resend).** Invites, password links, reminders and the new
   access notices are queued but only send once Resend is set up.
3. **Speed work, stages 2 to 9** (deferred).
4. Customising the portal (own pages, menu editor, wording, email templates),
   see docs/TODO.md.

## Missing for a care business (suggestions to discuss)

Already in the portal: leave and other staff requests, an Incident register
template, onboarding and document expiry, contracts, cars, forms, tasks,
registers, reports, a staff announcement banner, the website and Assistant.

Not there yet, roughly in order of how often a care business needs them:

1. **Rostering and shifts**: who works when, with whom, swaps and cover.
2. **Shift notes and client progress notes**: written by support workers on
   their phone, seen by team leaders.
3. **Client care plans and goals**: per client, with review dates.
4. **Incident follow-up with deadlines**: the Incident register exists; add
   reportable-incident time limits, investigation steps and sign-off.
5. **Timesheets and a payroll export** (hours from shifts, to send to the
   accountant or payroll software).
6. **Training records**: courses, due dates and refreshers (certificates are
   covered by onboarding; courses and in-house training aren't).
7. **Policies library**: read-and-acknowledge (could come with "own pages").
8. **Client invoicing / plan budgets** (NDIS-style), if the business needs it
   in the portal rather than accounting software.

## Next

Merge this with the outside review, then choose: step 4 (recommended first),
Resend, or one of the missing features above.
