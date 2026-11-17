-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 114: removes reviews and re-assessments (and everything
-- recorded in them) and puts the hourly reminders back to documents only.
-- Safe to run again.
begin;
drop table if exists public.client_reviews;
drop function if exists public.guard_client_review();
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
update public.access_baselines set revoked_at = now() where module_id = 'clients.reviews' and revoked_at is null;
update public.app_modules set grant_ready = false where id = 'clients.reviews';
commit;
