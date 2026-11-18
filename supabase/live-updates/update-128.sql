-- Staff Portal · © cmeproject. All rights reserved.
-- Update 128: rostering round 3 (shift reference, type, car, pay group,
-- allowances, signatures needed; active clients only; field-level log written
-- only by the database; worker accept/decline; signatures; internal notes;
-- Cars trips linked to shifts). Safe to run again. Undo: undo-128.sql.
begin;
-- ===== Shift fields =====
create sequence if not exists public.shift_ref_seq;
alter table public.shifts add column if not exists ref text;
update public.shifts set ref = 'SH-' || lpad(nextval('public.shift_ref_seq')::text, 6, '0') where ref is null;
alter table public.shifts alter column ref set default ('SH-' || lpad(nextval('public.shift_ref_seq')::text, 6, '0'));
alter table public.shifts alter column ref set not null;
create unique index if not exists shifts_ref on public.shifts (ref);
alter table public.shifts add column if not exists shift_type text not null default 'standard';
alter table public.shifts add column if not exists vehicle_id uuid references public.cars (id) on delete restrict;
alter table public.shifts add column if not exists pay_group text not null default '';
alter table public.shifts add column if not exists allowances text[] not null default '{}';
alter table public.shifts add column if not exists needs_worker_signature boolean not null default false;
alter table public.shifts add column if not exists needs_client_signature boolean not null default false;
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'shifts_shift_type_check') then
    alter table public.shifts add constraint shifts_shift_type_check check (shift_type in
      ('standard', 'personal_care', 'domestic', 'community_access', 'overnight', 'sleepover', 'training', 'meeting', 'admin', 'other'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'shifts_pay_group_check') then
    alter table public.shifts add constraint shifts_pay_group_check check (length(pay_group) <= 60);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'shifts_allowances_check') then
    alter table public.shifts add constraint shifts_allowances_check check (cardinality(allowances) <= 10);
  end if;
end $$;
create index if not exists shifts_vehicle on public.shifts (vehicle_id, starts_at) where vehicle_id is not null and status <> 'cancelled';

-- Only active clients get new shifts; a car must be active and not double-booked.
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
drop trigger if exists guard_shift_client on public.shifts;
create trigger guard_shift_client before insert or update on public.shifts
  for each row execute function public.guard_shift_client();

