-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 138, AUD-016 Stage 6): access limited to clients in a person's programs.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role, job_title_id)
select 'csc@example.com', 'Casey', 'support_worker', id from public.job_titles where name = 'Client Services Coordinator';
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager');
insert into auth.users (email) values ('csc@example.com'), ('boss@example.com');
create function test.prog(p_name text) returns uuid language sql security definer as $$ select id from public.client_programs where name = p_name $$;
create function test.cid(p_name text) returns uuid language sql security definer as $$ select id from public.car_clients where name = p_name $$;
grant execute on all functions in schema test to authenticated;
insert into public.car_clients (name, status) values ('NDIS Client', 'active'), ('Private Client', 'active');
insert into public.client_locations (client_id, label, address, approved) select id, 'Home', '1 Test St', true from public.car_clients;
insert into public.client_services (client_id, program_id, label, status, start_date, location_id)
select c.id, test.prog(case when c.name = 'NDIS Client' then 'NDIS' else 'Private' end), 'Support', 'planned', current_date, l.id
  from public.car_clients c join public.client_locations l on l.client_id = c.id;
-- Client Services Coordinator's details access limited to their programs.
update public.access_baselines set revoked_at = now()
 where module_id = 'clients.details' and revoked_at is null
   and job_title_id = (select id from public.job_titles where name = 'Client Services Coordinator');
insert into public.access_baselines (job_title_id, module_id, actions, scope, by_system_admin)
select id, 'clients.details', '{view,edit}', 'programs', true from public.job_titles where name = 'Client Services Coordinator';
select test.refused($$insert into public.access_baselines (access_level, module_id, scope, by_system_admin) values ('manager', 'clients.assign', 'programs', true)$$, 'Assigning staff can''t be limited to programs');

select test.act_as('csc@example.com');
set role authenticated;
select test.ok(not public.can('clients.details', 'view', test.cid('NDIS Client')), 'no programs set: no client in scope');
select test.refused($$update public.profiles set program_ids = array[test.prog('NDIS')] where id = auth.uid()$$, 'nobody sets their own programs');
reset role;

select test.act_as('boss@example.com');
set role authenticated;
update public.profiles set program_ids = array[test.prog('NDIS')] where email = 'csc@example.com';
reset role;
select test.ok((select count(*) from public.audit_log where action = 'programs_changed') = 1, 'setting programs is logged');

select test.act_as('csc@example.com');
set role authenticated;
select test.ok(public.can('clients.details', 'edit', test.cid('NDIS Client')), 'a client in their program is in scope');
select test.ok(not public.can('clients.details', 'view', test.cid('Private Client')), 'a client in another program isn''t');
select test.ok(public.can('clients.locations', 'view', test.cid('Private Client')), 'parts still set to every client are unchanged');
select test.ok(not public.client_in_my_programs(test.cid('Private Client')), 'the yes/no check answers for the signed-in person only');
reset role;
update public.client_services set status = 'ended' where client_id = test.cid('NDIS Client');
select test.act_as('csc@example.com');
set role authenticated;
select test.ok(not public.can('clients.details', 'view', test.cid('NDIS Client')), 'an ended service no longer counts');
reset role;
\o
select 'All program scope tests passed.';
