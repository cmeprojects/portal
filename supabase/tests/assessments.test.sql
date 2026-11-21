-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 159): assessments.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker'), ('cm@example.com', 'Casey', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com'), ('cm@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.cid(p text) returns uuid language sql security definer as $$ select id from public.car_clients where name = p $$;
create function test.tpl(p text) returns uuid language sql security definer as $$ select id from public.assessment_templates where name = p $$;
create function test.ver(p text, v int) returns uuid language sql security definer as $$ select id from public.assessment_versions where template_id = test.tpl(p) and version = v $$;
create function test.a(p_client text, p_status text default 'draft') returns uuid language sql security definer as $$
  select id from public.client_assessments where client_id = test.cid(p_client) and status = p_status order by created_at desc limit 1 $$;
create function test.findings(p_assessment uuid) returns text language sql security definer as $$
  select coalesce(string_agg(kind || ':' || state || case when edited then '*' else '' end, ',' order by source_key nulls last, mapping_no, kind), '') from public.assessment_findings where assessment_id = p_assessment $$;
create function test.n(p_email text, p_sql text) returns bigint language plpgsql as $$
declare v bigint;
begin
  perform test.act_as(p_email);
  execute 'set local role authenticated';
  execute 'select ' || p_sql into v;
  execute 'reset role';
  return v;
end $$;
grant execute on all functions in schema test to authenticated;
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Case Manager') where email = 'cm@example.com';
insert into public.car_clients (name, status) values ('Zara', 'active'), ('Ben', 'active');
insert into public.client_assignments (client_id, user_id) values (test.cid('Zara'), test.pid('cm@example.com'));
select test.act_as('owner@example.com');
set role authenticated;
insert into public.admin_designations (user_id, granted_by) values (test.pid('boss@example.com'), test.pid('owner@example.com'));
reset role;

-- 1. The sample template is published; published versions never change.
select test.ok((select status from public.assessment_versions where id = test.ver('Client needs assessment (Sample)', 1)) = 'published', 'the sample template is published');
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.assessment_questions set label = 'Changed' where key = 'lives_alone'$$, 'a published question can''t be changed');
select test.refused($$delete from public.assessment_questions where key = 'goal'$$, 'or deleted');
select test.refused($$update public.assessment_versions set effective_from = current_date where id = test.ver('Client needs assessment (Sample)', 1)$$, 'or its version');
select test.refused($$delete from public.assessment_versions$$, 'versions are never deleted');
-- A new version is a copy; edit the draft; publishing retires the old one.
select public.assessment_new_version(test.tpl('Client needs assessment (Sample)'));
select test.refused($$select public.assessment_new_version(test.tpl('Client needs assessment (Sample)'))$$, 'one draft at a time');
update public.assessment_questions set label = 'Do they live on their own?' where version_id = test.ver('Client needs assessment (Sample)', 2) and key = 'lives_alone';
update public.assessment_questions set rule = '{"match": "all", "when": [{"q": "goal", "op": "answered"}]}' where version_id = test.ver('Client needs assessment (Sample)', 2) and key = 'home_type';
select test.refused($$update public.assessment_versions set status = 'published' where id = test.ver('Client needs assessment (Sample)', 2)$$, 'a rule must look at an earlier question');
update public.assessment_questions set rule = null where version_id = test.ver('Client needs assessment (Sample)', 2) and key = 'home_type';
update public.assessment_versions set status = 'published' where id = test.ver('Client needs assessment (Sample)', 2);
reset role;
select test.ok((select count(*) from public.assessment_questions where version_id = test.ver('Client needs assessment (Sample)', 2)) = 12, 'the new version copied every question');
select test.ok((select status from public.assessment_versions where id = test.ver('Client needs assessment (Sample)', 1)) = 'retired'
           and (select label from public.assessment_questions where version_id = test.ver('Client needs assessment (Sample)', 1) and key = 'lives_alone') = 'Do they live alone?',
           'publishing retires the old version, which keeps its exact questions');
