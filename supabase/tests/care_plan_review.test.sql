-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 160): care plans, support plans and proposed budgets from assessments.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker'),
  ('cm@example.com', 'Casey', 'support_worker'), ('io@example.com', 'Ira', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com'), ('cm@example.com'), ('io@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.cid(p text) returns uuid language sql security definer as $$ select id from public.car_clients where name = p $$;
create function test.n(p_email text, p_sql text) returns bigint language plpgsql as $$
declare v bigint;
begin
  perform test.act_as(p_email);
  execute 'set local role authenticated';
  execute 'select ' || p_sql into v;
  execute 'reset role';
  return v;
end $$;
create function test.cp() returns uuid language sql security definer as $$ select id from public.client_care_plans where source_assessment_id is not null order by created_at limit 1 $$;
create function test.sp() returns uuid language sql security definer as $$ select id from public.client_support_plans order by created_at limit 1 $$;
create function test.bp() returns uuid language sql security definer as $$ select id from public.client_budget_proposals order by created_at limit 1 $$;
create function test.asmt() returns uuid language sql security definer as $$ select id from public.client_assessments order by created_at limit 1 $$;
grant execute on all functions in schema test to authenticated;
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Case Manager') where email = 'cm@example.com';
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Intake & Assessment Officer') where email = 'io@example.com';
insert into public.car_clients (name, status) values ('Zara', 'active'), ('Ben', 'active');
insert into public.client_assignments (client_id, user_id) values (test.cid('Zara'), test.pid('cm@example.com'));
insert into public.client_locations (client_id, label, address) values (test.cid('Zara'), 'Home', '1 Test St');
insert into public.client_services (client_id, program_id, label, start_date, location_id)
select test.cid('Zara'), p.id, 'Home support', current_date, l.id from public.client_programs p, public.client_locations l where p.scheme = 'private' and l.label = 'Home' limit 1;
insert into public.client_people (client_id, kind, name, relationship, phone) values (test.cid('Zara'), 'representative', 'Pat Rep', 'Daughter', '0412 345 678');
select test.act_as('owner@example.com');
set role authenticated;
insert into public.admin_designations (user_id, granted_by) values (test.pid('boss@example.com'), test.pid('owner@example.com'));
-- A small template: one optional question.
insert into public.assessment_templates (name) values ('Plan check');
insert into public.assessment_versions (template_id) select id from public.assessment_templates where name = 'Plan check';
insert into public.assessment_sections (version_id, title, sort_order) select v.id, 'Main', 1 from public.assessment_versions v join public.assessment_templates t on t.id = v.template_id where t.name = 'Plan check';
insert into public.assessment_questions (version_id, section_id, key, label, type, sort_order)
select s.version_id, s.id, 'note', 'Notes', 'long', 1 from public.assessment_sections s join public.assessment_versions v on v.id = s.version_id join public.assessment_templates t on t.id = v.template_id where t.name = 'Plan check';
update public.assessment_versions set status = 'published' where template_id = (select id from public.assessment_templates where name = 'Plan check');
reset role;

-- 0. Template version control: sections are in the change log too.
select test.ok((select count(*) from public.audit_log where entity = 'assessment_section') >= 1, 'template sections are in the change log');
select test.ok((select 'approve' = any (actions) from public.app_modules where id = 'clients.care_plans') and (select 'approve' = any (actions) from public.app_modules where id = 'clients.funding'), 'care plans and funding have an approve right');

-- 1. A completed assessment with findings, under one of Zara's programs.
select test.act_as('cm@example.com');
set role authenticated;
insert into public.client_assessments (client_id, template_id, version_id, enrolment_id)
select test.cid('Zara'), v.template_id, v.id, (select id from public.client_enrolments where client_id = test.cid('Zara') limit 1)
  from public.assessment_versions v join public.assessment_templates t on t.id = v.template_id where t.name = 'Plan check';
insert into public.assessment_findings (assessment_id, client_id, kind, text) values
  (test.asmt(), test.cid('Zara'), 'need', 'Help with showering'),
  (test.asmt(), test.cid('Zara'), 'risk', 'Falls in the bathroom'),
  (test.asmt(), test.cid('Zara'), 'goal', 'Shower on her own by June'),
  (test.asmt(), test.cid('Zara'), 'support', 'Personal care'),
  (test.asmt(), test.cid('Zara'), 'frequency', 'Three mornings a week'),
  (test.asmt(), test.cid('Zara'), 'equipment', 'Shower chair'),
  (test.asmt(), test.cid('Zara'), 'preference', 'Female worker'),
  (test.asmt(), test.cid('Zara'), 'limitation', 'Can''t stand for long');
insert into public.assessment_findings (assessment_id, client_id, kind, text) values (test.asmt(), test.cid('Zara'), 'need', 'Withdrawn one');
update public.assessment_findings set state = 'withdrawn' where text = 'Withdrawn one';
select test.refused($$select public.generate_care_documents(test.asmt())$$, 'drafts are made from a completed assessment only');
update public.client_assessments set status = 'completed' where id = test.asmt();
select public.generate_care_documents(test.asmt());
reset role;

select test.ok((select status from public.client_care_plans where id = test.cp()) = 'draft', 'the care plan is a draft');
select test.ok((select count(*) from public.client_care_plan_items where plan_id = test.cp()) = 6, 'care plan items from active findings (not the withdrawn one, not frequency)');
select test.ok((select string_agg(section, ',' order by section) from public.client_care_plan_items where plan_id = test.cp()) = 'need,preference,requirement,requirement,requirement,risk', 'findings go to the right sections');
select test.ok((select count(*) from public.client_care_goals where plan_id = test.cp() and source_finding_id is not null) = 1, 'the goal finding becomes a plan goal, with its source');
select test.ok((select count(*) from public.client_care_plan_items where plan_id = test.cp() and source_finding_id is null) = 0, 'every generated item keeps its finding');
select test.ok((select source_version_id = (select version_id from public.client_assessments where id = test.asmt())
                   and enrolment_id = (select enrolment_id from public.client_assessments where id = test.asmt())
                  from public.client_care_plans where id = test.cp()), 'the plan keeps its source assessment version and program');
select test.ok((select count(*) from public.client_support_plan_lines where plan_id = test.sp()) = 4, 'support plan lines from support, frequency, equipment and preference');
select test.ok((select count(*) from public.client_budget_lines where proposal_id = test.bp()) = 2, 'budget lines from the support lines (support and equipment)');
select test.ok((select coalesce(sum(estimated_cost), 0) from public.client_budget_lines where proposal_id = test.bp()) = 0, 'hours and rates are left blank');
select test.ok((select support_plan_id = test.sp() and source_version_id is not null from public.client_budget_proposals where id = test.bp()), 'the budget links to the support plan and the source version');

-- 2. Running it again changes nothing and makes no duplicates; an edited draft is left alone.
select test.act_as('cm@example.com');
set role authenticated;
update public.client_care_plan_items set text = 'Help with showering and drying' where plan_id = test.cp() and section = 'need';
select test.ok((select public.generate_care_documents(test.asmt()) -> 'made') = '[]'::jsonb, 'nothing new is made the second time');
reset role;
select test.ok((select count(*) from public.client_care_plans where source_assessment_id = test.asmt()) = 1 and (select count(*) from public.client_support_plans) = 1 and (select count(*) from public.client_budget_proposals) = 1, 'no duplicate documents');
select test.ok((select text = 'Help with showering and drying' and edited from public.client_care_plan_items where plan_id = test.cp() and section = 'need'), 'the edited item is kept and marked as edited');
select test.refused($$update public.client_care_plan_items set source_finding_id = null where plan_id = test.cp() and section = 'need'$$, 'where an item came from isn''t changed');

-- 3. Who sees and changes them.
select test.ok(test.n('io@example.com', '(select count(*) from public.client_care_plan_items)') = 6, 'intake: sees care plan items');
select test.ok(test.n('sam@example.com', '(select count(*) from public.client_care_plan_items) + (select count(*) from public.client_support_plans) + (select count(*) from public.client_budget_proposals)') = 0, 'support worker: sees none');
select test.act_as('io@example.com');
set role authenticated;
select test.refused($$insert into public.client_care_plan_items (plan_id, client_id, section, text) values (test.cp(), test.cid('Zara'), 'need', 'x')$$, 'intake: view only');
select test.refused($$select public.generate_care_documents(test.asmt())$$, 'intake can''t generate drafts');
reset role;

-- 4. Review: submit; someone with approve who didn't make or submit it decides.
select test.act_as('cm@example.com');
set role authenticated;
insert into public.client_care_plan_items (plan_id, client_id, section, text) values (test.cp(), test.cid('Zara'), 'instruction', 'Use the shower chair every time');
select test.refused($$update public.client_care_plans set status = 'current' where id = test.cp()$$, 'a draft can''t be approved straight away');
update public.client_care_plans set status = 'pending_review' where id = test.cp();
select test.refused($$update public.client_care_plan_items set text = 'x' where plan_id = test.cp() and section = 'risk'$$, 'items are fixed while waiting for review');
select test.refused($$update public.client_care_plans set status = 'current' where id = test.cp()$$, 'a case manager can''t approve (no approve right)');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.client_care_plans set status = 'changes_required' where id = test.cp()$$, 'changes required needs a note');
update public.client_care_plans set status = 'changes_required', review_note = 'Add how often' where id = test.cp();
reset role;
select test.act_as('cm@example.com');
set role authenticated;
insert into public.client_care_plan_items (plan_id, client_id, section, text) values (test.cp(), test.cid('Zara'), 'monitoring', 'Check skin weekly');
update public.client_care_plans set status = 'pending_review' where id = test.cp();
reset role;
select test.act_as('boss@example.com');
set role authenticated;
update public.client_care_plans set status = 'current' where id = test.cp();
reset role;
select test.ok((select status = 'current' and made_current_by = test.pid('boss@example.com') and submitted_by = test.pid('cm@example.com') and reviewed_by = test.pid('boss@example.com') from public.client_care_plans where id = test.cp()), 'approved, with who submitted and who approved');
select test.act_as('cm@example.com');
set role authenticated;
select test.refused($$update public.client_care_plan_items set text = 'x' where plan_id = test.cp() and section = 'risk'$$, 'an approved plan''s items are fixed');
select test.refused($$delete from public.client_care_plan_items where plan_id = test.cp()$$, 'and never removed');
select test.refused($$update public.client_care_plans set summary = 'x' where id = test.cp()$$, 'an approved plan''s wording is fixed');
reset role;
-- The maker can't approve their own plan, even with the approve right.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.client_care_plans (client_id, title) values (test.cid('Zara'), 'Boss plan');
update public.client_care_plans set status = 'pending_review' where title = 'Boss plan';
select test.refused($$update public.client_care_plans set status = 'current' where title = 'Boss plan'$$, 'nobody approves a plan they made or submitted');
reset role;
select test.act_as('cm@example.com');
set role authenticated;
update public.client_care_plans set status = 'draft' where title = 'Boss plan';
update public.client_care_plans set status = 'pending_review' where title = 'Boss plan';
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.client_care_plans set status = 'current' where title = 'Boss plan'$$, 'the maker still can''t approve after someone else submits');
reset role;
select test.act_as('owner@example.com');
set role authenticated;
update public.client_care_plans set status = 'current' where title = 'Boss plan';
reset role;
select test.ok((select status from public.client_care_plans where id = test.cp()) = 'archived' and (select archived_at is not null from public.client_care_plans where id = test.cp()), 'approving a new plan supersedes the old one (kept)');