-- ===== The log: events and field changes, written only by the database =====
alter table public.shift_events add column if not exists kind text not null default 'event';
alter table public.shift_events add column if not exists field text;
alter table public.shift_events add column if not exists old_value text;
alter table public.shift_events add column if not exists new_value text;
alter table public.shift_events add column if not exists source text not null default 'portal';
alter table public.shift_events add column if not exists reason text;
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'shift_events_kind_check') then
    alter table public.shift_events add constraint shift_events_kind_check check (kind in ('event', 'change'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'shift_events_source_check') then
    alter table public.shift_events add constraint shift_events_source_check check (source in ('portal', 'worker', 'system'));
  end if;
end $$;
drop policy if exists "the log is written by the system" on public.shift_events;
create policy "the log is written by the system" on public.shift_events
  for insert to authenticated
  with check (not (actor is distinct from (select auth.uid())) and pg_trigger_depth() > 0);
-- Workers read their own shifts' events (not the internal field log).
drop policy if exists "workers read their shift events" on public.shift_events;
create policy "workers read their shift events" on public.shift_events
  for select to authenticated
  using (kind = 'event' and shift_id in (select s.id from public.shifts s where s.worker_id = (select auth.uid()) and s.status <> 'draft'));

create or replace function public.shift_source(p_shift public.shifts)
returns text
language sql
stable
security invoker
set search_path = ''
as $$
  select case when auth.uid() is null then 'system'
              when p_shift.worker_id = auth.uid() and not public.can('ops.roster', 'edit') then 'worker'
              else 'portal' end
$$;

create or replace function public.log_shift()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_src text := public.shift_source(new);
  nm text;
begin
  if tg_op = 'INSERT' then
    insert into public.shift_events (shift_id, actor, kind, summary, source)
    values (new.id, auth.uid(), 'event',
            'added the shift' || case when new.series_id is not null then ' (repeating)' else '' end
            || case when new.status = 'published' then ' and published it' else ' as a draft' end, v_src);
    if new.worker_id is not null then
      select coalesce(nullif(full_name, ''), email) into nm from public.profiles where id = new.worker_id;
      insert into public.shift_events (shift_id, actor, kind, summary, source) values (new.id, auth.uid(), 'event', 'gave the shift to ' || coalesce(nm, 'a worker'), v_src);
    end if;
    return null;
  end if;

  -- Events (what happened).
  if new.status <> old.status then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'event',
            case new.status when 'published' then 'published it (the worker is told)' when 'cancelled' then 'cancelled the shift' else 'moved it back to draft' end,
            'Status', initcap(old.status), initcap(new.status), v_src);
  end if;
  if new.worker_id is distinct from old.worker_id then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'event',
            case when new.worker_id is null then 'made it an open shift'
                 else 'gave the shift to ' || coalesce((select coalesce(nullif(full_name, ''), email) from public.profiles where id = new.worker_id), 'a worker') end,
            'Worker',
            coalesce((select coalesce(nullif(full_name, ''), email) from public.profiles where id = old.worker_id), 'Vacant'),
            coalesce((select coalesce(nullif(full_name, ''), email) from public.profiles where id = new.worker_id), 'Vacant'), v_src);
  end if;
  if new.notified_at is distinct from old.notified_at and new.notified_at is not null then
    insert into public.shift_events (shift_id, actor, kind, summary, source) values (new.id, auth.uid(), 'event', 'told the worker', 'system');
  end if;

  -- Field changes (before and after).
  if (new.starts_at at time zone 'Australia/Sydney')::date <> (old.starts_at at time zone 'Australia/Sydney')::date then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'moved it from ' || public.au_day(old.starts_at) || ' to ' || public.au_day(new.starts_at), 'Date', public.au_day(old.starts_at), public.au_day(new.starts_at), v_src);
  end if;
  if public.au_time(new.starts_at) <> public.au_time(old.starts_at) then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'changed the start time from ' || public.au_time(old.starts_at) || ' to ' || public.au_time(new.starts_at), 'Start time', public.au_time(old.starts_at), public.au_time(new.starts_at), v_src);
  end if;
  if public.au_time(new.ends_at) <> public.au_time(old.ends_at) or (new.ends_at at time zone 'Australia/Sydney')::date <> (old.ends_at at time zone 'Australia/Sydney')::date then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'changed the finish time from ' || public.au_time(old.ends_at) || ' to ' || public.au_time(new.ends_at), 'Finish time',
            public.au_day(old.ends_at) || ' ' || public.au_time(old.ends_at), public.au_day(new.ends_at) || ' ' || public.au_time(new.ends_at), v_src);
  end if;
  if new.break_minutes <> old.break_minutes then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'changed the break from ' || old.break_minutes || ' to ' || new.break_minutes || ' minutes', 'Break', old.break_minutes || ' min', new.break_minutes || ' min', v_src);
  end if;
  if new.client_id is distinct from old.client_id then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'changed the client', 'Client',
            coalesce((select name from public.car_clients where id = old.client_id), 'No client'), coalesce((select name from public.car_clients where id = new.client_id), 'No client'), v_src);
  end if;
  if new.location_id is distinct from old.location_id then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'changed the location', 'Location',
            coalesce((select address from public.client_locations where id = old.location_id), 'Not set'), coalesce((select address from public.client_locations where id = new.location_id), 'Not set'), v_src);
  end if;
  if new.service_id is distinct from old.service_id then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'changed the service', 'Service',
            coalesce((select label from public.client_services where id = old.service_id), 'Not set'), coalesce((select label from public.client_services where id = new.service_id), 'Not set'), v_src);
  end if;
  if new.notes is distinct from old.notes then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'updated the worker instructions', 'Worker instructions', left(coalesce(old.notes, ''), 300), left(coalesce(new.notes, ''), 300), v_src);
  end if;
  if new.shift_type is distinct from old.shift_type then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'changed the shift type', 'Shift type', replace(initcap(old.shift_type), '_', ' '), replace(initcap(new.shift_type), '_', ' '), v_src);
  end if;
  if new.vehicle_id is distinct from old.vehicle_id then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'changed the car', 'Vehicle',
            coalesce((select name || ' (' || rego || ')' from public.cars where id = old.vehicle_id), 'None'), coalesce((select name || ' (' || rego || ')' from public.cars where id = new.vehicle_id), 'None'), v_src);
  end if;
  if new.pay_group is distinct from old.pay_group then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'changed the pay group', 'Pay group', nullif(old.pay_group, ''), nullif(new.pay_group, ''), v_src);
  end if;
  if new.allowances is distinct from old.allowances then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'changed the allowances', 'Allowances', coalesce(nullif(array_to_string(old.allowances, ', '), ''), 'None'), coalesce(nullif(array_to_string(new.allowances, ', '), ''), 'None'), v_src);
  end if;
  if new.series_id is distinct from old.series_id then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', case when new.series_id is null then 'took it out of its repeating series' else 'made it part of a repeating series' end,
            'Repeats', case when old.series_id is null then 'No' else 'Yes' end, case when new.series_id is null then 'No' else 'Yes' end, v_src);
  end if;
  if (new.needs_worker_signature, new.needs_client_signature) is distinct from (old.needs_worker_signature, old.needs_client_signature) then
    insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, source)
    values (new.id, auth.uid(), 'change', 'changed the signatures needed', 'Signatures needed',
            concat_ws(', ', case when old.needs_worker_signature then 'worker' end, case when old.needs_client_signature then 'client' end),
            concat_ws(', ', case when new.needs_worker_signature then 'worker' end, case when new.needs_client_signature then 'client' end), v_src);
  end if;
  return null;
