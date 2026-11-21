-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 160 (care plans, support plans and proposed budgets from assessments). Safe to run again.
-- Removes support plans, proposed budgets, care plan items, agreements and the
-- "approve" right (their change-log entries stay). Care plans and worker
-- instructions stay; plans waiting for review or needing changes go back to draft;
-- worker instructions lose only the note of which plan they came from.
begin;
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
