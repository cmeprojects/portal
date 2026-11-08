-- Staff Portal · © cmeproject. All rights reserved.
-- Update 54: clients linked to teams, an optional client on tasks, and a team
-- leader's clients for their dashboard. Safe to run again. Undo: undo-54.sql.
begin;
create table if not exists public.client_teams (
  client_id uuid not null references public.car_clients (id) on delete cascade,
  team_id   uuid not null references public.teams (id) on delete cascade,
  primary key (client_id, team_id)
);

alter table public.client_teams enable row level security;
drop policy if exists "members see which team looks after which client" on public.client_teams;
create policy "members see which team looks after which client" on public.client_teams
  for select to authenticated using (public.is_member());
drop policy if exists "people managers link clients to teams" on public.client_teams;
create policy "people managers link clients to teams" on public.client_teams
  for insert to authenticated with check (public.can_manage_people());
drop policy if exists "people managers unlink clients from teams" on public.client_teams;
create policy "people managers unlink clients from teams" on public.client_teams
  for delete to authenticated using (public.can_manage_people());
revoke update, truncate on public.client_teams from anon, authenticated;

alter table public.tasks add column if not exists client_id uuid references public.car_clients (id) on delete set null;
create index if not exists tasks_client on public.tasks (client_id) where client_id is not null;

-- Client names to pick from on a task (names only, like the Cars app).
create or replace function public.clients_to_pick()
returns table (id uuid, name text)
language sql
stable
security definer
set search_path = ''
as $$
  select c.id, c.name from public.car_clients c
   where c.active and public.is_member()
   order by c.name;
$$;

-- Set (or clear) the client a task is about: anyone who can work on the task.
create or replace function public.set_task_client(p_task uuid, p_client uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.can_edit_task(p_task) then
    raise exception 'Only people working on this task can change its client.';
  end if;
  if p_client is not null and not exists (select 1 from public.car_clients where id = p_client and active) then
    raise exception 'Choose a client from the list.';
  end if;
  update public.tasks set client_id = p_client where id = p_task;
end;
$$;

-- The client's name on a task, for anyone who can see the task.
create or replace function public.task_client(p_task uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select c.name from public.tasks t join public.car_clients c on c.id = t.client_id
   where t.id = p_task and public.can_see_task(p_task);
$$;

-- A team leader's clients: the clients their team(s) look after, with how
-- many of their tasks are open and overdue.
create or replace function public.my_team_clients()
returns table (client_id uuid, client_name text, team_name text, open_tasks bigint, overdue_tasks bigint)
language sql
stable
security definer
set search_path = ''
as $$
  select c.id, c.name, string_agg(distinct tm.name, ', '),
         (select count(*) from public.tasks t where t.client_id = c.id and t.status not in ('completed', 'closed')),
         (select count(*) from public.tasks t where t.client_id = c.id and t.status not in ('completed', 'closed') and t.due_date < current_date)
    from public.team_leaders tl
    join public.client_teams ct on ct.team_id = tl.team_id
    join public.car_clients c on c.id = ct.client_id and c.active
    join public.teams tm on tm.id = tl.team_id
   where tl.user_id = auth.uid()
   group by c.id, c.name
   order by c.name;
$$;

revoke execute on function public.clients_to_pick() from public, anon;
revoke execute on function public.set_task_client(uuid, uuid) from public, anon;
revoke execute on function public.task_client(uuid) from public, anon;
revoke execute on function public.my_team_clients() from public, anon;
grant execute on function public.clients_to_pick() to authenticated;
grant execute on function public.set_task_client(uuid, uuid) to authenticated;
grant execute on function public.task_client(uuid) to authenticated;
grant execute on function public.my_team_clients() to authenticated;
commit;
