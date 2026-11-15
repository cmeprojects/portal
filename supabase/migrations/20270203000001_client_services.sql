-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 90): Clients & Care step 5: service arrangements and
-- the readiness check future rostering uses.
--
--   * client_services: program (from the programs list), type of service,
--     start and end, status (planned, active, on hold, ended), the approved
--     location it happens at, scheduling restrictions, and consent (needed,
--     given on). A client can have several. Never deleted: they're ended.
--   * A service can only be made active when the client is ready for it:
--     client active; the location approved and current; an emergency
--     contact; safety answered (an alert or "No known safety alerts"); date
--     of birth when the program needs it; consent when it's needed.
--   * client_service_gaps(service) lists what's missing for one service, and
--     client_readiness(client) for the whole client (no active service is a
--     gap too). Read-only; they use the caller's own access. A profile alone
--     is never "ready".
--   * People managers and the system admin only. Every change is in the
--     change log (no values).

create table if not exists public.client_services (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id) on delete restrict,
  program_id uuid not null references public.client_programs (id) on delete restrict,
  label text not null check (length(trim(label)) between 1 and 80),
  status text not null default 'planned' check (status in ('planned', 'active', 'on_hold', 'ended')),
  start_date date not null,
  end_date date,
  location_id uuid not null references public.client_locations (id) on delete restrict,
  scheduling_notes text not null default '' check (length(scheduling_notes) <= 1000),
  consent_required boolean not null default false,
  consent_given_on date,
  consent_note text not null default '' check (length(consent_note) <= 500),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  constraint client_services_dates check (end_date is null or end_date >= start_date)
);
create index if not exists client_services_client on public.client_services (client_id);
alter table public.client_services enable row level security;

drop policy if exists "people managers see client_services" on public.client_services;
create policy "people managers see client_services" on public.client_services
  for select to authenticated using ((select public.can_manage_people()));
drop policy if exists "people managers add client_services" on public.client_services;
create policy "people managers add client_services" on public.client_services
  for insert to authenticated with check ((select public.can_manage_people()));
drop policy if exists "people managers change client_services" on public.client_services;
create policy "people managers change client_services" on public.client_services
  for update to authenticated using ((select public.can_manage_people())) with check ((select public.can_manage_people()));
grant select, insert, update on public.client_services to authenticated;

-- What's missing before a service can run (plain words; empty = ready).
create or replace function public.client_gaps(p_client uuid, p_program uuid, p_location uuid, p_consent_required boolean, p_consent_given date)
returns text[]
language sql
stable
security invoker
set search_path = ''
as $$
  select array_remove(array[
    case when (select status from public.car_clients where id = p_client) is distinct from 'active'
         then 'The client isn''t active yet.' end,
    case when not exists (select 1 from public.client_locations l
                           where l.id = p_location and l.client_id = p_client and l.approved
                             and (l.from_date is null or l.from_date <= public.local_today())
                             and (l.to_date is null or l.to_date >= public.local_today()))
         then 'The service location isn''t approved and current.' end,
    case when not exists (select 1 from public.client_people where client_id = p_client and kind = 'emergency' and active)
         then 'No emergency contact.' end,
    case when not exists (select 1 from public.client_alerts where client_id = p_client and active)
         then 'Safety isn''t answered (add an alert, or record "No known safety alerts").' end,
    case when coalesce((select needs_dob from public.client_programs where id = p_program), false)
              and (select date_of_birth from public.client_details where client_id = p_client) is null
         then 'Date of birth is needed for this program.' end,
    case when p_consent_required and p_consent_given is null
         then 'Consent is needed and hasn''t been recorded.' end
  ], null)
$$;

create or replace function public.client_service_gaps(p_service uuid)
returns text[]
language sql
stable
security invoker
set search_path = ''
as $$
  select public.client_gaps(s.client_id, s.program_id, s.location_id, s.consent_required, s.consent_given_on)
         || case when s.status <> 'active' then array['The service isn''t active.']
                 when s.start_date > public.local_today() then array['The service hasn''t started yet.']
                 when s.end_date < public.local_today() then array['The service has ended.']
                 else array[]::text[] end
    from public.client_services s
   where s.id = p_service
$$;

create or replace function public.client_readiness(p_client uuid)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with svc as (
    select s.id, s.label, public.client_service_gaps(s.id) as gaps
      from public.client_services s
     where s.client_id = p_client and s.status = 'active'
  )
  select jsonb_build_object(
    'ready', exists (select 1 from svc where cardinality(gaps) = 0),
    'services', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'label', label, 'gaps', to_jsonb(gaps))) from svc), '[]'::jsonb),
    'gaps', case when exists (select 1 from svc) then '[]'::jsonb
                 else to_jsonb(public.client_gaps(p_client, null, null, false, null) || array['No active service.']) end)
$$;

do $$
declare
  f text;
begin
  foreach f in array array['client_gaps(uuid, uuid, uuid, boolean, date)', 'client_service_gaps(uuid)', 'client_readiness(uuid)'] loop
    execute format('revoke execute on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end;
$$;

-- Save rules for a service.
create or replace function public.guard_client_service()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
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
$$;
revoke execute on function public.guard_client_service() from public, anon, authenticated;

drop trigger if exists a_guard_client_service on public.client_services;
create trigger a_guard_client_service before insert or update on public.client_services
  for each row execute function public.guard_client_service();
drop trigger if exists log_client_change on public.client_services;
create trigger log_client_change before insert or update on public.client_services
  for each row execute function public.log_client_change();
