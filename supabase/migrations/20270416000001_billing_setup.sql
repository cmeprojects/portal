-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 161): billing set-up (Phase 4A of the programs,
-- assessments and billing plan, approved 21 Nov 2026). Set-up only: nothing
-- here calculates or bills anything (billing lines come in Phase 4B).
--   * "Billing" access part, separate from Funding: view, prepare, approve,
--     prices, export. Default: System Administrator and Manager Administrators only.
--   * Scheme billing rules and a verification register: every scheme starts
--     "not confirmed"; calculations for it stay off until its rules are
--     confirmed (and, where listed, its figures verified with an "as at" date).
--   * The change log records additions, edits and removals of draft prices and
--     rate bands (the existing log_car_setup now also records removals).
--   * Price lists per scheme, versioned (a published version never changes; a
--     new version is a copy), each with its own rate bands (independent of
--     payroll), rounding rule, minimum and boundary-crossing rule.
--   * Public holidays by state.
--   * Client contribution rates (Support at Home), dated, never edited.
--   * Billing terms for approved services: dated versions, linked to the exact
--     program enrolment, funding record, agreement, price list and (optionally)
--     the support plan line; approved separately from care plans and funding.
--   * Cancellation details for cancelled shifts (notice, who, reason,
--     reasonable grounds, charge decision).
-- No new security definer function. Changes are in the change log / client
-- audit trail. Nothing existing is changed or deleted. Safe to run again.

-- 1. Access.
insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order, actions, grant_ready) values
  ('clients.billing', 'clients.list', 'clients', 'Billing', 'sensitive', true, 269, '{view,prepare,approve,prices,export}', true),
  ('system.settings.billing', 'system.settings', 'system', 'Billing set-up', 'normal', false, 1129, '{view}', false)
on conflict (id) do nothing;
update public.app_modules set status = 'active' where id in ('clients.billing', 'system.settings.billing') and status = 'retired';
-- Defaults (owner, 22 Nov 2026): the System Administrator and Manager
-- Administrators have every Billing action; nobody else has any by default
-- (other managers, Case Managers, Intake, Payroll & Rostering, support workers).
-- More people are given Billing on the Access page (for example by job title).
-- A "restrict" set on the Access page still applies to a Manager Administrator.
create or replace function public.billing_can(p_action text, p_client uuid default null) returns boolean
language sql stable set search_path = '' as $$
  select case
    when public.is_system_admin() and public.mfa_ok() then true
    when public.is_manager_admin(auth.uid()) and public.mfa_ok()
         and not exists (select 1 from public.access_grants g
                          where g.user_id = auth.uid() and g.module_id = 'clients.billing' and g.effect = 'restrict' and g.revoked_at is null
                            and (g.expires_at is null or g.expires_at > now()) and (g.starts_at is null or g.starts_at <= now())
                            and (cardinality(g.actions) = 0 or p_action = any (g.actions))) then true
    else public.care_doc_reach('clients.billing', p_action, p_client)
  end
$$;

-- 2. Scheme rules and the verification register.
create table if not exists public.billing_scheme_rules (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  scheme text not null unique,
  status text not null default 'not_confirmed' check (status in ('not_confirmed', 'confirmed')),
  rules_summary text not null default '' check (length(rules_summary) <= 4000),
  source text not null default '' check (length(source) <= 1000),
  as_at date,
  confirmed_by uuid,
  confirmed_at timestamptz,
  updated_by uuid,
  updated_at timestamptz not null default now()
);
insert into public.billing_scheme_rules (scheme) select key from public.client_schemes on conflict (scheme) do nothing;

create table if not exists public.billing_rule_checks (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  scheme text not null,
  item text not null check (length(trim(item)) between 1 and 300),
  value text not null default '' check (length(value) <= 1000),
  source text not null default '' check (length(source) <= 1000),
  as_at date,
  status text not null default 'unverified' check (status in ('unverified', 'verified')),
  checked_by uuid,
  checked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  unique (scheme, item)
);
insert into public.billing_rule_checks (scheme, item) values
  ('support_at_home', 'Quarterly rollover cap ($1,000 or 10% of the quarterly budget, whichever is higher)'),
  ('support_at_home', 'Care management: 10% of each quarterly budget'),
  ('support_at_home', 'Personal care: 0% client contribution from 1 Oct 2026'),
  ('support_at_home', 'Contribution rates by category and client type'),
  ('support_at_home', 'Lifetime contribution cap and its indexing dates'),
  ('support_at_home', 'Claim deadline (60 days after quarter end, or after exit)'),
  ('support_at_home', 'Late cancellation: under 2 business days, unless reasonable grounds'),
  ('support_at_home', 'New provider: budget may be unconfirmed for 28 days'),
  ('ndis', 'Claims within 90 days of the support (from 1 Dec 2026)'),
  ('ndis', 'Short notice cancellation: 7 clear days (support workers) or 2 clear business days (others)'),
  ('ndis', 'Provider travel caps (30 / 60 minutes)'),
  ('ndis', 'Price limits from the current Pricing Schedule'),
  ('ndis', 'Shift-crossing rules for evening and night items')
on conflict (scheme, item) do nothing;

