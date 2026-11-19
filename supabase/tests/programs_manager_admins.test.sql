-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 152): Manager Administrators manage programs and schemes;
-- other managers and staff can't (unless given the Care settings area).
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('boss2@example.com', 'Max', 'manager'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('boss2@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;
-- Morgan is a Manager Administrator (named by the system admin); Max is an ordinary manager.
select test.act_as('owner@example.com');
set role authenticated;
insert into public.admin_designations (user_id, granted_by) values (test.pid('boss@example.com'), test.pid('owner@example.com'));
reset role;

select test.act_as('boss@example.com');
set role authenticated;
select test.ok(public.is_manager_admin(), 'Morgan is a Manager Administrator');
insert into public.client_programs (name, scheme, sort_order) values ('NDIS – Plan managed', 'ndis', 15);
update public.client_programs set name = 'NDIS – Plan managed (new)' where name = 'NDIS – Plan managed';
update public.client_schemes set review_label = 'Plan reassessment' where key = 'ndis';
reset role;
select test.ok(exists (select 1 from public.client_programs where name = 'NDIS – Plan managed (new)'), 'a Manager Administrator adds and renames a program');
select test.ok((select review_label from public.client_schemes where key = 'ndis') = 'Plan reassessment', 'and changes a scheme''s wording');

select test.act_as('boss2@example.com');
set role authenticated;
select test.refused($$insert into public.client_programs (name, scheme) values ('Sneaky', 'private')$$, 'an ordinary manager can''t add programs');
update public.client_schemes set review_label = 'Changed' where key = 'ndis';
reset role;
select test.ok((select review_label from public.client_schemes where key = 'ndis') = 'Plan reassessment', 'or change a scheme''s wording');

select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$insert into public.client_programs (name, scheme) values ('Sneaky', 'private')$$, 'staff can''t add programs');
select test.ok((select count(*) from public.client_programs) >= 5, 'but everyone can read the programs (to choose one on a service)');
reset role;
\o
select 'All programs and schemes tests passed.';
