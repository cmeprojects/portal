-- Staff Portal · © cmeproject. All rights reserved.
-- Update 163: claims and client invoices (Phase 5A), with the compliance register (official link,
-- version, effective and review dates), business details, payers, NDIS catalogue and pricing zones,
-- official claim templates, recoveries, claims recorded as submitted only by a person, client
-- invoices and monthly Support at Home statements. Nothing is claimed or invoiced until someone
-- prepares it and someone else approves it. Safe to run again. Undo: undo-163.sql.
begin;
update public.app_modules set actions = actions || array['claim_prepare', 'claim_approve', 'claim_submit', 'invoice_prepare', 'invoice_approve', 'invoice_issue']
 where id = 'clients.billing' and not ('claim_prepare' = any (actions));

alter table public.billing_rule_checks
  add column if not exists official_url text not null default '' check (length(official_url) <= 500),
  add column if not exists document_version text not null default '' check (length(document_version) <= 100),
  add column if not exists effective_from date,
  add column if not exists review_by date;
alter table public.billing_parameters
  add column if not exists official_url text not null default '' check (length(official_url) <= 500),
  add column if not exists document_version text not null default '' check (length(document_version) <= 100),
  add column if not exists review_by date;
insert into public.billing_rule_checks (scheme, item)
select v.scheme, v.item from (values
  ('support_at_home', 'Care management account: 10% moved each quarter; its own rollover rule (separate from the participant''s carryover)'),
  ('support_at_home', 'Care management is clinical care: no participant contribution; claimed each quarter'),
  ('support_at_home', 'Contributions collected unless a fee reduction supplement applies; Services Australia''s calculation is authoritative'),
  ('support_at_home', 'Services Australia claim format and claiming rules (program manual, provider pages)'),
  ('ndis', 'NDIS Bulk Upload File template (from the provider portal): columns kept, CSV, date format, file name length'),
  ('ndis', 'NDIS Pricing Arrangements / Pricing Schedule version in force (price limits by zone, time of day)'),
  ('ndis', '"My provider" recording for agency-managed supports')
) v(scheme, item)
 where not exists (select 1 from public.billing_scheme_rules r where r.scheme = v.scheme and r.status = 'confirmed')
on conflict (scheme, item) do nothing;

create or replace function public.guard_billing_review() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.status = 'verified' then
    if tg_op = 'UPDATE' and old.status = 'verified' and ((old.official_url <> '' and new.official_url is distinct from old.official_url)
                                                         or (old.document_version <> '' and new.document_version is distinct from old.document_version)) then
      raise exception 'A verified entry keeps its official link and version. Mark it unverified first.';
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists guard_billing_review on public.billing_rule_checks;
create trigger guard_billing_review before insert or update on public.billing_rule_checks for each row execute function public.guard_billing_review();
drop trigger if exists guard_billing_review on public.billing_parameters;
create trigger guard_billing_review before insert or update on public.billing_parameters for each row execute function public.guard_billing_review();
revoke execute on function public.guard_billing_review() from public, anon, authenticated;

create or replace function public.billing_review_lapsed(p_scheme text) returns boolean
language sql stable set search_path = '' as $$
  select exists (select 1 from public.billing_rule_checks c where c.scheme = p_scheme and c.status = 'verified' and c.review_by < (now() at time zone 'Australia/Sydney')::date)
      or exists (select 1 from public.billing_parameters p where p.scheme = p_scheme and p.status = 'verified' and p.review_by < (now() at time zone 'Australia/Sydney')::date)
$$;

create or replace function public.billing_scheme_ready(p_scheme text) returns text
language sql stable set search_path = '' as $$
  select case
    when not exists (select 1 from public.billing_scheme_rules r where r.scheme = p_scheme and r.status = 'confirmed') then 'Billing rules for this scheme aren''t confirmed.'
    when exists (select 1 from public.billing_rule_checks c where c.scheme = p_scheme and (c.status <> 'verified' or c.official_url = '' or c.document_version = '' or c.review_by is null))
      then 'Every rule for this scheme needs to be verified with its official link, document version and a "review by" date (Billing set-up).'
    when exists (select 1 from public.billing_parameters p where p.scheme = p_scheme and p.status = 'verified' and (p.official_url = '' or p.document_version = '' or p.review_by is null))
      then 'Every verified figure for this scheme needs its official link, document version and a "review by" date (Billing set-up).'
    when exists (select 1 from public.billing_rule_checks c where c.scheme = p_scheme and c.review_by is not null and c.review_by < (now() at time zone 'Australia/Sydney')::date)
      then 'A verified rule for this scheme is past its review date. Review it in Billing set-up.'
    when exists (select 1 from public.billing_parameters p where p.scheme = p_scheme and p.status = 'verified' and p.review_by is not null and p.review_by < (now() at time zone 'Australia/Sydney')::date)
      then 'A verified figure for this scheme is past its review date. Review it in Billing set-up.'
  end
$$;

create or replace function public.abn_valid(p text) returns boolean
language sql immutable set search_path = '' as $$
  select p ~ '^\d{11}$' and (
    ((substr(p, 1, 1)::int - 1) * 10 + substr(p, 2, 1)::int * 1 + substr(p, 3, 1)::int * 3 + substr(p, 4, 1)::int * 5 + substr(p, 5, 1)::int * 7
     + substr(p, 6, 1)::int * 9 + substr(p, 7, 1)::int * 11 + substr(p, 8, 1)::int * 13 + substr(p, 9, 1)::int * 15 + substr(p, 10, 1)::int * 17
     + substr(p, 11, 1)::int * 19) % 89 = 0)
$$;
create table if not exists public.business_details (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  version integer not null default 1,
  legal_name text not null check (length(trim(legal_name)) between 1 and 200),
  trading_name text not null default '' check (length(trading_name) <= 200),
  abn text not null check (public.abn_valid(abn)),
  address text not null check (length(trim(address)) between 1 and 300),
  suburb text not null check (length(trim(suburb)) between 1 and 100),
  state text not null check (state in ('ACT', 'NSW', 'NT', 'QLD', 'SA', 'TAS', 'VIC', 'WA')),
  postcode text not null check (postcode ~ '^\d{4}$'),
  phone text not null default '' check (length(phone) <= 30),
  email text not null default '' check (email = '' or email ~ '^[^\s@]+@[^\s@]+\.[^\s@]+$'),
  gst_registered boolean not null default false,
  prices_include_gst boolean not null default true,
  gst_rate numeric(5, 2) not null default 10 check (gst_rate between 0 and 100),
  gst_verified_by_name text not null default '' check (length(gst_verified_by_name) <= 120),
  gst_verified_on date,
  gst_evidence text not null default '' check (length(gst_evidence) <= 500),
  ndis_registration_number text not null default '' check (length(ndis_registration_number) <= 40),
  ndis_registration_groups text[] not null default '{}',
  sah_provider_id text not null default '' check (length(sah_provider_id) <= 60),
  sah_service_branch text not null default '' check (length(sah_service_branch) <= 120),
  payment_account_name text not null default '' check (length(payment_account_name) <= 120),
  payment_bsb text not null default '' check (payment_bsb = '' or payment_bsb ~ '^\d{3}-?\d{3}$'),
  payment_account_number text not null default '' check (payment_account_number = '' or payment_account_number ~ '^\d{5,10}$'),
  payment_other text not null default '' check (length(payment_other) <= 500),
  invoice_prefix text not null default 'INV' check (invoice_prefix ~ '^[A-Z]{2,6}$'),
  payment_terms_days integer not null default 14 check (payment_terms_days between 0 and 120),
  write_off_threshold numeric(12, 2) not null default 500 check (write_off_threshold >= 0),
  note text not null default '' check (length(note) <= 500),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  unique (version)
);
create or replace view public.business_current with (security_invoker = true) as
  select *, (gst_verified_by_name <> '' and gst_verified_on is not null) as gst_verified
    from public.business_details order by version desc limit 1;

create or replace function public.guard_business_details() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op <> 'INSERT' then
    raise exception 'Business details are never edited or deleted. Save a new version.';
  end if;
  if public.from_portal() and not (public.is_system_admin() or public.billing_can('approve')) then
    raise exception 'Only the System Administrator or someone with the Billing approve right changes business details.';
  end if;
  new.version := coalesce((select max(version) from public.business_details), 0) + 1;
  new.created_by := auth.uid(); new.created_at := now();
  new.abn := regexp_replace(new.abn, '\s', '', 'g');
  if (new.gst_verified_by_name = '') <> (new.gst_verified_on is null) then
    raise exception 'Record both who verified the GST position (your accountant) and the date, or neither.';
  end if;
  if new.gst_verified_on is not null and new.gst_verified_on > (now() at time zone 'Australia/Sydney')::date then
    raise exception 'The GST verification date can''t be in the future.';
  end if;
  return new;
end;
$$;

