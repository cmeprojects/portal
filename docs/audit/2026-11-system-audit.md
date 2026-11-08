# Full system audit: Development copy (cmeprojects)

Staff Portal · © cmeproject

- **Date:** 8 November 2026
- **Copy:** Development (`dev` branch), tested on a local copy with test data only
- **Restore point:** branch `restore-before-audit` (see `docs/RESTORE.md`)
- **Database changes:** none. Every fix is in the app code, so there's no live update to run.

## How it was tested

- **Every page as every role.** An automated browser visited every page as the system admin, a manager, a staff admin, a team leader, a support worker and a signed-out visitor. It followed every link it found and recorded server errors, page errors, broken links, leftover placeholder words ("undefined", "NaN", "coming soon" and so on) and pages wider than a phone screen (390 px).
- **Real workflows, end to end.** Scripts pressed the actual buttons and then checked the database, so a change only counted when it was saved. The workflows were:
  - Tasks: create, start, comment, edit details, send for approval, approve.
  - Registers: add from a template, delete an unused one.
  - People: invite someone, and invite the same email twice.
  - My account: change name, refuse a wrong current password.
  - Settings: save a draft, then Deploy.
  - Forms: build, publish, send, fill in, see replies.
  - Downloads: every Excel export each role is shown.
  - Confirmation boxes: Cancel changes nothing; confirming carries out the action.
- **Permissions.** Pages and downloads were tried as people who shouldn't have them. All 26 server-action files were checked for a role check, and the 39 database permission (RLS) test files were run.
- **Look and feel.** Desktop and phone screenshots of the main screens were reviewed for layout, wording and consistency.

## Summary

