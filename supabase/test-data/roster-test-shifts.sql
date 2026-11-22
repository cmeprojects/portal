-- Staff Portal · © cmeproject. All rights reserved.
-- TEST DATA (Dev only; cmeprojects, 22 Nov 2026). Not a live update; not for a customer's database.
-- Adds roster test shifts so Timesheets and Billing can be tried out:
--   * the last 7 days: finished shifts, published, each with a worker. Most have a
--     timesheet the worker "sent" (status: waiting for approval, NOT approved), with
--     times a few minutes off the roster, plus the worker's service record. A few
--     have no timesheet yet ("not sent").
--   * the coming week (next Monday to Sunday): rostered shifts, mostly published,
--     some drafts.
-- Uses existing active clients with an active approved service and an approved
-- location, and existing active support workers. Workers are NOT notified (the
-- shifts are marked as already told). Every test shift has a reference starting
-- "TEST-" so it can be found and removed with roster-test-shifts-undo.sql.
-- Safe to run again: a slot that already has a test shift is skipped. Shifts the
-- portal refuses (leave, an overlapping shift, a program not active that day) are
-- skipped and counted. Each service record is saved as if the shift's worker wrote
-- it in the app (the portal records the worker from who is signed in). Shows a
-- summary at the end.
begin;
do $$
declare
  v_today date := (now() at time zone 'Australia/Sydney')::date;
  v_next_monday date := v_today + (8 - extract(isodow from v_today)::int);
  d date;
  i integer;
  v_made integer := 0;
  v_skipped integer := 0;
  v_refused integer := 0;
  v_ts integer := 0;
  v_ref text;
  v_id uuid;
  v_start timestamptz;
  v_hours numeric;
  v_type text;
  s record;
  w uuid[];
  n_w integer;
begin
  select array_agg(id order by full_name, email) into w
    from (select p.id, p.full_name, p.email from public.profiles p
           where p.active and p.role = 'support_worker' order by p.full_name, p.email limit 6) x;
  n_w := coalesce(array_length(w, 1), 0);
  if n_w = 0 then
    raise exception 'No active support workers to roster.';
  end if;
  for d in select generate_series(v_today - 7, v_today - 1, interval '1 day')::date
           union all select generate_series(v_next_monday, v_next_monday + 6, interval '1 day')::date
           order by 1 loop
    i := 0;
    for s in select sv.id, sv.client_id, sv.location_id, coalesce(sv.shift_types[1], c.shift_types[1]) as stype, sv.start_date, sv.end_date
               from public.client_services sv
               join public.client_locations l on l.id = sv.location_id and l.approved
               join public.car_clients cl on cl.id = sv.client_id and cl.status = 'active'
               left join public.service_catalogue c on c.id = sv.catalogue_id
              where sv.status = 'active' and coalesce(sv.shift_types[1], c.shift_types[1]) is not null
                and sv.start_date <= d and (sv.end_date is null or sv.end_date >= d)
              order by sv.created_at, sv.id
              limit 8 loop
      -- Weekends: only every other service.
      if extract(isodow from d) >= 6 and i % 2 = 1 then i := i + 1; continue; end if;
      v_ref := 'TEST-' || to_char(d, 'YYYYMMDD') || '-' || left(s.id::text, 8);
      if exists (select 1 from public.shifts where ref = v_ref) then
        v_skipped := v_skipped + 1; i := i + 1; continue;
      end if;
      -- A different worker per service; each worker's shifts that day don't overlap.
      v_hours := case i % 3 when 0 then 2 when 1 then 1.5 else 3 end;
      v_start := ((d + time '08:00') + make_interval(mins => (i / n_w) * 210)) at time zone 'Australia/Sydney';
      v_type := s.stype;
      begin
        insert into public.shifts (worker_id, client_id, service_id, location_id, starts_at, ends_at, break_minutes, status, shift_type, ref, notify_worker, notified_at)
        values (w[(i % n_w) + 1], s.client_id, s.id, s.location_id, v_start, v_start + make_interval(mins => (v_hours * 60)::int), 0,
                case when d >= v_next_monday and i % 4 = 3 then 'draft' else 'published' end, v_type, v_ref, false, now())
        returning id into v_id;
        -- Finished shifts: most have a timesheet sent (waiting for approval) and a service record.
        if d < v_today and i % 5 <> 4 then
          insert into public.shift_timesheets (shift_id, actual_start, actual_end, break_minutes, status, note)
          values (v_id, v_start + make_interval(mins => (i % 3) * 5 - 5), v_start + make_interval(mins => (v_hours * 60)::int + (i % 4) * 5), 0, 'submitted',
                  case when i % 3 = 2 then 'Stayed a little longer to finish' else '' end);
          -- The service record is written as the shift's worker would write it in the app.
          perform set_config('request.jwt.claims', json_build_object('sub', w[(i % n_w) + 1], 'role', 'authenticated')::text, true);
          insert into public.shift_service_records (shift_id, worker_id, client_id, delivered, client_wellbeing)
          values (v_id, w[(i % n_w) + 1], s.client_id, 'Support delivered as planned (test data).', 'settled');
          perform set_config('request.jwt.claims', '', true);
          v_ts := v_ts + 1;
        end if;
        v_made := v_made + 1;
      exception when others then
        perform set_config('request.jwt.claims', '', true);
        v_refused := v_refused + 1;
      end;
      i := i + 1;
    end loop;
  end loop;
  raise notice 'Test shifts made: %, timesheets sent: %, already there: %, refused by the portal''s rules: %', v_made, v_ts, v_skipped, v_refused;
end $$;
commit;

-- Summary.
select case when s.starts_at < now() then 'Last 7 days (finished)' else 'Coming week' end as period,
       s.status, count(*) as shifts,
       count(t.shift_id) filter (where t.status = 'submitted') as timesheets_waiting_for_approval,
       count(*) filter (where s.starts_at < now() and t.shift_id is null) as timesheets_not_sent
  from public.shifts s left join public.shift_timesheets t on t.shift_id = s.id
 where s.ref like 'TEST-%'
 group by 1, 2 order by 1 desc, 2;
