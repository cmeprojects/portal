-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 85): Clients & Care step 1: the client record, its
-- permanent reference, status, and the programs list. Builds on the existing
-- client list (car_clients), used by Cars, built features, tasks and teams;
-- no second client table.
--
--   * Every client gets a reference CL-00001, CL-00002 ... made by the
--     database (a sequence): unique, permanent, never reused, never edited.
--     Existing clients get theirs in alphabetical order of name.
--   * Status: pending, active, suspended or discharged. Existing clients start
--     as pending, to be checked before they're made active (owner decision).
--     Only people managers and the system admin change status; each change
--     is in the change log.
--   * Preferred name.
--   * Programs (NDIS, Support at Home, Private, Other to start): the system
--     admin adds, renames or deactivates them; nobody deletes them. "Needs
--     date of birth" marks the programs where date of birth is required
--     (used from step 3).
--   * Staff and team leaders see the basic record (name, preferred name,
--     reference, status) of clients linked to their own teams.
-- Nothing else changes: existing policies, the "shown/hidden" switch and
-- every module using clients keep working as before.

-- Programs -----------------------------------------------------------------
create table if not exists public.client_programs (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  name text not null check (length(trim(name)) between 1 and 80),
  needs_dob boolean not null default false,
  active boolean not null default true,
  sort_order integer not null default 0,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);
create unique index if not exists client_programs_name on public.client_programs (org_id, lower(trim(name)));
alter table public.client_programs enable row level security;

drop policy if exists "members read programs" on public.client_programs;
create policy "members read programs" on public.client_programs
  for select to authenticated using ((select public.is_member()));
drop policy if exists "the system admin adds programs" on public.client_programs;
create policy "the system admin adds programs" on public.client_programs
  for insert to authenticated with check ((select public.is_system_admin()));
drop policy if exists "the system admin changes programs" on public.client_programs;
create policy "the system admin changes programs" on public.client_programs
  for update to authenticated using ((select public.is_system_admin())) with check ((select public.is_system_admin()));
-- No delete rule: programs are deactivated, never deleted.
grant select, insert, update on public.client_programs to authenticated;

insert into public.client_programs (name, needs_dob, sort_order)
select v.name, v.needs_dob, v.sort_order
  from (values ('NDIS', true, 10), ('Support at Home', true, 20), ('Private', false, 30), ('Other', false, 40)) v(name, needs_dob, sort_order)
 where not exists (select 1 from public.client_programs p where lower(p.name) = lower(v.name));

-- Client record ------------------------------------------------------------
alter table public.car_clients
  add column if not exists client_ref text,
  add column if not exists status text not null default 'pending',
  add column if not exists preferred_name text not null default '',
  add column if not exists status_changed_at timestamptz,
  add column if not exists status_changed_by uuid references public.profiles (id) on delete set null;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'car_clients_status_check') then
    alter table public.car_clients add constraint car_clients_status_check
      check (status in ('pending', 'active', 'suspended', 'discharged'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'car_clients_preferred_name_check') then
    alter table public.car_clients add constraint car_clients_preferred_name_check
      check (length(preferred_name) <= 80);
  end if;
end;
$$;

create sequence if not exists public.client_ref_seq;
grant usage on sequence public.client_ref_seq to authenticated;

create or replace function public.next_client_ref()
returns text
language sql
volatile
set search_path = ''
as $$
  select 'CL-' || case when n < 100000 then lpad(n::text, 5, '0') else n::text end
    from (select nextval('public.client_ref_seq') as n) s
$$;
revoke execute on function public.next_client_ref() from public, anon;
grant execute on function public.next_client_ref() to authenticated;

-- Existing clients, in alphabetical order (only those without a reference).
do $$
declare
  c record;
begin
  for c in select id from public.car_clients where client_ref is null order by lower(name), created_at, id loop
    update public.car_clients set client_ref = public.next_client_ref() where id = c.id;
  end loop;
end;
$$;

alter table public.car_clients alter column client_ref set not null;
create unique index if not exists car_clients_client_ref on public.car_clients (client_ref);

-- SECURITY DEFINER so it can write the change log (owner approval needed; a
-- trigger function can't be called directly, and nobody can execute it).
create or replace function public.guard_client_record()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.client_ref := public.next_client_ref(); -- always made here, never chosen
    if new.status <> 'pending' and auth.uid() is not null and not public.can_manage_people() then
      raise exception 'Only people managers can set a client''s status.';
    end if;
    return new;
  end if;
  if new.client_ref is distinct from old.client_ref then
    raise exception 'A client''s reference never changes.';
  end if;
  if new.status is distinct from old.status then
    if auth.uid() is not null and not public.can_manage_people() then
      raise exception 'Only people managers can change a client''s status.';
    end if;
    new.status_changed_at := now();
    new.status_changed_by := auth.uid();
    perform public.write_audit('client_status', 'client', new.id::text,
      jsonb_build_object('client', new.client_ref, 'from', old.status, 'to', new.status));
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_client_record() from public, anon, authenticated;

drop trigger if exists guard_client_record on public.car_clients;
create trigger guard_client_record before insert or update on public.car_clients
  for each row execute function public.guard_client_record();

-- Staff and team leaders: the clients of their own teams (basic record).
drop policy if exists "staff see their teams' clients" on public.car_clients;
create policy "staff see their teams' clients" on public.car_clients
  for select to authenticated
  using ((select public.is_member()) and exists (
    select 1 from public.client_teams ct
     where ct.client_id = car_clients.id
       and (exists (select 1 from public.team_members tm where tm.team_id = ct.team_id and tm.user_id = (select auth.uid()))
            or exists (select 1 from public.team_leaders tl where tl.team_id = ct.team_id and tl.user_id = (select auth.uid())))));