See [Results](#results) at the end of this file for the final numbers.

| | |
|---|---|
| Pages inspected | 189 different pages; 636 page visits across 6 roles (final re-crawl) |
| Issues found | 21 |
| Fixed and tested | 17 |
| Not changed: needs your decision, or test data only | 4 (all Low) |
| Critical issues | None found |
| High issues | 1 found, fixed and tested |

## Issue register

Severity: **Critical** = broken security, lost data or the system stops. **High** = an important workflow can't be completed. **Medium** = noticeable, but work can still be done. **Low** = wording, polish, minor.

| # | Area | Issue (expected vs what happened) | Severity | What was done | Status |
|---|---|---|---|---|---|
| 1 | Forms | **Expected:** staff can open a form they're sent. **Actual:** while Forms was switched off, the system admin (never locked out) could still publish and send a form. Staff got the bell and email, then "We can't find that page". | High | The system admin now sees "Forms is switched off for everyone else" with a link to turn it on. Send, Remind and Add to Compliance are refused with a clear reason until Forms is on. The same notice shows on the Assistant and Staff app pages when those are off. | Fixed and tested |
| 2 | Tasks | **Expected:** a message after Start, Send for approval, Approve and similar actions. **Actual:** the button disappears once the task moves on, so its message never showed. | Medium | The success is now reported from the action itself. Retested: "Marked as in progress.", "Sent to a manager for approval.", "Marked as completed." | Fixed and tested |
| 3 | Tasks | **Expected:** confirmation after saving Edit details or a follow-up action. **Actual:** the section closed on save, hiding its "Saved" message. | Medium | Added a short message at the bottom of the screen ("Saved."), used whenever a section closes after saving. | Fixed and tested |
| 4 | Forms editor | **Expected:** after Publish, everything is saved. **Actual:** "Unsaved changes" stayed on, and the next-step link (send it, Compliance, QR code) was hidden. | Medium | Publishing now counts as saved. | Fixed and tested |
| 5 | Compliance | **Expected:** progress shows what's left to do. **Actual:** with nothing set up, everyone showed a full bar, which looked finished. | Medium | Shows "Nothing set yet" instead of a bar, plus a hint to add documents, trainings or uploads. Finished people show a green bar. | Fixed; checked by screenshot |
| 6 | Dashboard | **Expected:** the whole tasks table fits on a laptop. **Actual:** long register names pushed the Due column off screen. | Medium | Register names now wrap, so Due stays visible. | Fixed; checked by screenshot |
| 7 | Whole portal | **Expected:** a consistent, branded look. **Actual:** "Are you sure?" questions used the browser's plain grey pop-up in 15 places. | Medium | Replaced with one branded confirmation box, with Cancel and a clear action button ("Deactivate", "Delete", "Throw away"). | Fixed. Tested on Deactivate; the other 14 use the same code. |
| 8 | Sign-in | **Expected:** only turned-off accounts see "Your account is turned off". **Actual:** an active person opening that page was signed out, told their account was off, and got a page error. | Low | Active people are sent back to the portal. | Fixed and tested by the re-crawl |
| 9 | People | **Expected:** inviting someone already invited explains what to do. **Actual:** it said "already has an account". | Low | Now says they've already been invited and to use Resend invite (or turn a deactivated account back on). | Fixed and tested |
| 10 | Tasks | **Expected:** "Fill these in first: …" says where to fill them. **Actual:** it only listed the fields. | Low | It now adds "Open Edit details on this task to add them." | Fixed and tested |
| 11 | Website | **Expected:** no placeholder text. **Actual:** an empty About page said "More about us is coming soon." | Low | Replaced with a short, useful line that points to Ask a question or Get started. | Fixed and tested by the re-crawl |
| 12 | Settings | **Expected:** confirm before deleting or clearing. **Actual:** Delete this draft (Feature builder), Delete sample records and Clear Cars app PIN acted straight away. | Low | Each now asks first. | Fixed |
| 13 | Buttons | **Expected:** busy buttons say so. **Actual:** Save name, Save password, Resend invite, Reset two-factor login and Clear Cars app PIN didn't change while working. | Low | They now show "Saving…", "Sending…" and so on. | Fixed |
| 14 | Registers | **Expected:** clear wording. **Actual:** "It has 3 tasks or items". | Low | Now "It has 3 tasks" or "It has 3 items". | Fixed |
| 15 | People | **Expected:** current wording. **Actual:** "(no Microsoft account needed)" was left over from an early version. | Low | Removed. | Fixed |
| 16 | My account | **Expected:** a signed-out save is refused. **Actual:** it could say "Name saved." without saving. | Low | Signed-out people are sent to sign in. | Fixed |
| 17 | Forms | **Expected:** screen readers announce "Sent. Thank you." **Actual:** the message wasn't announced. | Low | Marked as a status message. | Fixed |
| 18 | Demo data | Sample tasks' activity says "asked System to look after it". | Low | Test data only (the sample loader). Real tasks show the right names. | Not changed |
| 19 | Settings → Features | The "Sign-in" row shows **Off** when only two-factor login is off, even though other sign-in methods are on. | Low | It needs a wording choice: show "Two-factor off", or show the row as On. | Requires decision |
| 20 | Whole portal | Some forms show their message above the fields, others below. | Low | Cosmetic; changing every form adds risk for little gain. Suggested for a later polish pass. | Not changed |
| 21 | Not testable here | Emails, Google sign-in, AI Assistant answers, file uploads to storage, the Cars app on a real phone (PIN, install) and the scheduled due-date alerts. | — | They need the live services or a phone. Please spot-check them on the Development copy after deploying. | Not tested here |

## Permissions and security (unchanged, checked)

- All 26 server-action files check who is signed in. They use the role helpers or a permission check, or they rely on database rules (RLS) that limit people to their own rows (their own chats, their own name).
- A support worker opening System settings or Staff settings is sent back to their dashboard. Report downloads return 403 (not allowed) for roles that aren't shown them.
- People are only shown the downloads they're allowed to open, and each of those works: 15 checked.
- No security control was loosened. The Forms fix (#1) adds a server-side check rather than only hiding a button.

## Readiness

The Development copy is in good shape for showing clients. No critical issues were found. The one high issue is fixed and tested. Every page loads for every role without errors, and the core workflows complete and save correctly.

Before real staff use it, check the services in #21 on the live Development copy, decide #19, and turn two-factor login back on (it's off on the test copy).

## Results

| Check | Result |
|---|---|
| Lint and type check | Clean |
| Production build | Builds cleanly, including without database settings (as on Vercel) |
| Database tests | 668 passed, 0 failed (40 groups, including the fresh install) |
| Re-crawl after fixes | 189 pages, 636 visits across 6 roles: 0 server errors, 0 page errors, 0 broken links, 0 placeholder words, 0 pages too wide for a phone |
| Workflow retest | 55 of 56 passed. The 1 failure was the test reading the address before the redirect finished; the same check passed in a real browser (10 of 10 admin pages blocked for a support worker). |
| Downloads | 13 of 13 shown downloads open, for every role |
| Confirmation box | Cancel changes nothing; confirming carries out the action; no plain browser pop-ups |

## Round 2: design refresh (8 November 2026)

- **Checkpoint:** branch `restore-before-design` (commit `c22be46`). The database was not changed.
- **Method:** made in the shared design kit, so every page changed together and no page was styled on its own.

| Module | Change | Tested |
|---|---|---|
| Design kit | Sentence-case page and section headings instead of spaced capitals. A calmer page colour and lines. One soft card shadow everywhere, including 39 hand-built boxes. Buttons with clear hover, pressed, focus and disabled states. Inputs with a focus ring. Bordered notices. | Screenshots on desktop and phone; lint, typecheck, build |
| Sidebar | The crowded footer (name, sign-out link, colour switcher, credits) became one account block (initials, name, role) that opens to Colours, Sign out and About. Clearer active menu item. | Colour choice and Sign out tested on desktop and phone |
| Regression | The task workflow end to end, plus a re-crawl as system admin, support worker and visitor. | See results below |

Found in round 2 and fixed:

- **System admin dashboard on a phone (Medium):** invisible hover tooltips stuck out past the screen edge, so the page scrolled sideways. The first crawls never reached this page because the setup wizard showed instead. Tooltips are now hidden on small screens, where there's no hover. Retested: the page is exactly phone width.
- **Closed website heading (Low):** the default said "Our website is coming soon". It now says "Thanks for stopping by" (the system admin can still change it in Website settings).

Left for a later pass (lower value, or more risk than they're worth now): card layouts for wide tables on phones (they scroll sideways today), icons on dashboard number tiles, and putting form messages in the same place everywhere.
