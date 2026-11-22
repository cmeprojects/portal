-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 165 (suppliers, client charges, markup rules, pathway budgets). Safe to run again.
-- It stops, changing nothing, if a client charge is already in a submitted claim or an issued
-- invoice: those documents must not lose lines (correct them first with credit notes or claim
-- results, or keep update 165). Otherwise nothing is lost: every record update 165 added is first
-- copied to a locked schema, undo_165_kept, that only the database owner can read (suppliers,
-- supplier invoices and lines, markup rules, pathway budgets, client charges, their ledger entries,
-- recoveries and draft claim and invoice lines). Then those charge lines and ledger entries are
-- removed (so budgets show what they did before the charges), the new tables and functions are
-- dropped, the update 163/164 rules are put back exactly, and the added rule checks still
-- unverified are removed. Undo does NOT restore anything later.
begin;
do $$
declare
  v_busy boolean := false;
begin
  if to_regclass('public.client_charges') is not null then
    execute $q$select exists (select 1 from public.claim_items i join public.claims c on c.id = i.claim_id where i.charge_id is not null and c.status not in ('draft', 'cancelled'))
                   or exists (select 1 from public.invoice_items i join public.invoices v on v.id = i.invoice_id where i.charge_id is not null and v.status not in ('draft', 'cancelled'))$q$ into v_busy;
  end if;
  if v_busy then
    raise exception 'Undo stopped: a client charge is in a submitted claim or an issued invoice. Nothing was changed.';
  end if;
end $$;
create schema if not exists undo_165_kept;
revoke all on schema undo_165_kept from public;
do $$
declare
  t text;
begin
  foreach t in array array['suppliers', 'supplier_invoices', 'supplier_invoice_lines', 'billing_markup_rules', 'client_pathway_budgets', 'client_charges'] loop
    if to_regclass('public.' || t) is not null then
      if to_regclass('undo_165_kept.' || t) is null then
        execute format('create table undo_165_kept.%I as table public.%I', t, t);
      else
        execute format('insert into undo_165_kept.%I select * from public.%I p where not exists (select 1 from undo_165_kept.%I k where to_jsonb(k) = to_jsonb(p))', t, t, t);
      end if;
    end if;
  end loop;
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'line_recoveries' and column_name = 'charge_id') then
    create table if not exists undo_165_kept.charge_ledger as select * from public.funding_ledger where false;
    insert into undo_165_kept.charge_ledger select * from public.funding_ledger l where l.client_charge_id is not null and not exists (select 1 from undo_165_kept.charge_ledger k where k.id = l.id);
    create table if not exists undo_165_kept.charge_recoveries as select * from public.line_recoveries where false;
    insert into undo_165_kept.charge_recoveries select * from public.line_recoveries r where r.charge_id is not null and not exists (select 1 from undo_165_kept.charge_recoveries k where k.id = r.id);
    create table if not exists undo_165_kept.charge_claim_items as select * from public.claim_items where false;
    insert into undo_165_kept.charge_claim_items select * from public.claim_items i where i.charge_id is not null and not exists (select 1 from undo_165_kept.charge_claim_items k where k.id = i.id);
    create table if not exists undo_165_kept.charge_invoice_items as select * from public.invoice_items where false;
    insert into undo_165_kept.charge_invoice_items select * from public.invoice_items i where i.charge_id is not null and not exists (select 1 from undo_165_kept.charge_invoice_items k where k.id = i.id);
    -- Remove the charge rows (their guards don't allow deletes, so they're paused for these statements only).
    alter table public.claim_items disable trigger guard_claim_item;
    delete from public.claim_items where charge_id is not null;
    alter table public.claim_items enable trigger guard_claim_item;
    alter table public.invoice_items disable trigger guard_invoice_item;
    delete from public.invoice_items where charge_id is not null;
    alter table public.invoice_items enable trigger guard_invoice_item;
    alter table public.line_recoveries disable trigger guard_line_recovery;
    delete from public.line_recoveries where charge_id is not null;
    alter table public.line_recoveries enable trigger guard_line_recovery;
    alter table public.funding_ledger disable trigger guard_funding_ledger;
    delete from public.funding_ledger where client_charge_id is not null;
    alter table public.funding_ledger enable trigger guard_funding_ledger;
  end if;
