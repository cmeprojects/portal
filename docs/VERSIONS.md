# Versions (cmeprojects)

Staff Portal · © cmeproject. Each version is kept as a branch, so it can be restored or shown in a demo at any time.

| Version | Branch | Date | What it is |
|---|---|---|---|
| **0.1.0** | `version-0.1.0` (commit c94669f) | 12 Nov 2026 | Everything up to and including module framework step 1: improvement phases 1–5, TFN declarations, uniform buttons, new sidebar and top bar from the module catalogue. Database updates up to **68**. |
| **0.1.1** | `version-0.1.1` | 12 Nov 2026 | Module framework step 2: one permission check (`can(module, action, person)`) with category, module and submodule permissions, actions, inheritance, restrictions, "sensitive needs its own grant", scope, start and end dates, and "new modules are never given automatically". It gives exactly today's answers where today's rules apply, so **no change to anyone's access**, and no security rule uses it yet, so **no performance change**. Database update **69**. |

## How to demo or restore a version
- **Demo:** in Vercel, deploy the version's branch to a demo project. Use a database set up with the setup SQL from that branch (`supabase/install/fresh-install.sql`).
- **Restore Development to a version:** run the `undo-NN.sql` files in reverse order down to that version's last update, then deploy the version's branch.
- Git tags couldn't be pushed from this environment, so versions are branches. A `v0.1.0` tag exists locally.