create table if not exists public.billing_payers (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  kind text not null check (kind in ('services_australia', 'ndia', 'plan_manager', 'participant', 'client', 'other')),
  client_id uuid references public.car_clients (id),
  person_id uuid references public.client_people (id),
  name text not null check (length(trim(name)) between 1 and 200),
  abn text not null default '' check (abn = '' or public.abn_valid(abn)),
  email text not null default '' check (email = '' or email ~ '^[^\s@]+@[^\s@]+\.[^\s@]+$'),
  phone text not null default '' check (length(phone) <= 30),
  address text not null default '' check (length(address) <= 400),
  reference text not null default '' check (length(reference) <= 100),
  active boolean not null default true,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  constraint billing_payers_client check ((kind in ('participant', 'client')) = (client_id is not null))
);
insert into public.billing_payers (kind, name)
select k, n from (values ('services_australia', 'Services Australia (Support at Home)'), ('ndia', 'National Disability Insurance Agency')) v(k, n)
 where not exists (select 1 from public.billing_payers p where p.kind = v.k);

create table if not exists public.client_payer_links (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id),
  role text not null check (role in ('funding', 'client')),
  funding_id uuid references public.client_funding (id),
  payer_id uuid not null references public.billing_payers (id),
  starts_on date not null,
  ends_on date,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  constraint client_payer_links_dates check (ends_on is null or ends_on >= starts_on),
  constraint client_payer_links_funding check ((role = 'funding') = (funding_id is not null))
);

create table if not exists public.client_fee_reductions (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id),
  enrolment_id uuid not null references public.client_enrolments (id),
  full_reduction boolean not null default true,
  starts_on date not null,
  ends_on date,
  source text not null check (length(trim(source)) between 1 and 300),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  constraint client_fee_reductions_dates check (ends_on is null or ends_on >= starts_on)
);

create table if not exists public.ndis_catalogue_versions (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  name text not null check (length(trim(name)) between 1 and 200),
  document_version text not null default '' check (length(document_version) <= 100),
  official_url text not null default '' check (length(official_url) <= 500),
  effective_from date not null,
  effective_to date,
  review_by date,
  file_name text not null default '' check (length(file_name) <= 200),
  file_checksum text not null default '',
  item_count integer not null default 0,
  status text not null default 'draft' check (status in ('draft', 'verified')),
  verified_by uuid, verified_at timestamptz,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  constraint ndis_catalogue_versions_dates check (effective_to is null or effective_to >= effective_from)
);
create table if not exists public.ndis_support_items (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  version_id uuid not null references public.ndis_catalogue_versions (id),
  item_number text not null check (length(trim(item_number)) between 1 and 40),
  item_name text not null default '' check (length(item_name) <= 500),
  category text not null default '' check (length(category) <= 200),
  registration_group text not null default '' check (length(registration_group) <= 200),
  unit text not null default '' check (length(unit) <= 20),
  limit_national numeric(10, 2),
  limit_remote numeric(10, 2),
  limit_very_remote numeric(10, 2),
  quotable boolean not null default false,
  details jsonb not null default '{}',
  unique (version_id, item_number)
);
create table if not exists public.client_location_pricing (
  location_id uuid primary key references public.client_locations (id),
  org_id uuid not null default public.default_org_id(),
  client_id uuid references public.car_clients (id),
  ndis_zone text not null check (ndis_zone in ('national', 'remote', 'very_remote')),
  mmm text not null default '' check (length(mmm) <= 10),
  source text not null check (length(trim(source)) between 1 and 300),
  set_by uuid default auth.uid(),
  set_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now()
);
create table if not exists public.ndis_plan_details (
  funding_id uuid primary key references public.client_funding (id),
  org_id uuid not null default public.default_org_id(),
  client_id uuid references public.car_clients (id),
  my_provider boolean not null default false,
  recorded_on date not null,
  note text not null default '' check (length(note) <= 300),
  recorded_by uuid default auth.uid(),
  updated_by uuid,
  updated_at timestamptz not null default now()
);

create table if not exists public.claim_templates (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  program text not null check (program in ('support_at_home', 'ndis')),
  name text not null check (length(trim(name)) between 1 and 200),
  version integer not null default 1,
  headers jsonb not null check (jsonb_typeof(headers) = 'array' and jsonb_array_length(headers) between 1 and 80),
  mapping jsonb not null default '{}',
  date_format text not null default 'YYYY-MM-DD' check (date_format in ('YYYY-MM-DD', 'YYYY/MM/DD', 'DD/MM/YYYY')),
  file_name_max integer check (file_name_max is null or file_name_max between 5 and 200),
  official_url text not null default '' check (length(official_url) <= 500),
  document_version text not null default '' check (length(document_version) <= 100),
  file_name text not null default '' check (length(file_name) <= 200),
  file_checksum text not null default '',
  review_by date,
  status text not null default 'draft' check (status in ('draft', 'verified', 'retired')),
  verified_by uuid, verified_at timestamptz,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  unique (program, version)
);

create or replace function public.guard_billing_reference() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_old jsonb;
  v_new jsonb;
begin
  if tg_op = 'DELETE' then
    if (to_jsonb(old) ->> 'status') = 'draft' then return old; end if;
    raise exception 'A verified record is never deleted.';
  end if;
  if public.from_portal() and not public.billing_can('prices') and not public.billing_can('approve') then
    raise exception 'Only people with the Billing prices or approve right change this.';
  end if;
  if tg_op = 'INSERT' then
    new := jsonb_populate_record(new, jsonb_build_object('status', 'draft', 'verified_by', null, 'verified_at', null, 'created_by', auth.uid(), 'created_at', now()));
    if tg_table_name = 'claim_templates' then
      new := jsonb_populate_record(new, jsonb_build_object('version', coalesce((select max(version) from public.claim_templates where program = (to_jsonb(new) ->> 'program')), 0) + 1));
    end if;
    return new;
  end if;
  v_old := to_jsonb(old) - array['status', 'verified_by', 'verified_at', 'updated_by', 'updated_at', 'item_count'];
  v_new := to_jsonb(new) - array['status', 'verified_by', 'verified_at', 'updated_by', 'updated_at', 'item_count'];
  if (to_jsonb(old) ->> 'status') <> 'draft' and v_new is distinct from v_old then
    raise exception 'A verified record never changes. Import or add a new version.';
  end if;
  if (to_jsonb(new) ->> 'status') = 'verified' and (to_jsonb(old) ->> 'status') = 'draft' then
    if public.from_portal() and not public.billing_can('approve') then
      raise exception 'Only someone with the Billing approve right (the owner''s nominee) verifies it.';
    end if;
    if coalesce(to_jsonb(new) ->> 'official_url', '') = '' or coalesce(to_jsonb(new) ->> 'document_version', '') = '' or (to_jsonb(new) ->> 'review_by') is null then
      raise exception 'To verify, record the official link, the document version and a "review by" date.';
    end if;
    if tg_table_name = 'ndis_catalogue_versions' and not exists (select 1 from public.ndis_support_items i where i.version_id = new.id) then
      raise exception 'Import the catalogue''s items first.';
    end if;
    new := jsonb_populate_record(new, jsonb_build_object('verified_by', auth.uid(), 'verified_at', now()));
    if tg_table_name = 'claim_templates' then
      update public.claim_templates set status = 'retired' where program = (to_jsonb(new) ->> 'program') and status = 'verified' and id <> new.id;
    end if;
  elsif (to_jsonb(new) ->> 'status') = 'retired' and (to_jsonb(old) ->> 'status') = 'verified' and pg_trigger_depth() > 1 then
    null;
  elsif (to_jsonb(new) ->> 'status') is distinct from (to_jsonb(old) ->> 'status') then
    raise exception 'A draft is verified; a verified template is retired by verifying the next one.';
  end if;
  return new;
end;
$$;
create or replace function public.guard_ndis_item() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_version uuid := case when tg_op = 'DELETE' then old.version_id else new.version_id end;
begin
  if (select status from public.ndis_catalogue_versions where id = v_version) is distinct from 'draft' then
    raise exception 'A verified catalogue never changes. Import a new version.';
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;

create or replace function public.ndis_price_check(p_line uuid)
returns table (problem text, ndis_zone text, catalogue_version_id uuid, item_number text, price_limit numeric)
language plpgsql stable set search_path = '' as $$
#variable_conflict use_column
declare
  l public.billing_lines;
  v_item text;
  v_loc uuid;
  v_zone text;
  v_ver uuid;
  s public.ndis_support_items;
  v_limit numeric;
