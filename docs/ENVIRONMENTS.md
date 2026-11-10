# Copies of the portal (cmeprojects)

Staff Portal · © cmeproject

One codebase, many copies. Every copy runs the same code with its **own
database**, so no copy can ever see another's data. You (cmeprojects) are the
system admin on every copy.

## Naming

| Thing | Pattern | Examples |
|---|---|---|
| Code | one GitHub repository | `cmeprojects/portal` |
| Branches | what each copy follows | `dev` (Development), `main` (Demo), `release` (clients) |
| Supabase organisations | who pays | `cmeprojects-internal` (Free: Development, Demo), `cmeprojects-clients` (Pro: clients) |
| Supabase projects | `cme-<copy>` or `client-<name>` | `cme-dev`, `cme-demo`, `client-engagedcare` |
| Vercel projects (one Vercel account) | same as the Supabase project | `cme-dev`, `cme-demo`, `client-engagedcare` |
| Company files | `supabase/companies/<name>.sql` | `cmeprojects.sql`, `engaged-care.sql` |
| Logos | `public/companies/<name>/` | `public/companies/cmeprojects/` |
| Copy label (not on client copies) | `NEXT_PUBLIC_ENV_LABEL` | `DEVELOPMENT`, `DEMO` |

## The copies

| Copy | Branch | Supabase / Vercel project | Branding | Data |
|---|---|---|---|---|
| Development | `dev` | `cme-dev` (the original project, renamed) | the Engaged Care look for now | test data only |
| Demo (and backup) | `main` | the copy made from the fresh install (`cme-demo`) | </>cmeprojects | sample data only |
| Engaged Care (when ready) | `release` | a new `client-engagedcare` project (Pro), fresh install + `supabase/companies/engaged-care.sql` | Engaged Care | real |
| New clients | `release` | `client-<name>` (Pro) | theirs | real |

Development keeps the Engaged Care colours and logo while it's being built.
When Engaged Care is ready to go live, their company copy is made fresh (it
never shares Development's database), and Development switches to the
</>cmeprojects look.

The **reproduction copy is the code**: `supabase/install/fresh-install.sql`
rebuilds an empty database at any time (tested on every build).

## Flow of changes

1. Build and try on **Development** (`dev`).
2. Merge `dev` into `main`: the **Demo** updates by itself.
3. Run any new live update on each client database **first**, then merge
   `main` into `release`: every client's portal updates by itself.

Code goes out automatically when you merge. Database updates are run per copy
(later: one button in the Control Centre).

## Setting up a new copy (Development, Demo or a client)

1. **Supabase**: New project in the right organisation, region **Sydney**, a
   strong database password (keep it in your password manager).
2. **Database**: SQL Editor → New query → paste all of
   `supabase/install/fresh-install.sql` (open it on GitHub, **Copy raw file**)
   → Run. Safe to run again: on a copy already in use it adds only what's missing.
3. **Company file**: same way, `supabase/companies/<name>.sql`
   (`cmeprojects.sql` for Development and Demo).
4. **Supabase settings**: Authentication → Sign In / Providers: turn **off**
   "Allow new users to sign up". Authentication → URL Configuration: Site URL
   = the copy's address; add `<address>/**` to Redirect URLs.
5. **Vercel**: Add New → Project → import `cmeprojects/portal`. Name it as in
   the table. Settings → Git → Production Branch = the copy's branch.
6. **Vercel environment variables** (Settings → Environment Variables), from
   the new Supabase project (Project Settings → API): `NEXT_PUBLIC_SUPABASE_URL`,
   `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`,
   `NEXT_PUBLIC_SITE_URL` (the copy's address), `CRON_SECRET` (a new random
   string), and for Development/Demo `NEXT_PUBLIC_ENV_LABEL`. Emails
   (`RESEND_API_KEY`, `EMAIL_FROM`) and the AI (`ANTHROPIC_API_KEY`) can wait.
   Never paste keys in chat.
7. **Deploy**, then **your system admin account**: Supabase → Authentication →
   Users → Add user → your email and a password, tick "Auto confirm". The
   first person in a new copy becomes its **system admin**. Sign in at
   `<address>/login` and set up two-factor login.

## Check every copy after setting it up (cmeprojects)

The one setting that's easy to miss: Vercel only shows a branch at the copy's
address if it's that project's **Production branch**. Otherwise pushes become
"Preview" builds at a different address, and the copy looks unchanged.

| Copy | Vercel project | Production branch | `NEXT_PUBLIC_ENV_LABEL` | Variables ticked for |
|---|---|---|---|---|
| Development | `cme-dev` | `dev` | `DEVELOPMENT` | Production and Preview |
| Demo | `cme-demo` | `main` | `DEMO` | Production and Preview |
| Each client | `client-<name>` | `release` | not set | Production |

After setting up or changing a copy:

1. Open the copy and sign in as the system admin. Under your name, at the
   bottom of the menu, check the **branch · version** line. It must name the
   branch in the table (for example `dev · e32cf4b`).
2. Development and Demo show the amber label bar, on the sign-in page too.
   Clients don't.
3. Vercel → Deployments: the top one is marked **Production** and **Ready**.
4. If something looks unchanged: Deployments → ⋯ → Redeploy, with **Use
   existing Build Cache** unticked, then refresh the page (Ctrl+Shift+R).

Changes flow `dev` → `main` → `release`. A client only gets a change when
`main` is merged into `release`, and the Demo only when `dev` is merged into
`main`. Nothing reaches a client by accident.

## Where each key comes from (if you forget)

Vercel hides saved values (the padlock): that's normal, and nobody can read
them back, you included. Every key can be found again or replaced:

| Key | Where to get it again | If you lose it |
|---|---|---|
| `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase → that copy's project → Project Settings → API | Copy it again |
| `SUPABASE_SERVICE_ROLE_KEY` | Same page (service_role / secret key) | Copy it again. If it may have leaked, rotate it there, then update Vercel |
| `CRON_SECRET` | Nowhere: it's a random password you made up | Make a new one, paste it in Vercel, redeploy |
| `ANTHROPIC_API_KEY` | console.anthropic.com → API keys (shown only once) | Create a new key, paste it in Vercel, delete the old one |
| `RESEND_API_KEY` | resend.com → API keys (shown only once) | Create a new key, paste it in Vercel, delete the old one |

Keep one password-manager entry per copy (for example "Staff Portal: cme-dev")
with its database password and these keys. After changing any value in
Vercel, redeploy.

## Logs in each copy

- **Change log** (Settings → Change log) lives in each copy's own database. A
  new client starts from a fresh install, so its change log starts empty:
  nothing to clear, and Development's history never goes to a client.
- **Deployment history** stays in each Vercel project (Deployments).
- **Database updates run** are recorded per copy in
  `supabase/live-updates/README.md`.

## Keeping the install file current

After adding a migration: `bash scripts/build-install.sh`, then commit
`supabase/install/fresh-install.sql` with it.
