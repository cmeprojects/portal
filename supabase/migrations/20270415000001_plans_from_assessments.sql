-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 160): draft care plans, support plans and proposed budgets
-- from assessments (Phase 3 of the programs, assessments and billing plan,
-- approved 21 Nov 2026).
--   * Care plans (the existing table, extended): Draft -> Pending review ->
--     Changes required -> Approved ("current") -> Superseded ("archived").
--     Manually made plans follow the same steps; existing current and archived
--     plans are left as they are. Items (needs, risks, care requirements,
--     interventions, support instructions, monitoring, preferences) and goals
--     keep the finding they came from.
--   * Support plans and proposed budgets (new), with the same steps. Budgets
--     hold estimates only (typed-in rates), never prices, funding or billing,
--     and are compared with verified funding records only for periods that fit.
--   * Approving needs the new "approve" right (care plans: Care plans; budgets:
--     Funding) and a different person from whoever made or submitted it.
--   * Client or representative agreement is recorded separately, only after
--     approval, and never changes.
--   * Drafts are generated from a completed assessment in one step; running it
--     again never changes an existing draft and makes no duplicates.
--   * "Add to worker instructions" from an approved plan's instruction items,
--     once per item, keeping where it came from. Existing instructions untouched.
--   * Template version control: sections are now in the change log too.
-- No new security definer function. Changes are in the client audit trail.
-- Nothing is deleted except items on an unapproved draft. Safe to run again.

-- 0. Assessment template sections in the change log (version control).
drop trigger if exists assessment_sections_log on public.assessment_sections;
create trigger assessment_sections_log after insert or update on public.assessment_sections
  for each row execute function public.log_car_setup('assessment_section');

