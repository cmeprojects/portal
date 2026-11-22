-- Staff Portal · © cmeproject. All rights reserved.
-- PREVIEW for update 164 (claim results, payments, receipts, credit notes, refunds, write-offs, bank reconciliation).
-- READ ONLY: one SELECT, changes nothing. Update 164 adds tables and rules; it records no payment and changes no claim or invoice.
select 1 as section, 'CHECK' as kind, 'Update 163 (claims and invoices) is in place (needed)' as item,
       case when to_regclass('public.claims') is not null then 'yes' else 'NO - run update 163 first' end as result
union all
select 1, 'CHECK', 'Update 164 already run?', case when to_regclass('public.payments') is not null then 'yes (running it again changes nothing)' else 'no' end
union all
select 2, 'LEFT AS THEY ARE', 'Claims (draft / approved / submitted / acknowledged / cancelled)',
       (select count(*) filter (where status = 'draft') || ' / ' || count(*) filter (where status = 'approved') || ' / ' || count(*) filter (where status = 'submitted') || ' / '
               || count(*) filter (where status = 'acknowledged') || ' / ' || count(*) filter (where status = 'cancelled') from public.claims)
union all
select 2, 'LEFT AS THEY ARE', 'Invoices (draft / approved / issued / sent / cancelled)',
       (select count(*) filter (where status = 'draft') || ' / ' || count(*) filter (where status = 'approved') || ' / ' || count(*) filter (where status = 'issued') || ' / '
               || count(*) filter (where status = 'sent') || ' / ' || count(*) filter (where status = 'cancelled') from public.invoices)
union all
select 2, 'LEFT AS THEY ARE', 'Billing lines in a claim or invoice (they stay locked as now)',
       (select count(distinct line_id)::text from (select line_id from public.claim_items where line_id is not null union all select line_id from public.invoice_items) x)
union all
select 3, 'WILL BE ADDED', 'Billing actions', 'payments, refunds, write-offs, reconcile (System Administrator and Manager Administrators have them; others none until given)'
union all
select 3, 'WILL BE ADDED', 'Claim results', 'accepted, partly accepted or rejected per claim line; rejected lines can go in a linked replacement claim; accepted amounts never claimed again'
union all
select 3, 'WILL BE ADDED', 'Money', 'payments and allocations (receipts RCT-YYYY-000001 for client payments), credit notes CN-YYYY-000001, refunds, write-offs (second approver above the threshold, $500 to start)'
union all
select 3, 'WILL BE ADDED', 'Bank reconciliation', 'bank statement lines imported and matched to payments or refunds; completed periods never change'
order by 1, 3;
