-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (QA-008 A2): a fresh install starts with "Odometer photo when
-- returning" Off (decision D-009).

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

select test.ok((select value #>> '{}' from public.app_settings where key = 'vehicles.odo_photo') = 'off', 'a fresh install starts with the odometer photo setting Off');
select test.ok(public.car_setting('vehicles.odo_photo', 'optional') = 'off', 'the Cars functions read it as Off');

\o
\echo 'All odometer default tests passed.'
