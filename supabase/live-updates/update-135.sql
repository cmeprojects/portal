-- Staff Portal · © cmeproject. All rights reserved.
-- Update 135: a car trip links itself to the driver's shift.
-- Safe to run again. Undo: undo-135.sql.
begin;
create or replace function public.link_trip_to_shift() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.shift_id is null and new.driver_id is not null then
    select s.id into new.shift_id
    from public.shifts s
    where s.worker_id = new.driver_id
      and s.status = 'published'
      and coalesce(new.started_at, now()) between s.starts_at - interval '1 hour' and s.ends_at + interval '1 hour'
    order by (s.client_id is not distinct from new.client_id) desc, abs(extract(epoch from (s.starts_at - coalesce(new.started_at, now()))))
    limit 1;
  end if;
  return new;
end;
$$;
revoke execute on function public.link_trip_to_shift() from public, anon, authenticated;

drop trigger if exists link_trip_to_shift on public.car_trips;
create trigger link_trip_to_shift before insert on public.car_trips
  for each row execute function public.link_trip_to_shift();
commit;
