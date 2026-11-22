-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 164): Phase 5B. Claim results, payments and receipts, credit notes,
-- refunds, write-offs and bank reconciliation (D-066; built under D-068).
--   * Claim results per claim line: accepted, partly accepted or rejected, recorded from the
--     government's result by someone with the claim submit right. Results are added, never
--     changed (a correction is a new result with a reason). Accepted amounts are never
--     claimed again; fully rejected lines can go in a replacement claim linked to the original.
--   * Payments received (from Services Australia, the NDIA, plan managers, participants and
--     clients) with allocations to invoices or accepted claim lines; never more than the payment
--     or than what's owed. Client payments get a receipt number (RCT-YYYY-000001).
--   * Credit notes against issued invoices (CN-YYYY-000001): prepared, approved by someone else,
--     issued with a PDF; never more than the invoice. A line fully credited (or fully rejected
--     by the government) can then be voided and remade.
--   * Refunds of credit (payer overpayments): proposed, approved by someone else with the refund
--     right, then recorded as paid.
--   * Write-offs: proposed, approved by someone else with the write-off right; above the
--     business's threshold (default $500) a second, different approver is needed.
--   * Bank reconciliation: bank statement lines imported, each matched to one payment or refund
--     (or excluded with a reason); a period is completed only when everything in it is matched
--     or excluded and the balances agree. Completed periods don't change.
-- New Billing actions: payment_record, refund, write_off, reconcile. No new security definer
-- function. Safe to run again.

-- 0. Actions.
update public.app_modules set actions = actions || array['payment_record', 'refund', 'write_off', 'reconcile']
 where id = 'clients.billing' and not ('payment_record' = any (actions));

-- 1. Numbering for credit notes and receipts (per year, never reused).
create table if not exists public.billing_number_counters (
  kind text not null check (kind in ('credit_note', 'receipt')),
  year integer not null,
  last_number integer not null default 0,
  primary key (kind, year)
);
create or replace function public.billing_next_number(p_kind text, p_prefix text) returns text
language plpgsql set search_path = '' as $$
declare
  v_year integer := extract(year from (now() at time zone 'Australia/Sydney'))::int;
  v_n integer;
begin
  insert into public.billing_number_counters (kind, year, last_number) values (p_kind, v_year, 1)
    on conflict (kind, year) do update set last_number = public.billing_number_counters.last_number + 1
    returning last_number into v_n;
  return p_prefix || '-' || v_year || '-' || lpad(v_n::text, 6, '0');
end;
$$;

-- 2. Claim results and replacement claims.
alter table public.claim_items add column if not exists replaces_item_id uuid references public.claim_items (id);
alter table public.claim_items drop constraint if exists claim_items_source;
alter table public.claim_items add constraint claim_items_source check (
  (replaces_item_id is null and ((line_id is not null and recovery_id is not null and quarter_budget_id is null) or (line_id is null and recovery_id is null and quarter_budget_id is not null)))
  or (replaces_item_id is not null and recovery_id is null and ((line_id is not null) <> (quarter_budget_id is not null))));
drop index if exists public.claim_items_one_care_management;
create unique index if not exists claim_items_one_care_management on public.claim_items (quarter_budget_id) where status = 'live' and replaces_item_id is null;

create table if not exists public.claim_item_results (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  claim_item_id uuid not null references public.claim_items (id),
  claim_id uuid not null references public.claims (id),
  client_id uuid not null references public.car_clients (id),
  outcome text not null check (outcome in ('accepted', 'partly_accepted', 'rejected')),
  accepted_amount numeric(12, 2) not null check (accepted_amount >= 0),
  reason_code text not null default '' check (length(reason_code) <= 60),
  reason text not null default '' check (length(reason) <= 1000),
  source_reference text not null default '' check (length(source_reference) <= 120),
  corrects_id uuid references public.claim_item_results (id),
  recorded_by uuid default auth.uid(),
  recorded_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now()
);
-- The result in force for each claim line (the latest).
create or replace view public.claim_item_outcomes with (security_invoker = true) as
  select distinct on (r.claim_item_id) r.claim_item_id, r.claim_id, r.client_id, r.outcome, r.accepted_amount, r.reason_code, r.reason, r.recorded_at, r.id as result_id
    from public.claim_item_results r order by r.claim_item_id, r.recorded_at desc, r.id desc;

create or replace function public.guard_claim_result() returns trigger
language plpgsql set search_path = '' as $$
declare
  i public.claim_items;
  v_status text;
  v_paid numeric;
begin
  if tg_op <> 'INSERT' then raise exception 'Claim results are never changed or deleted. Record a correction instead.'; end if;
  if public.from_portal() and not public.billing_can('claim_submit') then raise exception 'Only someone with the claim submit right records claim results.'; end if;
  select * into i from public.claim_items where id = new.claim_item_id;
  select status into v_status from public.claims where id = i.claim_id;
  if v_status not in ('submitted', 'acknowledged') or i.status <> 'live' then raise exception 'Results are recorded for lines of a submitted claim.'; end if;
  new.claim_id := i.claim_id; new.client_id := i.client_id; new.recorded_by := auth.uid(); new.recorded_at := now();
  if new.accepted_amount > i.claimed_value then raise exception 'The accepted amount can''t be more than was claimed.'; end if;
  if (new.outcome = 'accepted' and new.accepted_amount <> i.claimed_value) or (new.outcome = 'rejected' and new.accepted_amount <> 0)
     or (new.outcome = 'partly_accepted' and (new.accepted_amount = 0 or new.accepted_amount = i.claimed_value)) then
    raise exception 'Accepted means the full amount, rejected means nothing, partly accepted is in between.';
  end if;
  if new.outcome <> 'accepted' and length(trim(new.reason)) = 0 and length(trim(new.reason_code)) = 0 then raise exception 'Record the reason or code the government gave.'; end if;
  if exists (select 1 from public.claim_item_results r where r.claim_item_id = new.claim_item_id) then
    if new.corrects_id is null or new.corrects_id <> (select result_id from public.claim_item_outcomes o where o.claim_item_id = new.claim_item_id) then
      raise exception 'This line already has a result. A correction must point to the result in force.';
    end if;
    if length(trim(new.reason)) = 0 then raise exception 'Say why the result is corrected.'; end if;
  elsif new.corrects_id is not null then
    raise exception 'There''s no result to correct yet.';
  end if;
  select coalesce(sum(a.amount), 0) into v_paid from public.payment_allocations a join public.payments p on p.id = a.payment_id where a.claim_item_id = new.claim_item_id and p.status = 'recorded';
  if new.accepted_amount < v_paid then raise exception 'More than that has already been paid against this line.'; end if;
  if exists (select 1 from public.claim_items x join public.claims c on c.id = x.claim_id where x.replaces_item_id = new.claim_item_id and x.status = 'live' and c.status <> 'cancelled') then
    raise exception 'This line is in a replacement claim. Record results there.';
  end if;
  return new;
