-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 143. Safe to run again. Custom and catalogue services stay as
-- ordinary services (their name and program are kept); the catalogue is removed.
begin;
CREATE OR REPLACE FUNCTION public.guard_shift_client()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.guard_client_service()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  v_gaps text[];
begin
  if not exists (select 1 from public.client_locations where id = new.location_id and client_id = new.client_id) then
    raise exception 'Choose one of this client''s locations.';
  end if;
  if (tg_op = 'INSERT' or new.program_id is distinct from old.program_id)
     and not exists (select 1 from public.client_programs where id = new.program_id and active) then
    raise exception 'That program isn''t in use any more. Choose another.';
  end if;
  if new.status = 'active' and (tg_op = 'INSERT' or old.status <> 'active'
                                or new.location_id is distinct from old.location_id
                                or new.program_id is distinct from old.program_id) then
    v_gaps := public.client_gaps(new.client_id, new.program_id, new.location_id, new.consent_required, new.consent_given_on);
    if cardinality(v_gaps) > 0 then
      raise exception 'This service can''t be made active yet. %', array_to_string(v_gaps, ' ');
    end if;
  end if;
  return new;
end;
$function$;

drop function if exists public.service_shift_types(uuid);
drop index if exists public.client_services_one_per_custom;
drop index if exists public.client_services_one_per_catalogue;
alter table public.client_services drop column if exists shift_types;
alter table public.client_services drop constraint if exists client_services_description_check;
alter table public.client_services drop column if exists description;
alter table public.client_services drop constraint if exists client_services_origin_check;
alter table public.client_services drop column if exists origin;
alter table public.client_services drop column if exists catalogue_id;
drop table if exists public.service_catalogue;
drop function if exists public.guard_service_catalogue();
do $$ begin
  if not exists (select 1 from public.shifts where shift_type = 'shopping_assistance')
     and not exists (select 1 from public.shift_templates where shift_type = 'shopping_assistance') then
    delete from public.shift_types where key = 'shopping_assistance';
  end if;
end $$;
commit;