-- 5. Agreement: only after approval; never changes.
select test.act_as('cm@example.com');
set role authenticated;
select test.refused($$insert into public.client_plan_agreements (client_id, support_plan_id, agreed_by, agreed_name, method, agreed_on) values (test.cid('Zara'), test.sp(), 'client', 'Zara', 'verbal', current_date)$$, 'agreement waits for approval');
insert into public.client_plan_agreements (client_id, care_plan_id, agreed_by, person_id, agreed_name, method, agreed_on)
select test.cid('Zara'), id, 'person', (select id from public.client_people where name = 'Pat Rep'), 'Pat Rep', 'signed', current_date from public.client_care_plans where title = 'Boss plan';
select test.refused($$update public.client_plan_agreements set method = 'verbal'$$, 'a recorded agreement can''t be changed');
select test.refused($$insert into public.client_plan_agreements (client_id, care_plan_id, agreed_by, agreed_name, method, agreed_on) select test.cid('Zara'), id, 'client', 'Zara', 'verbal', current_date from public.client_care_plans where title = 'Boss plan'$$, 'one agreement per plan');
reset role;
select test.ok((select recorded_by = test.pid('cm@example.com') from public.client_plan_agreements), 'records who recorded the agreement');

-- 6. Worker instructions from an approved plan's instruction item, once.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.client_care_plans (client_id, title) values (test.cid('Zara'), 'Plan 3');
insert into public.client_care_plan_items (plan_id, client_id, section, text) select id, client_id, 'instruction', 'Encourage her to dry herself' from public.client_care_plans where title = 'Plan 3';
insert into public.client_care_plan_items (plan_id, client_id, section, text) select id, client_id, 'need', 'A need' from public.client_care_plans where title = 'Plan 3';
update public.client_care_plans set status = 'pending_review' where title = 'Plan 3';
reset role;
select test.act_as('owner@example.com');
set role authenticated;
update public.client_care_plans set status = 'current' where title = 'Plan 3';
reset role;
select test.act_as('cm@example.com');
set role authenticated;
select test.refused($$insert into public.client_worker_instructions (client_id, title, instructions, source_item_id) select client_id, 'x', text, id from public.client_care_plan_items where text = 'A need'$$, 'only instruction items are added');
insert into public.client_worker_instructions (client_id, title, instructions, source_item_id) select client_id, 'Drying', text, id from public.client_care_plan_items where text = 'Encourage her to dry herself';
select test.refused($$insert into public.client_worker_instructions (client_id, title, instructions, source_item_id) select client_id, 'Again', text, id from public.client_care_plan_items where text = 'Encourage her to dry herself'$$, 'once per item');
select test.refused($$update public.client_worker_instructions set source_item_id = null where title = 'Drying'$$, 'where it came from isn''t changed');
update public.client_worker_instructions set instructions = 'Encourage her to dry herself; help with feet' where title = 'Drying';
reset role;
select test.ok((select source_plan_id = (select id from public.client_care_plans where title = 'Plan 3') and added_by = test.pid('cm@example.com') from public.client_worker_instructions where title = 'Drying'), 'keeps the plan, item, who and when');
select test.ok(test.n('sam@example.com', '(select count(*) from public.client_worker_instructions)') = 0, 'workers see instructions only for their clients, as before');

