-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 124, Stage 6, D-058): Allied Health access, a premium package.
--
--   * Practitioners are `external` accounts. They see a client only while a
--     manager or the client's case manager has given them access: per client,
--     per section, from a start date to an end date (at most 12 months ahead),
--     with the client's consent recorded. On the end date access stops by itself.
--   * Two-factor sign-in is required: without it a practitioner sees nothing.
--   * Sections: details, alerts, care_plan, documents (shared ones), notes
--     (other practitioners' notes). Client basics (name, status) come with any
--     access. Practitioners can always upload their own reports and write their
--     own notes (changed within 24 hours). Funding, agreements, reviews, staff,
--     the roster and other clients are never shown.
--   * No new SECURITY DEFINER function: the checks are ordinary functions that
--     read the practitioner's own access rows.
--   * Reminders (server only): the practitioner hears when access is given and
--     14 days before it ends; the client's care contacts hear about new notes
--     and reports from practitioners.

insert into public.features (key, label, description, enabled, sort_order, premium, included) values
  ('allied_health', 'Allied Health access',
   'Outside practitioners (psychologists, OTs, physios and others) see the clients they are given, upload reports and write notes.',
   true, 46, true, true)
on conflict (key) do nothing;

insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order, actions) values
  ('clients.external', 'clients.list', 'clients', 'Allied Health practitioners', 'sensitive', true, 264, '{view,edit}')
on conflict (id) do nothing;

-- Who has access to which client.
create table if not exists public.client_external_access (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id) on delete restrict,
  user_id uuid not null references public.profiles (id) on delete restrict,
  sections text[] not null default '{details,alerts,care_plan,documents}',
  starts_on date not null default public.local_today(),
  ends_on date not null,
  consent_on date not null,
  consent_note text not null default '' check (length(consent_note) <= 500),
  consent_document_id uuid references public.client_documents (id) on delete restrict,
  reason text not null default '' check (length(reason) <= 500),
  given_by uuid references public.profiles (id) default auth.uid(),
  created_at timestamptz not null default now(),
  ended_at timestamptz,
  ended_by uuid references public.profiles (id),
  told_at timestamptz,
  updated_by uuid references public.profiles (id),
  updated_at timestamptz not null default now(),
  check (sections <@ array['details', 'alerts', 'care_plan', 'documents', 'notes']),
  check (ends_on >= starts_on)
);
create index if not exists client_external_access_user on public.client_external_access (user_id) where ended_at is null;
create index if not exists client_external_access_client on public.client_external_access (client_id) where ended_at is null;
create unique index if not exists client_external_access_one_open on public.client_external_access (client_id, user_id) where ended_at is null;
alter table public.client_external_access enable row level security;

-- My current access to a client (and section). Not for car_clients itself.
create or replace function public.external_sees_basics(p_client uuid, p_section text default null)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
     and public.feature_enabled('allied_health') -- practitioners can't read the features list
     and exists (select 1 from public.profiles p where p.id = auth.uid() and p.active and p.role = 'external')
     and exists (
       select 1 from public.client_external_access x
        where x.user_id = auth.uid() and x.client_id = p_client and x.ended_at is null
          and x.starts_on <= public.local_today() and x.ends_on >= public.local_today()
          and (p_section is null or p_section = any (x.sections)))
$$;

-- The same, and the client isn't archived.
create or replace function public.external_sees(p_client uuid, p_section text default null)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select public.external_sees_basics(p_client, p_section)
     and exists (select 1 from public.car_clients c where c.id = p_client and c.archived_at is null)
$$;
grant execute on function public.external_sees_basics(uuid, text) to authenticated;
grant execute on function public.external_sees(uuid, text) to authenticated;

