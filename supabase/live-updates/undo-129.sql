-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 129: removes shift templates and puts the update 128 roster
-- notices back. Safe to run again.
begin;
CREATE OR REPLACE FUNCTION public.run_roster_alerts()
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  r record;
  v_new int := 0;
  v_tomorrow int := 0;
  v_requests int := 0;
  v_decided int := 0;
  v_queried int := 0;
  v_today date := public.local_today();
begin
  if not public.feature_live('rostering') then
    return jsonb_build_object('rostering', 'off');
  end if;
  for r in
    select s.id, s.worker_id, s.starts_at, s.ends_at, c.name as client
      from public.shifts s left join public.car_clients c on c.id = s.client_id
     where s.status = 'published' and s.worker_id is not null and s.notified_at is null and s.ends_at > now()
  loop
    perform public.notify(r.worker_id, 'shift_published',
      'Shift ' || to_char(r.starts_at at time zone 'Australia/Sydney', 'Dy DD Mon, HH24:MI') || '–' || to_char(r.ends_at at time zone 'Australia/Sydney', 'HH24:MI'),
      coalesce(r.client, 'See My shifts'), '/my-shifts', true);
    update public.shifts set notified_at = now() where id = r.id;
    v_new := v_new + 1;
  end loop;
  for r in
    select s.id, s.worker_id, s.starts_at, c.name as client
      from public.shifts s left join public.car_clients c on c.id = s.client_id
     where s.status = 'published' and s.worker_id is not null
       and (s.starts_at at time zone 'Australia/Sydney')::date = v_today + 1 and s.reminded_on is null
  loop
    perform public.notify(r.worker_id, 'shift_tomorrow',
      'Tomorrow: shift at ' || to_char(r.starts_at at time zone 'Australia/Sydney', 'HH24:MI'), coalesce(r.client, 'See My shifts'), '/my-shifts', false);
    update public.shifts set reminded_on = v_today where id = r.id;
    v_tomorrow := v_tomorrow + 1;
  end loop;
  -- New requests: to the people who roster (managers, staff admins, and job titles with roster edit access).
  for r in
    select q.id, q.kind, p.full_name, p.email from public.shift_change_requests q join public.profiles p on p.id = q.requested_by
     where q.status = 'pending' and q.roster_told_at is null
  loop
    perform public.notify(u.id, 'shift_request',
      coalesce(nullif(r.full_name, ''), r.email) || case when r.kind = 'swap' then ' asked to swap a shift' else ' can''t work a shift' end,
      'Shift change requests', '/roster?requests=1', false)
      from public.profiles u
     where u.active and (u.role in ('manager', 'staff_admin')
                         or u.job_title_id in (select b.job_title_id from public.access_baselines b
                                              where b.module_id = 'ops.roster' and b.revoked_at is null and b.job_title_id is not null
                                                and (b.actions = '{}' or 'edit' = any (b.actions))));
    update public.shift_change_requests set roster_told_at = now() where id = r.id;
    v_requests := v_requests + 1;
  end loop;
  for r in
    select q.id, q.requested_by, q.status from public.shift_change_requests q
     where q.status in ('approved', 'declined') and q.worker_told_at is null
  loop
    perform public.notify(r.requested_by, 'shift_request_decided', 'Your shift change request was ' || r.status, 'See My shifts', '/my-shifts', true);
    update public.shift_change_requests set worker_told_at = now() where id = r.id;
    v_decided := v_decided + 1;
  end loop;
  for r in
    select t.shift_id, t.worker_id from public.shift_timesheets t where t.status = 'queried' and t.told_at is null
  loop
    perform public.notify(r.worker_id, 'timesheet_queried', 'A timesheet needs another look', 'See My shifts', '/my-shifts', true);
    update public.shift_timesheets set told_at = now() where shift_id = r.shift_id;
    v_queried := v_queried + 1;
  end loop;
  return jsonb_build_object('shifts_notified', v_new, 'shift_reminders', v_tomorrow, 'requests_notified', v_requests, 'requests_decided', v_decided, 'timesheets_queried', v_queried);
end;
$function$;
revoke execute on function public.run_roster_alerts() from public, anon, authenticated;
grant execute on function public.run_roster_alerts() to service_role;
drop function if exists public.roster_people();
drop table if exists public.shift_templates;
commit;