-- 1. "Approve" rights on the Access page (managers' "all actions" defaults include it).
update public.app_modules set actions = array_append(actions, 'approve')
 where id in ('clients.care_plans', 'clients.funding') and not ('approve' = any (actions));

-- Reach: all clients, or the clients someone is assigned to (as care plans).
create or replace function public.care_doc_reach(p_module text, p_action text, p_client uuid) returns boolean
language sql stable set search_path = '' as $$
  select (select public.can(p_module, p_action, '00000000-0000-0000-0000-000000000000'))
      or (p_client in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
          and public.can(p_module, p_action, p_client))
$$;
-- Who may approve, and who may not (made it, or submitted it).
create or replace function public.care_doc_approver_ok(p_module text, p_client uuid, p_created_by uuid, p_submitted_by uuid) returns boolean
language sql stable set search_path = '' as $$
  select public.care_doc_reach(p_module, 'approve', p_client)
     and auth.uid() is distinct from p_created_by
     and auth.uid() is distinct from p_submitted_by
$$;

-- 2. Care plans: extended.
alter table public.client_care_plans drop constraint if exists client_care_plans_status_check;
alter table public.client_care_plans add constraint client_care_plans_status_check
  check (status in ('draft', 'pending_review', 'changes_required', 'current', 'archived'));
alter table public.client_care_plans
  add column if not exists enrolment_id uuid references public.client_enrolments (id),
  add column if not exists source_assessment_id uuid references public.client_assessments (id),
  add column if not exists source_version_id uuid references public.assessment_versions (id),
  add column if not exists submitted_by uuid,
  add column if not exists submitted_at timestamptz,
  add column if not exists reviewed_by uuid,
  add column if not exists reviewed_at timestamptz,
  add column if not exists review_note text not null default '';

-- The source assessment must be this client's completed one; its version is recorded from it.
create or replace function public.care_doc_source(p_client uuid, p_assessment uuid, p_enrolment uuid) returns uuid
language plpgsql stable set search_path = '' as $$
declare
  v_version uuid;
begin
  if p_enrolment is not null and not exists (select 1 from public.client_enrolments e where e.id = p_enrolment and e.client_id = p_client) then
    raise exception 'Choose one of the client''s programs.';
  end if;
  if p_assessment is null then
    return null;
  end if;
  select a.version_id into v_version from public.client_assessments a
   where a.id = p_assessment and a.client_id = p_client and a.status in ('completed', 'superseded');
  if v_version is null then
    raise exception 'Only a completed assessment of this client can be the source.';
  end if;
  return v_version;
end;
$$;

create or replace function public.guard_care_plan() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_api boolean := public.from_portal();
begin
  if new.document_id is not null and not exists (select 1 from public.client_documents d where d.id = new.document_id and d.client_id = new.client_id) then
    raise exception 'That document belongs to another client.';
  end if;
  if tg_op = 'INSERT' then
    new.status := 'draft';
    new.created_by := auth.uid();
    new.created_at := now();
    new.made_current_by := null; new.made_current_at := null; new.archived_at := null;
    new.submitted_by := null; new.submitted_at := null; new.reviewed_by := null; new.reviewed_at := null; new.review_note := '';
    new.source_version_id := public.care_doc_source(new.client_id, new.source_assessment_id, new.enrolment_id);
    return new;
  end if;
  if (new.created_by, new.created_at, new.client_id, new.source_assessment_id, new.source_version_id, new.enrolment_id)
     is distinct from (old.created_by, old.created_at, old.client_id, old.source_assessment_id, old.source_version_id, old.enrolment_id) then
    raise exception 'Who made a plan, its source and program aren''t changed.';
  end if;
  if old.status = 'archived' and (new is distinct from old) then
    raise exception 'A superseded plan isn''t changed. Start a new draft instead.';
  end if;
  if old.status not in ('draft', 'changes_required')
     and (new.title, new.assessed_on, new.starts_on, new.review_by, new.summary, new.document_id)
       is distinct from (old.title, old.assessed_on, old.starts_on, old.review_by, old.summary, old.document_id) then
    raise exception 'A plan''s wording can only change while it''s a draft or needs changes.';
  end if;
  -- Status steps.
  new.made_current_by := old.made_current_by; new.made_current_at := old.made_current_at;
  new.archived_at := old.archived_at;
  if new.status is distinct from old.status then
    if new.status = 'pending_review' and old.status in ('draft', 'changes_required') then
      new.submitted_by := auth.uid(); new.submitted_at := now();
      new.reviewed_by := null; new.reviewed_at := null;
    elsif new.status = 'draft' and old.status = 'pending_review' then
      -- taken back to keep working on it (by someone who can change plans)
      if v_api and not public.care_doc_reach('clients.care_plans', 'edit', new.client_id) then
        raise exception 'Only someone who can change care plans can take it back.';
      end if;
    elsif new.status in ('changes_required', 'current') and old.status = 'pending_review' then
      if v_api and not public.care_doc_approver_ok('clients.care_plans', new.client_id, old.created_by, old.submitted_by) then
        raise exception 'Only someone with the right to approve care plans, who didn''t make or submit this one, can review it.';
      end if;
      if new.status = 'changes_required' and length(trim(new.review_note)) = 0 then
        raise exception 'Say what needs changing.';
      end if;
      new.reviewed_by := auth.uid(); new.reviewed_at := now();
      if new.status = 'current' then
        update public.client_care_plans set status = 'archived' where client_id = new.client_id and status = 'current' and id <> new.id;
        new.made_current_by := auth.uid(); new.made_current_at := now();
      end if;
    elsif new.status = 'archived' and old.status in ('current', 'draft', 'changes_required') then
      new.archived_at := now(); -- superseded by hand, or a draft withdrawn
    else
      raise exception 'A care plan goes Draft -> Pending review -> Approved (or Changes required). It can''t go from % to %.', old.status, new.status;
    end if;
  elsif (new.submitted_by, new.submitted_at, new.reviewed_by, new.reviewed_at) is distinct from (old.submitted_by, old.submitted_at, old.reviewed_by, old.reviewed_at)
        or (new.review_note is distinct from old.review_note and old.status <> 'pending_review') then
    raise exception 'Review details are set by the review itself.';
  end if;
  return new;
end;
$$;

create table if not exists public.client_care_plan_items (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  plan_id uuid not null references public.client_care_plans (id),
  client_id uuid not null references public.car_clients (id),
  section text not null check (section in ('need', 'risk', 'requirement', 'intervention', 'instruction', 'monitoring', 'preference')),
  text text not null check (length(trim(text)) between 1 and 1000),
  detail text not null default '' check (length(detail) <= 2000),
  source_finding_id uuid references public.assessment_findings (id),
  edited boolean not null default false,
  sort_order integer not null default 0,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now()
);
create index if not exists client_care_plan_items_plan on public.client_care_plan_items (plan_id, section, sort_order);

alter table public.client_care_goals add column if not exists source_finding_id uuid references public.assessment_findings (id);
create or replace function public.guard_care_goal() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_status text;
begin
  select p.status into v_status from public.client_care_plans p where p.id = new.plan_id and p.client_id = new.client_id;
  if v_status is null then
    raise exception 'That plan belongs to another client.';
  end if;
  if v_status = 'archived' then
    raise exception 'That plan is superseded. Goals on it aren''t changed.';
  end if;
  if tg_op = 'INSERT' then
    if v_status not in ('draft', 'changes_required') then
      raise exception 'Goals are added while the plan is a draft.';
    end if;
    return new;
  end if;
  if new.plan_id is distinct from old.plan_id or new.source_finding_id is distinct from old.source_finding_id then
    raise exception 'A goal stays with its plan and source.';
  end if;
  if v_status not in ('draft', 'changes_required') and (new.goal, new.measure) is distinct from (old.goal, old.measure) then
    raise exception 'An approved plan''s goals are fixed. Update their progress, or start a new draft.';
  end if;
  return new;
end;
$$;

-- 3. Support plans and proposed budgets.
create table if not exists public.client_support_plans (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id),
  enrolment_id uuid references public.client_enrolments (id),
  source_assessment_id uuid references public.client_assessments (id),
  source_version_id uuid references public.assessment_versions (id),
  title text not null check (length(trim(title)) between 1 and 120),
  summary text not null default '' check (length(summary) <= 4000),
  starts_on date,
  review_by date,
  status text not null default 'draft' check (status in ('draft', 'pending_review', 'changes_required', 'approved', 'superseded')),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  submitted_by uuid, submitted_at timestamptz,
  reviewed_by uuid, reviewed_at timestamptz,
  review_note text not null default '' check (length(review_note) <= 1000),
  approved_by uuid, approved_at timestamptz,
  superseded_at timestamptz,
  updated_by uuid,
  updated_at timestamptz not null default now()
);
create table if not exists public.client_support_plan_lines (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  plan_id uuid not null references public.client_support_plans (id),
  client_id uuid not null references public.car_clients (id),
  service_id uuid references public.client_services (id),
  support text not null check (length(trim(support)) between 1 and 500),
  frequency text not null default '' check (length(frequency) <= 200),
  hours_per_week numeric(6, 2) check (hours_per_week is null or hours_per_week between 0 and 168),
  delivery text not null default '' check (length(delivery) <= 1000),
  responsibilities text not null default '' check (length(responsibilities) <= 1000),
  instructions text not null default '' check (length(instructions) <= 2000),
  source_finding_id uuid references public.assessment_findings (id),
  edited boolean not null default false,
  sort_order integer not null default 0,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now()
);
create table if not exists public.client_budget_proposals (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id),
  enrolment_id uuid references public.client_enrolments (id),
  support_plan_id uuid references public.client_support_plans (id),
  source_assessment_id uuid references public.client_assessments (id),
  source_version_id uuid references public.assessment_versions (id),
  title text not null check (length(trim(title)) between 1 and 120),
  period_start date not null,
  period_end date not null,
  notes text not null default '' check (length(notes) <= 2000),
  status text not null default 'draft' check (status in ('draft', 'pending_review', 'changes_required', 'approved', 'superseded')),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  submitted_by uuid, submitted_at timestamptz,
  reviewed_by uuid, reviewed_at timestamptz,
  review_note text not null default '' check (length(review_note) <= 1000),
  approved_by uuid, approved_at timestamptz,
  superseded_at timestamptz,
  updated_by uuid,
  updated_at timestamptz not null default now(),
  constraint client_budget_proposals_period check (period_end >= period_start)
);
create table if not exists public.client_budget_lines (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  proposal_id uuid not null references public.client_budget_proposals (id),
  client_id uuid not null references public.car_clients (id),
  service_id uuid references public.client_services (id),
  description text not null check (length(trim(description)) between 1 and 500),
  hours_per_week numeric(6, 2) check (hours_per_week is null or hours_per_week between 0 and 168),
  weeks numeric(6, 2) check (weeks is null or weeks between 0 and 104),
  estimated_rate numeric(10, 2) check (estimated_rate is null or estimated_rate between 0 and 10000),
  estimated_cost numeric(12, 2) generated always as (round(coalesce(hours_per_week, 0) * coalesce(weeks, 0) * coalesce(estimated_rate, 0), 2)) stored,
  source_line_id uuid references public.client_support_plan_lines (id),
  sort_order integer not null default 0,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now()
);
create index if not exists client_support_plans_client on public.client_support_plans (client_id);
create index if not exists client_budget_proposals_client on public.client_budget_proposals (client_id);