-- 7. Support plan: same steps; approving another under the same program supersedes it.
select test.act_as('cm@example.com');
set role authenticated;
update public.client_support_plan_lines set hours_per_week = 3, service_id = (select id from public.client_services where label = 'Home support') where plan_id = test.sp() and support = 'Personal care';
select test.refused($$update public.client_support_plans set status = 'approved' where id = test.sp()$$, 'a support plan isn''t approved without review');
update public.client_support_plans set status = 'pending_review' where id = test.sp();
select test.refused($$update public.client_support_plans set status = 'approved' where id = test.sp()$$, 'a case manager can''t approve a support plan');
select test.refused($$delete from public.client_support_plans$$, 'support plans are never deleted');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
update public.client_support_plans set status = 'approved' where id = test.sp();
select test.refused($$update public.client_support_plans set title = 'x' where id = test.sp()$$, 'an approved support plan is fixed');
select test.refused($$update public.client_support_plan_lines set frequency = 'x' where plan_id = test.sp()$$, 'and its lines');
insert into public.client_support_plans (client_id, enrolment_id, title) select client_id, enrolment_id, 'Support plan 2' from public.client_support_plans where id = test.sp();
reset role;
select test.act_as('cm@example.com');
set role authenticated;
update public.client_support_plans set status = 'pending_review' where title = 'Support plan 2';
reset role;
select test.act_as('owner@example.com');
set role authenticated;
update public.client_support_plans set status = 'approved' where title = 'Support plan 2';
reset role;
select test.ok((select status = 'superseded' and superseded_at is not null and approved_by = test.pid('boss@example.com') from public.client_support_plans where id = test.sp()), 'the earlier support plan is superseded, kept with who approved it');

