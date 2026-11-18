# Shift panel: integration points for later (cmeprojects, 18 Nov 2026)

The redesigned shift panel (update 141) leaves these joins ready, without
inventing any financial rules.

## Cost codes (funding and pricing, not built yet)

- Shift types are now a managed list (`shift_types`, Rostering → ⋮ → Shift
  types). Cost codes will attach to a shift type through a link table
  (`shift_type_cost_codes`: shift type, cost code, from/to dates) owned by
  the funding and pricing set-up.
- The shift panel will then offer only the cost codes linked to the chosen
  shift type, and keep the chosen code on the shift (`shifts.cost_code_id`)
  for costing and reports.
- Nothing is hard-coded in the form; no codes or prices exist until then.

## Pay rates (pay settings, not built yet)

- Each shift keeps its pay classification (`shifts.pay_class`: regular or
  casual) and allowances (sleepover and others).
- Pay settings (Manager Administrators) will hold base rates, casual loading
  (configurable, not assumed to be 25%), day, evening, night, Saturday,
  Sunday and public holiday rates, and sleepover rules, kept apart from
  client funding.
- The rate is worked out from the worker's classification, the shift's
  times and day and the configured rules, and stored with the approved
  timesheet (planned shift → service record → timesheet stay separate).

## Also for later

- Job board (posting shifts for staff to apply): entry point shown as
  "coming later".
- Linking a form to a shift, and tasks for a shift: shown as "coming later"
  (tasks have no link to shifts yet).
- Smart suggest already uses leave, clashes, expired checks, availability,
  hours and who knows the client; qualifications, program eligibility and
  travel can be added when that data exists.
