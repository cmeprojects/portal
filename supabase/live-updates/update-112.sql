-- Staff Portal · © cmeproject. All rights reserved.
-- Update 112: client documents in a private store, with expiry reminders
-- (Care block C3). Safe to run again. Undo: undo-112.sql. Run update 111 first.
begin;
-- cmeprojects (update 112; Care block C3): client documents.
--
--   * New part "Client documents" (sensitive: a role or a person only, never a
--     whole function group). Managers: every client; Case Manager: assigned
--     clients, view and add; Intake: every client, view and add. Staff admins
--     and team staff: none.
--   * Files go in a private store ("client-docs"), 10 MB at most, PDF, images
--     (JPEG, PNG, WebP, HEIC) and Word only. A file can only be read or added
--     by someone who may see that client's documents; nobody changes or
--     deletes a file (a new version replaces it; the old one is kept).
--   * Each document: type, title, optional expiry date, version. Archiving
--     hides it from the list; nothing is deleted. Changes go in the change log
--     (which document, never its contents).
--   * Expiry reminders (30 days before and on the day) to the client's
--     assigned care manager or support coordinator, else the managers, from
--     the hourly timer (run_care_alerts, runnable by the server only).

insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order, actions) values
  ('clients.documents', 'clients.list', 'clients', 'Client documents', 'sensitive', true, 259, '{view,edit}')
on conflict (id) do nothing;

create table if not exists public.client_documents (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id) on delete restrict,
  doc_type text not null default 'other' check (doc_type in ('consent', 'assessment', 'plan', 'report', 'agreement', 'correspondence', 'identity', 'other')),
  title text not null check (length(title) between 1 and 120),
  file_path text not null unique check (file_path ~ '^[0-9a-f-]{36}/[^/]{1,200}$'),
  file_name text not null check (length(file_name) between 1 and 160),
  mime_type text not null,
  size_bytes int not null check (size_bytes between 1 and 10485760),
  expires_on date,
  version int not null default 1 check (version >= 1),
  replaces_id uuid references public.client_documents (id) on delete restrict,
  uploaded_by uuid default auth.uid() references public.profiles (id),
  created_at timestamptz not null default now(),
  archived_at timestamptz,
  archived_by uuid references public.profiles (id),
  updated_by uuid references public.profiles (id),
  updated_at timestamptz not null default now()
);
create index if not exists client_documents_client on public.client_documents (client_id) where archived_at is null;
create index if not exists client_documents_expiry on public.client_documents (expires_on) where archived_at is null and expires_on is not null;
alter table public.client_documents enable row level security;

