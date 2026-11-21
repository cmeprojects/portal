-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 113): care plans, goals and worker instructions
-- (Care block C4).

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin'),
  ('sam@example.com', 'Sam', 'support_worker'), ('cm@example.com', 'Casey', 'support_worker'), ('io@example.com', 'Ira', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('sam@example.com'), ('cm@example.com'), ('io@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.cid(p_name text) returns uuid language sql security definer as $$ select id from public.car_clients where name = p_name $$;
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
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Intake & Assessment Officer') where email = 'io@example.com';
insert into public.teams (name) values ('North');
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'North';
insert into public.car_clients (name) values ('Zara North'), ('Alex South');
insert into public.client_teams (client_id, team_id) select test.cid('Zara North'), id from public.teams where name = 'North';

select test.ok((select sensitivity from public.app_modules where id = 'clients.care_plans') = 'sensitive', 'Care plans is sensitive');

-- A manager drafts a plan with a goal and a worker instruction.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.client_care_plans (client_id, title, summary, status) values (test.cid('Zara North'), 'Plan 2026', 'Supports at home', 'current');
insert into public.client_care_goals (plan_id, client_id, goal) select id, client_id, 'Cook a meal weekly' from public.client_care_plans where title = 'Plan 2026';
select test.refused($$insert into public.client_care_goals (plan_id, client_id, goal) select id, test.cid('Alex South'), 'x' from public.client_care_plans where title = 'Plan 2026'$$, 'a goal stays with its plan''s client');
insert into public.client_worker_instructions (client_id, title, instructions) values (test.cid('Zara North'), 'Meals', 'Prompt, don''t do it for them.');
reset role;
select test.ok((select status from public.client_care_plans where title = 'Plan 2026') = 'draft', 'a new plan always starts as a draft');

-- Who sees what.
select test.ok(test.n('office@example.com', '(select count(*) from public.client_care_plans)') = 0, 'staff admin: no plans (D-052)');
select test.ok(test.n('sam@example.com', '(select count(*) from public.client_care_plans)') = 0, 'team staff: no plans');
select test.ok(test.n('sam@example.com', '(select count(*) from public.client_care_goals)') = 0, 'team staff: no goals');
select test.ok(test.n('sam@example.com', '(select count(*) from public.client_worker_instructions)') = 1, 'team staff: their team client''s worker instructions');
select test.ok(test.n('office@example.com', '(select count(*) from public.client_worker_instructions)') = 0, 'staff admin: no worker instructions');
select test.ok(test.n('io@example.com', '(select count(*) from public.client_care_plans)') = 1, 'intake: sees plans');
select test.act_as('io@example.com');
set role authenticated;
select test.refused($$insert into public.client_care_plans (client_id, title) values (test.cid('Zara North'), 'X')$$, 'intake: view only');
insert into public.client_assignments (client_id, user_id) values (test.cid('Zara North'), test.pid('cm@example.com'));
reset role;
select test.ok(test.n('cm@example.com', '(select count(*) from public.client_care_plans)') = 1, 'assigned case manager: sees the plan');

-- The case manager submits it (update 160: plans are reviewed and approved by
-- someone with the approve right who didn't make or submit it); then the wording is fixed.
select test.act_as('cm@example.com');
set role authenticated;
select test.refused($$update public.client_care_plans set status = 'current' where title = 'Plan 2026'$$, 'a draft isn''t approved without review');
update public.client_care_plans set status = 'pending_review' where title = 'Plan 2026';
reset role;
select test.act_as('owner@example.com');
set role authenticated;
update public.client_care_plans set status = 'current' where title = 'Plan 2026';
reset role;
select test.act_as('cm@example.com');
set role authenticated;
select test.refused($$update public.client_care_plans set summary = 'changed' where title = 'Plan 2026'$$, 'a current plan''s wording is fixed');
select test.refused($$update public.client_care_plans set status = 'draft' where title = 'Plan 2026'$$, 'a current plan doesn''t go back to draft');
select test.refused($$update public.client_care_goals set goal = 'changed'$$, 'a current plan''s goals are fixed');
update public.client_care_goals set status = 'achieved';
insert into public.client_care_plans (client_id, title) values (test.cid('Zara North'), 'Plan 2027');
update public.client_care_plans set status = 'pending_review' where title = 'Plan 2027';
reset role;
select test.act_as('boss@example.com');
set role authenticated;
update public.client_care_plans set status = 'current' where title = 'Plan 2027';
reset role;
select test.act_as('cm@example.com');
set role authenticated;
select test.refused($$update public.client_care_plans set status = 'current' where title = 'Plan 2026'$$, 'an archived plan stays archived');
select test.refused($$delete from public.client_care_plans$$, 'plans are never deleted');
reset role;
select test.ok((select status from public.client_care_goals limit 1) = 'achieved', 'progress can still be updated on a current plan');
select test.ok((select status from public.client_care_plans where title = 'Plan 2026') = 'archived', 'making a new plan current archives the old one');
select test.ok((select made_current_by = test.pid('boss@example.com') and submitted_by = test.pid('cm@example.com') from public.client_care_plans where title = 'Plan 2027'), 'records who submitted and who approved it');
select test.ok((select count(*) from public.client_care_plans where status = 'current') = 1, 'one current plan per client');

\o
