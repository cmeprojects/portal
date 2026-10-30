-- Staff Portal · © cmeproject. All rights reserved.
--
-- Live updates (cmeprojects): open pages refresh themselves when something
-- they show changes. Supabase sends a change only to people allowed to see
-- that row. Staff can't see other people's trips, so each car gets a
-- "last changed" time, touched whenever one of its trips changes, which
-- everyone who uses Cars can see.

alter table public.cars add column if not exists changed_at timestamptz not null default now();

create or replace function public.touch_car_from_trip()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.cars set changed_at = now() where id = coalesce(new.car_id, old.car_id);
  return coalesce(new, old);
end;
$$;
revoke execute on function public.touch_car_from_trip() from public, anon, authenticated;

drop trigger if exists car_trips_touch_car on public.car_trips;
create trigger car_trips_touch_car after insert or update or delete on public.car_trips
  for each row execute function public.touch_car_from_trip();

-- A "something changed" signal everyone signed in can see, for changes they
-- otherwise couldn't (a built feature switched off is hidden from staff, so
-- they'd never hear that it changed).
create table if not exists public.live_signals (
  topic      text primary key,
  changed_at timestamptz not null default now()
);
alter table public.live_signals enable row level security;
drop policy if exists "members see signals" on public.live_signals;
create policy "members see signals" on public.live_signals for select to authenticated using (public.is_member());
revoke insert, update, delete, truncate on public.live_signals from anon, authenticated;

create or replace function public.signal_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.live_signals (topic) values (tg_argv[0])
  on conflict (topic) do update set changed_at = now();
  return null;
end;
$$;
revoke execute on function public.signal_change() from public, anon, authenticated;

drop trigger if exists custom_features_signal on public.custom_features;
create trigger custom_features_signal after insert or update or delete on public.custom_features
  for each statement execute function public.signal_change('features');

-- The tables open pages listen to.
do $live$
declare
  t text;
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    return;
  end if;
  foreach t in array array['cars', 'car_trips', 'custom_entries', 'custom_fields', 'app_settings', 'features', 'notifications', 'live_signals'] loop
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end;
$live$;
