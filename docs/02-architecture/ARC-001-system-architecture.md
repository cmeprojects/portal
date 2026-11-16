# ARC-001: System Architecture

| Field | Value |
|---|---|
| Document ID | ARC-001 |
| Title | System Architecture |
| Category | 02 Architecture |
| Version | 0.1 |
| Status | **Draft** |
| Owner / Reviewer / Approver | Technical Lead / Technical Lead (peer if available) / Product Owner, role holders not yet assigned |
| Created | 16 Nov 2026 |
| Last reviewed | TBC |
| Next review | On significant feature change (GOV-001 §6) |
| Related | ARC-002 (Tenancy and Environments), DB-001, MOD-001, SEC-002, RSK-001, AUD-016 |

**How to read:** **Verified** = checked in the code or the database definitions
on 16 Nov 2026 (sources named). **Planned** = not built. **Assumption** =
not verified here.

## 1. Overview (verified)

One web application, the Staff Portal (also called the Staff and Care
Operations Portal), built with Next.js and hosted on Vercel, backed by
Supabase (Postgres database, authentication, file storage, scheduled jobs).
One codebase; **each customer gets its own Supabase project and its own Vercel
project** (ARC-002). The database enforces access itself through row level
security (RLS); the application checks roles and permissions on the server
as well.

```
Browser / phone (PWA) ──HTTPS──► Vercel: Next.js app (pages, server actions, /cron route)
                                    │  user's own session (RLS applies)
                                    │  service key only in named server code (bypasses RLS)
                                    ▼
                         Supabase project (one per customer)
                         • Postgres + RLS + functions + triggers
                         • Auth (email + password, optional TOTP)
                         • Storage (10 buckets)
                         • pg_cron + pg_net → calls /cron/due-alerts hourly
                                    │
              External: Anthropic API (Assistant), Resend (email, when configured)
```

## 2. Frontend and application structure (verified)

| Part | Where | What |
|---|---|---|
| Framework | `package.json` | Next.js 16 (App Router, Turbopack), React, TypeScript, Tailwind. Agent notice: this Next.js version differs from older documentation (AGENTS.md). |
| Signed-in portal | `src/app/(portal)/` | Dashboard, tasks, registers, records, people, onboarding, compliance, contracts, requests, forms, cars, built features (`/f`), reports, assistant, enquiries, settings, system, clients (`/settings/clients`). |
| Public pages | `src/app/login`, `auth`, `forgot-password`, `set-password`, `welcome`, `mfa`, `deactivated`, `ask`, `n` | Sign-in and account set-up; `/ask` is the public website assistant. |
| Staff phone app | `src/app/app/` | Installable app (manifest, PIN unlock, Cars, built features). |
| Cars app | `src/app/cars-app/` | Separate installable Cars app with PIN. |
| Scheduled job | `src/app/cron/due-alerts/route.ts` | Called hourly; checks `CRON_SECRET`. |
| Health | `src/app/health` | Public health check. |
| First check on every request | `src/proxy.ts` | Refreshes the session and sends signed-out visitors to sign-in. Public paths: /login, /auth, /forgot-password, /health, /cron, /robots.txt, /sitemap.xml, /ask. Role and two-factor checks are **not** here; they're on each page and in the database. |
| Server logic | `src/lib/*.ts`, `actions.ts` files | Server actions (form posts), data loading, permission helpers. |
| Shared components | `src/components/` | UI kit, sidebar, forms with busy state (`form-pending.tsx`), confirm dialogs. |

## 3. Backend and database services (verified)

- **Postgres (Supabase):** 93 tables in `public`, all with RLS on; 175
  policies on tables and 24 on file storage; 274 functions (227 SECURITY
  DEFINER, 37 of them triggers); 80 triggers (DB-001, SEC-002).
- **Database changes:** `supabase/migrations/` (107 files) for fresh
  installs; **live updates** `supabase/live-updates/update-NN.sql` with
  `undo-NN.sql`, run by the owner on each copy (QA-005).
  `supabase/install/fresh-install.sql` is built from the migrations
  (`scripts/build-install.py`); a test fails if it's out of date.
- **Storage buckets:** branding (public), avatars, compliance-files,
  compliance-library, staff-records, contracts, task-files, car-files,
  feature-files, form-files (private, with storage policies).
- **Scheduled work:** `supabase/setup/due-alerts-timer.sql` (pg_cron + pg_net,
  secret in Supabase Vault) calls `/cron/due-alerts` at five past each hour:
  due reminders, escalations, document expiry, car alerts, built-feature
  time alerts, request escalation, access-ending and onboarding reminders,
  then the email queue. Running on Dev (status 200, 15 Nov 2026); on other
  copies: **not verified**.

## 4. Authentication and authorisation (verified)

