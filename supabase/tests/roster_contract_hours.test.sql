-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 169): contracted weekly hours for the roster.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com'), ('kim@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;
select test.act_as('owner@example.com');
set role authenticated;
insert into public.admin_designations (user_id, granted_by) values (test.pid('boss@example.com'), test.pid('owner@example.com'));
reset role;

select test.act_as('boss@example.com');
set role authenticated;
insert into public.staff_contract_hours (user_id, hours_per_week) values (test.pid('sam@example.com'), 38), (test.pid('kim@example.com'), 20);
select test.refused($$update public.staff_contract_hours set hours_per_week = 90 where user_id = test.pid('kim@example.com')$$, 'contracted hours are 0 to 80 a week');
update public.staff_contract_hours set hours_per_week = 24 where user_id = test.pid('kim@example.com');
reset role;
select test.ok((select hours_per_week = 24 and set_by = test.pid('boss@example.com') from public.staff_contract_hours where user_id = test.pid('kim@example.com')), 'a roster editor sets and changes contracted hours (who set them is kept)');
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$update public.staff_contract_hours set hours_per_week = 10 where user_id = test.pid('sam@example.com')$$, 'a support worker can''t change contracted hours');
select test.ok((select count(*) = 1 from public.staff_contract_hours), 'a support worker sees only their own contracted hours');
reset role;
