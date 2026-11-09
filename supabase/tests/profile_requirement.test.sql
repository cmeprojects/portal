-- Staff Portal · © cmeproject. All rights reserved.
--
-- Complete your profile as an onboarding requirement (cmeprojects).

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

update public.features set enabled = true where key = 'hr_profiles';

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('office@example.com', 'Olive', 'staff_admin'), ('new@example.com', 'Nia', 'new_starter');
insert into auth.users (email) values ('office@example.com'), ('new@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;
-- No other onboarding items, so the profile is the only thing left.
update public.compliance_items set active = false;

select test.ok(public.onboarding_missing(test.pid('new@example.com')) = array['Complete your profile'], 'a new starter must complete their profile');
select test.ok(public.onboarding_missing(test.pid('office@example.com')) = array['Complete your profile'], 'so must existing staff while profiles are on');
select test.ok(public.onboarding_missing(test.pid('owner@example.com')) = '{}', 'the system admin doesn''t');

select test.act_as('office@example.com');
set role authenticated;
select test.refused($$update public.profiles set role = 'support_worker' where id = test.pid('new@example.com')$$, 'a new starter can''t get a role before their profile is done');
reset role;

select test.act_as('new@example.com');
set role authenticated;
select public.save_profile(test.pid('new@example.com'), '{"work_phone": "0400 000 001"}');
reset role;
select test.ok(cardinality(public.onboarding_missing(test.pid('new@example.com'))) = 1, 'a phone alone isn''t enough');
select test.act_as('new@example.com');
set role authenticated;
select public.save_profile(test.pid('new@example.com'), '{"emergency_name": "Ma", "emergency_phone": "0400 000 002"}');
reset role;
select test.ok(public.onboarding_missing(test.pid('new@example.com')) = '{}', 'phone and emergency contact complete it');
select test.ok((select onboarded_at is not null from public.profiles where id = test.pid('new@example.com')), 'finishing the profile completes onboarding straight away');

update public.features set enabled = false where key = 'hr_profiles';
select test.ok(public.onboarding_missing(test.pid('office@example.com')) = '{}', 'with profiles switched off, it isn''t required');

\o
\echo All profile requirement tests passed.
