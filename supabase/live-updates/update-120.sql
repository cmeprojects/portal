-- Staff Portal · © cmeproject. All rights reserved.
-- Update 120: leave balances (HR block step 3). Safe to run again.
-- Undo: undo-120.sql. Run update 119 first.
begin;
--
-- cmeprojects (update 120; HR block step 3, owner's order): leave balances.
--
--   * For each person and leave type (annual, personal/carer's, long
--     service): an opening balance in days, how many days build up a year,
--     and the date that balance was correct ("as at"). Set by people who
--     manage staff (not for themselves).
--   * The balance today = opening + what has built up since "as at" − the
--     weekdays of approved leave of that type since "as at". Worked out by
--     leave_balance(), which only sees what the person asking may see.
--   * Each person sees their own; managers and staff admins (Staff), and
--     people who see everyone's requests, see everyone's. Casual staff simply
--     have none set. Nothing is deleted.

create table if not exists public.leave_balances (
  user_id uuid not null references public.profiles (id) on delete restrict,
  leave_type text not null check (leave_type in ('annual', 'personal', 'long_service')),
  org_id uuid not null default public.default_org_id(),
  opening_days numeric(6,2) not null default 0 check (opening_days between -100 and 1000),
  accrual_days_per_year numeric(5,2) not null default 0 check (accrual_days_per_year between 0 and 60),
  as_at date not null default current_date,
  note text not null default '' check (length(note) <= 300),
  updated_by uuid default auth.uid() references public.profiles (id),
  updated_at timestamptz not null default now(),
  primary key (user_id, leave_type)
);
alter table public.leave_balances enable row level security;

drop policy if exists "see leave balances" on public.leave_balances;
create policy "see leave balances" on public.leave_balances
  for select to authenticated
  using (user_id = (select auth.uid()) or (select public.can('hr.requests', 'view')) or public.can('people.staff', 'edit', user_id));
drop policy if exists "set leave balances" on public.leave_balances;
create policy "set leave balances" on public.leave_balances
  for insert to authenticated
  with check (user_id <> (select auth.uid()) and public.can('people.staff', 'edit', user_id));
drop policy if exists "change leave balances" on public.leave_balances;
create policy "change leave balances" on public.leave_balances
  for update to authenticated
  using (user_id <> (select auth.uid()) and public.can('people.staff', 'edit', user_id))
  with check (user_id <> (select auth.uid()) and public.can('people.staff', 'edit', user_id));
grant select, insert, update on public.leave_balances to authenticated;

create or replace function public.touch_leave_balance()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_by := auth.uid();
  new.updated_at := now();
  return new;
end;
$$;
revoke execute on function public.touch_leave_balance() from public, anon, authenticated;
drop trigger if exists touch_leave_balance on public.leave_balances;
create trigger touch_leave_balance before insert or update on public.leave_balances
  for each row execute function public.touch_leave_balance();

-- The balance in days today (null when none is set, or not visible).
create or replace function public.leave_balance(p_user uuid, p_type text)
returns numeric
language sql
stable
security invoker
set search_path = ''
as $$
  select round(b.opening_days
               + b.accrual_days_per_year * greatest(public.local_today() - b.as_at, 0) / 365.0
               - coalesce((select count(*)
                             from public.leave_periods l,
                                  generate_series(greatest(l.start_date, b.as_at), l.end_date, interval '1 day') d
                            where l.user_id = b.user_id and l.leave_type = b.leave_type
                              and l.end_date >= b.as_at and extract(isodow from d) < 6), 0), 2)
    from public.leave_balances b
   where b.user_id = p_user and b.leave_type = p_type
$$;
grant execute on function public.leave_balance(uuid, text) to authenticated;
commit;
