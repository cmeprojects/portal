-- Staff Portal · © cmeproject. All rights reserved.
-- Update 86: staff see only the basic record of their teams' clients (fixes
-- update 85 exposing the free-text reference). Safe to run again.
-- Undo: undo-86.sql. Run update 85 first.
begin;
-- cmeprojects (update 86): staff see only the basic record of their teams'
-- clients. Update 85's read rule gave team members and team leaders the
-- whole client row, including the free-text reference (where some
-- organisations keep an NDIS number). No screen showed it, but it could be
-- read from the database. Now:
--   * that read rule is removed (people managers, car managers and the system
--     admin are unchanged);
--   * team_clients() gives staff and team leaders, for clients linked to their
--     own teams only: id, reference (CL-), name, preferred name and status.
--     Never the free-text reference, the shown/hidden flag or who added it.
-- team_clients() is SECURITY DEFINER (owner approval needed), like
-- team_private() in update 84: fixed columns, own teams only.

drop policy if exists "staff see their teams' clients" on public.car_clients;

create or replace function public.team_clients()
returns table (id uuid, client_ref text, name text, preferred_name text, status text)
language sql
stable
security definer
set search_path = ''
as $$
  select c.id, c.client_ref, c.name, c.preferred_name, c.status
    from public.car_clients c
   where auth.uid() is not null
     and public.is_member()
     and exists (
       select 1 from public.client_teams ct
        where ct.client_id = c.id
          and (exists (select 1 from public.team_members tm where tm.team_id = ct.team_id and tm.user_id = auth.uid())
               or exists (select 1 from public.team_leaders tl where tl.team_id = ct.team_id and tl.user_id = auth.uid())))
   order by c.name
$$;

revoke execute on function public.team_clients() from public, anon;
grant execute on function public.team_clients() to authenticated;
commit;
