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
| Development | `dev` | the original project (engagedcare-portal, rename to `cme-dev`) | the Engaged Care look for now | test data only |
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
   → Run. Only ever on a brand-new, empty project.
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

## Keeping the install file current

After adding a migration: `bash scripts/build-install.sh`, then commit
`supabase/install/fresh-install.sql` with it.
