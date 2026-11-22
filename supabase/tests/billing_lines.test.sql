-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 162): billing lines, quarter budgets and the funding ledger (Phase 4B).
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('boss2@example.com', 'Max', 'manager'), ('sam@example.com', 'Sam', 'support_worker'), ('cm@example.com', 'Casey', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('boss2@example.com'), ('sam@example.com'), ('cm@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.cid(p text) returns uuid language sql security definer as $$ select id from public.car_clients where name = p $$;
create function test.svc(p_client text) returns uuid language sql security definer as $$ select id from public.client_services where client_id = test.cid(p_client) and label = 'Home support' $$;
create function test.enrol(p_client text) returns uuid language sql security definer as $$ select id from public.client_enrolments where client_id = test.cid(p_client) and scheme = 'support_at_home' limit 1 $$;
create function test.qb(p_client text, p_start date) returns uuid language sql security definer as $$ select id from public.client_quarter_budgets where client_id = test.cid(p_client) and quarter_start = p_start $$;
-- A shift in Sydney time, with (optionally) an approved timesheet and a service record.
create function test.shift(p_client text, p_ref text, p_start text, p_end text, p_evidence text default 'both') returns uuid language plpgsql security definer as $$
declare v uuid;
begin
  insert into public.shifts (worker_id, client_id, service_id, location_id, starts_at, ends_at, status, shift_type, ref)
  select test.pid('sam@example.com'), test.cid(p_client), test.svc(p_client), l.id, (p_start::timestamp at time zone 'Australia/Sydney'), (p_end::timestamp at time zone 'Australia/Sydney'), 'published', 'personal_care', p_ref
    from public.client_locations l where l.client_id = test.cid(p_client) limit 1 returning id into v;
  if p_evidence in ('both', 'timesheet') then
    insert into public.shift_timesheets (shift_id, actual_start, actual_end, break_minutes, status) select id, starts_at, ends_at, 0, 'approved' from public.shifts where id = v;
  end if;
  if p_evidence = 'both' then
    insert into public.shift_service_records (shift_id, worker_id, client_id, delivered, client_wellbeing) values (v, test.pid('sam@example.com'), test.cid(p_client), 'Personal care as planned', 'settled');
  end if;
  return v;
end $$;
create function test.sid(p_ref text) returns uuid language sql security definer as $$ select id from public.shifts where ref = p_ref $$;
create function test.lines(p_ref text) returns text language sql security definer as $$
  select coalesce(string_agg(band_key || ':' || quantity || 'x' || unit_price || '=' || amount || coalesce('/c' || client_share, '') || '/' || status, ',' order by band_key, generated_at), '')
    from public.billing_lines where shift_id = test.sid(p_ref) $$;
create function test.n(p_email text, p_sql text) returns bigint language plpgsql as $$
declare v bigint;
begin
  perform test.act_as(p_email);
  execute 'set local role authenticated';
  execute 'select ' || p_sql into v;
  execute 'reset role';
  return v;
end $$;
grant execute on all functions in schema test to authenticated;
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Case Manager') where email = 'cm@example.com';
insert into public.job_titles (name, access_level) values ('Billing Officer', 'manager');
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Billing Officer') where email = 'boss2@example.com';
insert into public.access_baselines (job_title_id, module_id, actions, scope, effect, note, by_system_admin)
select id, 'clients.billing', '{view,prepare}', 'all', 'allow', 'Test: Billing Officer prepares', true from public.job_titles where name = 'Billing Officer';
insert into public.car_clients (name, status) values ('Zara', 'active'), ('Ben', 'active');
insert into public.client_locations (client_id, label, address, state, approved) values (test.cid('Zara'), 'Home', '1 Test St', 'NSW', true), (test.cid('Ben'), 'Home', '2 Test St', 'NSW', true);
insert into public.client_services (client_id, program_id, label, start_date, location_id, shift_types)
select c.id, p.id, 'Home support', '2026-07-01', l.id, '{personal_care}' from public.car_clients c join public.client_locations l on l.client_id = c.id, public.client_programs p where p.scheme = 'support_at_home' and c.name in ('Zara', 'Ben');
insert into public.client_funding (client_id, service_id, period_start, period_end, total_amount, classification) select test.cid('Zara'), test.svc('Zara'), '2026-07-01', '2027-06-30', 40000, 4;
select test.act_as('owner@example.com');
set role authenticated;
insert into public.admin_designations (user_id, granted_by) values (test.pid('boss@example.com'), test.pid('owner@example.com'));
reset role;

-- Set-up (as the Manager Administrator): rules confirmed, figures verified, prices, holiday, rates, terms.
select test.act_as('boss@example.com');
set role authenticated;
update public.billing_rule_checks set status = 'verified', value = 'As listed', source = 'Support at Home program manual', as_at = '2026-11-21' where scheme = 'support_at_home';
update public.billing_scheme_rules set status = 'confirmed', rules_summary = 'Provider price list; contribution by category; quarterly budget', source = 'Program manual', as_at = '2026-11-21' where scheme = 'support_at_home';
reset role;
select test.ok(test.n('boss@example.com', $q$(select count(*) from public.billing_parameters where status = 'verified')$q$) = 0, 'Support at Home figures start unverified');
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.client_quarter_budgets (client_id, enrolment_id, quarter_start, quarter_end, quarterly_amount, start_date, source) values (test.cid('Zara'), test.enrol('Zara'), '2026-07-01', '2026-09-30', 10000, '2026-07-01', 'x')$$, 'no quarter budget until the figures are verified');
select test.refused($$update public.billing_parameters set status = 'verified' where key = 'sah_care_management_pct'$$, 'a figure is verified only with its source and as-at date');
update public.billing_parameters set status = 'verified', source = 'Support at Home program manual', as_at = '2026-11-21';
select test.refused($$update public.billing_parameters set value = 12 where key = 'sah_care_management_pct'$$, 'a verified figure isn''t changed');
insert into public.price_lists (scheme, name) values ('support_at_home', 'Standard');
insert into public.price_list_versions (price_list_id, unit_minutes, rounding, minimum_minutes, crossing) select id, 15, 'up', 60, 'split' from public.price_lists;
insert into public.price_list_bands (version_id, key, label, day_kind, starts_at, ends_at) select v.id, b.k, b.l, b.d, b.s::time, b.e::time from public.price_list_versions v,
  (values ('wd_night', 'Weekday night', 'weekday', '00:00', '06:00'), ('wd_day', 'Weekday day', 'weekday', '06:00', '20:00'), ('wd_eve', 'Weekday evening', 'weekday', '20:00', '00:00'),
          ('sat', 'Saturday', 'saturday', null, null), ('sun', 'Sunday', 'sunday', null, null), ('ph', 'Public holiday', 'public_holiday', null, null)) b(k, l, d, s, e);
insert into public.price_items (version_id, label, band_key, price, sah_category) select v.id, 'Home support', b.k, b.p, 'everyday_living' from public.price_list_versions v,
  (values ('wd_night', 100), ('wd_day', 80), ('wd_eve', 90), ('sat', 110), ('sun', 120), ('ph', 150)) b(k, p);
update public.price_list_versions set status = 'published', effective_from = '2026-07-01';
insert into public.public_holidays (state, on_date, name) values ('NSW', '2026-11-10', 'Test holiday (NSW)'), ('VIC', '2026-11-11', 'Victorian only');
insert into public.client_contribution_rates (client_id, enrolment_id, category, rate_pct, effective_from, source) values
  (test.cid('Zara'), test.enrol('Zara'), 'everyday_living', 17.5, '2026-07-01', 'Services Australia letter'),
  (test.cid('Ben'), test.enrol('Ben'), 'everyday_living', 17.5, '2026-07-01', 'Services Australia letter');
reset role;
-- Terms prepared by the Billing Officer, approved by the Manager Administrator.
select test.act_as('boss2@example.com');
set role authenticated;
insert into public.client_service_terms (client_id, service_id, effective_from, enrolment_id, funding_id, price_list_id, quantity, unit, frequency, sah_category, funding_stream)
select c, test.svc(n), '2026-07-01', test.enrol(n), case when n = 'Zara' then (select id from public.client_funding limit 1) end, (select id from public.price_lists), 6, 'hour', 'week', 'everyday_living', 'ongoing'
  from (values ('Zara', test.cid('Zara')), ('Ben', test.cid('Ben'))) x(n, c);
update public.client_service_terms set status = 'pending_review';
reset role;
select test.act_as('boss@example.com');
set role authenticated;
update public.client_service_terms set status = 'approved';
reset role;

-- 1. Quarter budgets: made by one person, approved by another; figures from the verified register.
select test.act_as('boss2@example.com');
set role authenticated;
insert into public.client_quarter_budgets (client_id, enrolment_id, funding_id, quarter_start, quarter_end, classification, quarterly_amount, start_date, source)
values (test.cid('Zara'), test.enrol('Zara'), (select id from public.client_funding limit 1), '2026-07-01', '2026-09-30', 4, 10000, '2026-07-01', 'Services Australia budget notice');
select test.refused($$update public.client_quarter_budgets set status = 'approved' where id = test.qb('Zara', '2026-07-01')$$, 'the maker can''t approve their own budget');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
update public.client_quarter_budgets set status = 'approved' where id = test.qb('Zara', '2026-07-01');
select test.refused($$update public.client_quarter_budgets set quarterly_amount = 12000 where id = test.qb('Zara', '2026-07-01')$$, 'an approved budget isn''t changed');
reset role;
select test.ok((select prorated_amount = 10000 and care_management = 1000 and spendable = 9000 and care_management_pct = 10 from public.client_quarter_budgets where id = test.qb('Zara', '2026-07-01')),
  'a $10,000 quarter: care management $1,000, spendable $9,000');

-- 2. Delivered shifts become billing lines (made by the preparer).
select test.shift('Zara', 'S0', '2026-09-02 09:00', '2026-09-02 11:00');
select test.act_as('boss2@example.com');
set role authenticated;
select test.refused($$insert into public.billing_lines (client_id, shift_id, scheme, service_id, terms_id, enrolment_id, funding_stream, price_list_version_id, price_item_id, band_key, band_label, service_date, starts_at, ends_at, minutes_actual, minutes_billed, unit, quantity, unit_price, amount, gst_code)
  select test.cid('Zara'), test.sid('S0'), 'support_at_home', test.svc('Zara'), (select id from public.client_service_terms limit 1), test.enrol('Zara'), 'ongoing', (select id from public.price_list_versions), (select id from public.price_items limit 1), 'x', 'x', current_date, now(), now(), 1, 1, 'hour', 1, 1, 1, 'gst_free'$$, 'billing lines can''t be typed in; they''re made from delivered shifts');
select public.billing_generate('2026-09-01', '2026-09-30');
reset role;
select test.ok(test.lines('S0') = 'wd_day:2.00x80.00=160.00/c28.00/draft', 'weekday 9am-11am: 2 h x $80 = $160; client pays 17.5% = $28');
select test.ok((select government_share = 132 and quarter_budget_id = test.qb('Zara', '2026-07-01') and generated_by = test.pid('boss2@example.com') from public.billing_lines where shift_id = test.sid('S0')),
  'government share $132, charged to the quarter budget, made by the preparer');
select test.ok((select terms_id is not null and enrolment_id = test.enrol('Zara') and price_list_version_id is not null and contribution_rate_id is not null and calc ->> 'times_from' = 'approved timesheet' from public.billing_lines where shift_id = test.sid('S0')),
  'the line keeps its terms, enrolment, price list version, contribution rate and how it was worked out');
select test.act_as('boss2@example.com');
set role authenticated;
select test.ok((public.billing_generate('2026-09-01', '2026-09-30') ->> 'made')::int = 0, 'making lines again makes no duplicates');
select test.refused($$update public.billing_lines set status = 'approved' where shift_id = test.sid('S0')$$, 'the preparer can''t approve (and has no approve right)');
select test.refused($$update public.billing_lines set amount = 1 where shift_id = test.sid('S0')$$, 'amounts never change');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
update public.billing_lines set status = 'approved' where shift_id = test.sid('S0');
select test.refused($$delete from public.billing_lines$$, 'lines are never deleted');
reset role;
select test.ok((select string_agg(entry_kind || ':' || amount, ',') from public.funding_ledger where quarter_budget_id = test.qb('Zara', '2026-07-01')) = 'charge:-160.00', 'approving charges the full price to the quarter budget');
select test.ok((select available from public.funding_balances where account_id = test.qb('Zara', '2026-07-01')) = 8840, 'available: $9,000 - $160 = $8,840');
select test.ok((select sum(used_amount) from public.client_funding) = 0, 'the funding record itself never changes');

-- 3. Quarter close: carryover capped, the rest lapses; next quarter starts with the carryover.
select test.act_as('boss2@example.com');
set role authenticated;
select test.refused($$select public.billing_close_quarter(test.qb('Zara', '2026-07-01'))$$, 'only Billing approve closes a quarter');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select public.billing_close_quarter(test.qb('Zara', '2026-07-01'));
select test.refused($$select public.billing_close_quarter(test.qb('Zara', '2026-07-01'))$$, 'a quarter is closed once');
reset role;
select test.ok((select spent = 160 and unspent = 8840 and carryover_out = 1000 and lapsed = 7840 and status = 'closed' from public.client_quarter_budgets where id = test.qb('Zara', '2026-07-01')),
  'unspent $8,840: $1,000 carries over (the larger of $1,000 and 10%), $7,840 lapses');
select test.ok((select available from public.funding_balances where account_id = test.qb('Zara', '2026-07-01')) = 0, 'a closed quarter''s balance is zero (carryover and lapse are in the ledger)');
select test.act_as('boss2@example.com');
set role authenticated;
insert into public.client_quarter_budgets (client_id, enrolment_id, quarter_start, quarter_end, classification, quarterly_amount, start_date, source)
values (test.cid('Zara'), test.enrol('Zara'), '2026-10-01', '2026-12-31', 4, 10000, '2026-10-01', 'Services Australia budget notice');
-- Ben starts mid-quarter (16 Nov): pro rata, and a small budget to test going over it.
insert into public.client_quarter_budgets (client_id, enrolment_id, quarter_start, quarter_end, classification, quarterly_amount, start_date, source)
values (test.cid('Ben'), test.enrol('Ben'), '2026-10-01', '2026-12-31', 1, 200, '2026-11-16', 'Start notification');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
update public.client_quarter_budgets set status = 'approved' where status = 'draft';
reset role;
select test.ok((select carryover_in = 1000 and spendable = 10000 from public.client_quarter_budgets where id = test.qb('Zara', '2026-10-01')), 'the next quarter starts with the $1,000 carryover: spendable $10,000');
select test.ok((select prorated_amount = 100.00 and care_management = 10.00 and spendable = 90.00 from public.client_quarter_budgets where id = test.qb('Ben', '2026-10-01')),
  'a mid-quarter start is pro rata: 46 of 92 days of $200 = $100, care management $10');

-- 4. Rate bands, holidays, rounding and minimum, cancellations, delivery decisions, exceptions.
select test.shift('Zara', 'S1', '2026-11-04 09:00', '2026-11-04 11:00');
select test.shift('Zara', 'S2', '2026-11-04 19:00', '2026-11-04 21:00');
select test.shift('Zara', 'S3', '2026-11-10 10:00', '2026-11-10 11:00');
select test.shift('Zara', 'S4', '2026-11-05 13:00', '2026-11-05 13:40');
select test.shift('Zara', 'S5', '2026-11-06 09:00', '2026-11-06 10:00', 'none');
select test.shift('Zara', 'S7', '2026-11-06 13:00', '2026-11-06 14:00', 'timesheet');
select test.shift('Zara', 'S8', '2026-11-11 10:00', '2026-11-11 11:00');
insert into public.shifts (worker_id, client_id, service_id, location_id, starts_at, ends_at, status, shift_type, ref)
select test.pid('sam@example.com'), test.cid('Zara'), test.svc('Zara'), l.id, ('2026-11-12 09:00'::timestamp at time zone 'Australia/Sydney'), ('2026-11-12 11:00'::timestamp at time zone 'Australia/Sydney'), 'cancelled', 'personal_care', 'S6'
  from public.client_locations l where l.client_id = test.cid('Zara');
insert into public.shift_cancellations (shift_id, notified_at, cancelled_by, reason, reasonable_grounds, charge, charge_note) values (test.sid('S6'), '2026-11-12 07:00+11', 'client', 'Changed mind', false, 'charge', 'Late, no reasonable grounds');
select test.shift('Ben', 'B1', '2026-11-18 09:00', '2026-11-18 11:00');
select test.act_as('boss2@example.com');
set role authenticated;
select test.refused($$insert into public.billing_delivery_overrides (shift_id, decision, reason) values (test.sid('S7'), 'delivered', 'Worker forgot the service record')$$, 'only Billing approve decides delivery');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.billing_delivery_overrides (shift_id, decision, reason) values (test.sid('S7'), 'delivered', '')$$, 'a delivery decision needs a reason');
insert into public.billing_delivery_overrides (shift_id, decision, reason) values (test.sid('S7'), 'delivered', 'Worker confirmed by phone; service record to follow');
select test.refused($$update public.billing_delivery_overrides set reason = 'x'$$, 'a delivery decision is never changed');
reset role;
select test.act_as('boss2@example.com');
set role authenticated;
select public.billing_generate('2026-11-01', '2026-11-30');
reset role;
select test.ok(test.lines('S1') = 'wd_day:2.00x80.00=160.00/c28.00/draft', 'a weekday shift in one band: one line');
select test.ok(test.lines('S2') = 'wd_day:1.00x80.00=80.00/c14.00/draft,wd_eve:1.00x90.00=90.00/c15.75/draft', 'a shift crossing 8pm: one line per band (day $80 + evening $90)');
select test.ok(test.lines('S3') = 'ph:1.00x150.00=150.00/c26.25/draft', 'a public holiday in the location''s state (NSW) uses the holiday band');
select test.ok(test.lines('S8') = 'wd_day:1.00x80.00=80.00/c14.00/draft', 'another state''s holiday (VIC) doesn''t apply');
select test.ok(test.lines('S4') = 'wd_day:1.00x80.00=80.00/c14.00/draft' and (select minutes_actual = 40 and minutes_billed = 60 from public.billing_lines where shift_id = test.sid('S4')),
  '40 minutes: rounded up to 45, then the 60-minute minimum: 1 h');
