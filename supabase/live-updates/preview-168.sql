-- Staff Portal · © cmeproject. All rights reserved.
-- PREVIEW for update 168 (document templates). READ ONLY: one SELECT, changes nothing.
select 1 as section, 'CHECK' as kind, 'Update 167 (service codes) is in place (needed)' as item,
       case when exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'service_catalogue' and column_name = 'code') then 'yes' else 'NO - run update 167 first' end as result
union all
select 1, 'CHECK', 'Update 168 already run?', case when to_regclass('public.document_templates') is not null then 'yes (running it again changes nothing)' else 'no' end
union all
select 2, 'WILL BE ADDED', 'Document templates', 'one starting template each for invoices, statements, receipts and credit notes: full layout, the portal''s logo and colours'
union all
select 3, 'LEFT AS THEY ARE', 'Documents already issued (their PDFs never change)', (select (select count(*) from public.invoices where pdf_checksum is not null) + (select count(*) from public.client_statements) + (select count(*) from public.credit_notes where pdf_checksum is not null) + (select count(*) from public.payments where receipt_pdf_checksum is not null))::text
order by 1, 3;
