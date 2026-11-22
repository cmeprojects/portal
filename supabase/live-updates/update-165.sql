-- Staff Portal · © cmeproject. All rights reserved.
-- Update 165: suppliers and their invoices, client charges with markup, Support at Home pathway
-- budgets (AT-HM, Restorative Care, End-of-Life, unspent HCP funds) and charges in claims,
-- invoices and statements (Phase 5C). Nothing is charged by this update. Safe to run again.
-- Undo: undo-165.sql.
begin;
insert into public.billing_rule_checks (scheme, item)
select v.scheme, v.item from (values
  ('support_at_home', 'Assistive Technology and Home Modifications (AT-HM): funding tiers, approval and the period to use the funds'),
  ('support_at_home', 'Restorative Care Pathway: amount, duration and what it covers'),
  ('support_at_home', 'End-of-Life Pathway: amount, duration and eligibility'),
  ('support_at_home', 'Unspent Home Care Package funds: order of use with the quarterly budget, and what happens to the remainder'),
  ('support_at_home', 'Third-party (subcontracted) services: how they are priced and any administration or markup charge'),
  ('support_at_home', 'Participant contributions on AT-HM and pathway services'),
  ('ndis', 'Third-party supports: claimed at no more than the price limit (no markup above it)')
) v(scheme, item)
 where not exists (select 1 from public.billing_scheme_rules r where r.scheme = v.scheme and r.status = 'confirmed')
on conflict (scheme, item) do nothing;

create table if not exists public.suppliers (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  name text not null check (length(trim(name)) between 1 and 200),
  kind text not null default 'subcontractor' check (kind in ('subcontractor', 'equipment', 'home_modifications', 'other')),
  abn text not null default '' check (abn = '' or public.abn_valid(abn)),
  gst_registered boolean not null default false,
  email text not null default '' check (email = '' or email ~ '^[^\s@]+@[^\s@]+\.[^\s@]+$'),
  phone text not null default '' check (length(phone) <= 30),
  address text not null default '' check (length(address) <= 400),
  payment_bsb text not null default '' check (payment_bsb = '' or payment_bsb ~ '^\d{3}-?\d{3}$'),
  payment_account_number text not null default '' check (payment_account_number = '' or payment_account_number ~ '^\d{5,10}$'),
  payment_account_name text not null default '' check (length(payment_account_name) <= 120),
  active boolean not null default true,
  notes text not null default '' check (length(notes) <= 1000),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now()
);
create table if not exists public.supplier_invoices (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  supplier_id uuid not null references public.suppliers (id),
  supplier_ref text not null check (length(trim(supplier_ref)) between 1 and 60),
  invoice_date date not null,
  due_date date,
  total numeric(12, 2) not null default 0,
  gst numeric(12, 2) not null default 0,
  status text not null default 'received' check (status in ('received', 'approved', 'paid', 'rejected')),
  document_note text not null default '' check (length(document_note) <= 500),
  recorded_by uuid default auth.uid(),
  recorded_at timestamptz not null default now(),
  approved_by uuid, approved_at timestamptz,
  paid_on date, paid_reference text not null default '' check (length(paid_reference) <= 120), paid_by uuid,
  rejected_by uuid, rejected_at timestamptz, reject_reason text not null default '' check (length(reject_reason) <= 500),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  unique (supplier_id, supplier_ref)
);
create table if not exists public.supplier_invoice_lines (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  supplier_invoice_id uuid not null references public.supplier_invoices (id),
  description text not null check (length(trim(description)) between 1 and 300),
  client_id uuid references public.car_clients (id),
  service_date date,
  amount numeric(12, 2) not null check (amount >= 0),
  gst_amount numeric(12, 2) not null default 0 check (gst_amount >= 0),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now()
);

create table if not exists public.billing_markup_rules (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  funding_stream text not null check (funding_stream in ('all', 'ongoing', 'at_hm', 'restorative', 'end_of_life', 'hcp_unspent', 'ndis_plan', 'private')),
  markup_pct numeric(6, 2) not null check (markup_pct between 0 and 100),
  max_markup numeric(12, 2) check (max_markup is null or max_markup >= 0),
  effective_from date not null,
  note text not null default '' check (length(note) <= 500),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  unique (funding_stream, effective_from)
);
create table if not exists public.client_pathway_budgets (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id),
  enrolment_id uuid not null references public.client_enrolments (id),
  stream text not null check (stream in ('at_hm', 'restorative', 'end_of_life', 'hcp_unspent')),
  detail text not null default '' check (length(detail) <= 200),
  amount numeric(12, 2) not null check (amount > 0),
  starts_on date not null,
  ends_on date not null,
  source text not null check (length(trim(source)) between 1 and 500),
  status text not null default 'draft' check (status in ('draft', 'approved', 'closed')),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  approved_by uuid, approved_at timestamptz,
  closed_by uuid, closed_at timestamptz, close_note text not null default '' check (length(close_note) <= 500),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  constraint client_pathway_budgets_dates check (ends_on >= starts_on)
);

create table if not exists public.client_charges (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id),
  scheme text not null check (scheme in ('support_at_home', 'ndis', 'private')),
  enrolment_id uuid references public.client_enrolments (id),
  funding_stream text not null check (funding_stream in ('ongoing', 'at_hm', 'restorative', 'end_of_life', 'hcp_unspent', 'ndis_plan', 'private')),
  quarter_budget_id uuid references public.client_quarter_budgets (id),
  pathway_budget_id uuid references public.client_pathway_budgets (id),
  funding_id uuid references public.client_funding (id),
  location_id uuid references public.client_locations (id),
  supplier_line_id uuid references public.supplier_invoice_lines (id),
  description text not null check (length(trim(description)) between 1 and 300),
  service_date date not null,
  sah_category text check (sah_category in ('clinical', 'independence', 'everyday_living')),
  ndis_item text not null default '' check (length(ndis_item) <= 40),
  cost numeric(12, 2) not null default 0 check (cost >= 0),
  markup_pct numeric(6, 2) not null default 0 check (markup_pct between 0 and 100),
  markup_amount numeric(12, 2) not null default 0,
  markup_note text not null default '' check (length(markup_note) <= 500),
  amount numeric(12, 2) not null check (amount > 0),
  gst_code text not null default 'gst_free' check (gst_code in ('gst_free', 'taxable', 'input_taxed')),
  contribution_pct numeric(6, 2),
  client_share numeric(12, 2),
  government_share numeric(12, 2),
  over_budget boolean not null default false,
  approve_note text not null default '' check (length(approve_note) <= 1000),
  status text not null default 'draft' check (status in ('draft', 'approved', 'voided')),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  approved_by uuid, approved_at timestamptz,
  voided_by uuid, voided_at timestamptz, void_reason text not null default '' check (length(void_reason) <= 500),
  updated_by uuid,
  updated_at timestamptz not null default now()
);
create unique index if not exists client_charges_one_per_supplier_line on public.client_charges (supplier_line_id) where status <> 'voided' and supplier_line_id is not null;
alter table public.funding_ledger add column if not exists client_charge_id uuid references public.client_charges (id);

