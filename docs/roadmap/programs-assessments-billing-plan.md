# Programs, assessments and billing: plan (cmeprojects, owner, 21 Nov 2026)

The owner's consolidated recommendations for NDIS, Support at Home, CHSP, Private and future
programs, added to our plan. Nothing here is built yet; each phase is its own update (or several),
with tests, an undo and a report, as usual. Dev only.

**The principle:** one client, more than one program enrolment, program-specific care and funding,
and billing that follows each service. Keep client identity, program enrolment, service approval,
funding and billing separate: they are linked, but not the same thing.

**The flow:** organisation's programs → client profile → program enrolments → assessments → care
plan / support plan / proposed budget (drafts, approved by people) → approved services → service
delivered → billing line → claim or invoice → reports.

## Where the portal is today (checked 21 Nov 2026)

What the brief assumes, against what is built. This decides where each phase starts.

| Brief says | Today | So |
|---|---|---|
| Choosing the program **or programs** when adding a client "should remain" | Adding a client chooses **one** "Funded by" scheme. A client gets other programs only through their services (each approved service is under a program). | Choosing more than one program when adding a client is **new** (Phase 1). |
| Program enrolments with their own dates, status and history | None. The client has one scheme (`car_clients.scheme`); programs are per service. | **New**: an enrolment record per client and program (Phase 1). "Funded by" becomes the main enrolment, not a rule for billing. |
| Organisation controls which programs are offered | Partly: Programs and schemes (Portal settings, Manager Administrators) and the five fixed schemes (NDIS, Support at Home, CHSP, Private, Other). No "this organisation offers only NDIS" switch. | Add a per-scheme on/off for the organisation; the client form shows only those (Phase 1). |
| Approved services linked to a program | Yes: each client service has a program; the service catalogue lists which programs it's offered under. | Reuse; add the link to the enrolment and funding arrangement (Phase 1). |
| Approved services and shift types kept separate, shifts limited to the service's shift types | Yes (update 143): catalogue entries and custom services carry shift types, and rostering checks them. | Already done; only add the program and funding check at rostering (Phase 6). |
| Service agreements and funding records | Yes, per service, with the scheme. Funding holds a total and an amount used for a period (no ledger, no invoicing). | Reuse; the ledger is new (Phase 4). |
| Assessments with templates | No assessment module. Assessments are uploaded documents (type "Assessment"); a care plan has an "assessed on" date. | **New** (Phase 2). The Forms builder (questions, required answers, versions) is the likely starting point rather than a second form engine. |
| Care plans | Yes: draft, current and archived, with goals and worker instructions, history kept. | Reuse as the target of generated drafts (Phase 3). |
| Support plan, proposed budget | No. | **New** (Phase 3). |
| Audit trail | Client audit trail (updates 155 to 157) covers client records, services, agreements, funding, care plans, documents, openings and downloads. | Reuse the same pattern for financial records (Phase 4). |
| Billing access | No billing permission; no finance role. | **New**: a "Billing" part on the Access page with separate view / change prices / approve / claim / export rights (Phase 4). |

## Decisions (owner's recommendations; confirm before each phase)

