-- Staff Portal · © cmeproject. All rights reserved.
-- Update 88: Clients & Care step 3: contact details, date of birth,
-- identifiers and the client's people (emergency contacts, representatives).
-- Safe to run again. Undo: undo-88.sql. Run update 87 first.
begin;
-- cmeprojects (update 88): Clients & Care step 3: contact details, date of
-- birth and identifiers (one row per client), and the client's people:
-- emergency contacts, next of kin, nominees, guardians and authorised
-- representatives. All of it is sensitive: only people managers and the
-- system admin read or change it (support workers and team leaders don't).
-- Changes are in the change log (which item changed, never the values).
-- Nothing is deleted: people are ended (active off) instead.

create table if not exists public.client_details (
  client_id uuid primary key references public.car_clients (id) on delete restrict,
  org_id uuid not null default public.default_org_id(),
  date_of_birth date check (date_of_birth is null or date_of_birth between date '1900-01-01' and current_date),
  phone text not null default '' check (length(phone) <= 30),
  email text not null default '' check (length(email) <= 120),
  home_address text not null default '' check (length(home_address) <= 300),
  preferred_contact text not null default '' check (preferred_contact in ('', 'phone', 'sms', 'email', 'post', 'through_representative')),
  communication_needs text not null default '' check (length(communication_needs) <= 1000),
  ndis_number text not null default '' check (ndis_number = '' or ndis_number ~ '^[0-9]{9}$'),
  aged_care_id text not null default '' check (length(aged_care_id) <= 30),
  updated_by uuid,
  updated_at timestamptz not null default now()
);
alter table public.client_details enable row level security;

create table if not exists public.client_people (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id) on delete restrict,
  kind text not null check (kind in ('emergency', 'next_of_kin', 'nominee', 'guardian', 'representative')),
  name text not null check (length(trim(name)) between 1 and 100),
  relationship text not null default '' check (length(relationship) <= 60),
  phone text not null default '' check (length(phone) <= 30),
  email text not null default '' check (length(email) <= 120),
  authority text not null default '' check (length(authority) <= 500),
  primary_contact boolean not null default false,
  active boolean not null default true,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  constraint client_people_reachable check (phone <> '' or email <> '')
);
create index if not exists client_people_client on public.client_people (client_id);
alter table public.client_people enable row level security;

do $$
declare
  t text;
begin
  foreach t in array array['client_details', 'client_people'] loop
    execute format('drop policy if exists "people managers see %1$s" on public.%1$I', t);
    execute format('create policy "people managers see %1$s" on public.%1$I for select to authenticated using ((select public.can_manage_people()))', t);
    execute format('drop policy if exists "people managers add %1$s" on public.%1$I', t);
    execute format('create policy "people managers add %1$s" on public.%1$I for insert to authenticated with check ((select public.can_manage_people()))', t);
    execute format('drop policy if exists "people managers change %1$s" on public.%1$I', t);
    execute format('create policy "people managers change %1$s" on public.%1$I for update to authenticated using ((select public.can_manage_people())) with check ((select public.can_manage_people()))', t);
    execute format('grant select, insert, update on public.%I to authenticated', t);
  end loop;
end;
$$;

-- One change-log writer for every client table from here on.
-- SECURITY DEFINER so it can write the change log (owner approval needed; a
-- trigger function can't be called directly, and nobody can execute it).
-- It records which item changed, never the values (they're sensitive).
create or replace function public.log_client_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ref text := (select client_ref from public.car_clients where id = new.client_id);
  v_what text := coalesce(to_jsonb(new) ->> 'kind', to_jsonb(new) ->> 'label', '');
begin
  if tg_op = 'UPDATE' and new.client_id is distinct from old.client_id then
    raise exception 'This stays with its client. Add a new one for another client.';
  end if;
  new.updated_at := now();
  new.updated_by := auth.uid();
  perform public.write_audit(tg_table_name || case when tg_op = 'INSERT' then '_added' else '_changed' end,
    'client', new.client_id::text, jsonb_build_object('client', v_ref, 'item', v_what));
  return new;
end;
$$;
revoke execute on function public.log_client_change() from public, anon, authenticated;

drop trigger if exists log_client_change on public.client_details;
create trigger log_client_change before insert or update on public.client_details
  for each row execute function public.log_client_change();
drop trigger if exists log_client_change on public.client_people;
create trigger log_client_change before insert or update on public.client_people
  for each row execute function public.log_client_change();
commit;
