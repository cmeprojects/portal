-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 120: removes leave balances (and the balances set in them).
-- Approved leave itself is untouched. Safe to run again.
begin;
drop function if exists public.leave_balance(uuid, text);
drop table if exists public.leave_balances;
drop function if exists public.touch_leave_balance();
commit;
