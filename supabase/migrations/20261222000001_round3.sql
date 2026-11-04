-- Staff Portal · © cmeproject. All rights reserved.
--
-- Round 3 (cmeprojects):
--   1. The system admin is never affected by feature switches (except
--      two-factor login, emails and auto-escalation, which apply to everyone).
--   2. A new access level for later: External contractor (allied health),
--      with no permissions yet.
--   3. Each register can say who may create tasks in it.
--   4. The weekly mileage report: which day, from what time, and what period.
--   5. A manager can share areas the system admin gave them with staff admins.
--   6. With no active staff admin, managers look after Compliance.

-- ---------------------------------------------------------------------------
-- 2. External contractor (allied health): a new access level, no permissions yet
-- ---------------------------------------------------------------------------

alter type public.app_role add value if not exists 'external';

-- ---------------------------------------------------------------------------
-- 1. Feature switches never lock the system admin out
-- ---------------------------------------------------------------------------

-- What's actually switched on (for everyone, the system admin included).
create or replace function public.feature_live(p_key text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((
    select f.enabled and f.included
       and (f.parent is null or coalesce((select p.enabled and p.included from public.features p where p.key = f.parent), false))
      from public.features f
     where f.key = p_key
  ), false)
$$;

-- Whether the signed-in person can use a feature: the system admin always
-- can (so switching something off never locks them out), except for
-- two-factor login, emails and auto-escalation.
create or replace function public.feature_enabled(p_key text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when p_key in ('two_factor', 'email_notifications', 'auto_escalation') then public.feature_live(p_key)
    else public.feature_live(p_key) or public.is_system_admin()
  end
$$;

-- These follow what's really switched on, whoever is signed in.
create or replace function public.compliance_applies(p_item public.compliance_items, p_role public.app_role, p_teams uuid[])
returns boolean
language sql
stable
set search_path = ''
as $$
  select p_item.active
     and public.feature_live(case p_item.kind when 'form' then 'compliance_forms' else 'compliance_' || p_item.kind end)
     and (p_item.kind <> 'form' or public.feature_live('forms'))
     and (cardinality(p_item.applies_roles) = 0 or p_role = any (p_item.applies_roles))
     and (cardinality(p_item.applies_teams) = 0 or p_item.applies_teams && coalesce(p_teams, '{}'))
$$;

create or replace function public.leads_user(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.feature_live('teams') and exists (
    select 1
      from public.team_leaders tl
      join public.team_members m on m.team_id = tl.team_id
     where tl.user_id = auth.uid()
       and m.user_id = p_user_id
  ) and public.has_role(array['team_leader', 'manager', 'system_admin']::public.app_role[])
$$;

create or replace function public.notification_on(p_code text, p_channel text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (public.notification_feature(p_code) is null or public.feature_live(public.notification_feature(p_code)))
     and coalesce(((select value from public.app_settings where key = 'notify.channels') -> p_code ->> p_channel)::boolean, true)
$$;

-- Emails: nothing goes out while Emails is off, whoever triggered it.
create or replace function public.filter_email()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.feature_live('email_notifications')
     or not public.notification_on(case when new.template = 'notice' then coalesce(new.data ->> 'kind', 'notice') else new.template end, 'email') then
    return null;
  end if;
  return new;
end;
$$;

create or replace function public.website_front_page()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.feature_live('assistant')
     and coalesce((select value = 'true'::jsonb from public.app_settings where key = 'website.front_page'), false)
$$;

-- External contractors have no permissions yet: they aren't "members".
create or replace function public.is_member()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.my_role() is not null and public.my_role()::text <> 'external' and public.mfa_ok()
$$;

-- ---------------------------------------------------------------------------
-- 3. Who may create tasks in each register (empty: as before)
-- ---------------------------------------------------------------------------

alter table public.registries add column if not exists create_roles text[] not null default '{}';

create or replace function public.limited_task_guard() returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_roles text[] := (select create_roles from public.registries where id = new.registry_id);
begin
  -- Only a person creating a task themselves (not a task made by another rule).
  if pg_trigger_depth() = 1 and new.created_by = auth.uid() and not public.is_system_admin() then
    if cardinality(coalesce(v_roles, '{}')) > 0 then
      -- The register's own list decides (its managers set it).
      if not (public.my_role()::text = any (v_roles))
         and not exists (select 1 from public.registry_managers rm where rm.registry_id = new.registry_id and rm.user_id = auth.uid()) then
        raise exception 'This register only takes new tasks from chosen roles' using errcode = '42501';
      end if;
    elsif public.my_role()::text in (select jsonb_array_elements_text(coalesce(
           (select value from public.app_settings where key = 'tasks.limited_roles'), '[]')))
       and not exists (select 1 from public.registries r where r.id = new.registry_id and r.is_default) then
      raise exception 'You can raise General tasks and questions only' using errcode = '42501';
    end if;
  end if;
  return new;
end $$;

-- ---------------------------------------------------------------------------
-- 4. The weekly mileage report: day, time and period
-- ---------------------------------------------------------------------------

insert into public.app_settings (key, value, label, description) values
  ('vehicles.weekly_day', '1', 'Weekly mileage report: which day', 'The day the report is sent.'),
  ('vehicles.weekly_hour', '7', 'Weekly mileage report: from what hour', 'The hour of the day (0 to 23) it''s sent, in your time zone.'),
  ('vehicles.weekly_period', '"last_7_days"', 'Weekly mileage report: what it covers', 'The days the report covers.')
on conflict (key) do nothing;

create or replace function public.run_car_alerts(p_now timestamptz default now())
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_wday int;
  v_whour int;
  v_period text;
  v_from date;
  v_to date;
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

  end if;

  -- The weekly mileage report (cmeprojects): on the chosen day, from the
  -- chosen hour, covering the chosen period.
  v_wday := coalesce((select (value #>> '{}')::int from public.app_settings where key = 'vehicles.weekly_day'), 1);
  v_whour := coalesce((select (value #>> '{}')::int from public.app_settings where key = 'vehicles.weekly_hour'), 0);
  v_period := coalesce((select value #>> '{}' from public.app_settings where key = 'vehicles.weekly_period'), 'last_7_days');
  v_from := case v_period
              when 'last_14_days' then v_today - 14
              when 'previous_week' then v_today - (extract(isodow from v_today)::int - 1) - 7
              when 'month_to_date' then date_trunc('month', v_today - 1)::date
              else v_today - 7
            end;
  v_to := case v_period when 'previous_week' then v_today - extract(isodow from v_today)::int else v_today - 1 end;
  if extract(isodow from v_today) = v_wday and v_hour >= v_whour then
    insert into public.daily_runs (job, day) values ('car_weekly', v_today) on conflict do nothing;
    if found and exists (select 1 from public.car_trips
                          where (started_at at time zone v_tz)::date between v_from and v_to) then
      -- Only the people chosen in Settings → Cars.
      for v_person in
        select p.id from public.profiles p
         where p.active
           and p.id::text in (select jsonb_array_elements_text(s.value) from public.app_settings s
                               where s.key = 'vehicles.weekly_recipients' and jsonb_typeof(s.value) = 'array')
      loop
        perform public.notify(v_person, 'car_weekly',
          format('Mileage report: %s to %s', to_char(v_from, 'FMDD Mon'), to_char(v_to, 'FMDD Mon YYYY')),
          'Car use and mileage, ready to download.',
          '/reports/cars?from=' || v_from::text || '&to=' || v_to::text, true);
        v_weekly := v_weekly + 1;
      end loop;
    end if;
  end if;

  return jsonb_build_object('car_reminders', v_reminders, 'cars_not_returned', v_told, 'car_notices', v_cars, 'car_weekly', v_weekly);
end;
$$;

-- ---------------------------------------------------------------------------
-- 5. Managers share their areas with staff admins
-- ---------------------------------------------------------------------------

create table if not exists public.delegation_shares (
  area      text not null check (area in ('branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'website', 'registers')),
  user_id   uuid not null references public.profiles (id) on delete cascade,
  shared_by uuid not null references public.profiles (id) on delete cascade,
  shared_at timestamptz not null default now(),
  primary key (area, user_id)
);

alter table public.delegation_shares enable row level security;
drop policy if exists "members read shares" on public.delegation_shares;
create policy "members read shares" on public.delegation_shares
  for select to authenticated using (public.is_member());
revoke insert, update, delete, truncate on public.delegation_shares from anon, authenticated;

-- Can the signed-in person look after this area? The system admin; people
-- the Delegation tab names; and staff admins a delegated manager shared it with.
create or replace function public.can_admin_area(p_area text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.mfa_ok() and (
    public.is_system_admin()
    or (p_area is not null and exists (
      select 1
        from public.delegation_rules r
        join public.profiles p on p.id = auth.uid()
       where r.area = p_area
         and p.active
         and ((r.mode = 'managers' and p.role = 'manager')
              or (r.mode = 'selected' and p.id = any (r.people) and p.role in ('manager', 'staff_admin')))
    ))
    or (p_area is not null and exists (
      select 1
        from public.delegation_shares s
        join public.profiles me on me.id = auth.uid()
        join public.profiles sp on sp.id = s.shared_by
        join public.delegation_rules r on r.area = s.area
       where s.area = p_area and s.user_id = auth.uid()
         and me.active and me.role = 'staff_admin'
         and sp.active and sp.role = 'manager'
         and (r.mode = 'managers' or (r.mode = 'selected' and sp.id = any (r.people)))
    ))
  )
$$;

-- A delegated manager shares (or stops sharing) an area with a staff admin.
create or replace function public.share_area(p_area text, p_user uuid, p_on boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.my_role() <> 'manager' or not public.can_admin_area(p_area) then
    raise exception 'Only a manager who looks after this area can share it.';
  end if;
  if p_area not in ('branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'website', 'registers') then
    raise exception 'This area can''t be shared.';
  end if;
  if p_on then
    if not exists (select 1 from public.profiles where id = p_user and active and role = 'staff_admin') then
      raise exception 'Areas can only be shared with active staff admins.';
    end if;
    insert into public.delegation_shares (area, user_id, shared_by) values (p_area, p_user, auth.uid())
    on conflict (area, user_id) do update set shared_by = excluded.shared_by, shared_at = now();
  else
    delete from public.delegation_shares where area = p_area and user_id = p_user;
  end if;
  perform public.write_audit(case when p_on then 'area_shared' else 'area_unshared' end, 'profile', p_user::text, jsonb_build_object('area', p_area));
end;
$$;

revoke execute on function public.share_area(text, uuid, boolean) from public, anon;
grant execute on function public.share_area(text, uuid, boolean) to authenticated;
revoke execute on function public.feature_live(text) from public, anon;
grant execute on function public.feature_live(text) to authenticated;

-- ---------------------------------------------------------------------------
-- 6. No active staff admin: managers look after Compliance
-- ---------------------------------------------------------------------------

create or replace function public.can_manage_compliance()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.mfa_ok() and (public.my_role() = 'system_admin'
         or public.my_role() = any (public.setting_roles('compliance.manager_roles'))
         or (public.my_role() = 'manager'
             and not exists (select 1 from public.profiles where role = 'staff_admin' and active)))
$$;
