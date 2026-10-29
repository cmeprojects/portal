-- Staff Portal · © cmeproject. All rights reserved.
--
-- Company cars (cmeprojects): staff start a trip (car, purpose, client, start
-- odometer) and return it (end odometer). The driver is whoever is signed in,
-- and the times are recorded by the database. Starting and returning can be
-- undone for a few minutes; after that only a car manager can correct a trip,
-- with a reason, and the change log keeps both versions.
--
-- Car managers (managers by default) add cars, clients and purposes of use.
-- Reminders: the driver at night if a car is still out, car managers the next
-- morning, rego and service coming up, and a weekly mileage report.

-- ---------------------------------------------------------------------------
-- Switch, settings and who does what
-- ---------------------------------------------------------------------------

update public.features
   set label = 'Cars', description = 'Company cars: staff start and return trips, with mileage reports.', enabled = true
 where key = 'vehicles';

insert into public.app_settings (key, value, label, description, is_public) values
  ('vehicles.manager_roles', '["manager"]', 'Who manages cars',
   'Add and switch off cars, clients and purposes of use, and correct trips. The system admin always can.', false),
  ('vehicles.report_roles', '["manager"]', 'Who sees car reports',
   'The car use log and mileage reports, for all cars and staff. Everyone sees their own trips.', false),
  ('vehicles.client_field', '"optional"', 'Client on each trip',
   'Off hides the client list, Optional lets staff leave it blank, Required makes them choose one.', false),
  ('vehicles.odo_photo', '"optional"', 'Odometer photo when returning',
   'Off, Optional or Required.', false),
  ('vehicles.undo_minutes', '10', 'Time to undo a start or return (minutes)',
   'After this, only a car manager can correct a trip.', false),
  ('vehicles.reminder_hour', '20', 'Car still out reminder (hour, 24-hour clock)',
   'The driver gets a reminder at this time if they haven''t returned the car. Car managers are told the next morning.', false),
  ('vehicles.app_days', '90', 'Stay signed in on the Cars app (days)',
   'Staff unlock the Cars app with their PIN until then, then sign in again.', false)
on conflict (key) do nothing;

