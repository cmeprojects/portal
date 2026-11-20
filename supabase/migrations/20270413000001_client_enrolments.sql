-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 158): program enrolments (Phase 1 of the programs,
-- assessments and billing plan, approved 21 Nov 2026).
--   * A client can be in more than one named program (NDIS, Support at Home,
--     CHSP, Private, Other, or a program set up under them). Each enrolment has
--     its own status (active, paused, ended), dates and history.
--   * "Funded by" (car_clients.scheme) is kept as the main program's scheme and
--     follows the main enrolment by itself. When the main one ends, another open
--     one (active first, then paused) becomes main; none open = no "Funded by".
--   * A new service needs an active enrolment in its program. A paused or ended
--     program blocks new services and new client shifts on those dates. Client
--     shifts can't skip the check by leaving out the service. Shifts with no
--     client (internal work) aren't checked. Nothing existing is re-checked.
--   * Ending a program is refused while it still has open services, agreements
--     or budgets. Nothing is ended or deleted for you.
--   * Each organisation chooses which schemes it offers (client_schemes.offered).
--     Turning one off only stops new use; existing records stay as they are.
--   * Existing clients get enrolments from their services and "Funded by"
--     (see preview-158.sql). Safe to run again: nothing is added twice.
-- No new security definer function; checks run as the person. Changes are in
-- the client audit trail. Nothing is deleted.

-- 1. Which schemes this organisation offers; scheme and program changes recorded.
alter table public.client_schemes add column if not exists offered boolean not null default true;
alter table public.client_schemes add column if not exists id uuid not null default gen_random_uuid();
drop trigger if exists client_schemes_log on public.client_schemes;
create trigger client_schemes_log after insert or update on public.client_schemes
  for each row execute function public.log_car_setup('client_scheme');
drop trigger if exists client_programs_log on public.client_programs;
create trigger client_programs_log after insert or update on public.client_programs
  for each row execute function public.log_car_setup('client_program');

-- 2. Enrolments.
create table if not exists public.client_enrolments (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id),
  program_id uuid not null references public.client_programs (id),
  scheme text not null references public.client_schemes (key),
  status text not null default 'active' check (status in ('active', 'paused', 'ended')),
  starts_on date not null default ((now() at time zone 'Australia/Sydney')::date),
  paused_from date,
  paused_until date,
  pause_reason text not null default '' check (length(pause_reason) <= 300),
  ends_on date,
  end_reason text not null default '' check (length(end_reason) <= 300),
  is_main boolean not null default false,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  constraint client_enrolments_end_after_start check (ends_on is null or ends_on >= starts_on),
  constraint client_enrolments_ended_has_date check (status <> 'ended' or ends_on is not null),
  constraint client_enrolments_paused_has_date check (status <> 'paused' or paused_from is not null),
  constraint client_enrolments_pause_order check (paused_until is null or paused_from is null or paused_until >= paused_from),
  constraint client_enrolments_main_is_open check (not is_main or status <> 'ended')
);
create unique index if not exists client_enrolments_one_open on public.client_enrolments (client_id, program_id) where status <> 'ended';
create unique index if not exists client_enrolments_one_main on public.client_enrolments (client_id) where is_main;
create index if not exists client_enrolments_client on public.client_enrolments (client_id);

alter table public.client_enrolments enable row level security;
drop policy if exists "see enrolments of clients you can see" on public.client_enrolments;
create policy "see enrolments of clients you can see" on public.client_enrolments
  for select to authenticated using (exists (select 1 from public.car_clients c where c.id = client_id));
drop policy if exists "add enrolments" on public.client_enrolments;
create policy "add enrolments" on public.client_enrolments
  for insert to authenticated with check (public.can('clients.list', 'edit', client_id));
drop policy if exists "change enrolments" on public.client_enrolments;
create policy "change enrolments" on public.client_enrolments
  for update to authenticated using (public.can('clients.list', 'edit', client_id)) with check (public.can('clients.list', 'edit', client_id));