create or replace view public.pathway_balances with (security_invoker = true) as
  select b.id as pathway_budget_id, b.client_id, b.stream, b.amount, b.status, b.starts_on, b.ends_on,
         coalesce((select sum(c.amount) from public.client_charges c where c.pathway_budget_id = b.id and c.status = 'approved'), 0) as used,
         b.amount - coalesce((select sum(c.amount) from public.client_charges c where c.pathway_budget_id = b.id and c.status = 'approved'), 0) as available
    from public.client_pathway_budgets b where b.status <> 'draft';

alter table public.line_recoveries alter column line_id drop not null;
alter table public.line_recoveries add column if not exists charge_id uuid references public.client_charges (id);
alter table public.line_recoveries drop constraint if exists line_recoveries_source;
alter table public.line_recoveries add constraint line_recoveries_source check ((line_id is null) <> (charge_id is null));
create unique index if not exists line_recoveries_charge_role on public.line_recoveries (charge_id, payer_role) where charge_id is not null;
alter table public.claim_items add column if not exists charge_id uuid references public.client_charges (id);
alter table public.claim_items drop constraint if exists claim_items_source;
alter table public.claim_items add constraint claim_items_source check (
  (replaces_item_id is null and (
     (line_id is not null and recovery_id is not null and quarter_budget_id is null and charge_id is null)
     or (line_id is null and recovery_id is null and quarter_budget_id is not null and charge_id is null)
     or (charge_id is not null and recovery_id is not null and line_id is null and quarter_budget_id is null)))
  or (replaces_item_id is not null and recovery_id is null and ((line_id is not null)::int + (quarter_budget_id is not null)::int + (charge_id is not null)::int) = 1));
alter table public.invoice_items alter column line_id drop not null;
alter table public.invoice_items add column if not exists charge_id uuid references public.client_charges (id);
alter table public.invoice_items drop constraint if exists invoice_items_source;
alter table public.invoice_items add constraint invoice_items_source check ((line_id is null) <> (charge_id is null));

create or replace function public.guard_supplier_invoice() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_api boolean := public.from_portal();
begin
  if tg_op = 'DELETE' then raise exception 'Supplier invoices are never deleted. Reject one instead.'; end if;
  if tg_op = 'INSERT' then
    if v_api and not public.billing_can('prepare') then raise exception 'Only someone with the Billing prepare right records supplier invoices.'; end if;
    new.status := 'received'; new.recorded_by := auth.uid(); new.recorded_at := now(); new.total := 0; new.gst := 0;
    new.approved_by := null; new.paid_on := null;
    if new.invoice_date > (now() at time zone 'Australia/Sydney')::date then raise exception 'The invoice date can''t be in the future.'; end if;
    return new;
  end if;
  if (new.supplier_id, new.supplier_ref, new.invoice_date, new.recorded_by, new.recorded_at) is distinct from (old.supplier_id, old.supplier_ref, old.invoice_date, old.recorded_by, old.recorded_at) then
    raise exception 'A supplier invoice keeps its supplier, number and date. Reject it and record it again.';
  end if;
  new.total := coalesce((select sum(amount + gst_amount) from public.supplier_invoice_lines where supplier_invoice_id = new.id), 0);
  new.gst := coalesce((select sum(gst_amount) from public.supplier_invoice_lines where supplier_invoice_id = new.id), 0);
  new.approved_by := old.approved_by; new.approved_at := old.approved_at;
  if old.status in ('paid', 'rejected') and (to_jsonb(new) - array['updated_by', 'updated_at']) is distinct from (to_jsonb(old) - array['updated_by', 'updated_at']) then
    raise exception 'A paid or rejected supplier invoice never changes.';
  end if;
  if new.status is distinct from old.status then
    if old.status = 'received' and new.status = 'approved' then
      if v_api and (not public.billing_can('approve') or auth.uid() is not distinct from old.recorded_by) then raise exception 'Only someone with the Billing approve right, who didn''t record it, approves a supplier invoice.'; end if;
      if new.total <= 0 then raise exception 'The supplier invoice has no lines.'; end if;
      new.approved_by := auth.uid(); new.approved_at := now();
    elsif old.status = 'approved' and new.status = 'paid' then
      if v_api and not (public.billing_can('payment_record') or public.billing_can('approve')) then raise exception 'Only someone with the payment right records supplier payments.'; end if;
      if new.paid_on is null or length(trim(new.paid_reference)) = 0 then raise exception 'Record the date paid and the payment reference.'; end if;
      if new.paid_on > (now() at time zone 'Australia/Sydney')::date then raise exception 'The date paid can''t be in the future.'; end if;
      new.paid_by := auth.uid();
    elsif old.status in ('received', 'approved') and new.status = 'rejected' then
      if v_api and not public.billing_can('approve') then raise exception 'Only someone with the Billing approve right rejects supplier invoices.'; end if;
      if length(trim(new.reject_reason)) = 0 then raise exception 'Say why it''s rejected.'; end if;
      if exists (select 1 from public.client_charges c join public.supplier_invoice_lines l on l.id = c.supplier_line_id where l.supplier_invoice_id = old.id and c.status <> 'voided') then
        raise exception 'A client charge is made from this invoice. Void it first.';
      end if;
      new.rejected_by := auth.uid(); new.rejected_at := now();
    else
      raise exception 'A supplier invoice goes Received -> Approved -> Paid, or is rejected before it''s paid.';
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.guard_supplier_line() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_status text := (select status from public.supplier_invoices where id = case when tg_op = 'DELETE' then old.supplier_invoice_id else new.supplier_invoice_id end);
begin
  if v_status <> 'received' then raise exception 'Only a received (not yet approved) supplier invoice''s lines change.'; end if;
  if public.from_portal() and not public.billing_can('prepare') then raise exception 'Only someone with the Billing prepare right records supplier invoices.'; end if;
  if tg_op = 'DELETE' then
    if exists (select 1 from public.client_charges c where c.supplier_line_id = old.id and c.status <> 'voided') then raise exception 'A client charge is made from this line.'; end if;
    return old;
  end if;
  if tg_op = 'UPDATE' and exists (select 1 from public.client_charges c where c.supplier_line_id = old.id and c.status <> 'voided') then raise exception 'A client charge is made from this line.'; end if;
  if (select gst_registered from public.suppliers s join public.supplier_invoices i on i.supplier_id = s.id where i.id = new.supplier_invoice_id) = false and new.gst_amount <> 0 then
    raise exception 'This supplier isn''t registered for GST, so its invoice has no GST.';
  end if;
  return new;
