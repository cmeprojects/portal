-- Staff Portal · © cmeproject. All rights reserved.
-- Update 87: Clients & Care step 2: service locations. Safe to run again.
-- Undo: undo-87.sql. Run update 86 first.
begin;
-- cmeprojects (update 87): Clients & Care step 2: service locations. A client
-- can have several places where support happens (home, day program, a
-- relative's house). Each has an address, access instructions for workers,
-- optional from and to dates, and must be approved by a people manager
-- before it counts (rostering will only use approved, current locations).
--
--   * People managers and the system admin add, change and approve them.
--   * Locations are never deleted: give an end date instead (history kept).
--   * Changing the address of an approved location makes it unapproved again
--     (a manager approves the new address).
--   * Every change is in the change log.
--   * Staff and team leaders see the approved, current locations of their own
--     teams' clients (address and access instructions), and nothing else.
-- Nothing existing changes.

create table if not exists public.client_locations (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id) on delete restrict,
  label text not null default 'Home' check (length(trim(label)) between 1 and 60),
  address text not null check (length(trim(address)) between 3 and 200),
  suburb text not null default '' check (length(suburb) <= 60),
  state text not null default '' check (state in ('', 'NSW', 'VIC', 'QLD', 'WA', 'SA', 'TAS', 'ACT', 'NT')),
  postcode text not null default '' check (postcode = '' or postcode ~ '^[0-9]{4}$'),
  access_notes text not null default '' check (length(access_notes) <= 1000),
  from_date date,
  to_date date,
  approved boolean not null default false,
  approved_at timestamptz,
  approved_by uuid references public.profiles (id) on delete set null,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  constraint client_locations_dates check (to_date is null or from_date is null or to_date >= from_date)
);
create index if not exists client_locations_client on public.client_locations (client_id);
alter table public.client_locations enable row level security;

drop policy if exists "people managers see client locations" on public.client_locations;
create policy "people managers see client locations" on public.client_locations
  for select to authenticated using ((select public.can_manage_people()));
drop policy if exists "people managers add client locations" on public.client_locations;
create policy "people managers add client locations" on public.client_locations
  for insert to authenticated with check ((select public.can_manage_people()));
drop policy if exists "people managers change client locations" on public.client_locations;
create policy "people managers change client locations" on public.client_locations
  for update to authenticated using ((select public.can_manage_people())) with check ((select public.can_manage_people()));
-- No delete rule: end a location with a "to" date instead.

-- Staff and team leaders: approved, current locations of their teams' clients.
drop policy if exists "staff see their teams' approved client locations" on public.client_locations;
create policy "staff see their teams' approved client locations" on public.client_locations
  for select to authenticated
  using (approved
     and (from_date is null or from_date <= (select public.local_today()))
     and (to_date is null or to_date >= (select public.local_today()))
     and (select public.is_member())
     and exists (
       select 1 from public.client_teams ct
        where ct.client_id = client_locations.client_id
          and (exists (select 1 from public.team_members tm where tm.team_id = ct.team_id and tm.user_id = (select auth.uid()))
               or exists (select 1 from public.team_leaders tl where tl.team_id = ct.team_id and tl.user_id = (select auth.uid())))));

grant select, insert, update on public.client_locations to authenticated;

-- SECURITY DEFINER so it can write the change log (owner approval needed; a
-- trigger function can't be called directly, and nobody can execute it).
create or replace function public.guard_client_location()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ref text := (select client_ref from public.car_clients where id = new.client_id);
  v_moved boolean;
begin
  if tg_op = 'UPDATE' and new.client_id is distinct from old.client_id then
    raise exception 'A location stays with its client. Add a new one for another client.';
  end if;
  new.updated_at := now();
  new.updated_by := auth.uid();
  v_moved := tg_op = 'UPDATE' and (new.address, new.suburb, new.state, new.postcode)
                                is distinct from (old.address, old.suburb, old.state, old.postcode);
  if v_moved and old.approved then
    new.approved := false; -- a new address always needs approving again
  end if;
  if new.approved and tg_op = 'UPDATE' and old.approved then
    new.approved_at := old.approved_at; -- who approved it can't be rewritten
    new.approved_by := old.approved_by;
  elsif new.approved then
    new.approved_at := now();
    new.approved_by := auth.uid();
  else
    new.approved_at := null;
    new.approved_by := null;
  end if;
  perform public.write_audit(
    case when tg_op = 'INSERT' then 'client_location_added'
         when new.approved and not old.approved then 'client_location_approved'
         when v_moved and old.approved then 'client_location_needs_approval'
         else 'client_location_changed' end,
    'client', new.client_id::text,
    jsonb_build_object('client', v_ref, 'location', new.label, 'approved', new.approved,
                       'from', new.from_date, 'to', new.to_date));
  return new;
end;
$$;
revoke execute on function public.guard_client_location() from public, anon, authenticated;

drop trigger if exists guard_client_location on public.client_locations;
create trigger guard_client_location before insert or update on public.client_locations
  for each row execute function public.guard_client_location();
commit;
