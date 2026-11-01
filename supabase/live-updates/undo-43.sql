-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 43: removes the demo data tools. Sample records already loaded
-- stay (delete them first in System settings → Demo data if you want them gone).
-- Safe to run again.
begin;
drop function if exists public.demo_load();
drop function if exists public.demo_clear();
drop function if exists public.demo_clear_all_tasks();
drop function if exists public.delete_tasks_completely(uuid[]);
drop table if exists public.demo_records;
commit;
