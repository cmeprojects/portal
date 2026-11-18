-- Staff Portal · © cmeproject. All rights reserved.
-- Update 130: client shifts need a service and a location. Safe to run again.
-- Undo: undo-130.sql. Run update 129 first.
begin;
create or replace function public.guard_shift_client()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.status = 'cancelled' then
    return new;
  end if;
  if new.client_id is not null and (tg_op = 'INSERT' or new.client_id is distinct from old.client_id)
     and coalesce((select c.status from public.car_clients c where c.id = new.client_id), '') <> 'active' then
    raise exception 'That client isn''t active yet, so they can''t be rostered. Finish their set-up first.';
  end if;
  -- cmeprojects (update 130): a client shift needs its service and location.
  if new.client_id is not null and (new.service_id is null or new.location_id is null)
     and (tg_op = 'INSERT' or new.client_id is distinct from old.client_id or new.service_id is distinct from old.service_id or new.location_id is distinct from old.location_id) then
    raise exception 'Choose the client''s service and location for this shift.';
  end if;
  if new.vehicle_id is not null and (tg_op = 'INSERT' or new.vehicle_id is distinct from old.vehicle_id
                                     or new.starts_at is distinct from old.starts_at or new.ends_at is distinct from old.ends_at) then
    if not exists (select 1 from public.cars c where c.id = new.vehicle_id and c.active) then
      raise exception 'Choose an active company car.';
    end if;
    if exists (select 1 from public.shifts s where s.vehicle_id = new.vehicle_id and s.id <> new.id and s.status <> 'cancelled'
                and s.starts_at < new.ends_at and s.ends_at > new.starts_at) then
      raise exception 'That car is already booked for another shift at that time.';
    end if;
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_shift_client() from public, anon, authenticated;
commit;
