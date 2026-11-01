-- Staff Portal · © cmeproject. All rights reserved.
--
-- Enquiry intake: a new enquiry becomes a Call back task for the staff admin
-- (or whoever the system admin chose), due the next business day.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
update public.features set enabled = true, included = true where key = 'assistant';

select test.ok(public.next_business_day('2026-11-06') = '2026-11-09', 'Friday''s enquiry is due Monday');
select test.ok(public.next_business_day('2026-12-24') = '2026-12-29', 'Christmas Eve''s is due after the holidays');
select test.ok(public.next_business_day('2026-11-03') = '2026-11-04', 'a weekday''s is due the next day');

insert into public.website_enquiries (full_name, phone, needs, consent) values ('Pat Sample', '0400 000 000', array['Community access'], true);
select test.ok(exists (select 1 from public.tasks where title = 'Call back: Pat Sample' and assigned_to = test.pid('office@example.com')
                       and priority = 'high' and due_date = public.next_business_day(public.local_today()) and description like '%Community access%'),
  'it''s a Call back task for the staff admin, due the next business day');
select test.ok(exists (select 1 from public.notifications where user_id = test.pid('office@example.com') and kind = 'task_assigned'), 'with a bell note');
select test.ok(exists (select 1 from public.email_outbox where to_user = test.pid('office@example.com')),
  'and an email waiting to go');

update public.app_settings set value = '["manager"]' where key = 'assistant.intake_roles';
insert into public.website_enquiries (full_name, phone, consent) values ('Jo Test', '0400 000 001', true);
select test.ok(exists (select 1 from public.tasks where title = 'Call back: Jo Test' and assigned_to = test.pid('boss@example.com')), 'the system admin can change who does intake');

\o
\echo All enquiry intake tests passed.