create or replace function public.guard_billing_rules() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'DELETE' then
    raise exception 'Billing rules and checks are never deleted.';
  end if;
  if tg_table_name = 'billing_rule_checks' then
    if tg_op = 'UPDATE' and new.scheme is distinct from old.scheme then
      raise exception 'A check stays with its scheme.';
    end if;
    if new.status = 'verified' then
      if length(trim(new.value)) = 0 or length(trim(new.source)) = 0 or new.as_at is null then
        raise exception 'To mark it verified, record the figure or rule, the official source and the "as at" date.';
      end if;
      if tg_op = 'INSERT' or old.status <> 'verified' or (new.value, new.source, new.as_at) is distinct from (old.value, old.source, old.as_at) then
        new.checked_by := auth.uid(); new.checked_at := now();
      else
        new.checked_by := old.checked_by; new.checked_at := old.checked_at;
      end if;
    else
      new.checked_by := null; new.checked_at := null;
    end if;
    return new;
  end if;
  -- Scheme rules.
  if tg_op = 'UPDATE' and new.scheme is distinct from old.scheme then
    raise exception 'The scheme isn''t changed.';
  end if;
  if new.status = 'confirmed' then
    if length(trim(new.rules_summary)) = 0 or length(trim(new.source)) = 0 or new.as_at is null then
      raise exception 'To confirm a scheme''s billing rules, write them down with their source and "as at" date.';
    end if;
    if exists (select 1 from public.billing_rule_checks c where c.scheme = new.scheme and c.status <> 'verified') then
      raise exception 'Verify every listed figure for this scheme first.';
    end if;
    if tg_op = 'INSERT' or old.status <> 'confirmed' or (new.rules_summary, new.source, new.as_at) is distinct from (old.rules_summary, old.source, old.as_at) then
      new.confirmed_by := auth.uid(); new.confirmed_at := now();
    else
      new.confirmed_by := old.confirmed_by; new.confirmed_at := old.confirmed_at;
    end if;
  else
    new.confirmed_by := null; new.confirmed_at := null;
  end if;
  return new;
end;
$$;

-- A figure can't become unverified (or change) under a confirmed scheme without un-confirming it first.
create or replace function public.guard_billing_check_scheme() returns trigger
language plpgsql set search_path = '' as $$
begin
  if exists (select 1 from public.billing_scheme_rules r where r.scheme = new.scheme and r.status = 'confirmed')
     and (tg_op = 'INSERT' or new.status <> 'verified' or (new.value, new.source, new.as_at) is distinct from (old.value, old.source, old.as_at)) then
    raise exception 'This scheme''s rules are confirmed. Mark them not confirmed before changing its checks.';
  end if;
  return new;
end;
$$;

-- 3. Price lists, versions, rate bands and items.
create table if not exists public.price_lists (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  scheme text not null,
  name text not null check (length(trim(name)) between 1 and 120),
  description text not null default '' check (length(description) <= 1000),
  active boolean not null default true,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  unique (scheme, name)
);
create table if not exists public.price_list_versions (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  price_list_id uuid not null references public.price_lists (id),
  version integer not null default 1,
  status text not null default 'draft' check (status in ('draft', 'published', 'retired')),
  effective_from date,
  unit_minutes integer not null default 15 check (unit_minutes between 1 and 60),
  rounding text not null default 'nearest' check (rounding in ('nearest', 'up', 'down')),
  minimum_minutes integer not null default 0 check (minimum_minutes between 0 and 480),
  crossing text not null default 'split' check (crossing in ('split', 'whole_highest')),
  notes text not null default '' check (length(notes) <= 2000),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  published_by uuid,
  published_at timestamptz,
  updated_by uuid,
  updated_at timestamptz not null default now(),
  unique (price_list_id, version)
);
create unique index if not exists price_list_versions_one_draft on public.price_list_versions (price_list_id) where status = 'draft';
create unique index if not exists price_list_versions_one_published on public.price_list_versions (price_list_id) where status = 'published';

create table if not exists public.price_list_bands (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  version_id uuid not null references public.price_list_versions (id),
  key text not null check (key ~ '^[a-z][a-z0-9_]{0,39}$'),
  label text not null check (length(trim(label)) between 1 and 80),
  day_kind text not null check (day_kind in ('weekday', 'saturday', 'sunday', 'public_holiday')),
  starts_at time,
  ends_at time,
  priority integer not null default 0,
  sort_order integer not null default 0,
  updated_by uuid,
  updated_at timestamptz not null default now(),
  unique (version_id, key),
  constraint price_list_bands_times check (
    (day_kind = 'weekday' and starts_at is not null and ends_at is not null and (ends_at > starts_at or ends_at = '00:00'))
    or (day_kind <> 'weekday' and starts_at is null and ends_at is null))
);

create table if not exists public.price_items (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  version_id uuid not null references public.price_list_versions (id),
  catalogue_id uuid references public.service_catalogue (id),
  label text not null check (length(trim(label)) between 1 and 160),
  unit text not null default 'hour' check (unit in ('hour', 'visit', 'each', 'km', 'day')),
  band_key text,
  price numeric(10, 2) not null check (price between 0 and 100000),
  gst_code text not null default 'gst_free' check (gst_code in ('gst_free', 'taxable', 'input_taxed')),
  sah_category text check (sah_category in ('clinical', 'independence', 'everyday_living')),
  personal_care boolean not null default false,
  ndis_item text not null default '' check (length(ndis_item) <= 40),
  sort_order integer not null default 0,
  updated_by uuid,
  updated_at timestamptz not null default now()
);
create unique index if not exists price_items_one_per_band on public.price_items (version_id, coalesce(catalogue_id::text, label), coalesce(band_key, ''));

