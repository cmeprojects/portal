-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 137, AUD-016 Stage 6): more than one job title per person.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.title(p_name text) returns uuid language sql security definer as $$ select id from public.job_titles where name = p_name $$;
create function test.extras(p_email text) returns uuid[] language sql security definer as $$ select extra_job_title_ids from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;
update public.profiles set job_title_id = test.title('Support Worker') where email = 'sam@example.com';

select test.act_as('sam@example.com');
set role authenticated;
select test.ok(not public.can('ops.roster', 'edit'), 'a support worker doesn''t roster');
select test.refused($$update public.profiles set extra_job_title_ids = array[test.title('Rostering Officer')] where id = auth.uid()$$, 'nobody gives themselves an extra job title');
reset role;

select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.profiles set extra_job_title_ids = array[test.title('Manager')] where email = 'sam@example.com'$$, 'an extra job title must be at their own access level');
update public.profiles set extra_job_title_ids = array[test.title('Rostering Officer')] where email = 'sam@example.com';
reset role;

select test.act_as('sam@example.com');
set role authenticated;
select test.ok(public.can('ops.roster', 'edit'), 'an extra job title adds its defaults');
select test.ok(not public.can('clients.funding', 'view'), 'but nothing the titles don''t give');
reset role;

select test.ok((select count(*) from public.audit_log where action = 'extra_job_titles_changed') = 1, 'giving an extra job title is logged');
update public.job_titles set active = false where name = 'Rostering Officer';
select test.act_as('sam@example.com');
set role authenticated;
select test.ok(not public.can('ops.roster', 'edit'), 'a switched-off job title gives nothing');
reset role;
update public.job_titles set active = true where name = 'Rostering Officer';

select test.act_as('boss@example.com');
set role authenticated;
update public.profiles set job_title_id = test.title('Team Leader') where email = 'sam@example.com';
reset role;
select test.ok(cardinality(test.extras('sam@example.com')) = 0, 'a new access level drops extra titles that no longer fit');
\o
select 'All extra job title tests passed.';
