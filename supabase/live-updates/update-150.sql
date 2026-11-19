-- Staff Portal · © cmeproject. All rights reserved.
-- Update 150: SIL houses (behind the SIL houses switch, off until turned on).
-- Safe to run again. Undo: undo-150.sql.
begin;
insert into public.features (key, label, description, enabled, sort_order, premium, included) values
  ('sil_houses', 'SIL houses',
   'Supported Independent Living houses: residents, rooms, move-ins and move-outs, house notes for staff, and rostering by house.',
   false, 47, false, true)
on conflict (key) do nothing;

insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order, actions, grant_ready) values
  ('clients.houses', 'clients.list', 'clients', 'Houses (SIL)', 'normal', true, 266, '{view,edit}', true)
on conflict (id) do nothing;
update public.app_modules set status = 'active' where id = 'clients.houses' and status = 'retired'; -- run again after an undo
do $$
declare
  v_cm uuid := (select id from public.job_titles where name = 'Case Manager' and active limit 1);
  v_tl uuid := (select id from public.job_titles where name = 'Team Leader' and active limit 1);
  v_io uuid := (select id from public.job_titles where name = 'Intake & Assessment Officer' and active limit 1);
begin
  if not exists (select 1 from public.access_baselines where module_id = 'clients.houses' and revoked_at is null) then
    insert into public.access_baselines (access_level, module_id, actions, scope, note, by_system_admin)
    values ('manager', 'clients.houses', '{}', 'all', 'Houses default: managers', true);
    if v_tl is not null then
      insert into public.access_baselines (job_title_id, module_id, actions, scope, note, by_system_admin)
      values (v_tl, 'clients.houses', '{view,edit}', 'all', 'Houses default: team leaders', true);
    end if;
    if v_cm is not null then
      insert into public.access_baselines (job_title_id, module_id, actions, scope, note, by_system_admin)
      values (v_cm, 'clients.houses', '{view}', 'all', 'Houses default: case managers view', true);
    end if;
    if v_io is not null then
      insert into public.access_baselines (job_title_id, module_id, actions, scope, note, by_system_admin)
      values (v_io, 'clients.houses', '{view}', 'all', 'Houses default: intake view', true);
    end if;
  end if;
end $$;

