-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 117): more default access for the new roles
-- (owner's choices).

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin'),
  ('sam@example.com', 'Sam', 'support_worker'), ('cm@example.com', 'Casey', 'support_worker'), ('io@example.com', 'Ira', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('sam@example.com'), ('cm@example.com'), ('io@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.cid(p_name text) returns uuid language sql security definer as $$ select id from public.car_clients where name = p_name $$;
create function test.n(p_email text, p_sql text) returns bigint language plpgsql as $$
declare v bigint;
begin
  perform test.act_as(p_email);
  execute 'set local role authenticated';
  execute 'select ' || p_sql into v;
  execute 'reset role';
  return v;
end $$;
grant execute on all functions in schema test to authenticated;
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Case Manager') where email = 'cm@example.com';
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Intake & Assessment Officer') where email = 'io@example.com';
insert into public.teams (name) values ('North');
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'North';
insert into public.car_clients (name) values ('Zara North'), ('Alex South');
insert into public.client_teams (client_id, team_id) select test.cid('Zara North'), id from public.teams where name = 'North';

insert into public.client_locations (client_id, label, address) values (test.cid('Zara North'), 'Home', '1 Test St');
insert into public.client_services (client_id, program_id, label, start_date, location_id)
select test.cid('Zara North'), p.id, 'NDIS daily living', current_date, l.id from public.client_programs p, public.client_locations l where p.scheme = 'ndis' and l.label = 'Home' limit 1;
insert into public.client_services (client_id, program_id, label, start_date, location_id)
select test.cid('Zara North'), p.id, 'Home support', current_date, l.id from public.client_programs p, public.client_locations l where p.scheme = 'support_at_home' and l.label = 'Home' limit 1;
create function test.svc(p_label text) returns uuid language sql security definer as $$ select id from public.client_services where label = p_label $$;
grant execute on all functions in schema test to authenticated;
insert into public.client_assignments (client_id, user_id) values (test.cid('Zara North'), test.pid('cm@example.com'));



insert into public.invitations (email, full_name, role) values ('pr@example.com', 'Pat', 'support_worker');
insert into auth.users (email) values ('pr@example.com');
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Payroll & Rostering') where email = 'pr@example.com';
update public.client_locations set approved = true;
insert into public.client_funding (client_id, service_id, period_start, period_end, total_amount, plan_management)
values (test.cid('Zara North'), test.svc('NDIS daily living'), current_date, current_date + 365, 50000, 'plan');
insert into public.client_details (client_id, ndis_number) values (test.cid('Zara North'), '431234567');
create function test.can(p_email text, p_module text, p_action text, p_client uuid) returns boolean language plpgsql as $$
declare v boolean;
begin
  perform test.act_as(p_email);
  execute 'set local role authenticated';
  v := public.can(p_module, p_action, p_client);
  execute 'reset role';
  return v;
end $$;
grant execute on all functions in schema test to authenticated;

-- Case Manager: their assigned clients only.
select test.ok(test.can('cm@example.com', 'clients.funding', 'edit', test.cid('Zara North')), 'case manager: change funding for an assigned client');
select test.ok(not test.can('cm@example.com', 'clients.funding', 'edit', test.cid('Alex South')), 'but not for another client');
select test.ok(test.can('cm@example.com', 'clients.agreements', 'edit', test.cid('Zara North')), 'case manager: change agreements for an assigned client');
select test.ok(test.can('cm@example.com', 'insights.reports.compliance', 'view', null), 'case manager: compliance report');
select test.act_as('cm@example.com');
set role authenticated;
update public.client_funding set used_amount = 100;
reset role;
select test.ok((select used_amount from public.client_funding) = 100, 'case manager updates what''s been used');

-- Intake: every client.
select test.ok(test.can('io@example.com', 'clients.funding', 'edit', test.cid('Alex South')), 'intake: add funding for any client');
select test.ok(test.can('io@example.com', 'clients.reviews', 'view', test.cid('Alex South')) and not test.can('io@example.com', 'clients.reviews', 'edit', test.cid('Alex South')), 'intake: view reviews only');
select test.ok(test.can('io@example.com', 'clients.services', 'edit', test.cid('Alex South')), 'intake: change services');

-- Payroll & Rostering: view only, never the private parts.
select test.ok(test.n('pr@example.com', '(select count(*) from public.car_clients)') = 2, 'payroll: the client list');
select test.ok(test.n('pr@example.com', '(select count(*) from public.client_locations)') = 1, 'payroll: approved locations');
select test.ok(test.n('pr@example.com', '(select count(*) from public.client_services)') = 2, 'payroll: services');
select test.ok(test.n('pr@example.com', '(select count(*) from public.client_funding)') = 1, 'payroll: funding');
select test.ok(test.n('pr@example.com', '(select count(*) from public.client_details)') = 0, 'payroll: no personal details (NDIS number, date of birth)');
select test.ok(not test.can('pr@example.com', 'clients.notes', 'view', test.cid('Zara North')) and not test.can('pr@example.com', 'clients.documents', 'view', test.cid('Zara North'))
               and not test.can('pr@example.com', 'clients.care_plans', 'view', test.cid('Zara North')), 'payroll: no notes, documents or care plans');
select test.ok(not test.can('pr@example.com', 'hr.onboarding.expiry', 'view', null), 'payroll: no onboarding expiry list yet (owner to decide)');
select test.act_as('pr@example.com');
set role authenticated;
update public.client_funding set used_amount = 1;
reset role;
select test.ok((select used_amount from public.client_funding) = 100, 'payroll can''t change funding');

-- Nobody else changes.
select test.ok(test.n('office@example.com', '(select count(*) from public.client_funding)') = 0, 'staff admin: still none (D-052)');
select test.ok(test.n('sam@example.com', '(select count(*) from public.client_funding)') = 0, 'team staff: still none');

\o
