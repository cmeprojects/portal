-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 88: removes client contact details, identifiers and people
-- (with everything entered in them). Run undo-89 and undo-90 first if those
-- were run. Safe to run again.
begin;
drop table if exists public.client_people;
drop table if exists public.client_details;
drop function if exists public.log_client_change();
commit;
