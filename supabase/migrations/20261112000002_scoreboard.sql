-- Staff Portal · © cmeproject. All rights reserved.
--
-- Scoreboard: how each person is going with their tasks, so staff admins
-- can see who needs support. The system admin chooses who else can see it;
-- team leaders (if allowed) see only the team they lead.

insert into public.app_settings (key, value, label, description, is_public) values
  ('people.scoreboard_roles', '["staff_admin", "manager"]', 'Who can see the scoreboard',
   'Besides the system admin. Team leaders, if ticked, see only the team they lead.', false),
  ('people.stuck_days', '7', 'A task is stuck after (days without activity)',
   'On the scoreboard, an open task with nothing done on it for this many days counts as stuck.', false)
on conflict (key) do nothing;

create function public.can_see_scoreboard()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.mfa_ok() and (public.my_role() = 'system_admin'
         or public.my_role() = any (public.setting_roles('people.scoreboard_roles')))
$$;

create function public.staff_scoreboard(p_days int default 30)
returns table (
  user_id uuid,
  full_name text,
  role public.app_role,
  open_tasks int,
  overdue int,
  escalated int,
  stuck int,
  completed int,
  completed_on_time int,
  completed_with_due int,
  avg_days_late numeric,
  oldest_overdue date,
  onboarding_missing int
)
language sql
stable
security definer
set search_path = ''
as $$
  with params as (
    select public.local_today() as today,
           greatest(coalesce(p_days, 30), 1) as days,
           coalesce((select (value #>> '{}')::int from public.app_settings where key = 'people.stuck_days'), 7) as stuck_days
  ),
  people as (
    select p.* from public.profiles p
     where public.can_see_scoreboard()
       and p.active and p.role not in ('system_admin', 'new_starter')
       and p.id <> auth.uid()
       and (public.my_role() <> 'team_leader' or public.leads_user(p.id))
  ),
  last_activity as (
    select e.task_id, max(e.created_at) as at from public.task_events e group by e.task_id
  ),
  t as (
    select tk.*, coalesce(la.at, tk.updated_at) as last_at
      from public.tasks tk
      left join last_activity la on la.task_id = tk.id
     where tk.assigned_to in (select id from people)
  )
  select p.id,
         coalesce(nullif(p.full_name, ''), p.email),
         p.role,
         count(*) filter (where t.status not in ('completed', 'closed'))::int,
         count(*) filter (where t.status not in ('completed', 'closed') and t.due_date < pr.today)::int,
         count(*) filter (where t.status = 'escalated')::int,
         count(*) filter (where t.status not in ('completed', 'closed')
                            and t.last_at < now() - make_interval(days => pr.stuck_days))::int,
         count(*) filter (where t.completed_at >= now() - make_interval(days => pr.days))::int,
         count(*) filter (where t.completed_at >= now() - make_interval(days => pr.days)
                            and t.due_date is not null and t.completed_at::date <= t.due_date)::int,
         count(*) filter (where t.completed_at >= now() - make_interval(days => pr.days) and t.due_date is not null)::int,
         round(avg(t.completed_at::date - t.due_date) filter (where t.completed_at >= now() - make_interval(days => pr.days)
                                                               and t.due_date is not null and t.completed_at::date > t.due_date), 1),
         min(t.due_date) filter (where t.status not in ('completed', 'closed') and t.due_date < pr.today),
         cardinality(public.onboarding_missing(p.id))
    from people p
    cross join params pr
    left join t on t.assigned_to = p.id
   group by p.id, p.full_name, p.email, p.role
$$;

revoke execute on function public.staff_scoreboard(int) from public, anon;
grant execute on function public.staff_scoreboard(int) to authenticated;
