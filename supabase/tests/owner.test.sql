-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects: the owner can't be turned off, demoted, renamed, reset or
-- signed out by another system admin (for example an outside reviewer).

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('admin2@example.com', 'Riley Reviewer', 'system_admin'), ('boss@example.com', 'Morgan', 'manager');
insert into auth.users (email) values ('admin2@example.com'), ('boss@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;
-- Set in the database (SQL editor), as on a real copy.
update public.profiles set is_owner = true where email = 'owner@example.com';
insert into auth.sessions (id, user_id) values (gen_random_uuid(), test.pid('owner@example.com')), (gen_random_uuid(), test.pid('boss@example.com'));

select test.act_as('admin2@example.com');
set role authenticated;
select test.refused($$update public.profiles set active = false where email = 'owner@example.com'$$, 'another system admin can''t turn the owner off');
select test.refused($$update public.profiles set role = 'manager' where email = 'owner@example.com'$$, 'or change the owner''s role');
select test.refused($$update public.profiles set full_name = 'Someone else' where email = 'owner@example.com'$$, 'or rename the owner');
select test.refused($$update public.profiles set is_owner = true where email = 'admin2@example.com'$$, 'or make themselves the owner');
select test.ok(not public.can_help_sign_in(test.pid('owner@example.com')), 'or reset the owner''s two-factor or password');
select test.refused($$select public.sign_out_everywhere(test.pid('owner@example.com'))$$, 'or sign the owner out');
select test.ok(public.sign_out_everyone() >= 1, 'signing everyone out still works');
reset role;
select test.ok((select count(*) from auth.sessions where user_id = test.pid('owner@example.com')) = 1, '... but the owner stays signed in');
select test.ok((select count(*) from auth.sessions where user_id = test.pid('boss@example.com')) = 0, '... and everyone else is signed out');

select test.act_as('admin2@example.com');
set role authenticated;
update public.profiles set role = 'manager' where email = 'boss@example.com';
select test.ok((select role from public.profiles where email = 'boss@example.com') = 'manager', 'other people are managed as before');
reset role;

select test.act_as('owner@example.com');
set role authenticated;
update public.profiles set active = false where email = 'admin2@example.com';
select test.ok(not (select active from public.profiles where email = 'admin2@example.com'), 'the owner can turn off the other system admin');
select test.ok(public.can_help_sign_in(test.pid('admin2@example.com')), 'and help them sign in');
reset role;
