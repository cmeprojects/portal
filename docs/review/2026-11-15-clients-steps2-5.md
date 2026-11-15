# Clients & Care steps 2 to 5 (cmeprojects)

Dev only. Written, tested locally and pushed; **the owner runs the SQL later,
in order**. Screens are already on Dev: each section shows "appears after
database update NN" until its update is run.

| Step | Update | Undo | What |
|---|---|---|---|
| 2 | update-87.sql | undo-87.sql | Service locations |
| 3 | update-88.sql | undo-88.sql | Contact details, date of birth, identifiers; emergency contacts and representatives |
| 4 | update-89.sql | undo-89.sql | Safety alerts, worker instructions, detailed risk notes |
| 5 | update-90.sql | undo-90.sql | Service arrangements and the readiness check |

Run 87, 88, 89, 90 in that order. Undo in reverse (90 first).

## Tables (all hang off the one client record, `car_clients`)

- `client_locations` (many per client): name, address, suburb, state,
  postcode, access instructions, from and until dates, approved (who and
  when kept). Never deleted: end them with a date.
- `client_details` (one per client): date of birth, phone, email, home
  address, best way to contact, communication needs, NDIS number (nine
  numbers), My Aged Care ID.
- `client_people` (many): emergency contact, next of kin, nominee, guardian,
  authorised representative; relationship, phone or email (one needed),
  authority or consent, main contact, current. Never deleted.
- `client_alerts` (many): type, severity, alert, what workers must do, who to
  call, review date, current. "No known safety alerts" is recorded the same way.
- `client_alert_notes` (one per alert): detailed risk notes.
- `client_services` (many): service, program (from the programs list),
  location (one of the client's), start and end, status (planned, active, on
  hold, ended), scheduling restrictions, consent needed and given on.

## Access

| Who | Locations | Details, people | Alerts | Risk notes | Services |
|---|---|---|---|---|---|
| People managers, system admin | All | All | All | All | All |
| Team leaders, support workers (own teams' clients) | Approved and current only (address, access instructions) | **No** | Current ones (alert, severity, what to do, who to call) | **No** | **No** (programs and funding) |
| Other teams' staff | No | No | No | No | No |

Enforced by RLS. Nothing is deleted through the portal (no delete rules).
Every change goes in the change log, saying which item changed, never the
values (contact details and notes are sensitive).

## Core and conditional rules (enforced by the database)

- A changed address on an approved location needs approving again.
- A location, person, alert or service stays with its client.
- A service uses one of its own client's locations, and a program in use.
- **A service can only be made active when the client is ready:** client
  active; the service location approved and current; a current emergency
  contact; safety answered (an alert or "No known safety alerts"); date of
  birth when the program needs it (NDIS, Support at Home); consent when it's
  needed. The refusal lists what's missing in plain words.
- `client_readiness(client)` and `client_service_gaps(service)` give the same
  answer for screens and future rostering. A profile with no active service
  is never ready.

## Needs your approval

Two SECURITY DEFINER trigger functions (they can't be called directly;
nobody can execute them), both so changes can be written to the change log:
1. `guard_client_location()` (update 87): also handles approval (who and
   when can't be faked) and re-approval after an address change.
2. `log_client_change()` (update 88): one change-log writer for every other
   client table (details, people, alerts, notes, services).

Everything else uses the caller's own access (INVOKER) and RLS.

## Screens

Clients page → open a client → **Open full profile**: status and readiness
at the top ("Ready for services", or "Before services can start" with the
list), then Details, Service locations, Emergency contacts and
representatives, Safety (with "Record: no known safety alerts"), and Service
arrangements (each service shows what to fix). Managers only.

## Tests

- `client_locations.test.sql` 19 checks; `client_care.test.sql` 28 checks
  (sensitive data hidden from staff and team leaders, staff see current
  alerts but not notes, nothing deleted, readiness and each refusal reason,
  consent, inactive programs, own locations only, logs without values).
- Full database suite: 1,132 checks pass, 0 fail.
- Undo round trips for 87, 88, 89 and 90: each matches the original.
- Browser: add a location (approved), an emergency contact, "no known
  safety alerts", activate the client; an NDIS service is refused without
  date of birth (with the reason); after adding it, the client shows "Ready
  for services"; a support worker can't open the profile; the profile and
  client list work before updates 87 to 90 (sections say which update).

## Not in these steps (later, each for approval)

- The six optional sections (assessments and care plans, service
  agreements, funding and budgets, reviews, client documents, communication
  preferences) and their switches.
- Per-person access ticks for sensitive client parts on the Access page
  (today: people managers and the system admin).
- A staff view of their clients (locations and alerts) in the portal.
- Rostering.
