-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 87: removes service locations (the table and every location in
-- it). Clients are untouched. Safe to run again.
begin;
drop table if exists public.client_locations;
drop function if exists public.guard_client_location();
commit;