-- Shared steps for support plans and budgets (module decides who approves).
create or replace function public.guard_care_document() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_api boolean := public.from_portal();
  v_module text := case when tg_table_name = 'client_budget_proposals' then 'clients.funding' else 'clients.care_plans' end;
  v_what text := case when tg_table_name = 'client_budget_proposals' then 'proposed budgets' else 'support plans' end;
  v_old jsonb;
  v_new jsonb;
begin
  if tg_op = 'DELETE' then
    raise exception 'This is never deleted.';
  end if;
  if tg_op = 'INSERT' then
    new.status := 'draft';
    new.created_by := auth.uid(); new.created_at := now();
    new.submitted_by := null; new.submitted_at := null; new.reviewed_by := null; new.reviewed_at := null; new.review_note := '';
    new.approved_by := null; new.approved_at := null; new.superseded_at := null;
    new.source_version_id := public.care_doc_source(new.client_id, new.source_assessment_id, new.enrolment_id);
    if tg_table_name = 'client_budget_proposals' and (to_jsonb(new) ->> 'support_plan_id') is not null
       and not exists (select 1 from public.client_support_plans s where s.id = (to_jsonb(new) ->> 'support_plan_id')::uuid and s.client_id = new.client_id) then
      raise exception 'That support plan belongs to another client.';
    end if;
    return new;
  end if;
  v_old := to_jsonb(old) - array['status', 'submitted_by', 'submitted_at', 'reviewed_by', 'reviewed_at', 'review_note', 'approved_by', 'approved_at', 'superseded_at', 'updated_by', 'updated_at'];
  v_new := to_jsonb(new) - array['status', 'submitted_by', 'submitted_at', 'reviewed_by', 'reviewed_at', 'review_note', 'approved_by', 'approved_at', 'superseded_at', 'updated_by', 'updated_at'];
  if (v_new - array['title', 'summary', 'starts_on', 'review_by', 'period_start', 'period_end', 'notes']) is distinct from (v_old - array['title', 'summary', 'starts_on', 'review_by', 'period_start', 'period_end', 'notes']) then
    raise exception 'Who made it, its source, client and program aren''t changed.';
  end if;
  if old.status not in ('draft', 'changes_required') and v_new is distinct from v_old then
    raise exception 'It can only change while it''s a draft or needs changes.';
  end if;
  if old.status = 'superseded' and new is distinct from old then
    raise exception 'A superseded document isn''t changed.';
  end if;
  new.approved_by := old.approved_by; new.approved_at := old.approved_at; new.superseded_at := old.superseded_at;
  if new.status is distinct from old.status then
    if new.status = 'pending_review' and old.status in ('draft', 'changes_required') then
      new.submitted_by := auth.uid(); new.submitted_at := now(); new.reviewed_by := null; new.reviewed_at := null;
    elsif new.status = 'draft' and old.status = 'pending_review' then
      if v_api and not public.care_doc_reach(v_module, 'edit', new.client_id) then
        raise exception 'Only someone who can change % can take it back.', v_what;
      end if;
    elsif new.status in ('changes_required', 'approved') and old.status = 'pending_review' then
      if v_api and not public.care_doc_approver_ok(v_module, new.client_id, old.created_by, old.submitted_by) then
        raise exception 'Only someone with the right to approve %, who didn''t make or submit this one, can review it.', v_what;
      end if;
      if new.status = 'changes_required' and length(trim(new.review_note)) = 0 then
        raise exception 'Say what needs changing.';
      end if;
      new.reviewed_by := auth.uid(); new.reviewed_at := now();
      if new.status = 'approved' then
        new.approved_by := auth.uid(); new.approved_at := now();
        execute format('update public.%I set status = ''superseded'', superseded_at = now() where client_id = $1 and status = ''approved'' and id <> $2 and enrolment_id is not distinct from $3', tg_table_name)
          using new.client_id, new.id, new.enrolment_id;
      end if;
    elsif new.status = 'superseded' and old.status = 'approved' and pg_trigger_depth() > 1 then
      new.superseded_at := now();
    else
      raise exception 'It goes Draft -> Pending review -> Approved (or Changes required). It can''t go from % to %.', old.status, new.status;
    end if;
  elsif (new.submitted_by, new.submitted_at, new.reviewed_by, new.reviewed_at) is distinct from (old.submitted_by, old.submitted_at, old.reviewed_by, old.reviewed_at)
        or (new.review_note is distinct from old.review_note and old.status <> 'pending_review') then
    raise exception 'Review details are set by the review itself.';
  end if;
  return new;
