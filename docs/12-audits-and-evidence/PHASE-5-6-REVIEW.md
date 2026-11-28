# Phase 5-6 consolidated review and deployment readiness (updates 163-170)

cmeprojects, 27 Nov 2026. Prepared by the coding agent for the owner's review. Nothing was run on
Dev, nothing was undone, and no correction has been made yet: corrections below wait for approval.

## A. Deployment status

- **163-166 on Dev:** run by the owner (164-166 confirmed 23 Nov 2026). The agent can't reach Dev
  (no credentials, by design). To confirm, run the read-only check
  `supabase/live-updates/check-158-170.sql` on Dev: 158-166 should read "yes", 167-170 "no",
  15 Billing actions. An `undo_160_kept` schema may exist from the earlier undo of 160.
- **167-170 locally:** built, committed, not on Dev.
- **Order and dependencies:** 167 (service codes) -> 168 (document templates) -> 169 (contracted
  hours; the roster screens already in the app need it) -> 170 (roster billing checks; needs 162).
  Each preview checks its prerequisites.
- **Round trip (this session, all four together):** each preview is read-only (ran inside a
  read-only transaction with no error); each update ran twice; undo 170, 169, 168, 167 in turn,
  each twice, returned the schema exactly to the step before (0 differences each), so no undo
  touches earlier work; running 167-170 again after the undos matched the first run (0 differences).
- **No undo of 163-166 is needed:** no data-integrity or security defect was found.

## B. Findings

Legend: PASS verified; CORRECTION proposed (needs approval); BLOCKED waiting on owner input or
official verification; DEFERRED future work (in TODO).

### 163 Claims and client invoices
- PASS: compliance register. Claims, invoices and line approval pause when a rule or figure isn't
  verified with official link, document version and "review by" date, or is past its review date
  (`billing_scheme_ready`). The dashboard names each item due within 30 days. Nothing defaults to
  zero: unverified schemes produce no calculation.
- PASS: business details versioned, never edited (new version), ABN validated; issued documents keep
  the version. Bank details readable only with Billing view or by the System Administrator.
- PASS: invoice issue blocked until business details exist and the accountant's GST verification
  (who and date) is recorded. "Tax invoice" is set only when the business is GST-registered **and**
  at least one line is taxable; GST is worked out per line from its GST code; GST-free lines carry
  no GST. Ordinary invoices print "INVOICE".
- PASS: NDIS price limits by support date, catalogue release in force (within its review date) and
  the pricing zone of the **delivery location** (shift location, then service location; never the
  home address by default); "my provider" checked per plan; lines that fail are excluded with the
  reason.