| Layer | Mechanism | Source |
|---|---|---|
| Sign-in | Supabase Auth, email and password; invite links; password reset | `src/app/login`, `src/lib/email/invite.ts` |
| Two-factor | TOTP, behind a system admin switch (`two_factor`); currently **off on Dev** by decision D-007; `mfa_ok()` is used in permission checks | `src/app/mfa`, `public.mfa_ok()` |
| Phone apps | Shared PIN lock, "stay signed in" days setting, wrong-PIN lockout | `src/lib/app-lock*.ts`, `car-pin.ts` |
| Page and action checks | `requireSession`, `requireRole`, `requireTaskAccess` on the server | `src/lib/session.ts` |
| Access levels | 7 fixed roles (`app_role` enum) plus job titles on top | `src/lib/roles.ts`, `job_titles` |
| Permission engine | `can(module, action, person)` with individual grants (allow/restrict, scope, dates), Manager Administrators, pass-on | `public.can()`, `access_grants`, `admin_designations`, `src/lib/module-access.ts` |
| Database enforcement | RLS on every table; SECURITY DEFINER functions for controlled actions; guard triggers | SEC-002 |
| Owner protection | Owner account can't be turned off, demoted, reset or signed out (update 74) | `profiles.is_owner`, `guard_owner` |
| Service key | `SUPABASE_SERVICE_ROLE_KEY` / `SUPABASE_SECRET_KEY`, **bypasses RLS**, used only in server code: cron route, sign-in, staff invites and deactivation, access and delegation actions, contracts, onboarding checks and reminders, email, assistant, avatars, re-authentication, car PIN, phone app manifest | `src/lib/supabase/admin.ts` and the 22 files that import `createAdminClient` |

**Limitation (verified):** about 180 access decisions are hard-coded by role
name in pages and RLS; the module permission engine covers onboarding, cars,
forms, reports, built features, enquiries, contracts, records and settings
areas (updates 69 to 78), not everything (MOD-001, AUD-016).

## 5. Hosting and deployment (verified from repository documents)

- **Vercel**: one project per copy; branch per copy: `dev` → Development,
  `main` → Demo, `release` → customers (docs/ENVIRONMENTS.md).
  `version-0.1.1` is a restore branch kept equal to `dev` by instruction.
- **Supabase**: one project per copy (Dev: `cme-dev`, Sydney region since
  11 Nov 2026).
- **Deploy**: Vercel builds on push. **Database updates are manual**
  (owner runs the SQL), not part of the deploy.
- **Restore**: code by branch; database by undo files (docs/RESTORE.md).
  **Database backups and a tested restore: not documented** (RSK-002).

## 6. External integrations (verified in code)

| Service | Used for | Data sent | Config |
|---|---|---|---|
| Supabase | Database, auth, storage, cron | All portal data | `NEXT_PUBLIC_SUPABASE_URL`, anon/publishable key, service key |
| Vercel | Hosting | All requests | Vercel project |
| Anthropic API | Portal Assistant and the public website assistant (`src/lib/assistant.ts`, `@anthropic-ai/sdk`) | Questions and the documents/pages used as context (exact content: **to verify** in ARC-003) | `ANTHROPIC_API_KEY`; Assistant feature switch |
| Resend | Email (invites, reminders, queue) | Recipient, subject, body | `RESEND_API_KEY` (local testing uses Mailpit); **not configured on Dev** (D-007) |
| GitHub | Code hosting | Code only | Repository `cmeprojects/portal` |

Libraries (13 direct dependencies): exceljs (Excel export), pdf-lib (signed
contract PDFs), mammoth and unpdf (reading uploaded documents for the
Assistant), qrcode, lucide-react (icons), Supabase SDKs, Anthropic SDK.
Licences: **not yet registered** (IP-002).

## 7. Environment separation (verified from docs/ENVIRONMENTS.md)

Development, Demo and customer copies are separate Supabase and Vercel
projects with their own keys and data. Copy label shown on non-customer
copies (`NEXT_PUBLIC_ENV_LABEL`). Company branding from
`supabase/companies/<name>.sql` and `public/companies/<name>/`.

## 8. Current customer database arrangement (verified)

**One database per customer.** Many tables have an `org_id` column
(default `default_org_id()`, one organisation row per database), but **no
RLS policy uses `org_id`** (checked: no policy condition mentions it).
Isolation between customers therefore depends entirely on separate projects
and keys. **Shared-database multi-tenancy is not implemented** (RSK-001).

## 9. Known limitations and gaps

| # | Gap | Evidence | Planned? |
|---|---|---|---|
| 1 | No shared-database tenant isolation; `org_id` unused in rules | §8 | Planned only if the SaaS model needs it (decision needed) |
| 2 | Database backup and restore not documented or tested | docs/RESTORE.md | Needed before live (OPS-001) |
| 3 | Hard-coded role checks (~180) alongside the permission engine | AUD-016 | Function-based model proposed (AUD-016), not approved |
| 4 | Fixed access levels; job titles carry no permissions | AUD-016 | Same |
| 5 | Service key used in 22 server files (bypasses RLS) | §4 | Review each use (RSK-008) |
| 6 | 227 SECURITY DEFINER functions, 50 executable by signed-out callers | SEC-002 appendix | Review (RSK-005) |
| 7 | Hourly timer set up on Dev only; email not configured | §3, D-007 | Before live |
| 8 | Release register behind (0.1.1 still covers updates 71 to 90) | docs/VERSIONS.md | Owner decision |
| 9 | Data flows to Anthropic not documented | §6 | ARC-003 |

## Sources

`package.json`; `src/proxy.ts`; `src/app/**`; `src/lib/session.ts`,
`roles.ts`, `modules.ts`, `module-access.ts`, `assistant.ts`, `email/*`,
`supabase/*`; `src/app/cron/due-alerts/route.ts`; `supabase/setup/*`;
`docs/ENVIRONMENTS.md`, `docs/RESTORE.md`, `docs/VERSIONS.md`; local
database catalogue (counts above), built from `supabase/migrations`
(updates to 90). Dev itself was **not** inspected directly.

## Change history

| Version | Date | Author | Change | Approved by |
|---|---|---|---|---|
| 0.1 | 16 Nov 2026 | Technical Lead (prepared by Claude) | First draft from code and database definitions | Not approved |