drop policy if exists "see practitioner access" on public.client_external_access;
create policy "see practitioner access" on public.client_external_access
  for select to authenticated
  using (user_id = (select auth.uid())
         or ((select public.can('clients.external'::text, 'view'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
         or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
             and public.can('clients.external'::text, 'view'::text, client_id)));
drop policy if exists "give practitioner access" on public.client_external_access;
create policy "give practitioner access" on public.client_external_access
  for insert to authenticated
  with check (public.feature_live('allied_health')
              and (((select public.can('clients.external'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
                   or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
                       and public.can('clients.external'::text, 'edit'::text, client_id))));
drop policy if exists "change practitioner access" on public.client_external_access;
create policy "change practitioner access" on public.client_external_access
  for update to authenticated
  using (((select public.can('clients.external'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
         or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
             and public.can('clients.external'::text, 'edit'::text, client_id)))
  with check (((select public.can('clients.external'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
              or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
                  and public.can('clients.external'::text, 'edit'::text, client_id)));
-- No delete rule: ended access stays on record.
grant select, insert, update on public.client_external_access to authenticated;

create or replace function public.guard_external_access()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if pg_trigger_depth() > 1 then
    return new;
  end if;
  if tg_op = 'UPDATE' and new.told_at is distinct from old.told_at
     and (to_jsonb(new) - 'told_at' - 'updated_at' - 'updated_by') = (to_jsonb(old) - 'told_at' - 'updated_at' - 'updated_by') then
    return new;
  end if;
  if tg_op = 'INSERT' then
    if not exists (select 1 from public.profiles p where p.id = new.user_id and p.active and p.role = 'external') then
      raise exception 'Access can only be given to an active practitioner (external) account.';
    end if;
    new.given_by := auth.uid();
    new.created_at := now();
    new.ended_at := null;
    new.ended_by := null;
    new.told_at := null;
    if new.starts_on < public.local_today() then
      new.starts_on := public.local_today();
    end if;
  else
    if new.user_id is distinct from old.user_id or new.given_by is distinct from old.given_by or new.created_at is distinct from old.created_at then
      raise exception 'Give new access instead of changing who it''s for.';
    end if;
    if old.ended_at is not null then
      raise exception 'Ended access stays ended. Give new access instead.';
    end if;
    if new.ended_at is not null then
      new.ended_at := now();
      new.ended_by := auth.uid();
      return new;
    end if;
  end if;
  if new.consent_on is null or new.consent_on > public.local_today() then
    raise exception 'Record the date the client (or their representative) agreed.';
  end if;
  if new.ends_on > public.local_today() + interval '12 months' then
    raise exception 'Access can last at most 12 months from today. Extend it later if needed.';
  end if;
  if new.ends_on < public.local_today() then
    raise exception 'The end date has already passed.';
  end if;
  if new.consent_document_id is not null
     and not exists (select 1 from public.client_documents d where d.id = new.consent_document_id and d.client_id = new.client_id) then
    raise exception 'That consent document belongs to another client.';
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_external_access() from public, anon, authenticated;
drop trigger if exists guard_external_access on public.client_external_access;
create trigger guard_external_access before insert or update on public.client_external_access
  for each row execute function public.guard_external_access();
drop trigger if exists log_client_external_access on public.client_external_access;
create trigger log_client_external_access before insert or update on public.client_external_access
  for each row execute function public.log_client_change();

-- What practitioners can read.
drop policy if exists "practitioners see their clients" on public.car_clients;
create policy "practitioners see their clients" on public.car_clients
  for select to authenticated
  using (archived_at is null and public.external_sees_basics(id));
drop policy if exists "practitioners see client details" on public.client_details;
create policy "practitioners see client details" on public.client_details
  for select to authenticated
  using (public.external_sees(client_id, 'details'));
drop policy if exists "practitioners see client alerts" on public.client_alerts;
create policy "practitioners see client alerts" on public.client_alerts
  for select to authenticated
  using (active and public.external_sees(client_id, 'alerts'));
drop policy if exists "practitioners see care plans" on public.client_care_plans;
create policy "practitioners see care plans" on public.client_care_plans
  for select to authenticated
  using (public.external_sees(client_id, 'care_plan'));
drop policy if exists "practitioners see care goals" on public.client_care_goals;
create policy "practitioners see care goals" on public.client_care_goals
  for select to authenticated
  using (public.external_sees(client_id, 'care_plan'));
drop policy if exists "practitioners see worker instructions" on public.client_worker_instructions;
create policy "practitioners see worker instructions" on public.client_worker_instructions
  for select to authenticated
  using (active and public.external_sees(client_id, 'care_plan'));

-- Documents: shared ones (with the documents section), and their own.
alter table public.client_documents add column if not exists shared_with_practitioners boolean not null default false;
drop policy if exists "practitioners see client documents" on public.client_documents;
create policy "practitioners see client documents" on public.client_documents
  for select to authenticated
  using (archived_at is null
         and ((shared_with_practitioners and public.external_sees(client_id, 'documents'))
              or (uploaded_by = (select auth.uid()) and public.external_sees(client_id))));
drop policy if exists "practitioners add reports" on public.client_documents;
create policy "practitioners add reports" on public.client_documents
  for insert to authenticated
  with check (doc_type in ('report', 'assessment') and replaces_id is null and public.external_sees(client_id));

do $do$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  drop policy if exists "practitioners read shared files" on storage.objects;
  create policy "practitioners read shared files" on storage.objects
    for select to authenticated
    using (bucket_id = 'client-docs' and (storage.foldername(name))[1] ~ '^[0-9a-f-]{36}$'
           and public.external_sees(((storage.foldername(name))[1])::uuid)
           and (owner = (select auth.uid()) or name in (select d.file_path from public.client_documents d)));
  drop policy if exists "practitioners add report files" on storage.objects;
  create policy "practitioners add report files" on storage.objects
    for insert to authenticated
    with check (bucket_id = 'client-docs' and (storage.foldername(name))[1] ~ '^[0-9a-f-]{36}$'
                and public.external_sees(((storage.foldername(name))[1])::uuid));
end
$do$;

-- Practitioner notes.
create table if not exists public.client_practitioner_notes (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id) on delete restrict,
  author_id uuid references public.profiles (id) default auth.uid(),
  note_date date not null default public.local_today(),
  body text not null check (length(body) between 1 and 5000),
  created_at timestamptz not null default now(),
  told_at timestamptz,
  updated_by uuid references public.profiles (id),
  updated_at timestamptz not null default now()
);
create index if not exists client_practitioner_notes_client on public.client_practitioner_notes (client_id, note_date desc);
alter table public.client_practitioner_notes enable row level security;

drop policy if exists "see practitioner notes" on public.client_practitioner_notes;
create policy "see practitioner notes" on public.client_practitioner_notes
  for select to authenticated
  using ((author_id = (select auth.uid()) and public.external_sees(client_id))
         or public.external_sees(client_id, 'notes')
         or ((select public.can('clients.external'::text, 'view'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
         or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
             and public.can('clients.external'::text, 'view'::text, client_id)));
drop policy if exists "write practitioner notes" on public.client_practitioner_notes;
create policy "write practitioner notes" on public.client_practitioner_notes
  for insert to authenticated
  with check (author_id = (select auth.uid()) and public.external_sees(client_id));
drop policy if exists "change own practitioner notes" on public.client_practitioner_notes;
create policy "change own practitioner notes" on public.client_practitioner_notes
  for update to authenticated
  using (author_id = (select auth.uid()) and public.external_sees(client_id))
  with check (author_id = (select auth.uid()) and public.external_sees(client_id));
-- No delete rule.
grant select, insert, update on public.client_practitioner_notes to authenticated;

create or replace function public.guard_practitioner_note()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if pg_trigger_depth() > 1 then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.author_id := auth.uid();
    new.created_at := now();
    new.told_at := null;
  else
    if new.told_at is distinct from old.told_at
       and (to_jsonb(new) - 'told_at' - 'updated_at' - 'updated_by') = (to_jsonb(old) - 'told_at' - 'updated_at' - 'updated_by') then
      return new; -- the server marking a reminder as sent
    end if;
    if new.author_id is distinct from old.author_id or new.created_at is distinct from old.created_at then
      raise exception 'A note stays with the person who wrote it.';
    end if;
    if old.created_at < now() - interval '24 hours' then
      raise exception 'Notes can only be changed within 24 hours. Add a new note instead.';
    end if;
    new.told_at := old.told_at;
  end if;
  if new.note_date > public.local_today() then
    raise exception 'The note date can''t be in the future.';
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_practitioner_note() from public, anon, authenticated;
drop trigger if exists guard_practitioner_note on public.client_practitioner_notes;
create trigger guard_practitioner_note before insert or update on public.client_practitioner_notes
  for each row execute function public.guard_practitioner_note();
drop trigger if exists log_client_practitioner_notes on public.client_practitioner_notes;
create trigger log_client_practitioner_notes before insert or update on public.client_practitioner_notes
  for each row execute function public.log_client_change();

-- Who opened which client page (practitioners only).
create table if not exists public.client_external_views (
  id bigint generated always as identity primary key,
  client_id uuid not null references public.car_clients (id) on delete restrict,
  user_id uuid not null default auth.uid() references public.profiles (id) on delete restrict,
  viewed_at timestamptz not null default now()
);
create index if not exists client_external_views_client on public.client_external_views (client_id, viewed_at desc);
alter table public.client_external_views enable row level security;
drop policy if exists "practitioners record views" on public.client_external_views;
create policy "practitioners record views" on public.client_external_views
  for insert to authenticated
  with check (user_id = (select auth.uid()) and viewed_at > now() - interval '1 minute' and public.external_sees(client_id));
drop policy if exists "see practitioner views" on public.client_external_views;
create policy "see practitioner views" on public.client_external_views
  for select to authenticated
  using (((select public.can('clients.external'::text, 'view'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
         or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
             and public.can('clients.external'::text, 'view'::text, client_id)));
grant select, insert on public.client_external_views to authenticated;

-- Reminders (the hourly timer, server only).
create or replace function public.run_practitioner_alerts()
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  r record;
  v_given int := 0;
  v_ending int := 0;
  v_notes int := 0;
  v_reports int := 0;
begin
  if not public.feature_live('allied_health') then
    return jsonb_build_object('skipped', 'allied_health off');
  end if;
  for r in
    select x.id, x.user_id, x.client_id, x.ends_on, c.name, c.preferred_name
      from public.client_external_access x join public.car_clients c on c.id = x.client_id
     where x.ended_at is null and x.told_at is null and x.ends_on >= public.local_today() and c.archived_at is null
  loop
    perform public.notify(r.user_id, 'practitioner_access_given',
      'You can now see ' || coalesce(nullif(r.preferred_name, ''), r.name),
      'Until ' || to_char(r.ends_on, 'DD Mon YYYY') || '.', '/practitioner', true);
    update public.client_external_access set told_at = now() where id = r.id;
    v_given := v_given + 1;
  end loop;
  for r in
    select x.id, x.user_id, x.client_id, x.ends_on, c.name, c.preferred_name, c.client_ref
      from public.client_external_access x join public.car_clients c on c.id = x.client_id
     where x.ended_at is null and c.archived_at is null
       and x.ends_on between public.local_today() and public.local_today() + 14
  loop
    if not exists (select 1 from public.care_alerts_sent s where s.kind = 'practitioner_access_ending' and s.item_id = r.id and s.due_on = r.ends_on) then
      insert into public.care_alerts_sent (kind, item_id, due_on) values ('practitioner_access_ending', r.id, r.ends_on);
      perform public.notify(r.user_id, 'practitioner_access_ending',
        'Your access to ' || coalesce(nullif(r.preferred_name, ''), r.name) || ' ends on ' || to_char(r.ends_on, 'DD Mon YYYY'),
        'Ask the client''s case manager if you need longer.', '/practitioner', true);
      perform public.notify(u, 'practitioner_access_ending',
        'A practitioner''s access ends on ' || to_char(r.ends_on, 'DD Mon YYYY'),
        r.name || ' (' || r.client_ref || ')', '/settings/clients/' || r.client_id || '?tab=practitioners', false)
        from public.client_care_contacts(r.client_id) u;
      v_ending := v_ending + 1;
    end if;
  end loop;
  for r in
    select n.id, n.client_id, c.name, c.client_ref, coalesce(p.full_name, p.email) as who
      from public.client_practitioner_notes n
      join public.car_clients c on c.id = n.client_id
      left join public.profiles p on p.id = n.author_id
     where n.told_at is null
  loop
    perform public.notify(u, 'practitioner_note', r.who || ' added a note', r.name || ' (' || r.client_ref || ')',
      '/settings/clients/' || r.client_id || '?tab=practitioners', false)
      from public.client_care_contacts(r.client_id) u;
    update public.client_practitioner_notes set told_at = now() where id = r.id;
    v_notes := v_notes + 1;
  end loop;
  for r in
    select d.id, d.client_id, d.title, d.created_at, c.name, c.client_ref, coalesce(p.full_name, p.email) as who
      from public.client_documents d
      join public.car_clients c on c.id = d.client_id
      join public.profiles p on p.id = d.uploaded_by and p.role = 'external'
     where d.created_at > now() - interval '7 days'
  loop
    if not exists (select 1 from public.care_alerts_sent s where s.kind = 'practitioner_report' and s.item_id = r.id) then
      insert into public.care_alerts_sent (kind, item_id, due_on) values ('practitioner_report', r.id, (r.created_at at time zone 'Australia/Sydney')::date);
      perform public.notify(u, 'practitioner_report', r.who || ' uploaded ' || r.title, r.name || ' (' || r.client_ref || ')',
        '/settings/clients/' || r.client_id || '?tab=documents', false)
        from public.client_care_contacts(r.client_id) u;
      v_reports := v_reports + 1;
    end if;
  end loop;
  return jsonb_build_object('given', v_given, 'ending', v_ending, 'notes', v_notes, 'reports', v_reports);
end;
$$;
revoke execute on function public.run_practitioner_alerts() from public, anon, authenticated;
grant execute on function public.run_practitioner_alerts() to service_role;

-- Switched over from the start, with defaults: managers for every client,
-- case managers for their assigned clients.
update public.app_modules set grant_ready = true where id = 'clients.external' and not grant_ready;
do $$
declare
  v_cm uuid := (select id from public.job_titles where name = 'Case Manager' and active limit 1);
begin
  if not exists (select 1 from public.access_baselines where module_id = 'clients.external' and revoked_at is null) then
    insert into public.access_baselines (access_level, module_id, actions, scope, note)
    values ('manager', 'clients.external', '{}', 'all', 'Allied Health default: managers, every client');
    if v_cm is not null then
      insert into public.access_baselines (job_title_id, module_id, actions, scope, note)
      values (v_cm, 'clients.external', '{view,edit}', 'assigned', 'Allied Health default: case managers, assigned clients');
    end if;
  end if;
end $$;
