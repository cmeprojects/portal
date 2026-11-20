-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 87): Clients & Care step 2: service locations.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('lead@example.com', 'Taylor', 'team_leader'),
  ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('lead@example.com'), ('sam@example.com'), ('kim@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.cid(p_name text) returns uuid language sql security definer as $$ select id from public.car_clients where name = p_name $$;
create function test.lid(p_label text) returns uuid language sql security definer as $$ select id from public.client_locations where label = p_label $$;
grant execute on all functions in schema test to authenticated;
insert into public.teams (name) values ('North'), ('South');
insert into public.team_leaders select id, test.pid('lead@example.com') from public.teams where name = 'North';
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'North';
insert into public.team_members (team_id, user_id) select id, test.pid('kim@example.com') from public.teams where name = 'South';
insert into public.car_clients (name) values ('Zara North');
insert into public.client_teams (client_id, team_id) select test.cid('Zara North'), id from public.teams where name = 'North';

-- A manager adds locations.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.client_locations (client_id, label, address, suburb, state, postcode, access_notes, approved, approved_by)
values (test.cid('Zara North'), 'Home', '1 Test St', 'Parramatta', 'NSW', '2150', 'Key safe by the front door', true, test.pid('sam@example.com'));
insert into public.client_locations (client_id, label, address, approved) values (test.cid('Zara North'), 'Day program', '5 Centre Rd', false);
insert into public.client_locations (client_id, label, address, approved, to_date) values (test.cid('Zara North'), 'Old flat', '9 Past Ave', true, current_date - 1);
insert into public.client_locations (client_id, label, address, approved, from_date) values (test.cid('Zara North'), 'Next place', '7 Soon St', true, current_date + 10);
select test.refused($$insert into public.client_locations (client_id, address, state) values (test.cid('Zara North'), '2 Bad St', 'XX')$$, 'only Australian states');
select test.refused($$insert into public.client_locations (client_id, address, postcode) values (test.cid('Zara North'), '2 Bad St', '21')$$, 'postcodes are four numbers');
select test.refused($$insert into public.client_locations (client_id, address, from_date, to_date) values (test.cid('Zara North'), '2 Bad St', current_date, current_date - 1)$$, 'the end can''t be before the start');
reset role;
select test.ok((select approved_by = test.pid('boss@example.com') and approved_at is not null from public.client_locations where label = 'Home'), 'approval records who really approved it (not a name sent in)');
select test.ok(exists (select 1 from public.audit_log where action = 'client_locations_added' and details ->> 'item' = 'Home'), 'adding a location is in the change log (one entry, update 156)');

-- Approving, and an address change needing approval again.
select test.act_as('boss@example.com');
set role authenticated;
update public.client_locations set approved = true where label = 'Day program';
update public.client_locations set access_notes = 'Ring the bell' where label = 'Home';
reset role;
select test.ok((select approved from public.client_locations where label = 'Home'), 'changing access notes keeps it approved');
select test.ok(exists (select 1 from public.audit_log where action = 'client_locations_changed' and details ->> 'item' = 'Day program' and details -> 'fields' ? 'approved'), 'approving is in the change log');
select test.act_as('boss@example.com');
set role authenticated;
update public.client_locations set address = '3 New St' where label = 'Home';
reset role;
select test.ok((select not approved and approved_by is null from public.client_locations where label = 'Home'), 'a new address needs approving again');
select test.ok(exists (select 1 from public.audit_log where action = 'client_locations_changed' and details -> 'fields' ? 'address' and details -> 'fields' ? 'approved'), 'and the change log says so (the address and approval both changed)');
select test.act_as('boss@example.com');
set role authenticated;
update public.client_locations set approved = true where label = 'Home';
select test.refused($$update public.client_locations set client_id = gen_random_uuid() where label = 'Home'$$, 'a location stays with its client');
delete from public.client_locations where label = 'Home';
reset role;
select test.ok((select count(*) from public.client_locations where label = 'Home') = 1, 'locations can''t be deleted (end them with a date)');

-- Staff see approved, current locations of their own teams' clients only.
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select array_agg(label order by label) from public.client_locations) = array['Day program', 'Home'], 'a support worker sees their team client''s approved, current locations');
select test.ok((select access_notes = 'Ring the bell' from public.client_locations where label = 'Home'), 'with the access instructions');
select test.refused($$insert into public.client_locations (client_id, address) values (test.cid('Zara North'), '4 Sneaky St')$$, 'staff can''t add locations');
update public.client_locations set address = 'x' where label = 'Home';
reset role;
select test.ok((select address = '3 New St' from public.client_locations where label = 'Home'), 'staff can''t change locations');
select test.act_as('lead@example.com');
set role authenticated;
select test.ok((select count(*) from public.client_locations) = 2, 'the team leader sees the same two');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
update public.client_locations set approved = false where label = 'Day program';
reset role;
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select array_agg(label) from public.client_locations) = array['Home'], 'an unapproved location disappears for staff');
reset role;
select test.act_as('kim@example.com');
set role authenticated;
select test.ok((select count(*) from public.client_locations) = 0, 'another team''s staff see nothing');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.ok((select count(*) from public.client_locations) = 4, 'people managers see every location, including ended and future ones');
reset role;

\o
\echo 'All client location tests passed.'
