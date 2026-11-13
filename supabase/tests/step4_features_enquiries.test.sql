-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects step 4 (third batch): Built features and Enquiries follow the
-- Access page as well as the role rules.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin'), ('office2@example.com', 'Oscar', 'staff_admin');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('office2@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;
set session_replication_role = replica;
update public.features set enabled = true, included = true where key in ('feature_builder', 'assistant');
set session_replication_role = origin;
update public.app_settings set value = '[]'::jsonb where key = 'assistant.enquiry_roles';
insert into public.custom_features (slug, name, menu_label, status, published_at, enabled, fill_roles, see_roles, managers_fix)
  values ('fluid-intake', 'Fluid intake', 'Fluid intake', 'published', now(), true, '{}', '{}', true);
create function test.fid() returns uuid language sql security definer as $$ select id from public.custom_features where slug = 'fluid-intake' $$;
grant execute on all functions in schema test to authenticated;

select test.act_as('office@example.com');
set role authenticated;
select test.ok(not public.can_see_feature(test.fid()) and not public.can_fill_feature(test.fid()) and not public.can_manage_feature(test.fid(), 'fix'), 'a staff admin not given anything: no access to the built feature (as set)');
select test.ok(not public.can_see_enquiries(), 'and no enquiries');
reset role;

select test.act_as('owner@example.com');
set role authenticated;
insert into public.admin_designations (user_id, granted_by) values (test.pid('boss@example.com'), test.pid('owner@example.com'));
insert into public.access_grants (module_id, user_id, granted_by, can_pass_on) values
  ('ops.features', test.pid('boss@example.com'), test.pid('owner@example.com'), true),
  ('engagement.enquiries', test.pid('boss@example.com'), test.pid('owner@example.com'), true);
reset role;

select test.act_as('boss@example.com');
set role authenticated;
select test.ok(public.can_see_feature(test.fid()) and public.can_fill_feature(test.fid()), 'given Built features: sees and fills every built feature');
select test.ok(public.can_see_enquiries(), 'given Enquiries: sees enquiries');
insert into public.access_grants (module_id, user_id, granted_by, parent_id, actions)
  select 'ops.features', test.pid('office@example.com'), test.pid('boss@example.com'), id, array['view', 'configure'] from public.access_grants where user_id = test.pid('boss@example.com') and module_id = 'ops.features';
reset role;

select test.act_as('office@example.com');
set role authenticated;
select test.ok(public.can_see_feature(test.fid()) and not public.can_fill_feature(test.fid()), 'passed on view and set up: sees but doesn''t fill');
select test.ok(public.can_manage_feature(test.fid(), 'fix') and not public.can_manage_feature(test.fid(), 'targets'), 'set up: only the manager tools the system admin allowed (fix entries, not targets)');
reset role;
select test.act_as('office2@example.com');
set role authenticated;
select test.ok(not public.can_see_feature(test.fid()) and not public.can_see_enquiries(), 'another staff admin: nothing');
reset role;
