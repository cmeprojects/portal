-- Staff Portal · © cmeproject. All rights reserved.
-- PREVIEW for update 160 (care plans, support plans and proposed budgets). READ ONLY: one SELECT, changes nothing.
-- Update 160 adds new tables and steps; existing care plans, goals, worker
-- instructions, funding and assessments stay as they are. This shows what it
-- needs, what it leaves alone, and who will be able to approve.
select 1 as section, 'CHECK' as kind,
       'Update 159 (assessments) is in place (needed)' as item,
       case when to_regclass('public.assessment_findings') is not null then 'yes' else 'NO - run update 159 first' end as result
union all
select 1, 'CHECK', 'Update 160 already run?', case when to_regclass('public.client_support_plans') is not null then 'yes (running it again changes nothing)' else 'no' end
union all
select 2, 'LEFT AS THEY ARE', 'Care plans',
       (select count(*) filter (where status = 'current'))::text || ' current (shown as Approved), '
       || (select count(*) filter (where status = 'archived'))::text || ' archived (shown as Superseded), '
       || (select count(*) filter (where status = 'draft'))::text || ' drafts (now need review before approval)'
  from public.client_care_plans
union all
select 2, 'LEFT AS THEY ARE', 'Care plan goals', (select count(*) from public.client_care_goals)::text
union all
select 2, 'LEFT AS THEY ARE', 'Worker instructions', (select count(*) from public.client_worker_instructions)::text
union all
select 2, 'LEFT AS THEY ARE', 'Funding records (budgets never change them)', (select count(*) from public.client_funding)::text
union all
select 2, 'LEFT AS THEY ARE', 'Completed assessments (drafts can be made from these)', (select count(*) from public.client_assessments where status = 'completed')::text
union all
-- Rules with "every action" (empty list) get the new "approve" right; listed rules don't.
select case when b.module_id = 'clients.care_plans' then 3 else 4 end,
       case when b.module_id = 'clients.care_plans' then 'WILL APPROVE CARE AND SUPPORT PLANS' else 'WILL APPROVE PROPOSED BUDGETS' end,
       coalesce(j.name, g.name, b.access_level::text, 'unknown'),
       case when cardinality(b.actions) = 0 then 'yes (every action) · reach: ' || b.scope
            else 'no (only ' || array_to_string(b.actions, ', ') || ')' end
  from public.access_baselines b
  left join public.job_titles j on j.id = b.job_title_id
  left join public.function_groups g on g.id = b.function_group_id
 where b.module_id in ('clients.care_plans', 'clients.funding') and b.revoked_at is null and b.effect = 'allow'
union all
select case when x.module_id = 'clients.care_plans' then 3 else 4 end,
       case when x.module_id = 'clients.care_plans' then 'WILL APPROVE CARE AND SUPPORT PLANS' else 'WILL APPROVE PROPOSED BUDGETS' end,
       'Person: ' || coalesce(p.full_name, p.email, 'unknown'),
       case when cardinality(x.actions) = 0 then 'yes (every action, own grant)' else 'no (only ' || array_to_string(x.actions, ', ') || ')' end
  from public.access_grants x left join public.profiles p on p.id = x.user_id
 where x.module_id in ('clients.care_plans', 'clients.funding') and x.revoked_at is null and x.effect = 'allow'
union all
select 5, 'WILL BE ADDED', 'Steps for each document', 'Draft -> Pending review -> Changes required / Approved -> Superseded; approver can''t be who made or submitted it'
union all
select 5, 'WILL BE ADDED', 'New records', 'care plan items, support plans and lines, proposed budgets and lines (estimates only), client or representative agreements'
union all
select 5, 'WILL BE ADDED', 'Template version control', 'assessment template sections in the change log'
order by 1, 3;
