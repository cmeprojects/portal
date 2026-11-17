-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 104: removes the function group to part mapping (it gave no
-- access, so nobody's access changes). Safe to run again.
begin;
drop table if exists public.function_group_modules;
drop function if exists public.guard_function_group_module();
commit;
