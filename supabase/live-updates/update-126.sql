-- Staff Portal · © cmeproject. All rights reserved.
-- Update 126 (AUD-016): the initial job titles under their Function Groups.
-- Payroll & Rostering becomes Payroll Officer (same access) plus a new
-- Rostering Officer. Staff with no job title get one where there's a single
-- fit. Nobody's access changes. Safe to run again. Undo: undo-126.sql.
begin;

update public.job_titles set name = 'Payroll Officer' where name = 'Payroll & Rostering'
   and not exists (select 1 from public.job_titles where lower(name) = 'payroll officer');

do $$
declare
  r record;
  v_id uuid;
begin
  for r in
    select * from (values
      ('Client Services Coordinator', 'support_worker'::public.app_role, 'care_coordination', 3, 'Coordinates client services: administrative client details, agreements and follow-ups.'),
      ('Staff Administrator', 'staff_admin'::public.app_role, 'hr_workforce', 6, 'Staff records, onboarding, qualifications and workforce compliance.'),
      ('Rostering Officer', 'support_worker'::public.app_role, 'hr_workforce', 7, 'Builds and publishes rosters, worker availability and timesheet checks.'),
      ('Team Leader', 'team_leader'::public.app_role, 'service_delivery', 10, 'Leads a team: their team''s roster, clients, tasks and reports.'),
      ('Manager', 'manager'::public.app_role, 'management_admin', 20, 'Management overview within the authority given.'),
      ('Psychologist', 'external'::public.app_role, 'allied_health', 40, 'Psychological assessment and therapy for the clients they are given.'),
      ('Behaviour Support Practitioner', 'external'::public.app_role, 'allied_health', 41, 'Behaviour assessments and behaviour support plans for the clients they are given.'),
      ('Speech Pathologist', 'external'::public.app_role, 'allied_health', 42, 'Speech and communication assessments and therapy for the clients they are given.'),
      ('Occupational Therapist', 'external'::public.app_role, 'allied_health', 43, 'Functional assessments, recommendations and OT plans for the clients they are given.')
    ) as t(name, level, grp, sort_order, description)
  loop
    select id into v_id from public.job_titles where lower(name) = lower(r.name);
    if v_id is null then
      insert into public.job_titles (name, access_level, description, sort_order)
      values (r.name, r.level, r.description, r.sort_order) returning id into v_id;
    elsif (select access_level from public.job_titles where id = v_id) <> r.level then
      continue; -- that name is already used at another level: leave it to the owner
    else
      update public.job_titles set active = true where id = v_id and not active;
    end if;
    insert into public.job_title_functions (job_title_id, function_group_id)
    select v_id, g.id from public.function_groups g where g.key = r.grp and g.active
    on conflict do nothing;
  end loop;

  -- Payroll Officer sits under Finance & Accounts only (Payroll & Rostering was also under HR & Workforce).
  delete from public.job_title_functions f
   using public.job_titles j, public.function_groups g
   where f.job_title_id = j.id and f.function_group_id = g.id and j.name = 'Payroll Officer' and g.key = 'hr_workforce'
     and exists (select 1 from public.job_title_functions f2 join public.function_groups g2 on g2.id = f2.function_group_id
                  where f2.job_title_id = j.id and g2.key = 'finance_accounts');

  -- Rostering Officer: the roster and the client views it needs (not funding).
  v_id := (select id from public.job_titles where name = 'Rostering Officer' and access_level = 'support_worker');
  if v_id is not null and not exists (select 1 from public.access_baselines where job_title_id = v_id and revoked_at is null) then
    insert into public.access_baselines (job_title_id, module_id, actions, scope, note)
    select v_id, x.m, x.a, 'all', 'Rostering default: Rostering Officer'
      from (values ('ops.roster', '{view,edit}'::text[]), ('clients.list', '{view}'::text[]), ('clients.alerts', '{view}'::text[]), ('clients.locations', '{view}'::text[]), ('clients.services', '{view}'::text[])) as x(m, a)
     where exists (select 1 from public.app_modules where id = x.m);
  end if;

  -- No job title yet: give the level's single fitting one.
  update public.profiles set job_title_id = (select id from public.job_titles where name = 'Team Leader' and access_level = 'team_leader') where role = 'team_leader' and job_title_id is null;
  update public.profiles set job_title_id = (select id from public.job_titles where name = 'Manager' and access_level = 'manager') where role = 'manager' and job_title_id is null;
  update public.profiles set job_title_id = (select id from public.job_titles where name = 'Staff Administrator' and access_level = 'staff_admin') where role = 'staff_admin' and job_title_id is null;
  update public.invitations set job_title_id = (select id from public.job_titles where name = 'Team Leader' and access_level = 'team_leader') where role = 'team_leader' and job_title_id is null;
  update public.invitations set job_title_id = (select id from public.job_titles where name = 'Manager' and access_level = 'manager') where role = 'manager' and job_title_id is null;
  update public.invitations set job_title_id = (select id from public.job_titles where name = 'Staff Administrator' and access_level = 'staff_admin') where role = 'staff_admin' and job_title_id is null;
end $$;
-- Roster request notices go to job titles with roster edit access, not to a role name.
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
commit;