| Decision | Recommendation |
|---|---|
| Program choice when adding a client | Keep it required; allow more than one |
| Programs per client | More than one, one client profile |
| Programs offered | Set by the organisation; only those shown |
| Adding or ending a program later | Allowed; history kept, nothing deleted |
| Assessments, funding and agreements | Separate for each program; common details reused |
| Generated care plan / support plan | Draft, then reviewed and approved by an authorised person, each on its own |
| Generated budget | Proposed only; never treated as confirmed funding; approved separately |
| NDIS and Support at Home money rules | Separate logic for each |
| CHSP and Private | Their own billing treatment |
| Other | Configurable; never borrows another program's rules |
| What billing follows | Each approved service and its program and funding arrangement, not "Funded by" |
| Who sees billing | A configurable Billing permission (not a fixed Finance role; Payroll & Rostering doesn't get it automatically) |
| Public holidays | The state of the service location |
| Financial audit | Extend the existing audit trail |
| Government figures and deadlines | Checked against official sources, with an "as at" date, before building |

## Phases

**Phase 1: programs and enrolments. DONE: built (update 158), run on Dev and verified 21 Nov 2026 (15 enrolments, one main each, "Funded by" in step); approved by the owner.**
Built as approved: enrolments per **named program** (decision A); main promotion includes paused
enrolments (B); client shifts are checked against the program on the shift date, and a client shift
can't leave out its service (already required since update 130), internal shifts without a client
aren't checked, nothing historical is re-checked (C); open reviews are listed in the End dialog but
don't block (D); one database per customer kept, tested through role and direct-request boundaries
(E). Ending needs the person to see the client's services, agreements and budgets, so nothing open can
be hidden from the check. Not in Phase 1 (recorded): reminders for end and pause-return dates, full
roster integration, closing services when a client is discharged, Funding and Agreement forms listing
open services only.
Original scope: Organisation turns each scheme on or off. Client form: choose
one or more programs (required). Program enrolment record per client and program (status, start
and end, program identifiers such as NDIS number or My Aged Care ID). Link approved services,
agreements and funding to an enrolment; check a service is allowed under that enrolment. Existing
clients get an enrolment made from their current "Funded by" and their services' programs.
*Outcome:* an agreed data model, nothing rebuilt.

**Phase 2: assessments. DONE: built (update 159), run on Dev, verified and browser-checked 21 Nov 2026; approved by the owner.** Templates with versions
(published versions, their questions, options, rules and finding mappings never change; a new version is a
copy); client assessments that keep their exact version; draft -> completed (immutable) or cancelled with a
reason; corrections and reassessments are new assessments that supersede the old one (kept). Findings come
from mapped answers (no duplicates on re-save, one answer can make several, withdrawn not deleted, edited ones
flagged when their answer changes) and can be added by the assessor; fixed on completion; kept apart from
the answers with their source question and answer. Reused answers only where key and type match, marked with
their source, confirmed before completing. Two people on one draft: the later save is refused ("changed by
someone else"). Viewing recorded once an hour, printing every time. Access: "Assessments" (same defaults
and reach as care plans), templates by Manager Administrators and the care settings area; no support worker
or practitioner access. All checks in the database; no new SECURITY DEFINER function. Staff Forms unchanged
(the answer inputs are shared). The owner's real assessment-question document is configured later in the
template editor, with no rebuild. Not in Phase 2: care plan, support plan and budget generation (Phase 3),
reassessment reminders, practitioner access, assessment reports and exports, file and signature questions.
Original scope: Templates: common questions plus questions for each program, required
and optional, conditional questions, sections switched on or off, versions with effective dates
(a completed assessment keeps the version it used). Answers turned into structured findings
(needs, goals, risks, functional limits, supports, frequency, equipment, preferences). Owner's
separate assessment-question document to be reviewed first.

**Phase 3: drafts from assessments. DONE: built (update 160), run on Dev, browser-checked and approved by the owner 21 Nov 2026.** As approved
(sections 1 to 15 and the four template version-control safeguards): one-step generation from a completed
assessment's active findings (need -> needs; risk -> risks and safety; limitation, support, equipment -> care
requirements; intervention -> interventions; goal -> goals; preference -> preferences; support, intervention,
frequency, equipment, preference -> support plan lines; support, intervention, equipment lines -> budget lines
with hours and rates left blank), repeatable without duplicates or overwriting drafts. Care plans (extended),
support plans and proposed budgets each go Draft -> Pending review -> Changes required / Approved -> Superseded,
approved on their own by someone with the new "approve" right who didn't make or submit it. Source assessment,
template version and program enrolment kept on each document; items keep their finding. Agreement recorded
after approval and never changed, recording the client agreeing personally or a contact agreeing on their behalf
(role, relationship and authority kept as at that date). Budgets are estimates; funding that covers the whole
budget period is shown with its own balance (not prorated), partial overlaps shown but not counted; never funding. "Add to worker instructions" once per approved instruction item. Template sections in the change log;
version history and "what changed" on the template page. Not in Phase 3: notifications, AI wording, PDF export
of plans, withdrawing draft support plans and budgets, reassessment reminders.
Original scope: Rules-based first: findings → draft care plan, support plan
and proposed budget. Each draft: Draft → Pending review → Changes required → Approved →
Superseded, approved on its own, with its source assessment and version, who generated, changed,
reviewed and approved it, and earlier versions kept. The support plan is the provider's, never
shown as an NDIA or government plan. AI may later help word drafts, spot gaps and inconsistencies,
always traceable to the assessment and never approving anything.

