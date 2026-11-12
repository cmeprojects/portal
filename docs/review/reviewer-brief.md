# Outside review of the Staff Portal (cmeprojects)

How to let an outside reviewer (for example ChatGPT's agent) look around
the **Dev** portal safely, and what to ask it. Dev only, test data only.

## 1. Set up the reviewer account (you, about 10 minutes)

1. Run **live update 74** first (the owner protection). Its last line should
   show **your** name: you're the owner. No other system admin can then turn
   you off, change your role, name or email, reset your two-factor or
   password, or sign you out ("Sign out everyone" leaves you signed in).
2. Check Dev has **test data only** (no real staff, TFN forms, IDs or contracts).
3. **Invite** a new person on Dev: name `Reviewer`, role **System admin**, using
   an email inbox you control (a Gmail "+" address works, for example
   `yourname+reviewer@gmail.com`).
4. Open the invite in a **private window**, set a password, and set up
   two-factor with **your** phone's authenticator app (name the entry
   "Reviewer"). System admins always need two-factor; that stays on.
5. When ChatGPT's agent reaches the six-digit code screen, use **Take over**
   in ChatGPT and type the code from your phone yourself, then hand back.
   Never give ChatGPT the code's setup key or QR code.

The reviewer can see and use every page, including System settings, System
health and the Feature builder. It can still change settings and data on
Dev, so the message below tells it to look and report only, and the change
log records everything it does.

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
- Don't change, turn off or sign out other people, and don't make anyone a
  system admin.
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

1. **Staff → Reviewer → Deactivate** (only you, the owner, are safe from this;
   the reviewer can't do it to you).
2. Delete the "Reviewer" entry from your authenticator app.
3. Change log → **Everything about this person** shows everything it did.
4. Send the report to cmeprojects; it gets merged with our own review.
