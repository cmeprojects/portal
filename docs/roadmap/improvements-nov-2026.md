# Improvement and enhancement request: review and plan (cmeprojects)

Staff Portal · © cmeproject · 11 November 2026 · **Revised plan (rev 2): nothing implemented.** Approval needed per phase. Owner requirements of 11 November included.

## 1. What exists, what changes (by request item)

| # | Item | Exists now | Change needed | DB change |
|---|---|---|---|---|
| 2.1 | Sign-in page | Two-column layout (brand panel on desktop, logo small and left in the form) | Centred, larger logo; spacing and typography | No |
| 2.2 | Remembered email | Not built | Remember **email only** (never password or session) in the browser; "Not you? Use a different account" clears it; a tick box "Remember my email on this device" (off on shared devices). Cleared on deactivation | No |
| 3.1 | Animated charts | Doughnut and bar charts on the manager board (SVG and CSS, no library) | One-time grow-in animation on first load; respects reduced motion; no replay on filter changes | No |
| 3.2 | Birthdays and anniversaries | Commencement date (`start_date`) exists. No birthday field | Birthday **day and month only** (no year collected), with the employee's own **show / hide** choice (off by default, changeable any time). Same-day greetings + upcoming list. Active employees only (§5) | Yes (1 table) |
| 3.3 | Dashboard layout | Role dashboards built from "pieces" | Move Tasks under the business/care section; confirm the exact order with a mock-up | No |
| 4.1 | People icons | Some icons exist | Consistent icons for Staff, Teams, Managers, Roles, Clients, Onboarding, Staff requests | No |
| 4.2 | First Aid, CPR, Life saving | Onboarding uploads support category, issue date, expiry, number and verification. Default "First Aid and CPR" is one item | Split into **First Aid**, **CPR** and **Life saving** default items (switched off, editable). Mostly configuration | Seed only |
| 4.3 | TFN, bank, super, visa | Not built | Restricted records area (§3); TFN encrypted (§4), **after accountant/ATO review** | Yes |
| 5.1 | Policies and agreements | Read-and-acknowledge with typed name and version fingerprint; agreements with drawn signature; targeting by role, team or position | Add: assign to **selected people**; keep **old versions** (text or file per version); outstanding list | Yes |
| 5.2–5.3 | E-signatures and contracts | Drawn signature + typed name + version fingerprint + time + device | Own signing system, no subscription (§6); contracts with statuses Draft → Awaiting employee → Awaiting employer → Fully signed → Superseded/Expired | Yes |
| 6.1 | Collapsible sections | Finished items fold; sections don't | Every section expandable and collapsible; compact by default (open where something is due) | No |
| 6.2 | Buttons | Most tested in Step 2 | Check every button; fix any that do nothing | No |
| 6.3 | Expiry visibility | Expiry stored; "Expired or expiring" tile in People → Onboarding; daily expiring and expired alerts | **Expiry register** tab in People → Onboarding; staged reminders at **60, 30 and 7 days and on the day** to the person and Compliance managers only; dashboard tile for managers and Compliance; "needs renewal" and "awaiting verification" flags | Small |
| 7.1 | Test forms | None left (owner removed them) | **No deletion.** Existing forms, tables, reports and components untouched | No |
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
| 14.1 | Manager Deploy button | Settings save as drafts; Deploy makes them live | **Managers:** save applies live directly (§7). **System admin:** keeps Deploy | No |
| 14.2 | Settings layout | Managers see some settings on separate pages | Reuse the System settings layout for manager and staff admin settings | No |
| 14.3 | SLA settings | System admin: Features → Tasks. Managers: Settings → Due dates (SLA). One set of SLA data | One place: **Settings → Tasks → SLA settings** (same data, nothing duplicated) | No |
| 15 | Delegation | Areas, change log, sharing with staff admins | Separate **Staff details** area (ordinary profile) from **sensitive** areas; scoped, expiring, revocable, cascading delegation (§3) | Yes |

## 2. Dependencies
- **Delegation model (Phase 2) before any sensitive records** (Phases 3–4): sensitive access is granted through it.
- **Private storage + access log (Phase 3a)** is reused by work-rights documents, TFN forms and signed contracts.
- **TFN number (Phase 3b)** depends on the **accountant/ATO review** and on the encryption key being set up in Vercel.
- **Signed PDFs (Phase 4)** need one new free library (`pdf-lib`, MIT licence) to build PDFs on the server.
- **My forms (7.2) before the Forms menu fix (7.3).**
- **Name read-only (8)** goes with the Staff details area (Phase 2).

