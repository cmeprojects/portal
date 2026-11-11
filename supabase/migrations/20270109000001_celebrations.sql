-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects Phase 5: birthdays and work anniversaries.
--   * Birthdays: day and month only (the year is never asked or stored, so no
--     age can be shown or worked out). Shown to colleagues only when the person
--     chooses "Show my birthday" (off by default); they can change it any time.
--   * Only active staff appear.
--   * Work anniversaries use the commencement date (staff_private.start_date),
--     which keeps its existing privacy: the person and people who manage
--     staff see it. No change there.
-- No new SECURITY DEFINER function.

create table if not exists public.staff_birthdays (
  user_id   uuid primary key references public.profiles (id) on delete cascade,
  month     int not null check (month between 1 and 12),
  day       int not null check (day between 1 and 31),
  show      boolean not null default false,
  updated_at timestamptz not null default now(),
  check ((month, day) not in ((2, 30), (2, 31), (4, 31), (6, 31), (9, 31), (11, 31)))
);
alter table public.staff_birthdays enable row level security;
revoke all on public.staff_birthdays from anon;
revoke truncate on public.staff_birthdays from authenticated;
grant select, insert, update, delete on public.staff_birthdays to authenticated;

-- Your own always; colleagues' only when shown and they're active.
drop policy if exists "birthdays: your own, or shown by active colleagues" on public.staff_birthdays;
create policy "birthdays: your own, or shown by active colleagues" on public.staff_birthdays for select to authenticated
  using ((select public.is_member()) and (user_id = (select auth.uid())
         or (show and exists (select 1 from public.profiles p where p.id = staff_birthdays.user_id and p.active))));
drop policy if exists "birthdays: only your own" on public.staff_birthdays;
create policy "birthdays: only your own" on public.staff_birthdays for all to authenticated
  using (user_id = (select auth.uid()) and (select public.is_member()))
  with check (user_id = (select auth.uid()) and (select public.is_member()));
