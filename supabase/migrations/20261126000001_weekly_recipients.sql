-- Staff Portal · © cmeproject. All rights reserved.
--
-- Weekly mileage report recipients (cmeprojects): the system admin ticks which
-- managers get Monday's report (bell, and email once emails are set up).
-- To start with, every current manager is ticked.

insert into public.app_settings (key, value, label, description, is_public)
select 'vehicles.weekly_recipients',
       coalesce((select jsonb_agg(id order by full_name) from public.profiles where active and role = 'manager'), '[]'::jsonb),
       'Who gets the weekly mileage report',
       'Every Monday morning: last week''s car use and mileage, by bell and email. Tick the managers who should get it.',
       false
on conflict (key) do nothing;

create or replace function public.run_car_alerts(p_now timestamptz default now())
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tz text := coalesce((select value #>> '{}' from public.app_settings where key = 'region.timezone'), 'Australia/Melbourne');
  v_now timestamp := p_now at time zone v_tz;
  v_today date := v_now::date;
  v_hour int := extract(hour from v_now);
  v_remind_hour int := public.car_setting('vehicles.reminder_hour', '20')::int;
  v_morning int := coalesce((select (value #>> '{}')::int from public.app_settings where key = 'tasks.summary_hour'), 7);
  t record;
  c record;
  v_person uuid;
  v_reminders int := 0;
  v_told int := 0;
  v_cars int := 0;
  v_weekly int := 0;
begin
  if not public.feature_enabled('vehicles') then
    return jsonb_build_object('cars', 'off');
  end if;

  -- The driver, in the evening, if the car is still out.
  if v_hour >= v_remind_hour then
    for t in
      select tr.id, tr.driver_id, ca.name from public.car_trips tr join public.cars ca on ca.id = tr.car_id
       where tr.returned_at is null and tr.reminded_at is null
    loop
      perform public.notify(t.driver_id, 'car_still_out', format('You still have the %s out', t.name),
        'Return it in the Cars app when you''ve finished with it.', '/cars');
      update public.car_trips set reminded_at = p_now where id = t.id;
      v_reminders := v_reminders + 1;
    end loop;
  end if;

  -- Car managers, the next morning, for cars out since before today.
  if v_hour >= v_morning then
    for t in
      select tr.id, tr.driver_id, tr.started_at, ca.name, ca.rego,
             case when p.role = 'system_admin' then 'Admin' else coalesce(nullif(p.full_name, ''), p.email) end driver
        from public.car_trips tr
        join public.cars ca on ca.id = tr.car_id
        join public.profiles p on p.id = tr.driver_id
       where tr.returned_at is null and tr.managers_told_at is null
         and (tr.started_at at time zone v_tz)::date < v_today
    loop
      for v_person in select public.car_managers() loop
        continue when v_person = t.driver_id;
        perform public.notify(v_person, 'car_not_returned',
          format('%s (%s) hasn''t been returned', t.name, t.rego),
          format('%s took it on %s. You can return it for them on the Cars page.', t.driver,
                 to_char(t.started_at at time zone v_tz, 'Dy DD Mon, FMHH12:MI am')),
          '/cars/manage', true);
      end loop;
      update public.car_trips set managers_told_at = p_now where id = t.id;
      v_told := v_told + 1;
    end loop;

    -- Rego expiring within 30 days, and service coming up (by date or within 500 km).
    for c in
      select * from public.cars
       where active and rego_expires is not null and rego_expires <= v_today + 30
         and rego_alerted is distinct from rego_expires
    loop
      for v_person in select public.car_managers() loop
        perform public.notify(v_person, 'car_rego',
          format('Rego for %s (%s) %s %s', c.name, c.rego, case when c.rego_expires < v_today then 'expired on' else 'is due' end,
                 to_char(c.rego_expires, 'FMDD Mon YYYY')),
          'Update the date on the car once it''s renewed.', '/cars/manage', c.rego_expires < v_today);
      end loop;
      update public.cars set rego_alerted = c.rego_expires where id = c.id;
      v_cars := v_cars + 1;
    end loop;
    for c in
      select *, coalesce(service_due_date::text, '') || '/' || coalesce(service_due_km::text, '') as due_key
        from public.cars
       where active and ((service_due_date is not null and service_due_date <= v_today + 14)
                         or (service_due_km is not null and odometer >= service_due_km - 500))
         and service_alerted is distinct from (coalesce(service_due_date::text, '') || '/' || coalesce(service_due_km::text, ''))
    loop
      for v_person in select public.car_managers() loop
        perform public.notify(v_person, 'car_service', format('%s (%s) is due for a service', c.name, c.rego),
          concat_ws(' · ', case when c.service_due_date is not null then 'By ' || to_char(c.service_due_date, 'FMDD Mon YYYY') end,
                    case when c.service_due_km is not null then 'At ' || to_char(c.service_due_km, 'FM999,999,999') || ' km (now ' ||
                         to_char(c.odometer, 'FM999,999,999') || ' km)' end),
          '/cars/manage');
      end loop;
      update public.cars set service_alerted = c.due_key where id = c.id;
      v_cars := v_cars + 1;
    end loop;

    -- Monday: last week's mileage report is ready.
    if extract(isodow from v_today) = 1 then
      insert into public.daily_runs (job, day) values ('car_weekly', v_today) on conflict do nothing;
      if found and exists (select 1 from public.car_trips
                            where (started_at at time zone v_tz)::date between v_today - 7 and v_today - 1) then
        -- Only the people the system admin chose (System settings → Cars).
        for v_person in
          select p.id from public.profiles p
           where p.active
             and p.id::text in (select jsonb_array_elements_text(s.value) from public.app_settings s
                                 where s.key = 'vehicles.weekly_recipients' and jsonb_typeof(s.value) = 'array')
        loop
          perform public.notify(v_person, 'car_weekly',
            format('Mileage report: %s to %s', to_char(v_today - 7, 'FMDD Mon'), to_char(v_today - 1, 'FMDD Mon YYYY')),
            'Last week''s car use and mileage, ready to download.',
            '/reports/cars?from=' || (v_today - 7)::text || '&to=' || (v_today - 1)::text, true);
          v_weekly := v_weekly + 1;
        end loop;
      end if;
    end if;
  end if;

  return jsonb_build_object('car_reminders', v_reminders, 'cars_not_returned', v_told, 'car_notices', v_cars, 'car_weekly', v_weekly);
end;
$$;

revoke execute on function public.run_car_alerts(timestamptz) from public, anon, authenticated;
grant execute on function public.run_car_alerts(timestamptz) to service_role;
