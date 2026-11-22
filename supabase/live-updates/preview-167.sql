-- Staff Portal · © cmeproject. All rights reserved.
-- PREVIEW for update 167 (service codes). READ ONLY: one SELECT, changes nothing.
select 1 as section, 'CHECK' as kind, 'Update 166 (financial reporting) is in place (needed)' as item,
       case when to_regclass('public.billing_revenue') is not null then 'yes' else 'NO - run update 166 first' end as result
union all
select 1, 'CHECK', 'Update 167 already run?', case when exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'service_catalogue' and column_name = 'code') then 'yes (running it again changes nothing)' else 'no' end
union all
select 2, 'WILL BE CODED', 'Catalogue services (coded SERV-0001 onwards in catalogue order)', (select count(*)::text from public.service_catalogue)
union all
select 3, 'LEFT AS THEY ARE', 'Client services not linked to the catalogue (still priced by name)', (select count(*)::text from public.client_services where catalogue_id is null and status <> 'ended')
union all
select 3, 'LEFT AS THEY ARE', 'Prices', (select count(*)::text from public.price_items)
order by 1, 3;