- PASS: manual submission only. Claim file download never changes status; only recording the
  submission (claim submit right, approved claim, file made, the government portal's reference)
  makes it Submitted; a claim can't be set to Submitted directly. No government API code exists.
- PASS: Support at Home full value, contribution and government amount kept apart; care management
  in its own account; full fee reduction supplement stops contribution invoices.
- PASS: invoice numbers sequential per year, never reused; issued PDF stored once and locked; PDF and
  export downloads are in the download trail.
- BLOCKED: partial fee reduction supplements. The screens record only full reductions; how a partial
  supplement changes the contribution needs the verified rule (owner item 12).

### 164 Results, payments, reconciliation
- PASS (database tests): accepted / partly accepted / rejected per line with a reason; results never
  change; a fully rejected line goes into one linked replacement claim only; payments, credits,
  refunds and write-offs can't exceed what's owed; preparer can't approve; above the write-off
  threshold (configurable, $500 default) a second, different person approves; excluded bank lines
  need a reason; a period can't be completed while a line is unmatched; receipts and credit notes
  numbered and locked once issued.
- **CORRECTION C1:** a client receipt PDF can be made before business details exist, so it would
  print a blank business name and ABN. Fix: refuse to issue the receipt PDF until business details
  are recorded (app only, no SQL).
- DEFERRED: split payments and grouped bank deposits (matching is one-to-one, exact amount).

### 165 Suppliers, markup, pathways
- PASS (database tests): a supplier invoice never makes a client charge by itself; a charge needs an
  approved supplier invoice, one live charge per supplier line, its own approval by someone else, a
  reason when the markup differs from the rule; markup rules never change; AT-HM charges need an
  approved pathway budget.
- BLOCKED: markup rules, pathway rules and unspent HCP treatment to verify (owner items 7, 11).

### 166 Reporting
- PASS: separate sections for revenue (approved lines and charges, full value), government claims
  (claimed, expected, accepted, paid, written off, waiting), invoices (issued, credited, paid,
  owing), money owed by age, money in and out, supplier costs and charges, budgets, integrity checks.
  CSV needs the export right and is in the download trail.
- DEFERRED: a reconciliation-status section in Reports (today on the Reconciliation tab and as the
  "Unmatched bank lines" check).

### 167 Service codes and catalogue pricing
- PASS: codes unique (index), sequential, prefix changes leave existing codes alone, locked once
  billed. Catalogue names are unique ignoring case, so a by-name link can't be ambiguous; prices can
  be linked, by name, or both; "Not priced yet" list; a service with no price can't be billed.
  Catalogue-only pricing isn't forced.
- PASS (note): the Support at Home service type is a display label only; claims don't use it.
- BLOCKED: approved Support at Home service-type mapping (owner item 6).

### 168 Document templates
- PASS: wording follows the document, not the template. Tax invoice / Invoice from the GST rule
  above; credit notes are "ADJUSTMENT NOTE" for a tax invoice, otherwise "CREDIT NOTE", and name the
  original invoice; receipts are "RECEIPT" with payment and allocations; statements are titled as
  statements. Business name, ABN and address always print and template settings can't remove them.
  Templates are versioned (insert only); each issued document records the version; issued PDFs never
  change.
- **CORRECTION C5 (wording only), done 28 Nov 2026:** the code comment, the 168 migration header and
  the template settings note said "Tax invoice" always prints; they now say it prints only when it
  applies. D-072 already read correctly ("legally required parts can't be removed").

### 169 Rostering
- PASS: client view default, Staff one click; best match only sorts (never assigns); Duplicate makes
  a draft open shift copying the plan only (no timesheet, signatures, approvals or billing);
  contracted hours editable only by roster editors, workers see only their own.
- **CORRECTION C4:** on phones there's no tap alternative to the right-click Duplicate. Add
  "Duplicate as an open shift" to the shift panel (app only).
- DEFERRED: auto-wrap visits, breaks as roster items, roster using the catalogue.

### 170 Roster billing checks and forecast
- PASS: estimates never make lines, never touch funding or the ledger (test: no lines made; the
  function writes nothing); dates, terms, enrolment, price list, bands, holidays, contribution,
  location and funding are taken on the shift date; the forecast is worked out fresh on every page
  load; incomplete set-up shows its reason, never a made-up amount.
- PASS (direct requests, this session): a support worker, case manager and team leader calling the
  functions directly get no prices, terms, balances, budgets or forecast rows; a billing officer
  does. Warning only (D-075); no new SECURITY DEFINER function.
- **CORRECTION C2 (wording):** "4 ready" should read "4 with no set-up issue found (not delivered,
  billed or claimed)", and the roster hover should say "estimate only".
- **CORRECTION C3:** the budget forecast's "Available now" combines the approved balance and draft
  lines. Show separately: approved balance, draft lines, rostered estimates, projected left, goes
  over on (app only).

### Access, security and audit (all updates)
- PASS: all 15 Billing actions exist and were checked one by one this session: System Administrator
  and Manager Administrator all 15; Billing Officer (test grant) only view and prepare; Case
  Manager, Intake & Assessment Officer, Payroll Officer, Team Leader, Staff Administrator, Support
  Worker none. Every table has RLS; none of the 63 functions added in 163-170 is SECURITY DEFINER;
  no 163-170 table is granted to signed-out visitors.
- **CORRECTION C6 (test only):** the default-access test checks only the first 5 actions. Extend it
  to all 15 and to the roles above.

## C. Critical safeguards

