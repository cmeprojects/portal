-- Staff Portal · © cmeproject. All rights reserved.
-- Update 36: the Website and Assistant (premium, off until switched on):
-- a public "ask anything" page that answers from your own documents, and
-- an enquiry form that lists new customers for managers to call back.
-- Safe to run again. To remove it again, run undo-36.sql.
begin;
-- Website and Assistant (cmeprojects): a public "ask anything" page that
-- answers only from documents the system admin uploads, and catches new
-- customer enquiries. A premium add-on, off until switched on.
--
--   assistant_settings   one row: wording, model and monthly limit
--   assistant_documents  what the system admin uploaded, and who may get
--                        answers from it (public / staff / managers)
--   assistant_chunks     those documents cut into searchable pieces
--   assistant_questions  a log of questions (no names), to find gaps
--   website_enquiries    people who left their details (the funnel)
--
-- The public pages talk to the database only through the server (service
-- role); the portal reads these as the signed-in person, so Row Level
-- Security decides who sees what.

insert into public.features (key, label, description, enabled, sort_order, premium, included) values
  ('assistant', 'Website and Assistant',
   'A public website where anyone can ask questions and get answers from your own documents, and leave their details to be called back. The system admin manages the documents; managers follow up the enquiries.',
   false, 79, true, false)
on conflict (key) do nothing;

create table if not exists public.assistant_settings (
  id             boolean primary key default true check (id),
  model          text not null default 'haiku' check (model in ('haiku', 'sonnet')),
  heading        text not null default 'How can we help today?',
  intro          text not null default 'Ask anything about our services, the NDIS or our policies. Answers come from our own documents, with the source shown.',
  disclaimer     text not null default 'General information only, not official NDIS advice.',
  fallback       text not null default 'I can''t find that in our documents. Please call us or leave your details and we''ll call you.',
  phone          text not null default '',
  offer_call     boolean not null default true,
  log_questions  boolean not null default true,
  monthly_limit_aud numeric(8,2) not null default 50 check (monthly_limit_aud >= 0),
  hourly_limit   int not null default 60 check (hourly_limit between 1 and 500),
  updated_at     timestamptz not null default now()
);
insert into public.assistant_settings default values on conflict do nothing;

