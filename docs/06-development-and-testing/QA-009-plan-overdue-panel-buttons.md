# QA-009: Change plan: buttons in the dashboard "Past their due date" panel

| Field | Value |
|---|---|
| Document ID | QA-009 |
| Title | Change plan: dashboard task panel buttons follow the rules |
| Category | 06 Development and testing |
| Version | 0.1 |
| Status | **Draft: plan for approval.** Nothing implemented |
| Owner / Reviewer / Approver | Technical Lead (the owner) / Technical Lead / Product Owner (the owner) |
| Created | 16 Nov 2026 |
| Related | Owner report and screenshot (16 Nov 2026); updates 82, 83; DEC-001 D-015, D-016 |

## 1. What happens today (verified)

- The manager dashboard panel (`src/app/(portal)/manager-board.tsx`,
  `QuickActions`) shows, for every task in the list: **Escalation dealt with**
  (if escalated), **Remind**, **Reassign**, **Take over**, **Open task**.
- It doesn't check who is looking. The database decides on the click:
  - "Escalation dealt with" (`set_task_status` → In progress) is refused for
    **the task's own assignee** ("You can't make this change"): someone above
    them deals with an escalation. Allowed: the system admin, a manager of
    that register (any manager for registers with no named managers, update
    83), the assignee's team leader, the creator.
  - Reassign and Take over (`reassign_task`) need `can_edit_task`, refused
    for a manager who isn't named on a register that has named managers.
- The refusal shows as a small red line under the buttons, easy to miss.
- The task page already hides "Escalation dealt with" from the assignee
  (`tasks/[id]/page.tsx`); the panel doesn't.
- On the owner's screenshot every task is assigned to the person viewing, so
  "Escalation dealt with" is refused each time. Locally, a manager who isn't
  the assignee can use it (task moves to In progress, card leaves the list).

## 2. Proposed change (code only; no database, RLS or rule change)

1. **Hide "Escalation dealt with" on your own tasks**, with the line:
   "Escalated about you: your manager deals with the escalation. Update or
   finish the task to move it on." (same rule as the task page).
2. **Hide Reassign and Take over where they'd be refused** for a manager:
   registers with named managers that don't include them (unless they're the
   system admin or created the task), with the line "Only this register's
   managers can change it; open the task to see who." Uses data the
   dashboard already reads plus the register managers list (readable by all
   members). Remind stays (it's a comment).
3. **Clear refusals:** any refusal from the database shows as a visible
   message box on the card, not a small red line.
4. **Same button style:** "Escalation dealt with" uses the same outline style
   as the others, so it doesn't look greyed out on the Dev colours.

The database still checks every click; the screen only stops offering what
will fail. Edge case noted: a manager who is also the assignee's team leader
could act through the task page even if the panel hides Reassign (the panel
doesn't check team leadership); the task page stays the full route.

Files: `src/app/(portal)/manager-board.tsx`, `src/app/(portal)/role-dashboard.tsx`
(pass the viewer's id and role, register managers, and each task's creator).

## 3. Tests

- Lint, typecheck, unit; database suite unchanged (no SQL); build.
- Browser, local copy:
  - as a manager on a task assigned to them: no "Escalation dealt with",
    the explanation shows; Remind/Reassign/Take over as allowed;
  - as a manager on someone else's escalated General task: "Escalation dealt
    with" works (task to In progress, card leaves the list);
  - as a manager not named on a register with named managers: no Reassign
    or Take over, explanation shown;
  - as the system admin: all actions shown;
  - a forced refusal shows the visible message box;
  - buttons look the same; phone width; no page errors.

## 4. Rollback

Revert the one commit. No data to restore.
