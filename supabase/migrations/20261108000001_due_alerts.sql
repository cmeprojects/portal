-- Staff Portal · © cmeproject. All rights reserved.
--
-- Reminders, overdue alerts and automatic escalation. A timer calls
-- run_due_alerts() every hour; each step is sent once per task and due date.
--   Reminder   N working days before it's due  → the person looking after it
--   Due today                                   → them and helpers
--   Overdue    the day after it's due           → them and their team leaders
--                                                 (managers if there's no leader)
--   Escalated  N working days overdue           → managers; the task is
--                                                 marked escalated
--   Summary    every weekday from 7am           → managers, one email listing
--                                                 everything overdue
-- Completed and closed tasks, and tasks with no due date, never alert.

insert into public.app_settings (key, value, label, description, is_public) values
  ('tasks.sla_remind_days', '1', 'Reminder before the due date (days)',
   'Remind the person looking after a task this many days before it''s due. 0 means no reminder.', false),
  ('tasks.sla_escalate_days', '3', 'Escalate after (days overdue)',
   'Tell the managers and mark a task escalated when it''s this many days overdue.', false),
  ('tasks.sla_manager_summary', 'true', 'Morning summary for managers',
   'Every weekday morning, email managers one list of everything overdue.', false)
on conflict (key) do nothing;

-- What has been sent, so nobody hears about the same step twice. A new due
-- date starts the steps again.
create table public.task_alerts (
  id         bigint generated always as identity primary key,
  task_id    uuid not null references public.tasks (id) on delete cascade,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  step       text not null check (step in ('reminder', 'due_today', 'overdue', 'escalated')),
  due_date   date not null,
  created_at timestamptz not null default now(),
  unique (task_id, user_id, step, due_date)
);

create index task_alerts_user_idx on public.task_alerts (user_id, created_at desc);

alter table public.task_alerts enable row level security;
create policy "read your own alerts" on public.task_alerts
  for select to authenticated using (user_id = auth.uid());
revoke insert, update, delete, truncate on public.task_alerts from anon, authenticated;

-- Jobs that run once a day (the morning summary).
create table public.daily_runs (
  job text not null,
  day date not null,
  ran_at timestamptz not null default now(),
  primary key (job, day)
);
alter table public.daily_runs enable row level security;
revoke all on public.daily_runs from anon, authenticated;

-- Working days after p_from up to and including p_to (negative if p_to is earlier).
create function public.working_days_between(p_from date, p_to date, p_weekdays_only boolean)
returns int
language sql
immutable
set search_path = ''
as $$
  select case
    when not p_weekdays_only then p_to - p_from
    when p_to >= p_from then (select count(*)::int from generate_series(p_from + 1, p_to, interval '1 day') d
                               where extract(isodow from d) < 6)
    else -(select count(*)::int from generate_series(p_to + 1, p_from, interval '1 day') d
            where extract(isodow from d) < 6)
  end
$$;

-- Managers for a task: its register's managers, or every manager if it has none.
create function public.task_managers(p_task_id uuid)
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  with reg as (
    select rm.user_id from public.registry_managers rm
      join public.tasks t on t.registry_id = rm.registry_id
      join public.profiles p on p.id = rm.user_id and p.active and p.role = 'manager'
     where t.id = p_task_id
  )
  select user_id from reg
  union
  select id from public.profiles where active and role = 'manager' and not exists (select 1 from reg)
$$;

-- Records an alert and, the first time only, puts it in the bell and emails it.
create function public.send_due_alert(p_task_id uuid, p_user_id uuid, p_step text, p_due date)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id bigint;
begin
  if not exists (select 1 from public.profiles where id = p_user_id and active and role <> 'system_admin') then
    return;
  end if;
  insert into public.task_alerts (task_id, user_id, step, due_date)
  values (p_task_id, p_user_id, p_step, p_due)
  on conflict do nothing
  returning id into v_id;
  if v_id is not null then
    perform public.queue_task_email('task_' || p_step, p_task_id, p_user_id);
  end if;
end;
$$;

-- p_now is only for tests; the timer always uses the real time.
create function public.run_due_alerts(p_now timestamptz default now())
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tz text := coalesce((select value #>> '{}' from public.app_settings where key = 'region.timezone'), 'Australia/Melbourne');
  v_now timestamp := p_now at time zone v_tz;
  v_today date := v_now::date;
  v_weekdays boolean := coalesce((select (value #>> '{}')::boolean from public.app_settings where key = 'tasks.sla_weekdays_only'), false);
  v_remind int := coalesce((select (value #>> '{}')::int from public.app_settings where key = 'tasks.sla_remind_days'), 1);
  v_escalate int := coalesce((select (value #>> '{}')::int from public.app_settings where key = 'tasks.sla_escalate_days'), 3);
  v_summary boolean := coalesce((select (value #>> '{}')::boolean from public.app_settings where key = 'tasks.sla_manager_summary'), true);
  v_weekend boolean := extract(isodow from v_today) >= 6;
  t record;
  v_late int;
  v_person uuid;
  v_leaders uuid[];
  v_escalated int := 0;
  v_summaries int := 0;
  v_list jsonb;
begin
  if not public.feature_enabled('tasks') then
    return jsonb_build_object('skipped', 'tasks are switched off');
  end if;
  -- With "weekdays only", nothing is sent at the weekend; Monday catches up.
  if v_weekdays and v_weekend then
    return jsonb_build_object('skipped', 'weekend');
  end if;

  for t in
    select id, assigned_to, due_date, status, escalated
      from public.tasks
     where due_date is not null
       and status not in ('completed', 'closed')
       and due_date <= v_today + greatest(v_remind, 0) + 7
  loop
    v_late := public.working_days_between(t.due_date, v_today, v_weekdays);

    if t.due_date > v_today then
      if v_remind > 0 and -v_late <= v_remind then
        perform public.send_due_alert(t.id, t.assigned_to, 'reminder', t.due_date);
      end if;
      continue;
    end if;

    if t.due_date = v_today then
      perform public.send_due_alert(t.id, t.assigned_to, 'due_today', t.due_date);
      for v_person in select user_id from public.task_helpers where task_id = t.id loop
        perform public.send_due_alert(t.id, v_person, 'due_today', t.due_date);
      end loop;
      continue;
    end if;

    -- Overdue: the person and their team leaders (managers if there are none).
    perform public.send_due_alert(t.id, t.assigned_to, 'overdue', t.due_date);
    select coalesce(array_agg(distinct tl.user_id), '{}') into v_leaders
      from public.team_members m
      join public.team_leaders tl on tl.team_id = m.team_id
      join public.profiles p on p.id = tl.user_id and p.active
     where m.user_id = t.assigned_to and tl.user_id <> t.assigned_to;
    if cardinality(v_leaders) = 0 then
      select coalesce(array_agg(m), '{}') into v_leaders from public.task_managers(t.id) m;
    end if;
    foreach v_person in array v_leaders loop
      perform public.send_due_alert(t.id, v_person, 'overdue', t.due_date);
    end loop;

    -- Still overdue: managers, and the task is marked escalated.
    if v_escalate > 0 and v_late >= v_escalate then
      if t.status <> 'escalated' then
        update public.tasks set status = 'escalated', escalated = true, updated_at = now() where id = t.id;
        insert into public.task_events (task_id, actor_id, type, from_value, to_value, comment)
        values (t.id, null, 'status_changed', t.status::text, 'escalated',
                format('Escalated automatically: %s days overdue', v_late));
        v_escalated := v_escalated + 1;
      end if;
      for v_person in select m from public.task_managers(t.id) m loop
        perform public.send_due_alert(t.id, v_person, 'escalated', t.due_date);
      end loop;
    end if;
  end loop;

  -- The morning summary, once each weekday from 7am.
  if v_summary and not v_weekend and extract(hour from v_now) >= 7 and public.feature_enabled('email_notifications') then
    insert into public.daily_runs (job, day) values ('manager_summary', v_today) on conflict do nothing;
    if found then
      select jsonb_agg(jsonb_build_object(
               'id', t2.id,
               'ref', coalesce(r.prefix, 'T') || '-' || lpad(t2.ref_number::text, 4, '0'),
               'title', t2.title,
               'registry', r.name,
               'assignee', case when p.role = 'system_admin' then 'Admin' else coalesce(nullif(p.full_name, ''), p.email) end,
               'due_date', t2.due_date,
               'days_late', public.working_days_between(t2.due_date, v_today, v_weekdays),
               'escalated', t2.status = 'escalated')
             order by t2.due_date, t2.ref_number)
        into v_list
        from public.tasks t2
        join public.registries r on r.id = t2.registry_id
        join public.profiles p on p.id = t2.assigned_to
       where t2.due_date < v_today and t2.status not in ('completed', 'closed');
      if v_list is not null then
        insert into public.email_outbox (to_user, template, data)
        select id, 'overdue_summary', jsonb_build_object('tasks', v_list, 'day', v_today)
          from public.profiles where active and role = 'manager';
        get diagnostics v_summaries = row_count;
      end if;
    end if;
  end if;

  return jsonb_build_object('today', v_today, 'escalated', v_escalated, 'summaries', v_summaries);
end;
$$;

revoke execute on function public.run_due_alerts(timestamptz) from public, anon, authenticated;
revoke execute on function public.send_due_alert(uuid, uuid, text, date) from public, anon, authenticated;
revoke execute on function public.task_managers(uuid) from public, anon, authenticated;
grant execute on function public.run_due_alerts(timestamptz) to service_role;

-- The bell: reminders and overdue alerts you haven't opened since.
create function public.my_due_alerts()
returns table (task_id uuid, step text, at timestamptz)
language sql
stable
security definer
set search_path = ''
as $$
  select distinct on (a.task_id) a.task_id, a.step, a.created_at
    from public.task_alerts a
    join public.tasks t on t.id = a.task_id
   where public.is_member()
     and a.user_id = auth.uid()
     and t.status not in ('completed', 'closed')
     and a.due_date = t.due_date
     and not exists (select 1 from public.task_views v
                      where v.task_id = a.task_id and v.user_id = auth.uid() and v.seen_at >= a.created_at)
   order by a.task_id,
            array_position(array['escalated', 'overdue', 'due_today', 'reminder'], a.step),
            a.created_at desc
$$;

create or replace function public.mark_all_tasks_seen()
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.task_views (task_id, user_id, seen_at)
  select n.task_id, auth.uid(), now() from public.my_new_tasks() n
  union
  select a.task_id, auth.uid(), now() from public.my_due_alerts() a
  on conflict (task_id, user_id) do update set seen_at = excluded.seen_at
$$;

revoke execute on function public.my_due_alerts() from public, anon;
grant execute on function public.my_due_alerts() to authenticated;
