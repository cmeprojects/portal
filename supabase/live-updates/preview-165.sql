-- Staff Portal · © cmeproject. All rights reserved.
-- PREVIEW for update 165 (suppliers, client charges, markup, pathway budgets). READ ONLY: one SELECT, changes nothing.
-- Update 165 adds tables and rules; it makes no charge and changes no claim, invoice, budget or ledger entry.
select 1 as section, 'CHECK' as kind, 'Update 164 (payments) is in place (needed)' as item,
       case when to_regclass('public.payments') is not null then 'yes' else 'NO - run update 164 first' end as result
union all
select 1, 'CHECK', 'Update 165 already run?', case when to_regclass('public.client_charges') is not null then 'yes (running it again changes nothing)' else 'no' end
union all
select 1, 'CHECK', 'Schemes with confirmed rules (new rule checks are added only to unconfirmed schemes)', coalesce((select string_agg(scheme, ', ') from public.billing_scheme_rules where status = 'confirmed'), 'none')
union all
select 2, 'LEFT AS THEY ARE', 'Claim lines / invoice lines / recoveries', (select count(*) from public.claim_items) || ' / ' || (select count(*) from public.invoice_items) || ' / ' || (select count(*) from public.line_recoveries)
union all
select 2, 'LEFT AS THEY ARE', 'Support at Home enrolments (pathway budgets can be added to these)', (select count(*)::text from public.client_enrolments where scheme = 'support_at_home' and status <> 'ended')
union all
select 3, 'WILL BE ADDED', 'Rule checks to verify', '6 Support at Home (AT-HM, Restorative Care, End-of-Life, unspent HCP funds, third-party services and markup, contributions on pathways) and 1 NDIS (third-party supports at no more than the price limit), unverified'
union all
select 3, 'WILL BE ADDED', 'Suppliers', 'suppliers and their invoices (recorded, approved by someone else, paid); costs never charge a client by themselves'
union all
select 3, 'WILL BE ADDED', 'Client charges', 'charges from supplier costs (with the markup rule) or on their own, approved by someone else; claimed and invoiced like billing lines; in monthly statements'
union all
select 3, 'WILL BE ADDED', 'Pathway budgets', 'AT-HM, Restorative Care, End-of-Life and unspent HCP funds per client, from the Services Australia notice, approved by someone else'
order by 1, 3;