end;
$$;

-- Claim lines: replacement lines (fully rejected lines claimed again) are added by "Claim rejected lines again".
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
      if (new.line_id, new.quarter_budget_id, new.client_id) is distinct from (o.line_id, o.quarter_budget_id, o.client_id) then
        raise exception 'A replacement line is for the same service as the line it replaces.';
      end if;
      if exists (select 1 from public.claim_items x join public.claims c on c.id = x.claim_id where x.replaces_item_id = o.id and x.status = 'live' and c.status <> 'cancelled') then
        raise exception 'That line is already in a replacement claim.';
      end if;
      if o.line_id is not null and (select status from public.billing_lines where id = o.line_id) <> 'approved' then
        raise exception 'That billing line was voided. Claim its corrected line instead.';
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

-- Make a replacement claim from a submitted claim's fully rejected lines.
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
              and not exists (select 1 from public.write_offs w where w.claim_item_id = x.id and w.status not in ('rejected')) loop
    if v_new is null then
      insert into public.claims (program, payer_id, kind, replaces_claim_id, period_from, period_to, template_id)
      values (c.program, c.payer_id, 'replacement', c.id, c.period_from, c.period_to, v_tpl) returning id into v_new;
    end if;
    insert into public.claim_items (claim_id, line_id, quarter_budget_id, client_id, claimed_value, expected_amount, replaces_item_id)
    values (v_new, i.line_id, i.quarter_budget_id, i.client_id, i.claimed_value, i.expected_amount, i.id);
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

-- 3. Payments, receipts and allocations.
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  payer_id uuid not null references public.billing_payers (id),
  client_id uuid references public.car_clients (id),
  received_on date not null,
  amount numeric(12, 2) not null check (amount > 0),
  method text not null check (method in ('eft', 'bpay', 'card', 'cash', 'cheque', 'government_remittance', 'other')),
  reference text not null default '' check (length(reference) <= 120),
  receipt_number text unique,
  status text not null default 'recorded' check (status in ('recorded', 'reversed')),
  reversal_reason text not null default '' check (length(reversal_reason) <= 500),
  receipt_pdf_base64 text,
  receipt_pdf_checksum text,
  recorded_by uuid default auth.uid(),
  recorded_at timestamptz not null default now(),
  reversed_by uuid, reversed_at timestamptz,
  notes text not null default '' check (length(notes) <= 1000),
  updated_by uuid,
  updated_at timestamptz not null default now()
);
create table if not exists public.payment_allocations (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  payment_id uuid not null references public.payments (id),
  invoice_id uuid references public.invoices (id),
  claim_item_id uuid references public.claim_items (id),
  client_id uuid not null references public.car_clients (id),
  amount numeric(12, 2) not null check (amount > 0),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  constraint payment_allocations_target check ((invoice_id is null) <> (claim_item_id is null))
);

-- 4. Credit notes.
create table if not exists public.credit_notes (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  number text unique,
  invoice_id uuid not null references public.invoices (id),
  client_id uuid not null references public.car_clients (id),
  payer_id uuid not null references public.billing_payers (id),
  reason text not null check (length(trim(reason)) between 1 and 1000),
  status text not null default 'draft' check (status in ('draft', 'approved', 'issued', 'cancelled')),
  amount numeric(12, 2) not null default 0,
  gst numeric(12, 2) not null default 0,
  issue_date date,
  snapshot jsonb,
  pdf_base64 text,
  pdf_checksum text,
  prepared_by uuid default auth.uid(),
  prepared_at timestamptz not null default now(),
  approved_by uuid, approved_at timestamptz,
  issued_by uuid, issued_at timestamptz,
  cancelled_by uuid, cancelled_at timestamptz, cancel_reason text not null default '' check (length(cancel_reason) <= 500),
  updated_by uuid,
  updated_at timestamptz not null default now()
);
create table if not exists public.credit_note_items (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  credit_note_id uuid not null references public.credit_notes (id),
  invoice_item_id uuid not null references public.invoice_items (id),
  client_id uuid not null references public.car_clients (id),
  amount numeric(12, 2) not null check (amount > 0),
  gst_amount numeric(12, 2) not null default 0,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  unique (credit_note_id, invoice_item_id)
);

