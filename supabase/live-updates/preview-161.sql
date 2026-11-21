-- Staff Portal · © cmeproject. All rights reserved.
-- PREVIEW for update 161 (billing set-up). READ ONLY: one SELECT, changes nothing.
-- Update 161 adds set-up tables only. It calculates and bills nothing, and changes
-- no existing service, shift, funding record, agreement or enrolment.
select 1 as section, 'CHECK' as kind, 'Update 160 (care plans, support plans, budgets) is in place (needed)' as item,
       case when to_regclass('public.client_support_plan_lines') is not null then 'yes' else 'NO - run update 160 first' end as result
union all
select 1, 'CHECK', 'Update 161 already run?', case when to_regclass('public.client_service_terms') is not null then 'yes (running it again changes nothing)' else 'no' end
union all
select 2, 'LEFT AS THEY ARE', 'Approved services (each will need billing terms before Phase 4B can bill it)',
       (select count(*) filter (where status <> 'ended'))::text || ' open, ' || (select count(*) filter (where status = 'ended'))::text || ' ended' from public.client_services
union all
select 2, 'LEFT AS THEY ARE', 'Funding records (billing never changes them)', (select count(*) from public.client_funding)::text
union all
select 2, 'LEFT AS THEY ARE', 'Service agreements', (select count(*) from public.client_agreements)::text
union all
select 2, 'LEFT AS THEY ARE', 'Cancelled shifts (details can now be recorded)', (select count(*) from public.shifts where status = 'cancelled')::text
union all
select 2, 'LEFT AS THEY ARE', 'Clients with a Support at Home program (contribution rates can now be recorded)',
       (select count(distinct client_id) from public.client_enrolments where scheme = 'support_at_home' and status <> 'ended')::text
union all
select 3, 'WILL GET "BILLING" (DEFAULT)', 'Managers (every Billing action)',
       (select count(*) from public.profiles where role = 'manager' and active)::text || ' active managers'
union all
select 3, 'WILL GET "BILLING" (DEFAULT)', 'Anyone else', 'no one (Case Managers, Intake, Payroll & Rostering and others get nothing; Funding rights don''t give Billing)'
union all
select 4, 'WILL BE ADDED', 'Scheme billing rules', (select string_agg(label, ', ' order by sort_order) from public.client_schemes) || ': all "not confirmed" (billing stays off for them)'
union all
select 4, 'WILL BE ADDED', 'Verification register', '13 figures to verify (8 Support at Home, 5 NDIS), each needing its value, official source and "as at" date'
union all
select 4, 'WILL BE ADDED', 'Set-up', 'price lists with versions, rate bands and rounding; public holidays by state; contribution rates; billing terms; cancellation details'
order by 1, 3;
