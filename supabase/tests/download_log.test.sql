-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 154): the download trail.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;
select test.act_as('owner@example.com');
set role authenticated;
insert into public.admin_designations (user_id, granted_by) values (test.pid('boss@example.com'), test.pid('owner@example.com'));
reset role;

select test.act_as('sam@example.com');
set role authenticated;
insert into public.download_log (kind, label, user_id) values ('export', 'Staff list export', test.pid('boss@example.com'));
select test.ok((select count(*) from public.download_log) = 0, 'staff can record a download but not read the trail');
select test.refused($$update public.download_log set label = 'changed'$$, 'or change it') ;
reset role;
select test.ok((select user_id from public.download_log) = test.pid('sam@example.com'), 'it is always recorded as the person who downloaded');

select test.act_as('boss@example.com');
set role authenticated;
select test.ok((select count(*) from public.download_log) = 1, 'a Manager Administrator reads the trail');
select test.refused($$delete from public.download_log$$, 'entries are never deleted');
reset role;
\o
select 'All download trail tests passed.';
