-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects audit Stage B (update 81): "onboarding complete" includes bank,
-- super, right to work and TFN; checked right to work is needed before
-- clearing; the rest has 7 days; nobody's clearance is removed automatically.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

-- This test checks the pay and work-rights steps, so test people start without them.
drop trigger if exists test_fill_pay on public.profiles;
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com');
insert into public.invitations (email, full_name) values ('new@example.com', 'Nico');
insert into auth.users (email) values ('new@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;
set session_replication_role = replica;
update public.features set enabled = true, included = true where key = 'compliance';
-- Keep the checklist out of the way: nothing on it is needed before working here.
update public.compliance_items set before_work = false;
set session_replication_role = origin;
-- Sam was working before (cleared), with no right-to-work record.
update public.profiles set cleared_at = now() - interval '30 days' where email = 'sam@example.com';

select test.ok(public.can_work(test.pid('sam@example.com')), 'someone already cleared keeps working without a checked right to work (nothing removed)');
select test.ok('Bank account for your pay' = any (public.onboarding_missing(test.pid('new@example.com'))) and 'Tax file number declaration' = any (public.onboarding_missing(test.pid('new@example.com'))),
  '"onboarding complete" now includes bank and TFN');
select test.ok('Right to work in Australia (checked)' = any (public.onboarding_missing(test.pid('new@example.com'))), 'and right to work');
select test.ok(cardinality(public.pay_onboarding_missing(test.pid('owner@example.com'))) = 0, 'not for the system admin');

select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$select public.grant_clearance(test.pid('new@example.com'), 'ok')$$, 'can''t clear before right to work is checked');
select test.ok((public.work_status(test.pid('new@example.com')) -> 'before_work_missing') ? 'Right to work in Australia (checked)', 'shown as needed before working');
reset role;

-- Right to work checked: clearing works; bank, super and TFN have 7 days.
set session_replication_role = replica;
insert into public.staff_work_rights (user_id, status, verified_at) values (test.pid('new@example.com'), 'citizen', now());
set session_replication_role = origin;
select test.act_as('boss@example.com');
set role authenticated;
select public.grant_clearance(test.pid('new@example.com'), 'Minimum met');
select test.ok((public.work_status(test.pid('new@example.com')) ->> 'cleared')::boolean, 'cleared once right to work is checked');
select test.ok((public.work_status(test.pid('new@example.com')) ->> 'finish_by')::date = public.local_today() + 7, 'the rest is due in 7 days');
select test.ok((public.work_status(test.pid('new@example.com')) -> 'still_to_finish') ? 'Superannuation', 'super is still to finish');
select test.ok((public.work_status(test.pid('new@example.com')) ->> 'cleared_note') = 'Minimum met', 'the clearance note is shown');
select test.ok(not (public.work_status(test.pid('new@example.com')) ->> 'onboarding_complete')::boolean, 'not complete while bank, super and TFN are outstanding');
reset role;
select test.ok((select body from public.notifications where user_id = test.pid('new@example.com') and kind = 'cleared_to_work') like '%(7 days)%', 'the notice gives the 7-day date');
select test.ok(public.can_work(test.pid('new@example.com')), 'works while the rest is outstanding');
