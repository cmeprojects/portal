-- Staff Portal · © cmeproject. All rights reserved.
--
-- Feature builder: the system admin builds; staff fill in published, included
-- features; entries are checked, kept, and seen only by who should see them.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('lead@example.com', 'Taylor', 'team_leader'),
  ('sam@example.com', 'Sam Worker', 'support_worker'), ('lee@example.com', 'Lee Worker', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('lead@example.com'), ('sam@example.com'), ('lee@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.fid(p_label text) returns uuid language sql security definer as $$ select id from public.custom_fields where label = p_label $$;
create function test.feature() returns uuid language sql security definer as $$ select id from public.custom_features where slug = 'fluid-intake' $$;
create function test.client(p_name text) returns uuid language sql security definer as $$ select id from public.car_clients where name = p_name $$;
grant execute on all functions in schema test to authenticated;

-- Teams: Taylor leads Team North with Sam in it; Lee is in another team.
insert into public.teams (name) values ('Team North'), ('Team South');
insert into public.team_leaders (team_id, user_id) select id, test.pid('lead@example.com') from public.teams where name = 'Team North';
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'Team North';
insert into public.team_members (team_id, user_id) select id, test.pid('lee@example.com') from public.teams where name = 'Team South';

-- Managers can now keep the client list (not only car managers).
select test.act_as('boss@example.com');
set role authenticated;
insert into public.car_clients (name) values ('Jamie N.'), ('Mia T.');
select test.refused($$insert into public.custom_features (slug, name, menu_label) values ('xx', 'X', 'X')$$, 'only the system admin builds features');
reset role;

-- The system admin builds Fluid intake.
select test.act_as('owner@example.com');
set role authenticated;
insert into public.custom_features (slug, name, menu_label, default_target) values ('fluid-intake', 'Fluid intake', 'Fluid intake', 1500);
insert into public.custom_fields (feature_id, label, type, required, sort_order) values (test.feature(), 'Client', 'client', true, 1);
insert into public.custom_fields (feature_id, label, type, required, options, allow_other, sort_order)
  values (test.feature(), 'Drink', 'choice', true, '["Water", "Juice"]', true, 2);
insert into public.custom_fields (feature_id, label, type, required, unit, min_value, max_value, sort_order)
  values (test.feature(), 'Amount', 'number', true, 'ml', 0, 2000, 3);
insert into public.custom_fields (feature_id, label, type, sort_order) values (test.feature(), 'Refused', 'yesno', 4);
update public.custom_features set total_field = test.fid('Amount'), group_field = test.fid('Client') where id = test.feature();
insert into public.custom_client_targets (feature_id, client_id, target) values (test.feature(), test.client('Mia T.'), 1000);
reset role;
select test.ok(exists (select 1 from public.audit_log where action = 'insert_custom_feature'), 'building goes in the change log');

-- A draft can't be filled in or even seen by staff.
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.custom_features) = 0, 'staff don''t see drafts');
select test.refused($$select public.submit_custom_entry(test.feature(), '{}')$$, 'or fill them in');
reset role;

update public.custom_features set status = 'published', published_at = now() where slug = 'fluid-intake';

select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.custom_fields) = 4, 'once published, staff see the form');
select test.refused(format($$select public.submit_custom_entry(test.feature(), '{"%s": "Water", "%s": "200"}')$$,
  test.fid('Drink'), test.fid('Amount')), 'required fields must be filled');
select test.refused(format($$select public.submit_custom_entry(test.feature(), '{"%s": "%s", "%s": "Water", "%s": "5000"}')$$,
  test.fid('Client'), test.client('Jamie N.'), test.fid('Drink'), test.fid('Amount')), 'numbers stay within the limits');
select test.refused(format($$select public.submit_custom_entry(test.feature(), '{"%s": "%s", "%s": "Water", "%s": "lots"}')$$,
  test.fid('Client'), test.client('Jamie N.'), test.fid('Drink'), test.fid('Amount')), 'and must be numbers');
select public.submit_custom_entry(test.feature(), jsonb_build_object(
  test.fid('Client')::text, test.client('Jamie N.'), test.fid('Drink')::text, 'Coconut water', test.fid('Amount')::text, '250',
  test.fid('Refused')::text, 'No', 'made-up', 'ignored'));
select test.ok((select client_name = 'Jamie N.' and team_names = 'Team North' and data ->> test.fid('Drink')::text = 'Coconut water'
                       and (data ->> test.fid('Amount')::text)::numeric = 250 and not data ? 'made-up'
                  from public.custom_entries),
  'an entry keeps the client, team, typed drink and number, and drops unknown answers');
select test.ok((select created_by = test.pid('sam@example.com') from public.custom_entries), 'and records who entered it');
select test.refused($$update public.custom_entries set data = '{}'$$, 'entries can''t be edited directly');
reset role;

select test.act_as('lee@example.com');
set role authenticated;
select test.ok((select count(*) from public.custom_entries) = 0, 'other staff don''t see Sam''s entries');
select test.ok((select count(*) from public.custom_client_today(test.feature(), test.client('Jamie N.'))) = 1,
  'but they see today''s entries for a client, for the daily total');
select public.submit_custom_entry(test.feature(), jsonb_build_object(
  test.fid('Client')::text, test.client('Mia T.'), test.fid('Drink')::text, 'Juice', test.fid('Amount')::text, '100'));
reset role;

select test.act_as('lead@example.com');
set role authenticated;
select test.ok((select count(*) from public.custom_entries) = 1, 'a team leader sees their own team''s entries only');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.ok((select count(*) from public.custom_entries) = 2, 'managers see everyone''s');
select test.ok((select target from public.custom_client_targets) = 1000, 'and the per-client targets');
reset role;

-- Undo within the time.
select test.act_as('lee@example.com');
set role authenticated;
select public.undo_custom_entry((select max(id) from public.custom_entries));
select test.ok((select count(*) from public.custom_entries) = 0, 'staff can undo their own entry');
reset role;
update public.custom_entries set created_at = now() - interval '11 minutes';
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$select public.undo_custom_entry((select max(id) from public.custom_entries))$$, 'but not after the undo time');
reset role;

-- Out of the package: hidden, entries kept.
select test.act_as('owner@example.com');
set role authenticated;
update public.custom_features set enabled = false where slug = 'fluid-intake';
reset role;
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.custom_features) = 0, 'switched off: staff don''t see it');
select test.refused($$select public.submit_custom_entry(test.feature(), '{}')$$, 'or fill it in');
reset role;
select test.ok((select count(*) from public.custom_entries) = 1, 'and the entries are kept');

select test.act_as('owner@example.com');
set role authenticated;
select test.refused($$delete from public.custom_features where slug = 'fluid-intake'$$, 'a feature with entries can''t be deleted');
reset role;

\o
\echo All feature builder tests passed.