create table if not exists public.assistant_documents (
  id         uuid primary key default gen_random_uuid(),
  title      text not null check (length(title) between 1 and 200),
  audience   text not null default 'public' check (audience in ('public', 'staff', 'managers')),
  body       text not null,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.assistant_chunks (
  id          bigint generated always as identity primary key,
  document_id uuid not null references public.assistant_documents (id) on delete cascade,
  position    int not null,
  content     text not null,
  fts         tsvector generated always as (to_tsvector('english', content)) stored
);
create index if not exists assistant_chunks_fts on public.assistant_chunks using gin (fts);
create index if not exists assistant_chunks_doc on public.assistant_chunks (document_id);

create table if not exists public.assistant_questions (
  id         bigint generated always as identity primary key,
  question   text not null,
  audience   text not null,
  answered   boolean not null,
  sources    text[] not null default '{}',
  cost_usd   numeric(10,6) not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists assistant_questions_when on public.assistant_questions (created_at desc);

create table if not exists public.website_enquiries (
  id         uuid primary key default gen_random_uuid(),
  full_name  text not null check (length(full_name) between 1 and 120),
  phone      text not null check (length(phone) between 6 and 40),
  email      text not null default '',
  suburb     text not null default '',
  support_for text not null default '',
  has_plan   text not null default '',
  managed_by text not null default '',
  needs      text[] not null default '{}',
  best_time  text not null default '',
  heard_from text not null default '',
  message    text not null default '',
  asked      text not null default '',
  source     text not null default 'form' check (source in ('form', 'chat')),
  status     text not null default 'new' check (status in ('new', 'called', 'meeting', 'client', 'closed')),
  note       text not null default '',
  consent    boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists website_enquiries_when on public.website_enquiries (created_at desc);

alter table public.assistant_settings  enable row level security;
alter table public.assistant_documents enable row level security;
alter table public.assistant_chunks    enable row level security;
alter table public.assistant_questions enable row level security;
alter table public.website_enquiries   enable row level security;

-- Nothing is open to the public through the database: the website's server
-- uses the service role. Signed-in people only get what their role allows.
revoke all on public.assistant_settings, public.assistant_documents, public.assistant_chunks,
  public.assistant_questions, public.website_enquiries from anon;
revoke all on public.assistant_chunks, public.assistant_questions from authenticated;
grant select on public.assistant_questions to authenticated;
grant select, insert, update, delete on public.assistant_documents to authenticated;
grant select, update on public.assistant_settings to authenticated;
grant select, update on public.website_enquiries to authenticated;

drop policy if exists assistant_settings_read on public.assistant_settings;
create policy assistant_settings_read on public.assistant_settings
  for select to authenticated using (public.is_system_admin());
drop policy if exists assistant_settings_write on public.assistant_settings;
create policy assistant_settings_write on public.assistant_settings
  for update to authenticated using (public.is_system_admin()) with check (public.is_system_admin());

drop policy if exists assistant_documents_all on public.assistant_documents;
create policy assistant_documents_all on public.assistant_documents
  for all to authenticated using (public.is_system_admin()) with check (public.is_system_admin());

drop policy if exists assistant_questions_read on public.assistant_questions;
create policy assistant_questions_read on public.assistant_questions
  for select to authenticated using (public.is_system_admin());

drop policy if exists website_enquiries_read on public.website_enquiries;
create policy website_enquiries_read on public.website_enquiries
  for select to authenticated using (public.has_role(array['manager', 'system_admin']::public.app_role[]));
drop policy if exists website_enquiries_update on public.website_enquiries;
create policy website_enquiries_update on public.website_enquiries
  for update to authenticated
  using (public.has_role(array['manager', 'system_admin']::public.app_role[]))
  with check (public.has_role(array['manager', 'system_admin']::public.app_role[]));

-- The system admin only changes the wording and limits (the guard is the
-- policy above); a plain update keeps the time fresh.
create or replace function public.assistant_touch() returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end $$;
drop trigger if exists assistant_settings_touch on public.assistant_settings;
create trigger assistant_settings_touch before update on public.assistant_settings
  for each row execute function public.assistant_touch();
drop trigger if exists website_enquiries_touch on public.website_enquiries;
create trigger website_enquiries_touch before update on public.website_enquiries
  for each row execute function public.assistant_touch();

-- Cuts a document into pieces of about 900 characters, on paragraph breaks,
-- and makes them searchable. Called by the server after an upload.
create or replace function public.assistant_index(p_document uuid)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_body text;
  v_piece text := '';
  v_para text;
  v_pos int := 0;
begin
  if not public.is_system_admin() then
    raise exception 'Only the system admin can do this' using errcode = '42501';
  end if;
  select body into v_body from public.assistant_documents where id = p_document;
  if v_body is null then return 0; end if;
  delete from public.assistant_chunks where document_id = p_document;
  foreach v_para in array regexp_split_to_array(v_body, E'\\n\\s*\\n') loop
    v_para := btrim(v_para);
    continue when v_para = '';
    -- A very long paragraph is split further.
    while length(v_para) > 1400 loop
      if v_piece <> '' then
        v_pos := v_pos + 1;
        insert into public.assistant_chunks (document_id, position, content) values (p_document, v_pos, v_piece);
        v_piece := '';
      end if;
      v_pos := v_pos + 1;
      insert into public.assistant_chunks (document_id, position, content) values (p_document, v_pos, left(v_para, 1200));
      v_para := substr(v_para, 1201);
    end loop;
    if length(v_piece) + length(v_para) > 900 and v_piece <> '' then
      v_pos := v_pos + 1;
      insert into public.assistant_chunks (document_id, position, content) values (p_document, v_pos, v_piece);
      v_piece := '';
    end if;
    v_piece := case when v_piece = '' then v_para else v_piece || E'\n\n' || v_para end;
  end loop;
  if v_piece <> '' then
    v_pos := v_pos + 1;
    insert into public.assistant_chunks (document_id, position, content) values (p_document, v_pos, v_piece);
  end if;
  return v_pos;
end $$;
revoke all on function public.assistant_index(uuid) from public, anon;
grant execute on function public.assistant_index(uuid) to authenticated;

-- The best matching pieces for a question, only from documents this kind of
-- visitor may use. Only the website's server (service role) can call this.
create or replace function public.assistant_search(p_query text, p_audiences text[], p_limit int default 5)
returns table (document_id uuid, title text, content text, rank real)
language sql
stable
security definer
set search_path = ''
as $$
  with q as (select websearch_to_tsquery('english', p_query) as tsq)
  select d.id, d.title, c.content, ts_rank_cd(c.fts, q.tsq) as rank
  from public.assistant_chunks c
  join public.assistant_documents d on d.id = c.document_id, q
  where d.audience = any (p_audiences) and c.fts @@ q.tsq
  order by rank desc
  limit greatest(1, least(p_limit, 10))
$$;
revoke all on function public.assistant_search(text, text[], int) from public, anon, authenticated;
grant execute on function public.assistant_search(text, text[], int) to service_role;

-- Questions asked this hour (for the limit) and money spent this month (AUD).
create or replace function public.assistant_usage()
returns table (this_month_usd numeric, last_hour bigint)
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select sum(cost_usd) from public.assistant_questions where created_at >= date_trunc('month', now())), 0),
         (select count(*) from public.assistant_questions where created_at >= now() - interval '1 hour')
$$;
revoke all on function public.assistant_usage() from public, anon, authenticated;
grant execute on function public.assistant_usage() to service_role;

-- Counts for the portal dashboard and menu: new enquiries.
create or replace function public.new_enquiry_count()
returns bigint
language sql
stable
security definer
set search_path = ''
as $$
  select case when public.has_role(array['manager', 'system_admin']::public.app_role[])
    then (select count(*) from public.website_enquiries where status = 'new') else 0 end
$$;
revoke all on function public.new_enquiry_count() from public, anon;
grant execute on function public.new_enquiry_count() to authenticated;

-- A new enquiry also tells the managers by the bell.
create or replace function public.website_enquiry_notify() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.notifications (user_id, kind, title, body, href)
  select p.id, 'website_enquiry', 'New enquiry: ' || new.full_name,
         'Phone ' || new.phone || '. Call them back.', '/enquiries'
  from public.profiles p where p.active and p.role in ('manager', 'system_admin');
  return new;
end $$;

drop trigger if exists website_enquiry_notify on public.website_enquiries;
create trigger website_enquiry_notify after insert on public.website_enquiries
  for each row execute function public.website_enquiry_notify();

commit;
