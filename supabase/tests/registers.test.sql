-- Staff Portal · © cmeproject. All rights reserved.
--
-- Registers: setting them up, custom fields, reference numbers, records and
-- follow-up actions.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan Manager', 'manager'),
  ('other@example.com', 'Oscar Other', 'manager'),
  ('sam@example.com', 'Sam Worker', 'support_worker'),
  ('kim@example.com', 'Kim Worker', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('other@example.com'), ('sam@example.com'), ('kim@example.com');

create function test.pid(p_email text) returns uuid language sql as $$
  select id from public.profiles where email = p_email
$$;
create function test.reg(p_prefix text) returns uuid language sql as $$
  select id from public.registries where prefix = p_prefix
$$;
-- Looks a task up whoever is asking (to test refusals on hidden tasks).
create function test.tid(p_title text) returns uuid language sql security definer as $$
  select id from public.tasks where title = p_title
$$;
grant execute on all functions in schema test to authenticated;

-- Morgan manages the Risk and Asset registers.
insert into public.registry_managers (registry_id, user_id)
select id, test.pid('boss@example.com') from public.registries where prefix in ('RSK', 'AST');

select test.ok((select count(*) = 1 and bool_and(is_default and prefix = 'GEN') from public.registries where is_default),
  'every install has one built-in General tasks registry');

-- ---------------------------------------------------------------------------
-- Setting up registries
-- ---------------------------------------------------------------------------

select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$insert into public.registries (name) values ('Sam''s register')$$,
  'a support worker cannot create a registry');
reset role;

select test.act_as('boss@example.com');
set role authenticated;
insert into public.registries (name, description) values ('Vehicle Incident Register', 'Car incidents');
reset role;
select test.ok((select prefix = 'VIR' from public.registries where name = 'Vehicle Incident Register'),
  'a new registry gets a prefix from its initials');
select test.ok(exists (select 1 from public.registry_managers
                        where registry_id = test.reg('VIR') and user_id = test.pid('boss@example.com')),
  'the manager who creates a registry becomes its manager');

select test.act_as('boss@example.com');
set role authenticated;
insert into public.registry_fields (registry_id, key, label, type, required, options)
values (test.reg('VIR'), 'severity', 'Severity', 'choice', true, '["Minor", "Major"]');
update public.registries set requires_approval = true where prefix = 'VIR';
select test.refused($$insert into public.registry_fields (registry_id, key, label, type)
  values (test.reg('COI'), 'sneaky', 'Sneaky', 'text')$$,
  'a manager cannot add fields to a registry they do not manage');
select test.refused($$update public.registries set name = 'Renamed' where prefix = 'COI'$$,
  'a manager cannot change a registry they do not manage');
select test.refused($$delete from public.registry_fields$$, 'fields are never deleted (only retired)');
select test.refused($$delete from public.registries where prefix = 'VIR'$$, 'registries are never deleted');
reset role;

select test.act_as('owner@example.com');
set role authenticated;
select test.refused($$update public.registries set active = false where prefix = 'GEN'$$,
  'the General tasks registry cannot be retired');
update public.registries set name = 'Everyday tasks' where prefix = 'GEN';
reset role;
select test.ok((select name = 'Everyday tasks' from public.registries where prefix = 'GEN'),
  'the General tasks registry can be renamed');

-- ---------------------------------------------------------------------------
-- Tasks with custom fields
-- ---------------------------------------------------------------------------

select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$select public.create_task('Wet floor', test.reg('RSK'), test.pid('kim@example.com'))$$,
  'a required custom field must be filled in');
select test.refused($$select public.create_task('Wet floor', test.reg('RSK'), test.pid('kim@example.com'),
  p_details => '{"risk_rating": "Catastrophic"}')$$,
  'a dropdown only accepts its own choices');
select test.refused($$select public.create_task('Asset test', test.reg('MNT'), test.pid('kim@example.com'),
  p_details => '{"asset": "00000000-0000-0000-0000-000000000000"}')$$,
  'an asset field must point at a real asset');
select test.refused($$select public.create_task('Asset list', test.reg('AST'), test.pid('kim@example.com'))$$,
  'tasks cannot be created in a records register');
select public.create_task('Wet floor in kitchen', test.reg('RSK'), test.pid('kim@example.com'), 'Slippery after mopping',
  p_details => '{"risk_rating": "High", "consequence": "Falls", "made_up": "dropped"}',
  p_review_date => current_date + 30);
select public.create_task('Loose handrail', test.reg('RSK'), test.pid('kim@example.com'),
  p_details => '{"risk_rating": "Medium"}');
select public.create_task('Order gloves', test.reg('GEN'), test.pid('kim@example.com'));
reset role;

select test.ok((select details = '{"risk_rating": "High", "consequence": "Falls"}'::jsonb
                  from public.tasks where title = 'Wet floor in kitchen'),
  'custom field values are saved and unknown fields are dropped');
select test.ok((select array_agg(ref_number order by ref_number) = array[1, 2] from public.tasks where registry_id = test.reg('RSK')),
  'each registry numbers its own entries (RSK-0001, RSK-0002)');