drop policy if exists "see client documents" on public.client_documents;
create policy "see client documents" on public.client_documents
  for select to authenticated
  using (((select public.can('clients.documents'::text, 'view'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
         or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
             and public.can('clients.documents'::text, 'view'::text, client_id)));
drop policy if exists "add client documents" on public.client_documents;
create policy "add client documents" on public.client_documents
  for insert to authenticated
  with check (((select public.can('clients.documents'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
              or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
                  and public.can('clients.documents'::text, 'edit'::text, client_id)));
drop policy if exists "archive client documents" on public.client_documents;
create policy "archive client documents" on public.client_documents
  for update to authenticated
  using (((select public.can('clients.documents'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
         or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
             and public.can('clients.documents'::text, 'edit'::text, client_id)))
  with check (((select public.can('clients.documents'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
              or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
                  and public.can('clients.documents'::text, 'edit'::text, client_id)));
-- No delete rule.
grant select, insert, update on public.client_documents to authenticated;

-- A document's file never changes; only its title, type, expiry and archiving.
create or replace function public.guard_client_document()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if split_part(new.file_path, '/', 1) <> new.client_id::text then
      raise exception 'That file isn''t in this client''s folder.';
    end if;
    new.uploaded_by := auth.uid();
    new.created_at := now();
    new.archived_at := null;
    new.archived_by := null;
    if new.replaces_id is not null then
      if not exists (select 1 from public.client_documents d where d.id = new.replaces_id and d.client_id = new.client_id) then
        raise exception 'The document being replaced belongs to another client.';
      end if;
      new.version := (select d.version + 1 from public.client_documents d where d.id = new.replaces_id);
    end if;
    return new;
  end if;
  if new.file_path is distinct from old.file_path or new.file_name is distinct from old.file_name or new.mime_type is distinct from old.mime_type
     or new.size_bytes is distinct from old.size_bytes or new.version is distinct from old.version or new.replaces_id is distinct from old.replaces_id
     or new.uploaded_by is distinct from old.uploaded_by or new.created_at is distinct from old.created_at then
    raise exception 'A document''s file isn''t changed. Upload a new version instead.';
  end if;
  if old.archived_at is not null and new.archived_at is null then
    raise exception 'An archived document stays archived.';
  end if;
  if new.archived_at is not null and old.archived_at is null then
    new.archived_at := now();
    new.archived_by := auth.uid();
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_client_document() from public, anon, authenticated;
drop trigger if exists guard_client_document on public.client_documents;
create trigger guard_client_document before insert or update on public.client_documents
  for each row execute function public.guard_client_document();
drop trigger if exists log_client_documents on public.client_documents;
create trigger log_client_documents before insert or update on public.client_documents
  for each row execute function public.log_client_change();

-- The files: a private store, read and added only with access to that
-- client's documents. (Skipped where there's no file storage, e.g. tests.)
do $do$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values ('client-docs', 'client-docs', false, 10485760,
          array['application/pdf', 'image/jpeg', 'image/png', 'image/webp', 'image/heic',
                'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
  on conflict (id) do update set public = false, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;
  drop policy if exists "client document holders read files" on storage.objects;
  create policy "client document holders read files" on storage.objects
    for select to authenticated
    using (bucket_id = 'client-docs' and (storage.foldername(name))[1] ~ '^[0-9a-f-]{36}$'
           and public.can('clients.documents', 'view', ((storage.foldername(name))[1])::uuid));
  drop policy if exists "client document holders add files" on storage.objects;
  create policy "client document holders add files" on storage.objects
    for insert to authenticated
    with check (bucket_id = 'client-docs' and (storage.foldername(name))[1] ~ '^[0-9a-f-]{36}$'
                and public.can('clients.documents', 'edit', ((storage.foldername(name))[1])::uuid));
  -- No update or delete rule: files are never changed or removed.
end
$do$;

-- Reminders the hourly timer sends (one per document, kind and day).
create table if not exists public.care_alerts_sent (
  kind text not null,
  item_id uuid not null,
  due_on date not null,
  sent_at timestamptz not null default now(),
  primary key (kind, item_id, due_on)
);
alter table public.care_alerts_sent enable row level security;
-- No policies: only the server's timer reads and writes it.

-- Who hears about a client: their current care manager or support
-- coordinator, else the active managers.
create or replace function public.client_care_contacts(p_client uuid)
returns setof uuid
language sql
stable
security invoker
set search_path = ''
as $$
  with assigned as (
    select a.user_id from public.client_assignments a join public.profiles p on p.id = a.user_id and p.active
     where a.client_id = p_client and a.ended_at is null and a.assigned_as in ('case_manager', 'support_coordinator')
       and a.starts_on <= public.local_today() and (a.ends_on is null or a.ends_on >= public.local_today()))
  select user_id from assigned
  union all
  select id from public.profiles where active and role = 'manager' and not exists (select 1 from assigned)
$$;
revoke execute on function public.client_care_contacts(uuid) from public, anon, authenticated;

create or replace function public.run_care_alerts()
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  d record;
  v_docs int := 0;
begin
  if coalesce((select (value #>> '{}')::boolean from public.app_settings where key = 'care.section_documents'), true) then
    for d in
      select doc.id, doc.client_id, doc.title, doc.expires_on, c.name, c.client_ref,
             case when doc.expires_on <= public.local_today() then 'client_doc_expired' else 'client_doc_expiring' end as kind
        from public.client_documents doc join public.car_clients c on c.id = doc.client_id
       where doc.archived_at is null and doc.expires_on is not null
         and doc.expires_on <= public.local_today() + 30
         and not exists (select 1 from public.client_documents newer where newer.replaces_id = doc.id)
    loop
      if not exists (select 1 from public.care_alerts_sent s where s.kind = d.kind and s.item_id = d.id and s.due_on = d.expires_on) then
        insert into public.care_alerts_sent (kind, item_id, due_on) values (d.kind, d.id, d.expires_on);
        perform public.notify(u, d.kind,
          case when d.kind = 'client_doc_expired' then d.title || ' has expired' else d.title || ' expires on ' || to_char(d.expires_on, 'DD Mon YYYY') end,
          d.name || ' (' || d.client_ref || ')', '/settings/clients/' || d.client_id, true)
          from public.client_care_contacts(d.client_id) u;
        v_docs := v_docs + 1;
      end if;
    end loop;
  end if;
  return jsonb_build_object('client_documents', v_docs);
end;
$$;
revoke execute on function public.run_care_alerts() from public, anon, authenticated;
grant execute on function public.run_care_alerts() to service_role;

-- Switched over from the start, with defaults.
update public.app_modules set grant_ready = true where id = 'clients.documents' and not grant_ready;
do $$
declare
  v_cm uuid := (select id from public.job_titles where name = 'Case Manager' and active limit 1);
  v_io uuid := (select id from public.job_titles where name = 'Intake & Assessment Officer' and active limit 1);
begin
  if not exists (select 1 from public.access_baselines where module_id = 'clients.documents' and revoked_at is null) then
    insert into public.access_baselines (access_level, module_id, actions, scope, note)
    values ('manager', 'clients.documents', '{}', 'all', 'Care block default: managers, every client');
    if v_cm is not null then
      insert into public.access_baselines (job_title_id, module_id, actions, scope, note)
      values (v_cm, 'clients.documents', '{view,edit}', 'assigned', 'Care block default: case managers, assigned clients');
    end if;
    if v_io is not null then
      insert into public.access_baselines (job_title_id, module_id, actions, scope, note)
      values (v_io, 'clients.documents', '{view,edit}', 'all', 'Care block default: intake, every client');
    end if;
  end if;
end $$;
commit;
