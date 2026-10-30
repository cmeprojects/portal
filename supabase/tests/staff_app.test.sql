-- Staff Portal · © cmeproject. All rights reserved.
--
-- The Staff app is a premium add-on, off until the system admin switches it
-- on; its settings are readable by phones; people hear when their role changes.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com');

select test.ok((select premium and not enabled and not included from public.features where key = 'staff_app'), 'the Staff app is premium and off to start with');
select test.ok(not public.feature_enabled('staff_app'), 'so it isn''t available');

select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.features set enabled = true, included = true where key = 'staff_app'$$, 'a manager can''t switch it on');
select test.refused($$update public.app_settings set value = '"Mine"' where key = 'staff_app.name'$$, 'or change its settings');
reset role;

select test.act_as('owner@example.com');
set role authenticated;
update public.features set enabled = true, included = true where key = 'staff_app';
update public.app_settings set value = 'true' where key = 'staff_app.cars';
reset role;
select test.ok(public.feature_enabled('staff_app'), 'the system admin switches it on');

set role anon;
select test.ok((select count(*) from public.app_settings where key in ('staff_app.name', 'staff_app.icon', 'staff_app.cars', 'vehicles.separate_app')) = 4,
  'a phone installing the app can read its name and icon');
reset role;

select test.act_as('owner@example.com');
set role authenticated;
insert into public.custom_features (slug, name, menu_label) values ('fridge', 'Fridge temps', 'Fridge temps');
select test.refused($$update public.custom_features set app_colour = 'red'$$, 'icon colours must be real colours');
reset role;
select test.ok((select in_app and app_icon = 'clipboard' from public.custom_features where slug = 'fridge'), 'built features are in the app by default with a checklist icon');

-- Role changes
select test.act_as('boss@example.com');
set role authenticated;
update public.profiles set role = 'team_leader' where email = 'sam@example.com';
reset role;
select test.ok(exists (select 1 from public.notifications n join public.profiles p on p.id = n.user_id
                        where p.email = 'sam@example.com' and n.kind = 'role_changed' and n.title = 'Your role is now Team leader'),
  'Sam is told their role changed');
select test.ok(exists (select 1 from public.live_signals where topic = 'people'), 'and open pages are told to refresh');

-- Turned off: their open page hears about it (then signs them out).
delete from public.live_signals;
select test.act_as('boss@example.com');
set role authenticated;
update public.profiles set active = false where email = 'sam@example.com';
reset role;
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.live_signals where topic = 'people') = 1, 'a turned-off person still hears the signal');
reset role;

\o
\echo All Staff app tests passed.