-- Lists: scheme fixed; never deleted.
create or replace function public.guard_price_list() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'DELETE' then
    raise exception 'Price lists are never deleted. Mark them inactive.';
  end if;
  if not exists (select 1 from public.client_schemes s where s.key = new.scheme) then
    raise exception 'Choose one of the schemes.';
  end if;
  if tg_op = 'UPDATE' and new.scheme is distinct from old.scheme then
    raise exception 'A price list stays with its scheme.';
  end if;
  return new;
end;
$$;

-- Versions: only a draft changes; publishing checks the bands and items and retires the old one.
create or replace function public.guard_price_version() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_prev date;
  v_cover integer;
begin
  if tg_op = 'DELETE' then
    if old.status <> 'draft' then
      raise exception 'A published or retired price list version is never deleted.';
    end if;
    return old;
  end if;
  if tg_op = 'INSERT' then
    new.status := 'draft'; new.published_by := null; new.published_at := null;
    new.created_by := auth.uid(); new.created_at := now();
    new.version := coalesce((select max(version) from public.price_list_versions where price_list_id = new.price_list_id), 0) + 1;
    return new;
  end if;
  if (new.price_list_id, new.version, new.created_by, new.created_at) is distinct from (old.price_list_id, old.version, old.created_by, old.created_at) then
    raise exception 'A version keeps its list, number and maker.';
  end if;
  if old.status = 'retired' and new is distinct from old then
    raise exception 'A retired version never changes.';
  end if;
  if old.status = 'published' then
    if new.status = 'retired' and pg_trigger_depth() > 1
       and (new.effective_from, new.unit_minutes, new.rounding, new.minimum_minutes, new.crossing, new.notes) is not distinct from (old.effective_from, old.unit_minutes, old.rounding, old.minimum_minutes, old.crossing, old.notes) then
      return new;
    end if;
    raise exception 'A published version never changes. Start a new version.';
  end if;
  -- Draft.
  if new.status = 'retired' then
    raise exception 'Only a published version is retired (by publishing the next one).';
  end if;
  new.published_by := old.published_by; new.published_at := old.published_at;
  if new.status = 'published' then
    if new.effective_from is null then
      raise exception 'Give the date this version takes effect.';
    end if;
    select max(effective_from) into v_prev from public.price_list_versions where price_list_id = new.price_list_id and status in ('published', 'retired') and id <> new.id;
    if v_prev is not null and new.effective_from <= v_prev then
      raise exception 'It must take effect after the version it replaces (from %).', to_char(v_prev, 'DD/MM/YYYY');
    end if;
    if exists (select 1 from public.price_list_bands b where b.version_id = new.id and b.day_kind = 'weekday') then
      -- Weekday bands cover the whole day once, without gaps or overlaps (checked minute by minute in 15-minute steps).
      select count(*) into v_cover
        from generate_series(0, 95) g(q)
       where (select count(*) from public.price_list_bands b
               where b.version_id = new.id and b.day_kind = 'weekday'
                 and (g.q * interval '15 minutes')::time >= b.starts_at
                 and ((g.q * interval '15 minutes')::time < b.ends_at or b.ends_at = '00:00')) <> 1;
      if v_cover > 0 then
        raise exception 'Weekday rate bands must cover the whole day once, with no gaps or overlaps.';
      end if;
    end if;
    if (select count(distinct day_kind) from public.price_list_bands b where b.version_id = new.id and b.day_kind <> 'weekday')
       <> (select count(*) from public.price_list_bands b where b.version_id = new.id and b.day_kind <> 'weekday') then
      raise exception 'Saturday, Sunday and public holiday have one band each.';
    end if;
    if not exists (select 1 from public.price_items i where i.version_id = new.id) then
      raise exception 'Add at least one price before publishing.';
    end if;
    if exists (select 1 from public.price_items i where i.version_id = new.id and i.band_key is not null
                and not exists (select 1 from public.price_list_bands b where b.version_id = new.id and b.key = i.band_key)) then
      raise exception 'Every price must use one of this version''s rate bands.';
    end if;
    if exists (select 1 from public.price_items i join public.price_lists l on l.id = (select price_list_id from public.price_list_versions where id = new.id)
                where i.version_id = new.id and l.scheme = 'support_at_home' and i.sah_category is null) then
      raise exception 'Every Support at Home price needs its category (clinical, independence or everyday living).';
    end if;
    update public.price_list_versions set status = 'retired' where price_list_id = new.price_list_id and status = 'published' and id <> new.id;
    new.published_by := auth.uid(); new.published_at := now();
  end if;
  return new;
end;
$$;

