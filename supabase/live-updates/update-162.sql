-- Staff Portal · © cmeproject. All rights reserved.
-- Update 162: billing lines from delivered services, Support at Home quarterly budgets and the
-- append-only funding ledger, delivery decisions, exceptions (Phase 4B). Nothing is billed until
-- someone makes lines and someone else approves them. Safe to run again. Undo: undo-162.sql.
begin;
create table if not exists public.billing_parameters (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  scheme text not null,
  key text not null check (key in ('sah_care_management_pct', 'sah_rollover_floor', 'sah_rollover_pct')),
  value numeric(12, 2) not null check (value >= 0),
  effective_from date not null,
  source text not null default '' check (length(source) <= 1000),
  as_at date,
  status text not null default 'unverified' check (status in ('unverified', 'verified')),
  verified_by uuid,
  verified_at timestamptz,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  unique (scheme, key, effective_from)
);
insert into public.billing_parameters (scheme, key, value, effective_from) values
  ('support_at_home', 'sah_care_management_pct', 10, '2025-11-01'),
  ('support_at_home', 'sah_rollover_floor', 1000, '2025-11-01'),
  ('support_at_home', 'sah_rollover_pct', 10, '2025-11-01')
on conflict (scheme, key, effective_from) do nothing;

create or replace function public.guard_billing_parameter() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'DELETE' then
    raise exception 'Billing figures are never deleted. Add a new one from a later date.';
  end if;
  if tg_op = 'UPDATE' and (new.scheme, new.key, new.effective_from) is distinct from (old.scheme, old.key, old.effective_from) then
    raise exception 'A figure keeps its scheme, name and start date. Add a new one instead.';
  end if;
  if tg_op = 'UPDATE' and old.status = 'verified' and new.status = 'verified' and new.value is distinct from old.value then
    raise exception 'A verified figure isn''t changed. Mark it unverified first, or add a new one from a later date.';
  end if;
  if new.status = 'verified' then
    if length(trim(new.source)) = 0 or new.as_at is null then
      raise exception 'To verify a figure, record its official source and "as at" date.';
    end if;
    if tg_op = 'INSERT' or old.status <> 'verified' then
      new.verified_by := auth.uid(); new.verified_at := now();
    else
      new.verified_by := old.verified_by; new.verified_at := old.verified_at;
    end if;
  else
    new.verified_by := null; new.verified_at := null;
  end if;
  return new;
end;
$$;

create or replace function public.billing_figure(p_key text, p_on date) returns numeric
language sql stable set search_path = '' as $$
  select p.value from public.billing_parameters p
   where p.key = p_key and p.status = 'verified' and p.effective_from <= p_on
   order by p.effective_from desc limit 1
$$;

create table if not exists public.billing_delivery_overrides (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  shift_id uuid not null references public.shifts (id),
  client_id uuid references public.car_clients (id),
  decision text not null check (decision in ('delivered', 'not_delivered')),
  reason text not null check (length(trim(reason)) between 1 and 1000),
  decided_by uuid default auth.uid(),
  decided_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now()
);
create index if not exists billing_delivery_overrides_shift on public.billing_delivery_overrides (shift_id, decided_at desc);
create or replace function public.guard_delivery_override() returns trigger
language plpgsql set search_path = '' as $$
declare
  sh public.shifts;
begin
  if tg_op <> 'INSERT' then
    raise exception 'A delivery decision is never changed. Record a new one with its reason.';
  end if;
  select * into sh from public.shifts where id = new.shift_id;
  if sh.id is null or sh.client_id is null or sh.status <> 'published' then
    raise exception 'Delivery is decided for published client shifts only.';
  end if;
  if sh.starts_at > now() then
    raise exception 'That shift hasn''t happened yet.';
  end if;
  if public.from_portal() and not public.billing_can('approve', sh.client_id) then
    raise exception 'Only someone with the Billing approve right decides delivery.';
  end if;
  new.client_id := sh.client_id;
  new.decided_by := auth.uid();
  new.decided_at := now();
  return new;
end;
$$;

create table if not exists public.client_quarter_budgets (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id),
  enrolment_id uuid not null references public.client_enrolments (id),
  funding_id uuid references public.client_funding (id),
  quarter_start date not null,
  quarter_end date not null,
  classification integer check (classification between 1 and 8),
  quarterly_amount numeric(12, 2) not null check (quarterly_amount between 0 and 1000000),
  start_date date not null,
  prorated_amount numeric(12, 2) not null default 0,
  carryover_in numeric(12, 2) not null default 0,
  care_management_pct numeric(6, 2),
  rollover_floor numeric(12, 2),
  rollover_pct numeric(6, 2),
  care_management numeric(12, 2) not null default 0,
  spendable numeric(12, 2) not null default 0,
  source text not null check (length(trim(source)) between 1 and 300),
  status text not null default 'draft' check (status in ('draft', 'approved', 'closed')),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  approved_by uuid, approved_at timestamptz,
  closed_by uuid, closed_at timestamptz,
  spent numeric(12, 2), unspent numeric(12, 2), carryover_out numeric(12, 2), lapsed numeric(12, 2),
  updated_by uuid,
  updated_at timestamptz not null default now()
);
create unique index if not exists client_quarter_budgets_one on public.client_quarter_budgets (enrolment_id, quarter_start);

create or replace function public.guard_quarter_budget() returns trigger
language plpgsql set search_path = '' as $$
declare
  e public.client_enrolments;
  v_prev public.client_quarter_budgets;
  v_days integer;
  v_left integer;
