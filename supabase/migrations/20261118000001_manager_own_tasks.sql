-- Staff Portal · © cmeproject. All rights reserved.
--
-- Managers' own tasks don't need approval: a manager completing a task they
-- look after closes it directly (the page asks them to confirm). Tasks of
-- theirs already waiting for approval can be approved by them. Approval
-- requests go to the register's managers, or to every other manager when
-- the register's only manager is the one who sent it.

create or replace function public.can_approve_task(p_task_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and exists (
    select 1 from public.tasks t
     where t.id = p_task_id
       -- Nobody approves their own work, except managers (their own tasks don't need approval).
       and (t.assigned_to <> auth.uid() or public.has_role(array['manager']::public.app_role[]))
       and (public.is_system_admin()
            or (public.has_role(array['manager']::public.app_role[])
                and (exists (select 1 from public.registry_managers rm where rm.registry_id = t.registry_id and rm.user_id = auth.uid())
                     or not exists (select 1 from public.registry_managers rm join public.profiles p on p.id = rm.user_id and p.active
                                     where rm.registry_id = t.registry_id))))
  )
$$;

create or replace function public.set_task_status(p_task_id uuid, p_status public.task_status, p_note text default '')
returns public.task_status
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.tasks;
  v_requires boolean;
  v_to public.task_status := p_status;
  v_note text := coalesce(trim(p_note), '');
  v_mine boolean;
  v_editor boolean;
  v_approver boolean;
  v_label text;
  v_user uuid;
begin
  if not public.is_member() then
    raise exception 'Please sign in again';
  end if;
  select * into t from public.tasks where id = p_task_id for update;
  if t.id is null or not public.can_see_task(p_task_id) then
    raise exception 'Task not found';
  end if;
  select requires_approval into v_requires from public.registries where id = t.registry_id;
  v_mine := t.assigned_to = auth.uid();
  v_editor := public.can_edit_task(p_task_id);
  v_approver := public.can_approve_task(p_task_id);
  v_label := public.task_label(p_task_id);

  if p_status = t.status then
    raise exception 'The task is already %', replace(t.status::text, '_', ' ');
  end if;

  if p_status = 'in_progress' then
    if t.status = 'assigned' and v_editor then
      null;
    elsif t.status = 'awaiting_approval' and v_approver then
      if v_note = '' then raise exception 'Say what still needs doing, so they know'; end if;
    elsif t.status = 'escalated' and v_editor and not v_mine then
      null; -- the escalation has been dealt with
    elsif t.status in ('completed', 'closed') and v_editor and not v_mine then
      if v_note = '' then raise exception 'Give a reason for reopening the task'; end if;
    else
      raise exception 'You can''t make this change';
    end if;

  elsif p_status = 'completed' then
    if t.status = 'awaiting_approval' then
      if not v_approver then raise exception 'A manager of this register approves it'; end if;
    elsif t.status in ('assigned', 'in_progress', 'escalated') and v_editor then
      if exists (select 1 from public.tasks a where a.parent_task_id = t.id and a.status not in ('completed', 'closed')) then
        raise exception 'Finish or close its follow-up actions first';
      end if;
      if cardinality(public.task_missing_fields(t.id)) > 0 then
        raise exception 'Fill these in first: %', array_to_string(public.task_missing_fields(t.id), ', ');
      end if;
      -- A manager finishing their own task closes it without an approval step.
      if v_requires and not v_approver
         and not (v_mine and public.has_role(array['manager']::public.app_role[])) then
        v_to := 'awaiting_approval';
      end if;
    else
      raise exception 'You can''t make this change';
    end if;

  elsif p_status = 'closed' then
    if t.status <> 'completed' then raise exception 'Only completed tasks can be closed'; end if;
    if not (v_editor and (not v_mine or t.created_by = auth.uid())) then
      raise exception 'The person who created it, a team leader or a manager closes it';
    end if;

  else
    raise exception 'Use Escalate to escalate a task';
  end if;

  update public.tasks
     set status = v_to,
         escalated = case when v_to = 'in_progress' and t.status = 'escalated' then false else escalated end,
         completed_at = case when v_to = 'completed' then now() when v_to = 'in_progress' then null else completed_at end,
         closed_at = case when v_to = 'closed' then now() when v_to = 'in_progress' then null else closed_at end,
         updated_at = now()
   where id = t.id;
  insert into public.task_events (task_id, actor_id, type, from_value, to_value, comment)
  values (t.id, auth.uid(), 'status_changed', t.status::text, v_to::text, nullif(v_note, ''));

  -- Who hears about it.
  if v_to = 'awaiting_approval' then
    -- The register's managers; if none (other than whoever sent it), every other manager.
    for v_user in
      with reg as (
        select p.id from public.profiles p
          join public.registry_managers rm on rm.user_id = p.id and rm.registry_id = t.registry_id
         where p.active and p.role = 'manager' and p.id <> auth.uid()
      )
      select id from reg
      union
      select p.id from public.profiles p
       where p.active and p.role = 'manager' and p.id <> auth.uid() and not exists (select 1 from reg)
    loop
      perform public.notify(v_user, 'approval_needed', format('Approve: %s', v_label),
        format('%s has finished this and it needs your approval to close.', public.my_name()), '/tasks/' || t.id, true);
    end loop;
  elsif t.status = 'awaiting_approval' and v_to = 'in_progress' then
    perform public.notify(t.assigned_to, 'sent_back', format('Sent back: %s', v_label), v_note, '/tasks/' || t.id, true);
  elsif v_to = 'completed' then
    perform public.notify_task_people(t.id, 'task_completed', format('Completed: %s', v_label),
      format('by %s', public.my_name()));
  elsif v_to = 'in_progress' and t.status in ('completed', 'closed') then
    perform public.notify_task_people(t.id, 'task_reopened', format('Reopened: %s', v_label), v_note, true);
  end if;
  return v_to;
end;
$$;

-- Sign people out after a period without activity (0 = never).
insert into public.app_settings (key, value, label, description, is_public) values
  ('security.idle_minutes', '30', 'Sign out after (minutes without activity)',
   'People are signed out after this long without using the portal, even if they closed the browser. 0 means never.', false)
on conflict (key) do nothing;
