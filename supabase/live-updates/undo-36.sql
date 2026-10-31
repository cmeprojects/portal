-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 36: removes the Website and Assistant tables and switches the
-- feature off. Documents, questions and enquiries are DELETED. Everything
-- else in the portal is untouched. Safe to run again.
begin;
drop trigger if exists website_enquiry_notify on public.website_enquiries;
drop function if exists public.website_enquiry_notify();
drop function if exists public.new_enquiry_count();
drop function if exists public.assistant_usage();
drop function if exists public.assistant_search(text, text[], int);
drop function if exists public.assistant_index(uuid);
drop table if exists public.website_enquiries;
drop table if exists public.assistant_questions;
drop table if exists public.assistant_chunks;
drop table if exists public.assistant_documents;
drop table if exists public.assistant_settings;
drop function if exists public.assistant_touch();
delete from public.notifications where kind = 'website_enquiry';
delete from public.features where key = 'assistant';
commit;
