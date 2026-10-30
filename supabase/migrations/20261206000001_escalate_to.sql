-- Staff Portal · © cmeproject. All rights reserved.
--
-- Escalating to the right person (cmeprojects). A support worker escalates a
-- task to their team leader or to a manager; team leaders and staff admins
-- escalate straight to a manager. It shows in "Needs your attention" for
-- whoever it went to, who can add a helper, take it over or reassign it.
-- Reassigning or taking over an escalated task deals with the escalation.

alter table public.tasks add column if not exists escalated_to text check (escalated_to in ('team_leader', 'manager'));
alter table public.tasks add column if not exists escalated_by uuid references public.profiles (id);

-- The team leaders of the people looking after a task (or of whoever escalated it).
create or replace function public.task_team_leaders(p_task_id uuid, p_also uuid default null)
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select distinct l.user_id
    from public.tasks t
    join public.team_members m on m.user_id in (t.assigned_to, coalesce(p_also, t.assigned_to))
    join public.team_leaders l on l.team_id = m.team_id
    join public.profiles p on p.id = l.user_id and p.active
   where t.id = p_task_id
$$;
revoke execute on function public.task_team_leaders(uuid, uuid) from public, anon, authenticated;

drop function if exists public.escalate_task(uuid, text);
create or replace function public.escalate_task(p_task_id uuid, p_reason text, p_to text default 'manager')
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.tasks;
  v_to text := 'manager';
  v_user uuid;
  v_told int := 0;
begin
  select * into t from public.tasks where id = p_task_id for update;
  if t.id is null or not public.can_see_task(p_task_id) then
    raise exception 'Task not found';
  end if;
  if not (public.can_edit_task(p_task_id) or exists (select 1 from public.task_helpers where task_id = t.id and user_id = auth.uid())) then
    raise exception 'You can''t escalate this task';
  end if;
  if t.status in ('completed', 'closed', 'escalated') then
    raise exception 'This task can''t be escalated now';
  end if;
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'Say why it needs escalating';
  end if;
  -- Only support workers can send it to a team leader (if they have one).
  if p_to = 'team_leader' and public.my_role() = 'support_worker'
     and exists (select 1 from public.task_team_leaders(t.id, auth.uid()) x where x <> auth.uid()) then
    v_to := 'team_leader';
  end if;

  update public.tasks set status = 'escalated', escalated = true, escalated_to = v_to, escalated_by = auth.uid(), updated_at = now() where id = t.id;
  insert into public.task_events (task_id, actor_id, type, from_value, to_value, comment)
  values (t.id, auth.uid(), 'status_changed', t.status::text, 'escalated',
          trim(p_reason) || case when v_to = 'team_leader' then ' (to the team leader)' else ' (to a manager)' end);

  for v_user in
    select x from public.task_team_leaders(t.id, auth.uid()) x where v_to = 'team_leader'
    union
    select m from public.task_managers(t.id) m where v_to = 'manager'
  loop
    continue when v_user = auth.uid();
    perform public.notify(v_user, 'task_escalated', format('Escalated to you: %s', public.task_label(t.id)),
      format('%s: %s', public.my_name(), trim(p_reason)), '/tasks/' || t.id, true);
    v_told := v_told + 1;
  end loop;
  return v_to;
end;
$$;
revoke execute on function public.escalate_task(uuid, text, text) from public, anon;
grant execute on function public.escalate_task(uuid, text, text) to authenticated;

-- Dealt with: once it's no longer escalated, forget who it went to. Moving it
-- to someone else (reassign or take over) deals with the escalation.
create or replace function public.settle_escalation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if old.status = 'escalated' and new.status = 'escalated' and new.assigned_to is distinct from old.assigned_to then
    new.status := 'assigned';
    new.escalated := false;
  end if;
  if new.status <> 'escalated' then
    new.escalated_to := null;
  elsif old.status <> 'escalated' and new.escalated_to is null then
    -- Escalated by the overnight check: managers look at it.
    new.escalated_to := 'manager';
  end if;
  return new;
end;
$$;

drop trigger if exists tasks_settle_escalation on public.tasks;
create trigger tasks_settle_escalation before update on public.tasks
  for each row execute function public.settle_escalation();
