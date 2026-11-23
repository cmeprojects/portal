-- Staff Portal · © cmeproject. All rights reserved.
-- PREVIEW for update 170 (Phase 6: roster billing checks and budget forecast). READ ONLY: one SELECT, changes nothing.
select 1 as section, 'CHECK' as kind, 'Update 162 (billing lines) run?' as item, case when to_regprocedure('public.billing_calc(uuid, text)') is not null then 'yes' else 'NO: run update 162 first' end as result
union all
select 1, 'CHECK', 'Update 170 already run?', case when to_regprocedure('public.roster_billing_forecast(date, date, uuid)') is not null then 'yes (running it again changes nothing)' else 'no' end
union all
select 2, 'LEFT AS THEY ARE', 'Shifts', (select count(*)::text from public.shifts)
union all
select 2, 'LEFT AS THEY ARE', 'Billing lines (estimates never make lines)', (select count(*)::text from public.billing_lines)
union all
select 2, 'LEFT AS THEY ARE', 'Client shifts rostered from today, not billed', (select count(*)::text from public.shifts s where s.client_id is not null and s.status in ('draft', 'published') and s.starts_at >= now())
union all
select 3, 'WILL BE CHANGED', 'billing_calc()', 'adds an "estimate" kind from the rostered times; delivered-shift billing works exactly as before'
union all
select 3, 'WILL BE ADDED', 'roster_billing_forecast()', 'rostered, unbilled client shifts: estimate, why one can''t be billed, budget left after it (Billing view right only)'
order by 1, 3;