end $$;
revoke all on all tables in schema undo_165_kept from public;
do $$ begin
  execute 'revoke all on schema undo_165_kept from anon, authenticated';
  execute 'revoke all on all tables in schema undo_165_kept from anon, authenticated';
exception when undefined_object then null;
end $$;

drop trigger if exists guard_statement_charges on public.client_statements;
drop view if exists public.pathway_balances;
alter table public.funding_ledger drop column if exists client_charge_id;
alter table public.claim_items drop constraint if exists claim_items_source;
alter table public.claim_items drop column if exists charge_id;
alter table public.claim_items add constraint claim_items_source check (
  (replaces_item_id is null and ((line_id is not null and recovery_id is not null and quarter_budget_id is null) or (line_id is null and recovery_id is null and quarter_budget_id is not null)))
  or (replaces_item_id is not null and recovery_id is null and ((line_id is not null) <> (quarter_budget_id is not null))));
alter table public.invoice_items drop constraint if exists invoice_items_source;
alter table public.invoice_items drop column if exists charge_id;
alter table public.invoice_items alter column line_id set not null;
drop index if exists public.line_recoveries_charge_role;
alter table public.line_recoveries drop constraint if exists line_recoveries_source;
alter table public.line_recoveries drop column if exists charge_id;
alter table public.line_recoveries alter column line_id set not null;
drop table if exists public.client_charges;
drop table if exists public.client_pathway_budgets;
drop function if exists public.billing_markup_for(text, date);
drop table if exists public.billing_markup_rules;
drop table if exists public.supplier_invoice_lines;
drop table if exists public.supplier_invoices;
drop table if exists public.suppliers;
drop function if exists public.claim_add_charges(uuid);
drop function if exists public.invoice_add_charges(text, date, date);
drop function if exists public.ndis_charge_check(uuid);
drop function if exists public.client_charge_locked(uuid);
drop function if exists public.guard_supplier_invoice();
drop function if exists public.guard_supplier_line();
drop function if exists public.supplier_invoice_totals();
drop function if exists public.guard_markup_rule();
drop function if exists public.guard_pathway_budget();
drop function if exists public.guard_client_charge();
drop function if exists public.ledger_from_charge();
drop function if exists public.statement_add_charges();
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
revoke execute on function public.guard_line_recovery() from public, anon, authenticated;
revoke execute on function public.guard_claim_item() from public, anon, authenticated;

-- The rule checks 165 added, while still unverified (kept above as part of nothing else, so listed here).
create table if not exists undo_165_kept.rule_checks as select * from public.billing_rule_checks where false;
insert into undo_165_kept.rule_checks select * from public.billing_rule_checks c where c.status = 'unverified' and (c.scheme, c.item) in (
  ('support_at_home', 'Assistive Technology and Home Modifications (AT-HM): funding tiers, approval and the period to use the funds'),
  ('support_at_home', 'Restorative Care Pathway: amount, duration and what it covers'),
  ('support_at_home', 'End-of-Life Pathway: amount, duration and eligibility'),
  ('support_at_home', 'Unspent Home Care Package funds: order of use with the quarterly budget, and what happens to the remainder'),
  ('support_at_home', 'Third-party (subcontracted) services: how they are priced and any administration or markup charge'),
  ('support_at_home', 'Participant contributions on AT-HM and pathway services'),
  ('ndis', 'Third-party supports: claimed at no more than the price limit (no markup above it)'))
  and not exists (select 1 from undo_165_kept.rule_checks k where k.id = c.id);
revoke all on undo_165_kept.rule_checks from public;
alter table public.billing_rule_checks disable trigger guard_billing_rules;
delete from public.billing_rule_checks c where c.status = 'unverified' and exists (select 1 from undo_165_kept.rule_checks k where k.id = c.id);
alter table public.billing_rule_checks enable trigger guard_billing_rules;
commit;
