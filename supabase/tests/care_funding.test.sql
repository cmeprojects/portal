-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 116): funding and budgets
-- (Care block C7).

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



select test.ok((select sensitivity from public.app_modules where id = 'clients.funding') = 'sensitive', 'Funding and budgets is sensitive');

-- A manager records budgets; each scheme's rules apply, never mixed.
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.client_funding (client_id, service_id, period_start, period_end, total_amount) values (test.cid('Zara North'), test.svc('NDIS daily living'), current_date, current_date + 365, 50000)$$, 'NDIS needs plan management');
select test.refused($$insert into public.client_funding (client_id, service_id, period_start, period_end, total_amount, plan_management, classification) values (test.cid('Zara North'), test.svc('NDIS daily living'), current_date, current_date + 365, 50000, 'plan', 3)$$, 'NDIS can''t have a Support at Home classification');
insert into public.client_funding (client_id, service_id, period_start, period_end, total_amount, plan_management) values (test.cid('Zara North'), test.svc('NDIS daily living'), current_date, current_date + 365, 50000, 'plan');
select test.refused($$insert into public.client_funding (client_id, service_id, period_start, period_end, total_amount, plan_management, classification) values (test.cid('Zara North'), test.svc('Home support'), current_date, current_date + 90, 9000, 'self', 4)$$, 'Support at Home can''t have NDIS plan management');
select test.refused($$insert into public.client_funding (client_id, service_id, period_start, period_end, total_amount) values (test.cid('Zara North'), test.svc('Home support'), current_date, current_date + 90, 9000)$$, 'Support at Home needs the classification');
insert into public.client_funding (client_id, service_id, period_start, period_end, total_amount, classification) values (test.cid('Zara North'), test.svc('Home support'), current_date, current_date + 90, 9000, 4);
select test.refused($$insert into public.client_funding (client_id, service_id, period_start, period_end, total_amount, plan_management) values (test.cid('Zara North'), test.svc('NDIS daily living'), current_date, current_date - 1, 1, 'plan')$$, 'a period can''t end before it starts');
select test.refused($$update public.client_funding set plan_management = null where scheme = 'ndis'$$, 'NDIS plan management can''t be removed');
update public.client_funding set used_amount = 1250.50, used_as_of = current_date where scheme = 'ndis';
select test.refused($$delete from public.client_funding$$, 'budgets are never deleted');
reset role;
select test.ok((select used_amount from public.client_funding where scheme = 'ndis') = 1250.50, 'used so far is recorded');

-- Who sees them.
select test.ok(test.n('cm@example.com', '(select count(*) from public.client_funding)') = 2, 'assigned case manager sees them');
select test.ok(test.n('office@example.com', '(select count(*) from public.client_funding)') = 0, 'staff admin: none (D-052)');
select test.ok(test.n('io@example.com', '(select count(*) from public.client_funding)') = 0, 'intake: none by default');
select test.ok(test.n('sam@example.com', '(select count(*) from public.client_funding)') = 0, 'team staff: none');
select test.act_as('cm@example.com');
set role authenticated;
update public.client_funding set used_amount = 1;
reset role;
select test.ok((select count(*) from public.client_funding where used_amount = 1) = 0, 'case manager: view only');

-- Ending.
select test.act_as('boss@example.com');
set role authenticated;
update public.client_funding set status = 'ended' where scheme = 'support_at_home';
select test.refused($$update public.client_funding set used_amount = 5 where scheme = 'support_at_home'$$, 'an ended budget stays as it was');
reset role;

\o
