-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 164 (claim results, payments, receipts, credit notes, refunds, write-offs, bank
-- reconciliation). Safe to run again. Nothing is lost: every record update 164 added is first
-- copied to a locked schema, undo_164_kept, that only the database owner can read. Change-log
-- entries stay. Undo does NOT restore anything later; bringing records back is a separate, manual
-- decision. Replacement claim lines (and so replacement claims' lines) are kept there too and
-- removed from claim_items; the replacement claims themselves stay, with no lines. Then the
-- update 163 rules for claim lines and voiding are put back exactly, and the four new Billing
-- actions are taken off. Everything from update 163 and before stays as it is.
begin;
create schema if not exists undo_164_kept;
revoke all on schema undo_164_kept from public;
do $$
declare
  t text;
begin
  foreach t in array array['claim_item_results', 'payments', 'payment_allocations', 'credit_notes', 'credit_note_items', 'write_offs', 'refunds',
                           'bank_statement_lines', 'bank_reconciliations', 'billing_number_counters'] loop
    if to_regclass('public.' || t) is not null then
      if to_regclass('undo_164_kept.' || t) is null then
        execute format('create table undo_164_kept.%I as table public.%I', t, t);
      else
        execute format('insert into undo_164_kept.%I select * from public.%I p where not exists (select 1 from undo_164_kept.%I k where to_jsonb(k) = to_jsonb(p))', t, t, t);
      end if;
    end if;
  end loop;
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'claim_items' and column_name = 'replaces_item_id') then
    if to_regclass('undo_164_kept.claim_items_replacements') is null then
      create table undo_164_kept.claim_items_replacements as select * from public.claim_items where replaces_item_id is not null;
    else
      insert into undo_164_kept.claim_items_replacements select * from public.claim_items c where c.replaces_item_id is not null
        and not exists (select 1 from undo_164_kept.claim_items_replacements k where k.id = c.id);
    end if;
  end if;
end $$;
revoke all on all tables in schema undo_164_kept from public;
do $$ begin
  execute 'revoke all on schema undo_164_kept from anon, authenticated';
  execute 'revoke all on all tables in schema undo_164_kept from anon, authenticated';
exception when undefined_object then null;
end $$;

drop view if exists public.invoice_balances;
drop view if exists public.claim_item_balances;
drop view if exists public.payment_balances;
drop view if exists public.claim_item_outcomes;
drop table if exists public.bank_statement_lines;
drop table if exists public.bank_reconciliations;
drop table if exists public.payment_allocations;
drop table if exists public.refunds;
drop table if exists public.write_offs;
drop table if exists public.credit_note_items;
drop table if exists public.credit_notes;
drop table if exists public.payments;
drop table if exists public.claim_item_results;
drop table if exists public.billing_number_counters;
drop function if exists public.claim_resubmit(uuid);
drop function if exists public.billing_next_number(text, text);
drop function if exists public.billing_line_locked(uuid);
drop function if exists public.guard_claim_result();
drop function if exists public.guard_payment();
drop function if exists public.guard_payment_allocation();
drop function if exists public.guard_credit_note();
drop function if exists public.guard_credit_note_item();
drop function if exists public.guard_write_off();
drop function if exists public.guard_refund();
drop function if exists public.guard_bank_line();
drop function if exists public.guard_bank_reconciliation();

-- Replacement claim lines (copied above), then the update 163 claim line rules.
do $$ begin
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'claim_items' and column_name = 'replaces_item_id') then
    alter table public.claim_items disable trigger guard_claim_item;
    delete from public.claim_items where replaces_item_id is not null;
    alter table public.claim_items enable trigger guard_claim_item;
  end if;
end $$;
alter table public.claim_items drop constraint if exists claim_items_source;
alter table public.claim_items drop column if exists replaces_item_id;
alter table public.claim_items add constraint claim_items_source check ((line_id is not null and recovery_id is not null and quarter_budget_id is null)
                                    or (line_id is null and recovery_id is null and quarter_budget_id is not null));
drop index if exists public.claim_items_one_care_management;
create unique index if not exists claim_items_one_care_management on public.claim_items (quarter_budget_id) where status = 'live';
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
revoke execute on function public.guard_claim_item() from public, anon, authenticated;
revoke execute on function public.guard_line_recovered() from public, anon, authenticated;
update public.app_modules set actions = array(select a from unnest(actions) a where a not in ('payment_record', 'refund', 'write_off', 'reconcile'))
 where id = 'clients.billing' and actions && array['payment_record', 'refund', 'write_off', 'reconcile'];
commit;
