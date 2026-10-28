# Setting up a portal for a company

Staff Portal · © cmeproject

Each company gets **its own copy** of the portal: its own Supabase project
(database, sign-in, files) and its own website. They all run the **same
code** from this repository, so a fix or new feature reaches every company.
One company's data can never be seen by another.

```
          one GitHub repository (this code)
                 │                 │
     ┌───────────┘                 └───────────┐
 Website for Company A                Website for Company B
 (Vercel, its own settings)           (Vercel, its own settings)
     │                                         │
 Supabase project A (Sydney)          Supabase project B (Sydney)
 its own database, logins, files      its own database, logins, files
```

Setting up a new company takes about 30–45 minutes. You need:

- a Supabase account (supabase.com)
- a Vercel account, or another host that runs Next.js
- the company's name, logo and colours
- optional: a Google Cloud account for "Continue with Google"
- optional: an email sending service (Resend) so emails come from the company

---

## 1. Create the Supabase project

1. Go to **supabase.com** → **New project**.
2. **Name:** for example `engagedcare-portal`.
3. **Region:** **Sydney (ap-southeast-2)** so the data stays in Australia.
4. **Database password:** make a long one and keep it in a password manager.
5. Wait for the project to finish setting up.

## 2. Create the tables and security rules

Pick **one** way:

**A. With the SQL Editor (no tools needed)**

1. In Supabase, open **SQL Editor** → **New query**.
2. Open each file in `supabase/migrations/` in order (oldest first), paste
   it all in and click **Run**.
3. Make a copy of `supabase/companies/engaged-care.sql` for the new company
   (for example `supabase/companies/acme.sql`), change the name, colours and
   registries, then paste it in and click **Run**.

**B. With the Supabase command line (best for updates later)**

```bash
npx supabase login
npx supabase link --project-ref <your-project-ref>
npx supabase db push                       # creates tables and rules
# then run the company file in the SQL Editor (step A.3)
```

The project ref is the part of the project address before `.supabase.co`.

## 3. Sign-in settings

In Supabase, open **Authentication**:

1. **Sign In / Providers**
   - Turn **off** "Allow new users to sign up". The portal is invite-only.
   - Keep the **Email** provider **on**. Turning it off stops all email
     and password sign-in.
   - Under Email, set **Email OTP Expiration** to `86400` (24 hours, the
     longest Supabase allows). Invite links last this long; a staff admin
     can resend an invite after that.
   - Set the **minimum password length** to `10`.
