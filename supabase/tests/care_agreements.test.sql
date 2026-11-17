-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 115): service agreements
-- (Care block C6).

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


-- The case manager schedules an NDIS plan review and a Support at Home re-assessment.

select test.ok((select sensitivity from public.app_modules where id = 'clients.agreements') = 'sensitive', 'Service agreements is sensitive');

-- Intake sets agreements up; the scheme follows the service.
select test.act_as('io@example.com');
set role authenticated;
insert into public.client_agreements (client_id, service_id, scheme, starts_on, ends_on, status, signed_on, signed_by_name)
values (test.cid('Zara North'), test.svc('NDIS daily living'), 'support_at_home', current_date, current_date + 20, 'signed', current_date, 'Someone');
insert into public.client_agreements (client_id, service_id, starts_on) values (test.cid('Zara North'), test.svc('Home support'), current_date);
select test.refused($$insert into public.client_agreements (client_id, service_id, starts_on) values (test.cid('Alex South'), test.svc('Home support'), current_date)$$, 'a service from another client is refused');
select test.refused($$insert into public.client_agreements (client_id, service_id, starts_on, ends_on) values (test.cid('Zara North'), test.svc('Home support'), current_date, current_date - 1)$$, 'it can''t end before it starts');
reset role;
select test.ok((select scheme from public.client_agreements where service_id = test.svc('NDIS daily living')) = 'ndis', 'NDIS service: NDIS agreement, whatever was sent');
select test.ok((select scheme from public.client_agreements where service_id = test.svc('Home support')) = 'support_at_home', 'Support at Home service: Support at Home agreement');
select test.ok((select status from public.client_agreements where service_id = test.svc('NDIS daily living')) = 'draft', 'a new agreement can''t start as signed');

-- Who sees them.
select test.ok(test.n('boss@example.com', '(select count(*) from public.client_agreements)') = 2, 'manager sees them');
select test.ok(test.n('cm@example.com', '(select count(*) from public.client_agreements)') = 2, 'assigned case manager sees them');
select test.ok(test.n('office@example.com', '(select count(*) from public.client_agreements)') = 0, 'staff admin: none (D-052)');
select test.ok(test.n('sam@example.com', '(select count(*) from public.client_agreements)') = 0, 'team staff: none');
select test.act_as('cm@example.com');
set role authenticated;
update public.client_agreements set notes = 'x';
reset role;
select test.ok((select count(*) from public.client_agreements where notes = 'x') = 2, 'case manager changes them (update 117)');

-- Signing and ending.
select test.act_as('io@example.com');
set role authenticated;
select test.refused($$update public.client_agreements set status = 'signed' where service_id = test.svc('NDIS daily living')$$, 'signing needs the date and who signed');
update public.client_agreements set status = 'signed', signed_on = current_date, signed_by_name = 'Zara North' where service_id = test.svc('NDIS daily living');
select test.refused($$update public.client_agreements set ends_on = current_date + 300 where service_id = test.svc('NDIS daily living')$$, 'a signed agreement''s dates are fixed');
select test.refused($$update public.client_agreements set status = 'draft' where service_id = test.svc('NDIS daily living')$$, 'a signed agreement can only end');
select test.refused($$delete from public.client_agreements$$, 'agreements are never deleted');
reset role;

-- Ending soon: one reminder, to the assigned care manager.
select public.run_care_alerts();
select public.run_care_alerts();
select test.ok((select count(*) from public.notifications where kind = 'client_agreement_ending' and user_id = test.pid('cm@example.com') and body like '%NDIS') = 1, 'one ending reminder, naming the scheme');
select test.act_as('io@example.com');
set role authenticated;
update public.client_agreements set status = 'ended' where service_id = test.svc('NDIS daily living');
select test.refused($$update public.client_agreements set notes = 'y' where service_id = test.svc('NDIS daily living')$$, 'an ended agreement stays as it was');
reset role;

\o