end;
$$;
create or replace function public.supplier_invoice_totals() returns trigger
language plpgsql set search_path = '' as $$
begin
  update public.supplier_invoices set updated_at = now() where id = case when tg_op = 'DELETE' then old.supplier_invoice_id else new.supplier_invoice_id end and status = 'received';
  return null;
end;
$$;

create or replace function public.guard_markup_rule() returns trigger
language plpgsql set search_path = '' as $$
begin
  if public.from_portal() and not public.billing_can('prices') then raise exception 'Only someone with the Billing prices right changes markup rules.'; end if;
  if tg_op = 'DELETE' then
    if exists (select 1 from public.client_charges c where c.status <> 'voided' and c.created_at >= old.created_at) then raise exception 'A markup rule that has been used is never deleted. Add a new one from a later date.'; end if;
    return old;
  end if;
  if tg_op = 'UPDATE' and (new.funding_stream, new.markup_pct, new.max_markup, new.effective_from) is distinct from (old.funding_stream, old.markup_pct, old.max_markup, old.effective_from) then
    raise exception 'A markup rule never changes. Add a new one from a later date.';
  end if;
  return new;
end;
$$;
create or replace function public.billing_markup_for(p_stream text, p_on date) returns public.billing_markup_rules
language sql stable set search_path = '' as $$
  select r.* from public.billing_markup_rules r where r.funding_stream in (p_stream, 'all') and r.effective_from <= p_on
   order by (r.funding_stream = p_stream) desc, r.effective_from desc limit 1
$$;

create or replace function public.guard_pathway_budget() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_api boolean := public.from_portal();
begin
  if tg_op = 'DELETE' then
    if old.status <> 'draft' then raise exception 'An approved pathway budget is never deleted.'; end if;
    return old;
  end if;
  if tg_op = 'INSERT' then
    if v_api and not public.billing_can('prepare', new.client_id) then raise exception 'Only someone with the Billing prepare right adds pathway budgets.'; end if;
    if not exists (select 1 from public.client_enrolments e where e.id = new.enrolment_id and e.client_id = new.client_id and e.scheme = 'support_at_home') then
      raise exception 'Pathway budgets are for a client''s Support at Home program.';
    end if;
    new.status := 'draft'; new.created_by := auth.uid(); new.created_at := now(); new.approved_by := null;
    return new;
  end if;
  if old.status = 'draft' and new.status = 'draft' then return new; end if;
  if (new.client_id, new.enrolment_id, new.stream, new.amount, new.starts_on, new.ends_on, new.source, new.created_by) is distinct from (old.client_id, old.enrolment_id, old.stream, old.amount, old.starts_on, old.ends_on, old.source, old.created_by) then
    raise exception 'An approved pathway budget never changes. Close it and add a new one.';
  end if;
  new.approved_by := old.approved_by; new.approved_at := old.approved_at;
  if new.status is distinct from old.status then
    if old.status = 'draft' and new.status = 'approved' then
      if v_api and (not public.billing_can('approve', old.client_id) or auth.uid() is not distinct from old.created_by) then raise exception 'Only someone with the Billing approve right, who didn''t add it, approves a pathway budget.'; end if;
      new.approved_by := auth.uid(); new.approved_at := now();
    elsif old.status = 'approved' and new.status = 'closed' then
      if v_api and not public.billing_can('approve', old.client_id) then raise exception 'Only someone with the Billing approve right closes a pathway budget.'; end if;
      if length(trim(new.close_note)) = 0 then raise exception 'Say why it''s closed (for example, period ended or pathway finished).'; end if;
      new.closed_by := auth.uid(); new.closed_at := now();
    else
      raise exception 'A pathway budget goes Draft -> Approved -> Closed.';
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.client_charge_locked(p_charge uuid) returns boolean
language sql stable set search_path = '' as $$
  select exists (select 1 from public.claim_items i join public.claims c on c.id = i.claim_id
                  where i.charge_id = p_charge and i.status = 'live' and c.status <> 'cancelled'
                    and (c.status in ('draft', 'approved') or coalesce((select o.outcome from public.claim_item_outcomes o where o.claim_item_id = i.id), 'pending') <> 'rejected'))
      or exists (select 1 from public.invoice_items i join public.invoices v on v.id = i.invoice_id
                  where i.charge_id = p_charge and i.status = 'live' and v.status <> 'cancelled'
                    and i.amount > coalesce((select sum(ci.amount) from public.credit_note_items ci join public.credit_notes n on n.id = ci.credit_note_id where ci.invoice_item_id = i.id and n.status = 'issued'), 0))
$$;

create or replace function public.guard_client_charge() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_api boolean := public.from_portal();
  l public.supplier_invoice_lines;
  r public.billing_markup_rules;
  v_ready text;
  v_rate record;
  v_avail numeric;
  v_scheme text;
