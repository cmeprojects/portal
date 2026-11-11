-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects step 1: the module catalogue (read-only) and pinned shortcuts (your own only).

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('sam@example.com'), ('kim@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;

select test.ok((select count(*) from public.app_modules) >= 40, 'the catalogue lists the modules');
select test.ok((select count(*) from public.app_modules where sensitivity = 'protected') >= 4, 'system modules are marked protected');
select test.ok(not exists (select 1 from public.app_modules m where m.parent_id is not null and not exists (select 1 from public.app_modules p where p.id = m.parent_id)), 'every submodule has its module');

select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.app_modules) >= 40, 'staff can read the catalogue (it grants nothing)');
select test.refused($$update public.app_modules set label = 'x'$$, 'nobody changes the catalogue from the app');
select test.refused($$insert into public.app_modules (id, category, label) values ('x.y', 'workspace', 'X')$$, 'or adds to it');
insert into public.pinned_items (user_id, href, label) values (test.pid('sam@example.com'), '/onboarding', 'My onboarding');
select test.refused($$insert into public.pinned_items (user_id, href, label) values (test.pid('kim@example.com'), '/', 'Home')$$, 'nobody pins for someone else');
select test.refused($$insert into public.pinned_items (user_id, href, label) values (test.pid('sam@example.com'), 'https://evil.example', 'x')$$, 'only portal pages can be pinned');
reset role;
select test.act_as('kim@example.com');
set role authenticated;
select test.ok((select count(*) from public.pinned_items) = 0, 'pins are private');
select test.refused($$delete from public.pinned_items$$, 'and can''t be removed by others');
reset role;
set role anon;
select test.refused($$select count(*) from public.app_modules$$, 'signed out: nothing');
reset role;
