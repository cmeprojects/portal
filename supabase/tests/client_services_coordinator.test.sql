-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 136, AUD-016 Stage 5): Client Services Coordinator defaults.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role, job_title_id)
select 'csc@example.com', 'Casey', 'support_worker', id from public.job_titles where name = 'Client Services Coordinator';
insert into auth.users (email) values ('csc@example.com');
insert into public.car_clients (name, status) values ('Test Client', 'active');
create function test.cid() returns uuid language sql security definer as $$ select id from public.car_clients where name = 'Test Client' $$;
grant execute on all functions in schema test to authenticated;

select test.act_as('csc@example.com');
set role authenticated;
select test.ok(public.can('clients.details', 'edit', test.cid()), 'changes client details');
select test.ok(public.can('clients.people', 'edit', test.cid()) and public.can('clients.locations', 'edit', test.cid()), 'changes contacts and locations');
select test.ok(public.can('clients.agreements', 'edit', test.cid()), 'changes service agreements');
select test.ok(public.can('clients.services', 'view', test.cid()) and not public.can('clients.services', 'edit', test.cid()), 'views services, doesn''t change them');
select test.ok(public.can('clients.funding', 'view', test.cid()) and not public.can('clients.funding', 'edit', test.cid()), 'views funding only');
select test.ok(not public.can('clients.notes', 'view', test.cid()), 'no progress notes');
select test.ok(not public.can('clients.documents', 'view', test.cid()), 'no documents');
select test.ok(not public.can('clients.care_plans', 'view', test.cid()), 'no care plans');
select test.ok(not public.can('clients.assign', 'edit', test.cid()), 'doesn''t assign staff');
select test.ok((select count(*) from public.car_clients) = 1, 'sees the client list');
select test.ok(not public.can('clients.list', 'edit'), 'doesn''t add clients');
reset role;
\o
select 'All Client Services Coordinator tests passed.';