create table if not exists public.sil_houses (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  name text not null check (length(trim(name)) between 1 and 80),
  kind text not null default 'sil' check (kind in ('sil', 'sda', 'respite', 'sta', 'other')),
  address text not null default '' check (length(address) <= 200),
  phone text not null default '' check (length(phone) <= 30),
  beds int check (beds is null or beds between 1 and 30),
  manager_id uuid references public.profiles (id),
  team_id uuid references public.teams (id),
  staff_notes text not null default '' check (length(staff_notes) <= 4000),
  active boolean not null default true,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index if not exists sil_houses_name on public.sil_houses (lower(name)) where active;

create table if not exists public.sil_house_residents (
  id uuid primary key default gen_random_uuid(),
  house_id uuid not null references public.sil_houses (id),
  client_id uuid not null references public.car_clients (id),
  room text not null default '' check (length(room) <= 40),
  moved_in date not null,
  moved_out date,
  move_reason text not null default '' check (length(move_reason) <= 500),
  added_by uuid default auth.uid(),
  added_at timestamptz not null default now(),
  ended_by uuid,
  check (moved_out is null or moved_out >= moved_in)
);
create unique index if not exists sil_house_residents_one_home on public.sil_house_residents (client_id) where moved_out is null;
create index if not exists sil_house_residents_house on public.sil_house_residents (house_id) where moved_out is null;

alter table public.shifts add column if not exists house_id uuid references public.sil_houses (id);
create index if not exists shifts_house on public.shifts (house_id, starts_at) where house_id is not null;

alter table public.sil_houses enable row level security;
alter table public.sil_house_residents enable row level security;
drop policy if exists "read houses" on public.sil_houses;
create policy "read houses" on public.sil_houses
  for select to authenticated
  using (public.feature_live('sil_houses')
         and ((select public.can('clients.houses', 'view'))
              or id in (select s.house_id from public.shifts s where s.worker_id = (select auth.uid()) and s.status = 'published')));
drop policy if exists "add houses" on public.sil_houses;
create policy "add houses" on public.sil_houses
  for insert to authenticated with check (public.feature_live('sil_houses') and (select public.can('clients.houses', 'edit')));
drop policy if exists "change houses" on public.sil_houses;
create policy "change houses" on public.sil_houses
  for update to authenticated
  using (public.feature_live('sil_houses') and (select public.can('clients.houses', 'edit')))
  with check (public.feature_live('sil_houses') and (select public.can('clients.houses', 'edit')));
grant select, insert, update on public.sil_houses to authenticated;
revoke all on public.sil_houses from anon;

drop policy if exists "read house residents" on public.sil_house_residents;
create policy "read house residents" on public.sil_house_residents
  for select to authenticated
  using (public.feature_live('sil_houses')
         and ((select public.can('clients.houses', 'view')) or public.can('clients.list', 'view', client_id)));
drop policy if exists "add house residents" on public.sil_house_residents;
create policy "add house residents" on public.sil_house_residents
  for insert to authenticated with check (public.feature_live('sil_houses') and (select public.can('clients.houses', 'edit')));
drop policy if exists "change house residents" on public.sil_house_residents;
create policy "change house residents" on public.sil_house_residents
  for update to authenticated
  using (public.feature_live('sil_houses') and (select public.can('clients.houses', 'edit')))
  with check (public.feature_live('sil_houses') and (select public.can('clients.houses', 'edit')));
grant select, insert, update on public.sil_house_residents to authenticated;
revoke all on public.sil_house_residents from anon;

create or replace function public.guard_sil_house() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.name := trim(new.name);
  new.updated_at := now();
  if tg_op = 'INSERT' then
    new.created_by := coalesce(auth.uid(), new.created_by);
    new.created_at := now();
  else
    new.created_by := old.created_by; new.created_at := old.created_at;
    if old.active and not new.active and exists (select 1 from public.sil_house_residents r where r.house_id = new.id and r.moved_out is null) then
      raise exception 'Move the residents out before closing the house.';
    end if;
  end if;
  if new.manager_id is not null and not exists (select 1 from public.profiles p where p.id = new.manager_id and p.active) then
    raise exception 'Choose an active staff member as the house manager.';
  end if;
  if new.beds is not null and new.beds < (select count(*) from public.sil_house_residents r where r.house_id = new.id and r.moved_out is null) then
    raise exception 'The house has more residents than that. Move someone out first.';
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_sil_house() from public, anon, authenticated;
drop trigger if exists guard_sil_house on public.sil_houses;
create trigger guard_sil_house before insert or update on public.sil_houses
  for each row execute function public.guard_sil_house();

create or replace function public.guard_sil_resident() returns trigger
language plpgsql set search_path = '' as $$
declare
  h public.sil_houses;
  v_home text;
begin
  select * into h from public.sil_houses where id = new.house_id;
  if tg_op = 'INSERT' then
    new.added_by := coalesce(auth.uid(), new.added_by); new.added_at := now(); new.ended_by := null;
    if not h.active then
      raise exception 'That house is closed.';
    end if;
    if coalesce((select c.status from public.car_clients c where c.id = new.client_id), 'discharged') = 'discharged' then
      raise exception 'That client is archived.';
    end if;
    select hh.name into v_home from public.sil_house_residents r join public.sil_houses hh on hh.id = r.house_id
     where r.client_id = new.client_id and r.moved_out is null;
    if v_home is not null then
      raise exception 'They already live at %. Move them out of there first.', v_home;
    end if;
    if new.moved_out is null and h.beds is not null
       and (select count(*) from public.sil_house_residents r where r.house_id = new.house_id and r.moved_out is null) >= h.beds then
      raise exception '% is full (% beds).', h.name, h.beds;
    end if;
    if new.moved_in > public.local_today() + 90 then
      raise exception 'A move-in can be at most 90 days ahead.';
    end if;
  else
    if new.house_id <> old.house_id or new.client_id <> old.client_id or new.added_by is distinct from old.added_by or new.added_at <> old.added_at then
      raise exception 'To move someone to another house, move them out here and in there.';
    end if;
    if old.moved_out is not null and new.moved_out is distinct from old.moved_out then
      raise exception 'They have already moved out.';
    end if;
    if new.moved_out is not null and old.moved_out is null then
      new.ended_by := auth.uid();
    end if;
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_sil_resident() from public, anon, authenticated;
drop trigger if exists guard_sil_resident on public.sil_house_residents;
create trigger guard_sil_resident before insert or update on public.sil_house_residents
  for each row execute function public.guard_sil_resident();

create or replace function public.guard_shift_house() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.house_id is not null and (tg_op = 'INSERT' or new.house_id is distinct from old.house_id) then
    if not public.feature_live('sil_houses') then
      raise exception 'SIL houses is switched off.';
    end if;
    if not exists (select 1 from public.sil_houses h where h.id = new.house_id and h.active) then
      raise exception 'That house is closed.';
    end if;
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_shift_house() from public, anon, authenticated;
drop trigger if exists guard_shift_house on public.shifts;
create trigger guard_shift_house before insert or update of house_id on public.shifts
  for each row execute function public.guard_shift_house();
commit;