select test.ok((select count(*) from public.audit_log where entity = 'assessment_version') >= 3, 'template changes are in the change log');

-- A template for one scheme, with a number limit.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.assessment_templates (name, schemes) values ('NDIS check', '{ndis}');
insert into public.assessment_versions (template_id) values (test.tpl('NDIS check'));
insert into public.assessment_sections (version_id, title, sort_order) values (test.ver('NDIS check', 1), 'Main', 1);
insert into public.assessment_questions (version_id, section_id, key, label, type, required, options, validation, sort_order)
select test.ver('NDIS check', 1), s.id, 'hours', 'Hours a week', 'number', true, '[]', '{"min": 0, "max": 40}', 1 from public.assessment_sections s where s.version_id = test.ver('NDIS check', 1);
insert into public.assessment_questions (version_id, section_id, key, label, type, required, sort_order)
select test.ver('NDIS check', 1), s.id, 'pick', 'Pick one', 'choice', false, 2 from public.assessment_sections s where s.version_id = test.ver('NDIS check', 1);
select test.refused($$update public.assessment_versions set status = 'published' where id = test.ver('NDIS check', 1)$$, 'a choice question needs options before publishing');
update public.assessment_questions set options = '["A", "B"]' where key = 'pick' and version_id = test.ver('NDIS check', 1);
update public.assessment_versions set status = 'published' where id = test.ver('NDIS check', 1);
reset role;
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$insert into public.assessment_templates (name) values ('Made up')$$, 'a support worker can''t make templates');
reset role;

-- 2. Starting an assessment: who, and which templates.
select test.act_as('cm@example.com');
set role authenticated;
insert into public.client_assessments (client_id, template_id, version_id) values (test.cid('Zara'), test.tpl('Client needs assessment (Sample)'), test.ver('Client needs assessment (Sample)', 2));
select test.refused($$insert into public.client_assessments (client_id, template_id, version_id) values (test.cid('Zara'), test.tpl('Client needs assessment (Sample)'), test.ver('Client needs assessment (Sample)', 1))$$, 'only a published (current) version can be used');
select test.refused($$insert into public.client_assessments (client_id, template_id, version_id) values (test.cid('Ben'), test.tpl('Client needs assessment (Sample)'), test.ver('Client needs assessment (Sample)', 2))$$, 'a Case Manager can''t assess a client outside their scope');
select test.refused($$insert into public.client_assessments (client_id, template_id, version_id) values (test.cid('Zara'), test.tpl('NDIS check'), test.ver('NDIS check', 1))$$, 'a scheme template needs the program it''s for');
insert into public.client_assessments (client_id, template_id, version_id, enrolment_id)
select test.cid('Zara'), test.tpl('NDIS check'), test.ver('NDIS check', 1), e.id from public.client_enrolments e where e.client_id = test.cid('Zara') and e.scheme = 'ndis';
reset role;
select test.ok((select count(*) from public.client_assessments where client_id = test.cid('Zara')) = 2, 'started: a common one and an NDIS one');
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$insert into public.client_assessments (client_id, template_id, version_id) values (test.cid('Zara'), test.tpl('Client needs assessment (Sample)'), test.ver('Client needs assessment (Sample)', 2))$$, 'a support worker can''t start one');
reset role;
select test.ok(test.n('sam@example.com', $$(select count(*) from public.client_assessments)$$) = 0, 'or see any');

-- 3. Answers are checked on every save.
select test.act_as('cm@example.com');
set role authenticated;
select test.refused($$update public.client_assessments set answers = '{"lives_alone": "Maybe"}' where id = test.a('Zara') and version_id = test.ver('Client needs assessment (Sample)', 2)$$, 'a yes/no answer must be Yes or No');
select test.refused($$update public.client_assessments set answers = '{"made_up": "x"}' where id = test.a('Zara') and version_id = test.ver('Client needs assessment (Sample)', 2)$$, 'unknown questions are refused');
select test.refused($$update public.client_assessments set answers = '{"hours": "50"}' where client_id = test.cid('Zara') and template_id = test.tpl('NDIS check')$$, 'numbers stay within their limits');
select test.refused($$update public.client_assessments set answers = '{"pick": "C"}' where client_id = test.cid('Zara') and template_id = test.tpl('NDIS check')$$, 'choices come from the list');
update public.client_assessments set status = 'cancelled', cancel_reason = 'Started by mistake' where client_id = test.cid('Zara') and template_id = test.tpl('NDIS check');

