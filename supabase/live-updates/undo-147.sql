-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 147. Safe to run again. The communication log and its entries are removed.
begin;
drop table if exists public.client_communications;
drop function if exists public.guard_client_communication();
commit;