select test.ok((select ref_number = 1 from public.tasks where title = 'Order gloves'),
  'General tasks have their own numbers too (GEN-0001)');

-- Editing details
select test.act_as('kim@example.com');
set role authenticated;
select public.update_task_details((select id from public.tasks where title = 'Wet floor in kitchen'),
  'Wet floor in kitchen', 'Slippery after mopping', 'high', null, current_date, current_date + 30,
  'Signs and a new mop', '{"risk_rating": "Extreme", "consequence": "Falls", "effectiveness": "Not yet reviewed"}');
reset role;
select test.ok((select details ->> 'risk_rating' = 'Extreme' and outcome = 'Signs and a new mop'
                  from public.tasks where title = 'Wet floor in kitchen'),
  'the person looking after it can update the details');
select test.ok((select comment like '%risk rating%' and comment like '%outcome%'
                  from public.task_events where type = 'details_changed'),
  'the timeline lists which fields changed');

select test.act_as('other@example.com');
set role authenticated;
select test.refused($$select public.update_task_details((select id from public.tasks where title = 'Wet floor in kitchen'),
  'x', '', 'low', null, null, null, '', '{"risk_rating": "Low"}')$$,
  'someone who cannot see the task cannot change it');
reset role;

-- Retiring a field keeps its data; changing the type of a used field is refused.
select test.act_as('boss@example.com');
set role authenticated;
update public.registry_fields set active = false where registry_id = test.reg('RSK') and key = 'consequence';
select test.refused($$update public.registry_fields set type = 'number' where registry_id = test.reg('RSK') and key = 'risk_rating'$$,
  'a field''s type cannot change once it has data');
reset role;
select test.act_as('kim@example.com');
set role authenticated;
select public.update_task_details((select id from public.tasks where title = 'Wet floor in kitchen'),
  'Wet floor in kitchen', 'Slippery after mopping', 'high', null, current_date, current_date + 30,
  'Signs and a new mop', '{"risk_rating": "High"}');
reset role;
select test.ok((select details ->> 'consequence' = 'Falls' from public.tasks where title = 'Wet floor in kitchen'),
  'values of a retired field are kept');

-- ---------------------------------------------------------------------------
-- Records (Asset Register)
-- ---------------------------------------------------------------------------

select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$select public.create_record(test.reg('AST'), 'Wheelchair', '{}')$$,
  'only the register''s managers can add assets');
reset role;

select test.act_as('boss@example.com');
set role authenticated;
select public.create_record(test.reg('AST'), 'Electric wheelchair',
  '{"brand": "Pride", "purchase_value": 4200, "purchase_date": "2024-07-01", "status": "In use"}');
select test.refused($$select public.create_record(test.reg('RSK'), 'Not a records register', '{}')$$,
  'records can only go in a records register');
reset role;

select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) = 1 from public.records), 'everyone can look up assets');
select public.create_task('Wheelchair battery', test.reg('MNT'), test.pid('kim@example.com'),
  p_details => jsonb_build_object('asset', (select id from public.records limit 1)));
select test.refused($$insert into public.records (registry_id, ref_number, title, created_by)
  values (test.reg('AST'), 99, 'x', test.pid('sam@example.com'))$$, 'nobody can insert records directly');
reset role;
select test.ok((select details ? 'asset' from public.tasks where title = 'Wheelchair battery'),
  'a maintenance task can link to an asset');

select test.act_as('boss@example.com');
set role authenticated;
select public.update_record((select id from public.records limit 1), 'Electric wheelchair',
  '{"brand": "Pride", "purchase_value": 4200, "purchase_date": "2024-07-01", "status": "Being repaired"}', false);
reset role;
select test.ok((select count(*) = 2 from public.record_events), 'asset changes are kept in its history');

-- ---------------------------------------------------------------------------
-- Follow-up actions
-- ---------------------------------------------------------------------------

select test.act_as('kim@example.com');
set role authenticated;
select public.create_task('Buy non-slip mats', null, test.pid('sam@example.com'),
  p_due_date => current_date + 7,
  p_parent_task_id => (select id from public.tasks where title = 'Wet floor in kitchen'));
reset role;
select test.ok((select registry_id = test.reg('RSK') and parent_task_id is not null
                  from public.tasks where title = 'Buy non-slip mats'),
  'a follow-up action belongs to the same register as its task');
select test.ok(exists (select 1 from public.task_events e join public.tasks t on t.id = e.task_id
                        where t.title = 'Wet floor in kitchen' and e.type = 'action_added'),
  'adding an action shows on the main task''s timeline');
select test.ok(exists (select 1 from public.email_outbox o join public.tasks t on t.id = o.task_id
                        where t.title = 'Buy non-slip mats' and o.to_user = test.pid('sam@example.com')),
  'the person given the action is emailed');

select test.act_as('other@example.com');
set role authenticated;
select test.refused($$select public.create_task('x', null, test.pid('sam@example.com'),
  p_parent_task_id => test.tid('Order gloves'))$$,
  'you cannot add actions to a task you cannot change');
reset role;

\o
\echo 'All register tests passed.'
