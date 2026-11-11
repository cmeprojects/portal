# Improvement and enhancement request: review and plan (cmeprojects)

Staff Portal · © cmeproject · 11 November 2026 · **Review only: nothing changed.** Approval needed per phase.

## 1. What exists, what changes (by request item)

| # | Item | Exists now | Change needed | DB change |
|---|---|---|---|---|
| 2.1 | Sign-in page | Two-column layout (brand panel on desktop, logo small and left in the form) | Centred, larger logo; spacing and typography | No |
| 2.2 | Remembered email | Not built | Remember **email only** (never password or session) in the browser; "Not you? Use a different account" clears it; a tick box "Remember my email on this device" (off on shared devices). Cleared on deactivation | No |
| 3.1 | Animated charts | Doughnut and bar charts on the manager board (SVG and CSS, no library) | One-time grow-in animation on first load; respects reduced motion; no replay on filter changes | No |
| 3.2 | Birthdays and anniversaries | Start date exists (anniversaries possible). **No date of birth field** | Add an optional **date of birth** (private) plus a **"show my birthday to colleagues"** choice (off by default); show **day and month only**, never year or age. Upcoming 14 days panel; empty state | Yes (2 columns) |
| 3.3 | Dashboard layout | Role dashboards built from "pieces" | Move Tasks under the business/care section; confirm the exact order with a mock-up | No |
| 4.1 | People icons | Some icons exist | Consistent icons for Staff, Teams, Managers, Roles, Clients, Onboarding, Staff requests | No |
| 4.2 | First Aid, CPR, Life saving | Onboarding uploads support category, issue date, expiry, number and verification. Default "First Aid and CPR" is one item | Split into **First Aid**, **CPR** and **Life saving** default items (switched off, editable). Mostly configuration | Seed only |
| 4.3 | TFN, bank, super, visa | Not built | New **sensitive employee records** area (see §3) | Yes |
| 5.1 | Policies and agreements | Read-and-acknowledge with typed name and version fingerprint; agreements with drawn signature; targeting by role, team or position | Add: assign to **selected people**; keep **old versions** (text or file per version); outstanding list | Yes |
| 5.2–5.3 | E-signatures and contracts | Drawn signature + typed name + version fingerprint + time + device | Per-employee **contracts** with statuses (Draft → Awaiting employee → Awaiting employer → Fully signed → Superseded); final **signed PDF** with an audit page and document hash; email code before signing; employer countersign. **Decision needed: build or third party** (§4) | Yes |
| 6.1 | Collapsible sections | Finished items fold; sections don't | Every section expandable and collapsible; compact by default (open where something is due) | No |
| 6.2 | Buttons | Most tested in Step 2 | Check every button; fix any that do nothing | No |
| 6.3 | Expiry visibility | Expiry stored; "Expired or expiring" tile in People → Onboarding; daily expiring and expired alerts | **Expiry register** tab in People → Onboarding; staged reminders at **60, 30 and 7 days and on the day** to the person and Compliance managers only; dashboard tile for managers and Compliance; "needs renewal" and "awaiting verification" flags | Small |
| 7.1 | Remove test forms | Forms are **data** in the Forms module (a core module, not test tables) | Delete only the test **forms (rows)**, not the module's tables. If they came from "Load sample data", **Demo data → Remove sample data** does it safely. Otherwise I list them first and you approve | Data only (approval) |
| 7.2 | Forms to everyone or selected | Forms can be sent to everyone, roles, teams or chosen people; they appear in My onboarding ("Forms sent to you") | Add a **My forms** item under My account (to fill in, done), and keep onboarding forms in onboarding only. No duplicates | No |
| 7.3 | Forms menu "skips" | Cause: the Forms menu shows for everyone when Forms is on, but the page is for form makers; others are sent elsewhere | Show **Forms** only to form makers; staff use **My forms** with a proper empty state | No |
| 8 | Name editing | Staff can change their own name (My account, Welcome page) | Name **read-only** for staff; only the system admin (or someone delegated) edits names, in the change log; enforced in the database | Yes (rule) |
| 9.1 | Requests vs tasks | **Separate.** Requests (leave, swaps and so on) are their own records with approvals. **No task is created** | Keep separate. Optional: "Create follow-up task" on an approved request (linked) where operational work is needed | Small (link column) |
| 9.2 | Request notifications | Approvers notified; escalation; bell and email | Check delegated approvers and no duplicates; the bell link opens the request | No/small |
| 10.1 | Directory tasks | Already: staff can't see another person's tasks (panel shown only to overseers and RLS limits tasks). Verify only | No |
| 10.2 | Directory for system admin | Deliberately hidden from the system admin | Add it back for the system admin | No |
| 11 | Bell under content | Bell panel uses `z-50`; some page elements create a higher stacking layer | Fix in the shared bell component (portal or stacking) | No |
| 12 | "Tools" heading | Menu group headed "Tools" (built features, Cars, Apps) | Remove the heading (or rename "Apps") | No |
| 13 | Request approvals UI | Waiting for me and All requests lists; detail page with actions | Summary tiles, status colours (Pending, Approved, Declined, Withdrawn, More info), filters and search, confirm dialogs, tidy detail and history | No |
| 14.1 | Manager Deploy button | Settings save as drafts; Deploy makes them live (all roles) | **Managers:** save = live straight away, with a "Changes are live" message. **System admin:** keep Deploy (or make it the same; your choice) | No |
| 14.2 | Settings layout | Managers see some settings on separate pages | Reuse the System settings layout for manager and staff admin settings | No |
| 14.3 | SLA settings | System admin: Features → Tasks. Managers: Settings → Due dates (SLA). One set of SLA data | One place: **Settings → Tasks → SLA settings** (same data, nothing duplicated) | No |
| 15 | Delegation | Delegation areas (system admin → all managers or chosen people; managers share with staff admins); change log; delegates can't grant themselves more | **Gap:** managers and staff admins can edit staff details and business cards **by default**. Change to **only when delegated** (new area "Staff details"). Add **expiry dates** to delegations; revoking takes effect immediately (it already does) | Yes |