**Phase 4: billing foundations. Plan approved in principle 21 Nov 2026; in two updates (4A set-up, 4B billing).**
Owner's corrections (binding): billing rate bands are set per price list, independent of payroll (the
calculation code may be shared); rounding (unit, nearest/up/down, minimum) is explicit and configurable per
price-list version; a manager's delivery override needs a reason and is audited (4B); a shift crossing rate
bands can give one legitimate line per band, never duplicates (4B: unique per shift, terms version and band);
CHSP, Private, Other and regulatory calculations stay off until their rules are confirmed (scheme rules
register; each listed figure verified with source and "as at" date); the Support at Home quarterly budget and
an append-only ledger stay traceable (4B); Billing permissions are separate from Funding; the ledger opening
balance goes through a controlled, approved step (4B); billing terms approval is separate from care plan and
funding approval.
4A (update 161), DONE: run on Dev, browser-checked and approved by the owner 22 Nov 2026: "Billing" access part (view,
prepare, approve, prices, export; default System Administrator and Manager Administrators only), scheme rules and verification register, versioned price
lists with their own rate bands (additions, edits and removals of draft prices and bands in the change log), rounding, minimum and band-crossing rule, public holidays by state, client
contribution rates (dated), billing terms for approved services (dated versions linked to the enrolment,
funding record, agreement, price list and support plan line; approved by Billing approve, not the preparer),
cancellation details (charge decided by Billing approve, with a reason). Nothing is calculated or billed.
Structure (owner, 22 Nov 2026): Billing is its own main menu module (dashboard, approvals, exceptions; billing
lines and exports from 4B), not part of the client page. Portal settings, Billing set-up: price lists, scheme
rules, verified figures, public holidays. The client page keeps only: Services (approved services and billing
terms), Funding (funding records and Support at Home contribution and budget information), Audit (the client's
billing history). Billing links to the client, service, agreement and funding records.
4B (update 162), DONE: run on Dev 22 Nov 2026 and approved by the owner (full billing workflow check on Dev to follow, once the nominated person has confirmed rules and verified figures): billing lines from delivered shifts
(approved timesheet and service record, or a delivery decision with a reason) and chargeable cancellations, under the
service's approved terms on the date, the price list version in force, its own bands (holidays of the location's
state), rounding, minimum and band rule; one line per band, never duplicated; a full snapshot and the working kept
on each line; Draft -> Approved by someone other than the maker (over-budget lines need a note); void with a reason
code and remake (the corrected line points to the original). Calculations only for confirmed schemes; Support at
Home figures (care management %, rollover floor and %) verified with source and "as at". Support at Home quarter
budgets per enrolment (pro rata, care management, carryover in and out, lapse), made and approved by different
people, closed once. Append-only funding ledger: charges and reversals from lines, carryover and lapse from a
quarter close, opening balances and adjustments proposed and approved by someone else; funding records untouched.
Exceptions listed with reasons; CSV export of approved lines (recorded in the download trail). Billing module tabs:
Dashboard, Billing lines, Exceptions, Budgets and ledger, Export; the client's Funding tab shows the budget and
ledger read only. Not in 4B: claims, invoices, statements, payments, reconciliation, supplier invoices and markup,
AT-HM and pathway accounts, unspent HCP funds, the NDIS catalogue import (Phase 5); roster budget guard (Phase 6).
Original scope: Correct and finalise the billing guide (see below). Rate tables
(client prices, versioned, kept apart from worker pay rates; the same time boundaries for both).
Public holidays by state. Contribution calculations. Quarterly budget ledger (Support at Home):
opening balance, allocations, charges, contributions, claims, payments, adjustments; never an
overwritten balance. Billing lines from delivered services. Billing permission. Financial audit
(prices, rates, contributions, budgets, lines, approvals, exports).

