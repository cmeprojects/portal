# Staff onboarding, compliance and clearance to work (cmeprojects)

Staff Portal · © cmeproject · 9 November 2026 · Development copy (`dev`)

## Safety

- **Checkpoints:** `restore-before-onboarding`, `restore-before-onboarding-step2`, `restore-before-onboarding-step3`.
- **Database updates:** 58 and 59, each safe to run again, each with an undo file.

| Update | What it adds | Undo |
|---|---|---|
| `clear-onboarding-items.sql` | Development only: removed the old read, training and upload items | None (one-off) |
| 58 | Statuses, clearance, overrides, cleared-only registers and cars, document details, acknowledgements, training completion, signed agreements, defaults | `undo-58.sql` |
| 59 | HR Pack in Delegation (request approvals, who can clear people), shareable with staff admins; cars setting placement | `undo-59.sql` |

## What was reused

- **Invites:** name and email only, already minimal.
- **Items:** read, training, upload and form items, with role and team targeting.
- **Records:** each upload is a new record, which gives the history. They already had the status, reviewer, review date, note and expiry.
- **Policy versions** and the daily expiry reminders.
- **Conditional role:** the existing "Finish onboarding" task.

## What changed

### Account set-up
- **One-time set-up link:** email security scanners can't use it up, because it's only used when the person presses **Set up my account**.
- **Supabase's own invite emails** now work too.
- **After choosing a password:** the person is asked to sign in, then goes to My onboarding.
- **Set-up stages in People → Staff:** Invite sent → Not set up yet → Account set up. Anyone with a role is Active.
- **Resend invite** works until a new starter has set up their account.
- **Delete (never set up):** only for new starters who never set up. Everyone else is deactivated, which keeps their records.

### My onboarding (staff)
- **Sections, in order:**
  1. Personal information
  2. Employment details
  3. Policies and acknowledgements
  4. Training
  5. Documents and qualifications
  6. Employment agreement
  7. Final verification

  Sections with nothing applicable are hidden.
- **Progress** counts only what applies to the person, shown as a ring plus a done count for each section.
- **Three statuses**, kept separate: Onboarding complete, Compliance verified, Cleared to work.
- **"Needed before you can start work"** lists what still blocks them.
- **Policies:** opening one is recorded first, then they acknowledge with a tick and their typed full name. The version and a fingerprint of the exact text are kept.
- **Training:** completion date, provider and certificate. **Mandatory trainings always need a certificate**, which is then checked.
- **Documents:** category, number, issue and expiry dates as set up, plus a full history (sent, checked by, date, notes).
- **Uploading never marks anything as verified.**
- **Employment agreement:** a drawn signature plus typed full name and a tick. It records the signature image, the version fingerprint, the time and the device.

### People → Onboarding (admins)
- **Overview tiles, each a filter:**
  - Onboarding not finished
  - Waiting for checks
  - Expired or expiring
  - Waiting for clearance
  - Working on an override
- **To check:** every file waiting for review, with **Looks good**, **Reject** (reason) and **Ask for a new copy** (reason).
- **Person page:** the three statuses, what's still needed before working, and these controls:
  - **Clear to work:** locked until the needed items are done and checked.
  - **Remove clearance**.
  - **Override:** a reason and an end date up to 30 days.
  - **End override**.
- **Records on the person page:** how each policy was acknowledged, plus **View signature** for agreements.
- **Item settings:** Needed before working, category, issue date and number, the certificate rule, job titles, and agreements.

### Clearance and duty restrictions
- **Who clears people:** managers and the system admin, plus staff admins when "Who can clear people to work" includes them. That setting is part of **HR Pack** in Delegation.
- **The working rule:** everything needed before working must be done and checked. Whatever's left becomes a **Finish onboarding** General task, due within a week. New starters get it when they're given a role.
- **Overrides** let someone work before they're cleared. They need a reason and an end date (up to 30 days), and they're recorded in the change log.
- **Cleared staff only** (a switch on each register): its tasks can't be given to anyone who isn't cleared. **Cars: cleared staff only** does the same for trips. If a needed document expires, the person is blocked again.
- **Existing staff:** staff working before update 58 count as cleared, so nobody was blocked by the update.

### Delegation
- **HR Pack** is a new Delegation area. It covers request approvals and who can clear people to work.
- A delegated manager can share it with a staff admin, like the other areas.

### Also
- **Phone numbers:** a country picker, Australian number checks, and one saved format.
- **Directory:** the card and tasks show beside the list, with editing in a pop-up.
- **My account:** shows only the details you can edit.
- **Faster page changes:** the frame's data now loads at the same time instead of one after another.

## Tests

| Check | Result |
|---|---|
| Database tests (all files) | 784 passed, 0 failed (34 new for this work) |
| Updates 58 and 59 and their undo files | Each ran twice without errors; 58 re-applied cleanly after its undo |
| Employee workflow (browser) | 11 of 11: sections, statuses, policy, training with certificate, document, signature, phone width |
| Admin workflow (browser) | 14 of 14 across two runs: tiles and filters, To check queue, new copy request, override, clearance, item settings, signatures |
| Invite and account set-up (browser) | Scanner-safe link, set password, asked to sign in, one-time use, resend after opening |
| Delegation and settings (browser) | 4 of 4 |
| Re-crawl, every page, every role | 757 page visits across 6 roles (including signed out): no errors, broken pages or sideways scrolling |
| Lint, typecheck, production build | Clean |

## Future items (assessed, not built)

| Item | Assessment |
|---|---|
| Automated reminders to staff | Easy: extend the daily job to remind people with outstanding items |
| Position-specific templates | Mostly covered by job-title targeting; a saved bundle could come later |
| Certified digital signatures | Needs an outside service (cost). The drawn plus typed signature covers most agreements |
| Probation reviews | Medium: a review task from the start date |
| Automatic training assignment | Comes with templates |
| Roster compliance | Waits for rostering. It would use the clearance check |
| Recurring reviews | Easy: "re-confirm every N months" on items |

## Limits

- **Signing staff's files:** only people who manage Compliance (staff admins) can open uploaded files and signatures. Managers clear people, but can't open the files unless they also manage Compliance.
- **Old items:** the old read, training and upload items were removed from Development, so set up your own on People → Onboarding. The sample agreement is switched off until its wording is replaced.
