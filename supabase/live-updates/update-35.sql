-- Staff Portal · © cmeproject. All rights reserved.
-- Update 35: time-based alerts for built features ("under target at 6 pm",
-- "nothing entered by 10 am"), checked every hour. They start switched off.
-- Run update 29 first. Safe to run again.
begin;
--
-- Time-based alerts for built features (cmeprojects). Checked every hour:
--   total_under_by  by a set time, a client's daily total is still under
--                   their target (e.g. under 1,500 ml at 6 pm)
--   no_entry_by     by a set time, nothing has been entered today
--                   (e.g. Fridge temps not done by 10 am)
-- They start switched off: the system admin sets the conditions and turns
-- each one on. Each runs once a day at most.

alter table public.custom_alerts drop constraint if exists custom_alerts_when_kind_check;
alter table public.custom_alerts add constraint custom_alerts_when_kind_check
  check (when_kind in ('any', 'choice', 'above', 'below', 'total_over', 'total_met', 'total_under_by', 'no_entry_by'));
alter table public.custom_alerts add column if not exists at_hour int check (at_hour between 0 and 23);

-- Which days a time alert has already run.
create table if not exists public.custom_alert_runs (
  alert_id uuid not null references public.custom_alerts (id) on delete cascade,
  day      date not null,
  primary key (alert_id, day)
);
alter table public.custom_alert_runs enable row level security;
revoke all on public.custom_alert_runs from anon, authenticated;

