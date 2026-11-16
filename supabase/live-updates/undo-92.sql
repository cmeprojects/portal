-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 92: removes the Function Groups list (and any groups added to
-- it). Nothing else uses it in Stage 1. Safe to run again.
begin;
drop table if exists public.function_groups;
drop function if exists public.guard_function_group();
commit;
