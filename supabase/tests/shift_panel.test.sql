-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 141): shift types list, notify worker, pay class, notes, signatures.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com'), ('kim@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.sid(p_who text) returns uuid language sql security definer as $$ select id from public.shifts where worker_id = (select id from public.profiles where email = p_who) limit 1 $$;
grant execute on all functions in schema test to authenticated;

select test.ok((select count(*) from public.shift_types where key in ('support_coordination', 'respite_care', 'gardening', 'on_call')) = 4, 'the owner''s shift types are there');
select test.ok((select label from public.shift_types where key = 'admin') = 'Office work', 'existing types kept, renamed to the owner''s wording');

-- Who manages the list.
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.shift_types) > 20, 'staff read the list');
select test.refused($$insert into public.shift_types (key, label) values ('joyride', 'Joyride')$$, 'staff can''t add a type');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.shift_types set label = 'X' where key = 'gardening'$$, 'a manager who isn''t a Manager Administrator can''t change them');
reset role;
select test.act_as('owner@example.com');
set role authenticated;
insert into public.shift_types (key, label) values ('hydrotherapy', 'Hydrotherapy');
select test.refused($$delete from public.shift_types where key = 'hydrotherapy'$$, 'types are switched off, never deleted');
reset role;

-- Shifts use the list.
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.shifts (worker_id, starts_at, ends_at, status, shift_type) values (test.pid('sam@example.com'), now() + interval '1 day', now() + interval '1 day 2 hours', 'draft', 'made_up')$$, 'a shift type must be on the list');
insert into public.shifts (worker_id, starts_at, ends_at, status, shift_type, notify_worker, pay_class, extra_notes, signatures_needed, notes)
values (test.pid('sam@example.com'), now() + interval '1 day', now() + interval '1 day 2 hours', 'published', 'hydrotherapy', false, 'casual', 'Parking at the back.', '{worker_in,representative_out}', 'Pool session'),
       (test.pid('kim@example.com'), now() + interval '2 days', now() + interval '2 days 2 hours', 'published', 'gardening', true, 'regular', '', '{}', '');
select test.refused($$update public.shifts set pay_class = 'salaried' where worker_id = test.pid('sam@example.com')$$, 'pay class is regular or casual');
reset role;
select test.ok((select needs_worker_signature and needs_client_signature from public.shifts where id = test.sid('sam@example.com')), 'the older signature switches follow the new list');
update public.shifts set needs_worker_signature = true where id = test.sid('kim@example.com');
select test.ok((select signatures_needed from public.shifts where id = test.sid('kim@example.com')) = '{worker_in,worker_out}', 'and the list follows the older switches (copy and paste)');

-- Notify worker unticked: no notice, but marked as done.
select public.run_roster_alerts();
select test.ok((select count(*) from public.notifications where user_id = test.pid('sam@example.com') and kind = 'shift_published') = 0, 'notify unticked: no notice');
select test.ok((select notified_at is not null from public.shifts where id = test.sid('sam@example.com')), 'but it''s not sent later either');
select test.ok((select count(*) from public.notifications where user_id = test.pid('kim@example.com') and kind = 'shift_published') = 1, 'notify ticked: the worker is told');

-- The worker sees their instructions and notes, never internal notes.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.shift_notes (shift_id, body) values (test.sid('sam@example.com'), 'Internal: check Sam''s timesheet.');
reset role;
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select extra_notes from public.shifts where id = test.sid('sam@example.com')) = 'Parking at the back.', 'the worker reads the additional notes');
select test.ok((select count(*) from public.shift_notes) = 0, 'but never the internal notes');
reset role;
\o
select 'All shift panel tests passed.';