begin
  if tg_op = 'DELETE' then
    if old.status <> 'draft' then
      raise exception 'An approved or closed quarter budget is never deleted.';
    end if;
    return old;
  end if;
  if tg_op = 'UPDATE' then
    if old.status = 'closed' and new is distinct from old then
      raise exception 'A closed quarter never changes.';
    end if;
    if old.status = 'approved' then
      if new.status = 'closed' and coalesce(current_setting('portal.billing_close', true), '') = 'on'
         and (new.quarterly_amount, new.start_date, new.spendable, new.carryover_in, new.care_management) is not distinct from (old.quarterly_amount, old.start_date, old.spendable, old.carryover_in, old.care_management) then
        return new;
      end if;
      raise exception 'An approved quarter budget isn''t changed. Use a ledger adjustment (approved by someone else) or close the quarter.';
    end if;
    if new.status = 'closed' then
      raise exception 'Close a quarter with "Close quarter".';
    end if;
    if (new.created_by, new.created_at, new.client_id, new.enrolment_id, new.quarter_start) is distinct from (old.created_by, old.created_at, old.client_id, old.enrolment_id, old.quarter_start) then
      raise exception 'A quarter budget keeps its client, program, quarter and maker.';
    end if;
  else
    new.status := 'draft'; new.created_by := auth.uid(); new.created_at := now();
    new.approved_by := null; new.approved_at := null; new.closed_by := null; new.closed_at := null;
    new.spent := null; new.unspent := null; new.carryover_out := null; new.lapsed := null;
  end if;
  select * into e from public.client_enrolments where id = new.enrolment_id;
  if e.id is null or e.client_id <> new.client_id or e.scheme <> 'support_at_home' then
    raise exception 'Choose the client''s Support at Home program.';
  end if;
  if not exists (select 1 from public.billing_scheme_rules r where r.scheme = 'support_at_home' and r.status = 'confirmed') then
    raise exception 'Support at Home billing rules aren''t confirmed yet (Billing set-up).';
  end if;
  if new.funding_id is not null and not exists (select 1 from public.client_funding f where f.id = new.funding_id and f.client_id = new.client_id and f.scheme = 'support_at_home') then
    raise exception 'Choose a Support at Home funding record of this client.';
  end if;
  -- Quarters: Jul-Sep, Oct-Dec, Jan-Mar, Apr-Jun.
  if extract(day from new.quarter_start) <> 1 or extract(month from new.quarter_start)::int not in (1, 4, 7, 10) then
    raise exception 'A quarter starts on 1 January, April, July or October.';
  end if;
  new.quarter_end := (new.quarter_start + interval '3 months' - interval '1 day')::date;
  if new.start_date is null then
    new.start_date := greatest(new.quarter_start, e.starts_on);
  end if;
  if new.start_date < new.quarter_start or new.start_date > new.quarter_end then
    raise exception 'The start date must be within the quarter.';
  end if;
  -- Verified figures in force at the start of the quarter.
  new.care_management_pct := public.billing_figure('sah_care_management_pct', new.quarter_start);
  new.rollover_floor := public.billing_figure('sah_rollover_floor', new.quarter_start);
  new.rollover_pct := public.billing_figure('sah_rollover_pct', new.quarter_start);
  if new.care_management_pct is null or new.rollover_floor is null or new.rollover_pct is null then
    raise exception 'Verify the Support at Home figures (care management %%, rollover floor and %%) in Billing set-up first.';
  end if;
  -- Carryover from the previous quarter (it must be closed first, if there was one).
  select * into v_prev from public.client_quarter_budgets where enrolment_id = new.enrolment_id and quarter_end = new.quarter_start - 1;
  if v_prev.id is not null and v_prev.status <> 'closed' then
    raise exception 'Close the previous quarter first, so its carryover is known.';
  end if;
  new.carryover_in := coalesce(v_prev.carryover_out, 0);
  v_days := new.quarter_end - new.quarter_start + 1;
  v_left := new.quarter_end - new.start_date + 1;
  new.prorated_amount := round(new.quarterly_amount * v_left / v_days, 2);
  new.care_management := round(new.prorated_amount * new.care_management_pct / 100, 2);
  new.spendable := new.prorated_amount + new.carryover_in - new.care_management;
  -- Steps.
  if tg_op = 'UPDATE' and new.status = 'approved' and old.status = 'draft' then
    if public.from_portal() and (not public.billing_can('approve', new.client_id) or auth.uid() is not distinct from old.created_by) then
      raise exception 'Only someone with the Billing approve right, who didn''t make this budget, approves it.';
    end if;
    new.approved_by := auth.uid(); new.approved_at := now();
  elsif tg_op = 'UPDATE' and new.status is distinct from old.status then
    raise exception 'A quarter budget goes Draft -> Approved -> Closed.';
  end if;
  return new;
end;
$$;

create table if not exists public.funding_ledger (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id),
  quarter_budget_id uuid references public.client_quarter_budgets (id),
  funding_id uuid references public.client_funding (id),
  entry_kind text not null check (entry_kind in ('opening_balance', 'charge', 'reversal', 'adjustment', 'carryover_out', 'lapse')),
  amount numeric(12, 2) not null,
  entry_date date not null,
  billing_line_id uuid,
  reason text not null default '' check (length(reason) <= 1000),
  status text not null default 'approved' check (status in ('proposed', 'approved', 'rejected')),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  decided_by uuid, decided_at timestamptz,
  updated_by uuid,
  updated_at timestamptz not null default now(),
  constraint funding_ledger_one_account check ((quarter_budget_id is null) <> (funding_id is null))
);
create index if not exists funding_ledger_budget on public.funding_ledger (quarter_budget_id);
create index if not exists funding_ledger_funding on public.funding_ledger (funding_id);
create unique index if not exists funding_ledger_one_opening on public.funding_ledger (funding_id) where entry_kind = 'opening_balance' and status in ('proposed', 'approved');

create or replace function public.guard_funding_ledger() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_client uuid;
begin
  if tg_op = 'DELETE' then
    raise exception 'Ledger entries are never deleted. Add an adjustment instead.';
  end if;
  if tg_op = 'UPDATE' then
    -- Only a proposed opening balance or adjustment is decided (approved or rejected) by someone else.
    if (to_jsonb(new) - array['status', 'decided_by', 'decided_at', 'updated_by', 'updated_at']) is distinct from (to_jsonb(old) - array['status', 'decided_by', 'decided_at', 'updated_by', 'updated_at'])
       or old.status <> 'proposed' or new.status not in ('approved', 'rejected') then
      raise exception 'Ledger entries never change. Only a proposed entry is approved or rejected.';
    end if;
    if public.from_portal() and (not public.billing_can('approve', new.client_id) or auth.uid() is not distinct from old.created_by) then
      raise exception 'Only someone with the Billing approve right, who didn''t propose it, decides this entry.';
    end if;
    new.decided_by := auth.uid(); new.decided_at := now();
    return new;
  end if;
  -- New entries.
  if new.quarter_budget_id is not null then
    select client_id into v_client from public.client_quarter_budgets where id = new.quarter_budget_id and status <> 'draft';
    if v_client is null then
      raise exception 'Ledger entries go on an approved quarter budget.';
    end if;
    if new.entry_kind = 'opening_balance' then
      raise exception 'A quarter budget''s opening amount is the budget itself.';
    end if;
  else
    select client_id into v_client from public.client_funding where id = new.funding_id;
  end if;
  if v_client is null or v_client <> new.client_id then
    raise exception 'That funding account belongs to another client.';
  end if;
  new.created_by := auth.uid(); new.created_at := now();
  if new.entry_kind in ('opening_balance', 'adjustment') then
    -- People propose these; someone else approves.
    if length(trim(new.reason)) = 0 then
      raise exception 'Say where the amount comes from, or why it''s adjusted.';
    end if;
    if new.entry_kind = 'opening_balance' and new.amount < 0 then
      raise exception 'An opening balance is the amount available (zero or more).';
    end if;
    new.status := 'proposed'; new.decided_by := null; new.decided_at := null;
  else
    -- Charges, reversals, carryover and lapse come from approved billing lines or a quarter close.
    if public.from_portal() and pg_trigger_depth() < 2 and coalesce(current_setting('portal.billing_close', true), '') <> 'on' then
      raise exception 'Charges and reversals come from billing lines; carryover and lapse from closing a quarter.';
    end if;
    new.status := 'approved'; new.decided_by := auth.uid(); new.decided_at := now();
  end if;
  return new;
