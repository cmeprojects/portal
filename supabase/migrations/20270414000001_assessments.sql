-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 159): assessments (Phase 2 of the programs, assessments
-- and billing plan, approved 21 Nov 2026).
--   * Templates with versions. A published version, its sections, questions,
--     options, "show only when" rules and finding mappings can never change;
--     changes go into a new version (a copy). Every assessment keeps the exact
--     version it was answered against.
--   * Client assessments: draft -> completed (or cancelled with a reason).
--     A completed assessment never changes; a correction or reassessment is a
--     new assessment that replaces it, and the old one becomes "superseded".
--   * Structured findings (needs, goals, risks ...) made from mapped answers,
--     kept apart from the answers. Saving again never duplicates them; one
--     answer can make several; assessors add their own; a finding that no
--     longer applies is withdrawn (kept), an edited one is flagged instead.
--     Findings are fixed once the assessment is completed.
--   * Answers reused from an earlier assessment only where the question key and
--     type match; they must be confirmed before completing.
--   * Checks run in the database (as the person), so direct requests follow the
--     same rules. No new security definer function. Nothing is deleted except
--     unpublished draft template parts.
--   * Access: "Assessments" (clients.assessments) with the same defaults and
--     reach as care plans; templates by Manager Administrators and the care
--     settings area. No support worker or practitioner access.
--   * Viewing an assessment is recorded once an hour per person; printing is
--     recorded every time. Changes are in the client audit trail.
-- Safe to run again.

-- 1. Templates and versions.
create table if not exists public.assessment_templates (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  name text not null check (length(trim(name)) between 1 and 120),
  description text not null default '' check (length(description) <= 1000),
  schemes text[] not null default '{}', -- empty = common to all programs
  active boolean not null default true,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.assessment_versions (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  template_id uuid not null references public.assessment_templates (id),
  version integer not null check (version >= 1),
  status text not null default 'draft' check (status in ('draft', 'published', 'retired')),
  effective_from date,
  published_by uuid,
  published_at timestamptz,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  unique (template_id, version)
);
create unique index if not exists assessment_versions_one_draft on public.assessment_versions (template_id) where status = 'draft';
create table if not exists public.assessment_sections (
  id uuid primary key default gen_random_uuid(),
  version_id uuid not null references public.assessment_versions (id) on delete cascade,
  title text not null check (length(trim(title)) between 1 and 120),
  sort_order integer not null default 0,
  enabled boolean not null default true,
  rule jsonb
);
create table if not exists public.assessment_questions (
  id uuid primary key default gen_random_uuid(),
  version_id uuid not null references public.assessment_versions (id) on delete cascade,
  section_id uuid not null references public.assessment_sections (id) on delete cascade,
  key text not null check (key ~ '^[a-z][a-z0-9_]{0,59}$'),
  label text not null check (length(trim(label)) between 1 and 300),
  type text not null check (type in ('text', 'long', 'choice', 'multi', 'yesno', 'date', 'number')),
  required boolean not null default false,
  help text not null default '' check (length(help) <= 300),
  options jsonb not null default '[]' check (jsonb_typeof(options) = 'array'),
  validation jsonb not null default '{}' check (jsonb_typeof(validation) = 'object'),
  rule jsonb,
  mappings jsonb not null default '[]' check (jsonb_typeof(mappings) = 'array'),
  sort_order integer not null default 0,
  unique (version_id, key)
);
create index if not exists assessment_questions_version on public.assessment_questions (version_id, sort_order);

-- 2. Client assessments and findings.
create table if not exists public.client_assessments (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id),
  enrolment_id uuid references public.client_enrolments (id),
  template_id uuid not null references public.assessment_templates (id),
  version_id uuid not null references public.assessment_versions (id),
  status text not null default 'draft' check (status in ('draft', 'completed', 'superseded', 'cancelled')),
  assessed_on date not null default ((now() at time zone 'Australia/Sydney')::date),
  answers jsonb not null default '{}' check (jsonb_typeof(answers) = 'object'),
  reused jsonb not null default '{}' check (jsonb_typeof(reused) = 'object'),
  replaces_id uuid references public.client_assessments (id),
  replaced_by uuid references public.client_assessments (id),
  started_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  completed_by uuid,
  completed_at timestamptz,
  cancelled_by uuid,
  cancelled_at timestamptz,
  cancel_reason text not null default '' check (length(cancel_reason) <= 300),
  updated_by uuid,
  updated_at timestamptz not null default now()
);
create index if not exists client_assessments_client on public.client_assessments (client_id, created_at desc);
create table if not exists public.assessment_findings (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  assessment_id uuid not null references public.client_assessments (id),
  client_id uuid not null references public.car_clients (id),
  kind text not null check (kind in ('need', 'goal', 'risk', 'limitation', 'support', 'intervention', 'frequency', 'equipment', 'preference')),
  text text not null check (length(trim(text)) between 1 and 1000),
  detail text not null default '' check (length(detail) <= 2000),
  origin text not null default 'manual' check (origin in ('manual', 'mapped')),
  source_key text,
  mapping_no integer,
  source_answer text,
  state text not null default 'active' check (state in ('active', 'withdrawn', 'answer_changed')),
  edited boolean not null default false,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now()
);
create unique index if not exists assessment_findings_one_per_mapping on public.assessment_findings (assessment_id, source_key, mapping_no) where origin = 'mapped';
create index if not exists assessment_findings_assessment on public.assessment_findings (assessment_id);

