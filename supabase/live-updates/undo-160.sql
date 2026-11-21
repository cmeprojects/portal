-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 160 (care plans, support plans and proposed budgets from assessments). Safe to run again.
-- Nothing is lost: before anything is removed, every record update 160 added is
-- copied to a locked schema, undo_160_kept, that only the database owner can read:
--   support plans and lines, proposed budgets and lines, care plan items,
--   client or representative agreements, each care plan's review details and
--   source, care goals' source findings, and which worker instructions came from
--   which approved plan item. Change-log entries stay as they are.
-- Then the new tables, columns and rules are removed and the "approve" right ends.
-- What stays as it is: care plans (title, wording, dates, approved and
-- superseded plans), goals, all worker instructions (including ones added from an
-- approved plan, with their wording), assessments, funding.
-- What changes: care plans waiting for review or needing changes go back to Draft
-- (their review details are in undo_160_kept); access rules that gave only
-- "approve" are ended; "approve" is removed from other rules.
begin;

-- 1. Keep a copy of everything update 160 added.
create schema if not exists undo_160_kept;
revoke all on schema undo_160_kept from public;
do $$
declare
  t text;
begin
  foreach t in array array['client_support_plans', 'client_support_plan_lines', 'client_budget_proposals', 'client_budget_lines', 'client_care_plan_items', 'client_plan_agreements'] loop
    if to_regclass('public.' || t) is not null then
      if to_regclass('undo_160_kept.' || t) is null then
        execute format('create table undo_160_kept.%I as table public.%I', t, t);
      else
        execute format('insert into undo_160_kept.%I select * from public.%I p where not exists (select 1 from undo_160_kept.%I k where k.id = p.id)', t, t, t);
      end if;
    end if;
  end loop;
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'client_care_plans' and column_name = 'submitted_by') then
    execute 'create table if not exists undo_160_kept.care_plan_review (id uuid, status_before_undo text, enrolment_id uuid, source_assessment_id uuid, source_version_id uuid,
               submitted_by uuid, submitted_at timestamptz, reviewed_by uuid, reviewed_at timestamptz, review_note text, kept_at timestamptz)';
    execute 'insert into undo_160_kept.care_plan_review
             select id, status, enrolment_id, source_assessment_id, source_version_id, submitted_by, submitted_at, reviewed_by, reviewed_at, review_note, now()
               from public.client_care_plans
              where status in (''pending_review'', ''changes_required'') or enrolment_id is not null or source_assessment_id is not null or submitted_by is not null or reviewed_by is not null';
  end if;
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'client_care_goals' and column_name = 'source_finding_id') then
    execute 'create table if not exists undo_160_kept.care_goal_source (id uuid, source_finding_id uuid, kept_at timestamptz)';
    execute 'insert into undo_160_kept.care_goal_source select id, source_finding_id, now() from public.client_care_goals where source_finding_id is not null';
  end if;
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'client_worker_instructions' and column_name = 'source_item_id') then
    execute 'create table if not exists undo_160_kept.worker_instruction_source (id uuid, source_plan_id uuid, source_item_id uuid, added_by uuid, added_at timestamptz, kept_at timestamptz)';
    execute 'insert into undo_160_kept.worker_instruction_source select id, source_plan_id, source_item_id, added_by, added_at, now() from public.client_worker_instructions where source_item_id is not null';
  end if;
end $$;
revoke all on all tables in schema undo_160_kept from public;
do $$ begin
  execute 'revoke all on schema undo_160_kept from anon, authenticated';
  execute 'revoke all on all tables in schema undo_160_kept from anon, authenticated';
exception when undefined_object then null;
end $$;

-- 2. Remove update 160.
drop trigger if exists guard_instruction_source on public.client_worker_instructions;
drop index if exists public.client_worker_instructions_one_per_item;
alter table public.client_worker_instructions
  drop column if exists source_item_id, drop column if exists source_plan_id,
  drop column if exists added_by, drop column if exists added_at;
drop table if exists public.client_plan_agreements;
drop table if exists public.client_budget_lines;
drop table if exists public.client_budget_proposals;
drop table if exists public.client_support_plan_lines;
drop table if exists public.client_support_plans;
drop table if exists public.client_care_plan_items;
drop policy if exists "approvers review care plans" on public.client_care_plans;
drop function if exists public.generate_care_documents(uuid);
drop function if exists public.budget_funding(uuid);
drop function if exists public.guard_care_document();
drop function if exists public.guard_care_line();
drop function if exists public.guard_plan_agreement();
drop function if exists public.guard_instruction_source();

