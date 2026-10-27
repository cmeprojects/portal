-- Staff Portal · © cmeproject. All rights reserved.
--
-- The bell: tasks newly given to you (to look after or to help on) that you
-- haven't opened since. Opening a task, or "Mark all as seen", clears it.

create table public.task_views (
  task_id uuid not null references public.tasks (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  seen_at timestamptz not null default now(),
  primary key (task_id, user_id)
);

alter table public.task_views enable row level security;

create policy "read your own views" on public.task_views
  for select to authenticated using (user_id = auth.uid());
revoke insert, update, delete, truncate on public.task_views from anon, authenticated;

-- Tasks given to the signed-in person by someone else, not yet opened since.
create function public.my_new_tasks()
returns table (task_id uuid, kind text, actor_id uuid, at timestamptz)
language sql
stable
security definer
set search_path = ''
as $$
  select distinct on (e.task_id)
         e.task_id,
         case when e.type = 'helper_added' then 'helping' else 'assigned' end,
         e.actor_id,
         e.created_at
    from public.task_events e
    join public.tasks t on t.id = e.task_id
   where public.is_member()
     and e.to_value = auth.uid()::text
     and e.type in ('created', 'helper_added', 'reassigned')
     and e.actor_id is distinct from auth.uid()
     and t.status not in ('completed', 'closed')
     -- Still looking after it / still helping.
     and (t.assigned_to = auth.uid()
          or exists (select 1 from public.task_helpers h where h.task_id = t.id and h.user_id = auth.uid()))
     and not exists (
       select 1 from public.task_views v
        where v.task_id = e.task_id and v.user_id = auth.uid() and v.seen_at >= e.created_at)
   order by e.task_id, e.created_at desc
$$;

create function public.mark_task_seen(p_task_id uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.task_views (task_id, user_id, seen_at)
  select p_task_id, auth.uid(), now()
   where public.can_see_task(p_task_id)
  on conflict (task_id, user_id) do update set seen_at = excluded.seen_at
$$;

create function public.mark_all_tasks_seen()
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.task_views (task_id, user_id, seen_at)
  select n.task_id, auth.uid(), now() from public.my_new_tasks() n
  on conflict (task_id, user_id) do update set seen_at = excluded.seen_at
$$;

revoke execute on function public.my_new_tasks() from public, anon;
revoke execute on function public.mark_task_seen(uuid) from public, anon;
revoke execute on function public.mark_all_tasks_seen() from public, anon;
grant execute on function public.my_new_tasks() to authenticated;
grant execute on function public.mark_task_seen(uuid) to authenticated;
grant execute on function public.mark_all_tasks_seen() to authenticated;
