-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 166 (financial reporting). Safe to run again. Update 166 only added a read-only view
-- and a read-only check function; removing them loses no data.
begin;
drop view if exists public.billing_revenue;
drop function if exists public.billing_integrity_checks();
commit;