-- 3. Rules: "show only when". A rule is {"match": "all" | "any", "when": [condition, ...]};
-- a condition is {"q": key, "op": is | is_not | in | answered | not_answered | gt | lt, "value": ...}.
create or replace function public.assessment_condition_ok(p_cond jsonb, p_answer jsonb) returns boolean
language plpgsql immutable set search_path = '' as $$
declare
  v_op text := p_cond ->> 'op';
  v_val jsonb := p_cond -> 'value';
  v_answered boolean := p_answer is not null and p_answer <> 'null'::jsonb and p_answer <> '""'::jsonb and p_answer <> '[]'::jsonb;
  v_text text := case when jsonb_typeof(p_answer) = 'string' then p_answer #>> '{}' when jsonb_typeof(p_answer) = 'number' then p_answer::text end;
begin
  if v_op = 'answered' then return v_answered; end if;
  if v_op = 'not_answered' then return not v_answered; end if;
  if not v_answered then return false; end if;
  if v_op in ('is', 'is_not') then
    return (v_op = 'is') = (case when jsonb_typeof(p_answer) = 'array' then p_answer ? (v_val #>> '{}') else v_text = (v_val #>> '{}') end);
  elsif v_op = 'in' then
    if jsonb_typeof(v_val) <> 'array' then return false; end if;
    return case when jsonb_typeof(p_answer) = 'array' then p_answer ?| array(select jsonb_array_elements_text(v_val)) else v_val ? v_text end;
  elsif v_op in ('gt', 'lt') then
    if v_text !~ '^-?\d+(\.\d+)?$' or (v_val #>> '{}') !~ '^-?\d+(\.\d+)?$' then return false; end if;
    return case when v_op = 'gt' then v_text::numeric > (v_val #>> '{}')::numeric else v_text::numeric < (v_val #>> '{}')::numeric end;
  end if;
  return false;
end;
$$;

create or replace function public.assessment_rule_ok(p_rule jsonb, p_answers jsonb) returns boolean
language sql immutable set search_path = '' as $$
  select case
    when p_rule is null or p_rule = 'null'::jsonb or coalesce(jsonb_array_length(p_rule -> 'when'), 0) = 0 then true
    when coalesce(p_rule ->> 'match', 'all') = 'any' then
      exists (select 1 from jsonb_array_elements(p_rule -> 'when') c where public.assessment_condition_ok(c, p_answers -> (c ->> 'q')))
    else
      not exists (select 1 from jsonb_array_elements(p_rule -> 'when') c where not public.assessment_condition_ok(c, p_answers -> (c ->> 'q')))
  end
$$;

-- Is this question showing, given the answers?
create or replace function public.assessment_question_visible(p_question uuid, p_answers jsonb) returns boolean
language sql stable set search_path = '' as $$
  select s.enabled and public.assessment_rule_ok(s.rule, p_answers) and public.assessment_rule_ok(q.rule, p_answers)
    from public.assessment_questions q join public.assessment_sections s on s.id = q.section_id
   where q.id = p_question
$$;

-- What's wrong with one answer (null when it's fine).
create or replace function public.assessment_answer_problem(p_type text, p_options jsonb, p_validation jsonb, p_label text, p_value jsonb) returns text
language plpgsql immutable set search_path = '' as $$
declare
  v_text text;
begin
  if p_value is null or p_value = 'null'::jsonb or p_value = '""'::jsonb or p_value = '[]'::jsonb then
    return null;
  end if;
  if p_type = 'multi' then
    if jsonb_typeof(p_value) <> 'array' then return p_label || ': choose from the list.'; end if;
    if exists (select 1 from jsonb_array_elements_text(p_value) x where not p_options ? x) then return p_label || ': choose from the list.'; end if;
    return null;
  end if;
  if jsonb_typeof(p_value) not in ('string', 'number') then return p_label || ': that answer isn''t valid.'; end if;
  v_text := case when jsonb_typeof(p_value) = 'string' then p_value #>> '{}' else p_value::text end;
  if p_type = 'text' and length(v_text) > 300 then return p_label || ': keep it under 300 characters.'; end if;
  if p_type = 'long' and length(v_text) > 5000 then return p_label || ': keep it under 5,000 characters.'; end if;
  if p_type = 'yesno' and v_text not in ('Yes', 'No') then return p_label || ': answer Yes or No.'; end if;
  if p_type = 'choice' and not p_options ? v_text then return p_label || ': choose from the list.'; end if;
  if p_type = 'date' then
    if v_text !~ '^\d{4}-\d{2}-\d{2}$' then return p_label || ': enter a date.'; end if;
    begin
      perform v_text::date;
    exception when others then
      return p_label || ': enter a real date.';
    end;
  end if;
  if p_type = 'number' then
    if v_text !~ '^-?\d+(\.\d+)?$' then return p_label || ': enter a number.'; end if;
    if p_validation ? 'min' and v_text::numeric < (p_validation ->> 'min')::numeric then return p_label || ': the lowest is ' || (p_validation ->> 'min') || '.'; end if;
    if p_validation ? 'max' and v_text::numeric > (p_validation ->> 'max')::numeric then return p_label || ': the highest is ' || (p_validation ->> 'max') || '.'; end if;
  end if;
  if p_type in ('text', 'long') and p_validation ? 'pattern' and v_text !~ (p_validation ->> 'pattern') then
    return p_label || ': ' || coalesce(p_validation ->> 'pattern_hint', 'that answer isn''t in the expected format.');
  end if;
  return null;
end;
$$;

-- Everything that stops an assessment being completed (empty = ready).
create or replace function public.assessment_check(p_assessment uuid) returns text[]
language sql stable set search_path = '' as $$
  with a as (select * from public.client_assessments where id = p_assessment),
  q as (
    select q.*, s.sort_order as s_sort, public.assessment_question_visible(q.id, a.answers) as visible, a.answers -> q.key as answer, a.reused -> q.key as reuse
      from a join public.assessment_questions q on q.version_id = a.version_id join public.assessment_sections s on s.id = q.section_id
  )
  select coalesce(array_agg(msg order by s_sort, sort_order), '{}') from (
    select q.s_sort, q.sort_order, q.label || ' needs an answer.' as msg from q
     where q.visible and q.required and (q.answer is null or q.answer in ('null'::jsonb, '""'::jsonb, '[]'::jsonb))
    union all
    select q.s_sort, q.sort_order, 'Confirm the reused answer for ' || q.label || '.' from q
     where q.visible and q.reuse is not null and coalesce((q.reuse ->> 'confirmed')::boolean, false) = false
    union all
    select q.s_sort, q.sort_order, public.assessment_answer_problem(q.type, q.options, q.validation, q.label, q.answer) from q
     where q.visible and public.assessment_answer_problem(q.type, q.options, q.validation, q.label, q.answer) is not null
  ) m
$$;

-- 4. Template rules: only drafts change; publishing checks the version.
create or replace function public.guard_assessment_template() returns trigger
language plpgsql set search_path = '' as $$
begin
  if exists (select 1 from unnest(new.schemes) s where not exists (select 1 from public.client_schemes c where c.key = s)) then
    raise exception 'Choose schemes from the list.';
  end if;
  if tg_op = 'UPDATE' and new.created_by is distinct from old.created_by then
    raise exception 'Who made a template stays as it was.';
  end if;
  new.updated_at := now();
  return new;
end;
$$;

create or replace function public.guard_assessment_version() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_bad text;
begin
  if tg_op = 'DELETE' then
    raise exception 'A version is never deleted.';
  end if;
  if tg_op = 'INSERT' then
    if new.status <> 'draft' and public.from_portal() then
      raise exception 'A new version starts as a draft.';
    end if;
    new.version := coalesce((select max(v.version) from public.assessment_versions v where v.template_id = new.template_id), 0) + 1;
    return new;
  end if;
  if (new.template_id, new.version, new.created_by, new.created_at) is distinct from (old.template_id, old.version, old.created_by, old.created_at) then
    raise exception 'A version stays with its template.';
  end if;
  if old.status = 'retired' then
    raise exception 'A retired version stays retired.';
  end if;
  if old.status = 'published' then
    if new.status = 'retired' and (new.effective_from, new.published_by, new.published_at) is not distinct from (old.effective_from, old.published_by, old.published_at) then
      return new;
    end if;
    raise exception 'A published version can''t be changed. Make a new version instead.';
  end if;
  if new.status = 'retired' then
    raise exception 'Publish a version before retiring it.';
  end if;
  if new.status = 'published' then
    new.effective_from := coalesce(new.effective_from, (now() at time zone 'Australia/Sydney')::date);
    new.published_by := auth.uid();
    new.published_at := now();
    if not exists (select 1 from public.assessment_questions q where q.version_id = new.id) then
      raise exception 'Add at least one question before publishing.';
    end if;
    -- Choices need options; mappings and rules must be valid; rules look only at earlier questions.
    select string_agg(msg, ' ') into v_bad from (
      select q.label || ': add the options.' as msg from public.assessment_questions q
       where q.version_id = new.id and q.type in ('choice', 'multi') and jsonb_array_length(q.options) = 0
      union all
      select q.label || ': a finding has an unknown kind or wording missing.' from public.assessment_questions q, jsonb_array_elements(q.mappings) m
       where q.version_id = new.id and (not (m ->> 'kind') = any (array['need', 'goal', 'risk', 'limitation', 'support', 'intervention', 'frequency', 'equipment', 'preference'])
                                         or length(trim(coalesce(m ->> 'text', ''))) = 0)
      union all
      select q.label || ': "show only when" must look at an earlier question.' from public.assessment_questions q
        join public.assessment_sections s on s.id = q.section_id, jsonb_array_elements(coalesce(q.rule -> 'when', '[]')) c
       where q.version_id = new.id and not exists (
         select 1 from public.assessment_questions p join public.assessment_sections ps on ps.id = p.section_id
          where p.version_id = new.id and p.key = c ->> 'q' and (ps.sort_order, p.sort_order) < (s.sort_order, q.sort_order))
      union all
      select s.title || ': "show only when" must look at a question in an earlier section.' from public.assessment_sections s, jsonb_array_elements(coalesce(s.rule -> 'when', '[]')) c
       where s.version_id = new.id and not exists (
         select 1 from public.assessment_questions p join public.assessment_sections ps on ps.id = p.section_id
          where p.version_id = new.id and p.key = c ->> 'q' and ps.sort_order < s.sort_order)
    ) b;
    if v_bad is not null then
      raise exception 'Can''t publish yet: %', v_bad;
    end if;
    -- The earlier published version is retired.
    update public.assessment_versions set status = 'retired' where template_id = new.template_id and status = 'published' and id <> new.id;
  end if;
  return new;
end;
$$;

create or replace function public.guard_assessment_part() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_version uuid := case when tg_op = 'DELETE' then old.version_id else new.version_id end;
begin
  if (select status from public.assessment_versions where id = v_version) <> 'draft'
     or (tg_op = 'UPDATE' and old.version_id is distinct from new.version_id) then
    raise exception 'A published version can''t be changed. Make a new version instead.';
  end if;
  if tg_op = 'DELETE' then
    return old;
  end if;
  if tg_table_name = 'assessment_questions' and (select version_id from public.assessment_sections where id = (to_jsonb(new) ->> 'section_id')::uuid) is distinct from new.version_id then
    raise exception 'That section belongs to another version.';
  end if;
  return new;
end;
$$;

-- A new draft version copied from the latest one (runs as the person).
create or replace function public.assessment_new_version(p_template uuid) returns uuid
language plpgsql set search_path = '' as $$
declare
  v_from uuid := (select id from public.assessment_versions where template_id = p_template order by version desc limit 1);
  v_new uuid;
  s record;
  v_sec uuid;
begin
  if exists (select 1 from public.assessment_versions where template_id = p_template and status = 'draft') then
    raise exception 'This template already has a draft. Edit that one.';
  end if;
  insert into public.assessment_versions (template_id) values (p_template) returning id into v_new;
  for s in select * from public.assessment_sections where version_id = v_from order by sort_order loop
    insert into public.assessment_sections (version_id, title, sort_order, enabled, rule) values (v_new, s.title, s.sort_order, s.enabled, s.rule) returning id into v_sec;
    insert into public.assessment_questions (version_id, section_id, key, label, type, required, help, options, validation, rule, mappings, sort_order)
    select v_new, v_sec, q.key, q.label, q.type, q.required, q.help, q.options, q.validation, q.rule, q.mappings, q.sort_order
      from public.assessment_questions q where q.section_id = s.id;
  end loop;
  return v_new;
end;
$$;
revoke execute on function public.assessment_new_version(uuid) from public, anon;
grant execute on function public.assessment_new_version(uuid) to authenticated;

-- 5. Assessment rules.
create or replace function public.guard_client_assessment() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_api boolean := public.from_portal();
  v_tpl public.assessment_templates;
  v_problems text[];
  v_key text;
  v_q public.assessment_questions;
  v_from public.client_assessments;
begin
  if tg_op = 'DELETE' then
    raise exception 'An assessment is never deleted. Cancel it instead.';
  end if;
  if tg_op = 'INSERT' then
    select * into v_tpl from public.assessment_templates where id = new.template_id;
    if (select v.template_id from public.assessment_versions v where v.id = new.version_id and v.status = 'published') is distinct from new.template_id then
      raise exception 'Choose a published assessment.';
    end if;
    if v_api and not v_tpl.active then
      raise exception 'That assessment isn''t in use any more.';
    end if;
    if new.enrolment_id is not null and not exists (select 1 from public.client_enrolments e where e.id = new.enrolment_id and e.client_id = new.client_id and e.status <> 'ended') then
      raise exception 'Choose one of the client''s open programs.';
    end if;
    if cardinality(v_tpl.schemes) > 0 and not exists (
         select 1 from public.client_enrolments e where e.id = new.enrolment_id and e.scheme = any (v_tpl.schemes)) then
      raise exception '% is for % clients. Choose the program it''s for.', v_tpl.name, array_to_string(v_tpl.schemes, ', ');
    end if;
    if new.replaces_id is not null and not exists (
         select 1 from public.client_assessments r where r.id = new.replaces_id and r.client_id = new.client_id and r.status = 'completed') then
      raise exception 'Only a completed assessment of this client can be replaced.';
    end if;
    if v_api then
      new.status := 'draft';
      new.started_by := auth.uid();
      new.created_at := now();
      new.replaced_by := null;
      new.completed_by := null; new.completed_at := null; new.cancelled_by := null; new.cancelled_at := null; new.cancel_reason := '';
    end if;
  else
    if (new.client_id, new.enrolment_id, new.template_id, new.version_id, new.replaces_id, new.started_by, new.created_at)
       is distinct from (old.client_id, old.enrolment_id, old.template_id, old.version_id, old.replaces_id, old.started_by, old.created_at) then
      raise exception 'An assessment stays with its client, program and version.';
    end if;
    if old.status = 'completed' then
      -- The only change: replaced by a newer completed assessment.
      if new.status = 'superseded' and new.replaced_by is not null and old.replaced_by is null
         and (new.answers, new.reused, new.assessed_on, new.completed_by, new.completed_at) is not distinct from (old.answers, old.reused, old.assessed_on, old.completed_by, old.completed_at)
         and exists (select 1 from public.client_assessments r where r.id = new.replaced_by and r.replaces_id = new.id and r.status = 'completed') then
        return new;
      end if;
      raise exception 'A completed assessment can''t be changed. Start a new assessment from it instead.';
    end if;
    if old.status in ('superseded', 'cancelled') then
      raise exception 'This assessment is %, so it can''t be changed.', old.status;
    end if;
    if new.replaced_by is distinct from old.replaced_by then
      raise exception 'Only a completed assessment can be replaced.';
    end if;
  end if;

  -- Answers: known questions, right type. Reused answers: same key and type as before.
  for v_key in select jsonb_object_keys(new.answers) loop
    select * into v_q from public.assessment_questions where version_id = new.version_id and key = v_key;
    if v_q.id is null then
      raise exception 'There''s no question "%" in this assessment.', v_key;
    end if;
    if public.assessment_answer_problem(v_q.type, v_q.options, v_q.validation, v_q.label, new.answers -> v_key) is not null then
      raise exception '%', public.assessment_answer_problem(v_q.type, v_q.options, v_q.validation, v_q.label, new.answers -> v_key);
    end if;
  end loop;
  if tg_op = 'INSERT' or new.reused is distinct from old.reused then
    for v_key in select jsonb_object_keys(new.reused) loop
      if tg_op = 'UPDATE' and old.reused ? v_key and (old.reused -> v_key -> 'from') = (new.reused -> v_key -> 'from') then
        continue; -- only the confirmation changed
      end if;
      if tg_op = 'UPDATE' then
        raise exception 'Answers can only be reused when the assessment is started.';
      end if;
      select * into v_from from public.client_assessments where id = (new.reused -> v_key ->> 'from')::uuid;
      if v_from.id is null or v_from.client_id <> new.client_id or v_from.status not in ('completed', 'superseded') then
        raise exception 'Answers can only be reused from this client''s completed assessments.';
      end if;
      if not exists (select 1 from public.assessment_questions a join public.assessment_questions b on b.key = a.key and b.type = a.type
                      where a.version_id = new.version_id and b.version_id = v_from.version_id and a.key = v_key) then
        raise exception 'The answer to "%" can''t be reused: the question isn''t the same kind.', v_key;
      end if;
    end loop;
  end if;
  if tg_op = 'UPDATE' then
    for v_key in select jsonb_object_keys(old.reused) loop
      if not new.reused ? v_key then
        raise exception 'A reused answer stays marked as reused.';
      end if;
    end loop;
  end if;

  if tg_op = 'UPDATE' and new.status <> old.status then
    if new.status = 'completed' then
      -- Checked against the new answers, not the saved ones.
      select coalesce(array_agg(msg), '{}') into v_problems from (
        select q.label || ' needs an answer.' as msg
          from public.assessment_questions q join public.assessment_sections s on s.id = q.section_id
         where q.version_id = new.version_id and q.required
           and s.enabled and public.assessment_rule_ok(s.rule, new.answers) and public.assessment_rule_ok(q.rule, new.answers)
           and (new.answers -> q.key is null or new.answers -> q.key in ('null'::jsonb, '""'::jsonb, '[]'::jsonb))
        union all
        select 'Confirm the reused answer for ' || q.label || '.'
          from public.assessment_questions q join public.assessment_sections s on s.id = q.section_id
         where q.version_id = new.version_id and new.reused ? q.key and coalesce((new.reused -> q.key ->> 'confirmed')::boolean, false) = false
           and s.enabled and public.assessment_rule_ok(s.rule, new.answers) and public.assessment_rule_ok(q.rule, new.answers)
        union all
        select 'Check the finding "' || left(f.text, 60) || '": its answer changed.'
          from public.assessment_findings f where f.assessment_id = new.id and f.state = 'answer_changed'
      ) m;
      if cardinality(v_problems) > 0 then
        raise exception 'Not ready to complete: %', array_to_string(v_problems, ' ');
      end if;
      new.completed_by := auth.uid();
      new.completed_at := now();
    elsif new.status = 'cancelled' then
      if length(trim(new.cancel_reason)) = 0 then
        raise exception 'Say why this assessment is cancelled.';
      end if;
      new.cancelled_by := auth.uid();
      new.cancelled_at := now();
    else
      raise exception 'A draft can only be completed or cancelled.';
    end if;
  end if;
  return new;
end;
$$;

-- After a change: keep mapped findings in step with the answers; mark the replaced one superseded.
create or replace function public.sync_assessment() returns trigger
language plpgsql set search_path = '' as $$
declare
  q record;
  m jsonb;
  n integer;
  v_applies boolean;
  v_answer text;
  f public.assessment_findings;
begin
  if tg_op = 'UPDATE' and new.status = 'completed' and old.status = 'draft' and new.replaces_id is not null then
    update public.client_assessments set status = 'superseded', replaced_by = new.id where id = new.replaces_id and status = 'completed';
  end if;
  if new.status <> 'draft' or (tg_op = 'UPDATE' and new.answers is not distinct from old.answers) then
    return null;
  end if;
  perform set_config('portal.findings_sync', 'on', true);
  for q in select aq.*, public.assessment_question_visible(aq.id, new.answers) as visible
             from public.assessment_questions aq where aq.version_id = new.version_id and jsonb_array_length(aq.mappings) > 0 loop
    v_answer := case when jsonb_typeof(new.answers -> q.key) = 'array' then (select string_agg(x, ', ') from jsonb_array_elements_text(new.answers -> q.key) x)
                     else new.answers ->> q.key end;
    n := 0;
    for m in select * from jsonb_array_elements(q.mappings) loop
      n := n + 1;
      v_applies := q.visible and public.assessment_condition_ok(coalesce(m -> 'when', '{"op": "answered"}'::jsonb), new.answers -> q.key);
      select * into f from public.assessment_findings where assessment_id = new.id and origin = 'mapped' and source_key = q.key and mapping_no = n;
      if v_applies then
        if f.id is null then
          insert into public.assessment_findings (assessment_id, client_id, kind, text, origin, source_key, mapping_no, source_answer)
          values (new.id, new.client_id, m ->> 'kind', replace(m ->> 'text', '{answer}', coalesce(v_answer, '')), 'mapped', q.key, n, v_answer);
        elsif not f.edited then
          update public.assessment_findings set kind = m ->> 'kind', text = replace(m ->> 'text', '{answer}', coalesce(v_answer, '')), source_answer = v_answer, state = 'active'
           where id = f.id and (kind, text, source_answer, state) is distinct from (m ->> 'kind', replace(m ->> 'text', '{answer}', coalesce(v_answer, '')), v_answer, 'active');
        elsif f.source_answer is distinct from v_answer then
          update public.assessment_findings set state = 'answer_changed', source_answer = v_answer where id = f.id;
        end if;
      elsif f.id is not null and f.state <> 'withdrawn' then
        update public.assessment_findings set state = case when f.edited then 'answer_changed' else 'withdrawn' end where id = f.id;
      end if;
    end loop;
  end loop;
  perform set_config('portal.findings_sync', '', true);
  return null;
end;
$$;

create or replace function public.guard_assessment_finding() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_sync boolean := coalesce(current_setting('portal.findings_sync', true), '') = 'on';
  v_a public.client_assessments;
begin
  if tg_op = 'DELETE' then
    raise exception 'A finding is never deleted. Withdraw it instead.';
  end if;
  select * into v_a from public.client_assessments where id = new.assessment_id;
  if v_a.status is distinct from 'draft' then
    raise exception 'Findings are fixed once the assessment is completed.';
  end if;
  new.client_id := v_a.client_id;
  if tg_op = 'INSERT' then
    if not v_sync then
      new.origin := 'manual';
      new.source_key := null;
      new.mapping_no := null;
      new.source_answer := null;
      new.state := 'active';
      new.edited := false;
      new.created_by := auth.uid();
    end if;
    return new;
  end if;
  if (new.assessment_id, new.origin, new.source_key, new.mapping_no, new.created_by, new.created_at)
     is distinct from (old.assessment_id, old.origin, old.source_key, old.mapping_no, old.created_by, old.created_at) then
    raise exception 'A finding stays with its assessment and source.';
  end if;
  if not v_sync then
    if new.source_answer is distinct from old.source_answer then
      raise exception 'The answer a finding came from stays as it was.';
    end if;
    if new.origin = 'mapped' and (new.text, new.detail, new.kind) is distinct from (old.text, old.detail, old.kind) then
      new.edited := true;
      if new.state = 'answer_changed' then
        new.state := 'active'; -- checked by the assessor
      end if;
    end if;
    if new.state not in ('active', 'withdrawn') and new.state is distinct from old.state then
      raise exception 'A finding can be active or withdrawn.';
    end if;
  end if;
  return new;
end;
$$;

do $$
declare t text;
begin
  foreach t in array array['assessment_templates', 'assessment_versions', 'assessment_sections', 'assessment_questions'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "staff read assessment templates" on public.%I', t);
    execute format('create policy "staff read assessment templates" on public.%I for select to authenticated using ((select public.is_member()))', t);
    execute format('drop policy if exists "template managers change templates" on public.%I', t);
    execute format('create policy "template managers change templates" on public.%I for all to authenticated using ((select public.can_admin_area(''care'')) or (select public.is_manager_admin())) with check ((select public.can_admin_area(''care'')) or (select public.is_manager_admin()))', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
    execute format('revoke all on public.%I from anon', t);
  end loop;
  foreach t in array array['client_assessments', 'assessment_findings'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "see assessments" on public.%I', t);
    execute format('create policy "see assessments" on public.%I for select to authenticated using (public.can(''clients.assessments'', ''view'', client_id))', t);
    execute format('drop policy if exists "add assessments" on public.%I', t);
    execute format('create policy "add assessments" on public.%I for insert to authenticated with check (public.can(''clients.assessments'', ''edit'', client_id))', t);
    execute format('drop policy if exists "change assessments" on public.%I', t);
    execute format('create policy "change assessments" on public.%I for update to authenticated using (public.can(''clients.assessments'', ''edit'', client_id)) with check (public.can(''clients.assessments'', ''edit'', client_id))', t);
    execute format('grant select, insert, update on public.%I to authenticated', t);
    execute format('revoke all on public.%I from anon', t);
  end loop;
end $$;

drop trigger if exists guard_assessment_template on public.assessment_templates;
create trigger guard_assessment_template before insert or update on public.assessment_templates for each row execute function public.guard_assessment_template();
drop trigger if exists assessment_templates_log on public.assessment_templates;
create trigger assessment_templates_log after insert or update on public.assessment_templates for each row execute function public.log_car_setup('assessment_template');
drop trigger if exists guard_assessment_version on public.assessment_versions;
create trigger guard_assessment_version before insert or update or delete on public.assessment_versions for each row execute function public.guard_assessment_version();
drop trigger if exists assessment_versions_log on public.assessment_versions;
create trigger assessment_versions_log after insert or update on public.assessment_versions for each row execute function public.log_car_setup('assessment_version');
drop trigger if exists guard_assessment_part on public.assessment_sections;
create trigger guard_assessment_part before insert or update or delete on public.assessment_sections for each row execute function public.guard_assessment_part();
drop trigger if exists guard_assessment_part on public.assessment_questions;
create trigger guard_assessment_part before insert or update or delete on public.assessment_questions for each row execute function public.guard_assessment_part();
drop trigger if exists assessment_questions_log on public.assessment_questions;
create trigger assessment_questions_log after insert or update on public.assessment_questions for each row execute function public.log_car_setup('assessment_question');

drop trigger if exists guard_client_assessment on public.client_assessments;
create trigger guard_client_assessment before insert or update or delete on public.client_assessments for each row execute function public.guard_client_assessment();
drop trigger if exists log_client_change on public.client_assessments;
create trigger log_client_change before insert or update on public.client_assessments for each row execute function public.log_client_change();
drop trigger if exists log_client_audit on public.client_assessments;
create trigger log_client_audit after insert or update on public.client_assessments for each row execute function public.log_client_change();
drop trigger if exists sync_assessment on public.client_assessments;
create trigger sync_assessment after insert or update on public.client_assessments for each row execute function public.sync_assessment();

drop trigger if exists guard_assessment_finding on public.assessment_findings;
create trigger guard_assessment_finding before insert or update or delete on public.assessment_findings for each row execute function public.guard_assessment_finding();
drop trigger if exists log_client_change on public.assessment_findings;
create trigger log_client_change before insert or update on public.assessment_findings for each row execute function public.log_client_change();
drop trigger if exists log_client_audit on public.assessment_findings;
create trigger log_client_audit after insert or update on public.assessment_findings for each row execute function public.log_client_change();

revoke execute on function public.guard_assessment_template() from public, anon, authenticated;
revoke execute on function public.guard_assessment_version() from public, anon, authenticated;
revoke execute on function public.guard_assessment_part() from public, anon, authenticated;
revoke execute on function public.guard_client_assessment() from public, anon, authenticated;
revoke execute on function public.sync_assessment() from public, anon, authenticated;
revoke execute on function public.guard_assessment_finding() from public, anon, authenticated;

-- 6. Viewing and printing are recorded.
alter table public.client_staff_views drop constraint if exists client_staff_views_area_check;
alter table public.client_staff_views add constraint client_staff_views_area_check check (area in ('profile', 'audit_trail', 'assessment'));
alter table public.download_log drop constraint if exists download_log_action_check;
alter table public.download_log add constraint download_log_action_check check (action in ('export', 'download_link_issued', 'download_denied', 'print'));

-- 7. Access: "Assessments" (same defaults and reach as care plans) and the templates page.
insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order, actions, grant_ready) values
  ('clients.assessments', 'clients.list', 'clients', 'Assessments', 'sensitive', true, 268, '{view,edit}', true),
  ('system.settings.assessments', 'system.settings', 'system', 'Assessment templates', 'normal', false, 1128, '{view,edit}', false)
on conflict (id) do nothing;
update public.app_modules set status = 'active' where id in ('clients.assessments', 'system.settings.assessments') and status = 'retired'; -- run again after an undo
insert into public.access_baselines (job_title_id, function_group_id, access_level, module_id, actions, scope, effect, note, by_system_admin)
select b.job_title_id, b.function_group_id, b.access_level, 'clients.assessments', b.actions, b.scope, b.effect, 'Assessments default: as for care plans', true
  from public.access_baselines b
 where b.module_id = 'clients.care_plans' and b.revoked_at is null
   and not exists (select 1 from public.access_baselines x where x.module_id = 'clients.assessments' and x.revoked_at is null);

-- 8. A realistic sample template, published (the owner's own templates come later).
do $sample$
declare
  v_t uuid;
  v_v uuid;
  s1 uuid; s2 uuid; s3 uuid; s4 uuid; s5 uuid;
begin
  if exists (select 1 from public.assessment_templates where name = 'Client needs assessment (Sample)') then
    return;
  end if;
  insert into public.assessment_templates (name, description, schemes)
  values ('Client needs assessment (Sample)', 'A sample to show how assessments work: sections, a question that only shows when needed, and findings made from answers. Retire it once your own templates are set up.', '{}')
  returning id into v_t;
  insert into public.assessment_versions (template_id, status) values (v_t, 'draft') returning id into v_v;
  insert into public.assessment_sections (version_id, title, sort_order) values (v_v, 'Living situation', 1) returning id into s1;
  insert into public.assessment_sections (version_id, title, sort_order) values (v_v, 'Daily living', 2) returning id into s2;
  insert into public.assessment_sections (version_id, title, sort_order) values (v_v, 'Mobility and falls', 3) returning id into s3;
  insert into public.assessment_sections (version_id, title, sort_order) values (v_v, 'Health and medicines', 4) returning id into s4;
  insert into public.assessment_sections (version_id, title, sort_order) values (v_v, 'Goals and preferences', 5) returning id into s5;
  insert into public.assessment_questions (version_id, section_id, key, label, type, required, help, options, rule, mappings, sort_order) values
    (v_v, s1, 'lives_alone', 'Do they live alone?', 'yesno', true, '', '[]', null,
     '[{"when": {"op": "is", "value": "Yes"}, "kind": "risk", "text": "Lives alone"}]', 1),
    (v_v, s1, 'checks_in', 'Who checks in on them, and how often?', 'long', true, 'Family, neighbours or services.',
     '[]', '{"match": "all", "when": [{"q": "lives_alone", "op": "is", "value": "Yes"}]}', '[]', 2),
    (v_v, s1, 'home_type', 'Type of home', 'choice', false, '', '["House", "Unit or apartment", "Retirement village", "Other"]', null, '[]', 3),
    (v_v, s2, 'help_with', 'What do they need help with?', 'multi', true, 'Tick all that apply.',
     '["Showering", "Dressing", "Meals", "Cleaning", "Shopping", "Medication", "None of these"]', null,
     '[{"when": {"op": "in", "value": ["Showering", "Dressing"]}, "kind": "need", "text": "Personal care help: {answer}"},
       {"when": {"op": "in", "value": ["Cleaning", "Shopping", "Meals"]}, "kind": "support", "text": "Everyday living help: {answer}"}]', 1),
    (v_v, s2, 'help_hours', 'Hours of help needed each week', 'number', false, '', '[]', null,
     '[{"when": {"op": "answered"}, "kind": "frequency", "text": "About {answer} hours a week"}]', 2),
    (v_v, s3, 'mobility_aid', 'Do they use a mobility aid?', 'choice', true, '', '["No", "Walking stick", "Walking frame", "Wheelchair"]', null,
     '[{"when": {"op": "in", "value": ["Walking stick", "Walking frame", "Wheelchair"]}, "kind": "limitation", "text": "Uses a {answer}"},
       {"when": {"op": "in", "value": ["Walking frame", "Wheelchair"]}, "kind": "equipment", "text": "{answer} (check the home is suitable)"}]', 1),
    (v_v, s3, 'falls', 'Falls in the last 12 months', 'number', true, '', '[]', null,
     '[{"when": {"op": "gt", "value": 0}, "kind": "risk", "text": "{answer} fall(s) in the last 12 months"}]', 2),
    (v_v, s3, 'falls_detail', 'What happened, and was there an injury?', 'long', false, '',
     '[]', '{"match": "all", "when": [{"q": "falls", "op": "gt", "value": 0}]}', '[]', 3),
    (v_v, s4, 'medicines_help', 'Do they need help with medicines?', 'yesno', true, '', '[]', null,
     '[{"when": {"op": "is", "value": "Yes"}, "kind": "intervention", "text": "Medication prompting or support"}]', 1),
    (v_v, s4, 'health_notes', 'Health conditions staff should know about', 'long', false, '', '[]', null, '[]', 2),
    (v_v, s5, 'goal', 'What would they most like to achieve?', 'long', true, 'In their own words.', '[]', null,
     '[{"when": {"op": "answered"}, "kind": "goal", "text": "{answer}"}]', 1),
    (v_v, s5, 'preferences', 'Preferences for how support is given', 'long', false, 'For example: times, a female worker, language.', '[]', null,
     '[{"when": {"op": "answered"}, "kind": "preference", "text": "{answer}"}]', 2);
  update public.assessment_versions set status = 'published', effective_from = date '2026-11-21' where id = v_v;
end
$sample$;