**Phase 5: claims, invoices, payments. Final plan approved by the owner 22 Nov 2026 (D-066). Built one
stage at a time (preview, deployment, tests, approval each). 5A built (update 163), waiting for the owner's
preview results and approval; 5B not started.**
- 5A Claims and client invoices, with the NDIS catalogue foundation and price-limit validation;
  business details (setup wizard and Portal settings) and payers; claim lines locked once claimed
  or invoiced (an additive rule, Phase 4 not reopened). Built with the compliance additions (D-067):
  official link, document version, effective date and "review by" on every rule, figure, claim
  template and NDIS catalogue (claims, invoices and line approval pause past a review date);
  official claim templates uploaded and verified (header row kept exactly, CSV, date format, file
  name limit); NDIS catalogue imported per release, price limits by support date and the delivery
  location's zone, snapshotted; Support at Home care management claimed once per quarter as
  clinical (no contribution) and shown in its own account; fee reduction supplements per client;
  monthly Support at Home statements.
- 5B Claim results (partial acceptance and rejection tracked separately), payments, receipts,
  credit notes, adjustments, refunds, write-offs (threshold $500, second approver above it),
  reconciliation.
- 5C Supplier invoices (costs kept apart from client revenue; never create a client charge by
  themselves), markup, AT-HM, Restorative Care and End-of-Life pathways, unspent HCP funds.
- 5D Consolidated financial reporting and cross-module integration (each stage brings its own
  operational reports first).
Rules: no double recovery (checked at billing line, payer and amount); multiple batches,
amendments and replacements linked to their originals; accepted amounts never resubmitted;
Support at Home full value, client contribution, government amount, claim amount and actual
payment kept distinct; NDIS pricing zone from the service delivery location and the pricing
version, kept in the snapshot; snapshots of prices, funding, client, payer and business details
and issued documents; duplicate checks on claims, invoices and imports; ordinary invoices vs tax
invoices from the verified GST status and line GST codes (accountant verification required);
separate permissions for prepare, approve, submit (claims and invoices), payments, reconcile,
refund and write-off; preparer differs from approver; approver may also submit with the submit
right. Both Support at Home and NDIS designed; neither enabled for real claims until its rules
and official formats are verified by the owner's nominee. PDF invoices downloaded or printed and
marked issued or sent; email later.
Manual government claim submission is mandatory (D-066): the portal prepares and validates the
file in the verified official format; an authorised person downloads it, uploads it in the
official portal, and records the submission (who, date and time, channel, external reference,
acknowledgement); only that record makes a claim "Submitted"; generating or downloading never
does. No direct API submission or automatic portal integration in Phase 5 (TODO: future optional
integration).

**Phase 6: tie it together.** Rostering picks the client's approved service and checks program and
funding; delivered shifts (not rostered ones) become billing lines after checks; budget checks
before billing; exception lists; dashboards.

## Billing guide corrections (before Phase 4)

From the review of "Care Portal: Complete Guide" (20 Nov 2026):
- Worked example: cleaning 2 h × $80 = $160 at 17.5% → client pays **$28**, $160 off the budget;
  personal care 1 h × $75 at 0% → client pays **$0**, $75 off the budget. Show opening balance,
  deductions, contribution and remaining balance.
- Claim deadline: settle "60 days after the quarter" versus "60 days after exit" from the official rule.
- Public holidays: by the service location's state (not Victoria, not the portal's time zone).
- NDIS short-notice cancellation ("7 clear days"): mark as to be confirmed.
- Support at Home figures to check: rollover cap ($1,000 or 10%), personal care from 1 Oct 2026,
  lifetime cap indexing dates, 28-day budget note for new providers. Add "As at" and "Checked by".
- Numbered steps restart at 1 in the Word file; private claude.ai links to remove; shared-core list repeated.

## Rules that always apply

One identity per client; enrolments with their own dates and status; history kept; every approved
service linked to a program and funding arrangement; no billing under a program not allowed for
that service and client; generated documents stay drafts until approved; proposed budgets aren't
funding; price, contribution and budget changes audited; financial approvals by authorised people;
access enforced in the database (RLS), not just hidden screens; approved records versioned, never
overwritten; new programs don't inherit another program's rules; regulatory figures tied to their
effective dates.
