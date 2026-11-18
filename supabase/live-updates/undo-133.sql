-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 133. Safe to run again.
begin;
drop policy if exists "workers see clients of their shifts" on public.car_clients;
drop policy if exists "workers see their shift locations" on public.client_locations;
drop policy if exists "workers see their shift services" on public.client_services;
drop policy if exists "workers see alerts for their shift clients" on public.client_alerts;
drop policy if exists "workers see instructions for their shift clients" on public.client_worker_instructions;
commit;
