-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 171, Zero Trust review): internal functions can't be called directly.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('lead@example.com', 'Taylor', 'team_leader'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('lead@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.req(p_subject text) returns public.requests language sql security definer as $$ select * from public.requests where subject = p_subject $$;
grant execute on all functions in schema test to authenticated;
insert into public.teams (name) values ('North');
insert into public.team_leaders select id, test.pid('lead@example.com') from public.teams where name = 'North';
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'North';

-- A worker's own leave request, still pending.
select test.act_as('sam@example.com');
set role authenticated;
select public.submit_request('leave', 'Beach week', '{"leave_type": "annual"}', current_date + 30, current_date + 34, null);
select test.refused($$select public.apply_request((test.req('Beach week')).id)$$, 'a worker can''t put their own pending leave into effect (apply_request)');
select test.refused($$select public.notify_many(array[test.pid('boss@example.com')], 'request_escalated', 'Fake notice', 'Approve this', '/requests')$$, 'a worker can''t send notices to others (notify_many)');
select test.refused($$select public.resolve_people(array['managers'], null)$$, 'a worker can''t list approval groups (resolve_people)');
select test.refused($$select public.escalate_requests()$$, 'a worker can''t run the escalation job');
reset role;
select test.ok((test.req('Beach week')).status = 'pending'
  and not exists (select 1 from public.leave_periods where user_id = test.pid('sam@example.com')), 'the leave stays pending and unrecorded');
select test.ok(not exists (select 1 from public.notifications where title = 'Fake notice'), 'no fake notice was made');
-- Managers can't call them directly either.
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$select public.apply_request((test.req('Beach week')).id)$$, 'a manager can''t skip the approval steps (apply_request)');
select test.refused($$select public.notify_many(array[test.pid('sam@example.com')], 'x', 'x', 'x', '/')$$, 'a manager can''t send notices directly (notify_many)');
reset role;
-- What uses them inside the database still works.
select test.ok(exists (select 1 from public.notifications n where n.user_id = test.pid('lead@example.com') and n.kind = 'request_submitted'), 'submitting still tells the approver (notify_many inside the database)');
select test.ok(has_function_privilege('service_role', 'public.escalate_requests()', 'execute'), 'the scheduler (service role) still runs the escalation job');
select test.ok(not has_function_privilege('anon', 'public.notify_many(uuid[], text, text, text, text)', 'execute') and not has_function_privilege('authenticated', 'public.apply_request(uuid)', 'execute'), 'signed-out and signed-in requests have no access to them');

\o
select 'All internal function tests passed.';