-- No delete: an enrolment is ended, never removed.
grant select, insert, update on public.client_enrolments to authenticated;
revoke all on public.client_enrolments from anon;

-- Requests from the portal (people) are checked; set-up scripts aren't.
create or replace function public.from_portal() returns boolean
language sql stable set search_path = '' as $$
  select session_user::text = 'authenticator' or current_user::text in ('authenticated', 'anon')
$$;

create or replace function public.guard_client_enrolment() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_api boolean := public.from_portal();
  v_prog public.client_programs;
  v_today date := (now() at time zone 'Australia/Sydney')::date;
  v_open text;
begin
  if tg_op = 'INSERT' then
    select * into v_prog from public.client_programs where id = new.program_id;
    if v_prog.id is null then
      raise exception 'Choose a program.';
    end if;
    new.scheme := v_prog.scheme;
    if v_api then
      if not v_prog.active then
        raise exception '% is switched off. Choose another program.', v_prog.name;
      end if;
      if not coalesce((select s.offered from public.client_schemes s where s.key = v_prog.scheme), false) then
        raise exception 'Your organisation doesn''t offer % at the moment.', (select s.label from public.client_schemes s where s.key = v_prog.scheme);
      end if;
      new.status := 'active';
      new.paused_from := null;
      new.paused_until := null;
      new.pause_reason := '';
      new.ends_on := null;
      new.end_reason := '';
      new.created_by := auth.uid();
      new.created_at := now();
    end if;
    if new.status <> 'ended' and exists (select 1 from public.client_enrolments e
                where e.client_id = new.client_id and e.program_id = new.program_id and e.status <> 'ended') then
      raise exception 'They''re already in %. Resume or end it instead.', v_prog.name;
    end if;
    if new.status = 'ended' then
      new.is_main := false;
    elsif new.is_main then
      update public.client_enrolments set is_main = false where client_id = new.client_id and is_main;
    elsif not exists (select 1 from public.client_enrolments e where e.client_id = new.client_id and e.is_main) then
      new.is_main := true; -- their first open program is the main one
    end if;
    return new;
  end if;

  -- Changes.
  if (new.client_id, new.program_id, new.scheme, new.created_by, new.created_at)
     is distinct from (old.client_id, old.program_id, old.scheme, old.created_by, old.created_at) then
    raise exception 'An enrolment stays with its client and program. End it and add a new one.';
  end if;
  if old.status = 'ended' then
    raise exception 'This program has ended. Add it again as a new enrolment instead.';
  end if;
  if new.starts_on is distinct from old.starts_on and exists (
       select 1 from public.client_services s
        where s.client_id = new.client_id and s.program_id = new.program_id and s.status <> 'ended' and s.start_date < new.starts_on) then
    raise exception 'Some of their services in this program start earlier. Choose a start date on or before %.',
      to_char((select min(s.start_date) from public.client_services s
                where s.client_id = new.client_id and s.program_id = new.program_id and s.status <> 'ended'), 'DD/MM/YYYY');
  end if;

  if new.status = 'paused' then
    if new.paused_from is null then
      raise exception 'Choose when the pause starts.';
    end if;
    if new.paused_from < new.starts_on then
      raise exception 'A pause can''t start before the program does (%).', to_char(new.starts_on, 'DD/MM/YYYY');
    end if;
    if new.paused_until is not null and new.paused_until < new.paused_from then
      raise exception 'The expected return can''t be before the pause starts.';
    end if;
  elsif new.status = 'active' then
    if old.status = 'paused' then -- resumed
      new.paused_from := null;
      new.paused_until := null;
      new.pause_reason := '';
    end if;
  elsif new.status = 'ended' then
    new.ends_on := coalesce(new.ends_on, v_today);
    if new.ends_on < new.starts_on then
      raise exception 'The end date can''t be before the program started (%).', to_char(new.starts_on, 'DD/MM/YYYY');
    end if;
    if v_api and length(trim(new.end_reason)) = 0 then
      raise exception 'Say why this program is ending.';
    end if;
    -- The person must be able to see everything that could still be open.
    if v_api and not (public.can('clients.services', 'view', new.client_id)
                      and public.can('clients.agreements', 'view', new.client_id)
                      and public.can('clients.funding', 'view', new.client_id)) then
      raise exception 'To end a program you need to see this client''s services, agreements and budgets. Ask a manager.';
    end if;
    select string_agg(x, '; ' order by x) into v_open from (
      select 'service "' || s.label || '"' as x
        from public.client_services s
       where s.client_id = new.client_id and s.program_id = new.program_id
         and s.status <> 'ended' and (s.end_date is null or s.end_date > new.ends_on)
      union all
      select 'agreement for "' || s.label || '"'
        from public.client_agreements a join public.client_services s on s.id = a.service_id
       where a.client_id = new.client_id and s.program_id = new.program_id and a.status <> 'ended'
      union all
      select 'budget for "' || s.label || '"'
        from public.client_funding f join public.client_services s on s.id = f.service_id
       where f.client_id = new.client_id and s.program_id = new.program_id
         and f.status = 'active' and (f.period_end is null or f.period_end > new.ends_on)
    ) b;
    if v_open is not null then
      raise exception 'Close or end these first: %.', v_open;
    end if;
    new.is_main := false;
  end if;

  if new.is_main and not old.is_main then
    update public.client_enrolments set is_main = false where client_id = new.client_id and is_main and id <> new.id;
  elsif old.is_main and not new.is_main and new.status <> 'ended' and pg_trigger_depth() = 1 then
    raise exception 'Choose another program as the main one instead.';
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_client_enrolment() from public, anon, authenticated;

