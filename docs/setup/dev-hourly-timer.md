# Hourly timer on Dev: instructions for review (cmeprojects)

Dev only (cme-dev, Sydney; site https://engagedcare-cmeproject.vercel.app).
Not run yet: **for your review and authorisation**. Email and MFA stay out of
scope.

## What the timer is

A schedule inside Supabase (pg_cron) calls the portal's `/cron/due-alerts`
page at **five past every hour**. The call carries a secret; the portal
refuses any call without the matching `CRON_SECRET`. Each run does, in order:

1. Task due-date reminders, overdue alerts, automatic escalation (once per
   missed due date, update 82) and the managers' morning summary.
2. **Document expiry reminders** (onboarding records and visas).
3. Car alerts, built-feature time alerts, request escalation, access-ending
   reminders.
4. **Seven-day onboarding reminders.**
5. Tries to send queued emails (email isn't set up, so these fail quietly and
   are retried; deferred with email, not a defect).

It records each run on **System health → Hourly timer**.

## Set-up steps (you do these)

1. Open `supabase/setup/due-alerts-timer.sql` and change the one address line
   to `https://engagedcare-cmeproject.vercel.app` (no slash at the end).
2. Run it in the Dev SQL Editor. It turns on `pg_cron` and `pg_net`, stores
   the address and a new random secret in the Supabase vault, schedules the job
   and shows the secret **once**.
3. Vercel → the Dev project → Settings → Environment Variables → add
   `CRON_SECRET` with that value, for the environment the Dev site runs
   on (usually Production for that project). **Don't paste it anywhere else, including here.**
4. Redeploy the Dev site (Deployments → latest → Redeploy).
5. Run checks 1 to 4 in `supabase/setup/timer-checks.sql` (run now, then see
   the answer). Expect status 200 and `"ok": true`, and System health showing
   "Ran just now".

Running the set-up again makes a new secret, so Vercel must then be updated
again.

## Expected behaviour on the first run

- Dev has overdue demo tasks. The first run may **escalate several of them**
  and send bell notices to the assignees, team leaders and managers. That's the
  normal rule (each escalates once per missed due date). If you'd rather not,
  turn off **Auto-escalation** (System settings → Tasks) and deploy before step 5.
- Expiry and onboarding reminders go only to people whose records qualify
  (below). Each reminder is sent **once**; running again doesn't repeat it.

## How the reminders are triggered

**Document expiry** (onboarding records with an expiry date, and visas):

| Stage | When | Who gets a bell notice |
|---|---|---|
| 60 days | expires within 60 days | the person |
| 30 days | within 30 days | the person (marked important) |
| 7 days | within 7 days | the person (important) |
| Today | expires today | the person and people admins |
| Expired | after the date | the person and people admins |

People admins get the 60, 30 and 7-day notices too (not marked important).
One notice per record per stage; they're kept in `compliance_alerts` so they
never repeat. The system admin's own records are skipped.

**Seven-day onboarding reminder** (update 81 rule):
- someone cleared to work **7 or more days ago** (and within the last 90
  days) who still hasn't finished bank account, super, the TFN form or a
  checked right to work;
- one bell notice to the person and to whoever cleared them, listing what's
  missing, linked to My onboarding;
- sent once per person; clearance is **never** removed;
- skipped while Compliance is switched off.

## How to verify both (test accounts only)

**Expiry:**
1. As a test staff member, upload an onboarding document with an expiry date
   **5 days from today** (or a staff admin enters it for them).
2. Run check 2 (run now), wait 30 seconds, then check 5.
3. Expect "… expires in 5 days" for that person and the people admins.
4. Run check 2 again: **no second notice** (once per stage).

**Seven-day onboarding:**
1. Choose a test person who is **cleared to work** but missing at least one
   of bank, super, TFN form or checked right to work.
2. Check 6 (test data only) makes their clearance 8 days old.
3. Run check 2, wait, then check 5. Expect one notice for the person and the
   person who cleared them, listing the missing items.
4. Run check 2 again: no repeat. Optionally put the date back (check 7).

**Not affected:** clearance status, roles, permissions and data other than the
reminders and escalations themselves.

## Clean-up and rollback

- Stop the timer: check 8 (`cron.unschedule('due-alerts')`), and optionally
  delete the two vault entries. Then remove `CRON_SECRET` from Vercel and
  redeploy if you want.
- Test data: put any changed clearance date back (check 7); delete or replace
  the test document if wanted.
- Notices already sent stay in the bell (people can mark them read). Escalated
  tasks stay escalated until a manager deals with them.
- No database structure is changed by any of this, so there's no undo SQL
  beyond check 8.

Files: `supabase/setup/due-alerts-timer.sql` (set-up),
`supabase/setup/timer-checks.sql` (checks, run now, test-only steps, rollback).