begin
  select * into l from public.billing_lines where id = p_line;
  select i.ndis_item into v_item from public.price_items i where i.id = l.price_item_id;
  if coalesce(v_item, '') = '' then
    return query select 'The price has no NDIS support item number.'::text, null::text, null::uuid, null::text, null::numeric; return;
  end if;
  select coalesce(sh.location_id, sv.location_id) into v_loc from public.shifts sh left join public.client_services sv on sv.id = sh.service_id where sh.id = l.shift_id;
  select z.ndis_zone into v_zone from public.client_location_pricing z where z.location_id = v_loc;
  if v_zone is null then
    return query select 'The service delivery location has no NDIS pricing zone (Billing -> Client billing).'::text, null::text, null::uuid, v_item, null::numeric; return;
  end if;
  select v.id into v_ver from public.ndis_catalogue_versions v
   where v.status = 'verified' and v.effective_from <= l.service_date and (v.effective_to is null or v.effective_to >= l.service_date)
     and (v.review_by is null or v.review_by >= (now() at time zone 'Australia/Sydney')::date)
   order by v.effective_from desc limit 1;
  if v_ver is null then
    return query select 'No verified NDIS catalogue (in force and within its review date) covers the support date.'::text, v_zone, null::uuid, v_item, null::numeric; return;
  end if;
  select * into s from public.ndis_support_items x where x.version_id = v_ver and x.item_number = v_item;
  if s.id is null then
    return query select ('Support item ' || v_item || ' isn''t in the NDIS catalogue in force on the support date.')::text, v_zone, v_ver, v_item, null::numeric; return;
  end if;
  v_limit := case v_zone when 'national' then s.limit_national when 'remote' then s.limit_remote else s.limit_very_remote end;
  if v_limit is not null and l.unit_price > v_limit then
    return query select ('The price $' || l.unit_price || ' is above the NDIS limit $' || v_limit || ' for item ' || v_item || ' (' || v_zone || ').')::text, v_zone, v_ver, v_item, v_limit; return;
  end if;
  if v_limit is null and not s.quotable then
    return query select ('Item ' || v_item || ' has no price limit for the ' || v_zone || ' zone.')::text, v_zone, v_ver, v_item, null::numeric; return;
  end if;
  return query select null::text, v_zone, v_ver, v_item, v_limit;
end;
$$;

create or replace function public.billing_payer_for(p_line uuid, p_role text) returns uuid
language plpgsql stable set search_path = '' as $$
declare
  l public.billing_lines;
  v_pm text;
begin
  select * into l from public.billing_lines where id = p_line;
  if p_role = 'funding' then
    if l.scheme = 'support_at_home' then
      return (select id from public.billing_payers where kind = 'services_australia' and active limit 1);
    elsif l.scheme = 'ndis' then
      select plan_management into v_pm from public.client_funding where id = l.funding_id;
      if v_pm = 'ndia' then
        return (select id from public.billing_payers where kind = 'ndia' and active limit 1);
      end if;
      return (select k.payer_id from public.client_payer_links k where k.client_id = l.client_id and k.role = 'funding' and k.funding_id = l.funding_id
                and k.starts_on <= l.service_date and (k.ends_on is null or k.ends_on >= l.service_date) order by k.starts_on desc limit 1);
    end if;
    return null;
  end if;
  return (select k.payer_id from public.client_payer_links k where k.client_id = l.client_id and k.role = 'client'
            and k.starts_on <= l.service_date and (k.ends_on is null or k.ends_on >= l.service_date) order by k.starts_on desc limit 1);
end;
$$;

create table if not exists public.line_recoveries (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  line_id uuid not null references public.billing_lines (id),
  client_id uuid not null references public.car_clients (id),
  payer_role text not null check (payer_role in ('funding', 'client')),
  payer_id uuid not null references public.billing_payers (id),
  service_value numeric(12, 2) not null,
  amount numeric(12, 2) not null check (amount >= 0),
  ndis_zone text,
  ndis_catalogue_version_id uuid references public.ndis_catalogue_versions (id),
  ndis_item text,
  ndis_limit numeric(10, 2),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  unique (line_id, payer_role)
);
create or replace function public.guard_line_recovery() returns trigger
language plpgsql set search_path = '' as $$
declare
  l public.billing_lines;
begin
  if tg_op <> 'INSERT' then
    raise exception 'A recovery never changes.';
  end if;
  if public.from_portal() and coalesce(current_setting('portal.billing_prepare', true), '') <> 'on' then
    raise exception 'Recoveries are made when claims or invoices are prepared.';
  end if;
  select * into l from public.billing_lines where id = new.line_id;
  if l.status <> 'approved' then
    raise exception 'Only approved billing lines are recovered.';
  end if;
  new.client_id := l.client_id;
  new.service_value := l.amount;
  if new.amount + coalesce((select sum(r.amount) from public.line_recoveries r where r.line_id = new.line_id), 0) > l.amount then
    raise exception 'That would recover more than the billing line''s value.';
  end if;
  new.created_by := auth.uid(); new.created_at := now();
  return new;
end;
$$;

create table if not exists public.claims (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  program text not null check (program in ('support_at_home', 'ndis')),
  payer_id uuid not null references public.billing_payers (id),
  kind text not null default 'original' check (kind in ('original', 'amendment', 'replacement')),
  replaces_claim_id uuid references public.claims (id),
  status text not null default 'draft' check (status in ('draft', 'approved', 'submitted', 'acknowledged', 'cancelled')),
  period_from date not null,
  period_to date not null,
  template_id uuid references public.claim_templates (id),
  item_count integer not null default 0,
  total_claimed numeric(12, 2) not null default 0,
  total_expected numeric(12, 2) not null default 0,
  excluded jsonb not null default '[]',
  file_name text,
  file_content text,
  file_checksum text,
  file_generated_by uuid, file_generated_at timestamptz,
  prepared_by uuid default auth.uid(),
  prepared_at timestamptz not null default now(),
  approved_by uuid, approved_at timestamptz,
  cancelled_by uuid, cancelled_at timestamptz, cancel_reason text not null default '' check (length(cancel_reason) <= 500),
  notes text not null default '' check (length(notes) <= 1000),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  constraint claims_period check (period_to >= period_from)
);
create table if not exists public.claim_items (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  claim_id uuid not null references public.claims (id),
  line_id uuid references public.billing_lines (id),
  recovery_id uuid references public.line_recoveries (id),
  quarter_budget_id uuid references public.client_quarter_budgets (id),
  client_id uuid not null references public.car_clients (id),
  claimed_value numeric(12, 2) not null,
  expected_amount numeric(12, 2) not null,
  constraint claim_items_source check ((line_id is not null and recovery_id is not null and quarter_budget_id is null)
                                    or (line_id is null and recovery_id is null and quarter_budget_id is not null)),
  status text not null default 'live' check (status in ('live', 'removed')),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now()
);
create unique index if not exists claim_items_one_live on public.claim_items (recovery_id) where status = 'live';
create unique index if not exists claim_items_one_care_management on public.claim_items (quarter_budget_id) where status = 'live';
create table if not exists public.claim_submissions (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  claim_id uuid not null unique references public.claims (id),
  submitted_by uuid default auth.uid(),
  submitted_at timestamptz not null,
  channel text not null check (channel in ('aged_care_provider_portal', 'ndis_provider_portal', 'other')),
  external_reference text not null default '' check (length(external_reference) <= 120),
  acknowledgement text not null default '' check (length(acknowledgement) <= 1000),
  acknowledged_at timestamptz,
  notes text not null default '' check (length(notes) <= 1000),
  recorded_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now()
);

create table if not exists public.invoice_number_counters (
  year integer primary key,
  last_number integer not null default 0
);
create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  number text unique,
  kind text not null check (kind in ('sah_contribution', 'private', 'ndis_plan_managed', 'ndis_self_managed')),
  client_id uuid not null references public.car_clients (id),
  payer_id uuid not null references public.billing_payers (id),
  status text not null default 'draft' check (status in ('draft', 'approved', 'issued', 'sent', 'cancelled')),
  period_from date not null,
  period_to date not null,
  tax_invoice boolean not null default false,
  subtotal numeric(12, 2) not null default 0,
  gst numeric(12, 2) not null default 0,
  total numeric(12, 2) not null default 0,
  terms_days integer,
  issue_date date,
  due_date date,
  business_version integer,
  snapshot jsonb,
  pdf_base64 text,
  pdf_checksum text,
  prepared_by uuid default auth.uid(),
  prepared_at timestamptz not null default now(),
  approved_by uuid, approved_at timestamptz,
  issued_by uuid, issued_at timestamptz,
  sent_by uuid, sent_at timestamptz, sent_note text not null default '' check (length(sent_note) <= 500),
  cancelled_by uuid, cancelled_at timestamptz, cancel_reason text not null default '' check (length(cancel_reason) <= 500),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  constraint invoices_period check (period_to >= period_from)
);
create table if not exists public.invoice_items (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  invoice_id uuid not null references public.invoices (id),
  line_id uuid not null references public.billing_lines (id),
  recovery_id uuid not null references public.line_recoveries (id),
  client_id uuid not null references public.car_clients (id),
  description text not null,
  service_date date not null,
  quantity numeric(10, 2) not null,
  unit_price numeric(10, 2) not null,
  amount numeric(12, 2) not null,
  gst_code text not null,
  gst_amount numeric(12, 2) not null default 0,
  status text not null default 'live' check (status in ('live', 'removed')),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now()
);
create unique index if not exists invoice_items_one_live on public.invoice_items (recovery_id) where status = 'live';

