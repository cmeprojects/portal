-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 90: removes service arrangements (with everything entered) and
-- the readiness check. Safe to run again.
begin;
drop table if exists public.client_services;
drop function if exists public.guard_client_service();
drop function if exists public.client_readiness(uuid);
drop function if exists public.client_service_gaps(uuid);
drop function if exists public.client_gaps(uuid, uuid, uuid, boolean, date);
commit;
