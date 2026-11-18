-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (updates 105 to 107): Clients on the one permission check,
-- client assignments and "assigned clients only" (Stage 5).

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin'),
  ('sam@example.com', 'Sam', 'support_worker'), ('cm1@example.com', 'Casey', 'support_worker'),
  ('cm2@example.com', 'Chris', 'support_worker'), ('io@example.com', 'Ira', 'support_worker'),
  ('pay@example.com', 'Pat', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('sam@example.com'), ('cm1@example.com'), ('cm2@example.com'), ('io@example.com'), ('pay@example.com');
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
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Case Manager') where email in ('cm1@example.com', 'cm2@example.com');
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Intake & Assessment Officer') where email = 'io@example.com';
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Payroll Officer') where email = 'pay@example.com';
insert into public.teams (name) values ('North');
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'North';
insert into public.car_clients (name) values ('Zara North'), ('Alex South');
insert into public.client_teams (client_id, team_id) select test.cid('Zara North'), id from public.teams where name = 'North';
insert into public.client_details (client_id, phone) values (test.cid('Zara North'), '0400 000 000'), (test.cid('Alex South'), '0400 111 111');
insert into public.client_alerts (client_id, kind, severity, title, worker_instructions) values (test.cid('Zara North'), 'medical', 'high', 'Nut allergy', 'EpiPen in the kitchen.');
insert into public.client_alert_notes (alert_id, client_id, details) values ((select id from public.client_alerts where title = 'Nut allergy'), gen_random_uuid(), 'Plan reviewed.');

-- Set up (updates 105 and 107).
select test.ok((select count(*) from public.app_modules where id in ('clients.list', 'clients.details', 'clients.people', 'clients.locations', 'clients.alerts', 'clients.notes', 'clients.services', 'clients.assign') and grant_ready) = 8, 'Clients and its seven parts are switched over');
select test.ok((select count(*) from public.app_modules where id in ('clients.details', 'clients.people', 'clients.notes', 'clients.services') and sensitivity = 'sensitive') = 4, 'details, contacts, risk notes and services are sensitive');
select test.ok((select count(*) from public.job_titles where name in ('Case Manager', 'Intake & Assessment Officer', 'Payroll Officer') and access_level = 'support_worker') = 3, 'three new roles at support worker level');

-- Same as today for managers, staff admins and team staff.
select test.ok(test.n('boss@example.com', '(select count(*) from public.car_clients)') = 2 and test.n('boss@example.com', '(select count(*) from public.client_details)') = 2, 'manager sees every client and their details');
select test.ok(test.n('office@example.com', '(select count(*) from public.car_clients)') = 0 and test.n('office@example.com', '(select count(*) from public.client_alert_notes)') = 0, 'staff admin: no client records by default (update 109)');
select test.ok(test.n('sam@example.com', '(select count(*) from public.client_alerts)') = 1, 'team staff still see their team''s client alerts (team rule)');
select test.ok(test.n('sam@example.com', '(select count(*) from public.client_details)') = 0, 'but not details');
select test.ok(test.n('pay@example.com', '(select count(*) from public.car_clients)') = 2 and test.n('pay@example.com', '(select count(*) from public.client_details)') = 0, 'Payroll & Rostering: the client list, never details (update 117)');

-- Case managers: assigned clients only.
select test.ok(test.n('cm1@example.com', '(select count(*) from public.car_clients)') = 0, 'a case manager with no assignment sees no clients');
select test.act_as('cm1@example.com');
set role authenticated;
select test.refused($$insert into public.client_assignments (client_id, user_id) values (test.cid('Zara North'), test.pid('cm2@example.com'))$$, 'case managers can''t assign staff');
reset role;
select test.act_as('io@example.com');
set role authenticated;
insert into public.client_assignments (client_id, user_id) values (test.cid('Zara North'), test.pid('cm1@example.com'));
select test.refused($$insert into public.client_assignments (client_id, user_id) values (test.cid('Alex South'), test.pid('io@example.com'))$$, 'nobody assigns a client to themselves');
reset role;
select test.ok(test.n('cm1@example.com', '(select count(*) from public.car_clients)') = 1, 'assigned: the case manager sees that client');
select test.act_as('cm1@example.com');
set role authenticated;
select test.refused($$insert into public.client_assignments (client_id, user_id) values (test.cid('Zara North'), test.pid('cm2@example.com'))$$, 'even for their own assigned client, a case manager can''t assign staff');
reset role;
select test.ok(not (select public.can('clients.assign', 'edit', test.cid('Zara North')) from (select test.act_as('cm1@example.com')) x), 'Assigning staff never follows "assigned clients only"');
select test.ok(test.n('cm1@example.com', $$(select count(*) from public.client_details where client_id = test.cid('Zara North'))$$) = 1, 'and their details');
select test.ok(test.n('cm1@example.com', $$(select count(*) from public.client_details where client_id = test.cid('Alex South'))$$) = 0, 'not another client''s');
select test.ok(test.n('cm2@example.com', '(select count(*) from public.car_clients)') = 0, 'another case manager doesn''t');
select test.act_as('cm1@example.com');
set role authenticated;
update public.client_details set phone = '0400 222 222' where client_id = test.cid('Zara North');
reset role;
select test.ok((select phone = '0400 222 222' from public.client_details where client_id = test.cid('Zara North')), 'the case manager updates their client''s details');
select test.act_as('cm1@example.com');
set role authenticated;
select test.refused($$update public.client_details set phone = 'x' where client_id = test.cid('Alex South')$$, 'but not another client''s');
reset role;

-- Ending an assignment stops access; history kept.
select test.act_as('io@example.com');
set role authenticated;
update public.client_assignments set ended_at = now() where client_id = test.cid('Zara North') and user_id = test.pid('cm1@example.com');
reset role;
select test.ok(test.n('cm1@example.com', '(select count(*) from public.car_clients)') = 0, 'assignment ended: access stops');
select test.ok((select count(*) from public.client_assignments where ended_at is not null and ended_by = test.pid('io@example.com')) = 1, 'the assignment is kept, with who ended it');
select test.act_as('io@example.com');
set role authenticated;
select test.refused($$update public.client_assignments set ended_at = null where user_id = test.pid('cm1@example.com')$$, 'an ended assignment can''t be reopened');
select test.refused($$delete from public.client_assignments$$, 'assignments are never deleted');
reset role;

-- Intake officers: every client; risk notes view only.
select test.ok(test.n('io@example.com', '(select count(*) from public.car_clients)') = 2, 'intake officer sees every client');
select test.ok(test.n('io@example.com', '(select count(*) from public.client_alert_notes)') = 1, 'and reads risk notes');
select test.act_as('io@example.com');
set role authenticated;
select test.refused($$update public.client_alert_notes set details = 'x'$$, 'but can''t change them');
insert into public.car_clients (name) values ('New Referral');
reset role;
select test.ok(test.cid('New Referral') is not null, 'intake officer adds a client');

-- The scope rule.
select test.refused($$insert into public.access_baselines (access_level, module_id, scope) values ('team_leader', 'ops.cars.manage', 'assigned')$$, '"assigned clients only" is only for parts of Clients');
select test.refused($$insert into public.access_baselines (access_level, module_id, scope) values ('team_leader', 'clients.assign', 'assigned')$$, 'and not for Assigning staff itself');

\o
