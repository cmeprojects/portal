-- Staff Portal · © cmeproject. All rights reserved.
-- MANUAL RECOVERY after undo-160 (cmeprojects). Not part of any update; never run automatically.
-- Undo-160 does NOT restore anything. It only keeps a locked copy in undo_160_kept.
-- Run this only when the owner decides to bring those records back, and only:
--   1. after update-160.sql has been run again (the live tables must exist), and
--   2. after a database backup.
-- Procedure and checks: docs/03-database-and-data/UPDATE-160-UNDO-RECOVERY.md
-- What it does, in one transaction:
--   * copies kept records back where they are missing (by id), parents first;
--     records whose client, plan or contact no longer exists are skipped and listed;
--   * puts back each care plan's source, program and review details, goal sources
--     and worker-instruction sources;
--   * does NOT change any status: plans that were waiting for review stay Draft
--     and are sent for review again by a person;
--   * the portal's checks are paused for the copy (they would otherwise reset who
--     made and approved each record), so a single change-log entry records the recovery.
-- Safe to run again: records already back are left alone.
begin;
do $$
begin
  if to_regclass('public.client_support_plans') is null then
    raise exception 'Run update-160.sql first; recovery needs the live tables.';
  end if;
  if to_regnamespace('undo_160_kept') is null then
    raise exception 'Nothing to recover: undo_160_kept doesn''t exist.';
  end if;
end $$;

set local session_replication_role = replica;

-- Copies kept rows back where missing, skipping any whose parent records are gone.
create or replace function pg_temp.restore(p_table text, p_where text) returns integer language plpgsql as $$
declare
  v_cols text;
  v_n integer := 0;
begin
  if to_regclass('undo_160_kept.' || p_table) is null then
    return 0;
  end if;
  select string_agg(quote_ident(c.column_name), ', ' order by c.ordinal_position) into v_cols
    from information_schema.columns c
   where c.table_schema = 'public' and c.table_name = p_table and c.is_generated = 'NEVER'
     and exists (select 1 from information_schema.columns k where k.table_schema = 'undo_160_kept' and k.table_name = p_table and k.column_name = c.column_name);
  execute format('insert into public.%I (%s) select %s from undo_160_kept.%I k where not exists (select 1 from public.%I p where p.id = k.id) and %s',
                 p_table, v_cols, v_cols, p_table, p_table, p_where);
  get diagnostics v_n = row_count;
  raise notice 'restored % row(s) to %', v_n, p_table;
  return v_n;
end $$;

select pg_temp.restore('client_support_plans', 'exists (select 1 from public.car_clients c where c.id = k.client_id)');
select pg_temp.restore('client_support_plan_lines', 'exists (select 1 from public.client_support_plans s where s.id = k.plan_id)');
select pg_temp.restore('client_budget_proposals', 'exists (select 1 from public.car_clients c where c.id = k.client_id)');
select pg_temp.restore('client_budget_lines', 'exists (select 1 from public.client_budget_proposals b where b.id = k.proposal_id)');
select pg_temp.restore('client_care_plan_items', 'exists (select 1 from public.client_care_plans p where p.id = k.plan_id)');
select pg_temp.restore('client_plan_agreements',
  '(k.care_plan_id is null or exists (select 1 from public.client_care_plans p where p.id = k.care_plan_id))
   and (k.support_plan_id is null or exists (select 1 from public.client_support_plans s where s.id = k.support_plan_id))');

-- Care plan sources and review details (latest kept copy of each plan); statuses unchanged.
do $$ begin
  if to_regclass('undo_160_kept.care_plan_review') is not null then
    update public.client_care_plans p
       set enrolment_id = k.enrolment_id, source_assessment_id = k.source_assessment_id, source_version_id = k.source_version_id,
           submitted_by = k.submitted_by, submitted_at = k.submitted_at, reviewed_by = k.reviewed_by, reviewed_at = k.reviewed_at,
           review_note = coalesce(k.review_note, '')
      from (select distinct on (id) * from undo_160_kept.care_plan_review order by id, kept_at desc) k
     where p.id = k.id and p.source_assessment_id is null and p.submitted_at is null and p.reviewed_at is null;
  end if;
  if to_regclass('undo_160_kept.care_goal_source') is not null then
    update public.client_care_goals g set source_finding_id = k.source_finding_id
      from (select distinct on (id) * from undo_160_kept.care_goal_source order by id, kept_at desc) k
     where g.id = k.id and g.source_finding_id is null;
  end if;
  if to_regclass('undo_160_kept.worker_instruction_source') is not null then
    update public.client_worker_instructions w
       set source_plan_id = k.source_plan_id, source_item_id = k.source_item_id, added_by = k.added_by, added_at = k.added_at
      from (select distinct on (id) * from undo_160_kept.worker_instruction_source order by id, kept_at desc) k
     where w.id = k.id and w.source_item_id is null
       and exists (select 1 from public.client_care_plan_items i where i.id = k.source_item_id)
       and not exists (select 1 from public.client_worker_instructions o where o.source_item_id = k.source_item_id);
  end if;
end $$;

set local session_replication_role = origin;

-- One change-log entry for the recovery (the copy itself bypassed the per-record log).
insert into public.audit_log (actor_id, action, entity, entity_id, details)
values (null, 'update_160_records_recovered', 'system', 'undo_160_kept',
        jsonb_build_object('source', 'database', 'note', 'Records kept by undo-160 copied back by hand (recover-160-kept.sql).'));

-- What was not brought back (missing parents), for the owner to review.
select 'not recovered' as result, t as kept_table, n as records
  from (
    select 'client_support_plan_lines' t, count(*) n from undo_160_kept.client_support_plan_lines k where not exists (select 1 from public.client_support_plan_lines p where p.id = k.id)
    union all select 'client_budget_lines', count(*) from undo_160_kept.client_budget_lines k where not exists (select 1 from public.client_budget_lines p where p.id = k.id)
    union all select 'client_care_plan_items', count(*) from undo_160_kept.client_care_plan_items k where not exists (select 1 from public.client_care_plan_items p where p.id = k.id)
    union all select 'client_plan_agreements', count(*) from undo_160_kept.client_plan_agreements k where not exists (select 1 from public.client_plan_agreements p where p.id = k.id)
  ) x
 where n > 0;
commit;