## 2. Dependencies
- **Sensitive records (4.3) → contracts (5.3) → expiry register (6.3)** share one secure document approach. Build the secure storage first.
- **Name read-only (8) and Staff details delegation (15)** both touch who can edit profiles. Do them together.
- **My forms (7.2) before the Forms menu fix (7.3).**
- **Manager save = live (14.1)** reuses the existing draft and deploy code (no new framework).

## 3. Sensitive employee information (TFN, bank, super, visa): proposed design
- **TFN:**
  - Do **not** store the TFN number in a field.
  - Keep the blank ATO TFN declaration template (uploadable by the system admin or a delegate) and the **completed form as a file** in a separate private storage area.
  - TFN Rule 2015 limits use and requires secure storage and destruction when no longer needed. **Professional or ATO guidance recommended** on how long to keep it (or pass it to payroll and delete).
- **Bank and super:** a separate table, readable only by the person and authorised payroll or HR users.
  - Shown **masked** (last 3 digits) unless "Reveal", which is logged.
  - Supabase encrypts all data at rest. Column-level encryption (Supabase Vault) is possible but adds complexity; I recommend masking + strict RLS + audit first.
- **Visa and work rights:**
  - Work rights type: citizen, permanent resident, visa.
  - For visa holders: subclass, conditions (free text), expiry, a VEVO check upload, verification.
  - Fields required only when "visa" is chosen. Configurable.
- **Documents:** a **separate private storage bucket**. Files are reached only through a server action that checks permission, writes an **access log** (view, download, upload, replace) and returns a link valid for 60 seconds. Never public URLs.
- **Never shown in:** directory, dashboards, notifications, search, ordinary reports or exports.
- **Access matrix (proposed):**

