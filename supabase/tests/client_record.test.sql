-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 85): Clients & Care step 1: permanent references,
-- status, programs, and staff seeing their own teams' clients.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin'),
  ('lead@example.com', 'Taylor', 'team_leader'), ('sam@example.com', 'Sam', 'support_worker'),
  ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('lead@example.com'), ('sam@example.com'), ('kim@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.cid(p_name text) returns uuid language sql security definer as $$ select id from public.car_clients where name = p_name $$;
grant execute on all functions in schema test to authenticated;
insert into public.teams (name) values ('North'), ('South');
insert into public.team_leaders select id, test.pid('lead@example.com') from public.teams where name = 'North';
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'North';
insert into public.team_members (team_id, user_id) select id, test.pid('kim@example.com') from public.teams where name = 'South';

-- References
select test.act_as('boss@example.com');
set role authenticated;
insert into public.car_clients (name, client_ref) values ('Zara North', 'CL-99999');
insert into public.car_clients (name) values ('Alex South'), ('Unlinked Person');
reset role;
select test.ok((select bool_and(client_ref ~ '^CL-[0-9]{5}$') from public.car_clients), 'every client gets a CL-00000 style reference');
select test.ok((select client_ref <> 'CL-99999' from public.car_clients where name = 'Zara North'), 'a reference can''t be chosen; the database makes it');
select test.ok((select count(distinct client_ref) = count(*) from public.car_clients), 'references are unique');
select test.ok((select status = 'pending' from public.car_clients where name = 'Alex South'), 'a new client starts as pending');

select test.act_as('owner@example.com');
set role authenticated;
select test.refused($$update public.car_clients set client_ref = 'CL-00001' where name = 'Alex South'$$, 'nobody changes a reference, not even the system admin');
reset role;

-- A failed insert still uses up its number: numbers are never reused.
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.car_clients (name) values ('')$$, 'a client needs a name');
insert into public.car_clients (name) values ('Later Client');
reset role;
select test.ok((select client_ref from public.car_clients where name = 'Later Client') > (select max(client_ref) from public.car_clients where name <> 'Later Client'), 'a later client always gets a higher number');

-- Status
select test.act_as('boss@example.com');
set role authenticated;
update public.car_clients set status = 'active' where name = 'Zara North';
reset role;
select test.ok((select status = 'active' and status_changed_by = test.pid('boss@example.com') and status_changed_at is not null from public.car_clients where name = 'Zara North'), 'a manager makes a client active (who and when kept)');
select test.ok(exists (select 1 from public.audit_log a join public.client_audit_values v on v.audit_id = a.id where a.action = 'car_clients_changed' and v.changes -> 'status' = '["pending", "active"]'::jsonb), 'the status change is in the change log (with before and after, update 156)');
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.car_clients set status = 'archived' where name = 'Zara North'$$, 'only pending, active, suspended or discharged');
reset role;

-- Teams: staff and team leaders get the basic record of their own teams' clients (update 86).
insert into public.client_teams (client_id, team_id) select test.cid('Zara North'), id from public.teams where name = 'North';
insert into public.client_teams (client_id, team_id) select test.cid('Alex South'), id from public.teams where name = 'South';
update public.car_clients set reference = 'NDIS 4300 000 000' where name = 'Zara North';
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.car_clients) = 0, 'a support worker can''t read client rows directly (no free-text reference)');
select test.ok((select array_agg(name order by name) from public.team_clients()) = array['Zara North'], 'a support worker gets only their team''s client');
select test.ok((select client_ref like 'CL-%' and status = 'active' from public.team_clients()), 'with the reference (CL-) and status');
select test.ok(not exists (select 1 from information_schema.routines r join information_schema.parameters p on p.specific_name = r.specific_name where r.routine_name = 'team_clients' and p.parameter_name in ('reference', 'active', 'created_by')), 'never the free-text reference, shown flag or who added it');
update public.car_clients set status = 'discharged' where name = 'Zara North';
reset role;
select test.ok((select status = 'active' from public.car_clients where name = 'Zara North'), 'a support worker''s update changes nothing');
select test.act_as('lead@example.com');
set role authenticated;
select test.ok((select array_agg(name) from public.team_clients()) = array['Zara North'], 'a team leader gets their team''s clients');
reset role;
select test.act_as('kim@example.com');
set role authenticated;
select test.ok((select array_agg(name) from public.team_clients()) = array['Alex South'], 'staff in another team get only theirs');
reset role;
set role anon;
select test.refused($$select * from public.team_clients()$$, 'signed-out users can''t run team_clients');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.ok((select count(*) = 4 and bool_or(reference <> '') from public.car_clients), 'managers still see every client and its reference (unchanged)');
reset role;
select test.act_as('office@example.com');
set role authenticated;
select test.ok((select count(*) from public.car_clients) = 0, 'staff admins don''t, by default (update 109)');
reset role;

-- Programs
select test.ok((select string_agg(name || ':' || needs_dob, ',' order by sort_order) from public.client_programs) = 'NDIS:true,Support at Home:true,CHSP:true,Private:false,Other:false', 'programs start with NDIS, Support at Home and CHSP needing date of birth');
select test.act_as('boss@example.com');
set role authenticated;
select test.ok((select count(*) from public.client_programs) = 5, 'members read the programs');
select test.refused($$insert into public.client_programs (name) values ('Brokerage')$$, 'a manager can''t add programs');
reset role;
select test.act_as('owner@example.com');
set role authenticated;
insert into public.client_programs (name, needs_dob) values ('Brokerage', false);
update public.client_programs set active = false where name = 'Other';
delete from public.client_programs where name = 'Private';
select test.refused($$insert into public.client_programs (name) values ('ndis')$$, 'program names are unique');
reset role;
select test.ok((select count(*) = 6 and bool_or(name = 'Brokerage') and bool_or(name = 'Private') and not bool_or(name = 'Other' and active) from public.client_programs), 'the system admin adds and deactivates programs; nobody deletes them');

\o
\echo 'All client record tests passed.'