-- 5. Write-offs and refunds.
create table if not exists public.write_offs (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  invoice_id uuid references public.invoices (id),
  claim_item_id uuid references public.claim_items (id),
  client_id uuid not null references public.car_clients (id),
  amount numeric(12, 2) not null check (amount > 0),
  reason text not null check (length(trim(reason)) between 1 and 1000),
  threshold numeric(12, 2),
  status text not null default 'proposed' check (status in ('proposed', 'first_approved', 'approved', 'rejected')),
  proposed_by uuid default auth.uid(),
  proposed_at timestamptz not null default now(),
  approved_by uuid, approved_at timestamptz,
  second_approved_by uuid, second_approved_at timestamptz,
  rejected_by uuid, rejected_at timestamptz, reject_reason text not null default '' check (length(reject_reason) <= 500),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  constraint write_offs_target check ((invoice_id is null) <> (claim_item_id is null))
);
create table if not exists public.refunds (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  payer_id uuid not null references public.billing_payers (id),
  client_id uuid references public.car_clients (id),
  payment_id uuid references public.payments (id),
  invoice_id uuid references public.invoices (id),
  amount numeric(12, 2) not null check (amount > 0),
  reason text not null check (length(trim(reason)) between 1 and 1000),
  status text not null default 'proposed' check (status in ('proposed', 'approved', 'paid', 'rejected')),
  proposed_by uuid default auth.uid(),
  proposed_at timestamptz not null default now(),
  approved_by uuid, approved_at timestamptz,
  paid_on date, paid_reference text not null default '' check (length(paid_reference) <= 120), paid_by uuid, paid_at timestamptz,
  rejected_by uuid, rejected_at timestamptz, reject_reason text not null default '' check (length(reject_reason) <= 500),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  constraint refunds_source check ((payment_id is null) <> (invoice_id is null))
);

-- 6. Balances (read only, worked out from the records above).
create or replace view public.invoice_balances with (security_invoker = true) as
  select v.id as invoice_id, v.client_id, v.payer_id, v.number, v.status, v.total, v.due_date,
         coalesce((select sum(n.amount) from public.credit_notes n where n.invoice_id = v.id and n.status = 'issued'), 0) as credited,
         coalesce((select sum(a.amount) from public.payment_allocations a join public.payments p on p.id = a.payment_id where a.invoice_id = v.id and p.status = 'recorded'), 0) as paid,
         coalesce((select sum(w.amount) from public.write_offs w where w.invoice_id = v.id and w.status = 'approved'), 0) as written_off,
         coalesce((select sum(r.amount) from public.refunds r where r.invoice_id = v.id and r.status in ('approved', 'paid')), 0) as refunded,
         v.total
           - coalesce((select sum(n.amount) from public.credit_notes n where n.invoice_id = v.id and n.status = 'issued'), 0)
           - coalesce((select sum(a.amount) from public.payment_allocations a join public.payments p on p.id = a.payment_id where a.invoice_id = v.id and p.status = 'recorded'), 0)
           - coalesce((select sum(w.amount) from public.write_offs w where w.invoice_id = v.id and w.status = 'approved'), 0)
           + coalesce((select sum(r.amount) from public.refunds r where r.invoice_id = v.id and r.status in ('approved', 'paid')), 0) as balance
    from public.invoices v where v.status in ('issued', 'sent');
create or replace view public.claim_item_balances with (security_invoker = true) as
  select i.id as claim_item_id, i.claim_id, i.client_id, i.claimed_value, o.outcome, coalesce(o.accepted_amount, 0) as accepted,
         coalesce((select sum(a.amount) from public.payment_allocations a join public.payments p on p.id = a.payment_id where a.claim_item_id = i.id and p.status = 'recorded'), 0) as paid,
         coalesce((select sum(w.amount) from public.write_offs w where w.claim_item_id = i.id and w.status = 'approved'), 0) as written_off,
         coalesce(o.accepted_amount, 0)
           - coalesce((select sum(a.amount) from public.payment_allocations a join public.payments p on p.id = a.payment_id where a.claim_item_id = i.id and p.status = 'recorded'), 0) as unpaid_accepted
    from public.claim_items i join public.claims c on c.id = i.claim_id left join public.claim_item_outcomes o on o.claim_item_id = i.id
   where i.status = 'live' and c.status in ('submitted', 'acknowledged');
-- A payment's amount not yet allocated (less refunds from it).
create or replace view public.payment_balances with (security_invoker = true) as
  select p.id as payment_id, p.payer_id, p.client_id, p.amount, p.status,
         coalesce((select sum(a.amount) from public.payment_allocations a where a.payment_id = p.id), 0) as allocated,
         coalesce((select sum(r.amount) from public.refunds r where r.payment_id = p.id and r.status in ('approved', 'paid')), 0) as refunded,
         p.amount - coalesce((select sum(a.amount) from public.payment_allocations a where a.payment_id = p.id), 0)
           - coalesce((select sum(r.amount) from public.refunds r where r.payment_id = p.id and r.status in ('approved', 'paid')), 0) as unallocated
    from public.payments p;

-- 7. Bank reconciliation.
create table if not exists public.bank_statement_lines (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  statement_date date not null,
  amount numeric(12, 2) not null check (amount <> 0),
  description text not null default '' check (length(description) <= 500),
  reference text not null default '' check (length(reference) <= 200),
  import_batch text not null default '' check (length(import_batch) <= 200),
  import_key text not null,
  status text not null default 'unmatched' check (status in ('unmatched', 'matched', 'excluded')),
  payment_id uuid references public.payments (id),
  refund_id uuid references public.refunds (id),
  exclude_reason text not null default '' check (length(exclude_reason) <= 500),
  matched_by uuid, matched_at timestamptz,
  imported_by uuid default auth.uid(),
  imported_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  unique (import_key)
);
create unique index if not exists bank_lines_one_payment on public.bank_statement_lines (payment_id) where payment_id is not null;
create unique index if not exists bank_lines_one_refund on public.bank_statement_lines (refund_id) where refund_id is not null;
create table if not exists public.bank_reconciliations (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  period_from date not null,
  period_to date not null,
  opening_balance numeric(14, 2) not null,
  closing_balance numeric(14, 2) not null,
  status text not null default 'draft' check (status in ('draft', 'completed')),
  notes text not null default '' check (length(notes) <= 1000),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  completed_by uuid, completed_at timestamptz,
  updated_by uuid,
  updated_at timestamptz not null default now(),
  constraint bank_reconciliations_period check (period_to >= period_from)
);