create or replace function public.run_feature_time_alerts()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tz text := coalesce((select value #>> '{}' from public.app_settings where key = 'region.timezone'), 'Australia/Melbourne');
  v_hour int := extract(hour from now() at time zone v_tz)::int;
  v_today date := (now() at time zone v_tz)::date;
  a public.custom_alerts;
  feat public.custom_features;
  v_unit text;
  v_lines text;
  v_title text;
  v_when text;
  v_user uuid;
  v_sent int := 0;
begin
  for a in
    select * from public.custom_alerts
     where active and when_kind in ('total_under_by', 'no_entry_by') and at_hour is not null and at_hour <= v_hour
  loop
    select * into feat from public.custom_features where id = a.feature_id;
    continue when not (feat.status = 'published' and feat.enabled);
    insert into public.custom_alert_runs (alert_id, day) values (a.id, v_today) on conflict do nothing;
    continue when not found;
    v_when := to_char(make_time(a.at_hour, 0, 0), 'FMHH12 am');
    v_lines := null;

    if a.when_kind = 'no_entry_by' then
      continue when exists (select 1 from public.custom_entries e
                             where e.feature_id = feat.id and (e.created_at at time zone v_tz)::date = v_today);
      v_title := format('%s: nothing entered yet today (%s)', feat.name, v_when);
      v_lines := 'No one has filled it in today.';
    else
      continue when feat.total_field is null;
      select unit into v_unit from public.custom_fields where id = feat.total_field;
      -- Clients with a target (their own, or the one for everyone) who are under it.
      select string_agg(format('%s: %s of %s%s', c.name, trim(to_char(t.total, 'FM999G999G990')), trim(to_char(t.target, 'FM999G999G990')),
                               case when coalesce(v_unit, '') <> '' then ' ' || v_unit else '' end), E'\n' order by c.name)
        into v_lines
        from public.car_clients c
        cross join lateral (
          select coalesce((select target from public.custom_client_targets where feature_id = feat.id and client_id = c.id), feat.default_target) target,
                 coalesce((select sum((e.data ->> feat.total_field::text)::numeric) from public.custom_entries e
                            where e.feature_id = feat.id and e.client_id = c.id
                              and jsonb_typeof(e.data -> feat.total_field::text) = 'number'
                              and (e.created_at at time zone v_tz)::date = v_today), 0) total
        ) t
       where c.active and t.target is not null and t.total < t.target;
      continue when v_lines is null;
      v_title := format('%s: under target at %s', feat.name, v_when);
    end if;

    v_title := coalesce(nullif(trim(replace(a.message, '{feature}', feat.name)), ''), v_title);
    for v_user in
      select p.id from public.profiles p
       where p.active and (p.role = any (a.notify_roles) or p.id = any (a.notify_people))
    loop
      if a.by_bell then
        insert into public.notifications (user_id, kind, title, body, href)
        values (v_user, 'feature_alert', left(v_title, 200), v_lines, '/reports/f/' || feat.slug || '?report=daily&range=today');
      end if;
      if a.by_email and public.feature_enabled('email_notifications') then
        insert into public.email_outbox (to_user, template, data)
        values (v_user, 'notice', jsonb_build_object('title', left(v_title, 200), 'body', v_lines, 'href', '/reports/f/' || feat.slug || '?report=daily&range=today'));
      end if;
      v_sent := v_sent + 1;
    end loop;
  end loop;
  return jsonb_build_object('time_alerts_sent', v_sent);
end;
$$;
revoke execute on function public.run_feature_time_alerts() from public, anon, authenticated;
grant execute on function public.run_feature_time_alerts() to service_role;

-- Runs after an entry is saved or fixed: tells people for each matching alert
-- (time-based alerts are checked by the hourly timer instead).
create or replace function public.fire_custom_alerts()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  feat public.custom_features;
  a public.custom_alerts;
  v_fixed boolean := tg_op = 'UPDATE';
  v_answer text;
  v_num numeric;
  v_target numeric;
  v_before numeric;
  v_after numeric;
  v_unit text;
  v_staff text;
  v_title text;
  v_body text;
  v_user uuid;
  v_detail text;
begin
  if v_fixed and new.data is not distinct from old.data then
    return new;
  end if;
  select * into feat from public.custom_features where id = new.feature_id;
  if not (feat.status = 'published' and feat.enabled) then
    return new;
  end if;
  select coalesce(nullif(full_name, ''), email) into v_staff from public.profiles where id = new.created_by;
  select unit into v_unit from public.custom_fields where id = feat.total_field;

  for a in select * from public.custom_alerts where feature_id = new.feature_id and active and (not v_fixed or on_fix)
                 and when_kind not in ('total_under_by', 'no_entry_by') loop
    v_detail := '';
    v_answer := case when a.field_id is null then null
                     when jsonb_typeof(new.data -> a.field_id::text) = 'array'
                       then (select string_agg(x, ', ') from jsonb_array_elements_text(new.data -> a.field_id::text) x)
                     else new.data ->> a.field_id::text end;

    if a.when_kind = 'choice' then
      if v_answer is null or not (lower(v_answer) = lower(a.match_text)
             or (jsonb_typeof(new.data -> a.field_id::text) = 'array'
                 and exists (select 1 from jsonb_array_elements_text(new.data -> a.field_id::text) x where lower(x) = lower(a.match_text)))) then
        continue;
      end if;
      v_detail := format('%s: %s', (select label from public.custom_fields where id = a.field_id), a.match_text);
    elsif a.when_kind in ('above', 'below') then
      begin
        v_num := v_answer::numeric;
      exception when others then
        continue;
      end;
      if v_num is null or a.limit_value is null
         or (a.when_kind = 'above' and v_num <= a.limit_value)
         or (a.when_kind = 'below' and v_num >= a.limit_value) then
        continue;
      end if;
      select format('%s: %s%s', label, rtrim(to_char(v_num, 'FM999G999G990D##'), '.'), case when unit <> '' then ' ' || unit else '' end)
        into v_detail from public.custom_fields where id = a.field_id;
    elsif a.when_kind in ('total_over', 'total_met') then
      if new.client_id is null or feat.total_field is null then
        continue;
      end if;
      v_target := coalesce((select target from public.custom_client_targets where feature_id = feat.id and client_id = new.client_id), feat.default_target);
      if v_target is null then
        continue;
      end if;
      v_after := public.custom_day_total(new, true);
      v_before := case when v_fixed then v_after - coalesce((new.data ->> feat.total_field::text)::numeric, 0)
                                               + coalesce((old.data ->> feat.total_field::text)::numeric, 0)
                       else public.custom_day_total(new, false) end;
      -- Only when the total crosses the line, so it's one alert a day.
      if (a.when_kind = 'total_over' and not (v_after > v_target and v_before <= v_target))
         or (a.when_kind = 'total_met' and not (v_after >= v_target and v_before < v_target)) then
        continue;
      end if;
      v_detail := format('%s is at %s of %s%s today', new.client_name, trim(to_char(v_after, 'FM999G999G990')),
                         trim(to_char(v_target, 'FM999G999G990')), case when v_unit <> '' then ' ' || v_unit else '' end);
    end if;

    v_title := coalesce(nullif(trim(replace(replace(replace(a.message, '{client}', new.client_name), '{staff}', v_staff), '{feature}', feat.name)), ''),
                        format('%s: %s', feat.name, coalesce(nullif(a.name, ''), case when a.when_kind = 'any' then 'new entry' else v_detail end)));
    v_body := concat_ws(' · ',
                        nullif(v_detail, ''),
                        nullif(case when a.when_kind in ('total_over', 'total_met') then '' else new.client_name end, ''),
                        format('%s by %s', case when v_fixed then 'Fixed' else 'Entered' end, v_staff));

    for v_user in
      select p.id from public.profiles p
       where p.active and p.id <> coalesce(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
         and (p.role = any (a.notify_roles)
              or p.id = any (a.notify_people)
              or (a.notify_leader and exists (select 1 from public.team_leaders l join public.team_members m on m.team_id = l.team_id
                                               where m.user_id = new.created_by and l.user_id = p.id)))
    loop
      if a.by_bell then
        insert into public.notifications (user_id, kind, title, body, href)
        values (v_user, 'feature_alert', left(v_title, 200), v_body, '/f/' || feat.slug);
      end if;
      if a.by_email and public.feature_enabled('email_notifications') then
        insert into public.email_outbox (to_user, template, data)
        values (v_user, 'notice', jsonb_build_object('title', left(v_title, 200), 'body', v_body, 'href', '/f/' || feat.slug));
      end if;
    end loop;
  end loop;
  return new;
end;
$$;

commit;