end;
$$;
revoke execute on function public.log_shift() from public, anon, authenticated;

-- ===== Worker responses =====
create table if not exists public.shift_responses (
  shift_id uuid primary key references public.shifts (id) on delete cascade,
  worker_id uuid not null references public.profiles (id) on delete restrict default auth.uid(),
  response text not null check (response in ('accepted', 'declined')),
  note text not null default '' check (length(note) <= 500),
  responded_at timestamptz not null default now()
);
alter table public.shift_responses enable row level security;
drop policy if exists "see shift responses" on public.shift_responses;
create policy "see shift responses" on public.shift_responses
  for select to authenticated
  using (worker_id = (select auth.uid()) or (select public.can('ops.roster', 'view')));
drop policy if exists "workers answer their shifts" on public.shift_responses;
create policy "workers answer their shifts" on public.shift_responses
  for insert to authenticated
  with check (worker_id = (select auth.uid())
              and shift_id in (select s.id from public.shifts s where s.worker_id = (select auth.uid()) and s.status = 'published' and s.ends_at > now()));
drop policy if exists "workers change their answer" on public.shift_responses;
create policy "workers change their answer" on public.shift_responses
  for update to authenticated
  using (worker_id = (select auth.uid()))
  with check (worker_id = (select auth.uid())
              and shift_id in (select s.id from public.shifts s where s.worker_id = (select auth.uid()) and s.status = 'published' and s.ends_at > now()));
drop policy if exists "people who roster clear answers" on public.shift_responses;
create policy "people who roster clear answers" on public.shift_responses
  for delete to authenticated
  using ((select public.can('ops.roster', 'edit')));
grant select, insert, update, delete on public.shift_responses to authenticated;

create or replace function public.log_shift_response()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.responded_at := now();
  new.worker_id := auth.uid();
  insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, new_value, reason, source)
  values (new.shift_id, auth.uid(), 'event', case when new.response = 'accepted' then 'accepted the shift' else 'declined the shift' end,
          'Worker response', case when tg_op = 'UPDATE' then initcap(old.response) end, initcap(new.response), nullif(new.note, ''), 'worker');
  return new;
end;
$$;
revoke execute on function public.log_shift_response() from public, anon, authenticated;
drop trigger if exists log_shift_response on public.shift_responses;
create trigger log_shift_response before insert or update on public.shift_responses
  for each row execute function public.log_shift_response();

-- A new worker, time or date means the old answer no longer counts.
create or replace function public.reset_shift_response()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.worker_id is distinct from old.worker_id or new.starts_at <> old.starts_at or new.ends_at <> old.ends_at or new.status = 'cancelled' then
    delete from public.shift_responses where shift_id = new.id;
  end if;
  return null;
end;
$$;
revoke execute on function public.reset_shift_response() from public, anon, authenticated;
drop trigger if exists reset_shift_response on public.shifts;
create trigger reset_shift_response after update on public.shifts
  for each row execute function public.reset_shift_response();