-- 8. Rules.
create or replace function public.guard_payment() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'DELETE' then raise exception 'Payments are never deleted. Reverse one with a reason.'; end if;
  if public.from_portal() and not public.billing_can('payment_record') then raise exception 'Only someone with the payment right records payments.'; end if;
  if tg_op = 'INSERT' then
    new.status := 'recorded'; new.recorded_by := auth.uid(); new.recorded_at := now(); new.receipt_number := null; new.receipt_pdf_base64 := null; new.receipt_pdf_checksum := null;
    if new.received_on > (now() at time zone 'Australia/Sydney')::date then raise exception 'The date received can''t be in the future.'; end if;
    if new.client_id is not null and not exists (select 1 from public.billing_payers b where b.id = new.payer_id and (b.client_id is null or b.client_id = new.client_id)) then
      raise exception 'That payer isn''t this client''s.';
    end if;
    -- Client and participant payments get a receipt number.
    if (select kind from public.billing_payers where id = new.payer_id) in ('client', 'participant', 'other') then
      new.receipt_number := public.billing_next_number('receipt', 'RCT');
    end if;
    return new;
  end if;
  if (to_jsonb(new) - array['status', 'reversal_reason', 'reversed_by', 'reversed_at', 'receipt_pdf_base64', 'receipt_pdf_checksum', 'notes', 'updated_by', 'updated_at'])
     is distinct from (to_jsonb(old) - array['status', 'reversal_reason', 'reversed_by', 'reversed_at', 'receipt_pdf_base64', 'receipt_pdf_checksum', 'notes', 'updated_by', 'updated_at']) then
    raise exception 'A payment never changes. Reverse it and record it again.';
  end if;
  if old.receipt_pdf_base64 is not null and new.receipt_pdf_base64 is distinct from old.receipt_pdf_base64 then raise exception 'An issued receipt never changes.'; end if;
  if new.status is distinct from old.status then
    if not (old.status = 'recorded' and new.status = 'reversed') then raise exception 'A payment can only be reversed.'; end if;
    if length(trim(new.reversal_reason)) = 0 then raise exception 'Say why the payment is reversed (for example, dishonoured).'; end if;
    if exists (select 1 from public.bank_statement_lines l where l.payment_id = old.id) then raise exception 'This payment is matched to a bank line. Unmatch it first.'; end if;
    if exists (select 1 from public.refunds r where r.payment_id = old.id and r.status in ('approved', 'paid')) then raise exception 'A refund was made from this payment.'; end if;
    new.reversed_by := auth.uid(); new.reversed_at := now();
  end if;
  return new;
end;
$$;

create or replace function public.guard_payment_allocation() returns trigger
language plpgsql set search_path = '' as $$
declare
  p public.payments;
  v_owed numeric;
begin
  if tg_op <> 'INSERT' then raise exception 'Allocations never change. Reverse the payment instead.'; end if;
  if public.from_portal() and not public.billing_can('payment_record') then raise exception 'Only someone with the payment right allocates payments.'; end if;
  select * into p from public.payments where id = new.payment_id for update;
  if p.status <> 'recorded' then raise exception 'That payment was reversed.'; end if;
  if new.amount > (select unallocated from public.payment_balances where payment_id = p.id) then raise exception 'That''s more than is left of the payment.'; end if;
  if new.invoice_id is not null then
    select b.balance, b.client_id into v_owed, new.client_id from public.invoice_balances b where b.invoice_id = new.invoice_id;
    if v_owed is null then raise exception 'Payments go against issued invoices.'; end if;
    if (select payer_id from public.invoices where id = new.invoice_id) <> p.payer_id then raise exception 'The invoice is for a different payer.'; end if;
  else
    select b.accepted - b.paid - b.written_off, b.client_id into v_owed, new.client_id from public.claim_item_balances b where b.claim_item_id = new.claim_item_id;
    if v_owed is null then raise exception 'Payments go against lines of a submitted claim.'; end if;
    if (select c.payer_id from public.claim_items i join public.claims c on c.id = i.claim_id where i.id = new.claim_item_id) <> p.payer_id then raise exception 'The claim is for a different payer.'; end if;
  end if;
  if new.amount > v_owed then raise exception 'That''s more than is owed (% left).', v_owed; end if;
  new.created_by := auth.uid(); new.created_at := now();
  return new;
end;
$$;

create or replace function public.guard_credit_note() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_api boolean := public.from_portal();
  v record;
  b record;
