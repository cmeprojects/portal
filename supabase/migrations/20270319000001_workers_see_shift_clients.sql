-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 133, AUD-016 §12): a worker sees what they need for
-- their own published shifts (from two weeks ago on): the client's name and
-- status, the shift's location and service, and the client's active alerts
-- and support instructions. Nothing else about the client, and nothing about
-- clients they aren't rostered with. Safe to run again.

drop policy if exists "workers see clients of their shifts" on public.car_clients;
create policy "workers see clients of their shifts" on public.car_clients
  for select to authenticated
  using (id in (select s.client_id from public.shifts s where s.worker_id = (select auth.uid()) and s.status = 'published' and s.ends_at > now() - interval '14 days' and s.client_id is not null));
drop policy if exists "workers see their shift locations" on public.client_locations;
create policy "workers see their shift locations" on public.client_locations
  for select to authenticated
  using (id in (select s.location_id from public.shifts s where s.worker_id = (select auth.uid()) and s.status = 'published' and s.ends_at > now() - interval '14 days' and s.location_id is not null));
drop policy if exists "workers see their shift services" on public.client_services;
create policy "workers see their shift services" on public.client_services
  for select to authenticated
  using (id in (select s.service_id from public.shifts s where s.worker_id = (select auth.uid()) and s.status = 'published' and s.ends_at > now() - interval '14 days' and s.service_id is not null));
drop policy if exists "workers see alerts for their shift clients" on public.client_alerts;
create policy "workers see alerts for their shift clients" on public.client_alerts
  for select to authenticated
  using (active and client_id in (select s.client_id from public.shifts s where s.worker_id = (select auth.uid()) and s.status = 'published' and s.ends_at > now() - interval '14 days' and s.client_id is not null));
drop policy if exists "workers see instructions for their shift clients" on public.client_worker_instructions;
create policy "workers see instructions for their shift clients" on public.client_worker_instructions
  for select to authenticated
  using (active and client_id in (select s.client_id from public.shifts s where s.worker_id = (select auth.uid()) and s.status = 'published' and s.ends_at > now() - interval '14 days' and s.client_id is not null));