## 3. Permissions and delegation (sensitive records)
**Three separate permission areas** (ordinary profile access never grants sensitive access):
| Area | Covers |
|---|---|
| Staff details | Names, contact, position, business card (ordinary profile) |
| Payroll and tax | Bank, super, TFN declaration and TFN number |
| Identity and work rights | Citizenship/residency, visa details and documents, VEVO checks |

**Rules (enforced by server checks and Supabase RLS, not just the screen):**
- **System admin** holds all areas and makes the **initial grant**, to chosen managers only (never "all managers" by default for sensitive areas).
- A grant to a manager can include **"may pass on"**. Only then can that manager grant the same area (no wider) to chosen staff admins. A delegate can never grant to themselves, widen the scope, or pass on further.
- **Staff admins get nothing automatically.** The existing "share with staff admins" setting will exclude both sensitive areas.
- **Scope** on every grant: all staff, or chosen teams.
- **Optional expiry date**; checked on every access (expired = no access, no clean-up job needed).
- **Revoke takes effect immediately**, and revoking a manager also ends anything they passed on.
- **TFN reveal** is a separate tick on a Payroll and tax grant ("can reveal TFN"); without it the holder sees the TFN masked only.
- Every grant, change, expiry and revoke goes to the change log (who, what, scope, when).
- Staff always see and update **their own** records; no staff member sees anyone else's.
- Never shown in the directory, dashboards, notifications, search, ordinary reports or exports.

**Storage and documents:** a separate private storage bucket; files opened only through a server action that checks permission, records the access (view, download, upload, replace) and returns a link valid for 60 seconds. Bank and super values shown masked unless revealed (logged).

**Security mode:** RLS on every new table and the bucket (SECURITY INVOKER reads). Audit entries use the existing `write_audit`. The delegation checks extend existing functions (already approved as SECURITY DEFINER). **No new SECURITY DEFINER function without your approval.**

## 4. TFN security (Phase 3b, after accountant/ATO review)
- **Prerequisite:** accountant/ATO review of collecting and storing the TFN, retention and destruction, and lodging the TFN declaration. Not built until you confirm.
- **Encryption:** AES-256-GCM (authenticated) in the app server only, using Node's built-in crypto (no new library). A fresh random 12-byte IV per value; the person's ID is bound as additional data so a value can't be moved to another record. The database stores only `key version : IV : ciphertext : tag`.
- **Keys:** kept in Vercel's environment settings (marked Sensitive), separate keys for Development and live; never in the database, source code, Git or chat.
- **Key rotation:** keys carry a version number. Add the new key, then a system-admin "re-encrypt TFNs" action rewrites every value with it (logged); the old key is removed only after that finishes.
- **Key recovery:** you keep an offline copy of each key (for example in a password manager). If a key is lost, its TFNs can't be recovered and must be collected again from the employees; the encrypted TFN declaration files are unaffected. This is written into the handover document.
- **Never exposed:** not in logs or error messages, notifications, ordinary reports, exports, search, or browser storage. A reveal is fetched on demand with no caching (`no-store`), shown masked again after 30 seconds and not kept in page state.
- **Decryption** only for the person themself and holders with "can reveal TFN". Checked on the server and by RLS before the value is even read.
- **Audit:** every reveal **and every refused reveal attempt** is logged (who, whose, when, allowed or refused).
- **Validation:** 9-digit format and ATO check digit, labelled "format check only". It is **not** proof the TFN belongs to the person.

## 5. Birthdays and employment anniversaries (Phase 5)
- **Data minimisation:** collect birthday **day and month only**; the year is never asked or stored, so age can't be shown or worked out.
- **Consent:** "Show my birthday to colleagues" choice, **off by default**, in My account; changeable any time and effective immediately. With it off, nobody else sees the birthday (enforced by RLS).
- **Anniversaries:** from the **commencement date** (`start_date`); shown as years of service ("3 years today"). Employees without a commencement date are skipped.
- **Active employees only:** deactivated people and staff not yet started are excluded.
- **Dashboard:** greetings on the day, plus an **upcoming list** (next 14 days), with an empty state. 29 February birthdays show on 28 February in other years.
- **No new SECURITY DEFINER** (normal RLS: own row always; others only when shown and active).

