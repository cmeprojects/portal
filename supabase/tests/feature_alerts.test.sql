-- Staff Portal · © cmeproject. All rights reserved.
--
-- Feature builder alerts: matching entries tell the chosen people straight
-- away, by bell and/or email; only the system admin sets alerts up.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('lead@example.com', 'Taylor', 'team_leader'),
  ('sam@example.com', 'Sam Worker', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('lead@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.fid(p_label text) returns uuid language sql security definer as $$ select id from public.custom_fields where label = p_label $$;
create function test.feature() returns uuid language sql security definer as $$ select id from public.custom_features where slug = 'fluid-intake' $$;
create function test.client(p_name text) returns uuid language sql security definer as $$ select id from public.car_clients where name = p_name $$;
create function test.bells(p_email text) returns bigint language sql security definer as $$
  select count(*) from public.notifications where user_id = test.pid(p_email) and kind = 'feature_alert' $$;
create function test.emails(p_email text) returns bigint language sql security definer as $$
  select count(*) from public.email_outbox where to_user = test.pid(p_email) and data ->> 'href' = '/f/fluid-intake' $$;
grant execute on all functions in schema test to authenticated;

insert into public.teams (name) values ('Team North');
insert into public.team_leaders (team_id, user_id) select id, test.pid('lead@example.com') from public.teams where name = 'Team North';
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'Team North';
insert into public.car_clients (name) values ('Mia T.');

select test.act_as('owner@example.com');
set role authenticated;
insert into public.custom_features (slug, name, menu_label, status, published_at) values ('fluid-intake', 'Fluid intake', 'Fluid intake', 'published', now());
insert into public.custom_fields (feature_id, label, type, required, sort_order) values (test.feature(), 'Client', 'client', true, 1);
insert into public.custom_fields (feature_id, label, type, options, sort_order) values (test.feature(), 'Drink', 'choice', '["Water", "Refused"]', 2);
insert into public.custom_fields (feature_id, label, type, unit, sort_order) values (test.feature(), 'Amount', 'number', 'ml', 3);
update public.custom_features set total_field = test.fid('Amount'), group_field = test.fid('Client') where id = test.feature();
insert into public.custom_client_targets (feature_id, client_id, target) values (test.feature(), test.client('Mia T.'), 1000);
insert into public.custom_alerts (feature_id, when_kind, field_id, match_text, by_email) values (test.feature(), 'choice', test.fid('Drink'), 'Refused', true);
insert into public.custom_alerts (feature_id, when_kind, field_id, limit_value, notify_roles, notify_leader) values (test.feature(), 'above', test.fid('Amount'), 500, '{}', true);
insert into public.custom_alerts (feature_id, name, when_kind, message) values (test.feature(), 'Goal reached', 'total_met', '{client} reached today''s goal');
reset role;

select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.custom_alerts (feature_id) values (test.feature())$$, 'only the system admin sets up alerts');
select test.ok((select count(*) from public.custom_alerts) = 0, 'and only they see them');
reset role;

select test.act_as('sam@example.com');
set role authenticated;
select public.submit_custom_entry(test.feature(), jsonb_build_object(test.fid('Client')::text, test.client('Mia T.'), test.fid('Drink')::text, 'Water', test.fid('Amount')::text, '200'));
reset role;
select test.ok(test.bells('boss@example.com') = 0 and test.bells('lead@example.com') = 0, 'an ordinary entry tells nobody');

select test.act_as('sam@example.com');
set role authenticated;
select public.submit_custom_entry(test.feature(), jsonb_build_object(test.fid('Client')::text, test.client('Mia T.'), test.fid('Drink')::text, 'Refused', test.fid('Amount')::text, '0'));
reset role;
select test.ok(test.bells('boss@example.com') = 1 and test.emails('boss@example.com') = 1, 'a refused drink tells managers by bell and email');
select test.ok((select title = 'Fluid intake: Drink: Refused' and body like '%Mia T.%Entered by Sam Worker' from public.notifications where kind = 'feature_alert' limit 1),
  'saying what happened, for whom, and who entered it');
select test.ok(test.bells('sam@example.com') = 0, 'the person who entered it isn''t told');

select test.act_as('sam@example.com');
set role authenticated;
select public.submit_custom_entry(test.feature(), jsonb_build_object(test.fid('Client')::text, test.client('Mia T.'), test.fid('Drink')::text, 'Water', test.fid('Amount')::text, '900'));
reset role;
select test.ok(test.bells('lead@example.com') = 1 and test.emails('lead@example.com') = 0, 'over the limit tells their team leader (bell only)');
select test.ok(exists (select 1 from public.notifications where title = 'Mia T. reached today''s goal'), 'reaching the goal sends the message the admin wrote');

select test.act_as('sam@example.com');
set role authenticated;
select public.submit_custom_entry(test.feature(), jsonb_build_object(test.fid('Client')::text, test.client('Mia T.'), test.fid('Drink')::text, 'Water', test.fid('Amount')::text, '100'));
reset role;
select test.ok((select count(*) from public.notifications where title like '%goal%') = 1, 'the goal alert is once a day, not on every entry after');

-- Time-based alerts: off until switched on, checked by the hourly timer, once a day.
insert into public.car_clients (name) values ('Jo B.');
insert into public.custom_client_targets (feature_id, client_id, target) values (test.feature(), test.client('Jo B.'), 500);
select test.act_as('owner@example.com');
set role authenticated;
insert into public.custom_alerts (feature_id, name, when_kind, at_hour, active) values (test.feature(), 'Under target', 'total_under_by', 0, false);
insert into public.custom_alerts (feature_id, name, when_kind, at_hour, active) values (test.feature(), 'Nothing yet', 'no_entry_by', 0, true);
reset role;
select public.run_feature_time_alerts();
select test.ok(not exists (select 1 from public.notifications where title like '%under target%'), 'a time alert that is off sends nothing');
select test.ok(not exists (select 1 from public.notifications where title like '%nothing entered%'), 'and nothing-entered stays quiet when there are entries today');
update public.custom_alerts set active = true where name = 'Under target';
select public.run_feature_time_alerts();
select test.ok((select count(*) from public.notifications where user_id = test.pid('boss@example.com') and title like 'Fluid intake: under target at %') = 1
               and exists (select 1 from public.notifications where title like '%under target%' and body like '%Jo B.: 0 of 500%' and body not like '%Mia T.%'),
  'switched on: managers hear which clients are under their target');
select public.run_feature_time_alerts();
select test.ok((select count(*) from public.notifications where user_id = test.pid('boss@example.com') and title like '%under target%') = 1, 'only once a day');

select test.act_as('sam@example.com');
set role authenticated;
select public.submit_custom_entry(test.feature(), jsonb_build_object(test.fid('Client')::text, test.client('Jo B.'), test.fid('Drink')::text, 'Water', test.fid('Amount')::text, '50'));
reset role;
select test.ok((select count(*) from public.notifications where title like '%under target%' or title like '%Nothing yet%') = 1, 'time alerts don''t go off on each entry');

\o
\echo All feature alert tests passed.
