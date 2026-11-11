-- Staff Portal · © cmeproject. All rights reserved.
--
-- Update 40: a manager given "Website" looks after where the Assistant looks
-- and its documents; others can't. Staff admins can change a staff
-- member's name. The website is the front page.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('boss2@example.com', 'Max', 'manager'),
  ('office@example.com', 'Olive', 'staff_admin'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('boss2@example.com'), ('office@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;

select test.ok((select value from public.app_settings where key = 'website.front_page') = 'true'::jsonb, 'the website is the front page');

select test.act_as('owner@example.com');
set role authenticated;
select public.set_delegation(test.pid('boss@example.com'), array['website']);
reset role;

select test.act_as('boss@example.com');
set role authenticated;
update public.assistant_settings set scope_public = 'both';
select test.ok((select scope_public from public.assistant_settings) = 'both', 'a manager given Website changes where it looks');
insert into public.assistant_documents (title, audience, body) values ('Rosters', 'staff', 'Rosters are sent every Friday.');
select test.ok(public.assistant_index((select id from public.assistant_documents where title = 'Rosters')) >= 1, 'and adds documents');
update public.app_settings set value = '"Back soon"' where key = 'website.closed_title';
select test.ok((select value from public.app_settings where key = 'website.closed_title') = '"Back soon"'::jsonb, 'and the website wording');
reset role;

select test.act_as('boss2@example.com');
set role authenticated;
select test.ok((select count(*) from public.assistant_settings) = 0, 'another manager can''t see Website settings');
select test.refused($$insert into public.assistant_documents (title, body) values ('Mine', 'Some words here')$$, 'or add documents');
reset role;

-- Names: a staff admin with Staff details access can fix a staff member's name
-- (cmeprojects Phase 2: access is given by the system admin).
select test.act_as('office@example.com');
set role authenticated;
select test.refused($$update public.profiles set full_name = 'Samuel Sample' where id = test.pid('sam@example.com')$$, 'not without Staff details access');
reset role;
select test.act_as('owner@example.com');
set role authenticated;
insert into public.access_grants (area, user_id, granted_by) values ('staff_details', test.pid('office@example.com'), test.pid('owner@example.com'));
reset role;
select test.act_as('office@example.com');
set role authenticated;
update public.profiles set full_name = 'Samuel Sample' where id = test.pid('sam@example.com');
reset role;
select test.ok((select full_name from public.profiles where email = 'sam@example.com') = 'Samuel Sample', 'a staff admin changes a staff member''s name');
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$update public.profiles set full_name = 'Boss' where id = test.pid('boss@example.com')$$, 'a support worker can''t rename others');
reset role;

-- Code audit: task titles can't be read through task_label().
set role authenticated;
select test.refused($$select public.task_label(gen_random_uuid())$$, 'task_label can''t be called directly');
reset role;
set role anon;
select test.refused($$select public.task_label(gen_random_uuid())$$, 'not by the public either');
reset role;

\o
\echo All round 2 tests passed.
