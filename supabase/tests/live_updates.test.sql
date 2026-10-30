-- Staff Portal · © cmeproject. All rights reserved.
--
-- Live updates: a car's "last changed" time moves with its trips, and
-- switching a built feature on or off sends a signal everyone can see.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('sam@example.com');

insert into public.cars (name, rego, odometer, changed_at) values ('Kia', '1EC 4KC', 1000, now() - interval '1 day');
insert into public.car_trips (car_id, driver_id, purpose, start_odo)
  select c.id, p.id, 'Client transport', 1000 from public.cars c, public.profiles p where p.email = 'sam@example.com';
select test.ok((select changed_at > now() - interval '1 minute' from public.cars), 'a trip marks its car as changed');

select test.act_as('owner@example.com');
set role authenticated;
insert into public.custom_features (slug, name, menu_label) values ('fluid-intake', 'Fluid intake', 'Fluid intake');
reset role;
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.live_signals where topic = 'features') = 1, 'staff see the signal for a feature they can''t see');
select test.refused($$update public.live_signals set changed_at = now()$$, 'but can''t send one');
reset role;

\o
\echo All live update tests passed.
