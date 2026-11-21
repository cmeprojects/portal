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

**Phase 2: assessments. Built (update 159, 21 Nov 2026; preview-159.sql first).** Templates with versions
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

**Phase 3: drafts from assessments.** Rules-based first: findings → draft care plan, support plan
and proposed budget. Each draft: Draft → Pending review → Changes required → Approved →
Superseded, approved on its own, with its source assessment and version, who generated, changed,
reviewed and approved it, and earlier versions kept. The support plan is the provider's, never
shown as an NDIA or government plan. AI may later help word drafts, spot gaps and inconsistencies,
always traceable to the assessment and never approving anything.

**Phase 4: billing foundations.** Correct and finalise the billing guide (see below). Rate tables
(client prices, versioned, kept apart from worker pay rates; the same time boundaries for both).
Public holidays by state. Contribution calculations. Quarterly budget ledger (Support at Home):
opening balance, allocations, charges, contributions, claims, payments, adjustments; never an
overwritten balance. Billing lines from delivered services. Billing permission. Financial audit
(prices, rates, contributions, budgets, lines, approvals, exports).

**Phase 5: claims and invoices.** Program-specific claim workflows, invoices, suppliers and markup
rules, AT-HM accounts, payments and receipts, reconciliation, financial reports.

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
