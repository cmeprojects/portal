-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 54: removes client-team links and the client on tasks.
-- Safe to run again.
begin;
drop function if exists public.my_team_clients();
drop function if exists public.task_client(uuid);
drop function if exists public.set_task_client(uuid, uuid);
drop function if exists public.clients_to_pick();
alter table public.tasks drop column if exists client_id;
drop table if exists public.client_teams;
commit;
