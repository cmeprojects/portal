-- Staff Portal · © cmeproject. All rights reserved.
--
-- The Cars app's name and icon: phones read them before anyone signs in, and
-- only the system admin (or a delegated car settings manager) changes them.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('sam@example.com');

set role anon;
select test.ok((select count(*) from public.app_settings where key in ('vehicles.app_name', 'vehicles.app_icon', 'vehicles.app_icon_uploads')) = 3,
  'a phone installing the app can read its name and icon');
reset role;

select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$update public.app_settings set value = '"Hacked"' where key = 'vehicles.app_name'$$, 'staff can''t change them');
reset role;

select test.act_as('owner@example.com');
set role authenticated;
update public.app_settings set value = '"EC Cars"' where key = 'vehicles.app_name';
reset role;
select test.ok((select value #>> '{}' from public.app_settings where key = 'vehicles.app_name') = 'EC Cars', 'the system admin names the app');

\o
\echo All Cars app look tests passed.