begin
  if tg_op = 'DELETE' then raise exception 'Credit notes are never deleted. Cancel a draft instead.'; end if;
  if tg_op = 'INSERT' then
    if v_api and not public.billing_can('invoice_prepare') then raise exception 'Only someone with the invoice prepare right prepares credit notes.'; end if;
    select * into v from public.invoices where id = new.invoice_id;
    if v.status not in ('issued', 'sent') then raise exception 'Credit notes are for issued invoices. Cancel a draft invoice instead.'; end if;
    new.client_id := v.client_id; new.payer_id := v.payer_id; new.status := 'draft'; new.number := null; new.amount := 0; new.gst := 0;
    new.prepared_by := auth.uid(); new.prepared_at := now(); new.snapshot := null; new.pdf_base64 := null; new.pdf_checksum := null;
    return new;
  end if;
  if (new.invoice_id, new.client_id, new.payer_id, new.prepared_by, new.prepared_at) is distinct from (old.invoice_id, old.client_id, old.payer_id, old.prepared_by, old.prepared_at) then
    raise exception 'A credit note keeps its invoice and preparer.';
  end if;
  if old.status in ('issued', 'cancelled') then
    if (to_jsonb(new) - array['pdf_base64', 'pdf_checksum', 'updated_by', 'updated_at']) is distinct from (to_jsonb(old) - array['pdf_base64', 'pdf_checksum', 'updated_by', 'updated_at'])
       or old.pdf_base64 is not null then
      raise exception 'An issued or cancelled credit note never changes.';
    end if;
    return new;
  end if;
  new.number := old.number; new.approved_by := old.approved_by; new.approved_at := old.approved_at;
  new.amount := coalesce((select sum(amount) from public.credit_note_items where credit_note_id = new.id), 0);
  if new.status is distinct from old.status then
    if new.status = 'approved' and old.status = 'draft' then
      if v_api and (not public.billing_can('invoice_approve') or auth.uid() is not distinct from old.prepared_by) then
        raise exception 'Only someone with the invoice approve right, who didn''t prepare it, approves a credit note.';
      end if;
      if new.amount <= 0 then raise exception 'The credit note has no lines.'; end if;
      new.approved_by := auth.uid(); new.approved_at := now();
    elsif new.status = 'issued' and old.status = 'approved' then
      if v_api and not public.billing_can('invoice_issue') then raise exception 'Only someone with the invoice issue right issues credit notes.'; end if;
      if new.amount > (select total - credited from public.invoice_balances where invoice_id = new.invoice_id) then
        raise exception 'That would credit more than the invoice.';
      end if;
      select * into b from public.business_current;
      new.number := public.billing_next_number('credit_note', 'CN');
      new.gst := coalesce((select sum(gst_amount) from public.credit_note_items where credit_note_id = new.id), 0);
      new.issue_date := (now() at time zone 'Australia/Sydney')::date; new.issued_by := auth.uid(); new.issued_at := now();
      new.snapshot := jsonb_build_object(
        'business', to_jsonb(b),
        'invoice', (select jsonb_build_object('number', number, 'issue_date', issue_date, 'total', total, 'tax_invoice', tax_invoice) from public.invoices where id = new.invoice_id),
        'payer', (select to_jsonb(p) from public.billing_payers p where p.id = new.payer_id),
        'client', (select jsonb_build_object('name', c.name, 'client_ref', c.client_ref) from public.car_clients c where c.id = new.client_id),
        'reason', new.reason,
        'items', (select coalesce(jsonb_agg(jsonb_build_object('description', ii.description, 'service_date', ii.service_date, 'amount', ci.amount, 'gst_amount', ci.gst_amount) order by ii.service_date), '[]')
                    from public.credit_note_items ci join public.invoice_items ii on ii.id = ci.invoice_item_id where ci.credit_note_id = new.id));
    elsif new.status = 'cancelled' and old.status in ('draft', 'approved') then
      if length(trim(new.cancel_reason)) = 0 then raise exception 'Say why the credit note is cancelled.'; end if;
      new.cancelled_by := auth.uid(); new.cancelled_at := now();
    else
      raise exception 'A credit note goes Draft -> Approved -> Issued, or a draft or approved one is cancelled.';
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.guard_credit_note_item() returns trigger
language plpgsql set search_path = '' as $$
declare
  n public.credit_notes;
  ii public.invoice_items;
  v_already numeric;
  v_inv record;
begin
  select * into n from public.credit_notes where id = case when tg_op = 'DELETE' then old.credit_note_id else new.credit_note_id end;
  if n.status <> 'draft' then raise exception 'Only a draft credit note''s lines change.'; end if;
  if tg_op = 'DELETE' then return old; end if;
  if tg_op = 'UPDATE' then raise exception 'Remove the line and add it again.'; end if;
  if public.from_portal() and not public.billing_can('invoice_prepare') then raise exception 'Only someone with the invoice prepare right prepares credit notes.'; end if;
  select * into ii from public.invoice_items where id = new.invoice_item_id;
  if ii.invoice_id <> n.invoice_id or ii.status <> 'live' then raise exception 'Choose a line of this invoice.'; end if;
  select coalesce(sum(ci.amount), 0) into v_already from public.credit_note_items ci join public.credit_notes x on x.id = ci.credit_note_id
   where ci.invoice_item_id = ii.id and x.status in ('draft', 'approved', 'issued') and ci.id is distinct from new.id;
  if new.amount + v_already > ii.amount then raise exception 'That would credit more than the line (% left).', ii.amount - v_already; end if;
  select * into v_inv from public.invoices where id = n.invoice_id;
  new.client_id := ii.client_id;
  new.gst_amount := case when ii.amount = 0 then 0 else round(ii.gst_amount * new.amount / ii.amount, 2) end;
  new.created_by := auth.uid(); new.created_at := now();
  return new;
end;
$$;

create or replace function public.guard_write_off() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_api boolean := public.from_portal();
  v_owed numeric;
