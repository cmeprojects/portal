# Phase 5 report: claims, invoices, payments, suppliers and reporting (updates 163 to 166)

cmeprojects · prepared 23 Nov 2026 · Australia/Sydney · amounts in AUD
Decisions: D-066 (plan), D-067 (5A), D-068 (delivered in one run), D-069 (5B), D-070 (5C), D-071 (5D).
Status: built and tested on local data. Update 163 has been run on Dev. Updates 164, 165 and 166 have
not been run on Dev. Nothing is deployed. The owner reviews all of Phase 5 now.

## 1. SQL to run on Dev (in this order)

| Step | File | What it does |
|---|---|---|
| 163 | preview-163.sql, update-163.sql (done 22 Nov 2026), undo-163.sql | Claims, client invoices, statements, compliance register |
| 164 | preview-164.sql, then update-164.sql; undo-164.sql if needed | Claim results, payments, receipts, credit notes, refunds, write-offs, bank reconciliation |
| 165 | preview-165.sql, then update-165.sql; undo-165.sql if needed | Suppliers, client charges with markup, pathway budgets |
| 166 | preview-166.sql, then update-166.sql; undo-166.sql if needed | Financial reports (read-only view and checks) and statement detail |

- Run each preview first (read only), then its update. Each update is safe to run again.
- Undo goes in reverse order (166, then 165, then 164). Each undo keeps everything it removes in a
  locked schema (undo_164_kept, undo_165_kept; 166 removes no data) and restores nothing by itself.
- undo-165 stops, changing nothing, if a client charge is already in a submitted claim or an issued
  invoice.
- Files are in supabase/live-updates/. Migrations, which new copies use, are in supabase/migrations/.

## 2. What Phase 5 does, stage by stage

### 5A: claims and client invoices (update 163)
- **Compliance register.** Every rule and figure records its official link, document version,
  effective date and "review by" date.
  - Claims and invoices need all of these.
  - Past a review date, claims, invoices and billing line approval pause for that scheme.
  - The dashboard warns 30 days ahead.
- **Business details.** A setup wizard step, and a section in Billing set-up.
  - Each save is a new version.
  - ABN, phone, email, BSB and account are checked.
  - The GST position needs the accountant's verification before any invoice is issued.
- **Payers.** Services Australia, the NDIA, plan managers, participants and clients, linked to each client by date.
- **NDIS.**
  - The Support Catalogue is imported per release and verified.
  - Price limits are applied by support date and by the pricing zone of the service delivery location.
  - "My provider" must be recorded for agency-managed claims.
  - Plan-managed and self-managed supports are invoiced.
- **Official claim templates.** Uploaded from the official file: header row kept exactly, CSV, date
  format and file name limit. Columns are mapped and then verified.
- **Claims.**
  - Prepared, then approved by someone else, then the file is made.
  - A claim becomes Submitted only when a person records the manual upload (who, when, where, reference), then the acknowledgement.
  - Support at Home claims carry the full value; the expected amount is the government share.
  - Care management is claimed once per quarter as clinical care, with no contribution, and shown in its own account.
- **Invoices.**
  - Prepared, then approved by someone else, then issued: numbered INV-YYYY-000001 (never reused), with a snapshot, PDF and checksum, due in 14 days.
  - Then marked sent.
  - It's a tax invoice only when GST-registered and at least one line is taxable.
  - A full fee reduction supplement stops contribution invoices.
- **Monthly Support at Home statements.**
- **No double recovery.** A billing line is recovered once per payer role. A line in a claim or invoice can't be voided.

### 5B: results, payments and reconciliation (update 164)
- **Claim results.** Each line is accepted, partly accepted or rejected.
  - Results are added, never changed; corrections are kept.
  - Only fully rejected lines are claimed again, in a linked replacement claim.
  - Accepted amounts are never claimed twice.
- **Payments.** Allocated to invoices or accepted claim lines, never beyond the payment or what's owed.
  - Reversal needs a reason.
  - Client payments get receipts RCT-YYYY-000001 (PDF).
- **Credit notes.** CN-YYYY-000001; prepared, approved by someone else, issued with a PDF. They're
  adjustment notes for tax invoices.
- **Unlocking a line.** A line fully credited, or fully rejected by the government, can be voided and remade.
- **Refunds.** Proposed, approved by someone else with the refund right, then recorded as paid.
- **Write-offs.** Proposed, approved by someone else with the write-off right; above the threshold
  ($500 to start) a second, different approver.
- **Bank reconciliation.** Statement CSV import, with duplicates skipped.
  - Each line is matched to one payment or refund of the same amount, or excluded with a reason.
  - A period completes only when everything is matched and opening plus lines equals closing.
  - Completed periods never change.

