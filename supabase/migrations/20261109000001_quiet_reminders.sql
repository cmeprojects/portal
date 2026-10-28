-- Staff Portal · © cmeproject. All rights reserved.
--
-- No email spam: reminders and "due today" go to the bell only. Emails are
-- sent only when a task is overdue or escalated (and the managers' summary).

create or replace function public.send_due_alert(p_task_id uuid, p_user_id uuid, p_step text, p_due date)
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
  if v_id is not null and p_step in ('overdue', 'escalated') then
    perform public.queue_task_email('task_' || p_step, p_task_id, p_user_id);
  end if;
end;
$$;

revoke execute on function public.send_due_alert(uuid, uuid, text, date) from public, anon, authenticated;