create table if not exists public.client_statements (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id),
  enrolment_id uuid not null references public.client_enrolments (id),
  month date not null check (extract(day from month) = 1),
  snapshot jsonb not null default '{}',
  pdf_base64 text,
  pdf_checksum text,
  issued_by uuid default auth.uid(),
  issued_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  unique (enrolment_id, month)
);

create or replace view public.care_management_accounts with (security_invoker = true) as
  select q.id as quarter_budget_id, q.client_id, q.enrolment_id, q.quarter_start, q.quarter_end, q.care_management as allocated,
         coalesce((select sum(i.claimed_value) from public.claim_items i join public.claims c on c.id = i.claim_id
                    where i.quarter_budget_id = q.id and i.status = 'live' and c.status in ('submitted', 'acknowledged')), 0) as claimed,
         exists (select 1 from public.claim_items i join public.claims c on c.id = i.claim_id
                  where i.quarter_budget_id = q.id and i.status = 'live' and c.status <> 'cancelled') as in_claim
    from public.client_quarter_budgets q where q.status in ('approved', 'closed');
grant select on public.care_management_accounts to authenticated;
revoke all on public.care_management_accounts from anon;

create or replace function public.recovery_in_use(p_recovery uuid, p_except uuid default null) returns boolean
language sql stable set search_path = '' as $$
  select exists (select 1 from public.claim_items i join public.claims c on c.id = i.claim_id
                  where i.recovery_id = p_recovery and i.status = 'live' and c.status <> 'cancelled' and i.id is distinct from p_except)
      or exists (select 1 from public.invoice_items i join public.invoices v on v.id = i.invoice_id
                  where i.recovery_id = p_recovery and i.status = 'live' and v.status <> 'cancelled' and i.id is distinct from p_except)
$$;

create or replace function public.guard_claim() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_api boolean := public.from_portal();
  v_ready text;
begin
  if tg_op = 'DELETE' then
    raise exception 'Claims are never deleted. Cancel a draft instead.';
  end if;
  if tg_op = 'INSERT' then
    if v_api and coalesce(current_setting('portal.billing_prepare', true), '') <> 'on' then
      raise exception 'Claims are made with "Prepare claim".';
    end if;
    new.status := 'draft'; new.prepared_by := auth.uid(); new.prepared_at := now();
    new.approved_by := null; new.approved_at := null; new.file_content := null; new.file_checksum := null; new.file_name := null;
    return new;
  end if;
  if (new.program, new.payer_id, new.kind, new.replaces_claim_id, new.period_from, new.period_to, new.prepared_by, new.prepared_at)
     is distinct from (old.program, old.payer_id, old.kind, old.replaces_claim_id, old.period_from, old.period_to, old.prepared_by, old.prepared_at) then
    raise exception 'A claim keeps its program, payer, period and preparer.';
  end if;
  if old.status in ('submitted', 'acknowledged', 'cancelled') and (to_jsonb(new) - array['status', 'updated_by', 'updated_at']) is distinct from (to_jsonb(old) - array['status', 'updated_by', 'updated_at']) then
    raise exception 'A submitted or cancelled claim never changes. Corrections are new linked claims (5B).';
  end if;
  new.approved_by := old.approved_by; new.approved_at := old.approved_at;
  if new.status is distinct from old.status then
    if new.status = 'approved' and old.status = 'draft' then
      if v_api and (not public.billing_can('claim_approve') or auth.uid() is not distinct from old.prepared_by) then
        raise exception 'Only someone with the claim approve right, who didn''t prepare the claim, approves it.';
      end if;
      v_ready := public.billing_scheme_ready(new.program);
      if v_ready is not null then raise exception '%', v_ready; end if;
      if new.template_id is null or not exists (select 1 from public.claim_templates t where t.id = new.template_id and t.status = 'verified'
                                                 and (t.review_by is null or t.review_by >= (now() at time zone 'Australia/Sydney')::date)) then
        raise exception 'This program''s official claim template isn''t verified (or is past its review date).';
      end if;
      if not exists (select 1 from public.claim_items i where i.claim_id = new.id and i.status = 'live') then
        raise exception 'The claim has no lines.';
      end if;
      new.approved_by := auth.uid(); new.approved_at := now();
    elsif new.status = 'cancelled' and old.status in ('draft', 'approved') then
      if v_api and not (public.billing_can('claim_prepare') or public.billing_can('claim_approve')) then
        raise exception 'You can''t cancel claims.';
      end if;
      if length(trim(new.cancel_reason)) = 0 then raise exception 'Say why the claim is cancelled.'; end if;
      new.cancelled_by := auth.uid(); new.cancelled_at := now();
    elsif new.status = 'submitted' and old.status = 'approved' and coalesce(current_setting('portal.claim_submission', true), '') = 'on' then
      null; -- only by recording the manual submission
    elsif new.status = 'acknowledged' and old.status = 'submitted' and coalesce(current_setting('portal.claim_submission', true), '') = 'on' then
      null;
    else
      raise exception 'A claim goes Draft -> Approved -> Submitted (only by recording the upload) -> Acknowledged, or a draft or approved claim is cancelled.';
    end if;
  end if;
  -- The file is made once, after approval, from the verified template.
  if new.file_content is distinct from old.file_content or new.file_checksum is distinct from old.file_checksum or new.file_name is distinct from old.file_name then
    if old.status <> 'approved' or old.file_content is not null then
      raise exception 'The claim file is made once, after approval.';
    end if;
    if v_api and not (public.billing_can('claim_approve') or public.billing_can('claim_submit')) then
      raise exception 'You can''t make claim files.';
    end if;
    new.file_generated_by := auth.uid(); new.file_generated_at := now();
  end if;
  return new;
end;
$$;

create or replace function public.guard_claim_item() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_status text;
begin
  select status into v_status from public.claims where id = case when tg_op = 'DELETE' then old.claim_id else new.claim_id end;
  if tg_op = 'DELETE' then raise exception 'Claim lines are never deleted. Remove them from a draft.'; end if;
  if v_status <> 'draft' then raise exception 'Only a draft claim''s lines change.'; end if;
  if tg_op = 'INSERT' then
    if public.from_portal() and coalesce(current_setting('portal.billing_prepare', true), '') <> 'on' then
      raise exception 'Claim lines are added by "Prepare claim".';
    end if;
    if new.recovery_id is not null and public.recovery_in_use(new.recovery_id) then raise exception 'That line is already being recovered.'; end if;
    if new.quarter_budget_id is not null and exists (select 1 from public.claim_items i join public.claims c on c.id = i.claim_id
                                                      where i.quarter_budget_id = new.quarter_budget_id and i.status = 'live' and c.status <> 'cancelled') then
      raise exception 'That quarter''s care management is already claimed.';
    end if;
    return new;
  end if;
  if (to_jsonb(new) - array['status', 'updated_by', 'updated_at']) is distinct from (to_jsonb(old) - array['status', 'updated_by', 'updated_at']) or not (old.status = 'live' and new.status = 'removed') then
    raise exception 'A claim line can only be removed from a draft.';
  end if;
  return new;
end;
$$;

create or replace function public.guard_claim_submission() returns trigger
language plpgsql set search_path = '' as $$
declare
  c public.claims;
begin
  if tg_op = 'DELETE' then raise exception 'Submission records are never deleted.'; end if;
  select * into c from public.claims where id = new.claim_id;
  if tg_op = 'INSERT' then
    if public.from_portal() and not public.billing_can('claim_submit') then
      raise exception 'Only someone with the claim submit right records a submission.';
    end if;
    if c.status <> 'approved' or c.file_content is null then
      raise exception 'Record the submission after the claim is approved and its file made and uploaded.';
    end if;
    if new.submitted_at > now() + interval '5 minutes' then raise exception 'The submission time can''t be in the future.'; end if;
    if length(trim(new.external_reference)) = 0 then raise exception 'Record the reference the government portal gave.'; end if;
    new.submitted_by := auth.uid(); new.recorded_at := now(); new.acknowledgement := ''; new.acknowledged_at := null;
    perform set_config('portal.claim_submission', 'on', true);
    update public.claims set status = 'submitted' where id = c.id;
    perform set_config('portal.claim_submission', 'off', true);
    return new;
  end if;
  -- Only the acknowledgement is added later, once.
  if (to_jsonb(new) - array['acknowledgement', 'acknowledged_at', 'updated_by', 'updated_at']) is distinct from (to_jsonb(old) - array['acknowledgement', 'acknowledged_at', 'updated_by', 'updated_at'])
     or old.acknowledged_at is not null then
    raise exception 'A submission record never changes; only its acknowledgement is added, once.';
  end if;
  if public.from_portal() and not public.billing_can('claim_submit') then raise exception 'Only someone with the claim submit right records it.'; end if;
  if length(trim(new.acknowledgement)) = 0 then raise exception 'Record the acknowledgement.'; end if;
  new.acknowledged_at := now();
  perform set_config('portal.claim_submission', 'on', true);
  update public.claims set status = 'acknowledged' where id = c.id;
  perform set_config('portal.claim_submission', 'off', true);
  return new;
