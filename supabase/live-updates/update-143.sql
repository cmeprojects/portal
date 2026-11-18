-- Staff Portal · © cmeproject. All rights reserved.
-- Update 143: approved services and the service catalogue.
-- Safe to run again. Undo: undo-143.sql.
begin;
insert into public.shift_types (key, label, sort_order, used_for)
values ('shopping_assistance', 'Shopping assistance', 25, 'client')
on conflict (key) do nothing;

create table if not exists public.service_catalogue (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  name text not null check (length(trim(name)) between 1 and 80),
  description text not null default '' check (length(description) <= 1000),
  active boolean not null default true,
  schemes text[] not null default '{}',
  classification text not null default '' check (length(classification) <= 60),
  shift_types text[] not null default '{}',
  sort_order int not null default 100,
  promoted_from uuid references public.client_services (id) on delete set null,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid default auth.uid(),
  updated_at timestamptz not null default now()
);
create unique index if not exists service_catalogue_name on public.service_catalogue (org_id, lower(name));
alter table public.service_catalogue enable row level security;
drop policy if exists "members read the service catalogue" on public.service_catalogue;
create policy "members read the service catalogue" on public.service_catalogue
  for select to authenticated using ((select public.is_member()));
drop policy if exists "manager administrators add catalogue services" on public.service_catalogue;
create policy "manager administrators add catalogue services" on public.service_catalogue
  for insert to authenticated with check ((select public.is_system_admin()) or (select public.is_manager_admin()));
drop policy if exists "manager administrators change catalogue services" on public.service_catalogue;
create policy "manager administrators change catalogue services" on public.service_catalogue
  for update to authenticated using ((select public.is_system_admin()) or (select public.is_manager_admin()))
  with check ((select public.is_system_admin()) or (select public.is_manager_admin()));
-- No delete: switched off instead, so client services keep their history.
grant select, insert, update on public.service_catalogue to authenticated;
revoke all on public.service_catalogue from anon;

create or replace function public.guard_service_catalogue() returns trigger
language plpgsql set search_path = '' as $$
begin
  if exists (select 1 from unnest(new.shift_types) t(k) where not exists (select 1 from public.shift_types s where s.key = t.k and s.used_for in ('client', 'both'))) then
    raise exception 'Choose client shift types only.';
  end if;
  if exists (select 1 from unnest(new.schemes) t(k) where not exists (select 1 from public.client_schemes s where s.key = t.k)) then
    raise exception 'Choose programs from the list.';
  end if;
  new.updated_at := now();
  new.updated_by := auth.uid();
  if tg_op = 'UPDATE' then
    new.created_by := old.created_by;
    new.created_at := old.created_at;
    new.promoted_from := old.promoted_from;
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_service_catalogue() from public, anon, authenticated;
drop trigger if exists guard_service_catalogue on public.service_catalogue;
create trigger guard_service_catalogue before insert or update on public.service_catalogue
  for each row execute function public.guard_service_catalogue();

-- The starting catalogue: separate services, each its own entry. Descriptions
-- are plain starting points for the organisation to edit (not official definitions).
insert into public.service_catalogue (name, description, shift_types, sort_order)
select x.n, x.d, x.t, x.o
  from (values
    ('Community Access', 'Assistance to access and participate in community activities.', array['community_access', 'social_activities', 'group_activity'], 10),
    ('Shopping Assistance', 'Assistance with shopping activities and related support.', array['shopping_assistance'], 20),
    ('Domestic Assistance', 'Assistance with household tasks.', array['domestic'], 30),
    ('Personal Care', 'Assistance with personal care activities.', array['personal_care'], 40),
    ('Gardening', '', array['gardening'], 50),
    ('Respite Care', '', array['respite_care', 'sleepover', 'overnight'], 60),
    ('Support Coordination', '', array['support_coordination'], 70)
  ) as x(n, d, t, o)
 where not exists (select 1 from public.service_catalogue c where lower(c.name) = lower(x.n));

