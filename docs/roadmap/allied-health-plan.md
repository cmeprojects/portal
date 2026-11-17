# Stage 6: Allied Health external access (plan for approval)

cmeprojects · 17 Nov 2026 · Status: **for the owner's approval; nothing built yet**

## The problem

Allied Health practitioners (psychologists, OTs, physios, speech pathologists,
behaviour support practitioners, dietitians) work with some clients but are not
staff. Today an `external` account can sign in and see only Home and My account
(`is_member()` is false; they inherit nothing). They need to see and add to the
records of **their own clients only**, for a set time, with the client's consent.

## Proposal

### 1. Access is given per client, never by role

- New table `client_external_access`: client, practitioner (an `external`
  account), sections given, start date, end date (required; default 6 months,
  at most 12), consent recorded (date, who recorded it, optional consent
  document), reason, given by, ended by/at.
- No end date, no consent, no access. On the end date access stops by itself
  (the rule checks the date; nothing has to run).
- One check, `external_sees(client, section)`, an ordinary (INVOKER) function
  reading the practitioner's own rows. **No new SECURITY DEFINER function.**
- Every client table policy gets one extra line: staff rules as now, **or**
  `external_sees(client_id, '<section>')`. Staff access does not change.

### 2. What a practitioner can see and do

| Section | See | Add or change |
|---|---|---|
| Client basics (name, preferred name, DOB, key needs, alerts) | yes, always with any access | no |
| Care plan (worker instructions, goals) | if given | no |
| Documents | only ones marked "Share with practitioners", plus their own | upload their own reports |
| Practitioner notes (new) | their own, and other practitioners' for that client if given | write their own; change within 24 hours |
| Funding, agreements, reviews, staff, roster, other clients, directory, tasks | **never** | never |

### 3. Screens

- **Practitioners (inside the client page):** case managers and managers see
  who has access, add a practitioner (pick the account, sections, dates,
  consent), extend or end access. A chip shows "Ends in 14 days".
- **Invite a practitioner:** the existing invite pop-up with access level
  External and an Allied Health title.
- **Practitioner home:** "My clients" list (only current access), each opens a
  cut-down client page with the sections given, Upload report and Add note.
  No menu items for anything else.

### 4. Safety

- Two-factor sign-in **required** for external accounts.
- A plain-English access log on the client: who gave access, when it ended,
  what the practitioner uploaded or wrote. Opening a client page is logged too.
- Notices: the case manager is told when a practitioner uploads or writes a
  note; the practitioner is told when access is given and 14 days before it
  ends; managers get a weekly list of access ending.
- Archiving a client, or deactivating the practitioner, ends all access.

### 5. Who can give access (default; changed on the Access page)

New part `clients.external` (one part of Clients): managers for all clients;
Case Managers for their assigned clients. Nobody else by default.

## Build order (each a live update with undo and round-trip test)

1. Update 124: table, `external_sees()`, policies, practitioner notes, shared
   documents flag, two-factor rule, tests.
2. App: Practitioners tab, invite, practitioner home and client page, log,
   notices; browser test as manager, case manager and a practitioner.

## Owner decisions needed

1. Premium package or included in every plan?
2. Can practitioners upload reports and write notes, or view only?
3. Default length of access (6 months suggested, 12 at most).
4. Two-factor required for practitioners (recommended: yes).