end;
$$;

create or replace function public.guard_invoice() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_api boolean := public.from_portal();
  b record;
  v_year integer;
  v_n integer;
  v_taxable boolean;
  v_ready text;
begin
  if tg_op = 'DELETE' then raise exception 'Invoices are never deleted. Cancel a draft instead.'; end if;
  if tg_op = 'INSERT' then
    if v_api and coalesce(current_setting('portal.billing_prepare', true), '') <> 'on' then
      raise exception 'Invoices are made with "Prepare invoices".';
    end if;
    new.status := 'draft'; new.number := null; new.prepared_by := auth.uid(); new.prepared_at := now();
    new.snapshot := null; new.pdf_base64 := null; new.pdf_checksum := null;
    return new;
  end if;
  if (new.kind, new.client_id, new.payer_id, new.period_from, new.period_to, new.prepared_by, new.prepared_at) is distinct from (old.kind, old.client_id, old.payer_id, old.period_from, old.period_to, old.prepared_by, old.prepared_at) then
    raise exception 'An invoice keeps its kind, client, payer, period and preparer.';
  end if;
  if old.status in ('issued', 'sent', 'cancelled') then
    if (to_jsonb(new) - array['status', 'sent_by', 'sent_at', 'sent_note', 'pdf_base64', 'pdf_checksum', 'updated_by', 'updated_at'])
       is distinct from (to_jsonb(old) - array['status', 'sent_by', 'sent_at', 'sent_note', 'pdf_base64', 'pdf_checksum', 'updated_by', 'updated_at']) then
      raise exception 'An issued invoice never changes. Corrections are credit notes (5B).';
    end if;
    if (new.pdf_base64, new.pdf_checksum) is distinct from (old.pdf_base64, old.pdf_checksum) and old.pdf_base64 is not null then
      raise exception 'The issued document never changes.';
    end if;
    if new.status = 'sent' and old.status = 'issued' then
      if v_api and not public.billing_can('invoice_issue') then raise exception 'Only someone with the invoice issue right marks it sent.'; end if;
      new.sent_by := auth.uid(); new.sent_at := now();
    elsif new.status is distinct from old.status then
      raise exception 'An issued invoice can only be marked sent.';
    end if;
    return new;
  end if;
  new.approved_by := old.approved_by; new.approved_at := old.approved_at; new.number := old.number;
  if new.status is distinct from old.status then
    if new.status = 'approved' and old.status = 'draft' then
      if v_api and (not public.billing_can('invoice_approve') or auth.uid() is not distinct from old.prepared_by) then
        raise exception 'Only someone with the invoice approve right, who didn''t prepare it, approves it.';
      end if;
      if not exists (select 1 from public.invoice_items i where i.invoice_id = new.id and i.status = 'live') then raise exception 'The invoice has no lines.'; end if;
      v_ready := public.billing_scheme_ready(case when new.kind = 'sah_contribution' then 'support_at_home' when new.kind = 'private' then 'private' else 'ndis' end);
      if v_ready is not null then raise exception '%', v_ready; end if;
      new.approved_by := auth.uid(); new.approved_at := now();
    elsif new.status = 'issued' and old.status = 'approved' then
      if v_api and not public.billing_can('invoice_issue') then raise exception 'Only someone with the invoice issue right issues invoices.'; end if;
      select * into b from public.business_current;
      if b.id is null then raise exception 'Enter the business details first (Portal settings).'; end if;
      if not b.gst_verified then raise exception 'The GST position isn''t verified by your accountant yet (Business details). Invoices can''t be issued.'; end if;
      -- Number: PREFIX-YYYY-000001, sequential per year, never reused.
      v_year := extract(year from (now() at time zone 'Australia/Sydney'))::int;
      insert into public.invoice_number_counters (year, last_number) values (v_year, 1)
        on conflict (year) do update set last_number = public.invoice_number_counters.last_number + 1
        returning last_number into v_n;
      new.number := b.invoice_prefix || '-' || v_year || '-' || lpad(v_n::text, 6, '0');
      -- GST from the verified business position and each line's GST code.
      update public.invoice_items set gst_amount = case when b.gst_registered and gst_code = 'taxable' then
               case when b.prices_include_gst then round(amount * b.gst_rate / (100 + b.gst_rate), 2) else round(amount * b.gst_rate / 100, 2) end else 0 end
       where invoice_id = new.id and status = 'live';
      select bool_or(gst_code = 'taxable') into v_taxable from public.invoice_items where invoice_id = new.id and status = 'live';
      new.tax_invoice := b.gst_registered and coalesce(v_taxable, false);
      select coalesce(sum(amount), 0), coalesce(sum(gst_amount), 0) into new.subtotal, new.gst from public.invoice_items where invoice_id = new.id and status = 'live';
      new.total := case when b.gst_registered and not b.prices_include_gst then new.subtotal + new.gst else new.subtotal end;
      new.terms_days := b.payment_terms_days;
      new.issue_date := (now() at time zone 'Australia/Sydney')::date;
      new.due_date := new.issue_date + b.payment_terms_days;
      new.business_version := b.version;
      new.issued_by := auth.uid(); new.issued_at := now();
      new.snapshot := jsonb_build_object(
        'business', to_jsonb(b),
        'payer', (select to_jsonb(p) from public.billing_payers p where p.id = new.payer_id),
        'client', (select jsonb_build_object('name', c.name, 'client_ref', c.client_ref, 'ndis_number', d.ndis_number, 'aged_care_id', d.aged_care_id, 'address', d.home_address)
                     from public.car_clients c left join public.client_details d on d.client_id = c.id where c.id = new.client_id),
        'items', (select coalesce(jsonb_agg(jsonb_build_object('description', i.description, 'service_date', i.service_date, 'quantity', i.quantity, 'unit_price', i.unit_price,
                   'amount', i.amount, 'gst_code', i.gst_code, 'gst_amount', i.gst_amount) order by i.service_date, i.description), '[]') from public.invoice_items i where i.invoice_id = new.id and i.status = 'live'));
    elsif new.status = 'cancelled' and old.status in ('draft', 'approved') then
      if length(trim(new.cancel_reason)) = 0 then raise exception 'Say why the invoice is cancelled.'; end if;
      new.cancelled_by := auth.uid(); new.cancelled_at := now();
    else
      raise exception 'An invoice goes Draft -> Approved -> Issued -> Sent, or a draft or approved invoice is cancelled.';
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.guard_invoice_item() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_status text;
begin
  select status into v_status from public.invoices where id = case when tg_op = 'DELETE' then old.invoice_id else new.invoice_id end;
  if tg_op = 'DELETE' then raise exception 'Invoice lines are never deleted.'; end if;
  if tg_op = 'INSERT' then
    if v_status <> 'draft' then raise exception 'Only a draft invoice''s lines change.'; end if;
    if public.from_portal() and coalesce(current_setting('portal.billing_prepare', true), '') <> 'on' then raise exception 'Invoice lines are added by "Prepare invoices".'; end if;
    if public.recovery_in_use(new.recovery_id) then raise exception 'That line is already being recovered.'; end if;
    return new;
  end if;
  -- The GST amount is set when issuing; otherwise only a draft's line can be removed.
  if v_status = 'approved' and (to_jsonb(new) - array['gst_amount', 'updated_by', 'updated_at']) = (to_jsonb(old) - array['gst_amount', 'updated_by', 'updated_at']) then
    return new;
  end if;
  if v_status <> 'draft' or (to_jsonb(new) - array['status', 'updated_by', 'updated_at']) is distinct from (to_jsonb(old) - array['status', 'updated_by', 'updated_at']) or not (old.status = 'live' and new.status = 'removed') then
    raise exception 'An invoice line can only be removed from a draft.';
  end if;
  return new;
end;
$$;

create or replace function public.guard_statement() returns trigger
language plpgsql set search_path = '' as $$
declare
  b record;
  v_end date;
