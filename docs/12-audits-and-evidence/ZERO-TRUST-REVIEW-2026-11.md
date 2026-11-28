# Zero Trust security review before updates 167-170 (cmeprojects, 28 Nov 2026)

Prepared by the coding agent for the owner. Local and test databases only; nothing was run on Dev,
and no real data was touched. Every scenario below was run against controlled test data.

## Scope and method

The review checked the 12 areas in the brief. For each one it asked whether the portal trusts
something it shouldn't: the screen, values typed in the browser, record IDs, role names, earlier
grants, or the fact that a request comes from a signed-in session.

How it was checked:
- **Database (where the rules really live):** direct requests made as different people, with
  changed IDs, amounts and statuses.
- **Every full-access (SECURITY DEFINER) function that changes data:** called directly as a
  support worker, aimed at someone else's records, inside a transaction that was rolled back.
- **Every use of the database master key in the app.**
- **The download and export addresses:** called while signed out.
- **Redirects:** tested in a real browser.

## Findings

### Vulnerabilities (confirmed, corrected locally, not on Dev)

**V1. A worker could put their own request into effect without approval.**
- **Affected:** `apply_request` (database), with leave, availability, swaps and shift changes.
- **Attack:** Sam submits a leave request (pending), then calls `apply_request` with its ID
  directly.
- **Impact:** the leave was recorded while the request was still pending. Rostering and leave then
  treat it as approved. This bypasses separation of duties.
- **Evidence:** "leave periods before: 0", then "leave periods after: 1 (request still pending)".
  Run as Sam, in a rolled-back transaction.
- **Cause:** the 2026 update meant this function to be internal (revoked from everyone, granted to
  no one). But Supabase gives every new function to signed-in users by default, so the revoke
  didn't close it.
- **Smallest safe correction:** update 171 removes signed-in users' right to call it. Approving a
  request still puts it into effect, because the approval function runs as the owner.
- **Tests:** `supabase/tests/internal_functions_locked.test.sql` (refused for a worker and for a
  manager; the leave stays pending), and `my_requests.test.sql` (approval still records the leave).

**V2. Anyone signed in could send any notice, with an email, to anyone.** (Update 171 also now
closes three helpers to signed-out visitors; see W4.)
- **Affected:** `notify_many` (database). `resolve_people` and `escalate_requests` had the same
  cause.
- **Attack:** a support worker calls `notify_many` with a manager's ID, a title such as "Approve
  this", any text and any link.
- **Impact:** the notice appears in the manager's bell and an email is queued from the portal.
  Combined with V4, the link could lead to an outside phishing page.
- **Evidence:** "notifications created for boss: 1" (Sam, rolled back).
- **Smallest safe correction:** update 171, as for V1. Notices sent by the database itself, for
  example to approvers, still work.
- **Tests:** as for V1.

**V3. Sign-in could send someone to another website afterwards (open redirect).**
- **Affected:** `src/lib/safe-next.ts` (the `next` page after sign-in).
- **Attack:** a link to `/login?next=/<tab>/evil.example`. Browsers drop the tab, which leaves
  `//evil.example`.
- **Impact:** after genuinely signing in, the person landed on the outside site, where a fake "sign
  in again" page could catch their password.
- **Evidence:** in a real browser, "landed on http://evil.example/".
- **Smallest safe correction:** `safeNext` now refuses control characters, spaces and backslashes,
  then checks by parsing that the result is still a path on this site. That includes after
  tidying: `/.//x` becomes `//x`, and the second check catches it.
- **Tests:** `tests/unit/safe-next.test.mjs` (21 checks). In the browser, all three tricks now land
  on the portal.

**V4. A bell notice could send someone to another website.**
- **Affected:** `src/app/n/[id]/route.ts`.
- **Attack:** a notice whose link starts `/\` (a backslash). It passed the route's own "starts with
  one /" check, and browsers read the backslash as `//`.
- **Impact:** an open redirect from a trusted portal notice. With V2, anyone could plant one.
- **Evidence:** `/\evil.example` resolved to `https://evil.example/`.
- **Smallest safe correction:** the route uses the hardened `safeNext`.
- **Tests:** as for V3.

### Warnings (low impact; proposed, not changed)

- **W1. Resend invite: closed after follow-up (28 Nov 2026); not exploitable, no change needed.**
  The app check (`managesStaffFor` = `can('people.staff', 'edit')`) and the database check that
  runs after the email (`log_admin_action('invite_resent')`, the same `can('people.staff', 'edit')`)
  are the same rule, asked in the same request. So anyone who could pass the first also passes the
  second, and nobody can trigger the email without staff editing rights.
  Tested with:
  - support worker: no;
  - team leader, even when given a team-only staff grant: no, because only managers and staff
    admins can hold it;
  - manager without two-factor in the session: no.
  Only managers and staff admins hold the right by default, for all staff. The email (an invite or
  sign-in link) goes to the person's own inbox and gives the sender no access.
- **W2. `onboarding_missing` shows any colleague's unfinished onboarding items** (titles only, no
  values). Impact: low (privacy). A direct fix would break internal callers that run without a
  signed-in person. Fix: a separate viewer-checked version for the Staff pages.
- **W3. A deactivated support worker could still read their own published shifts** by direct
  database request until their sign-in token expires (at most 60 minutes). The app sends them to
  "deactivated" at once, sign-in is blocked, and managers lose all access straight away. Fix: add
  the "active member" check to the worker's own-shift rule.