-- Client services: where each came from.
alter table public.client_services add column if not exists catalogue_id uuid references public.service_catalogue (id);
alter table public.client_services add column if not exists origin text not null default 'legacy';
alter table public.client_services drop constraint if exists client_services_origin_check;
alter table public.client_services add constraint client_services_origin_check check (origin in ('catalogue', 'custom', 'legacy'));
alter table public.client_services add column if not exists description text not null default '';
alter table public.client_services drop constraint if exists client_services_description_check;
alter table public.client_services add constraint client_services_description_check check (length(description) <= 1000);
alter table public.client_services add column if not exists shift_types text[] not null default '{}';
-- No duplicates: the same catalogue service, or the same custom name, twice under one program while current.
create unique index if not exists client_services_one_per_catalogue on public.client_services (client_id, catalogue_id, program_id) where catalogue_id is not null and status <> 'ended';
create unique index if not exists client_services_one_per_custom on public.client_services (client_id, lower(label), program_id) where origin = 'custom' and status <> 'ended';

-- The shift types a service covers: the catalogue's (always current), or the service's own.
create or replace function public.service_shift_types(p_service uuid) returns text[]
language sql stable set search_path = '' as $$
  select coalesce(case when s.catalogue_id is not null then c.shift_types else s.shift_types end, '{}')
    from public.client_services s left join public.service_catalogue c on c.id = s.catalogue_id
   where s.id = p_service
$$;
grant execute on function public.service_shift_types(uuid) to authenticated;
revoke execute on function public.service_shift_types(uuid) from anon;

CREATE OR REPLACE FUNCTION public.guard_client_service()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  v_gaps text[];
  v_cat public.service_catalogue;
begin
  -- cmeprojects (update 143): where the service came from, and its name and description.
  if tg_op = 'INSERT' then
    if new.catalogue_id is not null then
      select * into v_cat from public.service_catalogue where id = new.catalogue_id;
      if v_cat.id is null or not v_cat.active then
        raise exception 'That service isn''t in the catalogue any more. Choose another.';
      end if;
      if cardinality(v_cat.schemes) > 0 and not exists (select 1 from public.client_programs p where p.id = new.program_id and p.scheme = any (v_cat.schemes)) then
        raise exception '"%" isn''t offered under that program.', v_cat.name;
      end if;
      new.origin := 'catalogue';
      new.label := v_cat.name;
      new.description := v_cat.description;
      new.shift_types := '{}';
    elsif new.origin = 'legacy' then
      -- Only set-up scripts add older-style entries; people choose the catalogue or add a custom service.
      if current_user = 'authenticated' then
        raise exception 'Choose a service from the catalogue, or add other service.';
      end if;
    else
      new.origin := 'custom';
      if length(trim(coalesce(new.description, ''))) = 0 then
        raise exception 'Describe the service.';
      end if;
      if cardinality(new.shift_types) = 0 then
        raise exception 'Choose the shift types this service covers.';
      end if;
    end if;
  else
    if new.catalogue_id is distinct from old.catalogue_id or new.origin is distinct from old.origin then
      raise exception 'Where a service came from can''t be changed. Add a new service instead.';
    end if;
    if new.origin = 'catalogue' and (new.label is distinct from old.label or new.description is distinct from old.description or new.shift_types <> '{}') then
      raise exception 'A catalogue service keeps its name, description and shift types (set in the catalogue).';
    end if;
    if new.origin = 'custom' and cardinality(new.shift_types) = 0 then
      raise exception 'Choose the shift types this service covers.';
    end if;
  end if;
  if exists (select 1 from unnest(new.shift_types) t(k) where not exists (select 1 from public.shift_types s where s.key = t.k and s.used_for in ('client', 'both'))) then
    raise exception 'Choose client shift types only.';
  end if;
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

CREATE OR REPLACE FUNCTION public.guard_shift_client()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  v_service public.client_services;
  v_types text[];
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
