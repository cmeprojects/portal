-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 85: removes the client reference, status, preferred name,
-- programs and the staff read rule. Clients themselves (names, teams, trips,
-- tasks) are untouched. Note: references given out are lost; running update
-- 85 again gives new ones (the sequence restarts). Safe to run again.
begin;
drop policy if exists "staff see their teams' clients" on public.car_clients;
drop trigger if exists guard_client_record on public.car_clients;
drop function if exists public.guard_client_record();
drop index if exists public.car_clients_client_ref;
alter table public.car_clients drop constraint if exists car_clients_status_check;
alter table public.car_clients drop constraint if exists car_clients_preferred_name_check;
alter table public.car_clients
  drop column if exists client_ref,
  drop column if exists status,
  drop column if exists preferred_name,
  drop column if exists status_changed_at,
  drop column if exists status_changed_by;
drop function if exists public.next_client_ref();
drop sequence if exists public.client_ref_seq;
drop table if exists public.client_programs;
commit;
