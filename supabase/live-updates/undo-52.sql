-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 52: registers can't be deleted from the portal again. Safe to run again.
begin;
drop function if exists public.delete_unused_registry(uuid);
commit;