select test.ok(test.lines('S5') = '', 'no timesheet or service record: not billed');
select test.ok(test.lines('S7') = 'wd_day:1.00x80.00=80.00/c14.00/draft' and (select calc ->> 'delivery_decision' is not null from public.billing_lines where shift_id = test.sid('S7')), 'a recorded delivery decision lets it be billed, and is kept with the line');
select test.ok((select kind = 'cancellation' and amount = 160 from public.billing_lines where shift_id = test.sid('S6')), 'a chargeable late cancellation is billed as a cancellation at the rostered times');
select test.ok((select over_budget from public.billing_lines where shift_id = test.sid('B1')), 'a line beyond the available budget is flagged over budget');
select test.ok((select count(*) from public.billing_exceptions('2026-11-01', '2026-11-30') where shift_id = test.sid('S5') and problem like 'Waiting for delivery evidence%') = 1, 'the shift without evidence is listed as an exception');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.billing_lines set status = 'approved' where shift_id = test.sid('B1')$$, 'an over-budget line needs a note saying how it''s covered');
update public.billing_lines set status = 'approved', approve_note = 'Private agreement signed 18 Nov 2026' where shift_id = test.sid('B1');
update public.billing_lines set status = 'approved' where status = 'draft';
-- Void and remake (the corrected line points to the original).
select test.refused($$update public.billing_lines set status = 'voided' where shift_id = test.sid('S1')$$, 'voiding needs a reason');
update public.billing_lines set status = 'voided', void_reason = 'wrong_rate' where shift_id = test.sid('S1');
select test.refused($$update public.billing_lines set status = 'approved' where shift_id = test.sid('S1') and status = 'voided'$$, 'a voided line never changes');
reset role;
select test.ok((select count(*) from public.funding_ledger where billing_line_id = (select id from public.billing_lines where shift_id = test.sid('S1')) and entry_kind = 'reversal' and amount = 160) = 1, 'voiding an approved line reverses its charge in the ledger');
select test.act_as('boss2@example.com');
set role authenticated;
select public.billing_generate('2026-11-04', '2026-11-04');
reset role;
select test.ok((select count(*) from public.billing_lines where shift_id = test.sid('S1') and status = 'draft' and corrects_id = (select id from public.billing_lines where shift_id = test.sid('S1') and status = 'voided')) = 1,
  'the shift gets a corrected line pointing to the voided one (the original is kept)');