### 5C: suppliers, markup and pathways (update 165)
- **Suppliers and supplier invoices.** Duplicate number check and GST.
  - Recorded, approved by someone else, then paid.
  - Costs never charge a client by themselves.
- **Client charges.** Made by a person from an approved supplier line, with the markup rule (a
  different markup needs a reason), or on their own.
  - Approved by someone else; one live charge per supplier line.
  - Support at Home contributions use the client's rate for the category (clinical none).
  - Charges are claimed, invoiced and shown on statements like billing lines.
- **Pathway budgets.** AT-HM, Restorative Care, End-of-Life and unspent HCP funds per client.
  - Typed in from the Services Australia notice and approved by someone else.
  - Going over needs a covering note.
- **Markup rules.** The provider's pricing policy, by funding stream and date.

### 5D: reporting and integration (update 166)
- **Reports tab** for any period:
  - revenue by scheme and funding;
  - government claims;
  - client invoices;
  - money owed by age;
  - money in and out;
  - supplier costs against charges;
  - budgets;
  - integrity checks.
- A CSV for each section (export right; recorded in the download trail).
- A financial summary on the client's Funding tab.
- **Monthly statement layout** following the owner's sample (branding and colours not copied):
  - funds carried in;
  - the quarter month by month (subsidy against expenditure and what's left);
  - this month's income and expenditure;
  - detail tables for services, other charges and care management, with each line's category,
    contribution rate and the client's share.

## 3. Rights (Billing module)

| Action | Who has it by default |
|---|---|
| view, prepare, approve, prices, export (161) | System Administrator, Manager Administrators |
| claim prepare, approve, submit; invoice prepare, approve, issue (163) | System Administrator, Manager Administrators |
| payments, refund, write-off, reconcile (164) | System Administrator, Manager Administrators |

- Nobody else has these until given on the Access page.
- The approver is never the preparer; the database enforces this, as well as the screens.
- No new SECURITY DEFINER function anywhere in Phase 5.

## 4. Tests (local data; Dev not touched)

| Check | Result |
|---|---|
| Database tests, new | 163: 57 · 164: 47 · 165: 31 · 166: 6 (all passing; each refusal checked for the right reason) |
| Full database suite | All files passing (see the final run in the chat report) |
| Round trips (preview, update x2, undo x2, schema identical, update again) | 163, 164, 165, 166 clean |
| Undo with data | 164 and 165 keep everything in their undo schema; updates re-run cleanly |
| Browser | 163: 50/50 · 164: 34/34 · 165: 20/20 · 166: 16/16 · earlier 162: 25/25 |
| Lint, typecheck, fresh-install build | Passing |

- **161 browser test: 31 of 33 tonight (33 of 33 earlier on 22 Nov).** It books a cancelled shift for
  "this Monday 9 am". Sydney time passed midnight into Monday during the run, so that time was in the
  future, and the database rightly refuses a "told on" time in the future. This is a timing issue in
  the old test, not a fault.
- There's no "npm test" script in this repo.

## 5. Decisions made during the build (for the owner to check)
1. The new link, version and review date are required for claims and invoices, not when verifying a rule. This keeps the Phase 4 steps unchanged.
2. A review date in the past also pauses billing line approval. It's an added rule; the Phase 4 code isn't edited.
3. One 161 test's exact list of Billing actions became "includes the original five".
4. The care management account rollover is a register item to verify, not calculated.
5. The NDIS 90-day claiming rule is unverified. The 30, 60 and 75-day alerts don't assume it.
6. Receipts list what was allocated when the receipt PDF is made; later allocations show on the payment page.
7. Shift billing lines still use the quarterly budget. The order of use with unspent HCP funds is a rule to verify.
8. Support at Home contributions on charges use the client's category rate. Contributions on AT-HM and pathways are a rule to verify.
9. Bank lines match on the exact amount: one bank line to one payment or refund.

## 6. Waiting on the owner (nothing claims or invoices on Dev until these are done)
- **Nominee (D2).** The nominee verifies all 27 register checks, each with its official link,
  version and review date:
  - 13 from update 161, 7 added in 163 and 7 in 165;
  - plus the Support at Home figures.
- **Official files.** The NDIA Bulk Upload template and the Services Australia claim format, as CSV.
  Upload them, check the column mapping and verify.
- **Business details** and the accountant's GST verification (D1).
- **The NDIS Support Catalogue (current release)** and each NDIS location's pricing zone.
- **CHSP, Private and Other rules.** They stay blocked (D-065).
- **Settings.** Markup rules, and the write-off threshold if it isn't $500.
- **Browser checks** on Dev after running 164 to 166.