begin
  if tg_op = 'DELETE' then raise exception 'Write-offs are never deleted. Reject a proposal instead.'; end if;
  if tg_op = 'INSERT' then
    if v_api and not (public.billing_can('write_off') or public.billing_can('payment_record')) then raise exception 'You can''t propose write-offs.'; end if;
    if new.invoice_id is not null then
      select balance, client_id into v_owed, new.client_id from public.invoice_balances where invoice_id = new.invoice_id;
    else
      select accepted - paid - written_off, client_id into v_owed, new.client_id from public.claim_item_balances where claim_item_id = new.claim_item_id;
    end if;
    if v_owed is null then raise exception 'Write-offs are for issued invoices or lines of a submitted claim.'; end if;
    v_owed := v_owed - coalesce((select sum(w.amount) from public.write_offs w where (w.invoice_id = new.invoice_id or w.claim_item_id = new.claim_item_id) and w.status in ('proposed', 'first_approved')), 0);
    if new.amount > v_owed then raise exception 'That''s more than is owed (% left, counting proposals waiting).', v_owed; end if;
    new.status := 'proposed'; new.proposed_by := auth.uid(); new.proposed_at := now();
    new.threshold := coalesce((select write_off_threshold from public.business_current), 500);
    new.approved_by := null; new.second_approved_by := null;
    return new;
  end if;
  if (to_jsonb(new) - array['status', 'approved_by', 'approved_at', 'second_approved_by', 'second_approved_at', 'rejected_by', 'rejected_at', 'reject_reason', 'updated_by', 'updated_at'])
     is distinct from (to_jsonb(old) - array['status', 'approved_by', 'approved_at', 'second_approved_by', 'second_approved_at', 'rejected_by', 'rejected_at', 'reject_reason', 'updated_by', 'updated_at']) then
    raise exception 'A write-off proposal never changes. Reject it and propose again.';
  end if;
  new.approved_by := old.approved_by; new.approved_at := old.approved_at; new.second_approved_by := old.second_approved_by; new.second_approved_at := old.second_approved_at;
  if new.status is distinct from old.status then
    if v_api and not public.billing_can('write_off') then raise exception 'Only someone with the write-off right decides write-offs.'; end if;
    if auth.uid() is not distinct from old.proposed_by and new.status <> 'rejected' then raise exception 'Someone other than who proposed it approves a write-off.'; end if;
    if old.status = 'proposed' and new.status in ('first_approved', 'approved') then
      new.approved_by := auth.uid(); new.approved_at := now();
      new.status := case when old.amount > coalesce(old.threshold, 500) then 'first_approved' else 'approved' end;
    elsif old.status = 'first_approved' and new.status = 'approved' then
      if auth.uid() is not distinct from old.approved_by then raise exception 'Above the threshold a second, different person approves.'; end if;
      new.second_approved_by := auth.uid(); new.second_approved_at := now();
    elsif old.status in ('proposed', 'first_approved') and new.status = 'rejected' then
      if length(trim(new.reject_reason)) = 0 then raise exception 'Say why it''s rejected.'; end if;
      new.rejected_by := auth.uid(); new.rejected_at := now();
    else
      raise exception 'A write-off is proposed, approved (twice above the threshold) or rejected.';
    end if;
    if new.status = 'approved' then
      if old.invoice_id is not null then select balance into v_owed from public.invoice_balances where invoice_id = old.invoice_id;
      else select accepted - paid - written_off into v_owed from public.claim_item_balances where claim_item_id = old.claim_item_id; end if;
      if old.amount > v_owed then raise exception 'Less than that is owed now (%).', v_owed; end if;
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.guard_refund() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_api boolean := public.from_portal();
  v_avail numeric;
begin
  if tg_op = 'DELETE' then raise exception 'Refunds are never deleted. Reject a proposal instead.'; end if;
  if tg_op = 'INSERT' then
    if v_api and not (public.billing_can('refund') or public.billing_can('payment_record')) then raise exception 'You can''t propose refunds.'; end if;
    if new.payment_id is not null then
      select unallocated, payer_id, client_id into v_avail, new.payer_id, new.client_id from public.payment_balances where payment_id = new.payment_id and status = 'recorded';
    else
      select -balance, payer_id, client_id into v_avail, new.payer_id, new.client_id from public.invoice_balances where invoice_id = new.invoice_id;
    end if;
    v_avail := coalesce(v_avail, 0) - coalesce((select sum(r.amount) from public.refunds r where (r.payment_id = new.payment_id or r.invoice_id = new.invoice_id) and r.status = 'proposed'), 0);
    if new.amount > v_avail then raise exception 'Only % is in credit to refund (counting proposals waiting).', greatest(v_avail, 0); end if;
    new.status := 'proposed'; new.proposed_by := auth.uid(); new.proposed_at := now(); new.approved_by := null; new.paid_on := null;
    return new;
  end if;
  if (to_jsonb(new) - array['status', 'approved_by', 'approved_at', 'paid_on', 'paid_reference', 'paid_by', 'paid_at', 'rejected_by', 'rejected_at', 'reject_reason', 'updated_by', 'updated_at'])
     is distinct from (to_jsonb(old) - array['status', 'approved_by', 'approved_at', 'paid_on', 'paid_reference', 'paid_by', 'paid_at', 'rejected_by', 'rejected_at', 'reject_reason', 'updated_by', 'updated_at']) then
    raise exception 'A refund never changes. Reject it and propose again.';
  end if;
  new.approved_by := old.approved_by; new.approved_at := old.approved_at;
  if new.status is distinct from old.status then
    if old.status = 'proposed' and new.status = 'approved' then
      if v_api and (not public.billing_can('refund') or auth.uid() is not distinct from old.proposed_by) then raise exception 'Only someone with the refund right, who didn''t propose it, approves a refund.'; end if;
      if old.payment_id is not null then select unallocated into v_avail from public.payment_balances where payment_id = old.payment_id;
      else select -balance into v_avail from public.invoice_balances where invoice_id = old.invoice_id; end if;
      if old.amount > coalesce(v_avail, 0) then raise exception 'Only % is in credit now.', greatest(coalesce(v_avail, 0), 0); end if;
      new.approved_by := auth.uid(); new.approved_at := now();
    elsif old.status = 'approved' and new.status = 'paid' then
      if v_api and not (public.billing_can('refund') or public.billing_can('payment_record')) then raise exception 'You can''t record refunds paid.'; end if;
      if new.paid_on is null or length(trim(new.paid_reference)) = 0 then raise exception 'Record the date paid and the payment reference.'; end if;
      if new.paid_on > (now() at time zone 'Australia/Sydney')::date then raise exception 'The date paid can''t be in the future.'; end if;
      new.paid_by := auth.uid(); new.paid_at := now();
    elsif old.status = 'proposed' and new.status = 'rejected' then
      if v_api and not public.billing_can('refund') then raise exception 'Only someone with the refund right rejects refunds.'; end if;
      if length(trim(new.reject_reason)) = 0 then raise exception 'Say why it''s rejected.'; end if;
      new.rejected_by := auth.uid(); new.rejected_at := now();
    else
      raise exception 'A refund goes Proposed -> Approved -> Paid, or a proposal is rejected.';
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.guard_bank_line() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_date date := case when tg_op = 'INSERT' then new.statement_date else old.statement_date end;
begin
  if public.from_portal() and not public.billing_can('reconcile') then raise exception 'Only someone with the reconcile right works on bank lines.'; end if;
  if exists (select 1 from public.bank_reconciliations r where r.status = 'completed' and v_date between r.period_from and r.period_to) then
    raise exception 'That date is in a completed reconciliation and doesn''t change.';
  end if;
  if tg_op = 'DELETE' then
    if old.status <> 'unmatched' then raise exception 'Unmatch the line first.'; end if;
    return old;
  end if;
  if tg_op = 'INSERT' then
    new.status := 'unmatched'; new.payment_id := null; new.refund_id := null; new.imported_by := auth.uid(); new.imported_at := now();
    return new;
  end if;
  if (new.statement_date, new.amount, new.description, new.reference, new.import_batch, new.import_key) is distinct from (old.statement_date, old.amount, old.description, old.reference, old.import_batch, old.import_key) then
    raise exception 'Imported bank lines never change.';
  end if;
  if new.status = 'matched' then
    if (new.payment_id is null) = (new.refund_id is null) then raise exception 'Match the line to one payment or one refund.'; end if;
    if new.payment_id is not null and (old.amount <= 0 or old.amount <> (select amount from public.payments where id = new.payment_id and status = 'recorded')) then
      raise exception 'The payment''s amount doesn''t match the bank line.';
    end if;
    if new.refund_id is not null and (old.amount >= 0 or -old.amount <> (select amount from public.refunds where id = new.refund_id and status = 'paid')) then
      raise exception 'The refund''s amount doesn''t match the bank line (and it must be recorded as paid).';
    end if;
    new.exclude_reason := ''; new.matched_by := auth.uid(); new.matched_at := now();
  elsif new.status = 'excluded' then
    if length(trim(new.exclude_reason)) = 0 then raise exception 'Say why the line is excluded (for example, bank fees or not billing).'; end if;
    new.payment_id := null; new.refund_id := null; new.matched_by := auth.uid(); new.matched_at := now();
  else
    new.payment_id := null; new.refund_id := null; new.exclude_reason := ''; new.matched_by := null; new.matched_at := null;
  end if;
  return new;
