-- Staff Portal · © cmeproject. All rights reserved.
-- Update 167: service codes on the catalogue (existing services coded SERV-0001 onwards), the code
-- prefix setting, the Support at Home service type, the not-priced-yet list and codes on statements.
-- Changes no price, billing line or client service. Safe to run again. Undo: undo-167.sql.
begin;
insert into public.app_settings (key, value, label, description, is_public)
values ('billing.service_code_prefix', '"SERV"', 'Service code prefix', 'Letters at the start of every service code, for example SERV-0001.', false)
on conflict (key) do nothing;

alter table public.service_catalogue add column if not exists code text;
alter table public.service_catalogue add column if not exists sah_service_type text not null default '';
alter table public.service_catalogue drop constraint if exists service_catalogue_code_format;
alter table public.service_catalogue add constraint service_catalogue_code_format check (code is null or code ~ '^[A-Z0-9]{1,10}-[A-Z0-9]{1,10}$');
alter table public.service_catalogue drop constraint if exists service_catalogue_sah_type_length;
alter table public.service_catalogue add constraint service_catalogue_sah_type_length check (length(sah_service_type) <= 200);
create unique index if not exists service_catalogue_code_unique on public.service_catalogue (code) where code is not null;

create or replace function public.service_code_next() returns text
language sql volatile set search_path = '' as $$
  with p as (select coalesce(nullif(upper(regexp_replace(coalesce((select value #>> '{}' from public.app_settings where key = 'billing.service_code_prefix'), 'SERV'), '[^A-Za-z0-9]', '', 'g')), ''), 'SERV') as prefix)
  select p.prefix || '-' || lpad((coalesce((select max(substring(c.code from '-(\d+)$')::int) from public.service_catalogue c where c.code like p.prefix || '-%' and c.code ~ '-\d+$'), 0) + 1)::text, 4, '0')
    from p
$$;

create or replace function public.service_billed(p_service uuid) returns boolean
language sql stable set search_path = '' as $$
  select exists (select 1 from public.billing_lines bl join public.price_items pi on pi.id = bl.price_item_id where pi.catalogue_id = p_service)
$$;

create or replace function public.guard_service_code() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.code := nullif(upper(trim(coalesce(new.code, ''))), '');
  new.sah_service_type := trim(coalesce(new.sah_service_type, ''));
  if tg_op = 'INSERT' then
    if new.code is null then new.code := public.service_code_next(); end if;
    return new;
  end if;
  if new.code is null then new.code := old.code; end if;
  if new.code is distinct from old.code and old.code is not null and public.service_billed(old.id) then
    raise exception 'This service has been billed, so its code % stays as it is.', old.code;
  end if;
  return new;
end;
$$;
drop trigger if exists guard_service_code on public.service_catalogue;
create trigger guard_service_code before insert or update on public.service_catalogue for each row execute function public.guard_service_code();
revoke execute on function public.guard_service_code() from public, anon, authenticated;

do $$
declare
  r record;
begin
  for r in select id from public.service_catalogue where code is null order by sort_order, name, id loop
    update public.service_catalogue set code = public.service_code_next() where id = r.id;
  end loop;
end $$;

create or replace view public.services_not_priced with (security_invoker = true) as
  -- Catalogue services offered under the list's scheme with no price in its latest version.
  select l.id as price_list_id, l.name as price_list, l.scheme, v.id as version_id, v.version, v.status, 'catalogue'::text as kind, c.id as service_id, c.code, c.name as service, null::uuid as client_id
    from public.price_lists l
    join lateral (select * from public.price_list_versions x where x.price_list_id = l.id and x.status in ('draft', 'published') order by x.version desc limit 1) v on true
    join public.service_catalogue c on c.active and (cardinality(c.schemes) = 0 or l.scheme = any (c.schemes))
   where l.active and not exists (select 1 from public.price_items i where i.version_id = v.id and (i.catalogue_id = c.id or (i.catalogue_id is null and lower(i.label) = lower(c.name))))
  union all
  -- Open client services not in the catalogue, priced by name, with no price of that name.
  select l.id, l.name, l.scheme, v.id, v.version, v.status, 'client_service', s.id, null, s.label, s.client_id
    from public.client_services s
    join public.client_programs p on p.id = s.program_id
    join public.price_lists l on l.active and l.scheme = p.scheme
    join lateral (select * from public.price_list_versions x where x.price_list_id = l.id and x.status in ('draft', 'published') order by x.version desc limit 1) v on true
   where s.catalogue_id is null and s.status <> 'ended'
     and not exists (select 1 from public.price_items i where i.version_id = v.id and i.catalogue_id is null and lower(i.label) = lower(s.label));
grant select on public.services_not_priced to authenticated;
revoke all on public.services_not_priced from anon;

create or replace function public.statement_add_codes() returns trigger
language plpgsql set search_path = '' as $$
begin
  if jsonb_typeof(new.snapshot -> 'service_lines') = 'array' then
    new.snapshot := jsonb_set(new.snapshot, '{service_lines}', (
      select coalesce(jsonb_agg(x.e || jsonb_build_object('code', coalesce(x.code, '')) order by x.n), '[]')
        from (select e, n, (select c.code from public.billing_lines bl join public.price_items pi on pi.id = bl.price_item_id join public.service_catalogue c on c.id = pi.catalogue_id where bl.id = (e ->> 'id')::uuid) as code
                from jsonb_array_elements(new.snapshot -> 'service_lines') with ordinality as t(e, n)) x));
  end if;
  return new;
end;
$$;
create or replace function public.statement_add_detail_ids() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_end date := (new.month + interval '1 month' - interval '1 day')::date;
begin
  if jsonb_typeof(new.snapshot -> 'service_lines') = 'array' then
    new.snapshot := jsonb_set(new.snapshot, '{service_lines}', (
      select coalesce(jsonb_agg(jsonb_build_object('id', l.id, 'date', l.service_date, 'service', coalesce(sv.label, 'Service'), 'category', l.sah_category, 'pct', l.contribution_pct,
               'quantity', l.quantity, 'unit', l.unit, 'rate', l.unit_price, 'band', l.band_label, 'kind', l.kind, 'amount', l.amount, 'client_share', l.client_share) order by l.service_date, l.starts_at), '[]')
        from public.billing_lines l left join public.client_services sv on sv.id = l.service_id
       where l.enrolment_id = new.enrolment_id and l.status = 'approved' and l.service_date between new.month and v_end));
  end if;
  return new;
end;
$$;
drop trigger if exists guard_statement_ids on public.client_statements;
create trigger guard_statement_ids before insert on public.client_statements for each row execute function public.statement_add_detail_ids();
drop trigger if exists guard_statement_zcodes on public.client_statements;
create trigger guard_statement_zcodes before insert on public.client_statements for each row execute function public.statement_add_codes();
revoke execute on function public.statement_add_codes() from public, anon, authenticated;
revoke execute on function public.statement_add_detail_ids() from public, anon, authenticated;
revoke execute on function public.service_code_next() from public, anon;
grant execute on function public.service_code_next() to authenticated;

drop policy if exists "billing sets the service code prefix" on public.app_settings;
create policy "billing sets the service code prefix" on public.app_settings for update to authenticated
  using (key = 'billing.service_code_prefix' and ((select public.is_manager_admin(auth.uid())) or (select public.billing_can('prices'))))
  with check (key = 'billing.service_code_prefix' and ((select public.is_manager_admin(auth.uid())) or (select public.billing_can('prices'))) and (value #>> '{}') ~ '^[A-Za-z0-9]{1,10}$');
commit;
