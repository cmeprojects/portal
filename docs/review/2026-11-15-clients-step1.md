# Clients & Care step 1: client record, reference, programs (cmeprojects)

For approval. Dev only. Written and tested locally; **not run on Dev**.
No screens yet: the pages come after approval (they'll show the reference,
status, preferred name and the programs list).

- Update: `supabase/live-updates/update-85.sql` (safe to run again)
- Undo: `supabase/live-updates/undo-85.sql`
- Migration: `supabase/migrations/20270129000001_client_record.sql`
- Tests: `supabase/tests/client_record.test.sql`
- Plan and decisions: `docs/roadmap/client-foundation-plan.md`

## Tables and relationships

One client record, reused: `car_clients` (already used by Cars trips, built
features, tasks and client teams). **No second client table.**

| Change | What |
|---|---|
| `car_clients.client_ref` | `CL-00001` style. Made by the database from a sequence on every new client; a value sent in is ignored; it can never be edited; numbers are never reused (a failed save still uses its number). Unique. |
| `car_clients.status` | pending, active, suspended or discharged. New and existing clients start **pending**. |
| `car_clients.preferred_name` | Optional, up to 80 characters. |
| `status_changed_at`, `status_changed_by` | Who changed the status last, and when. |
| New `client_programs` | Name (unique), needs date of birth, active, order. Starts with NDIS and Support at Home (both need date of birth), Private, Other. |

Kept as is: `name`, the existing free-text `reference` (becomes "your own
reference", for external numbers), and `active` (shown or hidden in lists).
Service arrangements (step 5) will link a client to a program, which is what
makes date of birth required for NDIS and Support at Home.

**Existing Dev clients:** references in alphabetical order of name (tested:
"ava Clark" CL-00001, "Ben Ng" CL-00002, "Mia Brown" CL-00003, "Zed Adams"
CL-00004; case doesn't matter). All start pending, to be checked before
activation; "hidden" ones stay hidden.

## Access rules

| Who | Client record | Status | Programs |
|---|---|---|---|
| System admin | All (as now) | Change | Read, add, rename, deactivate |
| People managers (managers, staff admins) | All (as now) | Change | Read |
| Car managers | As now | **Can't** change | Read |
| Team leaders | **New:** their teams' clients (via client teams) | No | Read |
| Support workers | **New:** their teams' clients (via client teams) | No | Read |
| Nobody | — | — | **Delete** a program (deactivate instead) |

- Staff see only the basic record: name, preferred name, reference, status.
  Date of birth, contacts and other sensitive details go in separate tables
  with their own permissions (steps 3 and 4), so they're never in this row.
- Status changes are in the change log (from, to, who, client reference).
- Clients can't be deleted (as now: no delete rule).
- Enforced in the database (RLS and a guard trigger), not only on screen.
- Module configuration, client data access and delegation stay separate:
  nothing here is turned on by a switch.

## Needs your approval

1. **This update (85).**
2. **One SECURITY DEFINER function: `guard_client_record()`.** It's a trigger
   (it can't be called directly; nobody can execute it). It makes the
   reference, blocks reference edits, checks who changes status, and writes
   the change to the change log, which only system functions can write.

## Effect on what exists

- Cars, built features, tasks and the client picker keep working (they use
  their own functions or the columns they already had). Checked in the
  browser: adding a client on the Clients page gets a reference; the Clients,
  Cars and New task pages load for the system admin, a manager and a support
  worker.
- The new staff read rule: support workers' existing screens don't list
  clients directly, so nothing new appears yet. It's the base for steps 2 to 4.
- Stage 1: no existing policy is changed. The one new policy follows the
  Stage 1 form (calls wrapped to run once per statement).

## Tests (local)

- `client_record.test.sql`, 21 checks: reference format, can't be chosen,
  unique, never edited (even by the system admin), never reused; pending by
  default; a manager activates (who, when and the change log); only the four
  statuses; support workers and team leaders see their own teams' clients
  only and can't change them; people managers unchanged; programs start as
  agreed, members read them, a manager can't add, the system admin adds and
  deactivates, nobody deletes, names unique.
- Full database suite: 1,084 checks pass, 0 fail.
- Undo round trip: undo matches the original; re-apply matches.
- Alphabetical references for existing clients: checked as above.

## Rollback

`undo-85.sql` removes the new columns, programs, the reference sequence and
the staff read rule. Clients, teams, trips and tasks are untouched. The
references given out would be lost, and running 85 again starts again from
CL-00001, so roll back only before the references are in use.

## Next step (after approval)

Screens for step 1 (reference, status with a confirm, preferred name, the
"to check" list of pending clients, programs for the system admin), then
**step 2: service locations** for approval.

## After running (15 Nov 2026)

- Update 85 run on Dev by the owner.
- **Gap found while building the screens:** the staff read rule exposed the
  free-text reference to team staff through the database (no screen showed
  it). Fixed by update 86 (for approval): docs/review/2026-11-15-clients-step1-fix.md
- **Screens built** (Clients page, people managers): CL- reference on each
  client; status chip; preferred name and status in each client's panel
  (status change asks first and is logged); a "to check" notice listing
  pending clients; Programs list (system admin adds, renames, marks "needs
  date of birth", untick In use; others read only). The free-text field is
  now labelled "Your own reference". Browser-tested: 8 of 8.
