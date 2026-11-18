-- Staff Portal · © cmeproject. All rights reserved.
-- Update 131: speed. Practitioner read rules no longer run a per-client check
-- for staff, which slowed pages that read clients. Nobody's access changes.
-- Safe to run again. Undo: undo-131.sql.
begin;
-- Is the person signed in a practitioner (external)? Worked out once per query.
create or replace function public.practitioner_now()
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select exists (select 1 from public.profiles p where p.id = auth.uid() and p.active and p.role = 'external')
$$;
grant execute on function public.practitioner_now() to authenticated;
-- The per-client checks are costly: run them last.
alter function public.external_sees_basics(uuid, text) cost 10000;
alter function public.external_sees(uuid, text) cost 10000;

drop policy if exists "practitioners see their clients" on public.car_clients;
create policy "practitioners see their clients" on public.car_clients
  for select to authenticated
  using ((select public.practitioner_now()) and (archived_at is null and public.external_sees_basics(id)));

drop policy if exists "practitioners see client details" on public.client_details;
create policy "practitioners see client details" on public.client_details
  for select to authenticated
  using ((select public.practitioner_now()) and (public.external_sees(client_id, 'details')));

drop policy if exists "practitioners see client alerts" on public.client_alerts;
create policy "practitioners see client alerts" on public.client_alerts
  for select to authenticated
  using ((select public.practitioner_now()) and (active and public.external_sees(client_id, 'alerts')));

drop policy if exists "practitioners see care plans" on public.client_care_plans;
create policy "practitioners see care plans" on public.client_care_plans
  for select to authenticated
  using ((select public.practitioner_now()) and (public.external_sees(client_id, 'care_plan')));

drop policy if exists "practitioners see care goals" on public.client_care_goals;
create policy "practitioners see care goals" on public.client_care_goals
  for select to authenticated
  using ((select public.practitioner_now()) and (public.external_sees(client_id, 'care_plan')));

drop policy if exists "practitioners see worker instructions" on public.client_worker_instructions;
create policy "practitioners see worker instructions" on public.client_worker_instructions
  for select to authenticated
  using ((select public.practitioner_now()) and (active and public.external_sees(client_id, 'care_plan')));

drop policy if exists "practitioners see client documents" on public.client_documents;
create policy "practitioners see client documents" on public.client_documents
  for select to authenticated
  using ((select public.practitioner_now()) and (archived_at is null
         and ((shared_with_practitioners and public.external_sees(client_id, 'documents'))
              or (uploaded_by = (select auth.uid()) and public.external_sees(client_id)))));

drop policy if exists "practitioners add reports" on public.client_documents;
create policy "practitioners add reports" on public.client_documents
  for insert to authenticated
  with check ((select public.practitioner_now()) and (doc_type in ('report', 'assessment') and replaces_id is null and public.external_sees(client_id)));

drop policy if exists "see practitioner notes" on public.client_practitioner_notes;
create policy "see practitioner notes" on public.client_practitioner_notes
  for select to authenticated
  using (((select public.practitioner_now()) and ((author_id = (select auth.uid()) and public.external_sees(client_id))
              or public.external_sees(client_id, 'notes')))
         or ((select public.can('clients.external'::text, 'view'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
         or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
             and public.can('clients.external'::text, 'view'::text, client_id)));

drop policy if exists "write practitioner notes" on public.client_practitioner_notes;
create policy "write practitioner notes" on public.client_practitioner_notes
  for insert to authenticated
  with check ((select public.practitioner_now()) and (author_id = (select auth.uid()) and public.external_sees(client_id)));

drop policy if exists "change own practitioner notes" on public.client_practitioner_notes;
create policy "change own practitioner notes" on public.client_practitioner_notes
  for update to authenticated
  using ((select public.practitioner_now()) and (author_id = (select auth.uid()) and public.external_sees(client_id)))
  with check ((select public.practitioner_now()) and (author_id = (select auth.uid()) and public.external_sees(client_id)));

drop policy if exists "practitioners record views" on public.client_external_views;
create policy "practitioners record views" on public.client_external_views
  for insert to authenticated
  with check ((select public.practitioner_now()) and (user_id = (select auth.uid()) and viewed_at > now() - interval '1 minute' and public.external_sees(client_id)));

do $do$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  drop policy if exists "practitioners read shared files" on storage.objects;
  create policy "practitioners read shared files" on storage.objects
    for select to authenticated
    using (bucket_id = 'client-docs' and (storage.foldername(name))[1] ~ '^[0-9a-f-]{36}$'
           and (select public.practitioner_now()) and public.external_sees(((storage.foldername(name))[1])::uuid)
           and (owner = (select auth.uid()) or name in (select d.file_path from public.client_documents d)));
  drop policy if exists "practitioners add report files" on storage.objects;
  create policy "practitioners add report files" on storage.objects
    for insert to authenticated
    with check (bucket_id = 'client-docs' and (storage.foldername(name))[1] ~ '^[0-9a-f-]{36}$'
                and (select public.practitioner_now()) and public.external_sees(((storage.foldername(name))[1])::uuid));
end
$do$;
commit;