-- 8. Proposed budget: estimates only; financial approval; compared with funding that fits.
select test.act_as('cm@example.com');
set role authenticated;
update public.client_budget_lines set hours_per_week = 3, weeks = 12, estimated_rate = 70.50, service_id = (select id from public.client_services where label = 'Home support') where proposal_id = test.bp() and description = 'Personal care';
reset role;
select test.ok((select estimated_cost from public.client_budget_lines where description = 'Personal care') = 2538.00, 'estimated cost = hours a week x weeks x rate');
update public.client_budget_proposals set period_start = current_date, period_end = current_date + 90 where id = test.bp();
insert into public.client_funding (client_id, service_id, period_start, period_end, total_amount, used_amount)
select test.cid('Zara'), id, current_date, current_date + 60, 2000, 500 from public.client_services where label = 'Home support';
insert into public.client_funding (client_id, service_id, period_start, period_end, total_amount, used_amount)
select test.cid('Zara'), id, current_date - 300, current_date + 30, 9000, 0 from public.client_services where label = 'Home support';
insert into public.client_funding (client_id, service_id, period_start, period_end, total_amount, used_amount)
select test.cid('Zara'), id, current_date - 400, current_date - 200, 9000, 0 from public.client_services where label = 'Home support';
select test.ok((select string_agg(fit || ':' || coalesce(remaining::text, '-'), ',' order by fit) from public.budget_funding(test.bp())) = 'none:-,partial:9000.00,within:1500.00',
  'compared per service: funding within the period counts, partly overlapping is shown apart, older funding is left out, no funding says so');
