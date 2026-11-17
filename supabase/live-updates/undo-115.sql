-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 115: removes service agreements (and everything recorded in
-- them) and puts the hourly reminders back to documents and reviews.
-- Safe to run again.
begin;
create or replace function public.run_care_alerts()
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  d record;
  v_docs int := 0;
  v_reviews int := 0;
  v_today date := public.local_today();
begin
  if coalesce((select (value #>> '{}')::boolean from public.app_settings where key = 'care.section_documents'), true) then
    for d in
      select doc.id, doc.client_id, doc.title, doc.expires_on, c.name, c.client_ref,
             case when doc.expires_on <= v_today then 'client_doc_expired' else 'client_doc_expiring' end as kind
        from public.client_documents doc join public.car_clients c on c.id = doc.client_id
       where doc.archived_at is null and doc.expires_on is not null
         and doc.expires_on <= v_today + 30
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

  if coalesce((select (value #>> '{}')::boolean from public.app_settings where key = 'care.section_reviews'), true) then
    for d in
      select r.id, r.client_id, c.name, c.client_ref, sc.label as scheme_label,
             case when r.kind = 'change_of_situation' then 'client_review_change'
                  when r.due_on < v_today then 'client_review_overdue'
                  else 'client_review_due' end as kind,
             case when r.kind = 'change_of_situation' then sc.change_review_label else sc.review_label end as review_label,
             r.due_on,
             -- The reminder point reached most recently (one reminder per point).
             case when r.kind = 'change_of_situation' or r.due_on < v_today then r.due_on
                  else (select r.due_on - min(l) from unnest(sc.review_lead_days) l where r.due_on - l <= v_today) end as point
        from public.client_reviews r
        join public.car_clients c on c.id = r.client_id
        join public.client_schemes sc on sc.key = r.scheme
       where r.status = 'open'
    loop
      continue when d.point is null;
      if not exists (select 1 from public.care_alerts_sent s where s.kind = d.kind and s.item_id = d.id and s.due_on = d.point) then
        insert into public.care_alerts_sent (kind, item_id, due_on) values (d.kind, d.id, d.point);
        perform public.notify(u, d.kind,
          case d.kind when 'client_review_change' then d.review_label || ' raised'
                      when 'client_review_overdue' then d.review_label || ' is overdue'
                      else d.review_label || ' due ' || to_char(d.due_on, 'DD Mon YYYY') end,
          d.name || ' (' || d.client_ref || ') · ' || d.scheme_label, '/settings/clients/' || d.client_id, true)
          from public.client_care_contacts(d.client_id) u;
        v_reviews := v_reviews + 1;
      end if;
    end loop;
  end if;
  return jsonb_build_object('client_documents', v_docs, 'client_reviews', v_reviews);
end;
$$;
revoke execute on function public.run_care_alerts() from public, anon, authenticated;
grant execute on function public.run_care_alerts() to service_role;
drop table if exists public.client_agreements;
drop function if exists public.guard_client_agreement();
update public.access_baselines set revoked_at = now() where module_id = 'clients.agreements' and revoked_at is null;
update public.app_modules set grant_ready = false where id = 'clients.agreements';
commit;
