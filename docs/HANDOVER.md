# Handover: everything so far (cmeprojects)

Staff Portal · © cmeproject

Read this first in a new chat. It lists what has been built, how we work, what
has been agreed and what's next. Other docs in this folder go into more detail.

---

## 1. The product

- **Engaged Care Staff Portal**: a portal for a small NDIS provider in
  Melbourne (Engaged Care), plus a public website with an AI Assistant.
- Built and owned by **cmeprojects**.
- It's **SaaS** (cloud, single-tenant: one copy per client, each with its own
  Vercel project and Supabase project). Not an ERP: no accounts, payroll,
  rostering or billing.
- It sits **between** the tools Engaged Care already pays for (Microsoft 365,
  ShiftCare, QuickBooks) and covers the gaps: incidents, follow-ups, approvals,
  escalation, forms, cars, one audit trail.

**Live address:** https://engagedcare-cmeproject.vercel.app (sign-in `/login`,
website `/ask`). Changed from engagedcare-portal-beta.vercel.app; the owner was
given the steps to update `NEXT_PUBLIC_SITE_URL`, Supabase Site URL and
Redirect URLs, and the SEO website address.

## 2. Stack and hosting

| Part | What |
|---|---|
| Code | GitHub `cmeprojects/portal`, branch `main` (Vercel deploys from it) |
| App | Next.js 16 (App Router, `src/proxy.ts`, server actions), React 19, TypeScript, Tailwind 4 |
| Data | Supabase Pro, **Sydney**: Postgres with row-level security on every table, auth, storage, daily backups |
| Hosting | Vercel Pro, region syd1 |
| Email | Resend (not fully set up yet) |
| AI | Anthropic SDK v1.3: `claude-haiku-5-5` default, `claude-sonnet-5-5` optional; web search tool limited to listed sites |
| Running cost | About A$75 to A$90 a month |

Environment variables (set in Vercel only, never in chat or code):
`NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`,
`SUPABASE_SERVICE_ROLE_KEY`, `NEXT_PUBLIC_SITE_URL`, `RESEND_API_KEY`,
`EMAIL_FROM`, `CRON_SECRET`, `ANTHROPIC_API_KEY`.

Hosting notes worked out: Vercel Pro has unlimited projects (usage shared);
Supabase Pro is US$25 per organisation plus about US$10 compute per extra
project (8 GB database, 100 GB files). Free plans aren't fit for a business.
AWS or Azure hosting is possible (front end in 1 to 2 days, Supabase stays);
replacing Supabase is a 4 to 8 week rewrite and isn't recommended.

## 3. How we work (rules from the owner)

- Plain Australian English, AUD, `Australia/Sydney`; the owner is often on a phone.
- **Never** paste keys, secrets or passwords in chat; never ask for passwords.
  Test data only.