end;
$$;

create or replace view public.funding_balances with (security_invoker = true) as
  select 'quarter_budget' as account_kind, b.id as account_id, b.client_id, b.spendable as opening,
         coalesce(sum(l.amount) filter (where l.status = 'approved'), 0) as movements,
         b.spendable + coalesce(sum(l.amount) filter (where l.status = 'approved'), 0) as available
    from public.client_quarter_budgets b left join public.funding_ledger l on l.quarter_budget_id = b.id
   where b.status <> 'draft'
   group by b.id
  union all
  select 'funding', f.id, f.client_id, 0,
         coalesce(sum(l.amount) filter (where l.status = 'approved'), 0),
         coalesce(sum(l.amount) filter (where l.status = 'approved'), 0)
    from public.client_funding f join public.funding_ledger l on l.funding_id = f.id
   group by f.id;

create table if not exists public.billing_lines (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id),
  shift_id uuid not null references public.shifts (id),
  kind text not null default 'service' check (kind in ('service', 'cancellation')),
  status text not null default 'draft' check (status in ('draft', 'approved', 'voided')),
  scheme text not null,
  service_id uuid not null references public.client_services (id),
  terms_id uuid not null references public.client_service_terms (id),
  enrolment_id uuid not null references public.client_enrolments (id),
  funding_id uuid references public.client_funding (id),
  agreement_id uuid references public.client_agreements (id),
  quarter_budget_id uuid references public.client_quarter_budgets (id),
  funding_stream text not null,
  price_list_version_id uuid not null references public.price_list_versions (id),
  price_item_id uuid not null references public.price_items (id),
  band_key text not null,
  band_label text not null,
  service_date date not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  minutes_actual integer not null,
  minutes_billed integer not null,
  unit text not null,
  quantity numeric(10, 2) not null,
  unit_price numeric(10, 2) not null,
  amount numeric(12, 2) not null,
  gst_code text not null,
  sah_category text,
  personal_care boolean not null default false,
  contribution_rate_id uuid references public.client_contribution_rates (id),
  contribution_pct numeric(5, 2),
  client_share numeric(12, 2),
  government_share numeric(12, 2),
  holiday_state text,
  over_budget boolean not null default false,
  approve_note text not null default '' check (length(approve_note) <= 1000),
  calc jsonb not null default '{}',
  generated_by uuid default auth.uid(),
  generated_at timestamptz not null default now(),
  approved_by uuid, approved_at timestamptz,
  voided_by uuid, voided_at timestamptz,
  void_reason text check (void_reason in ('data_entry', 'wrong_rate', 'not_delivered', 'wrong_client', 'grounds_accepted', 'wrong_terms', 'other')),
  void_note text not null default '' check (length(void_note) <= 1000),
  corrects_id uuid references public.billing_lines (id),
  updated_by uuid,
  updated_at timestamptz not null default now()
);
create unique index if not exists billing_lines_one_live on public.billing_lines (shift_id, kind, terms_id, band_key) where status <> 'voided';
create index if not exists billing_lines_client on public.billing_lines (client_id, service_date);
create index if not exists billing_lines_status on public.billing_lines (status, service_date);

create or replace function public.guard_billing_line() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'DELETE' then
    raise exception 'Billing lines are never deleted. Void them with a reason.';
  end if;
  if tg_op = 'INSERT' then
    if public.from_portal() and coalesce(current_setting('portal.billing_generate', true), '') <> 'on' then
      raise exception 'Billing lines are made by "Make billing lines" from delivered shifts.';
    end if;
    new.status := 'draft'; new.generated_by := auth.uid(); new.generated_at := now();
    new.approved_by := null; new.approved_at := null; new.voided_by := null; new.voided_at := null;
    return new;
  end if;
  if (to_jsonb(new) - array['status', 'approve_note', 'approved_by', 'approved_at', 'voided_by', 'voided_at', 'void_reason', 'void_note', 'updated_by', 'updated_at'])
     is distinct from (to_jsonb(old) - array['status', 'approve_note', 'approved_by', 'approved_at', 'voided_by', 'voided_at', 'void_reason', 'void_note', 'updated_by', 'updated_at']) then
    raise exception 'A billing line''s amounts and sources never change. Void it with a reason and make it again.';
  end if;
  if old.status = 'voided' then
    raise exception 'A voided line never changes.';
  end if;
  new.approved_by := old.approved_by; new.approved_at := old.approved_at;
  if new.status = 'approved' and old.status = 'draft' then
    if public.from_portal() and (not public.billing_can('approve', new.client_id) or auth.uid() is not distinct from old.generated_by) then
      raise exception 'Only someone with the Billing approve right, who didn''t make these lines, approves them.';
    end if;
    if old.over_budget and length(trim(new.approve_note)) = 0 then
      raise exception 'This line is over the available budget. Say how it''s covered (private agreement, write-off, or other).';
    end if;
    new.approved_by := auth.uid(); new.approved_at := now();
  elsif new.status = 'voided' and old.status in ('draft', 'approved') then
    if public.from_portal() and not public.billing_can('approve', new.client_id) then
      raise exception 'Only someone with the Billing approve right voids billing lines.';
    end if;
    if new.void_reason is null then
      raise exception 'Choose why it''s voided.';
    end if;
    if new.void_reason = 'other' and length(trim(new.void_note)) = 0 then
      raise exception 'Say why it''s voided.';
    end if;
    new.voided_by := auth.uid(); new.voided_at := now();
  elsif new.status is distinct from old.status then
    raise exception 'A billing line goes Draft -> Approved, or is voided.';
  else
    if (new.void_reason, new.void_note, new.approve_note) is distinct from (old.void_reason, old.void_note, old.approve_note) then
      raise exception 'Notes are set when approving or voiding.';
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.ledger_from_line() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.quarter_budget_id is null and new.funding_id is null then
    return null;
  end if;
  if new.status = 'approved' and old.status = 'draft' then
    insert into public.funding_ledger (client_id, quarter_budget_id, funding_id, entry_kind, amount, entry_date, billing_line_id, reason)
    values (new.client_id, new.quarter_budget_id, case when new.quarter_budget_id is null then new.funding_id end, 'charge', -new.amount, new.service_date, new.id, 'Billing line approved');
  elsif new.status = 'voided' and old.status = 'approved' then
    insert into public.funding_ledger (client_id, quarter_budget_id, funding_id, entry_kind, amount, entry_date, billing_line_id, reason)
    values (new.client_id, new.quarter_budget_id, case when new.quarter_budget_id is null then new.funding_id end, 'reversal', new.amount, new.service_date, new.id, 'Approved line voided: ' || new.void_reason);
  end if;
  return null;
