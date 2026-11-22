-- Staff Portal · © cmeproject. All rights reserved.
-- Update 169: contracted weekly hours per worker for the roster (rostered against contracted hours,
-- unscheduled hours warning). Changes no shift. Safe to run again. Undo: undo-169.sql.
begin;
create table if not exists public.staff_contract_hours (
  user_id uuid primary key references public.profiles (id),
  id uuid not null default gen_random_uuid() unique,
  org_id uuid not null default public.default_org_id(),
  hours_per_week numeric(5, 2) not null check (hours_per_week >= 0 and hours_per_week <= 80),
  note text not null default '' check (length(note) <= 300),
  set_by uuid default auth.uid(),
  set_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now()
);
create or replace function public.guard_contract_hours() returns trigger
language plpgsql set search_path = '' as $$
begin
  if public.from_portal() and not public.can('ops.roster', 'edit') then
    raise exception 'Only people who can edit the roster set contracted hours.';
  end if;
  if tg_op = 'DELETE' then return old; end if;
  new.set_by := auth.uid(); new.set_at := now(); new.updated_at := now(); new.updated_by := auth.uid();
  return new;
end;
$$;
drop trigger if exists guard_contract_hours on public.staff_contract_hours;
create trigger guard_contract_hours before insert or update or delete on public.staff_contract_hours for each row execute function public.guard_contract_hours();
drop trigger if exists log_contract_hours on public.staff_contract_hours;
create trigger log_contract_hours after insert or update or delete on public.staff_contract_hours for each row execute function public.log_car_setup('contract_hours');
revoke execute on function public.guard_contract_hours() from public, anon, authenticated;

alter table public.staff_contract_hours enable row level security;
drop policy if exists "roster sees contract hours" on public.staff_contract_hours;
create policy "roster sees contract hours" on public.staff_contract_hours for select to authenticated using ((select public.can('ops.roster', 'view')) or user_id = (select auth.uid()));
drop policy if exists "roster sets contract hours" on public.staff_contract_hours;
create policy "roster sets contract hours" on public.staff_contract_hours for all to authenticated using ((select public.can('ops.roster', 'edit'))) with check ((select public.can('ops.roster', 'edit')));
grant select, insert, update, delete on public.staff_contract_hours to authenticated;
revoke all on public.staff_contract_hours from anon;
commit;