-- Bands and items change only on a draft version.
create or replace function public.guard_price_part() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_version uuid := case when tg_op = 'DELETE' then old.version_id else new.version_id end;
begin
  if tg_op = 'UPDATE' and new.version_id is distinct from old.version_id then
    raise exception 'It stays with its version.';
  end if;
  if (select status from public.price_list_versions where id = v_version) is distinct from 'draft' then
    raise exception 'Only a draft version can be changed. Start a new version.';
  end if;
  if tg_op = 'DELETE' then
    return old;
  end if;
  if tg_table_name = 'price_items' and (to_jsonb(new) ->> 'catalogue_id') is not null
     and not exists (select 1 from public.service_catalogue c where c.id = (to_jsonb(new) ->> 'catalogue_id')::uuid) then
    raise exception 'Choose a service from the catalogue.';
  end if;
  return new;
end;
$$;

-- A new version is a copy of the latest one (as the person).
create or replace function public.price_list_new_version(p_list uuid) returns uuid
language plpgsql set search_path = '' as $$
declare
  v_from public.price_list_versions;
  v_new uuid;
begin
  if exists (select 1 from public.price_list_versions where price_list_id = p_list and status = 'draft') then
    raise exception 'This price list already has a draft. Edit that one.';
  end if;
  select * into v_from from public.price_list_versions where price_list_id = p_list order by version desc limit 1;
  insert into public.price_list_versions (price_list_id, unit_minutes, rounding, minimum_minutes, crossing, notes)
  values (p_list, coalesce(v_from.unit_minutes, 15), coalesce(v_from.rounding, 'nearest'), coalesce(v_from.minimum_minutes, 0), coalesce(v_from.crossing, 'split'), coalesce(v_from.notes, ''))
  returning id into v_new;
  if v_from.id is not null then
    insert into public.price_list_bands (version_id, key, label, day_kind, starts_at, ends_at, priority, sort_order)
    select v_new, key, label, day_kind, starts_at, ends_at, priority, sort_order from public.price_list_bands where version_id = v_from.id;
    insert into public.price_items (version_id, catalogue_id, label, unit, band_key, price, gst_code, sah_category, personal_care, ndis_item, sort_order)
    select v_new, catalogue_id, label, unit, band_key, price, gst_code, sah_category, personal_care, ndis_item, sort_order from public.price_items where version_id = v_from.id;
  end if;
  return v_new;
end;
$$;
revoke execute on function public.price_list_new_version(uuid) from public, anon;
grant execute on function public.price_list_new_version(uuid) to authenticated;

-- 4. Public holidays by state.
create table if not exists public.public_holidays (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  state text not null check (state in ('ACT', 'NSW', 'NT', 'QLD', 'SA', 'TAS', 'VIC', 'WA')),
  on_date date not null,
  name text not null check (length(trim(name)) between 1 and 120),
  active boolean not null default true,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  unique (state, on_date)
);
create or replace function public.guard_public_holiday() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'DELETE' then
    raise exception 'Public holidays aren''t deleted. Switch one off instead.';
  end if;
  if tg_op = 'UPDATE' and (new.state, new.on_date) is distinct from (old.state, old.on_date) then
    raise exception 'A holiday keeps its state and date. Add the right one and switch this one off.';
  end if;
  return new;
end;
$$;

-- 5. Client contribution rates (Support at Home), dated; only closing a rate changes it.
create table if not exists public.client_contribution_rates (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id),
  enrolment_id uuid not null references public.client_enrolments (id),
  category text not null check (category in ('clinical', 'independence', 'everyday_living')),
  rate_pct numeric(5, 2) not null check (rate_pct between 0 and 100),
  contribution_group text not null default '' check (contribution_group in ('', 'standard', 'no_worse_off')),
  effective_from date not null,
  effective_to date,
  source text not null check (length(trim(source)) between 1 and 300),
  document_id uuid references public.client_documents (id),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  constraint client_contribution_rates_dates check (effective_to is null or effective_to >= effective_from)
);
create or replace function public.guard_contribution_rate() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'DELETE' then
    raise exception 'Contribution rates are never deleted. End one and add the new rate.';
  end if;
  if tg_op = 'UPDATE' then
    if (to_jsonb(new) - array['effective_to', 'updated_by', 'updated_at']) is distinct from (to_jsonb(old) - array['effective_to', 'updated_by', 'updated_at']) or old.effective_to is not null then
      raise exception 'A recorded rate isn''t changed. End it and add the new rate.';
    end if;
  else
    new.created_by := auth.uid(); new.created_at := now();
    if not exists (select 1 from public.client_enrolments e where e.id = new.enrolment_id and e.client_id = new.client_id and e.scheme = 'support_at_home') then
      raise exception 'Choose the client''s Support at Home program.';
    end if;
    if new.document_id is not null and not exists (select 1 from public.client_documents d where d.id = new.document_id and d.client_id = new.client_id) then
      raise exception 'That document belongs to another client.';
    end if;
  end if;
  if exists (select 1 from public.client_contribution_rates r
              where r.enrolment_id = new.enrolment_id and r.category = new.category and r.id <> new.id
                and r.effective_from <= coalesce(new.effective_to, 'infinity'::date) and coalesce(r.effective_to, 'infinity'::date) >= new.effective_from) then
    raise exception 'Another rate for this category covers some of those dates. End it first.';
  end if;
  return new;
end;
$$;

