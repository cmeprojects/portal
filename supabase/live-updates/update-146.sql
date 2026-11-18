-- Staff Portal · © cmeproject. All rights reserved.
-- Update 146: house rostering (SIL): other residents on a shift.
-- Safe to run again. Undo: undo-146.sql.
begin;
create table if not exists public.shift_residents (
  shift_id uuid not null references public.shifts (id) on delete cascade,
  client_id uuid not null references public.car_clients (id),
  service_id uuid not null references public.client_services (id),
  org_id uuid not null default public.default_org_id(),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  primary key (shift_id, client_id)
);
create index if not exists shift_residents_client on public.shift_residents (client_id);
alter table public.shift_residents enable row level security;
drop policy if exists "read shift residents" on public.shift_residents;
create policy "read shift residents" on public.shift_residents
  for select to authenticated
  using ((select public.can('ops.roster', 'view'))
         or shift_id in (select s.id from public.shifts s where s.worker_id = (select auth.uid()) and s.status = 'published')
         or public.can('clients.care_plans', 'view', client_id));
drop policy if exists "people who roster add residents" on public.shift_residents;
create policy "people who roster add residents" on public.shift_residents
  for insert to authenticated with check ((select public.can('ops.roster', 'edit')));
drop policy if exists "people who roster remove residents" on public.shift_residents;
create policy "people who roster remove residents" on public.shift_residents
  for delete to authenticated using ((select public.can('ops.roster', 'edit')));
-- No update: remove and add instead (both logged).
grant select, insert, delete on public.shift_residents to authenticated;
revoke all on public.shift_residents from anon;

create or replace function public.guard_shift_resident() returns trigger
language plpgsql set search_path = '' as $$
declare
  s public.shifts;
  v public.client_services;
  v_name text;
  v_types text[];
begin
  if tg_op = 'DELETE' then
    select name into v_name from public.car_clients where id = old.client_id;
    insert into public.shift_events (shift_id, actor, kind, summary, source, field, old_value, new_value)
    values (old.shift_id, auth.uid(), 'change', 'removed ' || coalesce(v_name, 'a resident') || ' from this shift', 'portal', 'Residents', v_name, null);
    return old;
  end if;
  select * into s from public.shifts where id = new.shift_id;
  if s.id is null or s.status = 'cancelled' then
    raise exception 'That shift isn''t there any more.';
  end if;
  if s.client_id is null then
    raise exception 'Residents are added to a client shift. Choose the main client first.';
  end if;
  if new.client_id = s.client_id then
    raise exception 'That''s already the shift''s main client.';
  end if;
  if coalesce((select c.status from public.car_clients c where c.id = new.client_id), '') <> 'active' then
    raise exception 'That client isn''t active yet, so they can''t be rostered.';
  end if;
  select * into v from public.client_services where id = new.service_id;
  if v.id is null or v.client_id <> new.client_id then
    raise exception 'Choose one of that resident''s approved services.';
  end if;
  if v.status in ('on_hold', 'ended')
     or (v.end_date is not null and v.end_date < (s.starts_at at time zone 'Australia/Sydney')::date)
     or v.start_date > (s.starts_at at time zone 'Australia/Sydney')::date then
    raise exception 'The resident''s approved service "%" isn''t current on that day.', v.label;
  end if;
  v_types := public.service_shift_types(new.service_id);
  if (v.origin <> 'legacy' or cardinality(v_types) > 0) and not (s.shift_type = any (v_types)) then
    raise exception 'The resident''s approved service "%" doesn''t cover this shift type.', v.label;
  end if;
  new.created_by := auth.uid();
  new.created_at := now();
  select name into v_name from public.car_clients where id = new.client_id;
  insert into public.shift_events (shift_id, actor, kind, summary, source, field, old_value, new_value)
  values (new.shift_id, auth.uid(), 'change', 'added ' || coalesce(v_name, 'a resident') || ' to this shift', 'portal', 'Residents', null, v_name);
  return new;
end;
$$;
revoke execute on function public.guard_shift_resident() from public, anon, authenticated;
drop trigger if exists guard_shift_resident on public.shift_residents;
create trigger guard_shift_resident before insert or delete on public.shift_residents
  for each row execute function public.guard_shift_resident();

-- The worker sees each resident's name, current alerts and instructions (as for the main client).
drop policy if exists "workers see residents of their shifts" on public.car_clients;
create policy "workers see residents of their shifts" on public.car_clients
  for select to authenticated
  using (id in (select r.client_id from public.shift_residents r join public.shifts s on s.id = r.shift_id
                 where s.worker_id = (select auth.uid()) and s.status = 'published' and s.ends_at > now() - interval '14 days'));
drop policy if exists "workers see alerts for residents of their shifts" on public.client_alerts;
create policy "workers see alerts for residents of their shifts" on public.client_alerts
  for select to authenticated
  using (active and client_id in (select r.client_id from public.shift_residents r join public.shifts s on s.id = r.shift_id
                                   where s.worker_id = (select auth.uid()) and s.status = 'published' and s.ends_at > now() - interval '14 days'));
drop policy if exists "workers see instructions for residents of their shifts" on public.client_worker_instructions;
create policy "workers see instructions for residents of their shifts" on public.client_worker_instructions
  for select to authenticated
  using (active and client_id in (select r.client_id from public.shift_residents r join public.shifts s on s.id = r.shift_id
                                   where s.worker_id = (select auth.uid()) and s.status = 'published' and s.ends_at > now() - interval '14 days'));

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
  -- cmeprojects (update 146): a new shift type must still be covered for every resident on the shift.
  if tg_op = 'UPDATE' and new.shift_type is distinct from old.shift_type
     and exists (select 1 from public.shift_residents r join public.client_services v on v.id = r.service_id
                  where r.shift_id = new.id
                    and (v.origin <> 'legacy' or cardinality(public.service_shift_types(r.service_id)) > 0)
                    and not (new.shift_type = any (public.service_shift_types(r.service_id)))) then
    raise exception 'A resident on this shift isn''t approved for that shift type. Change the residents first.';
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
commit;
