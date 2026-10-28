# Business notes

Staff Portal · © cmeproject

## Before any company uses or buys the portal

Get a **short written agreement** with every company. It should cover:

- **Who owns the code:** cmeproject.
- **Who owns the data:** always the company.
- **Support:** what's included, response times, how to ask for help.
- **Updates:** whether they get new versions, and how.
- **Price:** set-up fee, monthly or yearly fee, what happens if they stop paying.

Use a lawyer or a template from a small-business legal service. This note
isn't legal advice.

## Ways a company can buy it

1. **Subscription (default):** they pay to use it. cmeproject hosts it,
   owns the code and sends updates.
2. **Licence, self-hosted:** their Supabase project and website move into
   their own accounts. cmeproject still owns the code. Updates and support
   come with an ongoing fee.
3. **Buy the code outright (premium price):** they get a copy of the code at
   that point in time. Later updates aren't included unless sold separately.
   The contract should keep cmeproject's right to reuse its own platform for
   other customers.

## Licence

`LICENSE` in this repository says the software belongs to cmeproject and
can't be copied, changed or shared without written permission. Each
company's agreement gives them permission to **use** it on the terms above.

## Business rule: manager approval before a task is closed

**Rule.** In registers set to "Manager approval needed to close", the person
doing the work can't complete their own task. When they finish, it goes to
*Waiting for approval*. A manager of that register (or any manager, if the
register has none) checks it and either approves it or sends it back with a
reason. Nobody can approve their own work.

**Why.**
1. **Separation of duties.** The person who does the work is not the person
   who signs it off. This is a standard internal control and what auditors
   and quality reviewers look for.
2. **Quality and safety.** Risks, incidents, complaints and repairs affect
   the people we support. A second person confirms the fix actually worked
   (for example, the hazard is really gone) before the record says "done".
3. **Accountability and evidence.** Every approval or send-back is recorded
   with who, when and why. That trail shows the organisation acted on an
   issue and closed it properly, which matters for audits, insurers, funding
   bodies and any later complaint or investigation.
4. **Continuous improvement.** Managers see how issues were resolved, spot
   patterns, and decide whether a policy, training or follow-up is needed
   before the issue is closed for good.
5. **Consistency.** Everyone's work is closed to the same standard, not
   just marked done when the person feels finished.

**Which registers use it.** Set per register in its Set up page. Suggested:
Risk, Critical Incidents, Complaints and Feedback, and Maintenance (safety
repairs). Usually not needed for General tasks or simple admin jobs.

**What staff see.** "Finished: send for approval". The manager gets a bell
and an email. If sent back, the person gets the reason and carries on.

## Business rule: there is always at least one manager

When only one active manager is left, staff admins and managers can't
deactivate them or change their role, and a staff admin can't even send that
request. This stops the organisation being left with nobody who can approve
work, change roles or handle escalations. Add another manager first. The
system admin can still make the change if it's really needed (for example,
the only manager has left the organisation).