begin
  if tg_op = 'DELETE' then raise exception 'Charges are never deleted. Void one with a reason.'; end if;
  if tg_op = 'INSERT' then
    if v_api and not public.billing_can('prepare', new.client_id) then raise exception 'Only someone with the Billing prepare right makes client charges.'; end if;
    new.status := 'draft'; new.created_by := auth.uid(); new.created_at := now(); new.approved_by := null;
    -- Scheme and funding stream fit together; the funding account is the client's.
    if (new.scheme = 'support_at_home') <> (new.funding_stream in ('ongoing', 'at_hm', 'restorative', 'end_of_life', 'hcp_unspent'))
       or (new.scheme = 'ndis') <> (new.funding_stream = 'ndis_plan') or (new.scheme = 'private') <> (new.funding_stream = 'private') then
      raise exception 'Choose a funding stream for the scheme.';
    end if;
    v_ready := public.billing_scheme_ready(new.scheme);
    if v_ready is not null then raise exception '%', v_ready; end if;
    if new.scheme <> 'private' and new.scheme <> 'ndis' and not exists (select 1 from public.client_enrolments e where e.id = new.enrolment_id and e.client_id = new.client_id and e.scheme = new.scheme) then
      raise exception 'Choose the client''s program for this scheme.';
    end if;
    -- From a supplier line: the cost and the client come from it; the markup from the rule unless a reason is given.
    if new.supplier_line_id is not null then
      select * into l from public.supplier_invoice_lines where id = new.supplier_line_id;
      if (select status from public.supplier_invoices where id = l.supplier_invoice_id) not in ('approved', 'paid') then raise exception 'Approve the supplier invoice first.'; end if;
      if l.client_id is distinct from new.client_id then raise exception 'That supplier invoice line is for another client.'; end if;
      new.cost := l.amount + case when (select gst_registered from public.business_current) then 0 else l.gst_amount end;
      new.service_date := coalesce(l.service_date, new.service_date);
      r := public.billing_markup_for(new.funding_stream, new.service_date);
      if new.markup_pct is distinct from coalesce(r.markup_pct, 0) and length(trim(new.markup_note)) = 0 then
        raise exception 'The markup rule for this stream is % per cent. Say why this charge is different.', coalesce(r.markup_pct, 0);
      end if;
      new.markup_amount := round(new.cost * new.markup_pct / 100, 2);
      if r.max_markup is not null and new.markup_amount > r.max_markup and new.markup_pct = r.markup_pct then new.markup_amount := r.max_markup; end if;
      new.amount := new.cost + new.markup_amount;
    else
      new.markup_pct := 0; new.markup_amount := 0;
      if new.cost = 0 then new.cost := new.amount; end if;
    end if;
    if new.amount <= 0 then raise exception 'A charge is more than $0.'; end if;
    -- Funding account by stream.
    new.quarter_budget_id := null; new.pathway_budget_id := case when new.funding_stream in ('at_hm', 'restorative', 'end_of_life', 'hcp_unspent') then new.pathway_budget_id end;
    if new.funding_stream = 'ongoing' then
      select id into new.quarter_budget_id from public.client_quarter_budgets q where q.enrolment_id = new.enrolment_id and q.status = 'approved'
         and q.quarter_start <= new.service_date and q.quarter_end >= new.service_date;
      if new.quarter_budget_id is null then raise exception 'No approved quarter budget covers that date.'; end if;
    elsif new.funding_stream in ('at_hm', 'restorative', 'end_of_life', 'hcp_unspent') then
      if not exists (select 1 from public.client_pathway_budgets b where b.id = new.pathway_budget_id and b.client_id = new.client_id and b.stream = new.funding_stream
                       and b.status = 'approved' and b.starts_on <= new.service_date and b.ends_on >= new.service_date) then
        raise exception 'Choose the client''s approved % budget covering that date.', case new.funding_stream when 'at_hm' then 'AT-HM' when 'restorative' then 'Restorative Care' when 'end_of_life' then 'End-of-Life' else 'unspent HCP funds' end;
      end if;
    elsif new.funding_stream = 'ndis_plan' then
      if not exists (select 1 from public.client_funding f where f.id = new.funding_id and f.client_id = new.client_id and f.scheme = 'ndis'
                       and f.period_start <= new.service_date and f.period_end >= new.service_date) then
        raise exception 'Choose the client''s NDIS plan covering that date.';
      end if;
      if new.ndis_item = '' then raise exception 'Record the NDIS support item number.'; end if;
    end if;
    -- Contributions (Support at Home): the client's rate for the category; clinical care has none.
    if new.scheme = 'support_at_home' then
      if new.sah_category is null then raise exception 'Choose the Support at Home category.'; end if;
      if new.sah_category = 'clinical' then
        new.contribution_pct := 0;
      else
        select x.rate_pct into v_rate from public.client_contribution_rates x
         where x.enrolment_id = new.enrolment_id and x.category = new.sah_category and x.effective_from <= new.service_date and (x.effective_to is null or x.effective_to >= new.service_date)
         order by x.effective_from desc limit 1;
        if v_rate is null then raise exception 'No contribution rate recorded for the % category on that date.', new.sah_category; end if;
        new.contribution_pct := v_rate.rate_pct;
      end if;
      new.client_share := round(new.amount * new.contribution_pct / 100, 2);
      new.government_share := new.amount - new.client_share;
    elsif new.scheme = 'ndis' then
      new.contribution_pct := null; new.client_share := 0; new.government_share := new.amount;
    else
      new.contribution_pct := null; new.client_share := new.amount; new.government_share := 0;
    end if;
    -- Over budget?
    if new.quarter_budget_id is not null then
      select available into v_avail from public.funding_balances where account_kind = 'quarter_budget' and account_id = new.quarter_budget_id;
    elsif new.pathway_budget_id is not null then
      select available into v_avail from public.pathway_balances where pathway_budget_id = new.pathway_budget_id;
    elsif new.funding_id is not null then
      select available into v_avail from public.funding_balances where account_kind = 'funding' and account_id = new.funding_id;
    end if;
    new.over_budget := v_avail is not null and v_avail < new.amount;
    return new;
  end if;
  if (to_jsonb(new) - array['status', 'approved_by', 'approved_at', 'approve_note', 'voided_by', 'voided_at', 'void_reason', 'updated_by', 'updated_at'])
     is distinct from (to_jsonb(old) - array['status', 'approved_by', 'approved_at', 'approve_note', 'voided_by', 'voided_at', 'void_reason', 'updated_by', 'updated_at']) then
    raise exception 'A charge never changes. Void it and make it again.';
  end if;
  new.approved_by := old.approved_by; new.approved_at := old.approved_at;
  if new.status is distinct from old.status then
    if old.status = 'draft' and new.status = 'approved' then
      if v_api and (not public.billing_can('approve', old.client_id) or auth.uid() is not distinct from old.created_by) then raise exception 'Only someone with the Billing approve right, who didn''t make it, approves a charge.'; end if;
      if public.billing_review_lapsed(old.scheme) then raise exception 'Billing for this scheme is paused: a verified rule or figure is past its review date.'; end if;
      if old.pathway_budget_id is not null then
        select available into v_avail from public.pathway_balances where pathway_budget_id = old.pathway_budget_id;
        if old.amount > v_avail and length(trim(new.approve_note)) = 0 then raise exception 'This is over what''s left of the pathway budget (%). Say how it''s covered.', v_avail; end if;
      elsif old.over_budget and length(trim(new.approve_note)) = 0 then
        raise exception 'This charge is over the available budget. Say how it''s covered.';
      end if;
      new.approved_by := auth.uid(); new.approved_at := now();
    elsif old.status in ('draft', 'approved') and new.status = 'voided' then
      if v_api and not (public.billing_can('approve', old.client_id) or (old.status = 'draft' and public.billing_can('prepare', old.client_id))) then raise exception 'You can''t void this charge.'; end if;
      if length(trim(new.void_reason)) = 0 then raise exception 'Say why the charge is voided.'; end if;
      if old.status = 'approved' and public.client_charge_locked(old.id) then raise exception 'This charge is in a claim or invoice. Correct it there first.'; end if;
      new.voided_by := auth.uid(); new.voided_at := now();
    else
      raise exception 'A charge goes Draft -> Approved, or is voided.';
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.ledger_from_charge() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.status = 'approved' and old.status = 'draft' and (new.quarter_budget_id is not null or new.funding_id is not null) then
    insert into public.funding_ledger (client_id, quarter_budget_id, funding_id, entry_kind, amount, entry_date, reason, client_charge_id)
    values (new.client_id, new.quarter_budget_id, case when new.quarter_budget_id is null then new.funding_id end, 'charge', -new.amount, new.service_date, 'Charge: ' || new.description, new.id);
  elsif new.status = 'voided' and old.status = 'approved' and (new.quarter_budget_id is not null or new.funding_id is not null) then
    insert into public.funding_ledger (client_id, quarter_budget_id, funding_id, entry_kind, amount, entry_date, reason, client_charge_id)
    values (new.client_id, new.quarter_budget_id, case when new.quarter_budget_id is null then new.funding_id end, 'reversal', new.amount, new.service_date, 'Charge voided: ' || new.void_reason, new.id);
  end if;
  return null;
