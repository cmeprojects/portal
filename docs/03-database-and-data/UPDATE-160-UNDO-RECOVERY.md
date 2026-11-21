# Update 160: what undo keeps, and how to recover it (cmeprojects)

**Undo does not restore anything to the live portal.** `undo-160.sql` removes update 160 and
keeps a locked copy of the records it added in the database schema `undo_160_kept`. Those
records stay out of the portal unless someone deliberately runs the manual recovery below.

## What undo-160 does

| | |
|---|---|
| **Copies to `undo_160_kept` first** | Support plans and lines; proposed budgets and lines; care plan items; client or representative agreements (with the representative's name, role, relationship and authority as at the agreement date); each care plan's review details and source (status before undo, program, source assessment and template version, who submitted and reviewed and when, review note); care goals' source findings; which worker instructions came from which approved plan item (who added them and when). |
| **Removes from the live portal** | The new tables and columns, their checks and access rules, the generation and funding comparison functions, the template-section change-log trigger, and the "approve" right. |
| **Leaves as it is** | Every care plan (title, wording, dates; approved plans stay current, superseded plans stay superseded); goals and their progress; **all worker instructions, including ones added from an approved plan, with their wording** (only the link back to the plan item moves to the kept copy); assessments; funding; every change-log entry. |
| **Changes** | Care plans waiting for review or needing changes go back to Draft (their review details are in the kept copy). Access rules that gave only "approve" are ended; "approve" is taken out of other rules. |

`undo_160_kept` can be read only by the database owner (not by anyone signed in to the portal).
Running undo again doesn't duplicate kept records. Running `update-160.sql` again starts the
new tables empty.

## Manual recovery (only if the owner decides to)

Script: `supabase/live-updates/recover-160-kept.sql`. It is not part of any update.

1. **Decide and record** who asked for the recovery and why (for example in the decision register).
2. **Back up** the database (Supabase dashboard: Database, Backups), and note the time.
3. **Run `update-160.sql`** again if it isn't in place (recovery stops if the live tables are missing).
4. **Run `recover-160-kept.sql`** in the SQL Editor. In one transaction it:
   - copies kept records back where they're missing (matched by id), parents first:
     support plans, their lines, budgets, their lines, care plan items, agreements;
   - skips any record whose client, plan or support plan no longer exists, and lists what it skipped;
   - puts back care plans' source, program and review details, goals' source findings and
     worker instructions' source links (only where empty, and once per plan item);
   - **changes no status**: plans that were waiting for review stay Draft and are sent for review
     again by a person; approved support plans and budgets come back as they were, with who
     made, submitted and approved them;
   - pauses the portal's checks for the copy (otherwise they'd reset who made and approved each
     record) and writes one change-log entry, `update_160_records_recovered`.
5. **Check** the list it prints ("not recovered"), then open a few affected clients in the portal
   (Care plans and Funding tabs) and confirm agreements, items and budgets look right.
6. **Keep `undo_160_kept`** until the owner is satisfied. Removing it (`drop schema undo_160_kept cascade;`)
   is a separate decision and can't be undone.

Running the recovery again is safe: records already back are left alone (each run adds a change-log entry).

Tested 21 Nov 2026: update, undo twice, update again (tables empty, nothing restored), recovery
twice. Every record came back once, with statuses unchanged and the representative's capacity
and authority intact. The live schema was the same as a straight update.