## 6. Electronic signatures: own system (Phase 4)
| Requirement | How |
|---|---|
| Authenticated signer identity | Signed in, plus a fresh **email one-time code** at signing; the signer must be the assigned person |
| Explicit consent | A consent statement (to sign electronically and receive the document electronically) ticked before signing; its wording version is recorded |
| Exact version | Each document version has an ID and a **SHA-256 hash** of the exact PDF shown to the signer |
| Date and time | Server time (stored in UTC, shown in Sydney time), not the device's clock |
| Integrity check | A "Verify" action recomputes the signed PDF's hash and compares it with the record |
| Final signed PDF | Built on the server: the document, the signatures, and an **audit page** (signers, times, method, IP, device, hashes) |
| Immutable history | Signing events are append-only: no update or delete for anyone (permissions + trigger) |
| No changes after signing | Signed PDFs and their versions are locked; storage rules refuse overwrite and delete |
| Revised document | Creates a **new version and a new signing process**; the old one is marked Superseded, never altered |

Contracts: employee signs first, then an authorised employer signatory countersigns; statuses as in §1. Policies keep the current acknowledgement, with version history added.

**Needs professional (employment lawyer) review:**
- *Electronic Transactions Act 1999* (Cth) and the relevant state act (for example NSW 2000): identification method, reliability, consent, which law applies.
- *Fair Work Act 2009* and *Fair Work Regulations 2009*: employee record-keeping (form and 7-year retention), giving the employee a copy, and the Fair Work Information Statement and Casual Employment Information Statement.
- Modern award or enterprise agreement terms on written agreements (for example individual flexibility arrangements, and a parent's signature for employees under 18).
- Whether any document needs witnessing or a wet signature (for example deeds).
- *Privacy Act 1988*: the employee records exemption and its limits; the *Privacy (Tax File Number) Rule 2015*; the Notifiable Data Breaches scheme (applies to TFN information).
- *Migration Act 1958*: employer obligations for work rights and VEVO checks.
- Superannuation choice of fund and stapled fund obligations; how long to keep signed and sensitive records after employment ends.

No method here is claimed to satisfy every legal requirement.

## 7. Manager settings (Phase 2)
- **System admin:** keeps drafts and Deploy, unchanged.
- **Managers:** Save applies their authorised change directly. It's live only once the database has saved it (one transaction); if anything fails, nothing changes.
- **Messages:** "Saved: live now" on success; a clear error on failure, with the form kept as typed.
- Server checks + RLS limit managers to the areas delegated to them. No leftover drafts for managers.

## 8. Destructive operations
**None.** No forms, tables, reports or components are deleted.
**Access reductions** that need your approval:
- Staff can no longer edit their own name.
- Managers and staff admins edit staff details only when delegated (see decision 1).

## 9. Phases (each: lint, typecheck, tests, database tests, six roles)
| Phase | Contents | DB update |
|---|---|---|
| **1. Quick fixes** | Sign-in page; remembered email (opt-in); chart animation; People icons; collapsible onboarding sections and button check; bell layering; remove "Tools"; Directory for system admin; Forms menu fix + My forms; Request approvals UI | None |
| **2. Permissions** | Three permission areas; scoped, expiring, cascading delegation with "may pass on"; names read-only (DB-enforced, logged); manager save = live; SLA in one place; consistent settings layout | Yes + undo |
| **3a. Records** | First Aid, CPR, Life saving items; expiry register + staged reminders; private bucket + access log; bank, super, work rights and visa | Yes + undo |
| **3b. TFN** | TFN declaration form and encrypted TFN number. **Only after the accountant/ATO review and your go-ahead** | Yes + undo |
| **4. Signing** | Version history; assign to selected people; contracts; own e-signature system with signed PDFs | Yes + undo |
| **5. Dashboard** | Birthdays and anniversaries; dashboard order; optional follow-up task from a request; request notification checks | Yes + undo |

**Security testing** for Phases 2–5: RLS tests in `supabase/tests` for every new table, bucket and grant path (self, other staff, team leader, manager with and without grant, staff admin with and without pass-on, system admin, signed out, expired and revoked grants), plus checks that TFNs never appear in logs, responses or storage.

## 10. Owner decisions (rev 2, 11 November 2026)
1. **Staff details rollout:** existing managers keep it at rollout (visible, revocable).
2. **Sensitive areas:** two (Payroll and tax; Identity and work rights).
3. **TFN reveal:** separate tick.
4. **Delegation scope:** all staff, chosen teams, or **specific people**.
5. **Upcoming window:** 7 days.
6. **`pdf-lib`:** approved for Phase 4.
7. **Retention:** keep **5 years** after employment ends for now. Setting to change the period; system admin can **export** a leaver's records or **delete them permanently** (confirmation, logged; signed documents and the audit entry of the deletion kept as required). To be confirmed with accountant/lawyer.
8. **Phase 1:** approved, started 11 November 2026.
