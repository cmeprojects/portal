-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 135. Safe to run again. Trips already linked keep their shift.
begin;
drop trigger if exists link_trip_to_shift on public.car_trips;
drop function if exists public.link_trip_to_shift();
commit;
