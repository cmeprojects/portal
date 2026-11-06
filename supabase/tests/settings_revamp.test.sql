-- Staff Portal · © cmeproject. All rights reserved.
--
-- Settings revamp: feature parts, delegation per area, save then deploy,
-- notifications per channel, and the website front page.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('boss2@example.com', 'Max', 'manager'),
  ('office@example.com', 'Olive', 'staff_admin'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('boss2@example.com'), ('office@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;

-- Feature parts follow their feature.
select test.ok(public.feature_enabled('form_builder') = public.feature_enabled('forms'), 'the form builder follows Forms');
select test.ok(public.feature_enabled('teams') and public.feature_enabled('roles'), 'Teams and Roles start on');

-- Delegation: registers and roles start with every manager, the rest with the system admin.
select test.act_as('boss@example.com');
set role authenticated;
select test.ok(public.can_admin_area('registers') and public.can_admin_area('roles'), 'managers add registers and job titles, as today');
select test.ok(not public.can_admin_area('branding'), 'but not branding');
select test.refused($$select public.save_draft('setting', 'brand.company_name', '"Hacked"')$$, 'a manager can''t save a branding draft');
select test.refused($$select public.save_draft('delegation', 'branding', '{"mode": "managers"}')$$, 'or delegate');
reset role;

-- The system admin saves drafts: nothing is live until deployed.
select test.act_as('owner@example.com');
set role authenticated;
select test.ok(public.save_draft('setting', 'brand.company_name', '"Sample Care Co Melbourne"') = 'saved', 'a setting is saved as a draft');
select test.ok((select value from public.app_settings where key = 'brand.company_name') <> '"Sample Care Co Melbourne"', 'and isn''t live yet');
select test.ok(public.save_draft('delegation', 'branding', jsonb_build_object('mode', 'selected', 'people', jsonb_build_array(test.pid('office@example.com'), test.pid('sam@example.com')))) = 'saved', 'branding goes to selected people');
select test.refused($$select public.save_draft('delegation', 'tasks', '{"mode": "selected", "people": []}')$$, 'selected needs at least one person');
select test.ok(public.save_draft('feature', 'teams', '{"enabled": false}') = 'saved', 'Teams switched off as a draft');
select test.ok(public.save_draft('feature', 'teams', '{"enabled": true}') = 'unchanged', 'switching it back removes the draft');
select test.ok(public.save_draft('feature', 'roles', '{"enabled": false}') = 'saved', 'Roles off as a draft');
select test.ok(public.save_draft('setting', 'notify.channels', '{"task_assigned": {"bell": false}}') = 'saved', 'a notification switched off as a draft');
select test.ok((select count(*) from public.settings_drafts) = 4, 'four drafts waiting');
select test.ok(public.deploy_drafts() = 4, 'deploy makes all four live');
select test.ok((select value from public.app_settings where key = 'brand.company_name') = '"Sample Care Co Melbourne"', 'the setting is live');
select test.ok(not public.feature_live('roles'), 'Roles is off');
select test.ok((select people from public.delegation_rules where area = 'branding') = array[test.pid('office@example.com')], 'only the staff admin was kept (a support worker can''t be delegated to)');
select test.ok((select count(*) from public.audit_log where action = 'settings_deployed') = 1, 'the deploy is in the change log');
reset role;

-- The selected staff admin now looks after branding; drafts are their own.
select test.act_as('office@example.com');
set role authenticated;
select test.ok(public.can_admin_area('branding'), 'the staff admin looks after branding');
select test.ok(public.save_draft('setting', 'brand.portal_name', '"Staff hub"') = 'saved', 'and saves a draft');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.ok((select count(*) from public.settings_drafts) = 0, 'a manager doesn''t see someone else''s draft');
select test.ok(public.deploy_drafts() = 0, 'or deploy it');
reset role;
select test.act_as('owner@example.com');
set role authenticated;
select test.ok((select count(*) from public.settings_drafts) = 1, 'the system admin sees everyone''s drafts');
select test.ok(public.discard_drafts() = 1, 'and can discard them');
-- Website settings too.
select test.ok(public.save_draft('website', 'landing', '{"heading": "How can we help?", "suggestions": ["Who are you?"]}') = 'saved', 'a website part is saved as a draft');
select test.refused($$select public.save_draft('website', 'landing', '{"id": false}')$$, 'only real website settings can be saved');
select test.ok(public.deploy_drafts() = 1, 'and deployed');
select test.ok((select heading = 'How can we help?' and suggestions = array['Who are you?'] from public.assistant_settings), 'the website part is live');
reset role;

-- Notifications: a switched-off bell isn't created; email still is.
select public.notify(test.pid('sam@example.com'), 'task_assigned', 'A task for you', '', '/', false);
select test.ok((select count(*) from public.notifications where kind = 'task_assigned') = 0, 'a switched-off bell notification isn''t created');
select public.notify(test.pid('sam@example.com'), 'approval_needed', 'Please approve', '', '/', false);
select test.ok((select count(*) from public.notifications where kind = 'approval_needed') = 1, 'others still are');
update public.features set enabled = false where key = 'vehicles';
select public.notify(test.pid('sam@example.com'), 'car_still_out', 'Car still out', '', '/', false);
select test.ok((select count(*) from public.notifications where kind = 'car_still_out') = 0, 'nothing is sent for a feature that''s off');


-- Compliance parts: an item whose part is off doesn't count towards onboarding.
update public.features set enabled = true, included = true where key in ('compliance', 'forms');
insert into public.compliance_items (kind, title, body) values ('read', 'Code of Conduct', 'Be kind.');
insert into public.compliance_items (kind, title, needs_expiry) values ('upload', 'Police check', true);
select test.ok(cardinality(public.onboarding_missing(test.pid('sam@example.com'))) = 2, 'both items count while their parts are on');
update public.features set enabled = false where key = 'compliance_upload';
select test.ok(public.onboarding_missing(test.pid('sam@example.com')) = array['Code of Conduct'], 'switching off uploads stops the upload counting');
update public.features set enabled = true where key = 'compliance_upload';

-- Form builder off: only the system admin makes forms.
update public.app_settings set value = '["manager"]' where key = 'forms.maker_roles';
select test.act_as('boss@example.com');
set role authenticated;
select test.ok(public.can_make_forms(), 'a manager makes forms while the builder is on');
reset role;
update public.features set enabled = false where key = 'form_builder';
select test.act_as('boss@example.com');
set role authenticated;
select test.ok(not public.can_make_forms(), 'but not when the builder is off');
reset role;
select test.act_as('owner@example.com');
set role authenticated;
select test.ok(public.can_make_forms(), 'the system admin still can');
reset role;

-- Teams off: team leaders don't see their team's work.
insert into public.teams (name) values ('Team A');
update public.profiles set role = 'team_leader' where email = 'boss2@example.com';
insert into public.team_leaders (team_id, user_id) select id, test.pid('boss2@example.com') from public.teams where name = 'Team A';
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'Team A';
select test.act_as('boss2@example.com');
set role authenticated;
select test.ok(public.leads_user(test.pid('sam@example.com')), 'a team leader leads their team');
reset role;
update public.features set enabled = false where key = 'teams';
select test.act_as('boss2@example.com');
set role authenticated;
select test.ok(not public.leads_user(test.pid('sam@example.com')), 'not while Teams is off');
reset role;

-- The website is the front page only while the Assistant is on.
select test.act_as('owner@example.com');
update public.app_settings set value = 'true' where key = 'website.front_page';
update public.features set enabled = false where key = 'assistant';
select test.ok(not public.website_front_page(), 'Assistant off: the sign-in page is the front page');
update public.features set enabled = true, included = true where key = 'assistant';
select test.ok(public.website_front_page(), 'Assistant on: the website is the front page');

\o
\echo All settings revamp tests passed.