end;
$$;

create or replace function public.guard_bank_reconciliation() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_sum numeric;
begin
  if public.from_portal() and not public.billing_can('reconcile') then raise exception 'Only someone with the reconcile right reconciles.'; end if;
  if tg_op = 'DELETE' then
    if old.status = 'completed' then raise exception 'A completed reconciliation is never deleted.'; end if;
    return old;
  end if;
  if tg_op = 'INSERT' then
    new.status := 'draft'; new.created_by := auth.uid(); new.created_at := now(); new.completed_by := null; new.completed_at := null;
    if exists (select 1 from public.bank_reconciliations r where r.status = 'completed' and daterange(r.period_from, r.period_to, '[]') && daterange(new.period_from, new.period_to, '[]')) then
      raise exception 'That period overlaps a completed reconciliation.';
    end if;
    return new;
  end if;
  if old.status = 'completed' then raise exception 'A completed reconciliation never changes.'; end if;
  if new.status = 'completed' then
    if exists (select 1 from public.bank_statement_lines l where l.statement_date between new.period_from and new.period_to and l.status = 'unmatched') then
      raise exception 'Match or exclude every bank line in the period first.';
    end if;
    select coalesce(sum(amount), 0) into v_sum from public.bank_statement_lines l where l.statement_date between new.period_from and new.period_to;
    if new.opening_balance + v_sum <> new.closing_balance then
      raise exception 'The balances don''t agree: opening % plus lines % isn''t closing %.', new.opening_balance, v_sum, new.closing_balance;
    end if;
    new.completed_by := auth.uid(); new.completed_at := now();
  end if;
  return new;
end;
$$;