begin
  if tg_op = 'DELETE' then raise exception 'Statements are never deleted.'; end if;
  if tg_op = 'UPDATE' then
    if (to_jsonb(new) - array['pdf_base64', 'pdf_checksum', 'updated_by', 'updated_at']) is distinct from (to_jsonb(old) - array['pdf_base64', 'pdf_checksum', 'updated_by', 'updated_at'])
       or old.pdf_base64 is not null then
      raise exception 'An issued statement never changes.';
    end if;
    return new;
  end if;
  if public.from_portal() and not public.billing_can('invoice_issue', new.client_id) then raise exception 'Only someone with the invoice issue right issues statements.'; end if;
  if not exists (select 1 from public.client_enrolments e where e.id = new.enrolment_id and e.client_id = new.client_id and e.scheme = 'support_at_home') then
    raise exception 'Statements are for a client''s Support at Home program.';
  end if;
  v_end := (new.month + interval '1 month' - interval '1 day')::date;
  if v_end >= (now() at time zone 'Australia/Sydney')::date then raise exception 'Issue a month''s statement once the month has ended.'; end if;
  select * into b from public.client_quarter_budgets q where q.enrolment_id = new.enrolment_id and q.quarter_start <= new.month and q.quarter_end >= new.month and q.status <> 'draft';
  new.issued_by := auth.uid(); new.issued_at := now();
  new.snapshot := jsonb_build_object(
    'business', (select to_jsonb(x) from public.business_current x),
    'client', (select jsonb_build_object('name', c.name, 'client_ref', c.client_ref, 'aged_care_id', d.aged_care_id, 'address', d.home_address) from public.car_clients c left join public.client_details d on d.client_id = c.id where c.id = new.client_id),
    'month', new.month, 'month_end', v_end,
    'quarter', case when b.id is null then null else jsonb_build_object('start', b.quarter_start, 'end', b.quarter_end, 'quarterly_amount', b.quarterly_amount, 'carryover_in', b.carryover_in,
                 'care_management', b.care_management, 'spendable', b.spendable) end,
    'spent_in_month', (select coalesce(sum(bl.amount), 0) from public.billing_lines bl where bl.quarter_budget_id = b.id and bl.status = 'approved' and bl.service_date between new.month and v_end),
    'contributions_in_month', (select coalesce(sum(bl.client_share), 0) from public.billing_lines bl where bl.quarter_budget_id = b.id and bl.status = 'approved' and bl.service_date between new.month and v_end
                                 and not exists (select 1 from public.client_fee_reductions f where f.enrolment_id = new.enrolment_id and f.full_reduction and f.starts_on <= bl.service_date and (f.ends_on is null or f.ends_on >= bl.service_date))),
    'fee_reduction_in_month', exists (select 1 from public.client_fee_reductions f where f.enrolment_id = new.enrolment_id and f.starts_on <= v_end and (f.ends_on is null or f.ends_on >= new.month)),
    'available_now', (select available from public.funding_balances where account_kind = 'quarter_budget' and account_id = b.id),
    'lines', (select coalesce(jsonb_agg(jsonb_build_object('date', bl.service_date, 'band', bl.band_label, 'quantity', bl.quantity, 'amount', bl.amount, 'client_share', bl.client_share) order by bl.service_date, bl.starts_at), '[]')
                from public.billing_lines bl where bl.quarter_budget_id = b.id and bl.status = 'approved' and bl.service_date between new.month and v_end));
  return new;
end;
$$;

create or replace function public.guard_line_recovered() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.status = 'approved' and old.status = 'draft' and public.billing_review_lapsed(new.scheme) then
    raise exception 'Billing for this scheme is paused: a verified rule or figure is past its review date. Review it in Billing set-up.';
  end if;
  if new.status = 'voided' and old.status <> 'voided' and exists (select 1 from public.line_recoveries r where r.line_id = new.id and public.recovery_in_use(r.id)) then
    raise exception 'This line is in a claim or invoice. Correct it there (cancel the draft, or a credit or amendment once submitted).';
  end if;
  return new;
end;
$$;

create or replace function public.claim_prepare(p_program text, p_from date, p_to date) returns jsonb
language plpgsql set search_path = '' as $$
declare
  l record;
  v_payer uuid;
  v_claim uuid;
  v_ready text;
  v_excl jsonb := '[]';
  v_rec uuid;
  v_n integer := 0;
  c record;
  pc record;
  v_pm text;
  v_tpl uuid;
begin
  if public.from_portal() and not public.billing_can('claim_prepare') then raise exception 'Only someone with the claim prepare right prepares claims.'; end if;
  if p_program not in ('support_at_home', 'ndis') then raise exception 'Claims are for Support at Home or NDIS (agency-managed).'; end if;
  if p_to < p_from or p_to - p_from > 92 then raise exception 'Choose a period of up to three months.'; end if;
  v_ready := public.billing_scheme_ready(p_program);
  if v_ready is not null then raise exception '%', v_ready; end if;
  v_payer := (select id from public.billing_payers where kind = case when p_program = 'ndis' then 'ndia' else 'services_australia' end and active limit 1);
  select id into v_tpl from public.claim_templates where program = p_program and status = 'verified'
     and (review_by is null or review_by >= (now() at time zone 'Australia/Sydney')::date) order by version desc limit 1;
  if v_tpl is null then raise exception 'This program''s official claim template isn''t uploaded and verified (or is past its review date). Portal settings -> Billing.'; end if;
  perform set_config('portal.billing_prepare', 'on', true);
  insert into public.claims (program, payer_id, period_from, period_to, template_id) values (p_program, v_payer, p_from, p_to, v_tpl) returning id into v_claim;
  for l in select bl.* from public.billing_lines bl
            where bl.status = 'approved' and bl.scheme = p_program and bl.service_date between p_from and p_to
              and not exists (select 1 from public.line_recoveries r where r.line_id = bl.id and r.payer_role = 'funding' and public.recovery_in_use(r.id))
            order by bl.service_date, bl.starts_at loop
    select null::text as problem, null::text as ndis_zone, null::uuid as catalogue_version_id, null::text as item_number, null::numeric as price_limit into pc;
    if p_program = 'ndis' then
      select plan_management into v_pm from public.client_funding where id = l.funding_id;
      if coalesce(v_pm, '') <> 'ndia' then
        continue; -- plan- and self-managed are invoiced, not claimed
      end if;
      if not exists (select 1 from public.ndis_plan_details d where d.funding_id = l.funding_id and d.my_provider) then
        v_excl := v_excl || jsonb_build_object('line', l.id, 'reason', 'Not recorded as "my provider" for this agency-managed plan.'); continue;
      end if;
      select * into pc from public.ndis_price_check(l.id);
      if pc.problem is not null then v_excl := v_excl || jsonb_build_object('line', l.id, 'reason', pc.problem); continue; end if;
    end if;
    select id into v_rec from public.line_recoveries where line_id = l.id and payer_role = 'funding';
    if v_rec is null then
      insert into public.line_recoveries (line_id, client_id, payer_role, payer_id, service_value, amount, ndis_zone, ndis_catalogue_version_id, ndis_item, ndis_limit)
      values (l.id, l.client_id, 'funding', v_payer, l.amount,
              case when p_program = 'support_at_home' then coalesce(l.government_share, l.amount) else l.amount end,
              pc.ndis_zone, pc.catalogue_version_id, pc.item_number, pc.price_limit)
      returning id into v_rec;
    end if;
    -- Support at Home claims the full service value; Services Australia works out the contribution.
    insert into public.claim_items (claim_id, line_id, recovery_id, client_id, claimed_value, expected_amount)
    values (v_claim, l.id, v_rec, l.client_id, l.amount, (select amount from public.line_recoveries where id = v_rec));
    v_n := v_n + 1;
  end loop;
  -- Support at Home care management: once per approved quarter ending in the period (clinical, no contribution).
  if p_program = 'support_at_home' then
    for c in select q.* from public.client_quarter_budgets q
              where q.status in ('approved', 'closed') and q.care_management > 0 and q.quarter_end between p_from and p_to
                and not exists (select 1 from public.claim_items i join public.claims x on x.id = i.claim_id
                                 where i.quarter_budget_id = q.id and i.status = 'live' and x.status <> 'cancelled')
              order by q.quarter_end loop
      insert into public.claim_items (claim_id, quarter_budget_id, client_id, claimed_value, expected_amount)
      values (v_claim, c.id, c.client_id, c.care_management, c.care_management);
      v_n := v_n + 1;
    end loop;
  end if;
  update public.claims set item_count = v_n, excluded = v_excl,
         total_claimed = (select coalesce(sum(claimed_value), 0) from public.claim_items where claim_id = v_claim and status = 'live'),
         total_expected = (select coalesce(sum(expected_amount), 0) from public.claim_items where claim_id = v_claim and status = 'live')
   where id = v_claim;
  perform set_config('portal.billing_prepare', 'off', true);
  return jsonb_build_object('claim', v_claim, 'lines', v_n, 'excluded', jsonb_array_length(v_excl));
end;
$$;