-- After a change: keep a main program, and "Funded by" in step with it.
create or replace function public.sync_client_main() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_next uuid;
  v_scheme text;
begin
  if pg_trigger_depth() > 1 then
    return null;
  end if;
  if not exists (select 1 from public.client_enrolments e where e.client_id = new.client_id and e.is_main) then
    select e.id into v_next from public.client_enrolments e
     where e.client_id = new.client_id and e.status <> 'ended'
     order by (e.status = 'active') desc, e.starts_on, e.created_at
     limit 1;
    if v_next is not null then
      update public.client_enrolments set is_main = true where id = v_next;
    end if;
  end if;
  select e.scheme into v_scheme from public.client_enrolments e where e.client_id = new.client_id and e.is_main;
  perform set_config('portal.enrolment_sync', 'on', true);
  update public.car_clients set scheme = v_scheme where id = new.client_id and scheme is distinct from v_scheme;
  perform set_config('portal.enrolment_sync', '', true);
  return null;
end;
$$;
revoke execute on function public.sync_client_main() from public, anon, authenticated;

drop trigger if exists guard_client_enrolment on public.client_enrolments;
create trigger guard_client_enrolment before insert or update on public.client_enrolments
  for each row execute function public.guard_client_enrolment();
drop trigger if exists log_client_change on public.client_enrolments;
create trigger log_client_change before insert or update on public.client_enrolments
  for each row execute function public.log_client_change();
drop trigger if exists log_client_audit on public.client_enrolments;
create trigger log_client_audit after insert or update or delete on public.client_enrolments
  for each row execute function public.log_client_change();
drop trigger if exists sync_client_main on public.client_enrolments;
create trigger sync_client_main after insert or update on public.client_enrolments
  for each row execute function public.sync_client_main();

