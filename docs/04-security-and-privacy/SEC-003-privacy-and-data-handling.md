# SEC-003: Privacy and Data Handling (clients, care and rostering)

| Field | Value |
|---|---|
| Document ID | SEC-003 |
| Title | Privacy and Data Handling: clients, care and rostering |
| Category | 04 Security and privacy |
| Version | 0.1 (facts and first review) |
| Status | **Draft**. Facts gathered and gaps fixed by the developer (cmeprojects). Not a privacy approval: needs the owner's sign-off and an independent privacy adviser before real client data goes in. |
| Owner / Reviewer / Approver | Technical Lead (facts) / Privacy adviser (independent) / Product Owner |
| Created | 18 Nov 2026 |
| Related | SEC-002 (RLS register), SEC-004 (retention, to write), ARC-003 (data flows, to write), D-051, D-052, D-053, D-058, D-059 |

## 1. Scope and method

Client records, care information (plans, notes, documents, funding,
reviews, agreements), Allied Health access and rostering (shifts, shift
notes, signatures, events). Checked on a local copy built from
`supabase/migrations` with the test data (update 139 included):

1. **Every table has row level security on.** None without it.
2. **Signed-out visitors** read only public settings (branding, website
   text) and the list of switched-on features: no client or staff data.
3. **File storage:** every bucket is private except `branding` (logos).
   Client documents (`client-docs`) are private and read only with the
   Documents part for that client.
4. **Who sees what:** one person per role signed in (two-factor done) and
   the rows they can read counted, table by table. Re-run any time with
   `supabase/setup/privacy-matrix.sql` (read only; rolls back).
5. **Notices and emails:** what each care and roster alert carries.
6. **AI assistant:** answers from its own documents (`assistant_documents`);
   it doesn't read client, care or roster tables.

## 2. Who sees what (rows readable, local test data, 18 Nov 2026)

Counts are of the test data, so they show **who can read a table at all
and how widely**, not real numbers. 0 means nothing readable.

| table | Manager | Team Leader | Case Manager | Intake Officer | Client Services Coord. | Rostering Officer | Payroll Officer | Staff Administrator | Support Worker | Practitioner (external) |
|---|---|---|---|---|---|---|---|---|---|---|
| `car_clients` | 12 | 5 | 5 | 12 | 12 | 12 | 12 | 0 | 3 | 0 |
| `client_details` | 11 | 0 | 5 | 11 | 11 | 0 | 0 | 0 | 0 | 0 |
| `client_people` | 13 | 0 | 8 | 13 | 13 | 0 | 0 | 0 | 0 | 0 |
| `client_alerts` | 7 | 5 | 5 | 7 | 7 | 7 | 7 | 0 | 5 | 0 |
| `client_services` | 10 | 0 | 5 | 10 | 10 | 10 | 10 | 0 | 1 | 0 |
| `client_locations` | 11 | 5 | 5 | 11 | 11 | 11 | 11 | 0 | 5 | 0 |
| `client_comms` | 10 | 5 | 5 | 10 | 10 | 10 | 10 | 0 | 5 | 0 |
| `client_documents` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| `client_care_plans` | 8 | 0 | 5 | 8 | 0 | 0 | 0 | 0 | 0 | 0 |
| `client_worker_instructions` | 8 | 5 | 5 | 8 | 0 | 0 | 0 | 0 | 5 | 0 |
| `client_funding` | 9 | 0 | 5 | 9 | 9 | 0 | 9 | 0 | 0 | 0 |
| `client_agreements` | 8 | 0 | 5 | 8 | 8 | 0 | 0 | 0 | 0 | 0 |
| `client_reviews` | 9 | 0 | 5 | 9 | 9 | 0 | 0 | 0 | 0 | 0 |
| `client_assignments` | 26 | 12 | 5 | 26 | 26 | 26 | 26 | 0 | 3 | 0 |
| `client_practitioner_notes` | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| `shifts` | 21 | 2 | 2 | 2 | 2 | 21 | 21 | 21 | 5 | 0 |
| `shift_service_records` | 1 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | 1 | 0 |
| `shift_notes` | 1 | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 0 | 0 |
| `shift_events` | 89 | 0 | 0 | 0 | 0 | 89 | 89 | 89 | 20 | 0 |

Reading it:

- **Managers** see every client (today's rule).
- **Case Managers** see only their assigned clients (5), across all parts,
  including shift notes for those clients.
- **Intake & Assessment Officers** see every client; care plans and notes
  view only.
- **Client Services Coordinators** see every client's administrative parts;
  no care plans, notes or documents (update 136).
- **Rostering and Payroll Officers** see the client list, locations,
  services, alerts and (Payroll only) funding, plus the whole roster; never
  details, contacts, care plans or shift notes.
- **Staff Administrators** see no clients (D-052). They see the roster and
  its log, but not shift notes (update 139).
- **Support Workers** see the clients of their own published shifts and
  their team's clients (names, locations, alerts, instructions), and only
  their own shift notes.
- **Practitioners** see nothing until given access to a client (D-058).

## 3. Gaps found and fixed (update 139)

| # | Finding | Fix |
|---|---|---|
| 1 | **Shift notes were readable by anyone who could see the roster**, including Payroll Officers and Staff Administrators: what was done, how the client was and incident details. | Notes keep the client they're about. Read by the worker who wrote them and by people who can see that client's care plans. Notes for a shift with no client stay with people who roster. People who roster still see that notes are in, and any incident flag, in the shift's events. |
| 2 | **A client's case manager couldn't read their client's shift notes** (the rule checked a shift they can't see), although they were alerted. | Same fix: the rule now follows the client. |
| 3 | **Incident alerts put up to 200 characters of the incident into the bell and the email.** Other care reminders deliberately leave details out. | The alert names the worker and the client only, and links to the client's Shifts and notes tab, where it's read in the portal. |

Tests: `supabase/tests/shift_notes_privacy.test.sql`, and
`shift_service_records.test.sql` still passes.

## 4. Points for the owner to decide (not changed)

1. **Communication preferences** (`client_comms`) are readable by Rostering
   and Payroll Officers, Team Leaders and Support Workers (team clients),
   because they follow the client list unless set separately, and the
   "team sees comms" switch is on. Probably wanted for workers; Payroll
   likely doesn't need it.
2. **Who looks after a client** (`client_assignments`) is readable by anyone
   who can see the client list, for the same reason. Low sensitivity
   (staff names), but Payroll doesn't need it.
3. **Opening a client's page isn't logged for staff.** Practitioners' opens
   are logged (`client_external_views`); changes are logged for everyone.
   A view log for staff is recommended before real data.
4. **Client names appear in notices and emails** (documents expiring,
   reviews, agreements ending, incidents). No care details are included.
5. **Retention:** a records retention setting exists (`records.retention_years`);
   how client and care records are removed when it's reached is SEC-004 (to write).
6. **Payroll Officer and staff bank, super and TFN details**: still on the
   old rule; owner to decide (from Stage 5).

## 5. Where the data is

- Database and files: Supabase, Sydney region (Dev). Pages run on Vercel,
  Sydney (`syd1`).
- Emails: notices go by email when marked to; they carry names, never care
  details (after update 139).
- Real client data: **not yet**. Test data only until this document is
  approved (D-051).

## 6. Before real client data

1. Owner decides the points in §4.
2. Independent privacy adviser reviews this document and SEC-002.
3. SEC-004 (retention and removal) written and approved.
4. Re-run `supabase/setup/privacy-matrix.sql` on the copy that will hold
   real data and keep the result as evidence.
