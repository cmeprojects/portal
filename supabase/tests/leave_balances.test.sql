-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 120): leave balances (HR block step 3).

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin'),
  ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('sam@example.com'), ('kim@example.com');
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

-- A staff admin sets Sam's annual leave: 10 days as at 365 days ago, 20 a year.
select test.act_as('office@example.com');
set role authenticated;
insert into public.leave_balances (user_id, leave_type, opening_days, accrual_days_per_year, as_at) values (test.pid('sam@example.com'), 'annual', 10, 20, current_date - 365);
select test.refused($$insert into public.leave_balances (user_id, leave_type, opening_days) values (test.pid('office@example.com'), 'annual', 99)$$, 'nobody sets their own balance');
reset role;
-- Approved leave: Monday to Sunday next week (5 weekdays).
insert into public.leave_periods (user_id, leave_type, start_date, end_date)
values (test.pid('sam@example.com'), 'annual', (date_trunc('week', current_date) + interval '7 days')::date, (date_trunc('week', current_date) + interval '13 days')::date);
select test.ok((select updated_by = test.pid('office@example.com') from public.leave_balances), 'records who set it');

-- Balance = 10 + 20 − 5 weekdays = 25.
select test.ok(test.n('sam@example.com', $$(select public.leave_balance(test.pid('sam@example.com'), 'annual'))::int$$) = 25, 'balance: opening + built up − weekdays taken (25)');
select test.ok(test.n('sam@example.com', '(select count(*) from public.leave_balances)') = 1, 'Sam sees their own');
select test.ok(test.n('kim@example.com', '(select count(*) from public.leave_balances)') = 0, 'other staff don''t');
select test.ok(test.n('kim@example.com', $$(select coalesce(public.leave_balance(test.pid('sam@example.com'), 'annual'), -1))::int$$) = -1, 'and can''t work it out either');
select test.ok(test.n('boss@example.com', '(select count(*) from public.leave_balances)') = 1, 'managers see everyone''s');
select test.act_as('sam@example.com');
set role authenticated;
update public.leave_balances set opening_days = 100;
reset role;
select test.ok((select opening_days from public.leave_balances) = 10, 'staff can''t change their own balance');
select test.refused($$insert into public.leave_balances (user_id, leave_type) values (test.pid('sam@example.com'), 'holiday')$$, 'only annual, personal or long service');

\o
