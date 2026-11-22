-- Staff Portal · © cmeproject. All rights reserved.
-- PREVIEW for update 162 (billing lines, quarter budgets, funding ledger). READ ONLY: one SELECT, changes nothing.
-- Update 162 adds tables and functions. It makes no billing lines by itself, and
-- changes no shift, timesheet, service, funding record or agreement.
select 1 as section, 'CHECK' as kind, 'Update 161 (billing set-up) is in place (needed)' as item,
       case when to_regclass('public.client_service_terms') is not null then 'yes' else 'NO - run update 161 first' end as result
union all
select 1, 'CHECK', 'Update 162 already run?', case when to_regclass('public.billing_lines') is not null then 'yes (running it again changes nothing)' else 'no' end
union all
select 2, 'READY TO BILL WHEN LINES ARE MADE', 'Schemes with confirmed billing rules',
       (select count(*) filter (where status = 'confirmed'))::text || ' of ' || count(*)::text
       || coalesce(' (' || string_agg(scheme, ', ') filter (where status = 'confirmed') || ')', '') from public.billing_scheme_rules
union all
select 2, 'READY TO BILL WHEN LINES ARE MADE', 'Open services with approved billing terms',
       (select count(distinct t.service_id) from public.client_service_terms t join public.client_services s on s.id = t.service_id where t.status = 'approved' and s.status <> 'ended')::text
       || ' of ' || (select count(*) from public.client_services where status <> 'ended')::text
union all
select 2, 'READY TO BILL WHEN LINES ARE MADE', 'Published price lists', (select count(distinct price_list_id) from public.price_list_versions where status = 'published')::text
union all
select 3, 'LEFT AS THEY ARE', 'Client shifts in the last 90 days with delivery evidence (approved timesheet and service record)',
       (select count(*) from public.shifts s where s.client_id is not null and s.status = 'published' and s.starts_at between now() - interval '90 days' and now()
           and exists (select 1 from public.shift_timesheets t where t.shift_id = s.id and t.status = 'approved')
           and exists (select 1 from public.shift_service_records r where r.shift_id = s.id))::text
union all
select 3, 'LEFT AS THEY ARE', 'Cancellations marked "charge"', (select count(*) from public.shift_cancellations where charge = 'charge')::text
union all
select 3, 'LEFT AS THEY ARE', 'Funding records (billing never changes them; their typed "used" figure stays)', (select count(*) from public.client_funding)::text
union all
select 4, 'WILL BE ADDED', 'Support at Home figures to verify', 'care management 10%, rollover floor $1,000, rollover 10%: all unverified until checked with a source and "as at" date'
union all
select 4, 'WILL BE ADDED', 'Billing lines', 'made only when someone with Billing prepare clicks "Make billing lines"; approved by someone else with Billing approve'
union all
select 4, 'WILL BE ADDED', 'Quarter budgets and ledger', 'Support at Home quarter budgets (made and approved by different people) and an append-only ledger with approved opening balances'
order by 1, 3;
