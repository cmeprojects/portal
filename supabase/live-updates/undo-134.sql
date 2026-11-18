-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 134: removes service records. Safe to run again.
begin;
drop function if exists public.run_service_record_alerts();
drop table if exists public.shift_service_records;
drop function if exists public.guard_service_record();
commit;
