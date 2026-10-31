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

## Website and Assistant ("Engaged Care Assistant")

Version 1 is built (live update 36, premium, off until switched on):
the public website at /ask (ask anything, answers from uploaded documents with
the source shown, "Would you like to talk to our team?"), /ask/get-started
(the new-customer enquiry form), a Sign in link to the portal, and in the
portal: Assistant (documents, wording, model, limits, questions asked) for the
system admin, Enquiries (stages from New to Became a client) for managers, and
an Open website link in the menu. Restore points: docs/RESTORE.md.

Still to do (agreed, not built yet):

- **Search options per group** (documents only / web only / both, e.g. Public:
  documents only, Staff: both), a trusted-websites list, and "From the web"
  labels. Version 1 answers from documents only.
- **Follow-up questions** that remember the chat (each question stands alone now).
- **A limit per visitor** (now the hourly limit covers the whole website).
- **Make a task** from an enquiry, Excel/print of enquiries, an email alert
  when an enquiry arrives (needs Resend), and a "where enquiries come from" summary.
- **Website as the front page** (open the domain to the website, with the portal
  behind Sign in), more website pages (services, about), SEO details.
- **Scanned PDFs** (pictures of pages) can't be read yet; paste the words in.
- Test with about 20 real questions on Haiku, then decide whether to move to Sonnet.
