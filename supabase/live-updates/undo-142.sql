-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 142. Safe to run again.
begin;
alter table public.shifts drop constraint if exists shifts_shift_type_other_check;
alter table public.shifts drop column if exists shift_type_other;
alter table public.shift_types drop constraint if exists shift_types_used_for_check;
alter table public.shift_types drop column if exists used_for;
commit;