end;
$$;

-- Lines and items change only while their document is a draft or needs changes.
create or replace function public.guard_care_line() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_row jsonb := to_jsonb(case when tg_op = 'DELETE' then old else new end);
  v_parent uuid := coalesce((v_row ->> 'plan_id')::uuid, (v_row ->> 'proposal_id')::uuid);
  v_status text;
  v_client uuid;
begin
  if tg_table_name = 'client_care_plan_items' then
    select status, client_id into v_status, v_client from public.client_care_plans where id = v_parent;
  elsif tg_table_name = 'client_support_plan_lines' then
    select status, client_id into v_status, v_client from public.client_support_plans where id = v_parent;
  else
    select status, client_id into v_status, v_client from public.client_budget_proposals where id = v_parent;
  end if;
  if v_status is null or v_status not in ('draft', 'changes_required') then
    raise exception 'This can only change while the document is a draft or needs changes.';
  end if;
  if tg_op = 'DELETE' then
    return old;
  end if;
  new.client_id := v_client;
  if (v_row ->> 'service_id') is not null and not exists (select 1 from public.client_services s where s.id = (v_row ->> 'service_id')::uuid and s.client_id = v_client) then
    raise exception 'Choose one of this client''s services.';
  end if;
  if tg_op = 'UPDATE' then
    if (to_jsonb(new) - array['text', 'detail', 'support', 'frequency', 'hours_per_week', 'delivery', 'responsibilities', 'instructions', 'service_id', 'description', 'weeks', 'estimated_rate', 'estimated_cost', 'sort_order', 'section', 'edited', 'updated_by', 'updated_at'])
       is distinct from (to_jsonb(old) - array['text', 'detail', 'support', 'frequency', 'hours_per_week', 'delivery', 'responsibilities', 'instructions', 'service_id', 'description', 'weeks', 'estimated_rate', 'estimated_cost', 'sort_order', 'section', 'edited', 'updated_by', 'updated_at']) then
      raise exception 'Where this came from isn''t changed.';
    end if;
    if tg_table_name <> 'client_budget_lines' and (v_row ->> 'source_finding_id') is not null then
      new := jsonb_populate_record(new, jsonb_build_object('edited', true));
    end if;
  end if;
  return new;