-- A billing line stays locked while it's in a live claim or invoice, unless the government fully
-- rejected it (and it isn't in a replacement claim) or an issued credit note covers it in full.
create or replace function public.billing_line_locked(p_line uuid) returns boolean
language sql stable set search_path = '' as $$
  select exists (select 1 from public.claim_items i join public.claims c on c.id = i.claim_id
                  where i.line_id = p_line and i.status = 'live' and c.status <> 'cancelled'
                    and (c.status in ('draft', 'approved') or coalesce((select o.outcome from public.claim_item_outcomes o where o.claim_item_id = i.id), 'pending') <> 'rejected'))
      or exists (select 1 from public.invoice_items i join public.invoices v on v.id = i.invoice_id
                  where i.line_id = p_line and i.status = 'live' and v.status <> 'cancelled'
                    and i.amount > coalesce((select sum(ci.amount) from public.credit_note_items ci join public.credit_notes n on n.id = ci.credit_note_id where ci.invoice_item_id = i.id and n.status = 'issued'), 0))
$$;
create or replace function public.guard_line_recovered() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.status = 'approved' and old.status = 'draft' and public.billing_review_lapsed(new.scheme) then
    raise exception 'Billing for this scheme is paused: a verified rule or figure is past its review date. Review it in Billing set-up.';
  end if;
  if new.status = 'voided' and old.status <> 'voided' and public.billing_line_locked(new.id) then
    raise exception 'This line is in a claim or invoice. Correct it there (cancel the draft, a credit note for an invoice, or wait for the government''s rejection of a claim).';
  end if;
  return new;
end;
$$;

-- 9. Read and change rules.
do $$
declare
  t text;
begin
  -- Client records.
  foreach t in array array['claim_item_results', 'payment_allocations', 'credit_notes', 'credit_note_items', 'write_offs'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "billing see %s" on public.%I', t, t);
    execute format('create policy "billing see %s" on public.%I for select to authenticated using (public.billing_can(''view'', client_id))', t, t);
    execute format('drop policy if exists "billing add %s" on public.%I', t, t);
    execute format('create policy "billing add %s" on public.%I for insert to authenticated with check (public.billing_can(''view'', client_id))', t, t);
    execute format('drop policy if exists "billing change %s" on public.%I', t, t);
    execute format('create policy "billing change %s" on public.%I for update to authenticated using (public.billing_can(''view'', client_id)) with check (public.billing_can(''view'', client_id))', t, t);
    execute format('grant select, insert, update on public.%I to authenticated', t);
    execute format('revoke all on public.%I from anon', t);
  end loop;
  drop policy if exists "billing remove credit_note_items" on public.credit_note_items;
  create policy "billing remove credit_note_items" on public.credit_note_items for delete to authenticated using (public.billing_can('invoice_prepare', client_id));
  grant delete on public.credit_note_items to authenticated;
  -- Payments and refunds: a client's (client reach) or a payer's covering many clients (all-client reach).
  foreach t in array array['payments', 'refunds'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "billing see %s" on public.%I', t, t);
    execute format('create policy "billing see %s" on public.%I for select to authenticated using (case when client_id is null then public.billing_can(''view'') else public.billing_can(''view'', client_id) end)', t, t);
    execute format('drop policy if exists "billing add %s" on public.%I', t, t);
    execute format('create policy "billing add %s" on public.%I for insert to authenticated with check (case when client_id is null then public.billing_can(''view'') else public.billing_can(''view'', client_id) end)', t, t);
    execute format('drop policy if exists "billing change %s" on public.%I', t, t);
    execute format('create policy "billing change %s" on public.%I for update to authenticated using (case when client_id is null then public.billing_can(''view'') else public.billing_can(''view'', client_id) end) with check (case when client_id is null then public.billing_can(''view'') else public.billing_can(''view'', client_id) end)', t, t);
    execute format('grant select, insert, update on public.%I to authenticated', t);
    execute format('revoke all on public.%I from anon', t);
  end loop;
  -- Bank reconciliation: all-client reach.
  foreach t in array array['bank_statement_lines', 'bank_reconciliations'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "billing see %s" on public.%I', t, t);
    execute format('create policy "billing see %s" on public.%I for select to authenticated using (public.billing_can(''view''))', t, t);
    execute format('drop policy if exists "billing add %s" on public.%I', t, t);
    execute format('create policy "billing add %s" on public.%I for insert to authenticated with check (public.billing_can(''reconcile''))', t, t);
    execute format('drop policy if exists "billing change %s" on public.%I', t, t);
    execute format('create policy "billing change %s" on public.%I for update to authenticated using (public.billing_can(''reconcile'')) with check (public.billing_can(''reconcile''))', t, t);
    execute format('drop policy if exists "billing remove %s" on public.%I', t, t);
    execute format('create policy "billing remove %s" on public.%I for delete to authenticated using (public.billing_can(''reconcile''))', t, t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
    execute format('revoke all on public.%I from anon', t);
  end loop;
  alter table public.billing_number_counters enable row level security;
  revoke all on public.billing_number_counters from anon, authenticated;
  drop policy if exists "billing numbering" on public.billing_number_counters;
  create policy "billing numbering" on public.billing_number_counters for all to authenticated using (public.billing_can('view')) with check (public.billing_can('view'));
  grant select, insert, update on public.billing_number_counters to authenticated;
  foreach t in array array['claim_item_outcomes', 'invoice_balances', 'claim_item_balances', 'payment_balances'] loop
    execute format('grant select on public.%I to authenticated', t);
    execute format('revoke all on public.%I from anon', t);
  end loop;
end $$;
revoke execute on function public.claim_resubmit(uuid) from public, anon;
grant execute on function public.claim_resubmit(uuid) to authenticated;
revoke execute on function public.billing_next_number(text, text) from public, anon;
grant execute on function public.billing_next_number(text, text) to authenticated;

-- 10. Triggers: checks, then the change log (set-up) or client audit trail (client records).
do $$
declare
  t text;
begin
  foreach t in array array['claim_item_results:guard_claim_result', 'payments:guard_payment', 'payment_allocations:guard_payment_allocation', 'credit_notes:guard_credit_note',
                           'credit_note_items:guard_credit_note_item', 'write_offs:guard_write_off', 'refunds:guard_refund', 'bank_statement_lines:guard_bank_line',
                           'bank_reconciliations:guard_bank_reconciliation'] loop
    execute format('drop trigger if exists %I on public.%I', split_part(t, ':', 2), split_part(t, ':', 1));
    execute format('create trigger %I before insert or update or delete on public.%I for each row execute function public.%I()', split_part(t, ':', 2), split_part(t, ':', 1), split_part(t, ':', 2));
  end loop;
  foreach t in array array['payments:payment', 'refunds:refund', 'bank_statement_lines:bank_line', 'bank_reconciliations:bank_reconciliation'] loop
    execute format('drop trigger if exists log_billing_setup on public.%I', split_part(t, ':', 1));
    execute format('create trigger log_billing_setup after insert or update or delete on public.%I for each row execute function public.log_car_setup(%L)', split_part(t, ':', 1), split_part(t, ':', 2));
    execute format('drop trigger if exists stamp_billing_setup on public.%I', split_part(t, ':', 1));
    execute format('create trigger stamp_billing_setup before insert or update on public.%I for each row execute function public.stamp_billing_updated()', split_part(t, ':', 1));
  end loop;
  foreach t in array array['claim_item_results', 'payment_allocations', 'credit_notes', 'credit_note_items', 'write_offs'] loop
    execute format('drop trigger if exists log_client_change on public.%I', t);
    execute format('create trigger log_client_change before insert or update on public.%I for each row execute function public.log_client_change()', t);
    execute format('drop trigger if exists log_client_audit on public.%I', t);
    execute format('create trigger log_client_audit after insert or update or delete on public.%I for each row execute function public.log_client_change()', t);
  end loop;
end $$;

revoke execute on function public.guard_claim_result() from public, anon, authenticated;
revoke execute on function public.guard_payment() from public, anon, authenticated;
revoke execute on function public.guard_payment_allocation() from public, anon, authenticated;
revoke execute on function public.guard_credit_note() from public, anon, authenticated;
revoke execute on function public.guard_credit_note_item() from public, anon, authenticated;
revoke execute on function public.guard_write_off() from public, anon, authenticated;
revoke execute on function public.guard_refund() from public, anon, authenticated;
revoke execute on function public.guard_bank_line() from public, anon, authenticated;
revoke execute on function public.guard_bank_reconciliation() from public, anon, authenticated;
