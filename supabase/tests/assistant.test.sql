-- Staff Portal · © cmeproject. All rights reserved.
--
-- Website and Assistant: only the system admin manages documents and
-- settings; managers (not staff) see the enquiries; the search only returns
-- documents the visitor's kind may use; the website's server (service role)
-- is the only way in for the public.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com');
create function test.doc(p_title text) returns uuid language sql security definer as $$ select id from public.assistant_documents where title = p_title $$;
grant execute on all functions in schema test to authenticated;

select test.act_as('owner@example.com');
set role authenticated;
insert into public.assistant_documents (title, audience, body) values
  ('Cancellation Policy', 'public', E'Please cancel at least two days before a visit.\n\nShort notice cancellations may be charged.'),
  ('Medication Policy', 'staff', E'Staff must record every medication given to a client in the register.'),
  ('Approval Rules', 'managers', E'Managers approve every role change before it starts.');
select test.ok(public.assistant_index(test.doc('Cancellation Policy')) >= 1, 'the system admin can index a document');
select public.assistant_index(test.doc('Medication Policy'));
select public.assistant_index(test.doc('Approval Rules'));
select test.ok((select count(*) from public.assistant_documents) = 3, 'the system admin sees the library');
update public.assistant_settings set model = 'sonnet', monthly_limit_aud = 20;
select test.ok((select model from public.assistant_settings) = 'sonnet', 'the system admin changes the settings');
reset role;

-- Others can't see or change documents or settings.
select test.act_as('boss@example.com');
set role authenticated;
select test.ok((select count(*) from public.assistant_documents) = 0, 'a manager sees no documents');
select test.ok((select count(*) from public.assistant_settings) = 0, 'a manager sees no settings');
select test.refused($$insert into public.assistant_documents (title, body) values ('Mine', 'x')$$, 'a manager can''t add a document');
select test.refused($$select public.assistant_index(test.doc('Cancellation Policy'))$$, 'a manager can''t index');
select test.refused($$select * from public.assistant_chunks$$, 'chunks are not open to signed-in people');
reset role;

-- The public can't touch anything directly.
set role anon;
select test.refused($$select * from public.assistant_documents$$, 'the public can''t read documents');
select test.refused($$insert into public.website_enquiries (full_name, phone) values ('Pat', '0400000000')$$, 'the public can''t insert directly');
reset role;

-- Search respects who is asking (as the website's server does).
set role service_role;
select count(*) as n_pub  from public.assistant_search('cancel visit', array['public']) \gset
select count(*) as n_pub_staff from public.assistant_search('medication register', array['public']) \gset
select count(*) as n_staff from public.assistant_search('medication register', array['public', 'staff']) \gset
select count(*) as n_staff_mgr from public.assistant_search('approve role change', array['public', 'staff']) \gset
select count(*) as n_mgr from public.assistant_search('approve role change', array['public', 'staff', 'managers']) \gset
insert into public.website_enquiries (full_name, phone, support_for, needs, consent) values ('Pat Sample', '0400 000 000', 'Me', array['Community access'], true);
insert into public.assistant_questions (question, audience, answered, cost_usd) values ('Cancel?', 'public', true, 0.001);
select last_hour as n_hour from public.assistant_usage() \gset
reset role;
select test.ok(:n_pub >= 1, 'public visitors find the public policy');
select test.ok(:n_pub_staff = 0, 'public visitors can''t find staff-only text');
select test.ok(:n_staff >= 1, 'staff find staff-only text');
select test.ok(:n_staff_mgr = 0, 'staff can''t find managers-only text');
select test.ok(:n_mgr >= 1, 'managers find managers-only text');
select test.ok(:n_hour = 1, 'usage counts the question');
select test.ok(exists (select 1 from public.notifications where kind = 'website_enquiry' and user_id = (select id from public.profiles where email = 'boss@example.com')), 'a new enquiry rings the manager''s bell');

-- Managers see and update enquiries; staff don't.
select test.act_as('boss@example.com');
set role authenticated;
select test.ok((select count(*) from public.website_enquiries) = 1, 'a manager sees the enquiry');
select test.ok(public.new_enquiry_count() = 1, 'and the count of new ones');
update public.website_enquiries set status = 'called', note = 'Left a message';
select test.ok((select status from public.website_enquiries) = 'called', 'a manager moves it on');
reset role;
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.website_enquiries) = 0, 'a support worker sees no enquiries');
select test.ok(public.new_enquiry_count() = 0, 'and no count');
reset role;

\o
\echo All assistant tests passed.
