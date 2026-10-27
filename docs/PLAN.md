# Plan and decisions

Staff Portal · © cmeproject

## Milestones

1. ✅ Foundations: sign-in, roles, staff, teams, system settings
2. ✅ Tasks: create and assign, helpers, My tasks, emails
   - ✅ Registers: custom fields, register pages, set-up, General tasks,
     follow-up actions, asset list
3. Ticket features: comments, status changes, approvals, reassign,
   escalate, attachments; logo upload in System settings (per company)
4. Manager side: dashboard, reports and exports, auto-escalation
5. Vehicles and mileage
6. Going live

## Decisions

- One copy of the code for every company; each company has its own
  Supabase project and website (no shared database).
- Roles: support worker, team leader, manager, staff admin, system admin.
- Two-factor login has a main on/off switch (system admins only).
- All tasks live in one table; register pages are filtered views. Notes
  columns (Status Notes, Further Information) become timeline comments.
- **Vehicles: no odometer photos.** Trips record the odometer readings as
  typed numbers only.
