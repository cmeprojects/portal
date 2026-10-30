-- Staff Portal · © cmeproject. All rights reserved.
--
-- Cars (cmeprojects): staff say where they went when they return a car
-- (optional), instead of giving details when they start. "What's it for?"
-- stays on Start for the purpose Other.

alter table public.car_trips add column if not exists went_to text not null default '';

drop function if exists public.return_car_trip(bigint, int, text, text);

-- Return a car, with where it went (optional). A car manager can return it
-- for the driver, with a reason.
create or replace function public.return_car_trip(p_trip_id bigint, p_end_odo int, p_photo_path text default null, p_note text default '', p_where text default '')
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
         went_to = left(coalesce(trim(p_where), ''), 300),
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
create or replace function public.undo_car_return(p_trip_id bigint)
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
     set returned_at = null, end_odo = null, returned_by = null, return_note = '', went_to = '', odo_photo_path = null
   where id = t.id;
  update public.cars
     set odometer = greatest(t.start_odo, coalesce((select max(end_odo) from public.car_trips where car_id = t.car_id and id <> t.id), 0))
   where id = t.car_id;
  perform public.write_audit('car_return_undone', 'car_trip', t.id::text, to_jsonb(t));
end;
$$;

revoke execute on function public.return_car_trip(bigint, int, text, text, text) from public, anon;
grant execute on function public.return_car_trip(bigint, int, text, text, text) to authenticated;
