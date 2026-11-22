-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 166): Phase 5D. Consolidated financial reporting (D-066; built under D-068).
-- Read-only views and checks over what Phases 4 and 5 recorded; nothing here changes a record.
--   * billing_revenue: every approved billing line and client charge in one place (date, client,
--     scheme, funding stream, value, client share, government share), for reports.
--   * billing_integrity_checks(): consistency checks a finance person runs (recoveries above the
--     service value, issued documents without their PDF, totals that don't add up, money allocated
--     beyond what's owed, claims approved but not submitted, unmatched bank lines, old drafts).
--   * Monthly Support at Home statements carry the detail of a full statement (owner's sample,
--     23 Nov 2026): funds carried in, the quarter month by month (subsidy against expenditure and
--     what's left), this month's income and expenditure (services, other charges, care
--     management), and each service and charge with its category, contribution rate and share.
--     Added to new statements only; issued statements never change.
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

-- Statement detail (runs after the 163 snapshot and the 165 charges are added).
create or replace function public.statement_add_detail() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_end date := (new.month + interval '1 month' - interval '1 day')::date;
  b public.client_quarter_budgets;
  v_days integer;
  v_m date;
  v_months jsonb := '[]';
  v_from date;
  v_to date;
  v_sub numeric;
  v_exp numeric;
  v_cm numeric;
  v_svc numeric;
  v_chg numeric;
  v_month_sub numeric := 0;
  v_month_cm numeric := 0;
begin
  select * into b from public.client_quarter_budgets q where q.enrolment_id = new.enrolment_id and q.quarter_start <= new.month and q.quarter_end >= new.month and q.status <> 'draft';
  if b.id is not null then
    v_days := b.quarter_end - b.start_date + 1;
    v_m := date_trunc('month', b.quarter_start)::date;
    while v_m <= new.month loop
      v_from := greatest(v_m, b.start_date);
      v_to := least((v_m + interval '1 month' - interval '1 day')::date, b.quarter_end);
      -- The quarter's amount and care management spread by day (the budget's own days).
      v_sub := case when v_to < v_from then 0 else round(b.prorated_amount * (v_to - v_from + 1) / v_days, 2) end;
      v_cm := case when v_to < v_from then 0 else round(b.care_management * (v_to - v_from + 1) / v_days, 2) end;
      select coalesce(sum(amount), 0) into v_svc from public.billing_lines where quarter_budget_id = b.id and status = 'approved' and service_date between v_m and v_to;
      select coalesce(sum(amount), 0) into v_chg from public.client_charges where quarter_budget_id = b.id and status = 'approved' and service_date between v_m and v_to;
      v_months := v_months || jsonb_build_object('month', v_m, 'days', greatest(v_to - v_from + 1, 0), 'subsidy', v_sub, 'services', v_svc, 'charges', v_chg, 'care_management', v_cm, 'expenditure', v_svc + v_chg + v_cm);
      if v_m = new.month then v_month_sub := v_sub; v_month_cm := v_cm; end if;
      v_m := (v_m + interval '1 month')::date;
    end loop;
  end if;
  new.snapshot := new.snapshot || jsonb_build_object(
    'period_days', v_end - new.month + 1,
    'carried_in', jsonb_build_object(
      'rollover', coalesce(b.carryover_in, 0),
      'unspent_hcp', (select coalesce(sum(p.amount), 0) from public.client_pathway_budgets p where p.enrolment_id = new.enrolment_id and p.stream = 'hcp_unspent' and p.status <> 'draft' and p.starts_on <= v_end and p.ends_on >= new.month)),
    'quarter_months', v_months,
    'month_income', jsonb_build_object('subsidy', v_month_sub),
    'month_expenditure', jsonb_build_object(
      'services', (select coalesce(sum(amount), 0) from public.billing_lines where enrolment_id = new.enrolment_id and status = 'approved' and service_date between new.month and v_end),
      'other_charges', (select coalesce(sum(amount), 0) from public.client_charges where enrolment_id = new.enrolment_id and status = 'approved' and service_date between new.month and v_end),
      'care_management', v_month_cm),
    'service_lines', (select coalesce(jsonb_agg(jsonb_build_object('date', l.service_date, 'service', coalesce(sv.label, 'Service'), 'category', l.sah_category, 'pct', l.contribution_pct,
                        'quantity', l.quantity, 'unit', l.unit, 'rate', l.unit_price, 'band', l.band_label, 'kind', l.kind, 'amount', l.amount, 'client_share', l.client_share) order by l.service_date, l.starts_at), '[]')
                        from public.billing_lines l left join public.client_services sv on sv.id = l.service_id
                       where l.enrolment_id = new.enrolment_id and l.status = 'approved' and l.service_date between new.month and v_end),
    'charge_lines', (select coalesce(jsonb_agg(jsonb_build_object('date', c.service_date, 'description', c.description, 'stream', c.funding_stream, 'category', c.sah_category, 'pct', c.contribution_pct,
                        'amount', c.amount, 'client_share', c.client_share) order by c.service_date), '[]')
                       from public.client_charges c where c.enrolment_id = new.enrolment_id and c.status = 'approved' and c.service_date between new.month and v_end));
  return new;
end;
$$;
drop trigger if exists guard_statement_detail on public.client_statements;
create trigger guard_statement_detail before insert on public.client_statements for each row execute function public.statement_add_detail();
revoke execute on function public.statement_add_detail() from public, anon, authenticated;

grant select on public.billing_revenue to authenticated;
revoke all on public.billing_revenue from anon;
revoke execute on function public.billing_integrity_checks() from public, anon;
grant execute on function public.billing_integrity_checks() to authenticated;
