-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 121): performance and development reviews, HR reminders.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin'), ('lead@example.com', 'Lee', 'team_leader'),
  ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('lead@example.com'), ('sam@example.com'), ('kim@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
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
insert into public.teams (name) values ('North');
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'North';
insert into public.team_leaders (team_id, user_id) select id, test.pid('lead@example.com') from public.teams where name = 'North';

select test.ok((select sensitivity from public.app_modules where id = 'hr.performance') = 'sensitive', 'Performance and development is sensitive');

-- Sam's team leader plans a probation review; Kim's (not in the team) can't.
select test.act_as('lead@example.com');
set role authenticated;
insert into public.staff_reviews (user_id, kind, due_on) values (test.pid('sam@example.com'), 'probation', current_date + 10);
select test.refused($$insert into public.staff_reviews (user_id, kind, due_on) values (test.pid('kim@example.com'), 'annual', current_date)$$, 'a team leader only for their teams');
select test.refused($$insert into public.staff_reviews (user_id, kind, due_on) values (test.pid('lead@example.com'), 'annual', current_date)$$, 'nobody plans their own review');
reset role;
select test.ok((select reviewer_id = test.pid('lead@example.com') from public.staff_reviews), 'the planner is the reviewer unless chosen');

-- Who sees it while planned.
select test.ok(test.n('boss@example.com', '(select count(*) from public.staff_reviews)') = 1, 'managers see it');
select test.ok(test.n('office@example.com', '(select count(*) from public.staff_reviews)') = 1, 'staff admins see it');
select test.ok(test.n('sam@example.com', '(select count(*) from public.staff_reviews)') = 0, 'the person doesn''t see it until it''s held');
select test.ok(test.n('kim@example.com', '(select count(*) from public.staff_reviews)') = 0, 'other staff don''t');

-- Reminder 14 days before (once), to the reviewer.
select public.run_hr_alerts();
select public.run_hr_alerts();
select test.ok((select count(*) from public.notifications where kind = 'staff_review_due' and user_id = test.pid('lead@example.com')) = 1, 'one reminder to the reviewer');
select test.ok((select count(*) from public.notifications where kind = 'staff_review_due' and user_id = test.pid('sam@example.com')) = 0, 'not to the person');

-- Held: needs a date and summary; then fixed; the person acknowledges.
select test.act_as('lead@example.com');
set role authenticated;
select test.refused($$update public.staff_reviews set status = 'held'$$, 'holding needs the date and a summary');
update public.staff_reviews set status = 'held', held_on = current_date, summary = 'Going well', goals = 'Medication training', outcome = 'passed';
select test.refused($$update public.staff_reviews set summary = 'changed'$$, 'a held review stays as it was');
select test.refused($$delete from public.staff_reviews$$, 'reviews are never deleted');
reset role;
select test.ok(test.n('sam@example.com', '(select count(*) from public.staff_reviews)') = 1, 'the person sees it once held');
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$update public.staff_reviews set summary = 'mine now'$$, 'the person can''t change it');
update public.staff_reviews set acknowledged_at = now();
reset role;
select test.ok((select acknowledged_at is not null from public.staff_reviews), 'the person acknowledges it');
set role authenticated;
select test.refused($$select public.run_hr_alerts()$$, 'staff can''t run the reminders');
reset role;

\o