-- ===== Signatures =====
create table if not exists public.shift_signatures (
  id uuid primary key default gen_random_uuid(),
  shift_id uuid not null references public.shifts (id) on delete restrict,
  kind text not null check (kind in ('worker_in', 'worker_out', 'client', 'representative')),
  signer_name text not null check (length(trim(signer_name)) between 1 and 100),
  signer_role text not null default '' check (length(signer_role) <= 60),
  signature text not null check (signature like 'data:image/png;base64,%' and length(signature) <= 200000),
  captured_by uuid references public.profiles (id) default auth.uid(),
  signed_at timestamptz not null default now(),
  voided_at timestamptz,
  voided_by uuid references public.profiles (id),
  void_reason text check (length(void_reason) <= 500)
);
create index if not exists shift_signatures_shift on public.shift_signatures (shift_id);
alter table public.shift_signatures enable row level security;
drop policy if exists "see shift signatures" on public.shift_signatures;
create policy "see shift signatures" on public.shift_signatures
  for select to authenticated
  using ((select public.can('ops.roster', 'view'))
         or shift_id in (select s.id from public.shifts s where s.worker_id = (select auth.uid())));
drop policy if exists "add shift signatures" on public.shift_signatures;
create policy "add shift signatures" on public.shift_signatures
  for insert to authenticated
  with check (shift_id in (select s.id from public.shifts s where s.status = 'published'
                            and (s.worker_id = (select auth.uid()) or (select public.can('ops.roster', 'edit')))));
drop policy if exists "void shift signatures" on public.shift_signatures;
create policy "void shift signatures" on public.shift_signatures
  for update to authenticated
  using ((select public.can('ops.roster', 'edit')))
  with check ((select public.can('ops.roster', 'edit')));
-- No delete rule: signatures are kept.
grant select, insert, update on public.shift_signatures to authenticated;

create or replace function public.guard_shift_signature()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.captured_by := auth.uid();
    new.signed_at := now();
    new.voided_at := null;
    new.voided_by := null;
    new.void_reason := null;
    insert into public.shift_events (shift_id, actor, kind, summary, field, new_value, source)
    values (new.shift_id, auth.uid(), 'event', 'recorded a signature (' || replace(new.kind, '_', ' ') || ', ' || new.signer_name || ')', 'Signature', new.signer_name,
            case when exists (select 1 from public.shifts s where s.id = new.shift_id and s.worker_id = auth.uid()) then 'worker' else 'portal' end);
    return new;
  end if;
  if (to_jsonb(new) - 'voided_at' - 'voided_by' - 'void_reason') <> (to_jsonb(old) - 'voided_at' - 'voided_by' - 'void_reason') then
    raise exception 'A signature can''t be changed. Void it with a reason and record a new one.';
  end if;
  if old.voided_at is not null then
    raise exception 'That signature is already voided.';
  end if;
  if new.voided_at is null or length(trim(coalesce(new.void_reason, ''))) = 0 then
    raise exception 'Give a reason to void a signature.';
  end if;
  new.voided_at := now();
  new.voided_by := auth.uid();
  insert into public.shift_events (shift_id, actor, kind, summary, field, old_value, reason, source)
  values (new.shift_id, auth.uid(), 'event', 'voided a signature (' || replace(new.kind, '_', ' ') || ')', 'Signature', old.signer_name, new.void_reason, 'portal');
  return new;
end;
$$;
revoke execute on function public.guard_shift_signature() from public, anon, authenticated;
drop trigger if exists guard_shift_signature on public.shift_signatures;
create trigger guard_shift_signature before insert or update on public.shift_signatures
  for each row execute function public.guard_shift_signature();

-- ===== Internal rostering notes (never shown to the worker) =====
create table if not exists public.shift_notes (
  id uuid primary key default gen_random_uuid(),
  shift_id uuid not null references public.shifts (id) on delete restrict,
  author_id uuid references public.profiles (id) default auth.uid(),
  body text not null check (length(trim(body)) between 1 and 2000),
  created_at timestamptz not null default now()
);
create index if not exists shift_notes_shift on public.shift_notes (shift_id, created_at);
alter table public.shift_notes enable row level security;
drop policy if exists "people who roster read notes" on public.shift_notes;
create policy "people who roster read notes" on public.shift_notes
  for select to authenticated using ((select public.can('ops.roster', 'edit')));
drop policy if exists "people who roster add notes" on public.shift_notes;
create policy "people who roster add notes" on public.shift_notes
  for insert to authenticated with check ((select public.can('ops.roster', 'edit')) and author_id = (select auth.uid()));
-- No update or delete: notes are kept as written.
grant select, insert on public.shift_notes to authenticated;

-- ===== Trips (Cars module) linked to a shift =====
alter table public.car_trips add column if not exists shift_id uuid references public.shifts (id) on delete set null;
create index if not exists car_trips_shift on public.car_trips (shift_id) where shift_id is not null;
commit;
