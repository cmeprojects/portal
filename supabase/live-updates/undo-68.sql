-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 68: removes the module catalogue and everyone's pinned
-- shortcuts. Safe to run again.
begin;
drop table if exists public.pinned_items;
drop table if exists public.app_modules;
commit;
