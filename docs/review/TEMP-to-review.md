# TEMPORARY: everything to review or run (cmeprojects, 15 Nov 2026)

One place for what's waiting on the owner. Delete this file once it's all
done. The client step 1 to 5 packs stay as permanent records:
`2026-11-15-clients-step1.md`, `2026-11-15-clients-step1-fix.md`,
`2026-11-15-clients-steps2-5.md`.

## 1. SQL to run on Dev: done (87 to 90 run 15 Nov 2026)

| Update | What | Undo |
|---|---|---|
| 87 | Client service locations | undo-87.sql |
| 88 | Client details, date of birth, identifiers, emergency contacts and representatives | undo-88.sql |
| 89 | Client safety alerts and risk notes | undo-89.sql |
| 90 | Client service arrangements and the readiness check | undo-90.sql |

Links: `https://github.com/cmeprojects/portal/blob/dev/supabase/live-updates/update-NN.sql`
(undo: `undo-NN.sql`). All safe to run twice. Undo in reverse order.

## 2. Approvals needed (SECURITY DEFINER trigger functions)

Both exist only so changes can be written to the change log; they're
triggers (can't be called directly, nobody can execute them).
- `guard_client_location()` (update 87): approval of locations (who and when
  can't be faked), re-approval after an address change.
- `log_client_change()` (update 88): one change-log writer for client
  details, people, alerts, risk notes and services (records which item
  changed, never the values).

Approved by running 87 and 88 (15 Nov 2026).

## 3. Quick checks on Dev (owner)

- **Update 81 (onboarding):** My onboarding shows three parts; clearance is
  refused without a checked right to work; anyone already cleared stays
  cleared.
- **Update 84 (team leaders):** as a test team leader → Directory → a team
  member: availability shows; no address or employee ID; "Only the person and
  people managers see private details". As a manager: the address shows.
- **Update 83 (General tasks):** as a manager, open an escalated General task
  → Escalation dealt with → it goes to In progress.
- **Update 86 (clients):** nothing to see on screen (staff never had a client
  screen); covered by tests.
- **After 87 to 90:** Clients → open a client → Open full profile → add a
  location (tick Approved), an emergency contact, "Record: no known safety
  alerts", set status Active, add a service → it shows "Ready for services".
  Try an NDIS service without date of birth: it's refused with the reason.

## 4. Optional on Dev: the reminder tests (timer is running)

Guide: `docs/setup/dev-hourly-timer.md` → "How to verify both".
- Expiry: a test document expiring in 5 days → run check 2 → check 5.
- 7-day onboarding: check 6 on a test cleared person → run check 2 → check 5.

## 5. What's been done since the HR plan (short)

| Item | State |
|---|---|
| Updates 81, 82, 83, 84, 85, 86 | Run on Dev |
| Hourly timer | Running on Dev (status 200) |
| Team leaders see availability only; emergency contact behind a switch | Done (84) |
| Managers act on General tasks escalations | Done (83) |
| Pack switches: parts off while the pack is off; premium Compliance stays off; notes clear | Done |
| Clients step 1: CL- references, status, preferred name, programs, screens | Done (85, 86) |
| Clients steps 2 to 5: database, tests and profile screens | Done (87 to 90 run on Dev) |

## 6. Next, each for approval

1. Clients: the six optional sections (assessments and care plans, service
   agreements, funding and budgets, reviews, client documents, communication
   preferences) with their switches; a staff view of their clients
   (approved locations and current alerts); per-person access ticks for the
   sensitive client parts.
2. HR: termination record (B4), then bank and super change history (B5).
3. Later: rostering, using the readiness check.