-- 6. Billing terms for approved services (dated, approved versions).
create table if not exists public.client_service_terms (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id),
  service_id uuid not null references public.client_services (id),
  version integer not null default 1,
  status text not null default 'draft' check (status in ('draft', 'pending_review', 'changes_required', 'approved', 'superseded')),
  effective_from date not null,
  effective_to date,
  enrolment_id uuid not null references public.client_enrolments (id),
  funding_id uuid references public.client_funding (id),
  agreement_id uuid references public.client_agreements (id),
  price_list_id uuid references public.price_lists (id),
  quantity numeric(8, 2) check (quantity is null or quantity between 0 and 10000),
  unit text not null default 'hour' check (unit in ('hour', 'visit', 'each', 'km', 'day')),
  frequency text not null default 'week' check (frequency in ('week', 'fortnight', 'month', 'quarter', 'plan', 'once', 'as_needed')),
  sah_category text check (sah_category in ('clinical', 'independence', 'everyday_living')),
  personal_care boolean not null default false,
  funding_stream text not null default 'ongoing' check (funding_stream in ('ongoing', 'at_hm', 'restorative', 'end_of_life', 'hcp_unspent', 'ndis_plan', 'grant', 'private', 'other')),
  source_support_line_id uuid references public.client_support_plan_lines (id),
  notes text not null default '' check (length(notes) <= 2000),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  submitted_by uuid, submitted_at timestamptz,
  reviewed_by uuid, reviewed_at timestamptz,
  review_note text not null default '' check (length(review_note) <= 1000),
  approved_by uuid, approved_at timestamptz,
  superseded_at timestamptz,
  updated_by uuid,
  updated_at timestamptz not null default now(),
  unique (service_id, version),
  constraint client_service_terms_dates check (effective_to is null or effective_to >= effective_from)
);
create index if not exists client_service_terms_service on public.client_service_terms (service_id, effective_from);

create or replace function public.guard_service_terms() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_api boolean := public.from_portal();
  s public.client_services;
  e public.client_enrolments;
  v_editable text[] := array['effective_from', 'enrolment_id', 'funding_id', 'agreement_id', 'price_list_id', 'quantity', 'unit', 'frequency', 'sah_category', 'personal_care', 'funding_stream', 'source_support_line_id', 'notes'];
  v_steps text[] := array['status', 'effective_to', 'submitted_by', 'submitted_at', 'reviewed_by', 'reviewed_at', 'review_note', 'approved_by', 'approved_at', 'superseded_at', 'updated_by', 'updated_at'];
