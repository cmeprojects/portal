-- Staff Portal · © cmeproject. All rights reserved.
-- UNDO the roster TEST DATA (Dev only; cmeprojects, 22 Nov 2026).
-- Removes only shifts whose reference starts with "TEST-", with their timesheets,
-- service records, notes, events and responses. A test shift that already has a
-- billing line, a delivery decision, a cancellation record, an incident or a car
-- trip is KEPT (those records are never deleted) and listed at the end.
-- Nothing else is touched. Safe to run again.
begin;
create temporary table test_shifts on commit drop as
  select s.id from public.shifts s
   where s.ref like 'TEST-%'
     and not exists (select 1 from public.billing_lines b where b.shift_id = s.id)
     and not exists (select 1 from public.billing_delivery_overrides o where o.shift_id = s.id)
     and not exists (select 1 from public.shift_cancellations c where c.shift_id = s.id)
     and not exists (select 1 from public.client_incidents x where x.shift_id = s.id)
     and not exists (select 1 from public.car_trips x where x.shift_id = s.id);
delete from public.shift_service_records where shift_id in (select id from test_shifts);
delete from public.shift_timesheets where shift_id in (select id from test_shifts);
delete from public.shift_notes where shift_id in (select id from test_shifts);
delete from public.shift_signatures where shift_id in (select id from test_shifts);
delete from public.shift_responses where shift_id in (select id from test_shifts);
delete from public.shift_interest where shift_id in (select id from test_shifts);
delete from public.shift_change_requests where shift_id in (select id from test_shifts);
delete from public.shift_residents where shift_id in (select id from test_shifts);
delete from public.shift_events where shift_id in (select id from test_shifts);
delete from public.shifts where id in (select id from test_shifts);
commit;

select 'Test shifts kept (they have billing or other records)' as item, count(*) as shifts from public.shifts where ref like 'TEST-%';