end;
$$;

create or replace function public.billing_calc(p_shift uuid, p_kind text default 'service')
returns table (problem text, terms_id uuid, band_key text, band_label text, minutes_actual integer, minutes_billed integer, quantity numeric, unit text,
               unit_price numeric, amount numeric, price_item_id uuid, price_list_version_id uuid, gst_code text, contribution_pct numeric,
               contribution_rate_id uuid, client_share numeric, government_share numeric, quarter_budget_id uuid, funding_id uuid, over_budget boolean,
               service_date date, starts_at timestamptz, ends_at timestamptz, holiday_state text, calc jsonb)
language plpgsql set search_path = '' as $$
#variable_conflict use_column
declare
  sh public.shifts;
  ts public.shift_timesheets;
  ov public.billing_delivery_overrides;
  sv public.client_services;
  t public.client_service_terms;
  e public.client_enrolments;
  ver public.price_list_versions;
  v_start timestamptz;
  v_end timestamptz;
  v_break integer;
  v_date date;
  v_state text;
  v_scheme text;
  v_rate public.client_contribution_rates;
  v_pct numeric;
  v_budget public.client_quarter_budgets;
  v_funding uuid;
  v_avail numeric;
  v_total integer;
  v_billed_total integer;
  v_extra integer;
  v_top text;
  r record;
  v_item public.price_items;
  v_qty numeric;
  v_amt numeric;
  v_client numeric;
  v_running numeric := 0;