| Safeguard | Status |
|---|---|
| Manual government claim submission | Confirmed (database) |
| No automatic claim submission | Confirmed; no API code |
| No double recovery | Confirmed (recovery checks; integrity check "Recoveries above the service value") |
| No duplicate accepted claim amounts | Confirmed (only fully rejected lines go into one replacement) |
| No unauthorised financial access | Confirmed (15 actions per role; direct-request probe) |
| No self-approval | Confirmed (database tests) |
| No automatic client charge from supplier invoices | Confirmed |
| Correct GST and tax invoice wording | Confirmed in the database and PDFs; docs wording to correct (C5) |
| No billing from roster estimates | Confirmed |
| No funding deductions from roster forecasts | Confirmed |
| No new SECURITY DEFINER function | Confirmed |

## D. Testing (actual results, 27 Nov 2026)

- Full database suite: 134 files, 2,578 checks, 0 failures; fresh install current. File counts
  (including set-up checks): claims_invoices 57, payments_reconciliation 104, suppliers_pathways 88,
  financial_reporting 94, service_codes 14, document_templates 10, roster_contract_hours 4,
  roster_billing_checks 22, billing_lines 55.
- Round trip 167-170 together: clean (section A).
- Lint and typecheck: pass.
- **Not rerun this session: browser tests.** The container restarted with an empty local database,
  and the earlier browser scripts and test data were in the temporary scratchpad, which was cleared.
  Earlier reported results (167 11/11, 168 6/6, roster 16/16, 170 13/13, 163 50/50, 164 34/34,
  162 25/25) can't be re-verified. Only the 170 script can be recovered (C7: save it in
  `tests/e2e`). The update 161 date failure ("this Monday 9am" is in the future just after
  midnight) came from that test script, not the app; it needs a fixed test date when the script is
  recreated.

## E. Data and rollback

No data-integrity or security defect was found in 163-166. No undo is recommended. All proposed
corrections are app, wording or test changes; none needs SQL or touches Dev data.

## F. Owner decisions and inputs

1. Approve corrections C1-C7 (or choose which).
2. Run `check-158-170.sql` on Dev and share the result.
3. Nominee: verify the 27 rule checks and figures (official link, version, effective and review dates).
4. Official NDIA bulk upload and Services Australia claim templates.
5. Business details and the accountant's GST verification.
6. Current NDIS Support Catalogue and delivery-location pricing zones.
7. Support at Home service-type mapping; markup rules; confirm the $500 write-off threshold.
8. CHSP, Private and Other rules; care management rollover; the NDIS 90-day claim rule; pathway and
   unspent HCP rules; partial fee reduction supplements.

## G. Recommendation

**Ready to deploy 167-170 in order after corrections C1-C4** (C5-C7 are wording and tests and can
ride with them). None of C1-C7 changes the SQL files, so the update files stay as they are. If you'd
rather not wait, 167-170 are safe to run now: the corrections are app-side.

Order: preview-167 -> update-167 -> preview-168 -> update-168 -> preview-169 -> update-169 ->
preview-170 -> update-170. Stop if a preview says a prerequisite is missing or shows something
unexpected. Real claims and invoices stay blocked until items 3-8 are in.

## Corrections done (28 Nov 2026, approved by the owner)

C1-C7 are built and tested locally (D-076); none changed SQL or Dev data.
- **C1:** `src/lib/business.ts`, `billing/money-actions.ts`.
- **C2 and C3:** `billing/tabs.tsx`, `billing/page.tsx`, `roster/page.tsx`.
- **C4:** `roster/actions.ts` (`duplicateOpenShift`), `roster/page.tsx`.
- **C5:** `src/lib/billing-pdf.ts`, the 168 migration header (a comment only; 168 isn't applied
  anywhere), `settings/billing/template-forms.tsx`.
- **C6:** `supabase/tests/billing_setup.test.sql`.
- **C7:** `tests/e2e/roster-billing.e2e.cjs` with `tests/e2e/fixtures/roster-billing.sql`, 23/23 on
  a fresh local database.

The Zero Trust review that followed is in `ZERO-TRUST-REVIEW-2026-11.md`.
