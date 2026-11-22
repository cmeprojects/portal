# To do (cmeprojects)

Staff Portal. Ideas and suggestions we've agreed to come back
to. When asked for a summary, include everything here.

Which live updates each copy has: see supabase/live-updates/README.md. Start with docs/HANDOVER.md.

**Documentation register (start here):** docs/00-governance/GOV-002-documentation-register.md lists every document with its ID, owner role, status and path; decisions are in docs/11-decisions-and-change-history/DEC-001-decision-register.md.

## NEXT: programs, assessments and billing (owner, 21 Nov 2026)

Plan: docs/roadmap/programs-assessments-billing-plan.md (owner's consolidated recommendations).
Six phases: (1) programs offered by the organisation, more than one program per client, program
enrolments; (2) assessment templates and findings; (3) draft care plan, support plan and proposed
budget from assessments, each approved by a person; (4) billing foundations: rate tables, ledger,
billing lines, Billing permission, financial audit; (5) claims and invoices; (6) tie into rostering.
Before Phase 4, the billing guide corrections listed in the plan. Confirm the decisions table
before each phase. Phase 1 done (update 158). Phase 2 built (update 159): waiting for the owner's assessment-question
document to set up the real templates in Portal settings, Assessment templates (no rebuild needed). Phase 3 done (update 160): drafts from assessments with review and approval; run on Dev, browser-checked and approved 21 Nov 2026. Phase 4 plan approved in principle (D-063). 4A done (update 161, run on Dev and approved 22 Nov 2026). 4B done (update 162, run on Dev and approved 22 Nov 2026). Owner to check the full billing workflow on Dev later, after the nominated person confirms Support at Home rules and verifies its figures (D-065); CHSP and Other stay blocked. Phase 5 (claims, invoices, payments) only after approval. Owner to supply: confirmed CHSP, Private and Other billing rules; verified regulatory figures; the corrected billing guide. Open: Intake & Assessment Officers can prepare (not approve) proposed budgets through their existing Funding edit right; owner to decide if that should be view only. After undo, undo_160_kept is kept until the owner decides; recovery is manual. Out of Phase 1, for later: reminders for program end
and pause-return dates; full roster integration; closing services, agreements and budgets when a
client is discharged (the preview found open services on discharged clients); Funding and Agreement
forms listing open services only.

## Review later: Intake & Assessment Officer access to assessments (owner, 21 Nov 2026)

Update 159 gave "Assessments" the same access as care plans (owner's Option A): Intake & Assessment
Officers can view assessments for all clients but not start or change them. If the workflow needs it,
give them edit on "Assessments" on the Access page (no code change).

## LATER: rostering improvements from a reference screenshot (owner, 22 Nov 2026)

Not now. The owner shared a screenshot of another product's weekly schedule as ideas for our
roster. Build them in our own design (no copying of another product's look or wording), after
checking each against what the roster already does, and only once the owner asks for it.
- Week view by worker: each row shows the worker's phone, suburb, employment type, hours
  rostered this week, hours available, and a warning for unscheduled (contracted but not yet
  rostered) hours; "See breakdown" of their week.
- Shift cards: client, time and length, service; breaks shown as their own small blocks;
  leave (for example Annual Leave) shown greyed across the days it covers.
- Hover card on a shift: client, address (suburb, state, postcode), date, time and length.
- Menu on a shift: view details, duplicate, edit times, repeat, delete, and "auto-wrap visits"
  (fit back-to-back visits into one worker's block; to define).
- Menu on an empty day: add a one-off visit, add a recurring visit, add a shift, add a break,
  other items.
- Top bar: search by worker, filters, "sort by best match" (likely worker suitability for the
  client: availability, distance, skills, continuity), view options, today and week arrows.
- Ties in with Phase 6 (rostering picks the approved service and checks program, terms and
  funding) and the budget guard.

## LATER: address auto-complete (owner, 19 Nov 2026)

The owner wants every address (clients, houses, staff, contacts) to auto-complete and fill the
street, suburb, state and postcode into their own fields. Chosen: a built-in suburb list (no cost,
no outside service): typing the suburb suggests matches and fills the postcode and state. Parked
on the data source:
- ABS Suburbs and Localities + Postal Areas (CC BY 4.0, clean licence): abs.gov.au and data.gov.au
  are blocked in the build environment; the owner can supply the files or allow the host.
- Matthew Proctor's australianpostcodes list: downloadable, but states no licence (compiled from
  former Australia Post data), a risk if the portal is sold or shared.
- A paid street-level service (Google Places, Addressfinder, Geoscape) can come later.
Validation of typed addresses (lib/validate.ts) stays in place meanwhile.

## ON HOLD: Clients & Care and new roles (owner, 16 Nov 2026)

Paused by the owner; pick up from here when asked. Done and on Dev:
client steps 1 to 5 (updates 85 to 90: CL- references, status, programs,
locations, details and people, safety, services and readiness, profile page).

Waiting:
1. **New roles plan** (docs/roadmap/new-roles-plan.md): case manager, intake
   and assessment officer, payroll officer, rostering officer. Seven
   questions for the owner in the plan; nothing built.
2. **Then:** staff view of their clients; the six optional client sections
   (assessments and care plans, service agreements, funding and budgets,
   reviews, client documents, communication preferences) with switches;
   per-person access ticks for sensitive client parts; delegation of client
   setup by Manager Administrators.
3. **HR:** termination record (B4), then bank and super history (B5).
4. **Rostering:** first version (122) and round 2 (123, premium package) built. Later: use `client_readiness()` and `client_service_gaps()` in Suggest worker; Stage 6 (Allied Health access, update 124) built; waiting for the owner to run 124.

Owner's open checks: docs/review/TEMP-to-review.md.

**Access model (16 Nov 2026): Stage 1 assessment done, awaiting approval**:
docs/review/2026-11-16-function-access-assessment.md (Function Groups → job
titles → individual grants, one engine). If approved it replaces the
new-roles plan (roles become job titles in Function Groups, not new access
levels). Nothing built.

## Customise the portal (aim: as much control as WordPress)

All system admin only (or delegated), recorded in the change log, each with
"Reset to default". Any of them can be a premium switch.

1. **Pages**: make your own pages (headings, text, pictures, links, files,
   videos) such as Policies, Who to call, How-to guides, On-call roster.
   Choose who sees each one (roles or teams) and put it in the menu.
2. **Menu editor**: rename, reorder and hide menu items; add your own links
   (rostering system, policy folder).
3. **Wording everywhere**: one page with every label, searchable, e.g.
   Task → Job, Register → Log, Support worker → Carer.
4. **Email templates**: edit the subject and words of every email (invites,
   reminders, alerts, password resets), with logo, footer and a preview.
5. **Dashboard and home**: choose which boxes each role sees, add quick-link
   tiles, pin a page or form to the top.
6. **Sign-in page**: background picture, welcome message, contact details.
7. **Task settings**: rename task statuses and priorities, choose colours.
8. **Notifications**: per kind of event, choose bell, email, both or off, and
   who gets it.
9. **Look and feel**: fonts, rounded or square corners, compact or roomy.

Suggested order: Pages and Menu editor first (offer a clickable preview).

## Email

- **Resend set-up** so emails actually send (invites, password resets, form
  invites and reminders, feature alerts, weekly mileage report). Before
  switching on, give an SQL link to clear old queued emails first.
- **Email sign-in codes** as a choice alongside the authenticator app
  (System settings → Security). Needs Resend first. A bit less secure than the
  app; fine as the easier option.

## Feature builder

- **A rule that creates a task** from an entry (e.g. a refused drink creates a
  follow-up task).
- **Weekly summary** email of a feature (e.g. each client's week against
  their target).
- **Stickers with another answer already chosen**, not only the client (e.g.
  one Fridge temps sticker per fridge with that fridge ticked).

## Cars

- Optional: Face ID / fingerprint to unlock the apps instead of the PIN.
- Optional: push notifications on phones (car still out, alerts).

## Speed (after the build is finished)
- **Performance stages 2 to 9** (plan: docs/audit/2026-11-performance-plan.md).
  Stage 1 is done. The owner decided (13 Nov 2026) to do the rest once the
  build is finished, before going live.

## Small things

- Printed Tasks report: make the "Opened and completed by month" chart
  smaller when printed.

## Website and Assistant

Version 1 is built (live update 36, premium, off until switched on):
the public website at /ask (ask anything, answers from uploaded documents with
the source shown, "Would you like to talk to our team?"), /ask/get-started
(the new-customer enquiry form), a Sign in link to the portal, and in the
portal: Assistant (documents, wording, model, limits, questions asked) for the
system admin, Enquiries (stages from New to Became a client) for managers, and
an Open website link in the menu. Restore points: docs/RESTORE.md.

Version 2 (updates 37 to 39) added: the new landing page, chat history for
staff (kept until the tab closes for visitors), Website settings (landing
page, suggested questions, credits, front-page switch, where it looks per
group, listed websites, model and limits), reading scanned PDFs and photos,
who sees enquiries, follow-up tasks and Excel for enquiries.

Still to do (agreed, not built yet):

- **Enquiries register**: a new enquiry becomes a task for … (owner still deciding).
- **Get support** form: to be reworked with the enquiries register.
- **Compliance report for managers**: more ways to customise (ideas: saved
  views per manager, choose columns, schedule a weekly email, a team leader view).
- **A limit per visitor** (the hourly limit covers the whole website now).
- **Website pages and menu** (future): the system admin (or a delegate) adds pages such as Services, with photos and ready-made layouts, and chooses the menu.
- A free bot check (Cloudflare Turnstile) on Request a call back (see docs/AUDIT-2026-11.md).
- Test with about 20 real questions on Haiku, then decide whether to move to Sonnet.

## Later (owner, 17 Nov 2026)

- **More default access for Case Manager, Intake & Assessment Officer and Payroll & Rostering.** Decide once
  the HR block and the Care block are finished. Set on the Access page (role grants); no code change needed
  unless a new part is involved. Today: Case Manager has assigned clients only; Intake has every client and
  assigning; Payroll & Rostering has nothing extra.

- **Payroll & Rostering: staff onboarding view (owner chose it, 17 Nov 2026; held back).** The expiry list and onboarding
  overview read other staff's check records, which only people who manage onboarding (`can_manage_compliance`,
  hr.onboarding approve) may read. Giving Payroll the page needs a new read rule for those records (for example
  expiring items only, title and date, no files). Owner to decide; then add it as its own update.

## Audit trails: future development (owner, 20 Nov 2026)

The client audit trail (update 155) and the download trail (update 154) are done. Not built yet, by
the owner's brief:

- **Staff audit trail**, **rostering audit trail** and **system audit trail** (each in its own area).
- **A global audit console** (one place across all areas), **audit analytics or anomaly detection**, and
  **advanced audit reporting or exports**.
- **Audit retention automation** (how long entries are kept; links to SEC-004).
- **Confirmed downloads.** Today a document download is recorded as "download link issued" (a one-minute
  link). Confirming the file arrived would mean sending files through the portal itself; decide if needed.
- **Refused document attempts for other clients.** A refused attempt is linked to the client the link
  named; attempts with no client in the link show only under Portal settings, Downloads.
- **Allied Health and Team Leaders**: they don't see client audit trails by default. Give "Activity and
  audit trail" on the Access page if wanted.
- **Client incidents** are linked to their client and keep their own history (client_incident_events,
  shown on the incident). They are not in the client's Activity tab. Checked 20 Nov 2026: updates
  154-156 don't change incidents or who can see them. Adding incident activity to the client trail is
  future work.
