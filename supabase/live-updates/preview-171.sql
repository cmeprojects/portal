-- Staff Portal · © cmeproject. All rights reserved.
-- PREVIEW for update 171 (internal functions locked). READ ONLY: one SELECT, changes nothing.
select 1 as section, 'CHECK' as kind, 'Update 171 already run?' as item,
       case when not has_function_privilege('authenticated', 'public.apply_request(uuid)', 'execute') then 'yes (running it again changes nothing)' else 'no' end as result
union all
select 2, 'NOW', 'Signed-in people can call apply_request (put a request into effect without approval)', case when has_function_privilege('authenticated', 'public.apply_request(uuid)', 'execute') then 'YES: to close' else 'no' end
union all
select 2, 'NOW', 'Signed-in people can call notify_many (send any notice to anyone)', case when has_function_privilege('authenticated', 'public.notify_many(uuid[], text, text, text, text)', 'execute') then 'YES: to close' else 'no' end
union all
select 2, 'NOW', 'Signed-in people can call resolve_people', case when has_function_privilege('authenticated', 'public.resolve_people(text[], uuid)', 'execute') then 'YES: to close' else 'no' end
union all
select 2, 'NOW', 'Signed-in people can call escalate_requests', case when has_function_privilege('authenticated', 'public.escalate_requests()', 'execute') then 'YES: to close' else 'no' end
union all
select 2, 'NOW', 'Signed-out visitors can call rule_on (its error shows members-only settings)', case when has_function_privilege('anon', 'public.rule_on(text)', 'execute') then 'YES: to close' else 'no' end
union all
select 2, 'NOW', 'Signed-out visitors can call setting_roles / can_take_tasks', case when has_function_privilege('anon', 'public.setting_roles(text)', 'execute') or has_function_privilege('anon', 'public.can_take_tasks(uuid)', 'execute') then 'YES: to close' else 'no' end
union all
select 3, 'LEFT AS THEY ARE', 'Requests (pending / all)', (select count(*) filter (where status = 'pending') || ' / ' || count(*) from public.requests)
union all
select 3, 'LEFT AS THEY ARE', 'Leave periods', (select count(*)::text from public.leave_periods)
union all
select 4, 'WILL BE CHANGED', 'Who can call the four functions', 'only database functions that use them (and the scheduler for escalation); approvals and notices work as before'
order by 1, 3;