create or replace function public.invoice_prepare(p_kind text, p_from date, p_to date) returns jsonb
language plpgsql set search_path = '' as $$
declare
  l record;
  v_role text := case when p_kind in ('sah_contribution', 'private') then 'client' else 'funding' end;
  v_payer uuid;
  v_inv uuid;
  v_rec uuid;
  v_amt numeric;
  v_excl jsonb := '[]';
  v_made integer := 0;
  v_n integer := 0;
  v_pm text;
  v_ready text;
  c record;
begin
  if public.from_portal() and not public.billing_can('invoice_prepare') then raise exception 'Only someone with the invoice prepare right prepares invoices.'; end if;
  if p_kind not in ('sah_contribution', 'private', 'ndis_plan_managed', 'ndis_self_managed') then raise exception 'Choose the kind of invoice.'; end if;
  if p_to < p_from or p_to - p_from > 92 then raise exception 'Choose a period of up to three months.'; end if;
  v_ready := public.billing_scheme_ready(case when p_kind = 'sah_contribution' then 'support_at_home' when p_kind = 'private' then 'private' else 'ndis' end);
  if v_ready is not null then raise exception '%', v_ready; end if;
  perform set_config('portal.billing_prepare', 'on', true);
  for l in select bl.* from public.billing_lines bl
            where bl.status = 'approved' and bl.service_date between p_from and p_to
              and bl.scheme = case when p_kind = 'sah_contribution' then 'support_at_home' when p_kind = 'private' then 'private' else 'ndis' end
              and not exists (select 1 from public.line_recoveries r where r.line_id = bl.id and r.payer_role = v_role and public.recovery_in_use(r.id))
            order by bl.client_id, bl.service_date, bl.starts_at loop
    if p_kind in ('ndis_plan_managed', 'ndis_self_managed') then
      select plan_management into v_pm from public.client_funding where id = l.funding_id;
      if coalesce(v_pm, '') <> (case when p_kind = 'ndis_plan_managed' then 'plan' else 'self' end) then continue; end if;
    end if;
    v_amt := case when p_kind = 'sah_contribution' then coalesce(l.client_share, 0) when p_kind = 'private' then l.amount else l.amount end;
    if p_kind = 'sah_contribution' and l.sah_category = 'clinical' and v_amt > 0 then
      v_excl := v_excl || jsonb_build_object('line', l.id, 'reason', 'Clinical care has no participant contribution. Check the client''s contribution rate.'); continue;
    end if;
    if v_amt <= 0 then continue; end if;
    -- Support at Home: no contribution invoice while a full fee reduction supplement applies.
    if p_kind = 'sah_contribution' and exists (select 1 from public.client_fee_reductions f where f.client_id = l.client_id and f.enrolment_id = l.enrolment_id and f.full_reduction
                                                 and f.starts_on <= l.service_date and (f.ends_on is null or f.ends_on >= l.service_date)) then
      v_excl := v_excl || jsonb_build_object('line', l.id, 'reason', 'Full fee reduction supplement applies.'); continue;
    end if;
    v_payer := public.billing_payer_for(l.id, v_role);
    if v_payer is null then
      v_excl := v_excl || jsonb_build_object('line', l.id, 'reason', case when v_role = 'client' then 'No billing contact (payer) recorded for this client.' else 'No plan manager or participant payer recorded for this NDIS plan.' end);
      continue;
    end if;
    if p_kind like 'ndis_%' then
      select * into c from public.ndis_price_check(l.id);
      if c.problem is not null then v_excl := v_excl || jsonb_build_object('line', l.id, 'reason', c.problem); continue; end if;
    end if;
    select id into v_inv from public.invoices where kind = p_kind and client_id = l.client_id and payer_id = v_payer and status = 'draft' and period_from = p_from and period_to = p_to;
    if v_inv is null then
      insert into public.invoices (kind, client_id, payer_id, period_from, period_to) values (p_kind, l.client_id, v_payer, p_from, p_to) returning id into v_inv;
      v_made := v_made + 1;
    end if;
    select id into v_rec from public.line_recoveries where line_id = l.id and payer_role = v_role;
    if v_rec is null then
      insert into public.line_recoveries (line_id, client_id, payer_role, payer_id, service_value, amount)
      values (l.id, l.client_id, v_role, v_payer, l.amount, v_amt) returning id into v_rec;
    end if;
    insert into public.invoice_items (invoice_id, line_id, recovery_id, client_id, description, service_date, quantity, unit_price, amount, gst_code)
    select v_inv, l.id, v_rec, l.client_id,
           coalesce(sv.label, 'Service') || ' (' || l.band_label || ')' || case when l.kind = 'cancellation' then ', late cancellation' else '' end
             || case when p_kind = 'sah_contribution' then ', your contribution ' || coalesce(l.contribution_pct::text, '?') || '% of $' || l.amount else '' end
             || coalesce(', NDIS item ' || nullif(pi.ndis_item, ''), ''),
           l.service_date, case when p_kind = 'sah_contribution' then 1 else l.quantity end, case when p_kind = 'sah_contribution' then v_amt else l.unit_price end, v_amt, l.gst_code
      from public.client_services sv, public.price_items pi where sv.id = l.service_id and pi.id = l.price_item_id;
    v_n := v_n + 1;
  end loop;
  update public.invoices v set subtotal = (select coalesce(sum(amount), 0) from public.invoice_items i where i.invoice_id = v.id and i.status = 'live'),
                               total = (select coalesce(sum(amount), 0) from public.invoice_items i where i.invoice_id = v.id and i.status = 'live')
   where v.status = 'draft' and v.kind = p_kind and v.period_from = p_from and v.period_to = p_to;
  perform set_config('portal.billing_prepare', 'off', true);
  return jsonb_build_object('invoices_made', v_made, 'lines', v_n, 'excluded', v_excl);
end;
$$;

do $$
declare
  t text;