-- 3. "Funded by" follows the main program (not changed directly from the portal).
create or replace function public.guard_funded_by() returns trigger
language plpgsql set search_path = '' as $$
begin
  if not public.from_portal() or coalesce(current_setting('portal.enrolment_sync', true), '') = 'on' then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.scheme := null; -- set from their programs
  elsif new.scheme is distinct from old.scheme then
    raise exception 'Who funds a client follows their main program. Change it on their Programs card.';
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_funded_by() from public, anon, authenticated;
drop trigger if exists guard_funded_by on public.car_clients;
create trigger guard_funded_by before insert or update on public.car_clients
  for each row execute function public.guard_funded_by();

-- 4. A new service needs an active enrolment in its program.
create or replace function public.guard_service_enrolment() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_e public.client_enrolments;
  v_name text;
begin
  if not public.from_portal() then
    return new;
  end if;
  if tg_op = 'UPDATE' and new.program_id is not distinct from old.program_id and new.start_date is not distinct from old.start_date then
    return new;
  end if;
  select p.name into v_name from public.client_programs p where p.id = new.program_id;
  select * into v_e from public.client_enrolments e
   where e.client_id = new.client_id and e.program_id = new.program_id and e.status <> 'ended';
  if v_e.id is null then
    raise exception 'Add % to their programs first (Profile, Programs).', coalesce(v_name, 'the program');
  end if;
  if v_e.status = 'paused' then
    raise exception '% is paused for this client. Resume it to add services.', v_name;
  end if;
  if new.start_date < v_e.starts_on then
    raise exception 'They''re in % from %. Choose that date or later.', v_name, to_char(v_e.starts_on, 'DD/MM/YYYY');
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_service_enrolment() from public, anon, authenticated;
drop trigger if exists guard_service_enrolment on public.client_services;
create trigger guard_service_enrolment before insert or update on public.client_services
  for each row execute function public.guard_service_enrolment();

-- 5. Client shifts: the program must be active (not paused or ended) on the shift date.
create or replace function public.guard_shift_enrolment() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_day date;
  v_prog uuid;
  v_name text;
  v_e public.client_enrolments;
begin
  if not public.from_portal() or new.client_id is null or new.status = 'cancelled' then
    return new; -- internal shifts (no client) and set-up scripts aren't checked
  end if;
  if tg_op = 'UPDATE' and (new.starts_at, new.client_id, new.service_id) is not distinct from (old.starts_at, old.client_id, old.service_id) then
    return new; -- other changes to an existing shift
  end if;
  v_day := (new.starts_at at time zone 'Australia/Sydney')::date;
  if new.service_id is not null then
    select s.program_id, p.name into v_prog, v_name
      from public.client_services s join public.client_programs p on p.id = s.program_id where s.id = new.service_id;
    select * into v_e from public.client_enrolments e
     where e.client_id = new.client_id and e.program_id = v_prog and e.starts_on <= v_day and (e.ends_on is null or e.ends_on >= v_day)
     order by e.starts_on desc limit 1;
    if v_e.id is null then
      raise exception '% isn''t one of this client''s programs on %.', v_name, to_char(v_day, 'DD/MM/YYYY');
    end if;
    if v_e.status = 'paused' and v_day >= v_e.paused_from and (v_e.paused_until is null or v_day <= v_e.paused_until) then
      raise exception '%', v_name || ' is paused for this client from ' || to_char(v_e.paused_from, 'DD/MM/YYYY')
        || coalesce(' until ' || to_char(v_e.paused_until, 'DD/MM/YYYY'), '') || '.';
    end if;
  elsif not exists (select 1 from public.client_enrolments e
                     where e.client_id = new.client_id and e.starts_on <= v_day and (e.ends_on is null or e.ends_on >= v_day)
                       and not (e.status = 'paused' and v_day >= e.paused_from and (e.paused_until is null or v_day <= e.paused_until))) then
    raise exception 'This client has no active program on %. Choose one of their approved services, or add a program first.', to_char(v_day, 'DD/MM/YYYY');
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_shift_enrolment() from public, anon, authenticated;
drop trigger if exists guard_shift_enrolment on public.shifts;
create trigger guard_shift_enrolment before insert or update on public.shifts
  for each row execute function public.guard_shift_enrolment();

