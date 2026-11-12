# Outside review of the Staff Portal (cmeprojects)

How to let an outside reviewer (for example ChatGPT's agent) look around
the **Dev** portal safely, and what to ask it. Dev only, test data only.

## 1. Set up the reviewer account (you, about 10 minutes)

1. Check Dev has **test data only** (no real staff, TFN forms, IDs or contracts).
2. **Invite** a new person on Dev: name `Reviewer`, role **Manager**, using an
   email inbox you control (a Gmail "+" address works, for example
   `yourname+reviewer@gmail.com`).
3. Open the invite in a **private window**, set a password and finish setting
   up. Keep this password only for the reviewer.
4. **Staff → Reviewer → let them sign in without two-factor** (the agent can't
   receive codes). This shows in the change log.
5. **Access → Manager Administrators → nominate Reviewer**, with an end date
   **two days** away and the note `Outside review`.
6. **Access → Give or change access → Reviewer**: turn on each category
   **except** HR & workforce → Contracts and Staff records (leave those off),
   end date two days away. Don't tick "May pass this on".

Why a manager and not a system admin: a system admin can turn off or demote
other system admins (including you). A manager can't, and can't see System
settings, System health or the Feature builder (cmeprojects reviews those).

## 2. Give ChatGPT this (copy everything in the box)

```
You're reviewing a staff portal for a small Australian care business, built by
cmeprojects. It's a test copy with made-up data. Please look and report only.

Address: <the Dev portal address>
Email: <the reviewer email>
Password: <the reviewer password>

Rules:
- Look around every page you can open: menus, buttons, forms, reports, the
  bell, your account, and on a phone-sized screen too.
- You may type into forms to see how they behave, but don't press Delete,
  Remove, Deactivate, End, Suspend or Deploy, and don't upload files.
- Don't change your own password or two-factor settings.
- Stop and sign out when finished.

Report back, in plain Australian English, as a numbered list grouped by page:
1. Anything broken (errors, buttons that do nothing, pages that don't load).
2. Anything confusing (unclear words, too many steps, things hard to find).
3. Anything missing that a manager of a care business would expect
   (for example rostering, leave, timesheets, incident follow-up, training).
4. Your top 10 suggestions, most valuable first.
For each item: the page address, what you did, what happened, what you
expected.
```

## 3. Afterwards (you)

1. **Access → Reviewer → End** the nomination (removes their admin access).
2. **Staff → Reviewer → Deactivate**.
3. Change log → **Everything about this person** shows everything it did.
4. Send the report to cmeprojects; it gets merged with our own review.
