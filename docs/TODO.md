# To do (cmeprojects)

Staff Portal for Engaged Care. Ideas and suggestions we've agreed to come back
to. When asked for a summary, include everything here.

Live database updates applied to Engaged Care: 1 to 35.

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

## Small things

- Printed Tasks report: make the "Opened and completed by month" chart
  smaller when printed.

## AI help chat ("Engaged Care Assistant") — discussed, not building yet

A ChatGPT/Claude-style page: anyone types a question and gets answers from
documents we upload (NDIS, NDIS policy, company policy, public policy).
Earlier mockups: Home, Answer with sources, Admin library.

Agreed so far:

- **Admin library**: upload PDFs and Word files, tag each one Public, Staff
  only or Managers only. Visitors use the chat without signing in; staff sign
  in with their portal account and see more.
- **Search options** (system admin chooses): Our documents only, Web only,
  or Both (documents first, the web only when they don't cover it).
  - A choice per group (e.g. Public: documents only; Staff: both).
  - Web search limited to trusted sites the admin lists (ndis.gov.au,
    ndiscommission.gov.au, legislation.gov.au).
  - Every answer labelled "From our documents" or "From the web", with sources.
- **AI model**: start with Claude Haiku (cheapest). The model is a setting in
  System settings so we can switch to Sonnet later without a rebuild.
- **Costs**: pay per question, no monthly fee. Rough guide in US dollars:
  Haiku under US$1 for 1,000 questions; Sonnet about US$12 for 1,000; a web
  search adds about US$10 per 1,000 searches plus reading the pages (check
  current prices before building).
- **Monthly spending limit** in settings (e.g. A$50); the chat pauses and
  says "please contact us" when it's reached.
- **Safety**: "not official NDIS advice" note, a contact-us button, no client
  personal details in the public chat, limits against spam, a log of
  questions (shows gaps in our documents).
- Data stays in Australia (Supabase Sydney) for the documents and search.