-- 6. Readiness: "No active program", and a service whose program isn't active.
create or replace function public.client_gaps(p_client uuid, p_program uuid, p_location uuid, p_consent_required boolean, p_consent_given date)
 returns text[] language sql stable set search_path = '' as $$
  select array_remove(array[
    case when (select status from public.car_clients where id = p_client) is distinct from 'active'
         then 'The client isn''t active yet.' end,
    case when p_program is null and not exists (select 1 from public.client_enrolments e where e.client_id = p_client and e.status <> 'ended')
         then 'No active program.' end,
    case when p_program is not null and not exists (select 1 from public.client_enrolments e where e.client_id = p_client and e.program_id = p_program and e.status = 'active')
         then 'This service''s program isn''t active for them (not added, paused or ended).' end,
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
    case when (select scheme from public.client_programs where id = p_program) = 'ndis'
              and coalesce((select ndis_number from public.client_details where client_id = p_client), '') = ''
         then 'The NDIS number is needed for an NDIS service.' end,
    case when (select scheme from public.client_programs where id = p_program) in ('support_at_home', 'chsp')
              and coalesce((select aged_care_id from public.client_details where client_id = p_client), '') = ''
         then 'The My Aged Care ID is needed for a Support at Home or CHSP service.' end,
    case when p_consent_required and p_consent_given is null
         then 'Consent is needed and hasn''t been recorded.' end
  ], null)
$$;

-- 7. Adding a client: their programs (one or more) are saved with them.
drop function if exists public.create_client_full(jsonb, jsonb, uuid, text);
create or replace function public.create_client_full(p_client jsonb, p_details jsonb, p_manager uuid default null, p_as text default 'case_manager',
                                                     p_programs uuid[] default '{}', p_main uuid default null, p_starts date default null)
 returns uuid language plpgsql set search_path = '' as $$
declare
  v_id uuid;
  v_main uuid := coalesce(p_main, p_programs[1]);
  v_p uuid;
begin
  if coalesce(cardinality(p_programs), 0) = 0 then
    raise exception 'Choose at least one program.';
  end if;
  if not (v_main = any (p_programs)) then
    raise exception 'The main program must be one of the programs chosen.';
  end if;
  insert into public.car_clients (name, title, given_name, middle_name, family_name, preferred_name, reference)
  values (p_client ->> 'name', coalesce(p_client ->> 'title', ''), p_client ->> 'given_name', coalesce(p_client ->> 'middle_name', ''), p_client ->> 'family_name',
          coalesce(p_client ->> 'preferred_name', ''), coalesce(p_client ->> 'reference', ''))
  returning id into v_id;
  insert into public.client_details (client_id, date_of_birth, gender, phone, email, home_address, state, ndis_number, aged_care_id)
  values (v_id, nullif(p_details ->> 'date_of_birth', '')::date, coalesce(p_details ->> 'gender', ''), coalesce(p_details ->> 'phone', ''), coalesce(p_details ->> 'email', ''),
          coalesce(p_details ->> 'home_address', ''), coalesce(p_details ->> 'state', ''), coalesce(p_details ->> 'ndis_number', ''), coalesce(p_details ->> 'aged_care_id', ''));
  -- The main program first, so it's the main one.
  insert into public.client_enrolments (client_id, program_id, starts_on, is_main)
  values (v_id, v_main, coalesce(p_starts, (now() at time zone 'Australia/Sydney')::date), true);
  foreach v_p in array p_programs loop
    if v_p <> v_main then
      insert into public.client_enrolments (client_id, program_id, starts_on)
      values (v_id, v_p, coalesce(p_starts, (now() at time zone 'Australia/Sydney')::date));
    end if;
  end loop;
  if p_manager is not null then
    insert into public.client_assignments (client_id, user_id, assigned_as) values (v_id, p_manager, coalesce(p_as, 'case_manager'));
  end if;
  return v_id;