begin
  select * into sh from public.shifts where id = p_shift;
  if sh.id is null or sh.client_id is null then
    return query select 'Not a client shift.'::text, null::uuid, null::text, null::text, null::int, null::int, null::numeric, null::text, null::numeric, null::numeric, null::uuid, null::uuid, null::text, null::numeric, null::uuid, null::numeric, null::numeric, null::uuid, null::uuid, false, null::date, null::timestamptz, null::timestamptz, null::text, '{}'::jsonb; return;
  end if;
  -- Delivered, or a chargeable cancellation.
  if p_kind = 'cancellation' then
    if sh.status <> 'cancelled' or not exists (select 1 from public.shift_cancellations c where c.shift_id = sh.id and c.charge = 'charge') then
      return query select 'Not a chargeable cancellation.'::text, null::uuid, null::text, null::text, null::int, null::int, null::numeric, null::text, null::numeric, null::numeric, null::uuid, null::uuid, null::text, null::numeric, null::uuid, null::numeric, null::numeric, null::uuid, null::uuid, false, null::date, null::timestamptz, null::timestamptz, null::text, '{}'::jsonb; return;
    end if;
    v_start := sh.starts_at; v_end := sh.ends_at; v_break := coalesce(sh.break_minutes, 0);
  else
    if sh.status <> 'published' then
      return query select 'The shift isn''t published (or was cancelled).'::text, null::uuid, null::text, null::text, null::int, null::int, null::numeric, null::text, null::numeric, null::numeric, null::uuid, null::uuid, null::text, null::numeric, null::uuid, null::numeric, null::numeric, null::uuid, null::uuid, false, null::date, null::timestamptz, null::timestamptz, null::text, '{}'::jsonb; return;
    end if;
    select * into ov from public.billing_delivery_overrides o where o.shift_id = sh.id order by o.decided_at desc limit 1;
    select * into ts from public.shift_timesheets x where x.shift_id = sh.id;
    if ov.id is not null and ov.decision = 'not_delivered' then
      return query select ('Marked not delivered: ' || ov.reason)::text, null::uuid, null::text, null::text, null::int, null::int, null::numeric, null::text, null::numeric, null::numeric, null::uuid, null::uuid, null::text, null::numeric, null::uuid, null::numeric, null::numeric, null::uuid, null::uuid, false, null::date, null::timestamptz, null::timestamptz, null::text, '{}'::jsonb; return;
    end if;
    if ov.id is null and (ts.shift_id is null or ts.status <> 'approved' or not exists (select 1 from public.shift_service_records sr where sr.shift_id = sh.id)) then
      return query select 'Waiting for delivery evidence (approved timesheet and the worker''s service record), or a delivery decision.'::text, null::uuid, null::text, null::text, null::int, null::int, null::numeric, null::text, null::numeric, null::numeric, null::uuid, null::uuid, null::text, null::numeric, null::uuid, null::numeric, null::numeric, null::uuid, null::uuid, false, null::date, null::timestamptz, null::timestamptz, null::text, '{}'::jsonb; return;
    end if;
    if ts.shift_id is not null and ts.status = 'approved' then
      v_start := ts.actual_start; v_end := ts.actual_end; v_break := coalesce(ts.break_minutes, 0);
    else
      v_start := sh.starts_at; v_end := sh.ends_at; v_break := coalesce(sh.break_minutes, 0);
    end if;
  end if;
  v_date := (v_start at time zone 'Australia/Sydney')::date;
  select * into sv from public.client_services where id = sh.service_id;
  if sv.id is null then
    return query select 'The shift has no approved service.'::text, null::uuid, null::text, null::text, null::int, null::int, null::numeric, null::text, null::numeric, null::numeric, null::uuid, null::uuid, null::text, null::numeric, null::uuid, null::numeric, null::numeric, null::uuid, null::uuid, false, v_date, v_start, v_end, null::text, '{}'::jsonb; return;
  end if;
  if v_date < sv.start_date or (sv.end_date is not null and v_date > sv.end_date) then
    return query select 'The shift is outside the service''s dates.'::text, null::uuid, null::text, null::text, null::int, null::int, null::numeric, null::text, null::numeric, null::numeric, null::uuid, null::uuid, null::text, null::numeric, null::uuid, null::numeric, null::numeric, null::uuid, null::uuid, false, v_date, v_start, v_end, null::text, '{}'::jsonb; return;
  end if;
  select * into t from public.client_service_terms x
   where x.service_id = sv.id and x.status in ('approved', 'superseded') and x.approved_at is not null
     and x.effective_from <= v_date and (x.effective_to is null or x.effective_to >= v_date)
   order by x.effective_from desc limit 1;
  if t.id is null then
    return query select 'No approved billing terms for this service on that date.'::text, null::uuid, null::text, null::text, null::int, null::int, null::numeric, null::text, null::numeric, null::numeric, null::uuid, null::uuid, null::text, null::numeric, null::uuid, null::numeric, null::numeric, null::uuid, null::uuid, false, v_date, v_start, v_end, null::text, '{}'::jsonb; return;
  end if;
  select * into e from public.client_enrolments where id = t.enrolment_id;
  if (e.ends_on is not null and v_date > e.ends_on) or v_date < e.starts_on
     or (e.paused_from is not null and v_date >= e.paused_from and (e.paused_until is null or v_date <= e.paused_until)) then
    return query select 'The program enrolment wasn''t active (ended, paused or not started) on that date.'::text, t.id, null::text, null::text, null::int, null::int, null::numeric, null::text, null::numeric, null::numeric, null::uuid, null::uuid, null::text, null::numeric, null::uuid, null::numeric, null::numeric, null::uuid, null::uuid, false, v_date, v_start, v_end, null::text, '{}'::jsonb; return;
  end if;
  v_scheme := e.scheme;
  if not exists (select 1 from public.billing_scheme_rules x where x.scheme = v_scheme and x.status = 'confirmed') then
    return query select ('Billing rules for this scheme (' || v_scheme || ') aren''t confirmed yet.')::text, t.id, null::text, null::text, null::int, null::int, null::numeric, null::text, null::numeric, null::numeric, null::uuid, null::uuid, null::text, null::numeric, null::uuid, null::numeric, null::numeric, null::uuid, null::uuid, false, v_date, v_start, v_end, null::text, '{}'::jsonb; return;
  end if;
  select * into ver from public.price_list_versions x
   where x.price_list_id = t.price_list_id and x.status in ('published', 'retired') and x.effective_from <= v_date
   order by x.effective_from desc limit 1;
  if ver.id is null then
    return query select 'No published price list version in force on that date for these terms.'::text, t.id, null::text, null::text, null::int, null::int, null::numeric, null::text, null::numeric, null::numeric, null::uuid, null::uuid, null::text, null::numeric, null::uuid, null::numeric, null::numeric, null::uuid, null::uuid, false, v_date, v_start, v_end, null::text, '{}'::jsonb; return;
  end if;
  select l.state into v_state from public.client_locations l where l.id = coalesce(sh.location_id, sv.location_id);
  if v_state is null or v_state = '' then
    return query select 'The service location has no state (needed for public holidays).'::text, t.id, null::text, null::text, null::int, null::int, null::numeric, null::text, null::numeric, null::numeric, null::uuid, ver.id, null::text, null::numeric, null::uuid, null::numeric, null::numeric, null::uuid, null::uuid, false, v_date, v_start, v_end, null::text, '{}'::jsonb; return;
  end if;
  -- Contribution (Support at Home only).
  if v_scheme = 'support_at_home' then
    if t.personal_care then
      v_pct := 0;
    else
      select * into v_rate from public.client_contribution_rates x
       where x.enrolment_id = e.id and x.category = t.sah_category and x.effective_from <= v_date and (x.effective_to is null or x.effective_to >= v_date)
       order by x.effective_from desc limit 1;
      if v_rate.id is null then
        return query select ('No contribution rate recorded for the ' || coalesce(t.sah_category, '?') || ' category on that date.')::text, t.id, null::text, null::text, null::int, null::int, null::numeric, null::text, null::numeric, null::numeric, null::uuid, ver.id, null::text, null::numeric, null::uuid, null::numeric, null::numeric, null::uuid, null::uuid, false, v_date, v_start, v_end, v_state, '{}'::jsonb; return;
      end if;
      v_pct := v_rate.rate_pct;
    end if;
    if t.funding_stream = 'ongoing' then
      select * into v_budget from public.client_quarter_budgets x
       where x.enrolment_id = e.id and x.status = 'approved' and x.quarter_start <= v_date and x.quarter_end >= v_date and x.start_date <= v_date;
      if v_budget.id is null then
        return query select 'No approved (open) Support at Home quarter budget covers that date.'::text, t.id, null::text, null::text, null::int, null::int, null::numeric, null::text, null::numeric, null::numeric, null::uuid, ver.id, null::text, null::numeric, null::uuid, null::numeric, null::numeric, null::uuid, null::uuid, false, v_date, v_start, v_end, v_state, '{}'::jsonb; return;
      end if;
    end if;
  end if;
  if v_budget.id is null and t.funding_id is not null then
    if exists (select 1 from public.client_funding f where f.id = t.funding_id and f.status = 'active' and f.period_start <= v_date and f.period_end >= v_date) then
      v_funding := t.funding_id;
    end if;
  end if;
  -- Minutes in each rate band (Sydney time; holidays of the location's state).
  create temporary table if not exists pg_temp.billing_mins (band text, label text, mins integer) on commit drop;
  delete from pg_temp.billing_mins where true; -- (API calls refuse a DELETE without WHERE)
  insert into pg_temp.billing_mins
  select b.key, b.label, count(*)::int
    from generate_series(v_start, v_end - interval '1 minute', interval '1 minute') g(m)
    cross join lateral (select (g.m at time zone 'Australia/Sydney') as lt) x
    join public.price_list_bands b on b.version_id = ver.id and b.day_kind = case
         when exists (select 1 from public.public_holidays h where h.state = v_state and h.on_date = x.lt::date and h.active) then 'public_holiday'
         when extract(isodow from x.lt) = 6 then 'saturday'
         when extract(isodow from x.lt) = 7 then 'sunday'
         else 'weekday' end
     and (b.day_kind <> 'weekday' or (x.lt::time >= b.starts_at and (x.lt::time < b.ends_at or b.ends_at = '00:00')))
   group by b.key, b.label;
  select coalesce(sum(mins), 0) into v_total from pg_temp.billing_mins;
  if v_total = 0 or v_total < extract(epoch from (v_end - v_start)) / 60 then
    return query select 'The price list''s rate bands don''t cover the whole shift.'::text, t.id, null::text, null::text, null::int, null::int, null::numeric, null::text, null::numeric, null::numeric, null::uuid, ver.id, null::text, null::numeric, null::uuid, null::numeric, null::numeric, null::uuid, null::uuid, false, v_date, v_start, v_end, v_state, '{}'::jsonb; return;
  end if;
  -- The unpaid break comes off the band with the most minutes.
  update pg_temp.billing_mins set mins = greatest(mins - v_break, 0)
   where band = (select band from pg_temp.billing_mins order by mins desc, band limit 1);
  -- Every band needs a price for this service.
  for r in select m.band, m.label, m.mins from pg_temp.billing_mins m where m.mins > 0 loop
    select * into v_item from public.price_items i
     where i.version_id = ver.id and (i.catalogue_id = sv.catalogue_id or (i.catalogue_id is null and lower(i.label) = lower(sv.label)))
       and (i.band_key = r.band or i.band_key is null)
     order by (i.band_key is null), i.label limit 1;
    if v_item.id is null then
      return query select ('No price for "' || sv.label || '" in the ' || r.label || ' band.')::text, t.id, r.band, r.label, null::int, null::int, null::numeric, null::text, null::numeric, null::numeric, null::uuid, ver.id, null::text, null::numeric, null::uuid, null::numeric, null::numeric, null::uuid, null::uuid, false, v_date, v_start, v_end, v_state, '{}'::jsonb; return;
    end if;
  end loop;
  -- Whole shift at the highest band, if the price list says so.
  if ver.crossing = 'whole_highest' then
    select m.band into v_top from pg_temp.billing_mins m
      join lateral (select i.price from public.price_items i where i.version_id = ver.id and (i.catalogue_id = sv.catalogue_id or (i.catalogue_id is null and lower(i.label) = lower(sv.label))) and (i.band_key = m.band or i.band_key is null) order by (i.band_key is null) limit 1) p on true
     where m.mins > 0 order by p.price desc limit 1;
    update pg_temp.billing_mins set mins = case when band = v_top then (select sum(mins) from pg_temp.billing_mins) else 0 end where true;
  end if;
  -- Minimum charge: added to the band with the most minutes.
  select coalesce(sum(mins), 0) into v_total from pg_temp.billing_mins;
  v_extra := greatest(ver.minimum_minutes - v_total, 0);
  -- Lines.
  v_billed_total := 0;
  for r in select m.band, m.label, m.mins + case when m.band = (select band from pg_temp.billing_mins order by mins desc, band limit 1) then v_extra else 0 end as mins, m.mins as actual
             from pg_temp.billing_mins m where m.mins > 0 or (m.band = (select band from pg_temp.billing_mins order by mins desc, band limit 1) and v_extra > 0) order by m.band loop
    select * into v_item from public.price_items i
     where i.version_id = ver.id and (i.catalogue_id = sv.catalogue_id or (i.catalogue_id is null and lower(i.label) = lower(sv.label)))
       and (i.band_key = r.band or i.band_key is null)
     order by (i.band_key is null), i.label limit 1;
    if v_item.unit = 'hour' then
      -- Rounding to the version's unit (nearest, up or down).
      r.mins := case ver.rounding
        when 'up' then ceil(r.mins::numeric / ver.unit_minutes) * ver.unit_minutes
        when 'down' then floor(r.mins::numeric / ver.unit_minutes) * ver.unit_minutes
        else round(r.mins::numeric / ver.unit_minutes) * ver.unit_minutes end;
      v_qty := round(r.mins::numeric / 60, 2);
    else
      -- Per visit (or each, day): one unit for the shift, on its main band only.
      if v_billed_total > 0 then continue; end if;
      v_qty := 1;
    end if;
    v_billed_total := v_billed_total + r.mins;
    v_amt := round(v_qty * v_item.price, 2);
    if v_scheme = 'support_at_home' then
      v_client := round(v_amt * v_pct / 100, 2);
    elsif v_scheme = 'private' then
      v_client := v_amt;
    elsif v_scheme = 'ndis' then
      v_client := 0;
    else
      v_client := null; -- CHSP and Other: per the scheme's confirmed rules, not calculated here
    end if;
    v_running := v_running + v_amt;
    if v_budget.id is not null then
      select available into v_avail from public.funding_balances where account_kind = 'quarter_budget' and account_id = v_budget.id;
      v_avail := coalesce(v_avail, v_budget.spendable)
               - coalesce((select sum(bl.amount) from public.billing_lines bl where bl.quarter_budget_id = v_budget.id and bl.status = 'draft'), 0);
    elsif v_funding is not null then
      select available into v_avail from public.funding_balances where account_kind = 'funding' and account_id = v_funding;
      v_avail := coalesce(v_avail, 0) - coalesce((select sum(bl.amount) from public.billing_lines bl where bl.funding_id = v_funding and bl.status = 'draft'), 0);
    else
      v_avail := null;
    end if;
    return query select null::text, t.id, r.band, r.label, r.actual::int, r.mins::int, v_qty, v_item.unit, v_item.price, v_amt, v_item.id, ver.id, v_item.gst_code,
      case when v_scheme = 'support_at_home' then v_pct end, v_rate.id, v_client, case when v_client is null then null else v_amt - v_client end,
      v_budget.id, case when v_budget.id is null then v_funding end, (v_avail is not null and v_avail < v_running), v_date, v_start, v_end, v_state,
      jsonb_build_object('price_list_version', ver.version, 'unit_minutes', ver.unit_minutes, 'rounding', ver.rounding, 'minimum_minutes', ver.minimum_minutes,
        'crossing', ver.crossing, 'break_minutes', v_break, 'times_from', case when p_kind = 'cancellation' then 'roster (cancellation)' when ts.status = 'approved' then 'approved timesheet' else 'roster (delivery decision)' end,
        'delivery_decision', ov.id, 'scheme', v_scheme, 'available_before', v_avail, 'minimum_added', case when r.band = (select band from pg_temp.billing_mins order by mins desc, band limit 1) then v_extra else 0 end);
  end loop;
end;
$$;

create or replace function public.billing_generate(p_from date, p_to date, p_client uuid default null) returns jsonb
language plpgsql set search_path = '' as $$
declare
  s record;
  c record;
  v_made integer := 0;
  v_skipped integer := 0;
  v_problems integer := 0;
  v_kind text;
  sv public.client_services;
begin
  if public.from_portal() and not public.billing_can('prepare', p_client) then
    raise exception 'Only someone who can prepare billing makes billing lines.';
  end if;
  if p_to < p_from or p_to - p_from > 92 then
    raise exception 'Choose a period of up to three months.';
  end if;
  perform set_config('portal.billing_generate', 'on', true);
  for s in select sh.id, sh.client_id, sh.status from public.shifts sh
            where sh.client_id is not null and (p_client is null or sh.client_id = p_client)
              and (sh.starts_at at time zone 'Australia/Sydney')::date between p_from and p_to
              and (sh.status = 'published' or (sh.status = 'cancelled' and exists (select 1 from public.shift_cancellations x where x.shift_id = sh.id and x.charge = 'charge')))
              and sh.starts_at <= now()
            order by sh.starts_at loop
    if public.from_portal() and not public.billing_can('prepare', s.client_id) then
      continue;
    end if;
    v_kind := case when s.status = 'cancelled' then 'cancellation' else 'service' end;
    for c in select * from public.billing_calc(s.id, v_kind) loop
      if c.problem is not null then
        v_problems := v_problems + 1;
        exit;
      end if;
      if exists (select 1 from public.billing_lines bl where bl.shift_id = s.id and bl.kind = v_kind and bl.terms_id = c.terms_id and bl.band_key = c.band_key and bl.status <> 'voided') then
        v_skipped := v_skipped + 1;
        continue;
      end if;
      select * into sv from public.client_services where id = (select service_id from public.shifts where id = s.id);
      insert into public.billing_lines (client_id, shift_id, kind, scheme, service_id, terms_id, enrolment_id, funding_id, agreement_id, quarter_budget_id, funding_stream,
        price_list_version_id, price_item_id, band_key, band_label, service_date, starts_at, ends_at, minutes_actual, minutes_billed, unit, quantity, unit_price, amount, gst_code,
        sah_category, personal_care, contribution_rate_id, contribution_pct, client_share, government_share, holiday_state, over_budget, calc, corrects_id)
      select s.client_id, s.id, v_kind, e.scheme, sv.id, c.terms_id, t.enrolment_id, c.funding_id, t.agreement_id, c.quarter_budget_id, t.funding_stream,
        c.price_list_version_id, c.price_item_id, c.band_key, c.band_label, c.service_date, c.starts_at, c.ends_at, c.minutes_actual, c.minutes_billed, c.unit, c.quantity, c.unit_price, c.amount, c.gst_code,
        t.sah_category, t.personal_care, c.contribution_rate_id, c.contribution_pct, c.client_share, c.government_share, c.holiday_state, c.over_budget, c.calc,
        (select bl.id from public.billing_lines bl where bl.shift_id = s.id and bl.kind = v_kind and bl.band_key = c.band_key and bl.status = 'voided' order by bl.voided_at desc limit 1)
        from public.client_service_terms t join public.client_enrolments e on e.id = t.enrolment_id where t.id = c.terms_id;
      v_made := v_made + 1;
    end loop;
  end loop;
  perform set_config('portal.billing_generate', 'off', true);
  return jsonb_build_object('made', v_made, 'already_made', v_skipped, 'with_problems', v_problems);
end;
$$;

create or replace function public.billing_exceptions(p_from date, p_to date, p_client uuid default null)
returns table (shift_id uuid, client_id uuid, service_id uuid, starts_at timestamptz, kind text, problem text)
language plpgsql set search_path = '' as $$
#variable_conflict use_column
declare
  s record;
  c record;
  v_kind text;
begin
  for s in select sh.id, sh.client_id, sh.service_id, sh.starts_at, sh.status from public.shifts sh
            where sh.client_id is not null and (p_client is null or sh.client_id = p_client)
              and (sh.starts_at at time zone 'Australia/Sydney')::date between p_from and p_to and sh.starts_at <= now()
              and (sh.status = 'published' or (sh.status = 'cancelled' and exists (select 1 from public.shift_cancellations x where x.shift_id = sh.id and x.charge = 'charge')))
              and public.billing_can('view', sh.client_id)
            order by sh.starts_at loop
    v_kind := case when s.status = 'cancelled' then 'cancellation' else 'service' end;
    for c in select * from public.billing_calc(s.id, v_kind) loop
      if c.problem is not null then
        shift_id := s.id; client_id := s.client_id; service_id := s.service_id; starts_at := s.starts_at; kind := v_kind; problem := c.problem;
        return next;
      elsif c.over_budget and not exists (select 1 from public.billing_lines bl where bl.shift_id = s.id and bl.status = 'approved') then
        shift_id := s.id; client_id := s.client_id; service_id := s.service_id; starts_at := s.starts_at; kind := v_kind; problem := 'Over the available budget: needs a private agreement or write-off note when approved.';
        return next;
      end if;
      exit;
    end loop;
  end loop;
end;
$$;

create or replace function public.billing_close_quarter(p_budget uuid) returns jsonb
language plpgsql set search_path = '' as $$
declare
  b public.client_quarter_budgets;
  v_spent numeric;
  v_unspent numeric;
  v_carry numeric;
  v_lapse numeric;
begin
  select * into b from public.client_quarter_budgets where id = p_budget;
  if b.id is null or b.status <> 'approved' then
    raise exception 'Only an approved, open quarter can be closed.';
  end if;
  if public.from_portal() and not public.billing_can('approve', b.client_id) then
    raise exception 'Only someone with the Billing approve right closes a quarter.';
  end if;
  if (now() at time zone 'Australia/Sydney')::date <= b.quarter_end then
    raise exception 'The quarter hasn''t ended yet.';
  end if;
  if exists (select 1 from public.billing_lines bl where bl.quarter_budget_id = b.id and bl.status = 'draft') then
    raise exception 'Approve or void the quarter''s draft billing lines first.';
  end if;
  if exists (select 1 from public.funding_ledger l where l.quarter_budget_id = b.id and l.status = 'proposed') then
    raise exception 'Decide the quarter''s proposed adjustments first.';
  end if;
  select coalesce(-sum(amount) filter (where entry_kind in ('charge', 'reversal')), 0) into v_spent from public.funding_ledger where quarter_budget_id = b.id and status = 'approved';
  select b.spendable + coalesce(sum(amount), 0) into v_unspent from public.funding_ledger where quarter_budget_id = b.id and status = 'approved';
  -- Carryover: the smaller of the unspent amount and the larger of the floor and the % of the quarterly amount. Never negative.
  v_carry := least(greatest(v_unspent, 0), greatest(b.rollover_floor, round(b.quarterly_amount * b.rollover_pct / 100, 2)));
  v_lapse := greatest(v_unspent, 0) - v_carry;
  perform set_config('portal.billing_close', 'on', true);
  if v_carry > 0 then
    insert into public.funding_ledger (client_id, quarter_budget_id, entry_kind, amount, entry_date, reason)
    values (b.client_id, b.id, 'carryover_out', -v_carry, b.quarter_end, 'Carried to the next quarter');
  end if;
  if v_lapse > 0 then
    insert into public.funding_ledger (client_id, quarter_budget_id, entry_kind, amount, entry_date, reason)
    values (b.client_id, b.id, 'lapse', -v_lapse, b.quarter_end, 'Above the rollover cap: returned to the government');
  end if;
  update public.client_quarter_budgets set status = 'closed', closed_by = auth.uid(), closed_at = now(), spent = v_spent, unspent = v_unspent, carryover_out = v_carry, lapsed = v_lapse
   where id = b.id;
  perform set_config('portal.billing_close', 'off', true);
  return jsonb_build_object('spent', v_spent, 'unspent', v_unspent, 'carryover', v_carry, 'lapsed', v_lapse);
end;
$$;

alter table public.billing_parameters enable row level security;
alter table public.billing_delivery_overrides enable row level security;
alter table public.client_quarter_budgets enable row level security;
alter table public.funding_ledger enable row level security;
alter table public.billing_lines enable row level security;
do $$
declare
  t text;
begin
  drop policy if exists "billing see figures" on public.billing_parameters;
  create policy "billing see figures" on public.billing_parameters for select to authenticated using (public.billing_can('view'));
  drop policy if exists "billing add figures" on public.billing_parameters;
  create policy "billing add figures" on public.billing_parameters for insert to authenticated with check (public.billing_can('approve'));
  drop policy if exists "billing change figures" on public.billing_parameters;
  create policy "billing change figures" on public.billing_parameters for update to authenticated using (public.billing_can('approve')) with check (public.billing_can('approve'));
  grant select, insert, update on public.billing_parameters to authenticated;
  revoke all on public.billing_parameters from anon;

  foreach t in array array['billing_delivery_overrides', 'client_quarter_budgets', 'funding_ledger', 'billing_lines'] loop
    execute format('drop policy if exists "billing see %s" on public.%I', t, t);
    execute format('create policy "billing see %s" on public.%I for select to authenticated using (public.billing_can(''view'', client_id))', t, t);
    execute format('drop policy if exists "billing add %s" on public.%I', t, t);
    execute format('create policy "billing add %s" on public.%I for insert to authenticated with check (public.billing_can(''prepare'', client_id) or public.billing_can(''approve'', client_id))', t, t);
    execute format('drop policy if exists "billing change %s" on public.%I', t, t);
    execute format('create policy "billing change %s" on public.%I for update to authenticated using (public.billing_can(''prepare'', client_id) or public.billing_can(''approve'', client_id)) with check (public.billing_can(''prepare'', client_id) or public.billing_can(''approve'', client_id))', t, t);
    execute format('grant select, insert, update on public.%I to authenticated', t);
    execute format('revoke all on public.%I from anon', t);
  end loop;
  drop policy if exists "billing remove draft budgets" on public.client_quarter_budgets;
  create policy "billing remove draft budgets" on public.client_quarter_budgets for delete to authenticated using (public.billing_can('prepare', client_id));
  grant delete on public.client_quarter_budgets to authenticated;
  grant select on public.funding_balances to authenticated;
  revoke all on public.funding_balances from anon;
end $$;
revoke execute on function public.billing_generate(date, date, uuid) from public, anon;
grant execute on function public.billing_generate(date, date, uuid) to authenticated;
revoke execute on function public.billing_close_quarter(uuid) from public, anon;
grant execute on function public.billing_close_quarter(uuid) to authenticated;
revoke execute on function public.billing_exceptions(date, date, uuid) from public, anon;
grant execute on function public.billing_exceptions(date, date, uuid) to authenticated;
revoke execute on function public.billing_calc(uuid, text) from public, anon;
grant execute on function public.billing_calc(uuid, text) to authenticated;

do $$
declare
  t text;
begin
  drop trigger if exists guard_billing_parameter on public.billing_parameters;
  create trigger guard_billing_parameter before insert or update or delete on public.billing_parameters for each row execute function public.guard_billing_parameter();
  drop trigger if exists log_billing_setup on public.billing_parameters;
  create trigger log_billing_setup after insert or update or delete on public.billing_parameters for each row execute function public.log_car_setup('billing_parameter');
  drop trigger if exists stamp_billing_setup on public.billing_parameters;
  create trigger stamp_billing_setup before insert or update on public.billing_parameters for each row execute function public.stamp_billing_updated();
  drop trigger if exists guard_delivery_override on public.billing_delivery_overrides;
  create trigger guard_delivery_override before insert or update or delete on public.billing_delivery_overrides for each row execute function public.guard_delivery_override();
  drop trigger if exists guard_quarter_budget on public.client_quarter_budgets;
  create trigger guard_quarter_budget before insert or update or delete on public.client_quarter_budgets for each row execute function public.guard_quarter_budget();
  drop trigger if exists guard_funding_ledger on public.funding_ledger;
  create trigger guard_funding_ledger before insert or update or delete on public.funding_ledger for each row execute function public.guard_funding_ledger();
  drop trigger if exists guard_billing_line on public.billing_lines;
  create trigger guard_billing_line before insert or update or delete on public.billing_lines for each row execute function public.guard_billing_line();
  drop trigger if exists ledger_from_line on public.billing_lines;
  create trigger ledger_from_line after update on public.billing_lines for each row execute function public.ledger_from_line();
  foreach t in array array['billing_delivery_overrides', 'client_quarter_budgets', 'funding_ledger', 'billing_lines'] loop
    execute format('drop trigger if exists log_client_change on public.%I', t);
    execute format('create trigger log_client_change before insert or update on public.%I for each row execute function public.log_client_change()', t);
    execute format('drop trigger if exists log_client_audit on public.%I', t);
    execute format('create trigger log_client_audit after insert or update or delete on public.%I for each row execute function public.log_client_change()', t);
  end loop;
end $$;

revoke execute on function public.guard_billing_parameter() from public, anon, authenticated;
revoke execute on function public.guard_delivery_override() from public, anon, authenticated;
revoke execute on function public.guard_quarter_budget() from public, anon, authenticated;
revoke execute on function public.guard_funding_ledger() from public, anon, authenticated;
revoke execute on function public.guard_billing_line() from public, anon, authenticated;
revoke execute on function public.ledger_from_line() from public, anon, authenticated;
commit;
