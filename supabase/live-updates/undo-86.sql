-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 86: removes team_clients() and puts update 85's staff read rule
-- back (staff read their teams' whole client rows again). Safe to run again.
begin;
drop function if exists public.team_clients();
drop policy if exists "staff see their teams' clients" on public.car_clients;
create policy "staff see their teams' clients" on public.car_clients
  for select to authenticated
  using ((select public.is_member()) and exists (
    select 1 from public.client_teams ct
     where ct.client_id = car_clients.id
       and (exists (select 1 from public.team_members tm where tm.team_id = ct.team_id and tm.user_id = (select auth.uid()))
            or exists (select 1 from public.team_leaders tl where tl.team_id = ct.team_id and tl.user_id = (select auth.uid())))));
commit;
