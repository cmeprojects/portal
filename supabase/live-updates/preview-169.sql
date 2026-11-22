-- Staff Portal · © cmeproject. All rights reserved.
-- PREVIEW for update 169 (contracted hours for the roster). READ ONLY: one SELECT, changes nothing.
select 1 as section, 'CHECK' as kind, 'Update 169 already run?' as item, case when to_regclass('public.staff_contract_hours') is not null then 'yes (running it again changes nothing)' else 'no' end as result
union all
select 2, 'LEFT AS THEY ARE', 'Shifts', (select count(*)::text from public.shifts)
union all
select 2, 'LEFT AS THEY ARE', 'Active staff (contracted hours start empty for everyone)', (select count(*)::text from public.profiles where active)
union all
select 3, 'WILL BE ADDED', 'Contracted hours', 'contracted weekly hours per worker, set by roster editors from the roster; the roster warns about unscheduled hours'
order by 1, 3;