begin
  -- Set-up: business details, payers (shared), catalogue, templates, counters.
  foreach t in array array['business_details', 'ndis_catalogue_versions', 'ndis_support_items', 'claim_templates'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "billing see %s" on public.%I', t, t);
    execute format('create policy "billing see %s" on public.%I for select to authenticated using (public.billing_can(''view'') or public.is_system_admin())', t, t);
    execute format('drop policy if exists "billing add %s" on public.%I', t, t);
    execute format('create policy "billing add %s" on public.%I for insert to authenticated with check (public.billing_can(''prices'') or public.billing_can(''approve'') or public.is_system_admin())', t, t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert on public.%I to authenticated', t);
  end loop;
  foreach t in array array['ndis_catalogue_versions', 'ndis_support_items', 'claim_templates'] loop
    execute format('drop policy if exists "billing change %s" on public.%I', t, t);
    execute format('create policy "billing change %s" on public.%I for update to authenticated using (public.billing_can(''prices'') or public.billing_can(''approve'')) with check (public.billing_can(''prices'') or public.billing_can(''approve''))', t, t);
    execute format('drop policy if exists "billing remove %s" on public.%I', t, t);
    execute format('create policy "billing remove %s" on public.%I for delete to authenticated using (public.billing_can(''prices''))', t, t);
    execute format('grant update, delete on public.%I to authenticated', t);
  end loop;
  alter table public.invoice_number_counters enable row level security;
  revoke all on public.invoice_number_counters from anon, authenticated;
  drop policy if exists "billing numbering" on public.invoice_number_counters;
  create policy "billing numbering" on public.invoice_number_counters for all to authenticated using (public.billing_can('invoice_issue')) with check (public.billing_can('invoice_issue'));
  grant select, insert, update on public.invoice_number_counters to authenticated;

  alter table public.billing_payers enable row level security;
  drop policy if exists "billing see payers" on public.billing_payers;
  create policy "billing see payers" on public.billing_payers for select to authenticated using (case when client_id is null then public.billing_can('view') else public.billing_can('view', client_id) end);
  drop policy if exists "billing add payers" on public.billing_payers;
  create policy "billing add payers" on public.billing_payers for insert to authenticated with check (case when client_id is null then public.billing_can('prepare') else public.billing_can('prepare', client_id) end);
  drop policy if exists "billing change payers" on public.billing_payers;
  create policy "billing change payers" on public.billing_payers for update to authenticated using (case when client_id is null then public.billing_can('prepare') else public.billing_can('prepare', client_id) end)
    with check (case when client_id is null then public.billing_can('prepare') else public.billing_can('prepare', client_id) end);
  grant select, insert, update on public.billing_payers to authenticated;
  revoke all on public.billing_payers from anon;

  -- Client records.
  foreach t in array array['client_payer_links', 'client_fee_reductions', 'client_location_pricing', 'ndis_plan_details', 'line_recoveries', 'claim_items', 'invoices', 'invoice_items', 'client_statements'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "billing see %s" on public.%I', t, t);
    execute format('create policy "billing see %s" on public.%I for select to authenticated using (public.billing_can(''view'', client_id))', t, t);
    execute format('drop policy if exists "billing add %s" on public.%I', t, t);
    execute format('create policy "billing add %s" on public.%I for insert to authenticated with check (public.billing_can(''prepare'', client_id) or public.billing_can(''claim_prepare'', client_id) or public.billing_can(''invoice_prepare'', client_id) or public.billing_can(''invoice_issue'', client_id))', t, t);
    execute format('drop policy if exists "billing change %s" on public.%I', t, t);
    execute format('create policy "billing change %s" on public.%I for update to authenticated using (public.billing_can(''view'', client_id)) with check (public.billing_can(''view'', client_id))', t, t);
    execute format('grant select, insert, update on public.%I to authenticated', t);
    execute format('revoke all on public.%I from anon', t);
  end loop;
  -- Claims cover many clients: people with all-client Billing reach.
  foreach t in array array['claims', 'claim_submissions'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "billing see %s" on public.%I', t, t);
    execute format('create policy "billing see %s" on public.%I for select to authenticated using (public.billing_can(''view''))', t, t);
    execute format('drop policy if exists "billing add %s" on public.%I', t, t);
    execute format('create policy "billing add %s" on public.%I for insert to authenticated with check (public.billing_can(''claim_prepare'') or public.billing_can(''claim_submit''))', t, t);
    execute format('drop policy if exists "billing change %s" on public.%I', t, t);
    execute format('create policy "billing change %s" on public.%I for update to authenticated using (public.billing_can(''view'')) with check (public.billing_can(''view''))', t, t);
    execute format('grant select, insert, update on public.%I to authenticated', t);
    execute format('revoke all on public.%I from anon', t);
  end loop;
  grant select on public.business_current to authenticated;
  revoke all on public.business_current from anon;
end $$;
revoke execute on function public.claim_prepare(text, date, date) from public, anon;
grant execute on function public.claim_prepare(text, date, date) to authenticated;
revoke execute on function public.invoice_prepare(text, date, date) from public, anon;
grant execute on function public.invoice_prepare(text, date, date) to authenticated;
revoke execute on function public.ndis_price_check(uuid) from public, anon;
grant execute on function public.ndis_price_check(uuid) to authenticated;

do $$
declare
  t text;
begin
  drop trigger if exists guard_business_details on public.business_details;
  create trigger guard_business_details before insert or update or delete on public.business_details for each row execute function public.guard_business_details();
  foreach t in array array['ndis_catalogue_versions', 'claim_templates'] loop
    execute format('drop trigger if exists guard_billing_reference on public.%I', t);
    execute format('create trigger guard_billing_reference before insert or update or delete on public.%I for each row execute function public.guard_billing_reference()', t);
  end loop;
  drop trigger if exists guard_ndis_item on public.ndis_support_items;
  create trigger guard_ndis_item before insert or update or delete on public.ndis_support_items for each row execute function public.guard_ndis_item();
  drop trigger if exists guard_line_recovery on public.line_recoveries;
  create trigger guard_line_recovery before insert or update or delete on public.line_recoveries for each row execute function public.guard_line_recovery();
  drop trigger if exists guard_claim on public.claims;
  create trigger guard_claim before insert or update or delete on public.claims for each row execute function public.guard_claim();
  drop trigger if exists guard_claim_item on public.claim_items;
  create trigger guard_claim_item before insert or update or delete on public.claim_items for each row execute function public.guard_claim_item();
  drop trigger if exists guard_claim_submission on public.claim_submissions;
  create trigger guard_claim_submission before insert or update or delete on public.claim_submissions for each row execute function public.guard_claim_submission();
  drop trigger if exists guard_invoice on public.invoices;
  create trigger guard_invoice before insert or update or delete on public.invoices for each row execute function public.guard_invoice();
  drop trigger if exists guard_invoice_item on public.invoice_items;
  create trigger guard_invoice_item before insert or update or delete on public.invoice_items for each row execute function public.guard_invoice_item();
  drop trigger if exists guard_statement on public.client_statements;
  create trigger guard_statement before insert or update or delete on public.client_statements for each row execute function public.guard_statement();
  drop trigger if exists guard_line_recovered on public.billing_lines;
  create trigger guard_line_recovered before update on public.billing_lines for each row execute function public.guard_line_recovered();

  foreach t in array array['business_details:business_details', 'ndis_catalogue_versions:ndis_catalogue_version', 'claim_templates:claim_template', 'billing_payers:billing_payer', 'claims:claim', 'claim_submissions:claim_submission'] loop
    execute format('drop trigger if exists log_billing_setup on public.%I', split_part(t, ':', 1));
    execute format('create trigger log_billing_setup after insert or update or delete on public.%I for each row execute function public.log_car_setup(%L)', split_part(t, ':', 1), split_part(t, ':', 2));
    execute format('drop trigger if exists stamp_billing_setup on public.%I', split_part(t, ':', 1));
    execute format('create trigger stamp_billing_setup before insert or update on public.%I for each row execute function public.stamp_billing_updated()', split_part(t, ':', 1));
  end loop;
  foreach t in array array['client_payer_links', 'client_fee_reductions', 'client_location_pricing', 'ndis_plan_details', 'line_recoveries', 'claim_items', 'invoices', 'invoice_items', 'client_statements'] loop
    execute format('drop trigger if exists log_client_change on public.%I', t);
    execute format('create trigger log_client_change before insert or update on public.%I for each row execute function public.log_client_change()', t);
    execute format('drop trigger if exists log_client_audit on public.%I', t);
    execute format('create trigger log_client_audit after insert or update or delete on public.%I for each row execute function public.log_client_change()', t);
  end loop;
end $$;

create or replace function public.guard_client_billing_link() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'DELETE' then raise exception 'These records are never deleted. End them with a date instead.'; end if;
  if tg_table_name = 'client_payer_links' then
    if not exists (select 1 from public.billing_payers p where p.id = new.payer_id and (p.client_id is null or p.client_id = new.client_id)) then
      raise exception 'Choose a payer for this client.';
    end if;
    if new.funding_id is not null and not exists (select 1 from public.client_funding f where f.id = new.funding_id and f.client_id = new.client_id) then
      raise exception 'Choose one of this client''s funding records.';
    end if;
    if tg_op = 'UPDATE' and (to_jsonb(new) - array['ends_on', 'updated_by', 'updated_at']) is distinct from (to_jsonb(old) - array['ends_on', 'updated_by', 'updated_at']) then
      raise exception 'A payer link only gets an end date. Add a new one for changes.';
    end if;
  elsif tg_table_name = 'client_fee_reductions' then
    if not exists (select 1 from public.client_enrolments e where e.id = new.enrolment_id and e.client_id = new.client_id and e.scheme = 'support_at_home') then
      raise exception 'Choose the client''s Support at Home program.';
    end if;
    if tg_op = 'UPDATE' and (to_jsonb(new) - array['ends_on', 'updated_by', 'updated_at']) is distinct from (to_jsonb(old) - array['ends_on', 'updated_by', 'updated_at']) then
      raise exception 'A fee reduction only gets an end date. Add a new one for changes.';
    end if;
  elsif tg_table_name = 'client_location_pricing' then
    new.client_id := (select client_id from public.client_locations where id = new.location_id);
    if new.client_id is null then raise exception 'Choose a client location.'; end if;
    new.set_by := auth.uid(); new.set_at := now();
  elsif tg_table_name = 'ndis_plan_details' then
    new.client_id := (select client_id from public.client_funding where id = new.funding_id and scheme = 'ndis');
    if new.client_id is null then raise exception 'Choose an NDIS funding record.'; end if;
    new.recorded_by := auth.uid();
  end if;
  return new;
end;
$$;
do $$
declare t text;
begin
  foreach t in array array['client_payer_links', 'client_fee_reductions', 'client_location_pricing', 'ndis_plan_details'] loop
    execute format('drop trigger if exists guard_client_billing_link on public.%I', t);
    execute format('create trigger guard_client_billing_link before insert or update or delete on public.%I for each row execute function public.guard_client_billing_link()', t);
  end loop;
end $$;

revoke execute on function public.guard_business_details() from public, anon, authenticated;
revoke execute on function public.guard_billing_reference() from public, anon, authenticated;
revoke execute on function public.guard_ndis_item() from public, anon, authenticated;
revoke execute on function public.guard_line_recovery() from public, anon, authenticated;
revoke execute on function public.guard_claim() from public, anon, authenticated;
revoke execute on function public.guard_claim_item() from public, anon, authenticated;
revoke execute on function public.guard_claim_submission() from public, anon, authenticated;
revoke execute on function public.guard_invoice() from public, anon, authenticated;
revoke execute on function public.guard_invoice_item() from public, anon, authenticated;
revoke execute on function public.guard_statement() from public, anon, authenticated;
revoke execute on function public.guard_line_recovered() from public, anon, authenticated;
revoke execute on function public.guard_client_billing_link() from public, anon, authenticated;
commit;
