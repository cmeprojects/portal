-- Staff Portal · © cmeproject. All rights reserved.
--
-- Website and Assistant, version 2 (cmeprojects):
--   * Chat history for signed-in staff (each person sees only their own).
--   * The website can be the front page (a public setting the sign-in
--     check reads before anyone signs in).
--   * Suggested questions and credits are set in Website settings.
--   * Where the assistant looks, per group: documents, listed websites, or both.
--   * Reading scanned PDFs and photos costs a little; it counts towards the
--     monthly limit.

alter table public.assistant_settings add column if not exists suggestions text[] not null
  default array['What services do you offer?', 'What''s your cancellation policy?', 'How do I start with you?', 'How does NDIS funding work?'];
alter table public.assistant_settings add column if not exists show_credits boolean not null default true;
alter table public.assistant_settings add column if not exists scope_public text not null default 'documents';
alter table public.assistant_settings add column if not exists scope_staff text not null default 'documents';
alter table public.assistant_settings add column if not exists scope_managers text not null default 'documents';
alter table public.assistant_settings add column if not exists trusted_sites text[] not null
  default array['ndis.gov.au', 'ndiscommission.gov.au', 'legislation.gov.au'];
alter table public.assistant_settings drop constraint if exists assistant_settings_scope_check;
alter table public.assistant_settings add constraint assistant_settings_scope_check check (
  scope_public in ('documents', 'web', 'both') and scope_staff in ('documents', 'web', 'both') and scope_managers in ('documents', 'web', 'both')
  and cardinality(trusted_sites) <= 30 and cardinality(suggestions) <= 8);

alter table public.assistant_documents add column if not exists read_cost_usd numeric(10,6) not null default 0;

-- The front-page switch is public (it is read before signing in).
insert into public.app_settings (key, value, label, description, is_public) values
  ('website.front_page', 'false', 'Website is the front page',
   'Visitors who aren''t signed in see the website first; staff sign in from there.', true)
on conflict (key) do nothing;

-- Spending this month includes reading scanned documents.
create or replace function public.assistant_usage()
returns table (this_month_usd numeric, last_hour bigint)
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select sum(cost_usd) from public.assistant_questions where created_at >= date_trunc('month', now())), 0)
       + coalesce((select sum(read_cost_usd) from public.assistant_documents where created_at >= date_trunc('month', now())), 0),
         (select count(*) from public.assistant_questions where created_at >= now() - interval '1 hour')
$$;

-- Chat history -----------------------------------------------------------------
create table if not exists public.assistant_chats (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  title      text not null default 'New chat' check (length(title) <= 120),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists assistant_chats_user on public.assistant_chats (user_id, updated_at desc);

create table if not exists public.assistant_messages (
  id         bigint generated always as identity primary key,
  chat_id    uuid not null references public.assistant_chats (id) on delete cascade,
  question   text not null check (length(question) <= 500),
  answer     text not null,
  sources    jsonb not null default '[]',
  answered   boolean not null default true,
  created_at timestamptz not null default now()
);
create index if not exists assistant_messages_chat on public.assistant_messages (chat_id, id);

alter table public.assistant_chats enable row level security;
alter table public.assistant_messages enable row level security;
revoke all on public.assistant_chats, public.assistant_messages from anon;
grant select, insert, update, delete on public.assistant_chats to authenticated;
grant select, insert, delete on public.assistant_messages to authenticated;

drop policy if exists assistant_chats_own on public.assistant_chats;
create policy assistant_chats_own on public.assistant_chats for all to authenticated
  using (user_id = auth.uid() and public.is_member()) with check (user_id = auth.uid() and public.is_member());
drop policy if exists assistant_messages_own on public.assistant_messages;
create policy assistant_messages_own on public.assistant_messages for all to authenticated
  using (exists (select 1 from public.assistant_chats c where c.id = chat_id and c.user_id = auth.uid()))
  with check (exists (select 1 from public.assistant_chats c where c.id = chat_id and c.user_id = auth.uid()));

-- A new message brings its chat to the top of the list.
create or replace function public.assistant_chat_touch() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  update public.assistant_chats set updated_at = now() where id = new.chat_id;
  return new;
end $$;
drop trigger if exists assistant_messages_touch on public.assistant_messages;
create trigger assistant_messages_touch after insert on public.assistant_messages
  for each row execute function public.assistant_chat_touch();