end;
$$;

create or replace function public.guard_line_recovery() returns trigger
language plpgsql set search_path = '' as $$
declare
  l public.billing_lines;
  c public.client_charges;
  v_value numeric;
begin
  if tg_op <> 'INSERT' then
    raise exception 'A recovery never changes.';
  end if;
  if public.from_portal() and coalesce(current_setting('portal.billing_prepare', true), '') <> 'on' then
    raise exception 'Recoveries are made when claims or invoices are prepared.';
  end if;
  if new.charge_id is not null then
    select * into c from public.client_charges where id = new.charge_id;
    if c.status <> 'approved' then raise exception 'Only approved charges are recovered.'; end if;
    new.client_id := c.client_id; v_value := c.amount;
    if new.amount + coalesce((select sum(r.amount) from public.line_recoveries r where r.charge_id = new.charge_id), 0) > v_value then
      raise exception 'That would recover more than the charge''s value.';
    end if;
  else
    select * into l from public.billing_lines where id = new.line_id;
    if l.status <> 'approved' then
      raise exception 'Only approved billing lines are recovered.';
    end if;
    new.client_id := l.client_id; v_value := l.amount;
    if new.amount + coalesce((select sum(r.amount) from public.line_recoveries r where r.line_id = new.line_id), 0) > v_value then
      raise exception 'That would recover more than the billing line''s value.';
    end if;
  end if;
  new.service_value := v_value;
  new.created_by := auth.uid(); new.created_at := now();
  return new;
end;
$$;

create or replace function public.guard_claim_item() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_status text;
  o public.claim_items;
begin
  select status into v_status from public.claims where id = case when tg_op = 'DELETE' then old.claim_id else new.claim_id end;
  if tg_op = 'DELETE' then raise exception 'Claim lines are never deleted. Remove them from a draft.'; end if;
  if v_status <> 'draft' then raise exception 'Only a draft claim''s lines change.'; end if;
  if tg_op = 'INSERT' then
    if public.from_portal() and coalesce(current_setting('portal.billing_prepare', true), '') <> 'on' then
      raise exception 'Claim lines are added by "Prepare claim".';
    end if;
    if new.replaces_item_id is not null then
      select * into o from public.claim_items where id = new.replaces_item_id;
      if (select outcome from public.claim_item_outcomes where claim_item_id = o.id) is distinct from 'rejected' then
        raise exception 'Only a fully rejected claim line is claimed again. Accepted amounts are never claimed twice.';
      end if;
      if (new.line_id, new.quarter_budget_id, new.charge_id, new.client_id) is distinct from (o.line_id, o.quarter_budget_id, o.charge_id, o.client_id) then
        raise exception 'A replacement line is for the same service as the line it replaces.';
      end if;
      if exists (select 1 from public.claim_items x join public.claims c on c.id = x.claim_id where x.replaces_item_id = o.id and x.status = 'live' and c.status <> 'cancelled') then
        raise exception 'That line is already in a replacement claim.';
      end if;
      if o.line_id is not null and (select status from public.billing_lines where id = o.line_id) <> 'approved' then
        raise exception 'That billing line was voided. Claim its corrected line instead.';
      end if;
      if o.charge_id is not null and (select status from public.client_charges where id = o.charge_id) <> 'approved' then
        raise exception 'That charge was voided.';
      end if;
      return new;
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

create or replace function public.claim_resubmit(p_claim uuid) returns jsonb
language plpgsql set search_path = '' as $$
declare
  c public.claims;
  v_new uuid;
  v_ready text;
  v_tpl uuid;
  v_n integer := 0;
  i record;
begin
  if public.from_portal() and not public.billing_can('claim_prepare') then raise exception 'Only someone with the claim prepare right prepares claims.'; end if;
  select * into c from public.claims where id = p_claim;
  if c.status not in ('submitted', 'acknowledged') then raise exception 'Only a submitted claim''s rejected lines are claimed again.'; end if;
  v_ready := public.billing_scheme_ready(c.program);
  if v_ready is not null then raise exception '%', v_ready; end if;
  select id into v_tpl from public.claim_templates where program = c.program and status = 'verified'
     and (review_by is null or review_by >= (now() at time zone 'Australia/Sydney')::date) order by version desc limit 1;
  if v_tpl is null then raise exception 'This program''s official claim template isn''t verified (or is past its review date).'; end if;
  perform set_config('portal.billing_prepare', 'on', true);
  for i in select x.* from public.claim_items x join public.claim_item_outcomes o on o.claim_item_id = x.id
            where x.claim_id = p_claim and x.status = 'live' and o.outcome = 'rejected'
              and not exists (select 1 from public.claim_items y join public.claims z on z.id = y.claim_id where y.replaces_item_id = x.id and y.status = 'live' and z.status <> 'cancelled')
              and (x.line_id is null or (select status from public.billing_lines where id = x.line_id) = 'approved')
              and (x.charge_id is null or (select status from public.client_charges where id = x.charge_id) = 'approved')
              and not exists (select 1 from public.write_offs w where w.claim_item_id = x.id and w.status not in ('rejected')) loop
    if v_new is null then
      insert into public.claims (program, payer_id, kind, replaces_claim_id, period_from, period_to, template_id)
      values (c.program, c.payer_id, 'replacement', c.id, c.period_from, c.period_to, v_tpl) returning id into v_new;
    end if;
    insert into public.claim_items (claim_id, line_id, quarter_budget_id, charge_id, client_id, claimed_value, expected_amount, replaces_item_id)
    values (v_new, i.line_id, i.quarter_budget_id, i.charge_id, i.client_id, i.claimed_value, i.expected_amount, i.id);
    v_n := v_n + 1;
  end loop;
  if v_new is null then
    perform set_config('portal.billing_prepare', 'off', true);
    raise exception 'No fully rejected lines to claim again (fix the cause first; voided lines are claimed through their corrected line).';
  end if;
  update public.claims set item_count = v_n,
         total_claimed = (select sum(claimed_value) from public.claim_items where claim_id = v_new and status = 'live'),
         total_expected = (select sum(expected_amount) from public.claim_items where claim_id = v_new and status = 'live')
   where id = v_new;
  perform set_config('portal.billing_prepare', 'off', true);
  return jsonb_build_object('claim', v_new, 'lines', v_n);