begin
  if tg_op = 'DELETE' then
    if old.status not in ('draft', 'changes_required') then
      raise exception 'Billing terms that were sent for review are kept.';
    end if;
    return old;
  end if;
  select * into s from public.client_services where id = new.service_id;
  if s.id is null or s.client_id <> new.client_id then
    raise exception 'That service belongs to another client.';
  end if;
  if tg_op = 'INSERT' then
    new.status := 'draft'; new.effective_to := null;
    new.created_by := auth.uid(); new.created_at := now();
    new.submitted_by := null; new.submitted_at := null; new.reviewed_by := null; new.reviewed_at := null; new.review_note := '';
    new.approved_by := null; new.approved_at := null; new.superseded_at := null;
    new.version := coalesce((select max(version) from public.client_service_terms where service_id = new.service_id), 0) + 1;
  else
    if (to_jsonb(new) - v_editable - v_steps) is distinct from (to_jsonb(old) - v_editable - v_steps) then
      raise exception 'Billing terms keep their service, version and maker.';
    end if;
    if old.status not in ('draft', 'changes_required') and (to_jsonb(new) - v_steps) is distinct from (to_jsonb(old) - v_steps) then
      raise exception 'Billing terms can only change while they''re a draft or need changes. Start a new version.';
    end if;
    if old.status = 'superseded' and new is distinct from old then
      raise exception 'Superseded billing terms never change.';
    end if;
  end if;
  -- What the terms point at must belong together.
  select * into e from public.client_enrolments where id = new.enrolment_id;
  if e.id is null or e.client_id <> new.client_id or e.program_id <> s.program_id then
    raise exception 'Choose the client''s enrolment in this service''s program.';
  end if;
  if new.effective_from < s.start_date or (s.end_date is not null and new.effective_from > s.end_date) then
    raise exception 'The terms must start within the service''s dates.';
  end if;
  if new.effective_from < e.starts_on or (e.ends_on is not null and new.effective_from > e.ends_on) then
    raise exception 'The terms must start within the program enrolment''s dates.';
  end if;
  if new.funding_id is not null and not exists (select 1 from public.client_funding f where f.id = new.funding_id and f.client_id = new.client_id and f.scheme = e.scheme and (f.service_id = new.service_id or f.service_id is null)) then
    raise exception 'Choose a funding record of this client, for this service and scheme.';
  end if;
  if new.agreement_id is not null and not exists (select 1 from public.client_agreements a where a.id = new.agreement_id and a.client_id = new.client_id and a.service_id = new.service_id) then
    raise exception 'Choose an agreement for this service.';
  end if;
  if new.price_list_id is not null and not exists (select 1 from public.price_lists p where p.id = new.price_list_id and p.scheme = e.scheme) then
    raise exception 'Choose a price list for this scheme.';
  end if;
  if new.source_support_line_id is not null and not exists (select 1 from public.client_support_plan_lines l where l.id = new.source_support_line_id and l.client_id = new.client_id) then
    raise exception 'That support plan line belongs to another client.';
  end if;
  if e.scheme = 'support_at_home' and new.sah_category is null and new.status <> 'draft' then
    raise exception 'Support at Home terms need the service category.';
  end if;
  if tg_op = 'INSERT' then
    return new;
  end if;
  -- Steps (approval is separate from care plans and funding: the Billing approve right).
  new.approved_by := old.approved_by; new.approved_at := old.approved_at; new.superseded_at := old.superseded_at;
  if new.status is distinct from old.status then
    if new.status = 'pending_review' and old.status in ('draft', 'changes_required') then
      if e.scheme = 'support_at_home' and new.sah_category is null then
        raise exception 'Support at Home terms need the service category.';
      end if;
      new.submitted_by := auth.uid(); new.submitted_at := now(); new.reviewed_by := null; new.reviewed_at := null;
    elsif new.status = 'draft' and old.status = 'pending_review' then
      if v_api and not public.billing_can('prepare', new.client_id) then
        raise exception 'Only someone who can prepare billing can take it back.';
      end if;
    elsif new.status in ('changes_required', 'approved') and old.status = 'pending_review' then
      if v_api and (not public.billing_can('approve', new.client_id) or auth.uid() is not distinct from old.created_by or auth.uid() is not distinct from old.submitted_by) then
        raise exception 'Only someone with the Billing approve right, who didn''t make or submit these terms, can review them.';
      end if;
      if new.status = 'changes_required' and length(trim(new.review_note)) = 0 then
        raise exception 'Say what needs changing.';
      end if;
      new.reviewed_by := auth.uid(); new.reviewed_at := now();
      if new.status = 'approved' then
        new.approved_by := auth.uid(); new.approved_at := now();
        if exists (select 1 from public.client_service_terms t where t.service_id = new.service_id and t.status = 'approved' and t.id <> new.id and t.effective_from >= new.effective_from) then
          raise exception 'Newer approved terms already start on or after this date.';
        end if;
        update public.client_service_terms set status = 'superseded', superseded_at = now(), effective_to = new.effective_from - 1
         where service_id = new.service_id and status = 'approved' and id <> new.id;
      end if;
    elsif new.status = 'superseded' and old.status = 'approved' and pg_trigger_depth() > 1 then
      new.superseded_at := now();
      return new;
    else
      raise exception 'Billing terms go Draft -> Pending review -> Approved (or Changes required). They can''t go from % to %.', old.status, new.status;
    end if;
  elsif new.effective_to is distinct from old.effective_to
     or (new.submitted_by, new.submitted_at, new.reviewed_by, new.reviewed_at) is distinct from (old.submitted_by, old.submitted_at, old.reviewed_by, old.reviewed_at)
     or (new.review_note is distinct from old.review_note and old.status <> 'pending_review') then
    raise exception 'Review details and end dates are set by the review itself.';
  end if;
  return new;
end;
$$;

-- 7. Cancellation details for cancelled shifts.
create table if not exists public.shift_cancellations (
  shift_id uuid primary key references public.shifts (id),
  org_id uuid not null default public.default_org_id(),
  client_id uuid references public.car_clients (id),
  notified_at timestamptz not null,
  cancelled_by text not null check (cancelled_by in ('client', 'representative', 'provider', 'worker', 'other')),
  reason text not null check (length(trim(reason)) between 1 and 1000),
  reasonable_grounds boolean,
  charge text not null default 'undecided' check (charge in ('undecided', 'no_charge', 'charge')),
  charge_note text not null default '' check (length(charge_note) <= 1000),
  decided_by uuid,
  decided_at timestamptz,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now()
);
create or replace function public.guard_shift_cancellation() returns trigger
language plpgsql set search_path = '' as $$
declare
  sh public.shifts;
begin
  if tg_op = 'DELETE' then
    raise exception 'Cancellation details are kept.';
  end if;
  select * into sh from public.shifts where id = new.shift_id;
  if sh.id is null or sh.status <> 'cancelled' then
    raise exception 'Record cancellation details on a cancelled shift.';
  end if;
  new.client_id := sh.client_id;
  if new.notified_at > now() + interval '5 minutes' then
    raise exception 'When they were told can''t be in the future.';
  end if;
  if new.charge <> 'undecided' and length(trim(new.charge_note)) = 0 then
    raise exception 'Say why it is or isn''t charged.';
  end if;
  if new.charge = 'charge' and new.reasonable_grounds is true then
    raise exception 'With reasonable grounds accepted, the client isn''t charged.';
  end if;
  if tg_op = 'INSERT' then
    new.created_by := auth.uid(); new.created_at := now();
  elsif (new.created_by, new.created_at) is distinct from (old.created_by, old.created_at) then
    raise exception 'Who recorded it stays as it was.';
  end if;
  if new.charge = 'undecided' then
    new.decided_by := null; new.decided_at := null;
  elsif tg_op = 'INSERT' or new.charge is distinct from old.charge or new.charge_note is distinct from old.charge_note or new.reasonable_grounds is distinct from old.reasonable_grounds then
    if public.from_portal() and not public.billing_can('approve', new.client_id) then
      raise exception 'Only someone with the Billing approve right decides whether a cancellation is charged.';
    end if;
    new.decided_by := auth.uid(); new.decided_at := now();
  else
    new.decided_by := old.decided_by; new.decided_at := old.decided_at;
  end if;
  return new;
