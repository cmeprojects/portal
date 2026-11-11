-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 66. Safe to run again.
begin;
alter table public.contracts drop column if exists letterhead;
commit;