select test.act_as('cm@example.com');
set role authenticated;
update public.client_budget_proposals set status = 'pending_review' where id = test.bp();
select test.refused($$update public.client_budget_proposals set status = 'approved' where id = test.bp()$$, 'a case manager can''t approve a budget');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
update public.client_budget_proposals set status = 'approved' where id = test.bp();
select test.refused($$update public.client_budget_lines set weeks = 1 where proposal_id = test.bp()$$, 'an approved budget is fixed');
reset role;
select test.ok((select approved_by = test.pid('boss@example.com') from public.client_budget_proposals where id = test.bp()), 'records who approved the budget');
select test.ok((select sum(used_amount) from public.client_funding) = 500 and (select count(*) from public.client_funding) = 3, 'a budget never changes funding');

-- 9. Audit trail and other clients.
select test.ok((select count(*) from public.audit_log where action in ('client_care_plan_items_added', 'client_support_plans_changed', 'client_budget_lines_changed', 'client_plan_agreements_added')) >= 4, 'changes are in the client audit trail');
select test.act_as('cm@example.com');
set role authenticated;
select test.refused($$insert into public.client_support_plans (client_id, title) values (test.cid('Ben'), 'x')$$, 'a case manager can''t add plans for a client they aren''t assigned to');
select test.refused($$insert into public.client_support_plans (client_id, title, source_assessment_id) values (test.cid('Ben'), 'x', test.asmt())$$, 'another client''s assessment can''t be the source');
reset role;

\o
select 'All care plan review tests passed.';