-- 5. The ledger: opening balances and adjustments proposed and approved by different people; append-only.
select test.act_as('boss2@example.com');
set role authenticated;
select test.refused($$insert into public.funding_ledger (client_id, funding_id, entry_kind, amount, entry_date, reason) values (test.cid('Zara'), (select id from public.client_funding limit 1), 'charge', -50, current_date, 'x')$$, 'charges can''t be typed into the ledger');
select test.refused($$insert into public.funding_ledger (client_id, funding_id, entry_kind, amount, entry_date) values (test.cid('Zara'), (select id from public.client_funding limit 1), 'opening_balance', 5000, '2026-11-01')$$, 'an opening balance needs its source');
insert into public.funding_ledger (client_id, funding_id, entry_kind, amount, entry_date, reason) values (test.cid('Zara'), (select id from public.client_funding limit 1), 'opening_balance', 5000, '2026-11-01', 'Balance from the funding statement as at 1 Nov 2026');
select test.refused($$insert into public.funding_ledger (client_id, funding_id, entry_kind, amount, entry_date, reason) values (test.cid('Zara'), (select id from public.client_funding limit 1), 'opening_balance', 6000, '2026-11-01', 'again')$$, 'one opening balance per funding record');
insert into public.funding_ledger (client_id, quarter_budget_id, entry_kind, amount, entry_date, reason) values (test.cid('Zara'), test.qb('Zara', '2026-10-01'), 'adjustment', 250, '2026-11-15', 'Supplement added by Services Australia');
reset role;
select test.ok((select status from public.funding_ledger where entry_kind = 'opening_balance') = 'proposed', 'an opening balance starts as proposed (not counted)');
select test.act_as('boss@example.com');
set role authenticated;
update public.funding_ledger set status = 'approved' where status = 'proposed';
select test.refused($$update public.funding_ledger set amount = 1 where entry_kind = 'opening_balance'$$, 'ledger entries never change');
select test.refused($$delete from public.funding_ledger$$, 'ledger entries are never deleted');
reset role;
select test.ok((select decided_by = test.pid('boss@example.com') and created_by = test.pid('boss2@example.com') from public.funding_ledger where entry_kind = 'opening_balance'), 'records who proposed and who approved the opening balance');
select test.ok((select available from public.funding_balances where account_kind = 'funding' and account_id = (select id from public.client_funding limit 1)) = 5000, 'the funding record''s ledger balance is the approved opening balance');

-- 6. Access, audit, and nothing silent.
select test.ok(test.n('cm@example.com', '(select count(*) from public.billing_lines) + (select count(*) from public.funding_ledger) + (select count(*) from public.client_quarter_budgets)') = 0, 'a Case Manager sees no billing lines, ledger or budgets');
select test.ok(test.n('sam@example.com', '(select count(*) from public.billing_lines)') = 0, 'a support worker sees no billing lines');
select test.act_as('cm@example.com');
set role authenticated;
select test.refused($$select public.billing_generate('2026-11-01', '2026-11-30')$$, 'a Case Manager can''t make billing lines');
reset role;
select test.ok((select count(*) from public.audit_log where action like 'billing_lines_%') >= 10 and (select count(*) from public.audit_log where action like 'funding_ledger_%') >= 3, 'billing lines and the ledger are in the client audit trail');
select test.ok((select count(*) from public.audit_log where action = 'changed_billing_parameter') >= 3, 'verifying figures is in the change log');

\o
select 'All billing line tests passed.';