end;
$$;

create or replace function public.ndis_charge_check(p_charge uuid)
returns table (problem text, ndis_zone text, catalogue_version_id uuid, price_limit numeric)
language plpgsql stable set search_path = '' as $$
#variable_conflict use_column
declare
  c public.client_charges;
  v_zone text;
  v_ver uuid;
  s public.ndis_support_items;
  v_limit numeric;
begin
  select * into c from public.client_charges where id = p_charge;
  select z.ndis_zone into v_zone from public.client_location_pricing z where z.location_id = c.location_id;
  if v_zone is null then return query select 'Choose a service delivery location with an NDIS pricing zone for this charge.'::text, null::text, null::uuid, null::numeric; return; end if;
  select v.id into v_ver from public.ndis_catalogue_versions v
   where v.status = 'verified' and v.effective_from <= c.service_date and (v.effective_to is null or v.effective_to >= c.service_date)
     and (v.review_by is null or v.review_by >= (now() at time zone 'Australia/Sydney')::date)
   order by v.effective_from desc limit 1;
  if v_ver is null then return query select 'No verified NDIS catalogue covers the support date.'::text, v_zone, null::uuid, null::numeric; return; end if;
  select * into s from public.ndis_support_items x where x.version_id = v_ver and x.item_number = c.ndis_item;
  if s.id is null then return query select ('Support item ' || c.ndis_item || ' isn''t in the catalogue in force.')::text, v_zone, v_ver, null::numeric; return; end if;
  v_limit := case v_zone when 'national' then s.limit_national when 'remote' then s.limit_remote else s.limit_very_remote end;
  if v_limit is not null and c.amount > v_limit then
    return query select ('The charge $' || c.amount || ' is above the NDIS limit $' || v_limit || ' for item ' || c.ndis_item || '.')::text, v_zone, v_ver, v_limit; return;
  end if;
  return query select null::text, v_zone, v_ver, v_limit;
end;
$$;

create or replace function public.claim_add_charges(p_claim uuid) returns jsonb
language plpgsql set search_path = '' as $$
declare
  cl public.claims;
  ch record;
  pc record;
  v_rec uuid;
  v_n integer := 0;
  v_excl jsonb;
  v_pm text;
begin
  if public.from_portal() and not public.billing_can('claim_prepare') then raise exception 'Only someone with the claim prepare right prepares claims.'; end if;
  select * into cl from public.claims where id = p_claim;
  if cl.status <> 'draft' or cl.kind <> 'original' then raise exception 'Charges are added to a draft (original) claim.'; end if;
  v_excl := cl.excluded;
  perform set_config('portal.billing_prepare', 'on', true);
  for ch in select c.* from public.client_charges c
             where c.status = 'approved' and c.scheme = cl.program and c.service_date between cl.period_from and cl.period_to
               and not exists (select 1 from public.line_recoveries r where r.charge_id = c.id and r.payer_role = 'funding' and public.recovery_in_use(r.id))
               and not exists (select 1 from public.claim_items i join public.claims x on x.id = i.claim_id where i.charge_id = c.id and i.status = 'live' and x.status <> 'cancelled')
             order by c.service_date loop
    select null::text as problem, null::text as ndis_zone, null::uuid as catalogue_version_id, null::numeric as price_limit into pc;
    if cl.program = 'ndis' then
      select plan_management into v_pm from public.client_funding where id = ch.funding_id;
      if coalesce(v_pm, '') <> 'ndia' then continue; end if;
      if not exists (select 1 from public.ndis_plan_details d where d.funding_id = ch.funding_id and d.my_provider) then
        v_excl := v_excl || jsonb_build_object('charge', ch.id, 'reason', 'Not recorded as "my provider" for this agency-managed plan.'); continue;
      end if;
      select * into pc from public.ndis_charge_check(ch.id);
      if pc.problem is not null then v_excl := v_excl || jsonb_build_object('charge', ch.id, 'reason', pc.problem); continue; end if;
    end if;
    select id into v_rec from public.line_recoveries where charge_id = ch.id and payer_role = 'funding';
    if v_rec is null then
      insert into public.line_recoveries (charge_id, client_id, payer_role, payer_id, service_value, amount, ndis_zone, ndis_catalogue_version_id, ndis_item, ndis_limit)
      values (ch.id, ch.client_id, 'funding', cl.payer_id, ch.amount, case when cl.program = 'support_at_home' then coalesce(ch.government_share, ch.amount) else ch.amount end,
              pc.ndis_zone, pc.catalogue_version_id, nullif(ch.ndis_item, ''), pc.price_limit)
      returning id into v_rec;
    end if;
    insert into public.claim_items (claim_id, charge_id, recovery_id, client_id, claimed_value, expected_amount)
    values (p_claim, ch.id, v_rec, ch.client_id, ch.amount, (select amount from public.line_recoveries where id = v_rec));
    v_n := v_n + 1;
  end loop;
  update public.claims set excluded = v_excl,
         item_count = (select count(*) from public.claim_items where claim_id = p_claim and status = 'live'),
         total_claimed = (select coalesce(sum(claimed_value), 0) from public.claim_items where claim_id = p_claim and status = 'live'),
         total_expected = (select coalesce(sum(expected_amount), 0) from public.claim_items where claim_id = p_claim and status = 'live')
   where id = p_claim;
  perform set_config('portal.billing_prepare', 'off', true);
  return jsonb_build_object('charges', v_n);
end;
$$;

create or replace function public.invoice_add_charges(p_kind text, p_from date, p_to date) returns jsonb
language plpgsql set search_path = '' as $$
declare
  ch record;
  pc record;
  v_role text := case when p_kind in ('sah_contribution', 'private') then 'client' else 'funding' end;
  v_scheme text := case when p_kind = 'sah_contribution' then 'support_at_home' when p_kind = 'private' then 'private' else 'ndis' end;
  v_payer uuid;
  v_inv uuid;
  v_rec uuid;
  v_amt numeric;
  v_pm text;
  v_n integer := 0;
  v_made integer := 0;
  v_excl jsonb := '[]';
