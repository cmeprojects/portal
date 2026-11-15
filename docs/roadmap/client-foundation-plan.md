# Client Management foundation: plan for approval (cmeprojects)

Planning only (15 Nov 2026). Nothing built. Decisions recorded below. Based on the owner's brief
"Mandatory client foundation for future rostering" and on what exists today.

## What exists today

- **One client list:** `car_clients` (id, name, optional reference, active),
  shown as **Clients** (People managers). It's already used by Cars trips,
  built features (`custom_client_targets`) and team links (`client_teams`).
  So it **is** the client record today, and it stays the one record: extended,
  never copied. (A plain `clients` view name can be added for readability.)
- **Permission framework:** the module catalogue, the Access page (ticks per
  action, sensitive parts never inherited, scope by team or person), feature
  switches (module configuration) and RLS. These are reused, not rebuilt.

## Data design (all hang off the one client ID)

| Data | Where | Required |
|---|---|---|
| Identity: full name, preferred name, **client reference** (unique, automatic, for example CL-00001), status (pending, active, suspended, discharged), date of birth | Columns on the client record (DOB in the sensitive part) | Name, reference and status always. DOB conditional (see question 2). |
| Contact: phone, email, residential address, preferred communication, accessibility or communication needs | `client_details` (one row per client) | Optional. Address required before a service is active. |
| **Service locations** (many): label, address, access notes, approved, from and to dates | `client_locations` | At least one approved location before a service is active. |
| **People:** emergency contacts, next of kin, nominee, guardian, authorised representative; relationship, contacts, authority or consent | `client_people` | At least one emergency contact before a service is active. **Sensitive.** |
| **Service arrangements** (many): program (NDIS, Support at Home, private, other), category or type, start and end, status, location, scheduling restrictions, consent needed or given | `client_services` | Program, type, start and location required for each arrangement. |
| **Safety:** alerts, risks and precautions, worker instructions, escalation information; severity, active, review date | `client_alerts` | Optional, but an active service can't start without the safety step answered (an alert, or "no known alerts", recorded). Detailed risk notes **sensitive**. |

**Readiness check (for future rostering):** a read-only function
`client_ready(client, service)` returns what's missing: active status, an
approved location, an active arrangement within its dates, safety answered,
consent where needed. **A profile alone is never "ready".** Rostering
(later) calls this function and builds no second copy.

## Required, conditional, optional, sensitive

- **Always required (enforced by the database, can't be switched off):**
  name, reference, status, the locations structure, emergency and safety,
  and service arrangement essentials.
- **Conditional:** enforced by the readiness check and the save rules, only
  when a service is active (or a program needs it).
- **Optional sections (switchable, data kept):** assessments and care plans,
  service agreements, funding and budgets, reviews, extra documents (later
  phases), and communication preferences.
- **Sensitive (own permission ticks, whatever the switch):** DOB and
  identifiers, representatives and emergency contacts, detailed risk notes,
  documents.

The configuration screen labels each section **Core**, **Conditional**,
**Optional** or **Sensitive**. Core sections have no Off switch. Switching
a section off hides it only; it never deletes data or affects permissions,
and other modules keep working.

## Permissions (three separate authorities, as now)

1. **Module configuration:** feature switches (System settings, system admin
   only). Turning on a client section gives **nobody** access to client data.
2. **Client data access:** catalogue modules under Clients & care, given on
   the Access page with actions (view, create, edit, approve, export) and
   scope (all, teams via `client_teams`, or people):
   - `clients.list` (profile and locations)
   - `clients.services`
   - `clients.safety`
   - `clients.people` (sensitive)
   - `clients.details` (sensitive: DOB, identifiers, address)
   RLS checks these through one helper (the same pattern as Contracts).
3. **Delegation:** Manager Administrators pass on only what they hold, as
   today.

Default visibility (to confirm, question 4): managers and staff admins as
today. Support workers and team leaders see **clients of their teams**:
name, preferred name, locations, active safety alerts and worker
instructions. They don't see contacts, representatives or sensitive details.

## Phases

1. **Foundation (this plan):**
   - the client record extended, with an automatic reference and statuses
   - locations, people, service arrangements and safety
   - the readiness check, permissions and RLS
   - pages: Clients list with search and status, a client profile with
     sections, and a short "new client" form
   - the change log for every change, and tests
2. **Optional sections:** documents, service agreements, care plans and
   reviews, funding.
3. **Rostering (separately approved):** service requirements and shifts,
   using the readiness check.

## Owner decisions (15 Nov 2026)

1. **References:** `CL-00001`, sequential, made by the database (a sequence),
   unique, permanent and never reused (also not after a client is
   discharged or a row removed).
2. **Date of birth:** required for NDIS and Support at Home arrangements; for
   other programs only where eligibility, legislation or the service needs it
   (a "needs date of birth" flag on each program). Kept in the sensitive part.
3. **Programs:** a table the system admin edits. It starts with NDIS, Support
   at Home, Private and Other. Programs can be added or deactivated, never
   deleted once used by any record.
4. **Support workers:** for clients of their own teams only: basic details,
   approved service locations and essential safety alerts and worker
   instructions. No funding, financial details, sensitive documents,
   assessments or unrestricted care records. Enforced by RLS and server
   checks, not only the screens.
5. **Existing Dev clients:** references given in alphabetical order of name.
   Statuses aren't all set to active. Today's list only has shown or
   hidden (`active`), which isn't a care status, so every existing client
   starts as **pending** with a "to check" list; the owner (or a manager)
   confirms each one before it becomes active. Hidden clients stay hidden.

**Scope:** all six optional sections stay in development scope (assessments
and care plans, service agreements, funding and budgets, reviews, client
documents, communication preferences). "Optional" means each organisation
chooses whether to switch it on. Identity, service locations, emergency
contacts, safety and rostering-dependent information are core and can't be
switched off. The wider Clients & Care list (support delivery, progress
notes, allied health, behaviour support) builds on the same client record
later.

**Build in small steps, each approved first:** (1) client record, reference
and programs; (2) locations; (3) people and emergency contacts; (4) safety;
(5) service arrangements and the readiness check; (6) the optional sections.

## Before starting

HR Pack critical items (from the HR review): run update 81 on Dev and fix
team leader private-details access. Client work can run alongside.
