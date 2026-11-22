-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 162 (billing lines, quarter budgets, funding ledger). Safe to run again.
-- Nothing is lost: every record update 162 added is first copied to a locked schema,
-- undo_162_kept, that only the database owner can read (billing lines, quarter
-- budgets, ledger entries, delivery decisions, billing figures). Change-log entries
-- stay. Undo does NOT restore anything later; bringing records back is a separate,
-- manual decision. Then the new tables, view and functions are removed. Everything
-- from update 161 and before (price lists, billing terms, rates, cancellations,
-- funding records, shifts, timesheets) stays exactly as it is.
begin;
create schema if not exists undo_162_kept;
revoke all on schema undo_162_kept from public;
do $$
declare
  t text;
begin
  foreach t in array array['billing_parameters', 'billing_delivery_overrides', 'client_quarter_budgets', 'funding_ledger', 'billing_lines'] loop
    if to_regclass('public.' || t) is not null then
      if to_regclass('undo_162_kept.' || t) is null then
        execute format('create table undo_162_kept.%I as table public.%I', t, t);
      else
        execute format('insert into undo_162_kept.%I select * from public.%I p where not exists (select 1 from undo_162_kept.%I k where k.id = p.id and k.updated_at = p.updated_at)', t, t, t);
      end if;
    end if;
  end loop;
end $$;
revoke all on all tables in schema undo_162_kept from public;
do $$ begin
  execute 'revoke all on schema undo_162_kept from anon, authenticated';
  execute 'revoke all on all tables in schema undo_162_kept from anon, authenticated';
exception when undefined_object then null;
end $$;

drop view if exists public.funding_balances;
drop table if exists public.funding_ledger;
drop table if exists public.billing_lines;
drop table if exists public.client_quarter_budgets;
drop table if exists public.billing_delivery_overrides;
drop table if exists public.billing_parameters;
drop function if exists public.billing_generate(date, date, uuid);
drop function if exists public.billing_exceptions(date, date, uuid);
drop function if exists public.billing_calc(uuid, text);
drop function if exists public.billing_close_quarter(uuid);
drop function if exists public.billing_figure(text, date);
drop function if exists public.guard_billing_parameter();
drop function if exists public.guard_delivery_override();
drop function if exists public.guard_quarter_budget();
drop function if exists public.guard_funding_ledger();
drop function if exists public.guard_billing_line();
drop function if exists public.ledger_from_line();
commit;