begin
  if public.from_portal() and not public.billing_can('invoice_prepare') then raise exception 'Only someone with the invoice prepare right prepares invoices.'; end if;
  if p_kind not in ('sah_contribution', 'private', 'ndis_plan_managed', 'ndis_self_managed') then raise exception 'Choose the kind of invoice.'; end if;
  perform set_config('portal.billing_prepare', 'on', true);
  for ch in select c.* from public.client_charges c
             where c.status = 'approved' and c.scheme = v_scheme and c.service_date between p_from and p_to
               and not exists (select 1 from public.line_recoveries r where r.charge_id = c.id and r.payer_role = v_role and public.recovery_in_use(r.id))
               and not exists (select 1 from public.invoice_items i join public.invoices x on x.id = i.invoice_id join public.line_recoveries r on r.id = i.recovery_id
                                where i.charge_id = c.id and i.status = 'live' and x.status <> 'cancelled' and r.payer_role = v_role)
             order by c.client_id, c.service_date loop
    if p_kind like 'ndis_%' then
      select plan_management into v_pm from public.client_funding where id = ch.funding_id;
      if coalesce(v_pm, '') <> (case when p_kind = 'ndis_plan_managed' then 'plan' else 'self' end) then continue; end if;
      select * into pc from public.ndis_charge_check(ch.id);
      if pc.problem is not null then v_excl := v_excl || jsonb_build_object('charge', ch.id, 'reason', pc.problem); continue; end if;
    end if;
    v_amt := case when p_kind = 'sah_contribution' then coalesce(ch.client_share, 0) else ch.amount end;
    if v_amt <= 0 then continue; end if;
    if p_kind = 'sah_contribution' and exists (select 1 from public.client_fee_reductions f where f.client_id = ch.client_id and f.enrolment_id = ch.enrolment_id and f.full_reduction
                                                 and f.starts_on <= ch.service_date and (f.ends_on is null or f.ends_on >= ch.service_date)) then
      v_excl := v_excl || jsonb_build_object('charge', ch.id, 'reason', 'Full fee reduction supplement applies.'); continue;
    end if;
    if v_role = 'client' then
      v_payer := (select k.payer_id from public.client_payer_links k where k.client_id = ch.client_id and k.role = 'client'
                    and k.starts_on <= ch.service_date and (k.ends_on is null or k.ends_on >= ch.service_date) order by k.starts_on desc limit 1);
    else
      v_payer := (select k.payer_id from public.client_payer_links k where k.client_id = ch.client_id and k.role = 'funding' and k.funding_id = ch.funding_id
                    and k.starts_on <= ch.service_date and (k.ends_on is null or k.ends_on >= ch.service_date) order by k.starts_on desc limit 1);
    end if;
    if v_payer is null then v_excl := v_excl || jsonb_build_object('charge', ch.id, 'reason', 'No payer recorded for this client.'); continue; end if;
    select id into v_inv from public.invoices where kind = p_kind and client_id = ch.client_id and payer_id = v_payer and status = 'draft' and period_from = p_from and period_to = p_to;
    if v_inv is null then
      insert into public.invoices (kind, client_id, payer_id, period_from, period_to) values (p_kind, ch.client_id, v_payer, p_from, p_to) returning id into v_inv;
      v_made := v_made + 1;
    end if;
    select id into v_rec from public.line_recoveries where charge_id = ch.id and payer_role = v_role;
    if v_rec is null then
      insert into public.line_recoveries (charge_id, client_id, payer_role, payer_id, service_value, amount) values (ch.id, ch.client_id, v_role, v_payer, ch.amount, v_amt) returning id into v_rec;
    end if;
    insert into public.invoice_items (invoice_id, charge_id, recovery_id, client_id, description, service_date, quantity, unit_price, amount, gst_code)
    values (v_inv, ch.id, v_rec, ch.client_id,
            ch.description || case when p_kind = 'sah_contribution' then ', your contribution ' || coalesce(ch.contribution_pct::text, '?') || '% of $' || ch.amount else '' end
              || coalesce(', NDIS item ' || nullif(ch.ndis_item, ''), ''),
            ch.service_date, 1, v_amt, v_amt, ch.gst_code);
    v_n := v_n + 1;
  end loop;
  update public.invoices v set subtotal = (select coalesce(sum(amount), 0) from public.invoice_items i where i.invoice_id = v.id and i.status = 'live'),
                               total = (select coalesce(sum(amount), 0) from public.invoice_items i where i.invoice_id = v.id and i.status = 'live')
   where v.status = 'draft' and v.kind = p_kind and v.period_from = p_from and v.period_to = p_to;
  perform set_config('portal.billing_prepare', 'off', true);
  return jsonb_build_object('invoices_made', v_made, 'charges', v_n, 'excluded', v_excl);
end;
$$;

create or replace function public.statement_add_charges() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_end date := (new.month + interval '1 month' - interval '1 day')::date;
  v_spent numeric;
  v_contrib numeric;
begin
  select coalesce(sum(c.amount), 0), coalesce(sum(c.client_share) filter (where not exists (
           select 1 from public.client_fee_reductions f where f.enrolment_id = new.enrolment_id and f.full_reduction and f.starts_on <= c.service_date and (f.ends_on is null or f.ends_on >= c.service_date))), 0)
    into v_spent, v_contrib
    from public.client_charges c where c.enrolment_id = new.enrolment_id and c.status = 'approved' and c.service_date between new.month and v_end;
  new.snapshot := new.snapshot || jsonb_build_object(
    'charges', (select coalesce(jsonb_agg(jsonb_build_object('date', c.service_date, 'description', c.description, 'stream', c.funding_stream, 'amount', c.amount, 'client_share', c.client_share) order by c.service_date), '[]')
                  from public.client_charges c where c.enrolment_id = new.enrolment_id and c.status = 'approved' and c.service_date between new.month and v_end),
    'spent_in_month', coalesce((new.snapshot ->> 'spent_in_month')::numeric, 0) + v_spent,
    'contributions_in_month', coalesce((new.snapshot ->> 'contributions_in_month')::numeric, 0) + v_contrib,
    'pathways', (select coalesce(jsonb_agg(jsonb_build_object('stream', b.stream, 'amount', b.amount, 'used', b.used, 'available', b.available, 'ends_on', b.ends_on)), '[]')
                   from public.pathway_balances b where b.client_id = new.client_id and b.status = 'approved' and b.starts_on <= v_end and b.ends_on >= new.month));
  return new;
end;
$$;

do $$
declare
  t text;
