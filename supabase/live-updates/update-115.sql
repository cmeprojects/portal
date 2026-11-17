-- Staff Portal · © cmeproject. All rights reserved.
-- Update 115: service agreements per service, with the scheme from the
-- program and an ending reminder (Care block C6). Safe to run again.
-- Undo: undo-115.sql. Run update 114 first.
begin;
--
-- cmeprojects (update 115; Care block C6): service agreements.
--
--   * New part "Service agreements" (sensitive). Managers: every client;
--     Case Manager: assigned clients, view only; Intake: every client, view
--     and change (they set agreements up). Staff admins and team staff: none.
--   * Each agreement is for one service; its scheme comes from that service's
--     program (NDIS and Support at Home never mix). Draft, sent, signed, then
--     ended. Signing needs the date and who signed. A signed agreement's
--     service, dates and signature are fixed: a change is a new agreement.
--     It can link to the signed copy in Documents. Nothing is deleted.
--   * A reminder 30 days before a signed agreement ends, to the assigned care
--     manager or support coordinator (else the managers).

insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order, actions) values
  ('clients.agreements', 'clients.list', 'clients', 'Service agreements', 'sensitive', true, 262, '{view,edit}')
on conflict (id) do nothing;

create table if not exists public.client_agreements (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id) on delete restrict,
  service_id uuid not null references public.client_services (id) on delete restrict,
  scheme text not null default 'other' references public.client_schemes (key) on delete restrict,
  status text not null default 'draft' check (status in ('draft', 'sent', 'signed', 'ended')),
  starts_on date not null,
  ends_on date,
  signed_on date,
  signed_by_name text not null default '' check (length(signed_by_name) <= 120),
  document_id uuid references public.client_documents (id) on delete restrict,
  notes text not null default '' check (length(notes) <= 1000),
  created_by uuid default auth.uid() references public.profiles (id),
  created_at timestamptz not null default now(),
  ended_at timestamptz,
  updated_by uuid references public.profiles (id),
  updated_at timestamptz not null default now(),
  check (ends_on is null or ends_on >= starts_on)
);
create index if not exists client_agreements_client on public.client_agreements (client_id);
alter table public.client_agreements enable row level security;
drop policy if exists "see agreements" on public.client_agreements;
create policy "see agreements" on public.client_agreements
  for select to authenticated
  using (((select public.can('clients.agreements'::text, 'view'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
         or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
             and public.can('clients.agreements'::text, 'view'::text, client_id)));
drop policy if exists "add agreements" on public.client_agreements;
create policy "add agreements" on public.client_agreements
  for insert to authenticated
  with check (((select public.can('clients.agreements'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
              or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
                  and public.can('clients.agreements'::text, 'edit'::text, client_id)));
drop policy if exists "change agreements" on public.client_agreements;
create policy "change agreements" on public.client_agreements
  for update to authenticated
  using (((select public.can('clients.agreements'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
         or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
             and public.can('clients.agreements'::text, 'edit'::text, client_id)))
  with check (((select public.can('clients.agreements'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
              or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
                  and public.can('clients.agreements'::text, 'edit'::text, client_id)));
-- No delete rule.
grant select, insert, update on public.client_agreements to authenticated;

create or replace function public.guard_client_agreement()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_scheme text;
begin
  if new.document_id is not null and not exists (select 1 from public.client_documents d where d.id = new.document_id and d.client_id = new.client_id) then
    raise exception 'That document belongs to another client.';
  end if;
  if tg_op = 'INSERT' then
    select p.scheme into v_scheme
      from public.client_services s join public.client_programs p on p.id = s.program_id
     where s.id = new.service_id and s.client_id = new.client_id;
    if v_scheme is null then
      raise exception 'That service belongs to another client.';
    end if;
    new.scheme := v_scheme;
    new.created_by := auth.uid();
    new.created_at := now();
    new.ended_at := null;
    if new.status in ('signed', 'ended') then
      new.status := 'draft';
    end if;
    new.signed_on := null;
    new.signed_by_name := '';
    return new;
  end if;
  if (new.service_id, new.scheme, new.created_by, new.created_at) is distinct from (old.service_id, old.scheme, old.created_by, old.created_at) then
    raise exception 'An agreement stays with its service. Add a new agreement instead.';
  end if;
  if old.status = 'ended' and new is distinct from old then
    raise exception 'This agreement has ended. Add a new one instead.';
  end if;
  if old.status = 'signed' then
    if new.status not in ('signed', 'ended') then
      raise exception 'A signed agreement can only end.';
    end if;
    if (new.starts_on, new.ends_on, new.signed_on, new.signed_by_name) is distinct from (old.starts_on, old.ends_on, old.signed_on, old.signed_by_name) then
      raise exception 'A signed agreement''s dates and signature are fixed. Add a new agreement instead.';
    end if;
  end if;
  if new.status = 'signed' and old.status <> 'signed' then
    if new.signed_on is null or length(trim(new.signed_by_name)) = 0 then
      raise exception 'Record when it was signed and who signed it.';
    end if;
  end if;
  if new.status = 'ended' and old.status <> 'ended' then
    new.ended_at := now();
  else
    new.ended_at := old.ended_at;
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_client_agreement() from public, anon, authenticated;
drop trigger if exists guard_client_agreement on public.client_agreements;
create trigger guard_client_agreement before insert or update on public.client_agreements
  for each row execute function public.guard_client_agreement();
drop trigger if exists log_client_agreements on public.client_agreements;
create trigger log_client_agreements before insert or update on public.client_agreements
  for each row execute function public.log_client_change();

-- The hourly timer: documents (112), reviews (114) and agreements ending.
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
  v_agreements int := 0;
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

  -- Signed agreements ending within 30 days (update 115).
  if coalesce((select (value #>> '{}')::boolean from public.app_settings where key = 'care.section_agreements'), true) then
    for d in
      select ag.id, ag.client_id, ag.ends_on, c.name, c.client_ref, sc.label as scheme_label
        from public.client_agreements ag
        join public.car_clients c on c.id = ag.client_id
        join public.client_schemes sc on sc.key = ag.scheme
       where ag.status = 'signed' and ag.ends_on is not null and ag.ends_on <= v_today + 30 and ag.ends_on >= v_today
    loop
      if not exists (select 1 from public.care_alerts_sent s where s.kind = 'client_agreement_ending' and s.item_id = d.id and s.due_on = d.ends_on) then
        insert into public.care_alerts_sent (kind, item_id, due_on) values ('client_agreement_ending', d.id, d.ends_on);
        perform public.notify(u, 'client_agreement_ending',
          'Service agreement ends ' || to_char(d.ends_on, 'DD Mon YYYY'),
          d.name || ' (' || d.client_ref || ') · ' || d.scheme_label, '/settings/clients/' || d.client_id, true)
          from public.client_care_contacts(d.client_id) u;
        v_agreements := v_agreements + 1;
      end if;
    end loop;
  end if;
  return jsonb_build_object('client_documents', v_docs, 'client_reviews', v_reviews, 'client_agreements', v_agreements);
end;
$$;
revoke execute on function public.run_care_alerts() from public, anon, authenticated;
grant execute on function public.run_care_alerts() to service_role;

-- Switched over from the start, with defaults.
update public.app_modules set grant_ready = true where id = 'clients.agreements' and not grant_ready;
do $$
declare
  v_cm uuid := (select id from public.job_titles where name = 'Case Manager' and active limit 1);
  v_io uuid := (select id from public.job_titles where name = 'Intake & Assessment Officer' and active limit 1);
begin
  if not exists (select 1 from public.access_baselines where module_id = 'clients.agreements' and revoked_at is null) then
    insert into public.access_baselines (access_level, module_id, actions, scope, note)
    values ('manager', 'clients.agreements', '{}', 'all', 'Care block default: managers, every client');
    if v_cm is not null then
      insert into public.access_baselines (job_title_id, module_id, actions, scope, note)
      values (v_cm, 'clients.agreements', '{view}', 'assigned', 'Care block default: case managers, assigned clients, view');
    end if;
    if v_io is not null then
      insert into public.access_baselines (job_title_id, module_id, actions, scope, note)
      values (v_io, 'clients.agreements', '{view,edit}', 'all', 'Care block default: intake, every client');
    end if;
  end if;
end $$;
commit;
