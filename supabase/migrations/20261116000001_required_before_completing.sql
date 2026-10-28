-- Staff Portal · © cmeproject. All rights reserved.
--
-- Required register fields are filled in before a task is completed (or sent
-- for approval), not necessarily when it's created: the person reporting it
-- often doesn't know yet. The system admin can change this so they're needed
-- when the task is created instead. A register's outcome box (for example
-- "Risk reduction strategies") can also be needed before completing.

insert into public.app_settings (key, value, label, description, is_public) values
  ('tasks.required_fields_when', '"complete"', 'When required fields must be filled in',
   'Before completing (or sending for approval), or when the task is created and assigned.', false)
on conflict (key) do nothing;

alter table public.registries add column outcome_required boolean not null default false;
update public.registries set outcome_required = true where kind = 'tasks' and show_outcome and not is_default;

-- Risk: the consequence and how well the controls work are part of the record.
update public.registry_fields f set required = true
  from public.registries r
 where r.id = f.registry_id and r.prefix = 'RSK' and f.key in ('consequence', 'effectiveness');

create or replace function public.clean_details(p_registry_id uuid, p_details jsonb, p_existing jsonb default '{}'::jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  f public.registry_fields;
  v jsonb;
  out jsonb := '{}'::jsonb;
  item jsonb;
  v_check_required boolean;
begin
  p_details := coalesce(p_details, '{}'::jsonb);
  -- For tasks, required fields are usually checked before completing (see
  -- task_missing_fields); records always need them when saved.
  v_check_required := (select kind from public.registries where id = p_registry_id) <> 'tasks'
                      or (select value #>> '{}' from public.app_settings where key = 'tasks.required_fields_when') = 'create';

  for f in select * from public.registry_fields where registry_id = p_registry_id order by sort_order loop
    if not f.active then
      if p_existing ? f.key then
        out := out || jsonb_build_object(f.key, p_existing -> f.key);
      end if;
      continue;
    end if;

    v := p_details -> f.key;
    if v is null or v = 'null'::jsonb or v = '""'::jsonb or v = '[]'::jsonb then
      if f.required and v_check_required then
        raise exception '% is required', f.label;
      end if;
      continue;
    end if;

    case f.type
      when 'text', 'long_text' then
        if jsonb_typeof(v) <> 'string' then raise exception '% must be text', f.label; end if;
        if length(v #>> '{}') > 5000 then raise exception '% is too long', f.label; end if;
      when 'number', 'money' then
        if jsonb_typeof(v) <> 'number' then raise exception '% must be a number', f.label; end if;
      when 'date' then
        if jsonb_typeof(v) <> 'string' or (v #>> '{}') !~ '^\d{4}-\d{2}-\d{2}$' then
          raise exception '% must be a date', f.label;
        end if;
        perform (v #>> '{}')::date;
      when 'yes_no' then
        if jsonb_typeof(v) <> 'boolean' then raise exception '% must be yes or no', f.label; end if;
      when 'choice' then
        if jsonb_typeof(v) <> 'string' or not (f.options ? (v #>> '{}')) then
          raise exception 'Choose one of the options for %', f.label;
        end if;
      when 'multi_choice' then
        if jsonb_typeof(v) <> 'array' then raise exception 'Choose options for %', f.label; end if;
        for item in select * from jsonb_array_elements(v) loop
          if jsonb_typeof(item) <> 'string' or not (f.options ? (item #>> '{}')) then
            raise exception 'Choose from the options for %', f.label;
          end if;
        end loop;
      when 'person' then
        if jsonb_typeof(v) <> 'string' or not exists (
          select 1 from public.profiles where id::text = (v #>> '{}')) then
          raise exception 'Choose a person for %', f.label;
        end if;
      when 'asset' then
        if jsonb_typeof(v) <> 'string' or not exists (
          select 1 from public.records r join public.registries g on g.id = r.registry_id
           where r.id::text = (v #>> '{}') and g.kind = 'records') then
          raise exception 'Choose an item for %', f.label;
        end if;
    end case;

    out := out || jsonb_build_object(f.key, v);
  end loop;

  return out;
end;
$$;

-- What still needs filling in before a task can be completed.
create function public.task_missing_fields(p_task_id uuid)
returns text[]
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(array_agg(label order by sort_order), '{}')
    from (
      select f.label, f.sort_order
        from public.tasks t
        join public.registry_fields f on f.registry_id = t.registry_id and f.active and f.required
       where t.id = p_task_id and t.parent_task_id is null
         and (t.details -> f.key is null or t.details -> f.key in ('null'::jsonb, '""'::jsonb, '[]'::jsonb))
      union all
      select r.outcome_label, 100000
        from public.tasks t
        join public.registries r on r.id = t.registry_id
       where t.id = p_task_id and t.parent_task_id is null
         and r.show_outcome and r.outcome_required and coalesce(trim(t.outcome), '') = ''
    ) m
$$;

revoke execute on function public.task_missing_fields(uuid) from public, anon;
grant execute on function public.task_missing_fields(uuid) to authenticated;

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
