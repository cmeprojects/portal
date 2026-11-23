-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 170): Phase 6, tying rostering to billing (owner, 23 Nov 2026; D-075).
-- Rostering already checks the client's approved service, its shift types and the program on the
-- shift date (updates 143 and 158). This adds the billing side, as checks and warnings, never as a
-- block on rostering:
--  * billing_calc() gains an "estimate" kind: the same calculation from the rostered times, for a
--    draft or published shift, with no delivery evidence needed. It never makes a billing line;
--    delivered shifts still need the approved timesheet and service record (or a delivery decision).
--  * roster_billing_forecast(): each rostered client shift not billed yet, with its estimate, the
--    reason it couldn't be billed (missing terms, enrolment, price, location state, contribution
--    rate, quarter budget, scheme rules), and the funding account it will draw on, with the
--    balance left after the shifts before it (approved balance, less draft lines, less earlier
--    estimates). Rows only for clients the person can see in Billing (the database decides).
-- People without the Billing view right see no billing detail on the roster.
-- No new security definer function. Safe to run again.

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
  elsif p_kind = 'estimate' then
    -- cmeprojects (update 170): an estimate for a rostered shift (draft or published), from the
    -- rostered times. Used only for roster checks and the budget forecast; never makes a line.
    if sh.status = 'cancelled' then
      return query select 'The shift was cancelled.'::text, null::uuid, null::text, null::text, null::int, null::int, null::numeric, null::text, null::numeric, null::numeric, null::uuid, null::uuid, null::text, null::numeric, null::uuid, null::numeric, null::numeric, null::uuid, null::uuid, false, null::date, null::timestamptz, null::timestamptz, null::text, '{}'::jsonb; return;
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
        'crossing', ver.crossing, 'break_minutes', v_break, 'times_from', case when p_kind = 'cancellation' then 'roster (cancellation)' when p_kind = 'estimate' then 'roster (estimate)' when ts.status = 'approved' then 'approved timesheet' else 'roster (delivery decision)' end,
        'delivery_decision', ov.id, 'scheme', v_scheme, 'available_before', v_avail, 'minimum_added', case when r.band = (select band from pg_temp.billing_mins order by mins desc, band limit 1) then v_extra else 0 end);
  end loop;
end;
$$;
create or replace function public.roster_billing_forecast(p_from date, p_to date, p_client uuid default null)
returns table (shift_id uuid, client_id uuid, service_id uuid, starts_at timestamptz, shift_status text, severity text, problem text,
               amount numeric, client_share numeric, account_kind text, account_id uuid, available_before numeric, left_after numeric)
language plpgsql set search_path = '' as $$
#variable_conflict use_column
declare
  s record;
  c record;
  v_left jsonb := '{}';
  v_key text;
  v_avail numeric;
  v_amount numeric;
  v_client numeric;
  v_problem text;
  v_kind text;
  v_account uuid;
begin
  if p_to < p_from or p_to - p_from > 190 then
    raise exception 'Choose a period of up to six months.';
  end if;
  for s in select sh.id, sh.client_id, sh.service_id, sh.starts_at, sh.status from public.shifts sh
            where sh.client_id is not null and sh.status in ('draft', 'published') and (p_client is null or sh.client_id = p_client)
              and (sh.starts_at at time zone 'Australia/Sydney')::date between p_from and p_to
              and not exists (select 1 from public.billing_lines bl where bl.shift_id = sh.id and bl.status <> 'voided')
              and public.billing_can('view', sh.client_id)
            order by sh.starts_at, sh.id loop
    v_amount := 0; v_client := 0; v_problem := null; v_kind := null; v_account := null;
    for c in select * from public.billing_calc(s.id, 'estimate') loop
      if c.problem is not null then v_problem := c.problem; exit; end if;
      v_amount := v_amount + c.amount;
      v_client := case when c.client_share is null or v_client is null then null else v_client + c.client_share end;
      if c.quarter_budget_id is not null then v_kind := 'quarter_budget'; v_account := c.quarter_budget_id;
      elsif c.funding_id is not null then v_kind := 'funding'; v_account := c.funding_id; end if;
    end loop;
    shift_id := s.id; client_id := s.client_id; service_id := s.service_id; starts_at := s.starts_at; shift_status := s.status;
    account_kind := v_kind; account_id := v_account; available_before := null; left_after := null;
    if v_problem is not null then
      severity := case when v_problem like 'Billing rules for this scheme%' or v_problem like 'No approved (open) Support at Home quarter budget%' then 'setup' else 'fix' end;
      problem := v_problem; amount := null; client_share := null;
      return next;
      continue;
    end if;
    amount := v_amount; client_share := v_client; problem := null; severity := 'ok';
    if v_account is not null then
      v_key := v_kind || ':' || v_account;
      if not (v_left ? v_key) then
        select b.available into v_avail from public.funding_balances b where b.account_kind = v_kind and b.account_id = v_account;
        if v_kind = 'quarter_budget' then
          v_avail := coalesce(v_avail, (select q.spendable from public.client_quarter_budgets q where q.id = v_account), 0)
                   - coalesce((select sum(bl.amount) from public.billing_lines bl where bl.quarter_budget_id = v_account and bl.status = 'draft'), 0);
        else
          v_avail := coalesce(v_avail, 0) - coalesce((select sum(bl.amount) from public.billing_lines bl where bl.funding_id = v_account and bl.status = 'draft'), 0);
        end if;
        v_left := v_left || jsonb_build_object(v_key, v_avail);
      end if;
      available_before := (v_left ->> v_key)::numeric;
      left_after := available_before - v_amount;
      v_left := v_left || jsonb_build_object(v_key, left_after);
      if left_after < 0 then
        severity := 'over_budget';
        problem := 'Would go over the available budget by ' || to_char(-left_after, 'FM$999,999,990.00') || ' (after earlier rostered shifts).';
      end if;
    end if;
    return next;
  end loop;
end;
$$;
revoke execute on function public.roster_billing_forecast(date, date, uuid) from public, anon;
grant execute on function public.roster_billing_forecast(date, date, uuid) to authenticated;
