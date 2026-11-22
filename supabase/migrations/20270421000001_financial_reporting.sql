-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 166): Phase 5D. Consolidated financial reporting (D-066; built under D-068).
-- Read-only views and checks over what Phases 4 and 5 recorded; nothing here changes a record.
--   * billing_revenue: every approved billing line and client charge in one place (date, client,
--     scheme, funding stream, value, client share, government share), for reports.
--   * billing_integrity_checks(): consistency checks a finance person runs (recoveries above the
--     service value, issued documents without their PDF, totals that don't add up, money allocated
--     beyond what's owed, claims approved but not submitted, unmatched bank lines, old drafts).
-- All follow each person's Billing reach (security invoker). No new security definer function.
-- Safe to run again.

create or replace view public.billing_revenue with (security_invoker = true) as
  select 'line'::text as source, l.id, l.client_id, l.service_date, l.scheme, l.funding_stream, l.kind as detail, l.amount, l.client_share, l.government_share,
         l.quarter_budget_id, null::uuid as pathway_budget_id, l.funding_id, l.approved_at
    from public.billing_lines l where l.status = 'approved'
  union all
  select 'charge', c.id, c.client_id, c.service_date, c.scheme, c.funding_stream, c.description, c.amount, c.client_share, c.government_share,
         c.quarter_budget_id, c.pathway_budget_id, c.funding_id, c.approved_at
    from public.client_charges c where c.status = 'approved';

create or replace function public.billing_integrity_checks()
returns table (check_name text, severity text, problem_count bigint, detail text)
language sql stable set search_path = '' as $$
  select 'Recoveries above the service value', 'error',
         (select count(*) from (select coalesce(r.line_id, r.charge_id) as k, max(r.service_value) as v, sum(r.amount) as s from public.line_recoveries r group by 1) x where x.s > x.v),
         'A billing line or charge recovered (claimed plus invoiced) for more than its value.'
  union all
  select 'Issued invoices without their PDF', 'error',
         (select count(*) from public.invoices where status in ('issued', 'sent') and pdf_checksum is null), 'Issued invoices should have their stored PDF.'
  union all
  select 'Issued credit notes without their PDF', 'error',
         (select count(*) from public.credit_notes where status = 'issued' and pdf_checksum is null), 'Issued credit notes should have their stored PDF.'
  union all
  select 'Invoice totals that don''t match their lines', 'error',
         (select count(*) from public.invoices v where v.status in ('issued', 'sent')
             and v.subtotal <> (select coalesce(sum(i.amount), 0) from public.invoice_items i where i.invoice_id = v.id and i.status = 'live')),
         'An issued invoice''s subtotal differs from the sum of its lines.'
  union all
  select 'Claim totals that don''t match their lines', 'error',
         (select count(*) from public.claims c where c.status <> 'cancelled'
             and c.total_claimed <> (select coalesce(sum(i.claimed_value), 0) from public.claim_items i where i.claim_id = c.id and i.status = 'live')),
         'A claim''s total differs from the sum of its live lines.'
  union all
  select 'Money allocated beyond what''s owed', 'error',
         (select count(*) from public.invoice_balances where balance < -0.004 and refunded = 0 and credited = 0)
         + (select count(*) from public.claim_item_balances where paid + written_off > accepted + 0.004),
         'An invoice paid beyond its total (without a credit), or a claim line paid beyond what was accepted.'
  union all
  select 'Approved claims not yet submitted', 'warning',
         (select count(*) from public.claims where status = 'approved'), 'Upload the file in the government portal, then record the submission.'
  union all
  select 'Submitted claims without results after 30 days', 'warning',
         (select count(*) from public.claims c join public.claim_submissions s on s.claim_id = c.id
           where c.status in ('submitted', 'acknowledged') and s.submitted_at < now() - interval '30 days'
             and exists (select 1 from public.claim_items i where i.claim_id = c.id and i.status = 'live' and not exists (select 1 from public.claim_item_results r where r.claim_item_id = i.id))),
         'Record the government''s results (Claims).'
  union all
  select 'Payments not fully allocated', 'warning',
         (select count(*) from public.payment_balances where status = 'recorded' and unallocated > 0), 'Allocate them, or refund the credit.'
  union all
  select 'Unmatched bank lines', 'warning',
         (select count(*) from public.bank_statement_lines where status = 'unmatched'), 'Match or exclude them (Reconciliation).'
  union all
  select 'Drafts older than 14 days', 'info',
         (select count(*) from public.claims where status = 'draft' and prepared_at < now() - interval '14 days')
         + (select count(*) from public.invoices where status = 'draft' and prepared_at < now() - interval '14 days')
         + (select count(*) from public.client_charges where status = 'draft' and created_at < now() - interval '14 days')
         + (select count(*) from public.billing_lines where status = 'draft' and generated_at < now() - interval '14 days'),
         'Draft claims, invoices, charges or billing lines waiting more than two weeks.'
$$;

grant select on public.billing_revenue to authenticated;
revoke all on public.billing_revenue from anon;
revoke execute on function public.billing_integrity_checks() from public, anon;
grant execute on function public.billing_integrity_checks() to authenticated;