- **Never push to `angelice13/testing`.** Work in `cmeprojects/portal`.
- Commits as `cmeproject <344775769+cmeprojects@users.noreply.github.com>` with
  `-c commit.gpgsign=false`. Messages start with `cmeprojects:`. **No AI
  attribution anywhere** (the owner's rule).
- Code header: `// Staff Portal · © cmeproject. All rights reserved.` and
  `cmeprojects:` comments where they help.
- **Database changes:** a new file in `supabase/migrations/` (never edit an
  applied one), a matching `supabase/live-updates/update-NN.sql` that is
  **safe to run again**, an `undo-NN.sql`, and tests in
  `supabase/tests/*.test.sql`. **Give the owner only the GitHub link** to the
  update file, never the SQL in chat:
  `https://github.com/cmeprojects/portal/blob/main/supabase/live-updates/update-NN.sql`
- Before pushing: `npm run lint && npm run typecheck && npm run test:db`
  (and `npm run build` for bigger changes). There is no `npm test` script.
- DB tests need local Postgres: `PGHOST=/tmp/pgtest PGPORT=54329 PGUSER=postgres npm run test:db`.
- Restore point before every big change: branch `restore-update-NN` (tags
  can't be pushed through the proxy). See `docs/RESTORE.md`.
- Don't ask the owner to check things midway; do tasks that need them last.
- Business documents with **lowest prices** (internal) or a **named client's
  proposal** are **not committed** to the repo. They're sent to the owner as
  files. Ask the owner for copies if needed.
- AGENTS.md: this Next.js version differs from training data; read
  `node_modules/next/dist/docs/` before using new APIs. Run `npx next typegen`
  after adding routes.

## 4. Live database updates

Applied to Engaged Care: **updates 1 to 45** (46 and 47 are ready to run, in order) (see `supabase/live-updates/README.md`).
Recent ones: 36 website and Assistant, 37 quick fixes, 38 website v2, 39
limited tasks, 40 website round 2, 41 enquiry intake, 42 About and SEO, 43
demo data, 44 Reports and exports premium, 45 sign out other devices.

## 5. What's built

### Roles
New starter, support worker, team leader, manager, staff admin, system admin
(hidden, never given tasks). Job titles ("roles") link to an access level.
Delegation gives named managers areas: branding, messages, people rules,
compliance settings, task settings, report access, car settings, website,
change log.

### Core
- **Tasks:** priorities, statuses (Assigned, In progress, Escalated, Awaiting
  approval, Completed, Closed), due dates by business day (public holidays
  setting), reminders, daily manager summary, auto-escalation, manual escalation
  (support workers choose team leader or manager), approvals, helpers,
  comments, attachments, follow-up actions, reassign and take over, Staff
  questions, limited roles (General tasks and questions only), print.
  Task actions share one panel: one form open at a time; on success the form
  closes, one message shows and the buttons refresh.
- **Registers:** custom fields, required fields, approvals, managers,
  follow-up actions, Excel.
- **People:** invite any email, Staff page (name, role and teams save with one
  button, one person open at a time), conditional roles for new starters,
  approvals of staff admin changes, deactivate, reset link, 2FA reset, clear
  Cars PIN, sign out of all devices (system admin), Teams, Roles, Clients.
- **Dashboards**, bell, scoreboard (weekly and year to date), change log.
- Lists across the app open **one row at a time** (`<details name="…">`).

### Premium modules (Features switches)
Compliance and onboarding, Forms, Cars and Cars app, Staff app, Feature
builder features (e.g. Fluid intake), Website and Assistant (with Enquiries),
Reports and exports.

### Website and Assistant
Front page switch (proxy rewrites `/` to `/ask` for visitors), answers in
Markdown (summary, bullets, bold, sources "Further information can be found
in"), staff-only answers when signed in, "Contact your manager" Call button,
"Yes, call me" for visitors, recent chats, Raise a question, Request a call
back (AU phone and postcode checks) becoming an enquiry plus a Call back task
for intake roles due next business day, About page (delegable), SEO, documents
(Word, text, PDF, scanned PDFs read by the AI; Public, Staff only, Managers
only), model and limits, Test the AI connection.

### Security
2FA (roles chosen; system admin always), 5 wrong passwords lock 15 minutes,
idle sign-out, sign out my other devices / someone everywhere / everyone
(update 45, checked by `my_session_active()` at most once a minute in the
proxy), RLS on every table, security definer functions with `search_path=''`,
parameterised queries only, security headers (HSTS, frame DENY, nosniff,
referrer, permissions), no raw HTML in answers. Audit November 2026:
`docs/AUDIT-2026-11.md`.

### Other
System health, Demo data (load sample records, delete sample records, delete
every task), EC Apps page with QR codes.

## 6. Documents

In `docs/deliverables/` (client-safe): 01 setup guide, 02 user manual,
03 system admin manual, 04 briefer deck (opens with "You already know what
isn't working", ends with a one-week trial), 05 proposal, 06 pricing and
running costs, 07 security and privacy, 08 go-live plan, 09 service terms
(draft), 10 test plan, 11 test report, 14 pricing options (ways to pay),
15 pricing (simple, 2 pages), 16 why a standalone portal (1 page).
`docs/simulation/index.html` is a clickable demo.

Kept out of the repo: 12 and 13 (internal) and 17 (client proposal). Document
generators live in the chat's scratchpad only, so a new chat rebuilds
documents from these notes.

List prices (client-safe): setup A$4,500; Core A$390 a month (30 staff); add-ons
Compliance A$120, Forms A$80, Cars A$90, Staff app A$60, Feature builder A$40
each, Website and Assistant A$190, Reports A$50; Complete bundle A$790; Starter
A$290 (15 staff). One-time licence and instalment options are in document 14.

## 7. Sales status

Client-specific notes (the proposal, budget and negotiation) are kept outside
the repo. Ask the owner for the latest proposal document.

## 8. Settings and features revamp (built: update 46)

Restore point: branch `restore-update-45` (commit `8b8fad4`); database undo:
`supabase/live-updates/undo-46.sql`. Migration
`20261221000001_settings_revamp.sql`, tests `supabase/tests/settings_revamp.test.sql`.

How it's built:
- **Drafts:** table `settings_drafts` (kind setting | feature | delegation | website);
  `save_draft()`, `deploy_drafts()`, `discard_drafts()`. App: `src/lib/drafts.ts`,
  `src/app/(portal)/deploy-actions.ts`, `src/components/deploy-bar.tsx` (yellow
  bar, pop-ups), `src/components/use-dirty.ts` (greyed-out Save).
- **Feature parts:** `features.parent`; `feature_enabled()` needs the parent on.
  App rules in `src/lib/feature-parts.ts`; session features are parent-aware.
- **Delegation:** table `delegation_rules` (area, mode admin | managers | selected,
  people); `can_admin_area()` and `my_admin_areas()`. Registers and job titles
  follow the `registers` and `roles` areas (all managers by default).
- **Notifications:** setting `notify.channels` (only what's switched off);
  triggers on `notifications` and `email_outbox`; catalogue in
  `src/lib/notification-catalogue.ts`; computed bell items filtered in the layout.
- **Front page:** `website_front_page()` (setting and Assistant on).
- Settings page: `src/app/(portal)/system/page.tsx` (ROWS and GENERAL lists).

The agreed spec:

**Settings tabs:** Features, Notifications, Delegation, General (branding,
messages, security, tasks, people rules), Website settings (always shown to the
system admin), Change log, System health, Demo data.

**Save and deploy:** every settings Save is greyed out until something changes
and after saving; success shows green "✓ Saved. Not live yet". Saved changes
are drafts; **Deploy** (with a count and a summary) makes them live together;
**Discard** drops them. While drafts exist: a yellow bar on every page, a
pop-up when leaving Settings and after signing in. Delegated managers deploy
their own drafts; the system admin deploys everyone's. Content actions stay
instant (documents, demo data, sign-outs).

**Features tab:** one expandable row per feature (one open at a time) with its
parts, package presets (Essentials, Recommended, Everything, Custom), and
"Looked after by: … · Change" opening a pop-up.

| Feature | Rule |
|---|---|
| Tasks, Clients, Scoreboard | Always on |
| Registers | Always on; adding and setting up registers is delegable (system admin by default) |
| Built features and Cars | On or off each; managers can **manage** (not build) when delegated |
| Forms | Forms on/off; Form builder on/off. Builder on: managers and/or staff admins create and manage forms (chosen). Builder off: existing forms still work and staff fill them in from the Forms menu |
| Assistant | Website, Assistant and Enquiries together; off: sign-in page is the front page |
| People | Basics always on (invite, role, name, reset email, 2FA reset if 2FA on, Cars PIN if Cars on, sign out of all devices, deactivate); Teams and Roles can be switched off |
| Compliance | Parts on/off: read and confirm, trainings, uploads, forms in onboarding, each Compliance tab |
| Reports | On/off; each report follows its feature |
| My onboarding | Only when at least one compliance part is on; forms to fill appear there only when Forms is on and at least one compliance part is on |
| Notifications | Only for features that are on |

**Anything switched off stays usable and changeable by the system admin**
(e.g. the Roles page and adding job titles stay with the system admin even
when Roles is off), so others rely on the system admin for it.

Roles off: the role picker shows access levels only (support worker, team
leader, manager, staff admin); job titles are kept. Teams off: team leaders
work like support workers; teams are kept.

**Delegation tab:** per area: Only me / All managers / Selected managers and
staff admins. Areas: registers setup, built features (manage), cars, forms,
compliance, teams, roles, website and enquiries, report access, branding,
messages, task settings, change log. Security, Features, Notifications, Demo
data and General stay with the system admin.

**Notifications tab:** grouped by feature (expandable), Bell and Email switch
per notification, starting at today's behaviour.

## 8b. Round 3 (update 47)

Migration `20261222000001_round3.sql`, tests `supabase/tests/round3.test.sql`,
undo `supabase/live-updates/undo-47.sql`.

- **The system admin is never locked out by switches:** `feature_live()` is what's
  really on; `feature_enabled()` is true for the system admin except
  two_factor, email_notifications, auto_escalation. Session features in the app
  match. Notifications, onboarding parts, team leaders and the front page use
  `feature_live()`.
- **External contractor (allied health)** access level `external`: signs in,
  no permissions (`is_member()` is false), Home and My account only.
- **Who creates tasks per register:** `registries.create_roles` (empty: as before;
  the register's managers always can). Set on the register's Set up page.
- **Weekly mileage report:** settings `vehicles.weekly_day`, `weekly_hour`,
  `weekly_period` (last 7 days, last week Mon–Sun, last 14 days, month so far).
- **Sharing:** a delegated manager shares areas with staff admins
  (`delegation_shares`, `share_area()`); not Roles or the change log.
- **No active staff admin:** managers do Compliance (and see its report).
- App: bell keeps read notices for 30 days, unread bold and counted; menu has
  no Tasks item (tasks are on Home/Dashboard) except Tasks for the system admin
  (`/tasks`); Tools is its own menu group; the system admin's home is the
  platform dashboard (`platform-dashboard.tsx`); questions leave yourself out
  of "who looks after it"; Cars app settings sit with the Staff app.

## 9. Future plans

- **Client tracking for allied health** (next module): behaviour ABC charts,
  fluid, food, bowel, sleep, PRN medication log (alongside the pharmacy chart,
  never replacing it), charts, external therapist access by client.
- **Rostering link** (ShiftCare API on Premium/Enterprise plans; Deputy via
  OAuth): read shifts and staff; warn when someone with an expired check is
  rostered; My shifts; incidents linked to shifts.
- **Google Drive** attachments once they move to Google Workspace.
- Multi-tenant version later, for selling to many providers.
- Everything in `docs/TODO.md` (pages and menu editor, wording, email
  templates, Resend set-up, email sign-in codes, Turnstile on call-backs,
  per-visitor limits, feature builder rules, Face ID unlock, push
  notifications).
- Owner's to-dos: add `ANTHROPIC_API_KEY` in Vercel, finish Resend, run user
  acceptance testing, confirm the logout behaviour after the Supabase session
  settings (refresh token reuse 600 s; time-box, inactivity timeout and single
  session off; JWT expiry optionally 28800).
