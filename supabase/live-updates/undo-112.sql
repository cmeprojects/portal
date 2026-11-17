-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 112: removes client documents (the table, its file rules and
-- reminders). Files already uploaded stay in the private store (not deleted),
-- unreadable until the update is run again. Safe to run again.
begin;
do $do$
begin
  if to_regclass('storage.objects') is not null then
    drop policy if exists "client document holders read files" on storage.objects;
    drop policy if exists "client document holders add files" on storage.objects;
  end if;
end
$do$;
drop function if exists public.run_care_alerts();
drop function if exists public.client_care_contacts(uuid);
drop table if exists public.care_alerts_sent;
drop table if exists public.client_documents;
drop function if exists public.guard_client_document();
update public.access_baselines set revoked_at = now() where module_id = 'clients.documents' and revoked_at is null;
update public.app_modules set grant_ready = false where id = 'clients.documents';
commit;