end;
$$;

-- 4. Client or representative agreement (after approval; never changes).
create table if not exists public.client_plan_agreements (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id),
  care_plan_id uuid unique references public.client_care_plans (id),
  support_plan_id uuid unique references public.client_support_plans (id),
  agreed_by text not null check (agreed_by in ('client', 'person')),
  person_id uuid references public.client_people (id),
  agreed_name text not null check (length(trim(agreed_name)) between 1 and 120),
  -- Capacity at the time: "The client, personally", or the contact's role and relationship
  -- (e.g. "Authorised representative (Daughter)") and any authority recorded for them.
  agreed_capacity text not null default '' check (length(agreed_capacity) <= 200),
  agreed_authority text not null default '' check (length(agreed_authority) <= 500),
  method text not null check (method in ('signed', 'written', 'verbal')),
  agreed_on date not null,
  document_id uuid references public.client_documents (id),
  notes text not null default '' check (length(notes) <= 1000),
  recorded_by uuid default auth.uid(),
  recorded_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  constraint client_plan_agreements_one_plan check ((care_plan_id is null) <> (support_plan_id is null)),
  constraint client_plan_agreements_person check ((agreed_by = 'client') = (person_id is null))
);
create or replace function public.guard_plan_agreement() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op <> 'INSERT' then
    raise exception 'A recorded agreement can''t be changed or deleted.';
  end if;
  if new.care_plan_id is not null and not exists (select 1 from public.client_care_plans p where p.id = new.care_plan_id and p.client_id = new.client_id and p.status = 'current') then
    raise exception 'Agreement is recorded once the care plan is approved.';
  end if;
  if new.support_plan_id is not null and not exists (select 1 from public.client_support_plans p where p.id = new.support_plan_id and p.client_id = new.client_id and p.status = 'approved') then
    raise exception 'Agreement is recorded once the support plan is approved.';
  end if;
  -- Who agreed, and in what capacity, comes from the records, not from what was typed.
  if new.agreed_by = 'client' then
    if new.person_id is not null then
      raise exception 'Choose either the client agreeing personally, or a contact agreeing on their behalf.';
    end if;
    new.agreed_name := coalesce((select c.name from public.car_clients c where c.id = new.client_id), new.agreed_name);
    new.agreed_capacity := 'The client, personally';
    new.agreed_authority := '';
  else
    select p.name,
           case p.kind when 'emergency' then 'Emergency contact' when 'next_of_kin' then 'Next of kin' when 'nominee' then 'Nominee'
                       when 'guardian' then 'Guardian' when 'representative' then 'Authorised representative' else p.kind end
             || case when coalesce(trim(p.relationship), '') <> '' then ' (' || trim(p.relationship) || ')' else '' end,
           coalesce(p.authority, '')
      into new.agreed_name, new.agreed_capacity, new.agreed_authority
      from public.client_people p where p.id = new.person_id and p.client_id = new.client_id;
    if not found then
      raise exception 'Choose one of the client''s contacts or representatives.';
    end if;
  end if;
  if new.document_id is not null and not exists (select 1 from public.client_documents d where d.id = new.document_id and d.client_id = new.client_id) then
    raise exception 'That document belongs to another client.';
  end if;
  if new.agreed_on > (now() at time zone 'Australia/Sydney')::date then
    raise exception 'The agreement date can''t be in the future.';
  end if;
  new.recorded_by := auth.uid();
  new.recorded_at := now();
  return new;
