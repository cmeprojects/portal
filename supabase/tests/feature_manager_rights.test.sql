-- Staff Portal · © cmeproject. All rights reserved.
--
-- Feature builder: what managers may change (fix entries, targets, drop-down
-- options) when the system admin ticks it, and typed answers joining the list.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin'),
  ('sam@example.com', 'Sam Worker', 'support_worker'), ('lee@example.com', 'Lee Worker', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('sam@example.com'), ('lee@example.com');
create function test.fid(p_label text) returns uuid language sql security definer as $$ select id from public.custom_fields where label = p_label $$;
create function test.feature() returns uuid language sql security definer as $$ select id from public.custom_features where slug = 'fluid-intake' $$;
create function test.client(p_name text) returns uuid language sql security definer as $$ select id from public.car_clients where name = p_name $$;
create function test.options(p_label text) returns jsonb language sql security definer as $$ select options from public.custom_fields where label = p_label $$;
create function test.entry() returns public.custom_entries language sql security definer as $$ select * from public.custom_entries order by id limit 1 $$;
grant execute on all functions in schema test to authenticated;

insert into public.car_clients (name) values ('Jamie N.'), ('Mia T.');

select test.act_as('owner@example.com');
set role authenticated;
insert into public.custom_features (slug, name, menu_label, status, published_at, see_roles)
  values ('fluid-intake', 'Fluid intake', 'Fluid intake', 'published', now(), '{team_leader}');
insert into public.custom_fields (feature_id, label, type, required, sort_order) values (test.feature(), 'Client', 'client', true, 1);
insert into public.custom_fields (feature_id, label, type, required, options, allow_other, add_typed, sort_order)
  values (test.feature(), 'Drink', 'choice', true, '["Water", "Juice"]', true, true, 2);
insert into public.custom_fields (feature_id, label, type, options, allow_other, sort_order)
  values (test.feature(), 'Thickness', 'choice', '["Regular"]', true, 3);
insert into public.custom_fields (feature_id, label, type, required, unit, min_value, max_value, sort_order)
  values (test.feature(), 'Amount', 'number', true, 'ml', 0, 2000, 4);
reset role;

-- Typed answers join the list when the field says so (once, whatever the case).
select test.act_as('sam@example.com');
set role authenticated;
select public.submit_custom_entry(test.feature(), jsonb_build_object(
  test.fid('Client')::text, test.client('Jamie N.'), test.fid('Drink')::text, 'Coconut water',
  test.fid('Thickness')::text, 'Lumpy', test.fid('Amount')::text, '250'));
select test.ok(test.options('Drink') = '["Water", "Juice", "Coconut water"]', 'a typed drink joins the list for next time');
select test.ok(test.options('Thickness') = '["Regular"]', 'but only where the builder ticked it');
select public.submit_custom_entry(test.feature(), jsonb_build_object(
  test.fid('Client')::text, test.client('Mia T.'), test.fid('Drink')::text, 'coconut WATER', test.fid('Amount')::text, '100'));
select test.ok(jsonb_array_length(test.options('Drink')) = 3, 'and isn''t added twice');
reset role;

-- Not ticked: managers can't change anything.
select test.act_as('boss@example.com');
set role authenticated;
select test.ok((select count(*) from public.custom_entries) = 0, 'a manager not in "who sees" doesn''t see entries');
select test.refused(format($$select public.correct_custom_entry(%s, '{}', 'wrong amount')$$, (test.entry()).id), 'or fix them');
select test.refused(format($$select public.set_custom_targets(%L, 1000, '{}')$$, test.feature()), 'or set targets');
select test.refused(format($$select public.set_custom_field_options(%L, '["Water"]')$$, test.fid('Drink')), 'or change options');
reset role;

select test.act_as('owner@example.com');
set role authenticated;
update public.custom_features set managers_fix = true, managers_targets = true, managers_options = true where slug = 'fluid-intake';
reset role;

select test.act_as('boss@example.com');
set role authenticated;
select test.ok((select count(*) from public.custom_entries) = 2, 'ticked: a manager who fixes entries sees them all');
select test.refused(format($$select public.correct_custom_entry(%s, jsonb_build_object(%L, %L, %L, 'Water', %L, '200'), '')$$,
  (test.entry()).id, test.fid('Client'), test.client('Jamie N.'), test.fid('Drink'), test.fid('Amount')), 'a fix needs a reason');
select test.refused(format($$select public.correct_custom_entry(%s, jsonb_build_object(%L, %L, %L, 'Water', %L, '9000'), 'typo')$$,
  (test.entry()).id, test.fid('Client'), test.client('Jamie N.'), test.fid('Drink'), test.fid('Amount')), 'and is checked like a new entry');
select public.correct_custom_entry((test.entry()).id, jsonb_build_object(
  test.fid('Client')::text, test.client('Mia T.'), test.fid('Drink')::text, 'Water', test.fid('Amount')::text, '200'), 'Wrong client and amount');
select test.ok((select client_name = 'Mia T.' and (data ->> test.fid('Amount')::text)::numeric = 200 and corrected_at is not null
                       and correction_reason = 'Wrong client and amount' and created_by <> auth.uid()
                  from test.entry()), 'the entry is fixed, still shows who made it, and says why');
select public.set_custom_targets(test.feature(), 1500, jsonb_build_object(test.client('Mia T.')::text, 1000, test.client('Jamie N.')::text, null));
select test.ok((select target from public.custom_client_targets where client_id = test.client('Mia T.')) = 1000
               and (select default_target from public.custom_features) = 1500, 'managers set targets');
select public.set_custom_field_options(test.fid('Drink'), '["Water", " Juice", "juice", "Milk", ""]');
select test.ok(test.options('Drink') = '["Water", "Juice", "Milk"]', 'and the drop-down options, tidied');
select test.refused($$update public.custom_fields set label = 'Hacked'$$, 'but not the rest of the form');
reset role;
select test.ok((select count(*) from public.custom_fields where label = 'Hacked') = 0, 'the form is unchanged');

select test.ok(exists (select 1 from public.audit_log where action = 'custom_entry_fixed'
                         and details -> 'before' ->> test.fid('Amount')::text = '250' and details ->> 'reason' = 'Wrong client and amount'),
  'the change log keeps the before, after and reason');
select test.ok(exists (select 1 from public.audit_log where action = 'custom_targets_set'), 'target changes are logged');

-- Staff admins and support workers still can't.
select test.act_as('office@example.com');
set role authenticated;
select test.refused(format($$select public.set_custom_targets(%L, 1, '{}')$$, test.feature()), 'staff admins can''t set targets');
reset role;
select test.act_as('lee@example.com');
set role authenticated;
select test.refused(format($$select public.correct_custom_entry(%s, '{}', 'because')$$, (test.entry()).id), 'staff can''t fix entries');
reset role;

\o
\echo All feature manager rights tests passed.
