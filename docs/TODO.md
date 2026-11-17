# To do (cmeprojects)

Staff Portal. Ideas and suggestions we've agreed to come back
to. When asked for a summary, include everything here.

Which live updates each copy has: see supabase/live-updates/README.md. Start with docs/HANDOVER.md.

**Documentation register (start here):** docs/00-governance/GOV-002-documentation-register.md lists every document with its ID, owner role, status and path; decisions are in docs/11-decisions-and-change-history/DEC-001-decision-register.md.

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