end;
$$;

-- 5. Worker instructions added from an approved plan (once per item).
alter table public.client_worker_instructions
  add column if not exists source_plan_id uuid references public.client_care_plans (id),
  add column if not exists source_item_id uuid references public.client_care_plan_items (id),
  add column if not exists added_by uuid,
  add column if not exists added_at timestamptz;
create unique index if not exists client_worker_instructions_one_per_item on public.client_worker_instructions (source_item_id) where source_item_id is not null;
create or replace function public.guard_instruction_source() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'UPDATE' then
    if (new.source_plan_id, new.source_item_id, new.added_by, new.added_at) is distinct from (old.source_plan_id, old.source_item_id, old.added_by, old.added_at) then
      raise exception 'Where an instruction came from isn''t changed.';
    end if;
    return new;
  end if;
  if new.source_item_id is null then
    new.source_plan_id := null; new.added_by := null; new.added_at := null;
    return new;
  end if;
  if not exists (select 1 from public.client_care_plan_items i join public.client_care_plans p on p.id = i.plan_id
                  where i.id = new.source_item_id and i.section = 'instruction' and p.status = 'current' and p.client_id = new.client_id) then
    raise exception 'Only an instruction on this client''s approved care plan can be added.';
  end if;
  new.source_plan_id := (select plan_id from public.client_care_plan_items where id = new.source_item_id);
  new.added_by := auth.uid();
  new.added_at := now();
  return new;
end;
$$;

-- 6. Funding comparison, per service. A funding record "covers" the budget when
-- its period starts on or before the budget's start and ends on or after the
-- budget's end; any other overlap is "partial" (shown, never counted); records
-- that don't overlap at all are left out. Amounts are the funding record's own
-- figures for its whole period: nothing is prorated.
create or replace function public.budget_funding(p_proposal uuid)
returns table (service_id uuid, service_label text, estimated_cost numeric, funding_id uuid, funding_start date, funding_end date,
               total numeric, used numeric, remaining numeric, fit text)
language sql stable set search_path = '' as $$
  with b as (select * from public.client_budget_proposals where id = p_proposal),
  costs as (
    select l.service_id, sum(l.estimated_cost) as cost from public.client_budget_lines l join b on b.id = l.proposal_id group by l.service_id
  )
  select c.service_id, s.label, c.cost, f.id, f.period_start, f.period_end, f.total_amount, f.used_amount,
         case when f.id is not null then greatest(f.total_amount - f.used_amount, 0) end,
         case when f.id is null then 'none'
              when f.period_start <= b.period_start and f.period_end >= b.period_end then 'covers'
              else 'partial' end
    from costs c cross join b
    left join public.client_services s on s.id = c.service_id
    left join public.client_funding f on f.service_id = c.service_id and f.client_id = b.client_id and f.status = 'active'
         and f.period_start <= b.period_end and f.period_end >= b.period_start
$$;

-- 7. Generation from a completed assessment (one step, as the person).
create or replace function public.generate_care_documents(p_assessment uuid) returns jsonb
language plpgsql set search_path = '' as $$
declare
  a public.client_assessments;
  v_name text;
  v_ver integer;
  v_care uuid;
  v_support uuid;
  v_budget uuid;
  v_made text[] := '{}';
  f record;
  n integer := 0;
