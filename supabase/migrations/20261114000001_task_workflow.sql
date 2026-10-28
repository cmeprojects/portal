-- Staff Portal · © cmeproject. All rights reserved.
--
-- Working on tasks (Milestone 3): status changes, approvals, comments,
-- escalating, reassigning, taking over and attachments. Everything goes
-- through these functions, is written to the task's history, and tells the
-- right people (bell; email only where action is needed).
--   assigned → in progress → completed → closed
--   In registers that need approval, "complete" goes to awaiting approval;
--   a manager of the register approves it or sends it back with a reason.

-- Approvers: the register's managers (or every manager if it has none) and
-- the system admin, but never the person who did the work.
create function public.can_approve_task(p_task_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and exists (
    select 1 from public.tasks t
     where t.id = p_task_id
       and t.assigned_to <> auth.uid()
       and (public.is_system_admin()
            or (public.has_role(array['manager']::public.app_role[])
                and (exists (select 1 from public.registry_managers rm where rm.registry_id = t.registry_id and rm.user_id = auth.uid())
                     or not exists (select 1 from public.registry_managers rm join public.profiles p on p.id = rm.user_id and p.active
                                     where rm.registry_id = t.registry_id))))
  )
$$;

-- Everyone involved in a task (to tell them about changes).
create function public.task_people(p_task_id uuid)
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select assigned_to from public.tasks where id = p_task_id
  union select created_by from public.tasks where id = p_task_id
  union select user_id from public.task_helpers where task_id = p_task_id
$$;

create function public.task_label(p_task_id uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(r.prefix, 'T') || '-' || lpad(t.ref_number::text, 4, '0') || ' ' || t.title
    from public.tasks t join public.registries r on r.id = t.registry_id where t.id = p_task_id
$$;

create function public.my_name()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select case when role = 'system_admin' then 'Admin' else coalesce(nullif(full_name, ''), email) end
    from public.profiles where id = auth.uid()
$$;

-- Tell everyone on the task except whoever did it.
create function public.notify_task_people(p_task_id uuid, p_kind text, p_title text, p_body text, p_email boolean default false)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid;
begin
  for v_user in select u from public.task_people(p_task_id) u loop
    continue when v_user = auth.uid();
    perform public.notify(v_user, p_kind, p_title, p_body, '/tasks/' || p_task_id, p_email);
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- Status
-- ---------------------------------------------------------------------------

create function public.set_task_status(p_task_id uuid, p_status public.task_status, p_note text default '')
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
      if v_requires and not v_approver then
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
    for v_user in
      select p.id from public.profiles p
       where p.active and p.id <> auth.uid() and p.role = 'manager'
         and (exists (select 1 from public.registry_managers rm where rm.registry_id = t.registry_id and rm.user_id = p.id)
              or not exists (select 1 from public.registry_managers rm join public.profiles q on q.id = rm.user_id and q.active
                              where rm.registry_id = t.registry_id))
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

-- ---------------------------------------------------------------------------
-- Comments, escalating, reassigning, taking over
-- ---------------------------------------------------------------------------

create function public.add_task_comment(p_task_id uuid, p_body text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_body text := trim(coalesce(p_body, ''));
begin
  if not public.can_see_task(p_task_id) then
    raise exception 'Task not found';
  end if;
  if v_body = '' then
    raise exception 'Write a comment first';
  end if;
  if length(v_body) > 4000 then
    raise exception 'Keep comments under 4,000 characters';
  end if;
  insert into public.task_events (task_id, actor_id, type, comment) values (p_task_id, auth.uid(), 'comment', v_body);
  update public.tasks set updated_at = now() where id = p_task_id;
  perform public.notify_task_people(p_task_id, 'task_comment',
    format('%s commented on %s', public.my_name(), public.task_label(p_task_id)), left(v_body, 160));
end;
$$;

create function public.escalate_task(p_task_id uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.tasks;
  v_user uuid;
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
  update public.tasks set status = 'escalated', escalated = true, updated_at = now() where id = t.id;
  insert into public.task_events (task_id, actor_id, type, from_value, to_value, comment)
  values (t.id, auth.uid(), 'status_changed', t.status::text, 'escalated', trim(p_reason));
  for v_user in select m from public.task_managers(t.id) m loop
    continue when v_user = auth.uid();
    perform public.notify(v_user, 'task_escalated', format('Escalated: %s', public.task_label(t.id)),
      format('%s: %s', public.my_name(), trim(p_reason)), '/tasks/' || t.id, true);
  end loop;
end;
$$;

create function public.reassign_task(p_task_id uuid, p_to uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.tasks;
begin
  select * into t from public.tasks where id = p_task_id for update;
  if t.id is null or not public.can_edit_task(p_task_id) then
    raise exception 'You can''t reassign this task';
  end if;
  if t.status in ('completed', 'closed') then
    raise exception 'Reopen the task before reassigning it';
  end if;
  if p_to is null or p_to = t.assigned_to then
    raise exception 'Choose someone else to look after it';
  end if;
  if not public.can_take_tasks(p_to) then
    raise exception 'Choose someone who can be given tasks';
  end if;
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'Give a reason for the change';
  end if;
  update public.tasks set assigned_to = p_to, updated_at = now() where id = t.id;
  delete from public.task_helpers where task_id = t.id and user_id = p_to;
  insert into public.task_events (task_id, actor_id, type, from_value, to_value, comment)
  values (t.id, auth.uid(), 'reassigned', t.assigned_to::text, p_to::text, trim(p_reason));
  perform public.queue_task_email('task_assigned', t.id, p_to);
  if t.assigned_to <> auth.uid() then
    perform public.notify(t.assigned_to, 'task_reassigned', format('Moved to someone else: %s', public.task_label(t.id)),
      trim(p_reason), '/tasks/' || t.id);
  end if;
end;
$$;

-- Team leaders and managers take over a task themselves.
create function public.take_over_task(p_task_id uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.has_role(array['team_leader', 'manager']::public.app_role[]) then
    raise exception 'Team leaders and managers can take over tasks';
  end if;
  perform public.reassign_task(p_task_id, auth.uid(), p_reason);
end;
$$;

-- ---------------------------------------------------------------------------
-- Attachments (files live in the private "task-files" bucket, in a folder
-- named by the task id; only people who can see the task can open them)
-- ---------------------------------------------------------------------------

create table public.task_attachments (
  id          bigint generated always as identity primary key,
  task_id     uuid not null references public.tasks (id) on delete cascade,
  file_path   text not null,
  file_name   text not null,
  size_bytes  bigint,
  uploaded_by uuid not null references public.profiles (id),
  created_at  timestamptz not null default now()
);

create index task_attachments_task_idx on public.task_attachments (task_id);
alter table public.task_attachments enable row level security;
create policy "people who see the task see its files" on public.task_attachments
  for select to authenticated using (public.can_see_task(task_id));
revoke insert, update, delete, truncate on public.task_attachments from anon, authenticated;

create function public.add_task_attachment(p_task_id uuid, p_path text, p_name text, p_size bigint default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.can_see_task(p_task_id) then
    raise exception 'Task not found';
  end if;
  if p_path is null or p_path not like p_task_id::text || '/%' then
    raise exception 'Upload the file again';
  end if;
  insert into public.task_attachments (task_id, file_path, file_name, size_bytes, uploaded_by)
  values (p_task_id, p_path, left(coalesce(nullif(trim(p_name), ''), 'file'), 200), p_size, auth.uid());
  insert into public.task_events (task_id, actor_id, type, comment) values (p_task_id, auth.uid(), 'attachment_added', left(p_name, 200));
  update public.tasks set updated_at = now() where id = p_task_id;
end;
$$;

create function public.task_folder_ok(p_name text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case when split_part(p_name, '/', 1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
              then public.can_see_task(split_part(p_name, '/', 1)::uuid) else false end
$$;

do $storage$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  insert into storage.buckets (id, name, public, file_size_limit)
  values ('task-files', 'task-files', false, 10485760)
  on conflict (id) do nothing;
  create policy "people on a task add files" on storage.objects
    for insert to authenticated with check (bucket_id = 'task-files' and public.task_folder_ok(name));
  create policy "people on a task open files" on storage.objects
    for select to authenticated using (bucket_id = 'task-files' and public.task_folder_ok(name));
end;
$storage$;

revoke execute on function public.notify_task_people(uuid, text, text, text, boolean) from public, anon, authenticated;
revoke execute on function public.task_people(uuid) from public, anon, authenticated;
revoke execute on function public.set_task_status(uuid, public.task_status, text) from public, anon;
revoke execute on function public.add_task_comment(uuid, text) from public, anon;
revoke execute on function public.escalate_task(uuid, text) from public, anon;
revoke execute on function public.reassign_task(uuid, uuid, text) from public, anon;
revoke execute on function public.take_over_task(uuid, text) from public, anon;
revoke execute on function public.add_task_attachment(uuid, text, text, bigint) from public, anon;
revoke execute on function public.can_approve_task(uuid) from public, anon;
grant execute on function public.can_approve_task(uuid) to authenticated;
