-- Staff Portal · © cmeproject. All rights reserved.
--
-- Phase 5 (cmeprojects): birthdays (day and month only, shown with consent).

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker'), ('boss@example.com', 'Morgan', 'manager');
insert into auth.users (email) values ('sam@example.com'), ('kim@example.com'), ('boss@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;

select test.act_as('sam@example.com');
set role authenticated;
insert into public.staff_birthdays (user_id, month, day) values (test.pid('sam@example.com'), 3, 14);
select test.refused($$insert into public.staff_birthdays (user_id, month, day) values (test.pid('kim@example.com'), 1, 1)$$, 'nobody sets someone else''s birthday');
select test.refused($$update public.staff_birthdays set month = 2, day = 30$$, 'impossible dates are refused');
reset role;

select test.act_as('kim@example.com');
set role authenticated;
select test.ok((select count(*) from public.staff_birthdays) = 0, 'hidden by default: colleagues don''t see it');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.ok((select count(*) from public.staff_birthdays) = 0, 'not even managers');
reset role;

select test.act_as('sam@example.com');
set role authenticated;
update public.staff_birthdays set show = true;
reset role;
select test.act_as('kim@example.com');
set role authenticated;
select test.ok((select count(*) from public.staff_birthdays) = 1, 'shown once the person chooses to');
select test.refused($$update public.staff_birthdays set show = false$$, 'only the person changes their choice');
reset role;

select set_config('request.jwt.claims', '', false);
update public.profiles set active = false where email = 'sam@example.com';
select test.act_as('kim@example.com');
set role authenticated;
select test.ok((select count(*) from public.staff_birthdays) = 0, 'only active staff appear');
reset role;
select test.ok(not exists (select 1 from information_schema.columns where table_name = 'staff_birthdays' and column_name in ('year', 'birth_date', 'date_of_birth')), 'no year is ever stored');

set role anon;
select test.refused($$select count(*) from public.staff_birthdays$$, 'signed out: nothing');
reset role;
