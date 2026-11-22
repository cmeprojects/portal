-- Staff Portal · © cmeproject. All rights reserved.
-- PREVIEW for update 163 (claims, client invoices, statements, compliance register). READ ONLY: one SELECT, changes nothing.
-- Update 163 adds tables and functions. It makes no claim or invoice by itself, and changes
-- no billing line, budget, ledger entry, price, term, shift or funding record.
select 1 as section, 'CHECK' as kind, 'Update 162 (billing lines) is in place (needed)' as item,
       case when to_regclass('public.billing_lines') is not null then 'yes' else 'NO - run update 162 first' end as result
union all
select 1, 'CHECK', 'Update 163 already run?', case when to_regclass('public.claims') is not null then 'yes (running it again changes nothing)' else 'no' end
union all
select 1, 'CHECK', 'Schemes with confirmed rules (new rule checks are added only to unconfirmed schemes)',
       coalesce((select string_agg(scheme, ', ') from public.billing_scheme_rules where status = 'confirmed'), 'none')
union all
select 2, 'LEFT AS THEY ARE', 'Billing lines (draft / approved / voided)',
       (select count(*) filter (where status = 'draft') || ' / ' || count(*) filter (where status = 'approved') || ' / ' || count(*) filter (where status = 'voided') from public.billing_lines)
union all
select 2, 'LEFT AS THEY ARE', 'Quarter budgets', (select count(*)::text from public.client_quarter_budgets)
union all
select 2, 'LEFT AS THEY ARE', 'Billing rule checks today (verified of total)', (select count(*) filter (where status = 'verified') || ' of ' || count(*) from public.billing_rule_checks)
union all
select 2, 'LEFT AS THEY ARE', 'NDIS funding records by plan management (agency / plan / self)',
       (select count(*) filter (where plan_management = 'ndia') || ' / ' || count(*) filter (where plan_management = 'plan') || ' / ' || count(*) filter (where plan_management = 'self')
          from public.client_funding where scheme = 'ndis')
union all
select 3, 'WILL BE ADDED', 'Rule checks to verify', '4 Support at Home (care management account, clinical no contribution, fee reduction supplement, claim format) and 3 NDIS (bulk upload template, pricing arrangements version, "my provider"), unverified'
union all
select 3, 'WILL BE ADDED', 'Compliance fields', 'official link, document version, effective date and "review by" on rule checks and figures; claims and invoices need them; a past review date pauses claims, invoices and line approval'
union all
select 3, 'WILL BE ADDED', 'Payers', '2 shared payers: Services Australia (Support at Home) and the NDIA; plan managers and client billing contacts are added per client'
union all
select 3, 'WILL BE ADDED', 'Billing actions', 'claim prepare, approve, submit; invoice prepare, approve, issue (System Administrator and Manager Administrators have them; others none until given)'
union all
select 3, 'WILL BE ADDED', 'Empty until used', 'business details, NDIS catalogue, pricing zones, claim templates, claims, submissions, invoices (numbered only when issued), statements, fee reductions'
order by 1, 3;
