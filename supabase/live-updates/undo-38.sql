-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 38: removes saved chats and the new website settings. Documents,
-- enquiries and everything else are kept. Safe to run again.
begin;
drop trigger if exists assistant_messages_touch on public.assistant_messages;
drop function if exists public.assistant_chat_touch();
drop table if exists public.assistant_messages;
drop table if exists public.assistant_chats;
delete from public.app_settings where key = 'website.front_page';
alter table public.assistant_settings drop constraint if exists assistant_settings_scope_check;
alter table public.assistant_settings drop column if exists suggestions, drop column if exists show_credits,
  drop column if exists scope_public, drop column if exists scope_staff, drop column if exists scope_managers,
  drop column if exists trusted_sites;
alter table public.assistant_documents drop column if exists read_cost_usd;
create or replace function public.assistant_usage() returns table (this_month_usd numeric, last_hour bigint)
language sql stable security definer set search_path = '' as $$
  select coalesce((select sum(cost_usd) from public.assistant_questions where created_at >= date_trunc('month', now())), 0),
         (select count(*) from public.assistant_questions where created_at >= now() - interval '1 hour')
$$;
commit;
