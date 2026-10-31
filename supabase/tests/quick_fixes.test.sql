-- Staff Portal · © cmeproject. All rights reserved.
--
-- Update 37: forms to fill in, who sees enquiries, the wrong-password lock,
-- Compliance as a premium add-on, deleting unused built features.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin'),
  ('sam@example.com', 'Sam', 'support_worker'), ('lee@example.com', 'Lee', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('sam@example.com'), ('lee@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.form(p_title text) returns uuid language sql security definer as $$ select id from public.forms where title = p_title $$;
create function test.fills(p_title text) returns boolean language sql as $$ select test.form(p_title) in (select public.my_forms_to_fill()) $$;
grant execute on all functions in schema test to authenticated;

update public.features set enabled = true, included = true where key in ('forms', 'assistant');

-- Three published forms: open to all, sent to Sam, in Compliance for staff admins.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.forms (title, created_by, status, enabled) values
  ('Open survey', test.pid('boss@example.com'), 'published', true),
  ('Sam only', test.pid('boss@example.com'), 'published', true),
  ('Office check', test.pid('boss@example.com'), 'published', true);
reset role;
insert into public.form_recipients (form_id, user_id) values (test.form('Sam only'), test.pid('sam@example.com'));
insert into public.compliance_items (kind, title, form_id, applies_roles)
  values ('form', 'Office check', test.form('Office check'), array['staff_admin']::public.app_role[]);

select test.act_as('sam@example.com');
set role authenticated;
select test.ok(test.fills('Open survey'), 'an open form is in everyone''s To fill in');
select test.ok(test.fills('Sam only'), 'a form sent to Sam is in his list');
select test.ok(not test.fills('Office check'), 'a Compliance form for staff admins isn''t in Sam''s list');
reset role;
select test.act_as('lee@example.com');
set role authenticated;
select test.ok(not test.fills('Sam only'), 'Lee doesn''t get the form sent only to Sam');
reset role;
select test.act_as('office@example.com');
set role authenticated;
select test.ok(test.fills('Office check'), 'the staff admin gets the Compliance form');
reset role;

-- Enquiries: managers by default; the system admin can change who.
insert into public.website_enquiries (full_name, phone, consent) values ('Pat', '0400 000 000', true);
select test.act_as('boss@example.com');
set role authenticated;
select test.ok(public.can_see_enquiries() and (select count(*) from public.website_enquiries) = 1, 'managers see enquiries by default');
reset role;
select test.act_as('office@example.com');
set role authenticated;
select test.ok(not public.can_see_enquiries() and (select count(*) from public.website_enquiries) = 0, 'staff admins don''t, by default');
reset role;
update public.app_settings set value = '["staff_admin"]' where key = 'assistant.enquiry_roles';
select test.act_as('office@example.com');
set role authenticated;
select test.ok((select count(*) from public.website_enquiries) = 1, 'once chosen, staff admins see them');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.ok((select count(*) from public.website_enquiries) = 0, 'and managers no longer do');
reset role;
insert into public.website_enquiries (full_name, phone, consent) values ('Jo', '0400 000 001', true);
select test.ok(exists (select 1 from public.notifications where kind = 'website_enquiry' and user_id = test.pid('office@example.com') and title like '%Jo'), 'the chosen role gets the bell');
select test.ok(not exists (select 1 from public.notifications where kind = 'website_enquiry' and user_id = test.pid('boss@example.com') and title like '%Jo'), 'others don''t');

-- Wrong passwords.
set role service_role;
select public.sign_in_guard('Sam@Example.com', 'fail') as a1 \gset
select public.sign_in_guard('sam@example.com', 'fail'), public.sign_in_guard('sam@example.com', 'fail'), public.sign_in_guard('sam@example.com', 'fail');
select public.sign_in_guard('sam@example.com', 'fail') as a5 \gset
select public.sign_in_guard('sam@example.com', 'check') as locked \gset
select public.sign_in_guard('lee@example.com', 'check') as lee \gset
reset role;
select test.ok(:a1 = 0, 'one wrong password doesn''t lock');
select test.ok(:a5 = 15 and :locked between 14 and 15, 'the fifth locks it for 15 minutes');
select test.ok(:lee = 0, 'other people aren''t affected');
update public.sign_in_failures set locked_until = now() - interval '1 minute';
set role service_role;
select public.sign_in_guard('sam@example.com', 'check') as after \gset
select public.sign_in_guard('sam@example.com', 'ok') as ok \gset
reset role;
select test.ok(:after = 0 and not exists (select 1 from public.sign_in_failures), 'after 15 minutes they can try again, and signing in clears it');
set role authenticated;
select test.refused($$select * from public.sign_in_failures$$, 'signed-in people can''t see the lock list');
select test.refused($$select public.sign_in_guard('x@example.com', 'ok')$$, 'or call the guard');
reset role;

-- Compliance off: nothing can be added to it.
update public.features set enabled = false where key = 'compliance';
select test.refused($$insert into public.compliance_items (kind, title) values ('read', 'Policy')$$, 'with Compliance off, nothing is added to it');
update public.features set enabled = true where key = 'compliance';

\o
\echo All quick fix tests passed.