end;
$$;

-- 8. Read and change rules.
alter table public.billing_scheme_rules enable row level security;
alter table public.billing_rule_checks enable row level security;
alter table public.price_lists enable row level security;
alter table public.price_list_versions enable row level security;
alter table public.price_list_bands enable row level security;
alter table public.price_items enable row level security;
alter table public.public_holidays enable row level security;
alter table public.client_contribution_rates enable row level security;
alter table public.client_service_terms enable row level security;
alter table public.shift_cancellations enable row level security;

do $$
declare
  t text;
begin
  -- Set-up: anyone with Billing view reads it; "prices" changes prices and holidays; "approve" confirms rules.
  foreach t in array array['billing_scheme_rules', 'billing_rule_checks', 'price_lists', 'price_list_versions', 'price_list_bands', 'price_items', 'public_holidays'] loop
    execute format('drop policy if exists "billing see %s" on public.%I', t, t);
    execute format('create policy "billing see %s" on public.%I for select to authenticated using (public.billing_can(''view''))', t, t);
    execute format('revoke all on public.%I from anon', t);
  end loop;
  foreach t in array array['price_lists', 'price_list_versions', 'price_list_bands', 'price_items', 'public_holidays'] loop
    execute format('drop policy if exists "billing add %s" on public.%I', t, t);
    execute format('create policy "billing add %s" on public.%I for insert to authenticated with check (public.billing_can(''prices''))', t, t);
    execute format('drop policy if exists "billing change %s" on public.%I', t, t);
    execute format('create policy "billing change %s" on public.%I for update to authenticated using (public.billing_can(''prices'')) with check (public.billing_can(''prices''))', t, t);
    execute format('grant select, insert, update on public.%I to authenticated', t);
  end loop;
  foreach t in array array['price_list_versions', 'price_list_bands', 'price_items'] loop
    execute format('drop policy if exists "billing remove draft %s" on public.%I', t, t);
    execute format('create policy "billing remove draft %s" on public.%I for delete to authenticated using (public.billing_can(''prices''))', t, t);
    execute format('grant delete on public.%I to authenticated', t);
  end loop;
  foreach t in array array['billing_scheme_rules', 'billing_rule_checks'] loop
    execute format('drop policy if exists "billing confirm %s" on public.%I', t, t);
    execute format('create policy "billing confirm %s" on public.%I for update to authenticated using (public.billing_can(''approve'')) with check (public.billing_can(''approve''))', t, t);
    execute format('grant select, update on public.%I to authenticated', t);
  end loop;
  drop policy if exists "billing add checks" on public.billing_rule_checks;
  create policy "billing add checks" on public.billing_rule_checks for insert to authenticated with check (public.billing_can('approve'));
  grant insert on public.billing_rule_checks to authenticated;

  -- Client records: Billing reach for the client.
  foreach t in array array['client_contribution_rates', 'client_service_terms'] loop
    execute format('drop policy if exists "billing see %s" on public.%I', t, t);
    execute format('create policy "billing see %s" on public.%I for select to authenticated using (public.billing_can(''view'', client_id))', t, t);
    execute format('drop policy if exists "billing add %s" on public.%I', t, t);
    execute format('create policy "billing add %s" on public.%I for insert to authenticated with check (public.billing_can(''prepare'', client_id))', t, t);
    execute format('drop policy if exists "billing change %s" on public.%I', t, t);
    execute format('create policy "billing change %s" on public.%I for update to authenticated using (public.billing_can(''prepare'', client_id) or public.billing_can(''approve'', client_id)) with check (public.billing_can(''prepare'', client_id) or public.billing_can(''approve'', client_id))', t, t);
    execute format('grant select, insert, update on public.%I to authenticated', t);
    execute format('revoke all on public.%I from anon', t);
  end loop;
  drop policy if exists "billing remove draft terms" on public.client_service_terms;
  create policy "billing remove draft terms" on public.client_service_terms for delete to authenticated using (public.billing_can('prepare', client_id));
  grant delete on public.client_service_terms to authenticated;

  -- Cancellation details: people who manage the roster, or billing.
  drop policy if exists "see shift cancellations" on public.shift_cancellations;
  create policy "see shift cancellations" on public.shift_cancellations for select to authenticated
    using (public.can('ops.roster', 'edit') or public.billing_can('view', client_id));
  drop policy if exists "add shift cancellations" on public.shift_cancellations;
  create policy "add shift cancellations" on public.shift_cancellations for insert to authenticated
    with check (public.can('ops.roster', 'edit') or public.billing_can('prepare', client_id));
  drop policy if exists "change shift cancellations" on public.shift_cancellations;
  create policy "change shift cancellations" on public.shift_cancellations for update to authenticated
    using (public.can('ops.roster', 'edit') or public.billing_can('prepare', client_id) or public.billing_can('approve', client_id))
    with check (public.can('ops.roster', 'edit') or public.billing_can('prepare', client_id) or public.billing_can('approve', client_id));
  grant select, insert, update on public.shift_cancellations to authenticated;
  revoke all on public.shift_cancellations from anon;
end $$;