end;
$$;
revoke execute on function public.create_client_full(jsonb, jsonb, uuid, text, uuid[], uuid, date) from public, anon;
grant execute on function public.create_client_full(jsonb, jsonb, uuid, text, uuid[], uuid, date) to authenticated;

-- 8. Existing clients: enrolments from their services and "Funded by" (as in
-- preview-158.sql; owner's decisions of 21 Nov 2026). Only what's missing is added.
do $backfill$
begin
  create temporary table backfill_158 on commit drop as
  with today as (select (now() at time zone 'Australia/Sydney')::date as d),
  svc as (
    select s.client_id, s.program_id, p.scheme, min(s.start_date) as first_start,
           count(*) filter (where s.status <> 'ended' and (s.end_date is null or s.end_date >= (select d from today))) as open_services,
           max(coalesce(s.end_date, (s.updated_at at time zone 'Australia/Sydney')::date)) as last_end
      from public.client_services s join public.client_programs p on p.id = s.program_id
     group by 1, 2, 3
  ),
  fb as (
    select c.id as client_id, c.scheme,
           (array_agg(p.id order by p.sort_order) filter (where p.active))[1] as program_id
      from public.car_clients c left join public.client_programs p on p.scheme = c.scheme
     where c.scheme is not null and not exists (select 1 from svc where svc.client_id = c.id and svc.scheme = c.scheme)
     group by 1, 2
  ),
  proposed as (
    select c.id as client_id, svc.program_id, svc.scheme, svc.first_start as starts_on,
           case when c.status = 'discharged' or svc.open_services = 0 then 'ended' else 'active' end as status,
           case when c.status = 'discharged' then greatest(svc.first_start, coalesce((c.archived_at at time zone 'Australia/Sydney')::date, svc.last_end))
                when svc.open_services = 0 then greatest(svc.first_start, svc.last_end) end as ends_on
      from svc join public.car_clients c on c.id = svc.client_id
    union all
    select c.id, fb.program_id, fb.scheme, (c.created_at at time zone 'Australia/Sydney')::date,
           case when c.status = 'discharged' then 'ended' else 'active' end,
           case when c.status = 'discharged' then greatest((c.created_at at time zone 'Australia/Sydney')::date, (c.archived_at at time zone 'Australia/Sydney')::date) end
      from fb join public.car_clients c on c.id = fb.client_id
     where fb.program_id is not null
  )
  select pr.*, row_number() over (partition by pr.client_id
                                  order by (pr.status = 'active') desc, (pr.scheme is not distinct from c.scheme) desc, pr.starts_on, pr.program_id) as pick
    from proposed pr join public.car_clients c on c.id = pr.client_id
   where not exists (select 1 from public.client_enrolments e where e.client_id = pr.client_id and e.program_id = pr.program_id);

  -- The main program first (only for clients without one yet), then the rest.
  insert into public.client_enrolments (client_id, program_id, status, starts_on, ends_on, end_reason, is_main)
  select b.client_id, b.program_id, b.status, b.starts_on, b.ends_on,
         case when b.status = 'ended' then 'Recorded when programs were added (update 158)' else '' end,
         true
    from backfill_158 b
   where b.pick = 1 and b.status = 'active'
     and not exists (select 1 from public.client_enrolments e where e.client_id = b.client_id and e.is_main);
  insert into public.client_enrolments (client_id, program_id, status, starts_on, ends_on, end_reason, is_main)
  select b.client_id, b.program_id, b.status, b.starts_on, b.ends_on,
         case when b.status = 'ended' then 'Recorded when programs were added (update 158)' else '' end,
         false
    from backfill_158 b
   where not exists (select 1 from public.client_enrolments e where e.client_id = b.client_id and e.program_id = b.program_id);
end
$backfill$;
