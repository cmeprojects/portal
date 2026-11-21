-- Staff Portal · © cmeproject. All rights reserved.
-- PREVIEW for update 159 (assessments). READ ONLY: one SELECT, changes nothing.
-- Update 159 adds new tables and a sample template; it doesn't change any
-- existing client, service, funding, shift or Forms record. This shows what it
-- needs and who will get the new "Assessments" part (copied from care plans).
select 1 as section, 'CHECK' as kind,
       'Update 158 (program enrolments) is in place (needed)' as item,
       case when to_regclass('public.client_enrolments') is not null then 'yes' else 'NO - run update 158 first' end as result
union all
select 1, 'CHECK', 'Update 159 already run?', case when to_regclass('public.client_assessments') is not null then 'yes (running it again changes nothing)' else 'no' end
union all
select 1, 'CHECK', 'Staff Forms and replies (left exactly as they are)',
       (select count(*) from public.forms)::text || ' forms, ' || (select count(*) from public.form_responses)::text || ' replies'
union all
select 2, 'WILL GET "ASSESSMENTS"',
       coalesce(j.name, g.name, b.access_level::text, 'unknown') as item,
       array_to_string(b.actions, ', ') || ' · reach: ' || b.scope || case when b.effect <> 'allow' then ' · ' || b.effect else '' end
  from public.access_baselines b
  left join public.job_titles j on j.id = b.job_title_id
  left join public.function_groups g on g.id = b.function_group_id
 where b.module_id = 'clients.care_plans' and b.revoked_at is null
union all
select 3, 'WILL BE ADDED', 'Sample template', '"Client needs assessment (Sample)", 5 sections, 12 questions, published, common to all programs'
union all
select 3, 'WILL BE ADDED', 'Portal settings tile', '"Assessment templates" for Manager Administrators and the care settings area'
order by 1, 3;
