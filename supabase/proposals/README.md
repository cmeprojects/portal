# Proposals (cmeprojects)

SQL that is written and tested but **not applied**, because it changes a
permission or a deliberate design rule and needs the owner's decision first.
Nothing here is in the migrations or the fresh install. If approved, it
becomes the next numbered live update (with its migration and tests).

| File | What it would change | Why it's waiting |
|---|---|---|
| managers-act-on-unmanaged-registers.sql (+ undo) | Managers could act on tasks in registers with no named managers (for example General tasks). Today every manager is told about those tasks' escalations, but only the system admin, the assigned person or their team leader can act, so a manager can't press "Escalation dealt with" there. | Reverses a deliberate rule (tested in registers.test.sql): a manager not named on a register can't change its tasks. Alternative without a permission change: name the managers on General tasks (Registers → General tasks → Set up). |
