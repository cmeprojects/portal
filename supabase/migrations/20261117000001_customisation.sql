-- Staff Portal · © cmeproject. All rights reserved.
--
-- More things the system admin can set without a developer: the logo
-- (uploaded), a support contact, an announcement banner, a note in the
-- welcome invite, the time of the managers' morning summary, who sees
-- Reports, and the Attachments, Auto-escalation and Reports switches.

insert into public.app_settings (key, value, label, description, is_public) values
  ('brand.support_contact', '""', 'Support contact',
   'Shown on the sign-in and two-factor pages, for example "Need help? Call the office on 03 9000 0000". Leave blank to hide.', true),
  ('brand.announcement', '""', 'Announcement banner',
   'A short message at the top of every page for all staff. Leave blank to hide.', false),
  ('people.invite_message', '""', 'Message in the welcome invite',
   'An extra note in the welcome email, for example who to call on their first day. Leave blank to leave it out.', false),
  ('tasks.summary_hour', '7', 'Morning summary time (hour, 24-hour clock)',
   'When the managers'' weekday summary of overdue tasks is sent, for example 7 for 7 am.', false),
  ('reports.roles', '["manager"]', 'Who can see Reports',
   'Besides the system admin. Team leaders see reports for the tasks of their own team.', false)
on conflict (key) do nothing;

update public.features set description = 'Escalate tasks to managers automatically when they''re overdue for the number of days set on Due dates (SLA).'
 where key = 'auto_escalation';
update public.features set description = 'Photos and files on tasks.' where key = 'attachments';
update public.features set description = 'The Reports page, with Excel downloads.' where key = 'reports';

-- No files on tasks while Attachments is switched off.
create or replace function public.add_task_attachment(p_task_id uuid, p_path text, p_name text, p_size bigint default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.feature_enabled('attachments') then
    raise exception 'Attachments are switched off';
  end if;
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

create or replace function public.run_due_alerts(p_now timestamptz default now())
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
  v_summary_hour int := coalesce((select (value #>> '{}')::int from public.app_settings where key = 'tasks.summary_hour'), 7);
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
    if v_escalate > 0 and v_late >= v_escalate and public.feature_enabled('auto_escalation') then
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
  if v_summary and not v_weekend and extract(hour from v_now) >= v_summary_hour and public.feature_enabled('email_notifications') then
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
grant execute on function public.run_due_alerts(timestamptz) to service_role;

-- Logos: a public bucket (the sign-in page and emails show them); only the
-- system admin uploads.
do $storage$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values ('branding', 'branding', true, 2097152, array['image/png', 'image/jpeg', 'image/svg+xml', 'image/webp'])
  on conflict (id) do nothing;
  create policy "system admin uploads logos" on storage.objects
    for insert to authenticated with check (bucket_id = 'branding' and public.is_system_admin());
end;
$storage$;
