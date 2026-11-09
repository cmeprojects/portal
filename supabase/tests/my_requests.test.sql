-- Staff Portal · © cmeproject. All rights reserved.
--
-- My requests (cmeprojects, HR Pack).

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin'), ('lead@example.com', 'Taylor', 'team_leader'), ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker'), ('ash@example.com', 'Ash', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('lead@example.com'), ('sam@example.com'), ('kim@example.com'), ('ash@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.req(p_subject text) returns public.requests language sql security definer as $$ select * from public.requests where subject = p_subject $$;
create function test.notes(p_email text, p_kind text) returns bigint language sql security definer as $$ select count(*) from public.notifications n join public.profiles p on p.id = n.user_id where p.email = p_email and n.kind = p_kind $$;
grant execute on all functions in schema test to authenticated;
insert into public.teams (name) values ('North');
insert into public.team_leaders select id, test.pid('lead@example.com') from public.teams where name = 'North';
insert into public.team_members (team_id, user_id) select id, u from public.teams, unnest(array[test.pid('sam@example.com'), test.pid('kim@example.com')]) u where name = 'North';

-- Leave: team leader first, then the manager; approval makes a leave period.
select test.act_as('sam@example.com');
set role authenticated;
select public.submit_request('leave', 'Christmas leave', '{"leave_type": "annual"}', '2026-12-22', '2026-12-29', null);
select test.refused($$select public.submit_request('leave', 'x', '{}', '2026-12-22', '2026-12-01', null)$$, 'an end date before the start is refused');
select test.refused($$select public.request_action((test.req('Christmas leave')).id, 'approve')$$, 'the person can''t approve their own request');
reset role;
select test.ok((test.req('Christmas leave')).status = 'pending' and public.request_ref((test.req('Christmas leave')).id) like 'REQ-%', 'a request gets a reference and starts pending');
select test.ok(test.notes('lead@example.com', 'request_submitted') = 1 and test.notes('boss@example.com', 'request_submitted') = 0, 'the team leader is told first, not the manager');

select test.act_as('kim@example.com');
set role authenticated;
select test.ok((select count(*) from public.requests) = 0, 'colleagues can''t see someone else''s request');
reset role;

select test.act_as('lead@example.com');
set role authenticated;
select public.request_action((test.req('Christmas leave')).id, 'info', 'Who covers your shifts?');
reset role;
select test.ok((test.req('Christmas leave')).status = 'info_needed', 'an approver asks for more information');
select test.act_as('sam@example.com');
set role authenticated;
select public.request_action((test.req('Christmas leave')).id, 'comment', 'Kim covers them.');
reset role;
select test.ok((test.req('Christmas leave')).status = 'pending', 'the person''s reply puts it back to pending');
select test.act_as('lead@example.com');
set role authenticated;
select public.request_action((test.req('Christmas leave')).id, 'approve', '');
reset role;
select test.ok((test.req('Christmas leave')).stage = 2 and (test.req('Christmas leave')).status = 'pending', 'first approval moves it to the second approver');
select test.ok(test.notes('boss@example.com', 'request_submitted') = 1, 'the manager is told for final approval');
select test.ok((select count(*) from public.leave_periods) = 0, 'no leave yet before final approval');
select test.act_as('lead@example.com');
set role authenticated;
select test.refused($$select public.request_action((test.req('Christmas leave')).id, 'approve', '')$$, 'the team leader can''t do the second approval too');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select public.request_action((test.req('Christmas leave')).id, 'approve', 'Enjoy.');
reset role;
select test.ok((test.req('Christmas leave')).status = 'approved', 'final approval');
select test.ok((select leave_type || ' ' || start_date || ' ' || end_date from public.leave_periods) = 'annual 2026-12-22 2026-12-29', 'approved leave becomes a leave period');
select test.ok((select count(*) from public.request_events where request_id = (test.req('Christmas leave')).id) = 5, 'the full history is kept (sent, info asked, reply, first and final approval)');

-- Shift swap: the partner accepts first; approval records it for both.
select test.act_as('sam@example.com');
set role authenticated;
select public.submit_request('swap', 'Swap Friday', '{"my_shift": "Fri 3 pm–11 pm"}', '2026-12-04', null, test.pid('kim@example.com'));
reset role;
select test.act_as('lead@example.com');
set role authenticated;
select test.refused($$select public.request_action((test.req('Swap Friday')).id, 'approve', '')$$, 'a swap can''t be approved before the colleague accepts');
reset role;
select test.act_as('kim@example.com');
set role authenticated;
select public.request_action((test.req('Swap Friday')).id, 'partner_accept', '');
reset role;
select test.act_as('lead@example.com');
set role authenticated;
select public.request_action((test.req('Swap Friday')).id, 'approve', '');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select public.request_action((test.req('Swap Friday')).id, 'approve', '');
reset role;
select test.ok((select count(*) from public.shift_changes where request_id = (test.req('Swap Friday')).id) = 2, 'an approved swap is recorded for both people');

-- HR enquiry: staff admin, then manager. Ash has no team leader.
select test.act_as('ash@example.com');
set role authenticated;
select public.submit_request('hr', 'Pay question', '{"message": "My last pay looks short."}', null, null, null);
reset role;
select test.ok(test.notes('office@example.com', 'request_submitted') = 1, 'HR enquiries go to the staff admin first');
select test.act_as('office@example.com');
set role authenticated;
select test.refused($$select public.request_action((test.req('Pay question')).id, 'decline', '')$$, 'declining needs a reason');
select public.request_action((test.req('Pay question')).id, 'decline', 'Pay was correct; see your payslip.');
reset role;
select test.ok((test.req('Pay question')).status = 'declined', 'a staff admin declines with a reason');

-- Availability change updates the weekly availability.
select test.act_as('ash@example.com');
set role authenticated;
select public.submit_request('availability', 'Mornings only', '{"availability": {"mon": ["am"], "tue": ["am"]}}', '2026-12-01', null, null);
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select public.request_action((test.req('Mornings only')).id, 'approve', '');
select public.request_action((test.req('Mornings only')).id, 'approve', '');
reset role;
select test.ok((select availability -> 'mon' from public.staff_private where user_id = test.pid('ash@example.com')) = '["am"]', 'an approved availability change updates their availability (no team leader: managers approve)');

-- Withdraw, switches and escalation
select test.act_as('sam@example.com');
set role authenticated;
select public.submit_request('other', 'Locker key', '{"message": "Need a locker."}', null, null, null);
select public.request_action((test.req('Locker key')).id, 'withdraw', '');
reset role;
select test.ok((test.req('Locker key')).status = 'withdrawn', 'the person withdraws a pending request');
update public.features set enabled = false where key = 'hr_req_swap';
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$select public.submit_request('swap', 'x', '{}', '2026-12-04', null, test.pid('kim@example.com'))$$, 'a switched-off request type can''t be sent');
select public.submit_request('timesheet', 'Wrong finish time', '{"date": "2026-11-02"}', null, null, null);
reset role;
update public.requests set updated_at = now() - interval '5 days' where subject = 'Wrong finish time';
select test.ok(public.escalate_requests() = 1 and test.notes('boss@example.com', 'request_escalated') = 1, 'a request left unattended is escalated to the manager');
select test.ok(public.escalate_requests() = 0, 'and only once');

\o
\echo All My requests tests passed.
