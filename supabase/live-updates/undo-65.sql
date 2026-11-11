-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 65: removes the birthdays staff have entered. Safe to run again.
begin;
drop table if exists public.staff_birthdays;
commit;