-- 4. Findings from answers: no duplicates, several from one answer, withdrawn when no longer true.
create temp table a1 as select test.a('Zara') as id;
update public.client_assessments set answers = '{"lives_alone": "Yes", "mobility_aid": "Walking frame"}' where id = (select id from a1);
update public.client_assessments set answers = '{"lives_alone": "Yes", "mobility_aid": "Walking frame"}' where id = (select id from a1);
update public.client_assessments set answers = answers || '{"falls": "0"}' where id = (select id from a1);
reset role;
select test.ok(test.findings((select id from a1)) = 'risk:active,limitation:active,equipment:active', 'saving again makes no duplicates; one answer makes two findings');
select test.act_as('cm@example.com');
set role authenticated;
update public.client_assessments set answers = answers || '{"mobility_aid": "No"}' where id = (select id from a1);
reset role;
select test.ok(test.findings((select id from a1)) = 'risk:active,limitation:withdrawn,equipment:withdrawn', 'findings that no longer apply are withdrawn, not deleted');
-- Edited finding, then its answer changes: flagged, and completion waits for a check.
select test.act_as('cm@example.com');
set role authenticated;
update public.assessment_findings set text = 'Lives alone; daughter visits weekly' where assessment_id = (select id from a1) and source_key = 'lives_alone';
insert into public.assessment_findings (assessment_id, client_id, kind, text) values ((select id from a1), test.cid('Zara'), 'goal', 'Stay at home');
select test.refused($$update public.assessment_findings set source_answer = 'No' where source_key = 'lives_alone'$$, 'the answer a finding came from can''t be changed by hand');
update public.client_assessments set answers = answers || '{"lives_alone": "No"}' where id = (select id from a1);
reset role;
select test.ok(test.findings((select id from a1)) = 'risk:answer_changed*,limitation:withdrawn,equipment:withdrawn,goal:active', 'an edited finding is flagged when its answer changes; manual findings stay');
select test.ok((select answers ->> 'lives_alone' from public.client_assessments where id = (select id from a1)) = 'No'
           and (select text from public.assessment_findings where assessment_id = (select id from a1) and source_key = 'lives_alone') = 'Lives alone; daughter visits weekly', 'answers and findings are kept apart');

-- 5. Completing: required questions that show; hidden ones aren't required.
select test.act_as('cm@example.com');
set role authenticated;
update public.client_assessments set answers = answers || '{"help_with": ["Cleaning"], "medicines_help": "No", "goal": "Stay at home"}' where id = (select id from a1);
select test.refused($$update public.client_assessments set status = 'completed' where id = (select id from a1)$$, 'can''t complete while a changed finding isn''t checked');
update public.assessment_findings set state = 'withdrawn' where assessment_id = (select id from a1) and source_key = 'lives_alone';
update public.client_assessments set status = 'completed' where id = (select id from a1);
reset role;
select test.ok((select status from public.client_assessments where id = (select id from a1)) = 'completed', 'completed: "Who checks in" was hidden (lives with others), so not required');
select test.act_as('cm@example.com');
set role authenticated;
select test.refused($$update public.client_assessments set answers = '{}' where id = (select id from a1)$$, 'a completed assessment can''t be changed');
select test.refused($$update public.assessment_findings set text = 'x' where assessment_id = (select id from a1)$$, 'nor its findings');
select test.refused($$insert into public.assessment_findings (assessment_id, client_id, kind, text) values ((select id from a1), test.cid('Zara'), 'need', 'late')$$, 'no findings can be added');
select test.refused($$delete from public.client_assessments$$, 'assessments are never deleted');

