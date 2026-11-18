# Approved services and the service catalogue (cmeprojects, update 143)

- **Service catalogue** (`service_catalogue`, Clients → Service catalogue): one entry per service
  (Community Access and Shopping Assistance are separate), with its description, the programs it's
  offered under (none ticked = every program), a classification and the shift types it covers.
  Manager Administrators (and the system admin) add, edit and switch entries off; nothing is deleted.
- **Client services** (`client_services`, client page → Services tab, "Approved Services"):
  - *Catalogue*: name and description copied when added and kept as they were; shift types follow the
    catalogue entry.
  - *Custom* ("Add other service"): its own name, description and shift types, for this client only;
    never added to the catalogue by itself. A Manager Administrator can copy it into the catalogue
    ("Add to the service catalogue"); the client's service stays as it was.
  - *Older entry*: made before update 143. With no shift types set it doesn't restrict rostering; set
    them under "View and edit details" to restrict it.
  - Statuses shown as Pending, Active, Suspended, Ended, and Expired once past the end date.
  - No duplicates: the same catalogue service, or the same custom name, twice under one program.
- **Rostering**: for a client shift you choose the shift type; only types the client's current services
  cover are offered, and the service is attached automatically (asked only when two services list the
  same type). The database refuses a client shift whose service isn't the client's, is suspended or
  ended, is outside its dates, or doesn't cover the shift type.
- **Later**: cost codes per catalogue service or shift type (funding and pricing); CHSP as a scheme
  if the organisation needs it (add it under Care settings → schemes).

## Update 144: starter list

Shift types added: Meal preparation, Medication support, Wound care, Continence and catheter care,
Nursing visit, Transport, Laundry, Home maintenance, Behaviour support, Skills building.
Catalogue services added (descriptions left for the organisation): Supported Independent Living (SIL),
Short Term Accommodation, Community Nursing, Meal Preparation, Transport, Laundry, Home Maintenance,
Behaviour Support, Skills Building, Group and Centre-based Activities, Overnight Support (active).

## Update 145: qualifications for shift types

Rostering → ⋮ → Shift types → "Qualifications needed": onboarding and compliance items a worker must
hold (current on the shift date) for that type, e.g. a medication course for Medication support,
nursing registration for Wound care. Smart suggest shows "doesn't hold: …"; the database refuses the
shift. The approved read-only roster_check_dates() now also returns checks with no expiry, and the item.

## Update 146: house rostering (SIL)

A client shift can list other residents at the same address ("Other residents at this address" in
the shift panel). Each resident needs a current approved service covering the shift type; it's
attached for them. Workers see each resident's name, alerts and instructions; adding or removing a
resident is logged. Not yet: splitting hours and costs between residents (with costing), and showing
house shifts in each resident's row in Client view (they show a "+N residents" badge on the main
client's shift).
