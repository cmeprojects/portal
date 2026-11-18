-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 146. Safe to run again. Residents listed on shifts are removed (each shift keeps its main client).
begin;
CREATE OR REPLACE FUNCTION public.guard_shift_client()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  v_service public.client_services;
  v_types text[];
  v_missing text;
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
  -- cmeprojects (update 143): the approved service must be this client's, current on the
  -- shift's date (not suspended, ended or past its end date), and must permit the shift type.
  if new.client_id is not null and new.service_id is not null
     and (tg_op = 'INSERT' or new.service_id is distinct from old.service_id or new.shift_type is distinct from old.shift_type
          or new.client_id is distinct from old.client_id or new.starts_at is distinct from old.starts_at) then
    select s.* into v_service from public.client_services s where s.id = new.service_id;
    if v_service.id is null or v_service.client_id <> new.client_id then
      raise exception 'Choose one of this client''s approved services.';
    end if;
    if v_service.status in ('on_hold', 'ended') then
      raise exception 'The approved service "%" is %, so it can''t be rostered.', v_service.label, case v_service.status when 'on_hold' then 'suspended' else 'ended' end;
    end if;
    if v_service.end_date is not null and v_service.end_date < (new.starts_at at time zone 'Australia/Sydney')::date then
      raise exception 'The approved service "%" ended on %.', v_service.label, to_char(v_service.end_date, 'DD Mon YYYY');
    end if;
    if v_service.start_date > (new.starts_at at time zone 'Australia/Sydney')::date then
      raise exception 'The approved service "%" starts on %.', v_service.label, to_char(v_service.start_date, 'DD Mon YYYY');
    end if;
    v_types := public.service_shift_types(new.service_id);
    if (v_service.origin <> 'legacy' or cardinality(v_types) > 0) and not (new.shift_type = any (v_types)) then
      raise exception 'The approved service "%" doesn''t cover that shift type. Choose a shift type it covers, or add the service to the client.', v_service.label;
    end if;
  end if;
  -- cmeprojects (update 145): qualifications the shift type needs. The worker must
  -- hold each one (current on the shift's date). Checked when the worker, the
  -- type or the time changes; system jobs (no signed-in person) aren't checked.
  if new.worker_id is not null and auth.uid() is not null
     and (tg_op = 'INSERT' or new.worker_id is distinct from old.worker_id or new.shift_type is distinct from old.shift_type or new.starts_at is distinct from old.starts_at) then
    select coalesce(string_agg(i.title, ', '), '') into v_missing
      from public.shift_types t
      cross join unnest(t.required_items) req(item_id)
      join public.compliance_items i on i.id = req.item_id
     where t.key = new.shift_type
       and not exists (select 1 from public.roster_check_dates(new.worker_id) c
                        where c.item_id = req.item_id
                          and (c.expires_on is null or c.expires_on >= (new.starts_at at time zone 'Australia/Sydney')::date));
    if v_missing <> '' then
      raise exception 'That worker doesn''t hold what this shift type needs: %.', v_missing;
    end if;
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

drop policy if exists "workers see instructions for residents of their shifts" on public.client_worker_instructions;
drop policy if exists "workers see alerts for residents of their shifts" on public.client_alerts;
drop policy if exists "workers see residents of their shifts" on public.car_clients;
drop table if exists public.shift_residents;
drop function if exists public.guard_shift_resident();
commit;
