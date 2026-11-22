-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 163 (claims, client invoices, statements, compliance register). Safe to run again.
-- Nothing is lost: every record update 163 added is first copied to a locked schema,
-- undo_163_kept, that only the database owner can read (business details, payers,
-- client payer links, fee reductions, NDIS zones, plan details, catalogues and items,
-- claim templates, recoveries, claims, claim lines, submissions, invoices, invoice
-- lines and numbering, statements), plus the official link, version and review dates
-- recorded on billing rules and figures. Change-log entries stay. Undo does NOT
-- restore anything later; bringing records back is a separate, manual decision.
-- Then the new tables, views, functions and triggers are removed, the added rule
-- checks that are still unverified are removed, and the six new Billing actions are
-- taken off the module. Everything from update 162 and before stays as it is
-- (billing lines, budgets, ledger, prices, terms).
-- Note: an invoice number issued while 163 was in place is kept in undo_163_kept;
-- if 163 is run again, numbering restarts from the counters kept there only if
-- they're brought back by hand (never reuse a number).
begin;
create schema if not exists undo_163_kept;
revoke all on schema undo_163_kept from public;
do $$
declare
  t text;
begin
  foreach t in array array['business_details', 'billing_payers', 'client_payer_links', 'client_fee_reductions', 'client_location_pricing', 'ndis_plan_details',
                           'ndis_catalogue_versions', 'ndis_support_items', 'claim_templates', 'line_recoveries', 'claims', 'claim_items', 'claim_submissions',
                           'invoices', 'invoice_items', 'invoice_number_counters', 'client_statements'] loop
    if to_regclass('public.' || t) is not null then
      if to_regclass('undo_163_kept.' || t) is null then
        execute format('create table undo_163_kept.%I as table public.%I', t, t);
      else
        execute format('insert into undo_163_kept.%I select * from public.%I p where not exists (select 1 from undo_163_kept.%I k where to_jsonb(k) = to_jsonb(p))', t, t, t);
      end if;
    end if;
  end loop;
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'billing_rule_checks' and column_name = 'review_by') then
    create table if not exists undo_163_kept.billing_rule_checks_review (id uuid, scheme text, item text, status text, official_url text, document_version text, effective_from date, review_by date, kept_at timestamptz);
    insert into undo_163_kept.billing_rule_checks_review
    select id, scheme, item, status, official_url, document_version, effective_from, review_by, now() from public.billing_rule_checks;
  end if;
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'billing_parameters' and column_name = 'review_by') then
    create table if not exists undo_163_kept.billing_parameters_review (id uuid, scheme text, key text, status text, official_url text, document_version text, review_by date, kept_at timestamptz);
    insert into undo_163_kept.billing_parameters_review
    select id, scheme, key, status, official_url, document_version, review_by, now() from public.billing_parameters;
  end if;
end $$;
revoke all on all tables in schema undo_163_kept from public;
do $$ begin
  execute 'revoke all on schema undo_163_kept from anon, authenticated';
  execute 'revoke all on all tables in schema undo_163_kept from anon, authenticated';
exception when undefined_object then null;
end $$;

drop trigger if exists guard_line_recovered on public.billing_lines;
drop trigger if exists guard_billing_review on public.billing_rule_checks;
drop trigger if exists guard_billing_review on public.billing_parameters;
drop view if exists public.care_management_accounts;
drop view if exists public.business_current;
drop table if exists public.client_statements;
drop table if exists public.invoice_items;
drop table if exists public.invoices;
drop table if exists public.invoice_number_counters;
drop table if exists public.claim_submissions;
drop table if exists public.claim_items;
drop table if exists public.claims;
drop table if exists public.line_recoveries;
drop table if exists public.claim_templates;
drop table if exists public.ndis_support_items;
drop table if exists public.ndis_catalogue_versions;
drop table if exists public.ndis_plan_details;
drop table if exists public.client_location_pricing;
drop table if exists public.client_fee_reductions;
drop table if exists public.client_payer_links;
drop table if exists public.billing_payers;
drop table if exists public.business_details;
drop function if exists public.claim_prepare(text, date, date);
drop function if exists public.invoice_prepare(text, date, date);
drop function if exists public.ndis_price_check(uuid);
drop function if exists public.billing_payer_for(uuid, text);
drop function if exists public.recovery_in_use(uuid, uuid);
drop function if exists public.billing_scheme_ready(text);
drop function if exists public.billing_review_lapsed(text);
drop function if exists public.abn_valid(text);
drop function if exists public.guard_billing_review();
drop function if exists public.guard_business_details();
drop function if exists public.guard_billing_reference();
drop function if exists public.guard_ndis_item();
drop function if exists public.guard_line_recovery();
drop function if exists public.guard_claim();
drop function if exists public.guard_claim_item();
drop function if exists public.guard_claim_submission();
drop function if exists public.guard_invoice();
drop function if exists public.guard_invoice_item();
drop function if exists public.guard_statement();
drop function if exists public.guard_line_recovered();
drop function if exists public.guard_client_billing_link();

-- The rule checks 163 added, while still unverified (a copy is kept above). Rules are
-- otherwise never deleted, so the guard is paused for this statement only.
alter table public.billing_rule_checks disable trigger guard_billing_rules;
delete from public.billing_rule_checks where status = 'unverified' and (scheme, item) in (
  ('support_at_home', 'Care management account: 10% moved each quarter; its own rollover rule (separate from the participant''s carryover)'),
  ('support_at_home', 'Care management is clinical care: no participant contribution; claimed each quarter'),
  ('support_at_home', 'Contributions collected unless a fee reduction supplement applies; Services Australia''s calculation is authoritative'),
  ('support_at_home', 'Services Australia claim format and claiming rules (program manual, provider pages)'),
  ('ndis', 'NDIS Bulk Upload File template (from the provider portal): columns kept, CSV, date format, file name length'),
  ('ndis', 'NDIS Pricing Arrangements / Pricing Schedule version in force (price limits by zone, time of day)'),
  ('ndis', '"My provider" recording for agency-managed supports'));
alter table public.billing_rule_checks enable trigger guard_billing_rules;
alter table public.billing_rule_checks drop column if exists official_url, drop column if exists document_version, drop column if exists effective_from, drop column if exists review_by;
alter table public.billing_parameters drop column if exists official_url, drop column if exists document_version, drop column if exists review_by;
update public.app_modules set actions = array(select a from unnest(actions) a where a not in ('claim_prepare', 'claim_approve', 'claim_submit', 'invoice_prepare', 'invoice_approve', 'invoice_issue'))
 where id = 'clients.billing' and actions && array['claim_prepare', 'claim_approve', 'claim_submit', 'invoice_prepare', 'invoice_approve', 'invoice_issue'];
commit;
