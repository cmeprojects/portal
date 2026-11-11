# Development credit conservation protocol (cmeprojects)

Staff Portal · © cmeproject · Set by the owner on 11 November 2026. Applies to every task unless the owner overrides it.

**Default approach:** understand → inspect only what's necessary → plan the smallest safe change → implement → test → report.

**Priority order:**
1. Security
2. Correct functionality
3. Data integrity
4. Existing business logic
5. Maintainability
6. Performance
7. Development efficiency

## Rules
- **Scope:**
  - Inspect only the relevant files.
  - Reuse existing components and patterns.
  - Make the smallest safe change.
  - No unrequested modules, dashboards, reports, tables, settings, workflows, redesigns or refactors. Record ideas in a backlog instead.
- **No wasted work:**
  - No full audits for small requests, and no re-reading unchanged files.
  - No repeated analysis or tests, and no duplicate documentation.
  - No multiple agents without a clear benefit.
  - Ask one concise question only when an essential requirement is ambiguous.
- **Database:**
  - Batch queries; never one query per employee, client or task.
  - Server-side filtering, sorting and pagination.
  - SQL for counts and aggregates.
  - No repeated settings or profile reads, and no needless sequential requests.
- **Security (never traded for fewer steps):**
  - RLS stays on and is never bypassed.
  - No frontend-only access control.
  - Prefer `SECURITY INVOKER`. No `SECURITY DEFINER` without explicit approval.
  - Never broaden permissions.
  - Keep SELECT, INSERT, UPDATE and DELETE restrictions, authentication and session checks, and audit logging.
- **Testing, proportional to the change:**
  - **Frontend:** the component, layouts and interactions.
  - **Database:** the query or function, RLS per role, integrity and rollback.
  - **Workflows:** the full flow, roles, notifications and audit.
  - **Major modules:** module regression and security.

  Never skip essential tests. Never claim a test passed unless it was run.
- **Performance:** no new optimisation projects. Stages 2–9 stay deferred (`docs/roadmap/performance-and-scalability.md`). Flag obvious new scalability problems with a focused fix.
- **Failures:** find the actual error, fix the root cause, retest what's affected.
- **Done means done:** no further changes once the outcome is achieved.

## Completion report (short, proportional)
- **Completed:** what was built.
- **Files changed:** only the relevant ones.
- **Testing:** what was run, the results, and what wasn't run.
- **Security:** whether RLS, permissions or functions were affected.
- **Outstanding:** known issues and future improvements.
- **Credit efficiency:** unnecessary work avoided. No invented figures.