2. **Multi-Factor:** make sure **TOTP (authenticator app)** is enabled.
3. **URL Configuration**
   - **Site URL:** the portal's web address, for example
     `https://engagedcare.cmeproject.com` (use `http://localhost:3000`
     until it's live).
   - **Redirect URLs:** add `https://<portal address>/**` and
     `http://localhost:3000/**`.
4. **Emails → Templates:** replace these 3 templates with the ones in
   `supabase/templates/` so their links open the portal correctly:
   - **Invite user** → `invite.html`
   - **Magic link** → `magic_link.html`
   - **Reset password** → `recovery.html`
5. **Emails → SMTP settings:** Supabase's built-in email is only for
   testing. It sends a few emails an hour and **only to people on your
   Supabase team**. Before inviting real staff, add an email service such
   as Resend here, with the company's "from" address.

## 4. Google sign-in (optional)

1. In **Google Cloud Console** → APIs & Services → Credentials, create an
   **OAuth client ID** (type: Web application).
2. **Authorised redirect URI:**
   `https://<your-project-ref>.supabase.co/auth/v1/callback`
3. In Supabase → Authentication → Sign In / Providers → **Google**, turn it
   on and paste the client ID and secret.

Staff can only use Google with the **same email they were invited with**.
If you skip this step, switch **Google sign-in** off in the portal's System
settings so the button doesn't show.

## 5. Keys for the website

In Supabase → **Project Settings → API Keys** copy:

| Setting in the website | Where to find it |
|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | Project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Publishable key (or the legacy "anon" key) |
| `SUPABASE_SERVICE_ROLE_KEY` | Secret key (or the legacy "service_role" key). **Keep this private.** |
| `NEXT_PUBLIC_SITE_URL` | The portal's web address |
| `RESEND_API_KEY` | resend.com → API Keys (task emails). **Keep this private.** |
| `EMAIL_FROM` | Who task emails come from, for example `Engaged Care <tasks@engagedcare.com.au>`. The domain must be verified in Resend. |

Until `RESEND_API_KEY` is set, task emails wait in a queue and nothing is
lost; they're sent once it's added.

Never put these keys in the code, in GitHub or in a chat. They go in the
website's environment variables (step 6) or in `.env.local` on your own
computer, which is never committed.

## 6. Put the website online (Vercel)

1. On **vercel.com** → **Add New → Project** → import this GitHub repository.
2. **Environment Variables:** add the settings from step 5.
3. Click **Deploy**.
4. **Settings → Domains:** add the company's address, for example
   `engagedcare.cmeproject.com` or `portal.engagedcare.com.au`.
5. Put that address in Supabase's Site URL and Redirect URLs (step 3.3), and
   in `NEXT_PUBLIC_SITE_URL`, then redeploy.

Vercel's free Hobby plan is for personal, non-commercial use only. When a
company starts using the portal for real, move to Vercel Pro, or another
host such as Netlify or Cloudflare Pages. Nothing in the code is tied to
Vercel.

For a second company, import the **same repository** again as a new Vercel
project with that company's keys.

## 7. Make yourself the system admin

1. In Supabase → **Authentication → Users → Add user → Create new user**,
   enter your own email and a password, and tick **Auto Confirm User**.
2. The very first account in a new portal automatically becomes its
   **system admin**.
3. Sign in to the portal. You'll be asked to set up two-factor login with an
   authenticator app.
4. Go to **System settings** to check the company name, logo and colours,
   then **Staff & roles** to invite the company's staff admin and staff.

## 8. Logo

Save the company's logo in `public/` (for example `public/logo.png`), deploy,
then set **System settings → Branding → Logo** to `/logo.png`. A logo can
also be any web address that serves an image.

---

## Updating every company

1. Push the change to GitHub. Each company's website rebuilds by itself.
2. If the change includes a new file in `supabase/migrations/`, apply it to
   **each** company's database:

   ```bash
   npx supabase link --project-ref <company A ref> && npx supabase db push
   npx supabase link --project-ref <company B ref> && npx supabase db push
   ```

Always apply database changes before, or at the same time as, the website
update.

## Before a company goes live

- Upgrade its Supabase project to **Pro** (daily backups, no pausing).
- Use a real email service (step 3.5) with the company's domain.
- Move the Vercel project to a commercial plan.
- Agree how long records are kept (System settings → Records).
- Load real data only after management has approved going live.

## Due date alerts (hourly timer)

Reminders, overdue alerts, automatic escalation and the managers' morning
summary run from a timer inside Supabase (pg_cron), so nothing depends on the
host.

1. Open `supabase/setup/due-alerts-timer.sql`, check the web address near the
   top, and run it in the Supabase SQL Editor.
2. It shows a `CRON_SECRET` once. Add it in Vercel → Settings → Environment
   Variables as `CRON_SECRET`, then redeploy. Don't paste it anywhere else.
3. The timer calls `/cron/due-alerts` at five past every hour. Managers change
   the reminder, escalation and summary settings on Due dates (SLA).

Rules: a reminder the day before (to the person), on the due date (them and
helpers), overdue (them and their team leaders, or managers if there's no
leader), and after 3 days overdue the managers are told and the task is marked
escalated. Reminders and due today show in the bell only; emails go out only when a task is overdue or escalated. Each step is sent once per due date. Managers get one summary email
each weekday from 7am. With "weekdays only" on, nothing is sent at weekends.

## Onboarding and Compliance

- Invites: with email sending set up (Resend), the portal sends its own
  branded welcome invite with the company logo. Until then Supabase sends the
  invite: paste `supabase/templates/invite.html` into Supabase →
  Authentication → Email Templates → Invite user.
- New people join as new starters and see **My onboarding**. Staff admins (and
  any roles the system admin adds under System settings → Compliance) manage
  documents to read, trainings and uploads on the **Compliance** page.
  Managers and team leaders see progress only.
- A new starter gets a role once onboarding is finished, or earlier as a
  conditional role (reason and deadline; staff admins need a manager's
  approval). They then get a "Finish onboarding" task due on the deadline,
  which completes itself when they finish.
- Uploaded files are stored privately in Supabase Storage (buckets
  `compliance-files` and `compliance-library`).