begin
  select * into a from public.client_assessments where id = p_assessment;
  if a.id is null or a.status <> 'completed' then
    raise exception 'Drafts are made from a completed assessment.';
  end if;
  if public.from_portal() and not public.care_doc_reach('clients.care_plans', 'edit', a.client_id) then
    raise exception 'You can''t make care plans for this client.';
  end if;
  select t.name, v.version into v_name, v_ver from public.assessment_versions v join public.assessment_templates t on t.id = v.template_id where v.id = a.version_id;

  -- Care plan (left alone if one from this assessment already exists and isn't superseded).
  select id into v_care from public.client_care_plans where source_assessment_id = a.id and status <> 'archived' order by created_at limit 1;
  if v_care is null then
    insert into public.client_care_plans (client_id, title, assessed_on, summary, enrolment_id, source_assessment_id)
    values (a.client_id, left('Care plan from ' || v_name || ' v' || v_ver, 120), a.assessed_on, '', a.enrolment_id, a.id)
    returning id into v_care;
    for f in select * from public.assessment_findings where assessment_id = a.id and state = 'active' order by created_at loop
      n := n + 1;
      if f.kind = 'goal' then
        insert into public.client_care_goals (plan_id, client_id, goal, measure, sort_order, source_finding_id)
        values (v_care, a.client_id, left(f.text, 500), '', n, f.id);
      elsif f.kind <> 'frequency' then
        insert into public.client_care_plan_items (plan_id, client_id, section, text, detail, source_finding_id, sort_order)
        values (v_care, a.client_id,
                case f.kind when 'need' then 'need' when 'risk' then 'risk' when 'intervention' then 'intervention' when 'preference' then 'preference' else 'requirement' end,
                f.text, f.detail, f.id, n);
      end if;
    end loop;
    v_made := v_made || 'care plan'::text;
  end if;

  -- Support plan.
  select id into v_support from public.client_support_plans where source_assessment_id = a.id and status <> 'superseded' order by created_at limit 1;
  if v_support is null then
    insert into public.client_support_plans (client_id, enrolment_id, source_assessment_id, title)
    values (a.client_id, a.enrolment_id, a.id, left('Support plan from ' || v_name || ' v' || v_ver, 120))
    returning id into v_support;
    n := 0;
    for f in select * from public.assessment_findings where assessment_id = a.id and state = 'active'
              and kind in ('support', 'intervention', 'frequency', 'equipment', 'preference') order by created_at loop
      n := n + 1;
      insert into public.client_support_plan_lines (plan_id, client_id, support, frequency, instructions, source_finding_id, sort_order)
      values (v_support, a.client_id,
              case f.kind when 'frequency' then 'How often support is needed' when 'preference' then 'Preference' else left(f.text, 500) end,
              case when f.kind = 'frequency' then left(f.text, 200) else '' end,
              case when f.kind = 'preference' then left(f.text, 2000) else '' end,
              f.id, n);
    end loop;
    v_made := v_made || 'support plan'::text;
  end if;

  -- Proposed budget (from the support plan's support lines; hours and rates left blank).
  select id into v_budget from public.client_budget_proposals where source_assessment_id = a.id and status <> 'superseded' order by created_at limit 1;
  if v_budget is null then
    insert into public.client_budget_proposals (client_id, enrolment_id, support_plan_id, source_assessment_id, title, period_start, period_end)
    values (a.client_id, a.enrolment_id, v_support, a.id, left('Proposed budget from ' || v_name || ' v' || v_ver, 120),
            (now() at time zone 'Australia/Sydney')::date, (now() at time zone 'Australia/Sydney')::date + 90)
    returning id into v_budget;
    insert into public.client_budget_lines (proposal_id, client_id, service_id, description, source_line_id, sort_order)
    select v_budget, a.client_id, l.service_id, l.support, l.id, l.sort_order
      from public.client_support_plan_lines l
      join public.assessment_findings fi on fi.id = l.source_finding_id
     where l.plan_id = v_support and fi.kind in ('support', 'intervention', 'equipment');
    v_made := v_made || 'proposed budget'::text;
  end if;

  return jsonb_build_object('care_plan', v_care, 'support_plan', v_support, 'budget', v_budget, 'made', to_jsonb(v_made));
end;
$$;
revoke execute on function public.generate_care_documents(uuid) from public, anon;
grant execute on function public.generate_care_documents(uuid) to authenticated;

-- 8. Read and change rules: the same reach as care plans (all clients, or the
-- clients someone is assigned to); budgets follow Funding.
do $$
declare
  t text;
  m text;
begin
  foreach t in array array['client_care_plan_items', 'client_support_plans', 'client_support_plan_lines', 'client_plan_agreements', 'client_budget_proposals', 'client_budget_lines'] loop
    m := case when t in ('client_budget_proposals', 'client_budget_lines') then 'clients.funding' else 'clients.care_plans' end;
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "see %s" on public.%I', t, t);
    execute format('create policy "see %s" on public.%I for select to authenticated using (public.care_doc_reach(%L, ''view'', client_id))', t, t, m);
    execute format('drop policy if exists "add %s" on public.%I', t, t);
    execute format('create policy "add %s" on public.%I for insert to authenticated with check (public.care_doc_reach(%L, ''edit'', client_id))', t, t, m);
    execute format('drop policy if exists "change %s" on public.%I', t, t);
    -- Reviewing (approve right) is a change too; the checks decide what each person may do.
    execute format('create policy "change %s" on public.%I for update to authenticated using (public.care_doc_reach(%L, ''edit'', client_id) or public.care_doc_reach(%L, ''approve'', client_id)) with check (public.care_doc_reach(%L, ''edit'', client_id) or public.care_doc_reach(%L, ''approve'', client_id))', t, t, m, m, m, m);
    execute format('grant select, insert, update on public.%I to authenticated', t);
    execute format('revoke all on public.%I from anon', t);
  end loop;
  foreach t in array array['client_care_plan_items', 'client_support_plan_lines', 'client_budget_lines'] loop
    execute format('drop policy if exists "remove draft %s" on public.%I', t, t);
    m := case when t = 'client_budget_lines' then 'clients.funding' else 'clients.care_plans' end;
    execute format('create policy "remove draft %s" on public.%I for delete to authenticated using (public.care_doc_reach(%L, ''edit'', client_id))', t, t, m);
    execute format('grant delete on public.%I to authenticated', t);
  end loop;
end $$;
-- Approvers can review care plans (the existing "change" rule needs edit).
drop policy if exists "approvers review care plans" on public.client_care_plans;
create policy "approvers review care plans" on public.client_care_plans for update to authenticated
  using (public.care_doc_reach('clients.care_plans', 'approve', client_id)) with check (public.care_doc_reach('clients.care_plans', 'approve', client_id));

-- 9. Triggers.
drop trigger if exists guard_care_document on public.client_support_plans;
create trigger guard_care_document before insert or update or delete on public.client_support_plans for each row execute function public.guard_care_document();
drop trigger if exists guard_care_document on public.client_budget_proposals;
create trigger guard_care_document before insert or update or delete on public.client_budget_proposals for each row execute function public.guard_care_document();
do $$
declare t text;
begin
  foreach t in array array['client_care_plan_items', 'client_support_plan_lines', 'client_budget_lines'] loop
    execute format('drop trigger if exists guard_care_line on public.%I', t);
    execute format('create trigger guard_care_line before insert or update or delete on public.%I for each row execute function public.guard_care_line()', t);
  end loop;
  foreach t in array array['client_care_plan_items', 'client_support_plans', 'client_support_plan_lines', 'client_budget_proposals', 'client_budget_lines', 'client_plan_agreements'] loop
    execute format('drop trigger if exists log_client_change on public.%I', t);
    execute format('create trigger log_client_change before insert or update on public.%I for each row execute function public.log_client_change()', t);
    execute format('drop trigger if exists log_client_audit on public.%I', t);
    execute format('create trigger log_client_audit after insert or update or delete on public.%I for each row execute function public.log_client_change()', t);
  end loop;
end $$;
drop trigger if exists guard_plan_agreement on public.client_plan_agreements;
create trigger guard_plan_agreement before insert or update or delete on public.client_plan_agreements for each row execute function public.guard_plan_agreement();
drop trigger if exists guard_instruction_source on public.client_worker_instructions;
create trigger guard_instruction_source before insert or update on public.client_worker_instructions for each row execute function public.guard_instruction_source();
-- Care plans and goals were already in the audit trail; removals of care plan goals aren't allowed (no delete rule).

revoke execute on function public.guard_care_document() from public, anon, authenticated;
revoke execute on function public.guard_care_line() from public, anon, authenticated;
revoke execute on function public.guard_plan_agreement() from public, anon, authenticated;
revoke execute on function public.guard_instruction_source() from public, anon, authenticated;
