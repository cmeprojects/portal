# Staff Portal

**Developed by cmeproject.** © cmeproject. All rights reserved.

A staff portal for small care and service businesses: tasks and registries,
approvals and reports, with vehicle logbooks to come. Staff sign in with any
email address, so nobody needs a Microsoft 365 account.

Each company runs its own copy, with its own database, website, branding and
wording. See **[docs/SETUP.md](docs/SETUP.md)** to set one up.

## What's in this version (Milestone 1: foundations)

- **Invite-only sign-in:** email and password, emailed sign-in link, or
  Google. Public sign-up is off.
- **Two-factor login** (authenticator app). System admins always need it;
  other roles are chosen in System settings (default: team leaders and up).
- **Roles:** support worker, team leader, manager, staff admin, system admin.
- **Staff & roles:** invite, change role or team, resend an invite,
  deactivate or reactivate. Deactivated people are blocked straight away and
  their history stays. System admins can reset someone's two-factor login.
- **Teams:** team leaders, and the support workers in each team.
- **Registries:** name, managers, and whether tasks need manager approval to
  close.
- **System settings** (system admins only): switch features on or off;
  change branding, wording and security settings.
- **Change log:** every change to people, roles and settings, which can
  never be edited or deleted.

## Who can do what

| Role | Can do |
|---|---|
| Support worker | Their own tasks: assigned to them, helping on, or created by them |
| Team leader | Their own tasks, plus the tasks of support workers in their team |
| Manager | Everything in the registries they manage: approvals, dashboard, reports |
| Staff admin | Invite people, set roles (up to manager), manage teams and registries |
| System admin | Everything, plus System settings, the change log and creating staff admins |

These rules are enforced by the **database** (Row Level Security), not just
hidden in the screens. A person with a role that needs two-factor login can
see nothing but their own profile until they've entered their code.

## How it's built

- **Next.js** (App Router, TypeScript) and **Tailwind CSS**
- **Supabase** for the database, sign-in, file storage and scheduled jobs.
  Hosted in Sydney.
- Standard Next.js only, so it runs on Vercel, Netlify, Cloudflare or any
  Node.js host. Nothing uses Vercel-only storage or jobs.

```
src/app/login, welcome, mfa, …   Sign-in pages
src/app/(portal)/                Pages after sign-in (menu, tasks, settings)
src/lib/                         Sign-in helpers, roles, branding
supabase/migrations/             Database tables and security rules
supabase/companies/              One set-up file per company
supabase/templates/              Email templates (invite, sign-in link, reset)
supabase/tests/                  Security rule tests
docs/SETUP.md                    Setting up a new company
```

## Running it on your computer

You need Node.js 22 and Docker.

```bash
npm install
npx supabase start            # local database, sign-in and test inbox
cp .env.example .env.local    # then paste the local keys it printed
npm run dev                   # http://localhost:3000
```

The local test inbox (to open invite emails) is at http://localhost:54324.
Create the first account in the local Supabase Studio or with the admin API;
the first account becomes the system admin.

## Checks

```bash
npm run lint
npm run typecheck
npm run build
npm run test:db      # security rule tests (needs a local Postgres: see scripts/test-db.sh)
```

The same checks run on GitHub for every push.