begin
  -- Set-up records (all-client reach).
  foreach t in array array['suppliers', 'supplier_invoices', 'billing_markup_rules'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "billing see %s" on public.%I', t, t);
    execute format('create policy "billing see %s" on public.%I for select to authenticated using (public.billing_can(''view''))', t, t);
    execute format('drop policy if exists "billing add %s" on public.%I', t, t);
    execute format('create policy "billing add %s" on public.%I for insert to authenticated with check (public.billing_can(''prepare'') or public.billing_can(''prices''))', t, t);
    execute format('drop policy if exists "billing change %s" on public.%I', t, t);
    execute format('create policy "billing change %s" on public.%I for update to authenticated using (public.billing_can(''view'')) with check (public.billing_can(''view''))', t, t);
    execute format('grant select, insert, update on public.%I to authenticated', t);
    execute format('revoke all on public.%I from anon', t);
  end loop;
  drop policy if exists "billing remove billing_markup_rules" on public.billing_markup_rules;
  create policy "billing remove billing_markup_rules" on public.billing_markup_rules for delete to authenticated using (public.billing_can('prices'));
  grant delete on public.billing_markup_rules to authenticated;
  alter table public.supplier_invoice_lines enable row level security;
  drop policy if exists "billing see supplier_invoice_lines" on public.supplier_invoice_lines;
  create policy "billing see supplier_invoice_lines" on public.supplier_invoice_lines for select to authenticated using (public.billing_can('view'));
  drop policy if exists "billing add supplier_invoice_lines" on public.supplier_invoice_lines;
  create policy "billing add supplier_invoice_lines" on public.supplier_invoice_lines for insert to authenticated with check (public.billing_can('prepare'));
  drop policy if exists "billing change supplier_invoice_lines" on public.supplier_invoice_lines;
  create policy "billing change supplier_invoice_lines" on public.supplier_invoice_lines for update to authenticated using (public.billing_can('prepare')) with check (public.billing_can('prepare'));
  drop policy if exists "billing remove supplier_invoice_lines" on public.supplier_invoice_lines;
  create policy "billing remove supplier_invoice_lines" on public.supplier_invoice_lines for delete to authenticated using (public.billing_can('prepare'));
  grant select, insert, update, delete on public.supplier_invoice_lines to authenticated;
  revoke all on public.supplier_invoice_lines from anon;
  -- Client records.
  foreach t in array array['client_charges', 'client_pathway_budgets'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "billing see %s" on public.%I', t, t);
    execute format('create policy "billing see %s" on public.%I for select to authenticated using (public.billing_can(''view'', client_id))', t, t);
    execute format('drop policy if exists "billing add %s" on public.%I', t, t);
    execute format('create policy "billing add %s" on public.%I for insert to authenticated with check (public.billing_can(''prepare'', client_id))', t, t);
    execute format('drop policy if exists "billing change %s" on public.%I', t, t);
    execute format('create policy "billing change %s" on public.%I for update to authenticated using (public.billing_can(''view'', client_id)) with check (public.billing_can(''view'', client_id))', t, t);
    execute format('grant select, insert, update on public.%I to authenticated', t);
    execute format('revoke all on public.%I from anon', t);
  end loop;
  drop policy if exists "billing remove client_pathway_budgets" on public.client_pathway_budgets;
  create policy "billing remove client_pathway_budgets" on public.client_pathway_budgets for delete to authenticated using (public.billing_can('prepare', client_id));
  grant delete on public.client_pathway_budgets to authenticated;
  grant select on public.pathway_balances to authenticated;
  revoke all on public.pathway_balances from anon;
end $$;
revoke execute on function public.claim_add_charges(uuid) from public, anon;
grant execute on function public.claim_add_charges(uuid) to authenticated;
revoke execute on function public.invoice_add_charges(text, date, date) from public, anon;
grant execute on function public.invoice_add_charges(text, date, date) to authenticated;
revoke execute on function public.ndis_charge_check(uuid) from public, anon;
grant execute on function public.ndis_charge_check(uuid) to authenticated;

do $$
declare
  t text;
begin
  foreach t in array array['supplier_invoices:guard_supplier_invoice', 'supplier_invoice_lines:guard_supplier_line', 'billing_markup_rules:guard_markup_rule',
                           'client_pathway_budgets:guard_pathway_budget', 'client_charges:guard_client_charge'] loop
    execute format('drop trigger if exists %I on public.%I', split_part(t, ':', 2), split_part(t, ':', 1));
    execute format('create trigger %I before insert or update or delete on public.%I for each row execute function public.%I()', split_part(t, ':', 2), split_part(t, ':', 1), split_part(t, ':', 2));
  end loop;
  drop trigger if exists supplier_invoice_totals on public.supplier_invoice_lines;
  create trigger supplier_invoice_totals after insert or update or delete on public.supplier_invoice_lines for each row execute function public.supplier_invoice_totals();
  drop trigger if exists ledger_from_charge on public.client_charges;
  create trigger ledger_from_charge after update on public.client_charges for each row execute function public.ledger_from_charge();
  drop trigger if exists guard_statement_charges on public.client_statements;
  create trigger guard_statement_charges before insert on public.client_statements for each row execute function public.statement_add_charges();
  foreach t in array array['suppliers:supplier', 'supplier_invoices:supplier_invoice', 'supplier_invoice_lines:supplier_invoice_line', 'billing_markup_rules:markup_rule'] loop
    execute format('drop trigger if exists log_billing_setup on public.%I', split_part(t, ':', 1));
    execute format('create trigger log_billing_setup after insert or update or delete on public.%I for each row execute function public.log_car_setup(%L)', split_part(t, ':', 1), split_part(t, ':', 2));
    execute format('drop trigger if exists stamp_billing_setup on public.%I', split_part(t, ':', 1));
    execute format('create trigger stamp_billing_setup before insert or update on public.%I for each row execute function public.stamp_billing_updated()', split_part(t, ':', 1));
  end loop;
  foreach t in array array['client_charges', 'client_pathway_budgets'] loop
    execute format('drop trigger if exists log_client_change on public.%I', t);
    execute format('create trigger log_client_change before insert or update on public.%I for each row execute function public.log_client_change()', t);
    execute format('drop trigger if exists log_client_audit on public.%I', t);
    execute format('create trigger log_client_audit after insert or update or delete on public.%I for each row execute function public.log_client_change()', t);
  end loop;
end $$;

revoke execute on function public.guard_supplier_invoice() from public, anon, authenticated;
revoke execute on function public.guard_supplier_line() from public, anon, authenticated;
revoke execute on function public.supplier_invoice_totals() from public, anon, authenticated;
revoke execute on function public.guard_markup_rule() from public, anon, authenticated;
revoke execute on function public.guard_pathway_budget() from public, anon, authenticated;
revoke execute on function public.guard_client_charge() from public, anon, authenticated;
revoke execute on function public.ledger_from_charge() from public, anon, authenticated;
revoke execute on function public.statement_add_charges() from public, anon, authenticated;
revoke execute on function public.guard_line_recovery() from public, anon, authenticated;
revoke execute on function public.guard_claim_item() from public, anon, authenticated;
commit;