-- 6. A new assessment from the completed one: reused answers need confirming; the old one is superseded.
insert into public.client_assessments (client_id, template_id, version_id, replaces_id, answers, reused)
values (test.cid('Zara'), test.tpl('Client needs assessment (Sample)'), test.ver('Client needs assessment (Sample)', 2), (select id from a1),
        '{"lives_alone": "No", "help_with": ["Cleaning"], "mobility_aid": "No", "falls": "0", "medicines_help": "No", "goal": "Stay at home"}',
        jsonb_build_object('lives_alone', jsonb_build_object('from', (select id from a1), 'confirmed', false), 'goal', jsonb_build_object('from', (select id from a1), 'confirmed', false)));
create temp table a2 as select test.a('Zara') as id;
select test.refused($$update public.client_assessments set status = 'completed' where id = (select id from a2)$$, 'reused answers must be confirmed first');
select test.refused($$update public.client_assessments set reused = '{}' where id = (select id from a2)$$, 'a reused answer stays marked as reused');
update public.client_assessments set reused = jsonb_set(jsonb_set(reused, '{lives_alone,confirmed}', 'true'), '{goal,confirmed}', 'true') where id = (select id from a2);
update public.client_assessments set status = 'completed' where id = (select id from a2);
reset role;
select test.ok((select status || '/' || (replaced_by = (select id from a2))::text from public.client_assessments where id = (select id from a1)) = 'superseded/true', 'the replaced assessment is superseded and points to the new one');
select test.ok((select count(*) from public.client_assessments where client_id = test.cid('Zara')) = 3, 'every assessment is kept');
-- Reuse is refused when the question isn't the same kind.
select test.act_as('cm@example.com');
set role authenticated;
select test.refused($$insert into public.client_assessments (client_id, template_id, version_id, enrolment_id, answers, reused)
  select test.cid('Zara'), test.tpl('NDIS check'), test.ver('NDIS check', 1), e.id, '{"hours": "3"}', jsonb_build_object('hours', jsonb_build_object('from', (select id from a1), 'confirmed', false))
    from public.client_enrolments e where e.client_id = test.cid('Zara') and e.scheme = 'ndis'$$, 'an answer can''t be reused from a different question');
reset role;

-- 7. Access, audit, viewing and printing.
select test.ok(test.n('cm@example.com', $$(select count(*) from public.client_assessments where client_id = test.cid('Zara'))$$) = 3, 'their Case Manager sees the client''s assessments');
select test.ok(test.n('cm@example.com', $$(select count(*) from public.client_assessments where client_id = test.cid('Ben'))$$) = 0, 'but not another client''s');
select test.ok((select count(*) from public.audit_log where entity = 'client' and entity_id = test.cid('Zara')::text and action = 'client_assessments_changed' and details -> 'fields' ? 'status') >= 3, 'completing and superseding are in the client audit trail');
select test.ok(test.n('owner@example.com', $$(select count(*) from public.client_audit_values v join public.audit_log a on a.id = v.audit_id where a.action like 'assessment_findings%')$$) > 0
           and test.n('cm@example.com', $$(select count(*) from public.client_audit_values)$$) = 0, 'values for the system admin only');
select test.act_as('cm@example.com');
set role authenticated;
insert into public.client_staff_views (client_id, area) values (test.cid('Zara'), 'assessment');
insert into public.client_staff_views (client_id, area) values (test.cid('Zara'), 'assessment');
insert into public.download_log (kind, action, label, client_id) values ('record', 'print', 'Printed assessment', test.cid('Zara'));
reset role;
select test.ok((select count(*) from public.client_staff_views where area = 'assessment') = 1, 'viewing is recorded once an hour');
select test.ok((select count(*) from public.download_log where action = 'print') = 1, 'printing is recorded');
\o
select 'All assessment tests passed.';