-- Care plans and goals: the checks as they were before update 160.
create or replace function public.guard_care_plan()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
  if new.document_id is not null and not exists (select 1 from public.client_documents d where d.id = new.document_id and d.client_id = new.client_id) then
    raise exception 'That document belongs to another client.';
  end if;
  if tg_op = 'INSERT' then
    new.status := 'draft';
    new.created_by := auth.uid();
    new.created_at := now();
    new.made_current_by := null;
    new.made_current_at := null;
    new.archived_at := null;
    return new;
  end if;
  if new.created_by is distinct from old.created_by or new.created_at is distinct from old.created_at then
    raise exception 'Who added a plan, and when, isn''t changed.';
  end if;
  if old.status = 'archived' and (new is distinct from old) then
    raise exception 'An archived plan isn''t changed. Start a new draft instead.';
  end if;
  if old.status = 'current' and new.status = 'draft' then
    raise exception 'A current plan can''t go back to draft. Start a new draft instead.';
  end if;
  if old.status <> 'draft' and (new.title, new.assessed_on, new.starts_on, new.review_by, new.summary, new.document_id)
       is distinct from (old.title, old.assessed_on, old.starts_on, old.review_by, old.summary, old.document_id) then
    raise exception 'A current plan''s wording is fixed. Start a new draft to change it.';
  end if;
  if new.status = 'current' and old.status = 'draft' then
    update public.client_care_plans set status = 'archived' where client_id = new.client_id and status = 'current' and id <> new.id;
    new.made_current_by := auth.uid();
    new.made_current_at := now();
  else
    new.made_current_by := old.made_current_by;
    new.made_current_at := old.made_current_at;
  end if;
  if new.status = 'archived' and old.status <> 'archived' then
    new.archived_at := now();
  else
    new.archived_at := old.archived_at;
  end if;
  return new;
end;
$function$

;
create or replace function public.guard_care_goal()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  v_status text;
begin
  select p.status into v_status from public.client_care_plans p where p.id = new.plan_id and p.client_id = new.client_id;
  if v_status is null then
    raise exception 'That plan belongs to another client.';
  end if;
  if v_status = 'archived' then
    raise exception 'That plan is archived. Goals on it aren''t changed.';
  end if;
  if tg_op = 'INSERT' then
    if v_status <> 'draft' then
      raise exception 'Goals are added while the plan is a draft.';
    end if;
    return new;
  end if;
  if new.plan_id is distinct from old.plan_id then
    raise exception 'A goal stays with its plan.';
  end if;
  if v_status <> 'draft' and (new.goal, new.measure) is distinct from (old.goal, old.measure) then
    raise exception 'A current plan''s goals are fixed. Update their progress, or start a new draft.';
  end if;
  return new;
end;
$function$

;
drop function if exists public.care_doc_approver_ok(text, uuid, uuid, uuid);
drop function if exists public.care_doc_source(uuid, uuid, uuid);
drop function if exists public.care_doc_reach(text, text, uuid);
update public.client_care_plans set status = 'draft' where status in ('pending_review', 'changes_required');
alter table public.client_care_plans drop constraint if exists client_care_plans_status_check;
alter table public.client_care_plans add constraint client_care_plans_status_check check (status in ('draft', 'current', 'archived'));
alter table public.client_care_plans
  drop column if exists enrolment_id, drop column if exists source_assessment_id, drop column if exists source_version_id,
  drop column if exists submitted_by, drop column if exists submitted_at, drop column if exists reviewed_by,
  drop column if exists reviewed_at, drop column if exists review_note;
alter table public.client_care_goals drop column if exists source_finding_id;

-- The "approve" right.
-- A rule that gave only "approve" is ended (an empty list would mean every action).
update public.access_baselines set revoked_at = now() where module_id in ('clients.care_plans', 'clients.funding') and actions = '{approve}' and revoked_at is null;
update public.access_grants set revoked_at = now() where module_id in ('clients.care_plans', 'clients.funding') and actions = '{approve}' and revoked_at is null;
update public.access_baselines set actions = array_remove(actions, 'approve') where module_id in ('clients.care_plans', 'clients.funding') and 'approve' = any (actions) and actions <> '{approve}';
update public.access_grants set actions = array_remove(actions, 'approve') where module_id in ('clients.care_plans', 'clients.funding') and 'approve' = any (actions) and actions <> '{approve}';
update public.app_modules set actions = array_remove(actions, 'approve') where id in ('clients.care_plans', 'clients.funding');

drop trigger if exists assessment_sections_log on public.assessment_sections;
commit;
