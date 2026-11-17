-- Staff Portal · © cmeproject. All rights reserved.
-- Update 114: reviews and re-assessments, kept apart by scheme, with
-- reminders (Care block C5). Safe to run again. Undo: undo-114.sql. Run update 113 first.
begin;
--
-- cmeprojects (update 114; Care block C5): reviews and re-assessments, kept
-- apart by scheme (owner: NDIS has plan reviews, Support at Home has
-- re-assessments; wording and rules never cross over).
--
--   * New part "Reviews" (sensitive). Managers: every client; Case Manager:
--     assigned clients, view and change. Staff admins, Intake and team staff:
--     none by default.
--   * Each review belongs to one scheme (from the service's program when a
--     service is chosen, so it can't be mixed up). Its name comes from that
--     scheme: NDIS "Plan review" / "Change of situation"; Support at Home
--     "Re-assessment" / "Re-assessment (change of situation)".
--   * Two kinds: scheduled (has a due date) and change of situation (needs a
--     reason, due straight away). Open, then completed (with the outcome) or
--     cancelled; a closed review isn't reopened. Nothing is deleted.
--   * Reminders to the assigned care manager or support coordinator (else the
--     managers): at each of the scheme's reminder points before the due date
--     (NDIS 90, 60 and 30 days; Support at Home 30 days; changeable in Care
--     settings), once when overdue, and straight away for a change of
--     situation. Reminders name the client and the review, never the reason.

insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order, actions) values
  ('clients.reviews', 'clients.list', 'clients', 'Reviews and re-assessments', 'sensitive', true, 261, '{view,edit}')
on conflict (id) do nothing;

create table if not exists public.client_reviews (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id) on delete restrict,
  scheme text not null references public.client_schemes (key) on delete restrict,
  service_id uuid references public.client_services (id) on delete restrict,
  kind text not null default 'scheduled' check (kind in ('scheduled', 'change_of_situation')),
  due_on date not null,
  reason text not null default '' check (length(reason) <= 1000),
  status text not null default 'open' check (status in ('open', 'completed', 'cancelled')),
  completed_on date,
  outcome text not null default '' check (length(outcome) <= 2000),
  document_id uuid references public.client_documents (id) on delete restrict,
  created_by uuid default auth.uid() references public.profiles (id),
  created_at timestamptz not null default now(),
  closed_by uuid references public.profiles (id),
  closed_at timestamptz,
  updated_by uuid references public.profiles (id),
  updated_at timestamptz not null default now()
);
create index if not exists client_reviews_client on public.client_reviews (client_id);
create index if not exists client_reviews_open on public.client_reviews (due_on) where status = 'open';
alter table public.client_reviews enable row level security;

drop policy if exists "see reviews" on public.client_reviews;
create policy "see reviews" on public.client_reviews
  for select to authenticated
  using (((select public.can('clients.reviews'::text, 'view'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
         or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
             and public.can('clients.reviews'::text, 'view'::text, client_id)));
drop policy if exists "add reviews" on public.client_reviews;
create policy "add reviews" on public.client_reviews
  for insert to authenticated
  with check (((select public.can('clients.reviews'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
              or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
                  and public.can('clients.reviews'::text, 'edit'::text, client_id)));
drop policy if exists "change reviews" on public.client_reviews;
create policy "change reviews" on public.client_reviews
  for update to authenticated
  using (((select public.can('clients.reviews'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
         or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
             and public.can('clients.reviews'::text, 'edit'::text, client_id)))
  with check (((select public.can('clients.reviews'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
              or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
                  and public.can('clients.reviews'::text, 'edit'::text, client_id)));
-- No delete rule.
grant select, insert, update on public.client_reviews to authenticated;

create or replace function public.guard_client_review()
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
    if new.service_id is not null then
      select p.scheme into v_scheme
        from public.client_services s join public.client_programs p on p.id = s.program_id
       where s.id = new.service_id and s.client_id = new.client_id;
      if v_scheme is null then
        raise exception 'That service belongs to another client, or has no program.';
      end if;
      new.scheme := v_scheme;
    end if;
    if new.kind = 'change_of_situation' then
      if length(trim(new.reason)) = 0 then
        raise exception 'Say what changed.';
      end if;
      new.due_on := public.local_today();
    end if;
    new.status := 'open';
    new.completed_on := null;
    new.outcome := '';
    new.created_by := auth.uid();
    new.created_at := now();
    new.closed_by := null;
    new.closed_at := null;
    return new;
  end if;
  if (new.scheme, new.service_id, new.kind, new.created_by, new.created_at) is distinct from (old.scheme, old.service_id, old.kind, old.created_by, old.created_at) then
    raise exception 'A review''s scheme, service and kind stay as they were. Add a new review instead.';
  end if;
  if old.status <> 'open' and new is distinct from old then
    raise exception 'This review is closed. Add a new one instead.';
  end if;
  if new.kind = 'change_of_situation' and new.due_on is distinct from old.due_on then
    raise exception 'A change of situation is due straight away.';
  end if;
  if new.status <> 'open' and old.status = 'open' then
    if new.status = 'completed' then
      new.completed_on := coalesce(new.completed_on, public.local_today());
      if length(trim(new.outcome)) = 0 then
        raise exception 'Record the outcome.';
      end if;
    end if;
    new.closed_by := auth.uid();
    new.closed_at := now();
  else
    new.closed_by := old.closed_by;
    new.closed_at := old.closed_at;
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_client_review() from public, anon, authenticated;
drop trigger if exists guard_client_review on public.client_reviews;
create trigger guard_client_review before insert or update on public.client_reviews
  for each row execute function public.guard_client_review();
drop trigger if exists log_client_reviews on public.client_reviews;
create trigger log_client_reviews before insert or update on public.client_reviews
  for each row execute function public.log_client_change();

-- The hourly timer: document expiry (update 112) plus review reminders.
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

-- Switched over from the start, with defaults.
update public.app_modules set grant_ready = true where id = 'clients.reviews' and not grant_ready;
do $$
declare
  v_cm uuid := (select id from public.job_titles where name = 'Case Manager' and active limit 1);
begin
  if not exists (select 1 from public.access_baselines where module_id = 'clients.reviews' and revoked_at is null) then
    insert into public.access_baselines (access_level, module_id, actions, scope, note)
    values ('manager', 'clients.reviews', '{}', 'all', 'Care block default: managers, every client');
    if v_cm is not null then
      insert into public.access_baselines (job_title_id, module_id, actions, scope, note)
      values (v_cm, 'clients.reviews', '{view,edit}', 'assigned', 'Care block default: case managers, assigned clients');
    end if;
  end if;
end $$;
commit;