| Role | Own sensitive record | Others' sensitive records |
|---|---|---|
| Staff, team leader | View, add, update own (bank, super, visa docs; TFN form upload) | None |
| Manager, staff admin | Own | **Only if delegated "Payroll and HR records"** (new delegation area) |
| System admin | Own | All |
| Signed out | None | None |

  Every view, reveal, download and change of others' records is logged.
- **Security mode:** tables and storage protected by RLS (SECURITY INVOKER reads). One small audit-logging step may need the existing `write_audit` (already SECURITY DEFINER, approved earlier); **no new SECURITY DEFINER function without your approval**.

## 4. E-signatures: build or third party (decision needed)
| | Enhanced in-app (build) | Third-party provider |
|---|---|---|
| How | Read → email one-time code → consent tick → drawn signature + typed name → server makes the **final PDF** (document + signature + audit page with signer, time, IP and device, version hash) → stored privately; employer countersigns the same way; signed PDFs locked (new version = new document) | DocuSign, Adobe Acrobat Sign, Dropbox Sign, or Australian-based providers (for example Annature). The provider handles identity, signing, certificate and tamper-evident PDF |
| Evidence strength | Good for policies and most agreements; our own audit trail | Stronger, independent certificate; well known to lawyers |
| Cost | Development only | Ongoing subscription (typically per sender per month, or per envelope; check current pricing) plus integration work |
| Data location | Your Supabase (Sydney) | The provider's servers (check AU data residency) |

**Recommendation:**
- **Policies and acknowledgements:** in-app (already built), with version history added.
- **Employment contracts:** start with the **enhanced in-app** workflow, designed so a provider can be plugged in later if your lawyer prefers.

**Legal note:** Australian law (*Electronic Transactions Act 1999* (Cth) and the Victorian equivalent) generally allows electronic signatures for employment contracts, but requirements depend on the document and circumstances. **Have an employment lawyer confirm the process.** No method is claimed to satisfy all legal requirements.

## 5. Destructive operations (each needs explicit approval)
- **Deleting test forms** (data). The Forms module's tables and code stay.
- **Dropping the Welcome page's ability to change the name.** Not destructive to data, but changes behaviour.
- **Nothing else** deletes data or structures.

## 6. Recommended order (adjusted for dependencies)
| Phase | Contents | DB update |
|---|---|---|
| **1. Quick fixes and polish** | Sign-in page; remembered email; chart animation; People icons; onboarding collapsible sections and button check; bell layering; remove "Tools"; Directory for system admin; Forms menu fix + **My forms**; Request approvals UI | None |
| **2. Permissions tidy-up** | Name read-only for staff; "Staff details" delegation (managers edit only when delegated); delegation expiry; manager save = live; SLA in one place; consistent settings layout | Yes (one update + undo) |
| **3. People records** | First Aid, CPR and Life saving items; expiry register + staged reminders; **sensitive records** (TFN form, bank, super, visa) with private storage and access log | Yes (one update + undo) |
| **4. Agreements and contracts** | Version history; assign to selected people; per-employee contracts with statuses, enhanced signing, signed PDF | Yes |
| **5. Dashboard and requests** | Birthdays and anniversaries (with consent); dashboard layout; optional follow-up task from a request; notification checks; delete approved test forms | Small |

## 7. Decisions needed from the owner
1. **Remembered email:** OK as an opt-in "Remember my email on this device" (off by default)?
2. **Birthdays:** OK to add an optional date of birth with "show my birthday" consent (day and month only)?
3. **Sensitive records:** OK not to store the TFN number (form file only)? Who besides the system admin should see bank, super and visa: a delegated "Payroll and HR records" area?
4. **E-signatures:** enhanced in-app first (recommended), or a third-party provider now?
5. **System admin settings:** keep Deploy for the system admin, or make every save live straight away for everyone?
6. **Test forms:** were they loaded with "Load sample data"? If not, I'll list them for approval.
7. **Approve Phase 1** to start.
