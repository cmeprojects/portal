-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 166 (financial reporting and statement detail). Safe to run again. Update 166 added a
-- read-only view, a read-only check function and the extra detail on new monthly statements;
-- removing them loses no data (statements already issued keep their detail and never change).
begin;
drop view if exists public.billing_revenue;
drop function if exists public.billing_integrity_checks();
drop trigger if exists guard_statement_detail on public.client_statements;
drop function if exists public.statement_add_detail();
commit;