- **W4. The 27 helper functions signed-out visitors could call: checked one by one (28 Nov
  2026).**
  - None writes anything or causes any action (each body checked).
  - None reads client, billing, HR or financial tables.
  - Called as a signed-out visitor with real IDs:
    - 18 answer only about the caller, who is nobody, so the answer is false or empty: the "can"
      checks, has_role, is_staff_admin, is_system_admin, manages_registry, my_name,
      my_role, sees_register_overview, task_folder_ok, leads_user, and mfa_ok. mfa_ok says "true",
      but every rule that uses it also needs a role, so it grants nothing.
    - 6 give harmless or public facts: default_org_id (an ID with no use without access),
      local_today, next_business_day, website_front_page, feature_enabled (on or off switches),
      and is_member (also needed by the public settings rule).
  - Three leaked something and were **corrected in update 171** (signed-in access kept):
    - **rule_on (low-severity vulnerability).** It's meant to say yes or no, but for a setting that
      isn't yes/no its error message printed the value. With only the public key, the live API
      returned the portal name and the list of roles that need two-factor. Members-only settings
      (for example, weekly report recipients, the staff phone line, the invite message) were
      readable the same way. No passwords or keys are kept in settings.
    - **setting_roles.** Which roles a setting lists (for example, who needs two-factor).
    - **can_take_tasks.** Whether a given person ID belongs to active staff.
  - After the fix the API answers "permission denied"; the sign-in page and public site are
    unaffected.
- **W5. Money approvals don't ask the person to sign in again.** Two-factor is required for every
  Billing role (checked: no Billing without it), and the session times out after 30 minutes idle.
  Fix: already on the later list.

### Pass (verified)

- **Authentication and sessions.** Every protected page and download sends a signed-out visitor to
  sign in (all 11 billing and roster download, export and page addresses checked). The
  scheduled-job address needs its 32+ character secret, compared in constant time (401 without
  it).
- **Two-factor.** Two-factor is required for manager, team leader, staff admin and system admin.
  Billing needs a two-factor session (the Billing Officer without one sees nothing).
- **Revoked access.** Deactivating a manager removes all access at once, even with an unexpired
  token. A revoked grant stops working on the next request; nothing is cached across requests.
- **Function-based permissions.** All 15 Billing actions were checked per role (System
  Administrator and Manager Administrator have all 15; nine other roles have none). Job titles
  don't grant Billing by themselves. A Manager Administrator restriction on the Access page
  applies.
- **RLS and direct requests.**
  - Every table has RLS.
  - A Case Manager changing a client ID got 0 rows (client, services, funding, billing).
  - Support worker, case manager and team leader got no prices, terms, balances, budgets or
    forecast rows through direct calls.
  - None of the 63 functions added in 163-170 is SECURITY DEFINER.
- **Financial actions.** Refused without the specific right: approve a line, record a payment,
  change business details. The maker can't approve; the second approver is enforced above the
  write-off threshold. Amounts and the client on a billing line can't be changed, even by a
  Manager Administrator. A claim can't be set to Submitted directly. Allocations can't go to
  another payer's invoice or claim, or be more than owed.
- **Client, staff and assessment records.** Client files need the client-documents right for that
  client's folder. Staff records and compliance files are the person's own folder, or someone with
  the matching right.
- **Files, PDFs and exports.**
  - Issued PDFs are stored once and locked.
  - PDF routes look up the record as the signed-in person, then check Billing view for that
    record's client.
  - Exports need the export right.
  - All downloads are in the download trail.
- **Input and ID tampering.** IDs are checked as UUIDs before use. Server actions re-check in the
  database. Amounts and payers are validated by database rules, not the screen.
- **Audit integrity.** Even the System Administrator can't delete, rewrite or type in audit
  records. The funding ledger can't be deleted. Approved and issued financial records never change
  (database tests).
- **Master key (service role).** 28 files were reviewed. Each use is either a background or
  sign-in job (alerts, email outbox, invites, password reset, sign-in lockout), or comes after the
  same change was accepted by the database as the signed-in person: deactivate, delete an
  unstarted person, two-factor reset, PIN clear, notices after a roster change. The platform
  dashboard that uses it is shown only to the System Administrator.
- **Background jobs.** These run only through the service role (the scheduler), which is now also
  the only caller of the escalation job (update 171).

### Deferred (architecture)

- **D1. Customer isolation is by separate databases, not by `org_id`.** 118 tables have `org_id`,
  but no access rule uses it. Each database holds exactly one organisation; even the System
  Administrator can't add a second (tested). Sharing one database between customers would need
  organisation-scoped access rules on every table and its own review.
- **D2. Signing in again for money approvals, issuing and exports** (W5), and the wider Zero Trust
  hardening list in the TODO.

## Recommendation

**Safe to deploy updates 167-170 after the security corrections.**

The four vulnerabilities aren't in 167-170 themselves; they predate them. But V1 and V2 are open on
Dev today, so run update 171 with or before 167-170.

The app fixes (V3, V4) ship with the code. Order:

preview-167 -> update-167 -> preview-168 -> update-168 -> preview-169 -> update-169 ->
preview-170 -> update-170 -> preview-171 -> update-171

171 doesn't depend on 167-170, so it can also go first. Nothing goes to Dev until you approve.
