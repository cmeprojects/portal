-- Staff Portal · © cmeproject. All rights reserved.
-- PREVIEW for update 166 (financial reporting). READ ONLY: one SELECT, changes nothing.
-- Update 166 adds a read-only revenue view and integrity checks; it changes no record.
select 1 as section, 'CHECK' as kind, 'Update 165 (suppliers and charges) is in place (needed)' as item,
       case when to_regclass('public.client_charges') is not null then 'yes' else 'NO - run update 165 first' end as result
union all
select 1, 'CHECK', 'Update 166 already run?', case when to_regclass('public.billing_revenue') is not null then 'yes (running it again changes nothing)' else 'no' end
union all
select 2, 'WILL BE ADDED', 'Revenue view', 'approved billing lines and client charges in one read-only list, for the Billing reports'
union all
select 2, 'WILL BE ADDED', 'Integrity checks', 'read-only checks: recoveries above value, documents without PDFs, totals that don''t add up, over-allocation, claims not submitted, unmatched bank lines, old drafts'
order by 1, 3;