alter table public.admin_delegations drop constraint if exists admin_delegations_areas_check;
alter table public.admin_delegations add constraint admin_delegations_areas_check
  check (areas <@ array['branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'audit']);

create or replace function public.setting_area(p_key text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when p_key in ('brand.support_contact', 'brand.announcement', 'people.invite_message') then 'messages'
    when p_key like 'brand.%' or p_key like 'wording.%' then 'branding'
    when p_key like 'people.%' then 'people'
    when p_key like 'compliance.%' then 'compliance'
    when p_key like 'tasks.%' then 'tasks'
    when p_key like 'reports.%' then 'reports'
    when p_key like 'vehicles.%' then 'vehicles'
    else null
  end
$$;

create function public.cars_on()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.feature_enabled('vehicles') and public.is_member() and public.my_role() <> 'new_starter'
$$;

create function public.can_manage_cars()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.cars_on()
     and (public.my_role() = 'system_admin' or public.my_role() = any (public.setting_roles('vehicles.manager_roles')))
$$;

create function public.can_see_car_reports()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.can_manage_cars()
      or (public.cars_on() and public.my_role() = any (public.setting_roles('vehicles.report_roles')))
$$;

create function public.car_setting(p_key text, p_default text)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select value #>> '{}' from public.app_settings where key = p_key), p_default)
$$;

-- ---------------------------------------------------------------------------
-- Cars, clients and purposes
-- ---------------------------------------------------------------------------

create table public.cars (
  id               uuid primary key default gen_random_uuid(),
  org_id           uuid not null default public.default_org_id() references public.organisation (id),
  name             text not null check (length(trim(name)) between 1 and 80),
  rego             text not null check (length(trim(rego)) between 1 and 12),
  car_type         text not null default '' check (length(car_type) <= 60),
  colour           text not null default '' check (length(colour) <= 40),
  -- The last known reading: set when the car is added, then by each return.
  odometer         int not null default 0 check (odometer between 0 and 2000000),
  rego_expires     date,
  service_due_date date,
  service_due_km   int check (service_due_km between 0 and 2000000),
  photo_path       text,
  notes            text not null default '' check (length(notes) <= 1000),
  active           boolean not null default true,
  -- Reminders already sent (so each is sent once).
  rego_alerted     date,
  service_alerted  text,
  created_by       uuid references public.profiles (id) default auth.uid(),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create unique index cars_rego_unique on public.cars (org_id, upper(replace(rego, ' ', '')));

create table public.car_clients (
  id         uuid primary key default gen_random_uuid(),
  org_id     uuid not null default public.default_org_id() references public.organisation (id),
  name       text not null check (length(trim(name)) between 1 and 80),
  reference  text not null default '' check (length(reference) <= 60),
  active     boolean not null default true,
  created_by uuid references public.profiles (id) default auth.uid(),
  created_at timestamptz not null default now()
);

create table public.car_purposes (
  id         uuid primary key default gen_random_uuid(),
  org_id     uuid not null default public.default_org_id() references public.organisation (id),
  name       text not null check (length(trim(name)) between 1 and 60),
  active     boolean not null default true,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);
create unique index car_purposes_name_unique on public.car_purposes (org_id, lower(trim(name)));

insert into public.car_purposes (name, sort_order) values
  ('Client transport', 10), ('Community access', 20), ('Shopping with a client', 30),
  ('Medical appointment', 40), ('Office errand', 50), ('Other', 90);

alter table public.cars enable row level security;
alter table public.car_clients enable row level security;
alter table public.car_purposes enable row level security;

create policy "staff see cars" on public.cars for select to authenticated using (public.cars_on());
create policy "car managers add cars" on public.cars for insert to authenticated with check (public.can_manage_cars());
create policy "car managers change cars" on public.cars for update to authenticated
  using (public.can_manage_cars()) with check (public.can_manage_cars());

-- Staff choose clients through car_client_options(), which shows names only.
create policy "car managers see clients" on public.car_clients for select to authenticated using (public.can_manage_cars());
create policy "car managers add clients" on public.car_clients for insert to authenticated with check (public.can_manage_cars());
create policy "car managers change clients" on public.car_clients for update to authenticated
  using (public.can_manage_cars()) with check (public.can_manage_cars());

create policy "staff see purposes" on public.car_purposes for select to authenticated using (public.cars_on());
create policy "car managers add purposes" on public.car_purposes for insert to authenticated with check (public.can_manage_cars());
create policy "car managers change purposes" on public.car_purposes for update to authenticated
  using (public.can_manage_cars()) with check (public.can_manage_cars());

-- Nothing is deleted: cars, clients and purposes are switched off instead.
revoke delete, truncate on public.cars, public.car_clients, public.car_purposes from anon, authenticated;

-- Changes to cars, clients and purposes go in the change log.
create function public.log_car_setup()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.write_audit(
    case when tg_op = 'INSERT' then 'added' else 'changed' end || '_' || tg_argv[0],
    tg_argv[0], new.id::text,
    case when tg_op = 'INSERT' then to_jsonb(new) else jsonb_build_object('before', to_jsonb(old), 'after', to_jsonb(new)) end);
  return new;
end;
$$;

create function public.touch_car()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger cars_touch before update on public.cars for each row execute function public.touch_car();
create trigger cars_log after insert or update of name, rego, car_type, colour, rego_expires, service_due_date,
  service_due_km, notes, active on public.cars for each row execute function public.log_car_setup('car');
create trigger car_clients_log after insert or update on public.car_clients for each row execute function public.log_car_setup('car_client');
create trigger car_purposes_log after insert or update on public.car_purposes for each row execute function public.log_car_setup('car_purpose');

-- ---------------------------------------------------------------------------
-- Trips
-- ---------------------------------------------------------------------------

create table public.car_trips (
  id              bigint generated always as identity primary key,
  org_id          uuid not null default public.default_org_id() references public.organisation (id),
  car_id          uuid not null references public.cars (id),
  driver_id       uuid not null references public.profiles (id),
  purpose         text not null check (length(purpose) between 1 and 60),
  details         text not null default '' check (length(details) <= 300),
  -- The client's name at the time, so history reads the same if it changes.
  client_id       uuid references public.car_clients (id),
  client_name     text not null default '',
  started_at      timestamptz not null default now(),
  start_odo       int not null check (start_odo between 0 and 2000000),
  -- How far the car went between the last return and this start (not logged).
  gap_km          int not null default 0,
  returned_at     timestamptz,
  end_odo         int check (end_odo between 0 and 2000000),
  km              int generated always as (end_odo - start_odo) stored,
  returned_by     uuid references public.profiles (id),
  return_note     text not null default '' check (length(return_note) <= 300),
  odo_photo_path  text,
  reminded_at     timestamptz,
  managers_told_at timestamptz,
  corrected_at    timestamptz,
  check (end_odo is null or end_odo >= start_odo),
  check ((returned_at is null) = (end_odo is null))
);
-- One trip at a time per car, and per driver.
create unique index car_trips_one_per_car on public.car_trips (car_id) where returned_at is null;
create unique index car_trips_one_per_driver on public.car_trips (driver_id) where returned_at is null;
create index car_trips_started on public.car_trips (started_at desc);

alter table public.car_trips enable row level security;
create policy "drivers see their trips, reports see all" on public.car_trips for select to authenticated
  using (public.cars_on() and (driver_id = auth.uid() or public.can_see_car_reports()));
-- Trips change only through the functions below.
revoke insert, update, delete, truncate on public.car_trips from anon, authenticated;

-- Which cars are free, who has the others, and the suggested start reading.
create function public.car_board()
returns table (id uuid, name text, rego text, car_type text, colour text, odometer int,
               trip_id bigint, driver_id uuid, driver_name text, started_at timestamptz)
language sql
stable
security definer
set search_path = ''
as $$
  select c.id, c.name, c.rego, c.car_type, c.colour, c.odometer,
         t.id, t.driver_id,
         case when p.role = 'system_admin' then 'Admin' else coalesce(nullif(p.full_name, ''), p.email) end,
         t.started_at
    from public.cars c
    left join public.car_trips t on t.car_id = c.id and t.returned_at is null
    left join public.profiles p on p.id = t.driver_id
   where public.cars_on() and c.active
   order by c.name, c.rego
$$;

-- Client names for the list on Start (no reference numbers).
create function public.car_client_options()
returns table (id uuid, name text)
language sql
stable
security definer
set search_path = ''
as $$
  select id, name from public.car_clients
   where public.cars_on() and active and public.car_setting('vehicles.client_field', 'optional') <> 'off'
   order by lower(name)
$$;

create function public.start_car_trip(p_car_id uuid, p_purpose_id uuid, p_client_id uuid, p_start_odo int, p_details text default '')
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  c public.cars;
  v_purpose text;
  v_client text := '';
  v_mode text := public.car_setting('vehicles.client_field', 'optional');
  v_id bigint;
begin
  if not public.cars_on() then
    raise exception 'Cars are switched off, or you can''t use them yet';
  end if;
  select * into c from public.cars where id = p_car_id and active for update;
  if c.id is null then
    raise exception 'Choose a car';
  end if;
  if exists (select 1 from public.car_trips where car_id = c.id and returned_at is null) then
    raise exception 'Someone else has this car out. Choose another one.';
  end if;
  if exists (select 1 from public.car_trips where driver_id = auth.uid() and returned_at is null) then
    raise exception 'Return the car you have out first';
  end if;
  select name into v_purpose from public.car_purposes where id = p_purpose_id and active;
  if v_purpose is null then
    raise exception 'Choose the purpose of the trip';
  end if;
  if v_purpose = 'Other' and coalesce(trim(p_details), '') = '' then
    raise exception 'Say what the trip is for';
  end if;
  if v_mode <> 'off' and p_client_id is not null then
    select name into v_client from public.car_clients where id = p_client_id and active;
    if v_client is null then
      raise exception 'Choose a client from the list';
    end if;
  end if;
  if v_mode = 'required' and coalesce(v_client, '') = '' then
    raise exception 'Choose the client';
  end if;
  if p_start_odo is null or p_start_odo < 0 then
    raise exception 'Enter the odometer reading';
  end if;
  if p_start_odo < c.odometer then
    raise exception 'That''s lower than the last reading for this car (% km). Check the dashboard.', c.odometer;
  end if;
  if p_start_odo > c.odometer + 5000 then
    raise exception 'That''s over 5,000 km more than the last reading (% km). Check the dashboard.', c.odometer;
  end if;

  insert into public.car_trips (car_id, driver_id, purpose, details, client_id, client_name, start_odo, gap_km)
  values (c.id, auth.uid(), v_purpose, left(coalesce(trim(p_details), ''), 300),
          case when v_mode <> 'off' then p_client_id end, coalesce(v_client, ''), p_start_odo, p_start_odo - c.odometer)
  returning id into v_id;
  return v_id;
end;
$$;

-- Undo a start (wrong car, pressed too early): the trip is removed.
create function public.undo_car_start(p_trip_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.car_trips;
begin
  select * into t from public.car_trips where id = p_trip_id for update;
  if t.id is null or t.driver_id <> auth.uid() or not public.cars_on() then
    raise exception 'Trip not found';
  end if;
  if t.returned_at is not null then
    raise exception 'This car has been returned. Undo the return first.';
  end if;
  if t.started_at < now() - make_interval(mins => public.car_setting('vehicles.undo_minutes', '10')::int) then
    raise exception 'It''s too late to undo. Return the car instead, or ask a car manager to fix the trip.';
  end if;
  delete from public.car_trips where id = t.id;
  perform public.write_audit('car_start_undone', 'car_trip', t.id::text, to_jsonb(t));
end;
$$;

-- Return a car. A car manager can return it for the driver, with a reason.
create function public.return_car_trip(p_trip_id bigint, p_end_odo int, p_photo_path text default null, p_note text default '')
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.car_trips;
  v_photo text := public.car_setting('vehicles.odo_photo', 'optional');
  v_for_someone boolean;
begin
  select * into t from public.car_trips where id = p_trip_id for update;
  if t.id is null or not public.cars_on() then
    raise exception 'Trip not found';
  end if;
  v_for_someone := t.driver_id <> auth.uid();
  if v_for_someone and not public.can_manage_cars() then
    raise exception 'Trip not found';
  end if;
  if t.returned_at is not null then
    raise exception 'This car has already been returned';
  end if;
  if v_for_someone and coalesce(trim(p_note), '') = '' then
    raise exception 'Say why you''re returning it for them';
  end if;
  if p_end_odo is null then
    raise exception 'Enter the odometer reading';
  end if;
  if p_end_odo < t.start_odo then
    raise exception 'That''s lower than the start reading (% km). Check the dashboard.', t.start_odo;
  end if;
  if p_end_odo > t.start_odo + 3000 then
    raise exception 'That''s over 3,000 km for one trip. Check the reading.';
  end if;
  if p_photo_path is not null and p_photo_path not like t.driver_id::text || '/%' and p_photo_path not like auth.uid()::text || '/%' then
    raise exception 'Upload the photo again';
  end if;
  if v_photo = 'required' and p_photo_path is null and not v_for_someone then
    raise exception 'Add a photo of the odometer';
  end if;

  update public.car_trips
     set returned_at = now(), end_odo = p_end_odo, returned_by = auth.uid(),
         return_note = left(coalesce(trim(p_note), ''), 300),
         odo_photo_path = case when v_photo = 'off' then null else p_photo_path end
   where id = t.id;
  update public.cars set odometer = greatest(odometer, p_end_odo) where id = t.car_id;

  if v_for_someone then
    perform public.notify(t.driver_id, 'car_returned_for_you',
      format('%s returned the %s for you', public.my_name(), (select name from public.cars where id = t.car_id)),
      coalesce(nullif(trim(p_note), ''), ''), '/cars');
    perform public.write_audit('car_returned_for_someone', 'car_trip', t.id::text,
      jsonb_build_object('driver', t.driver_id, 'end_odo', p_end_odo, 'note', p_note));
  end if;
  return p_end_odo - t.start_odo;
end;
$$;

-- Undo a return (wrong reading, pressed too early): the trip is open again.
create function public.undo_car_return(p_trip_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.car_trips;
begin
  select * into t from public.car_trips where id = p_trip_id for update;
  if t.id is null or not public.cars_on() or coalesce(t.returned_by, t.driver_id) <> auth.uid() then
    raise exception 'Trip not found';
  end if;
  if t.returned_at is null then
    raise exception 'This car hasn''t been returned';
  end if;
  if t.returned_at < now() - make_interval(mins => public.car_setting('vehicles.undo_minutes', '10')::int) then
    raise exception 'It''s too late to undo. Ask a car manager to fix the trip.';
  end if;
  if exists (select 1 from public.car_trips where car_id = t.car_id and id <> t.id and started_at > t.started_at) then
    raise exception 'Someone has taken this car since. Ask a car manager to fix the trip.';
  end if;
  if exists (select 1 from public.car_trips where driver_id = t.driver_id and returned_at is null) then
    raise exception 'Return the car you have out first';
  end if;
  update public.car_trips
     set returned_at = null, end_odo = null, returned_by = null, return_note = '', odo_photo_path = null
   where id = t.id;
  update public.cars
     set odometer = greatest(t.start_odo, coalesce((select max(end_odo) from public.car_trips where car_id = t.car_id and id <> t.id), 0))
   where id = t.car_id;
  perform public.write_audit('car_return_undone', 'car_trip', t.id::text, to_jsonb(t));
end;
$$;

-- A car manager fixes a trip after the undo time, with a reason.
create function public.correct_car_trip(p_trip_id bigint, p_start_odo int, p_end_odo int, p_purpose text, p_client_id uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.car_trips;
  n public.car_trips;
  v_client text := '';
begin
  if not public.can_manage_cars() then
    raise exception 'Only car managers can fix trips';
  end if;
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'Say why the trip is being changed';
  end if;
  select * into t from public.car_trips where id = p_trip_id for update;
  if t.id is null then
    raise exception 'Trip not found';
  end if;
  if p_start_odo is null or p_start_odo < 0 or (p_end_odo is not null and p_end_odo < p_start_odo) then
    raise exception 'The end reading can''t be lower than the start';
  end if;
  if (t.returned_at is null) <> (p_end_odo is null) then
    raise exception using message = case when t.returned_at is null then 'Return the car to add an end reading' else 'Enter the end reading' end;
  end if;
  if coalesce(trim(p_purpose), '') = '' then
    raise exception 'Enter the purpose';
  end if;
  if p_client_id is not null then
    select name into v_client from public.car_clients where id = p_client_id;
  end if;
  update public.car_trips
     set start_odo = p_start_odo, end_odo = p_end_odo, purpose = left(trim(p_purpose), 60),
         client_id = p_client_id, client_name = coalesce(v_client, ''), corrected_at = now()
   where id = t.id
  returning * into n;
  update public.cars
     set odometer = greatest(odometer, coalesce(p_end_odo, p_start_odo))
   where id = t.car_id;
  perform public.write_audit('car_trip_corrected', 'car_trip', t.id::text,
    jsonb_build_object('reason', trim(p_reason), 'before', to_jsonb(t), 'after', to_jsonb(n)));
end;
$$;

revoke execute on function public.cars_on() from public, anon;
revoke execute on function public.can_manage_cars() from public, anon;
revoke execute on function public.can_see_car_reports() from public, anon;
revoke execute on function public.car_setting(text, text) from public, anon;
revoke execute on function public.car_board() from public, anon;
revoke execute on function public.car_client_options() from public, anon;
revoke execute on function public.start_car_trip(uuid, uuid, uuid, int, text) from public, anon;
revoke execute on function public.undo_car_start(bigint) from public, anon;
revoke execute on function public.return_car_trip(bigint, int, text, text) from public, anon;
revoke execute on function public.undo_car_return(bigint) from public, anon;
revoke execute on function public.correct_car_trip(bigint, int, int, text, uuid, text) from public, anon;
revoke execute on function public.log_car_setup() from public, anon, authenticated;
grant execute on function public.cars_on(), public.can_manage_cars(), public.can_see_car_reports(), public.car_board(),
  public.car_client_options(), public.start_car_trip(uuid, uuid, uuid, int, text), public.undo_car_start(bigint),
  public.return_car_trip(bigint, int, text, text), public.undo_car_return(bigint),
  public.correct_car_trip(bigint, int, int, text, uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Cars app PIN (checked by the website; never readable from the browser)
-- ---------------------------------------------------------------------------

create table public.car_app_pins (
  user_id     uuid primary key references public.profiles (id) on delete cascade,
  pin_hash    text not null,
  failed      int not null default 0,
  updated_at  timestamptz not null default now()
);
alter table public.car_app_pins enable row level security;
revoke all on public.car_app_pins from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Reminders and the weekly mileage report (run every hour with the others)
-- ---------------------------------------------------------------------------

create function public.car_managers()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select id from public.profiles
   where active and (role = 'system_admin' or role = any (public.setting_roles('vehicles.manager_roles')))
$$;

create function public.run_car_alerts(p_now timestamptz default now())
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
        for v_person in
          select id from public.profiles
           where active and (role in ('manager', 'system_admin') or role = any (public.setting_roles('vehicles.report_roles')))
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

revoke execute on function public.car_managers() from public, anon, authenticated;
revoke execute on function public.run_car_alerts(timestamptz) from public, anon, authenticated;
grant execute on function public.run_car_alerts(timestamptz) to service_role;

-- ---------------------------------------------------------------------------
-- Files: car photos (car managers) and odometer photos (the driver)
-- ---------------------------------------------------------------------------

do $storage$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  insert into storage.buckets (id, name, public) values ('car-files', 'car-files', false) on conflict (id) do nothing;
  create policy "drivers upload odometer photos" on storage.objects
    for insert to authenticated
    with check (bucket_id = 'car-files' and public.cars_on() and (storage.foldername(name))[1] = auth.uid()::text);
  create policy "car managers upload car photos" on storage.objects
    for insert to authenticated
    with check (bucket_id = 'car-files' and public.can_manage_cars() and (storage.foldername(name))[1] = 'cars');
  create policy "car files are seen by the driver and car reports" on storage.objects
    for select to authenticated
    using (bucket_id = 'car-files' and public.cars_on()
           and ((storage.foldername(name))[1] in ('cars', auth.uid()::text) or public.can_see_car_reports()));
end;
$storage$;
