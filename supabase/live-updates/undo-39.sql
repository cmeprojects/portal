-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 39: everyone can use every register again. Safe to run again.
begin;
drop trigger if exists limited_task_guard on public.tasks;
drop function if exists public.limited_task_guard();
delete from public.app_settings where key = 'tasks.limited_roles';
commit;