-- The change log also records removals (draft prices, bands and versions).
-- Same function as before for additions and changes; removals are new.
create or replace function public.log_car_setup() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'DELETE' then
    perform public.write_audit('removed_' || tg_argv[0], tg_argv[0], old.id::text, to_jsonb(old));
    return old;
  end if;
  perform public.write_audit(
    case when tg_op = 'INSERT' then 'added' else 'changed' end || '_' || tg_argv[0],
    tg_argv[0], new.id::text,
    case when tg_op = 'INSERT' then to_jsonb(new) else jsonb_build_object('before', to_jsonb(old), 'after', to_jsonb(new)) end);
  return new;
end;
$$;

-- Who changed set-up records last, and when.
create or replace function public.stamp_billing_updated() returns trigger
language plpgsql set search_path = '' as $$
begin
  new := jsonb_populate_record(new, jsonb_build_object('updated_at', now(), 'updated_by', auth.uid()));
  return new;
end;
$$;
revoke execute on function public.stamp_billing_updated() from public, anon, authenticated;

-- 9. Triggers: checks, then the change log (set-up) or client audit trail (client records).
do $$
declare
  t text;
begin
  drop trigger if exists guard_billing_rules on public.billing_scheme_rules;
  create trigger guard_billing_rules before insert or update or delete on public.billing_scheme_rules for each row execute function public.guard_billing_rules();
  drop trigger if exists guard_billing_rules on public.billing_rule_checks;
  create trigger guard_billing_rules before insert or update or delete on public.billing_rule_checks for each row execute function public.guard_billing_rules();
  drop trigger if exists guard_billing_check_scheme on public.billing_rule_checks;
  create trigger guard_billing_check_scheme before insert or update on public.billing_rule_checks for each row execute function public.guard_billing_check_scheme();
  drop trigger if exists guard_price_list on public.price_lists;
  create trigger guard_price_list before insert or update or delete on public.price_lists for each row execute function public.guard_price_list();
  drop trigger if exists guard_price_version on public.price_list_versions;
  create trigger guard_price_version before insert or update or delete on public.price_list_versions for each row execute function public.guard_price_version();
  drop trigger if exists guard_price_part on public.price_list_bands;
  create trigger guard_price_part before insert or update or delete on public.price_list_bands for each row execute function public.guard_price_part();
  drop trigger if exists guard_price_part on public.price_items;
  create trigger guard_price_part before insert or update or delete on public.price_items for each row execute function public.guard_price_part();
  drop trigger if exists guard_public_holiday on public.public_holidays;
  create trigger guard_public_holiday before insert or update or delete on public.public_holidays for each row execute function public.guard_public_holiday();
  drop trigger if exists guard_contribution_rate on public.client_contribution_rates;
  create trigger guard_contribution_rate before insert or update or delete on public.client_contribution_rates for each row execute function public.guard_contribution_rate();
  drop trigger if exists guard_service_terms on public.client_service_terms;
  create trigger guard_service_terms before insert or update or delete on public.client_service_terms for each row execute function public.guard_service_terms();
  drop trigger if exists guard_shift_cancellation on public.shift_cancellations;
  create trigger guard_shift_cancellation before insert or update or delete on public.shift_cancellations for each row execute function public.guard_shift_cancellation();

  foreach t in array array['billing_scheme_rules:billing_scheme_rule', 'billing_rule_checks:billing_rule_check', 'price_lists:price_list', 'price_list_versions:price_list_version',
                           'price_list_bands:price_list_band', 'price_items:price_item', 'public_holidays:public_holiday'] loop
    execute format('drop trigger if exists log_billing_setup on public.%I', split_part(t, ':', 1));
    execute format('create trigger log_billing_setup after insert or update or delete on public.%I for each row execute function public.log_car_setup(%L)', split_part(t, ':', 1), split_part(t, ':', 2));
    execute format('drop trigger if exists stamp_billing_setup on public.%I', split_part(t, ':', 1));
    execute format('create trigger stamp_billing_setup before insert or update on public.%I for each row execute function public.stamp_billing_updated()', split_part(t, ':', 1));
  end loop;
  foreach t in array array['client_contribution_rates', 'client_service_terms', 'shift_cancellations'] loop
    execute format('drop trigger if exists log_client_change on public.%I', t);
    execute format('create trigger log_client_change before insert or update on public.%I for each row execute function public.log_client_change()', t);
    execute format('drop trigger if exists log_client_audit on public.%I', t);
    execute format('create trigger log_client_audit after insert or update or delete on public.%I for each row execute function public.log_client_change()', t);
  end loop;
end $$;

revoke execute on function public.guard_billing_rules() from public, anon, authenticated;
revoke execute on function public.guard_billing_check_scheme() from public, anon, authenticated;
revoke execute on function public.guard_price_list() from public, anon, authenticated;
revoke execute on function public.guard_price_version() from public, anon, authenticated;
revoke execute on function public.guard_price_part() from public, anon, authenticated;
revoke execute on function public.guard_public_holiday() from public, anon, authenticated;
revoke execute on function public.guard_contribution_rate() from public, anon, authenticated;
revoke execute on function public.guard_service_terms() from public, anon, authenticated;
revoke execute on function public.guard_shift_cancellation() from public, anon, authenticated;
