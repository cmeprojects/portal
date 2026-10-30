-- Staff Portal · © cmeproject. All rights reserved.
--
-- Live updates for tasks (cmeprojects): the bell, task lists and an open task
-- update by themselves when a task is created, assigned or changes, and when
-- a role change request is sent or decided.

do $live$
declare
  t text;
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    return;
  end if;
  foreach t in array array['tasks', 'task_events', 'people_change_requests'] loop
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end;
$live$;
