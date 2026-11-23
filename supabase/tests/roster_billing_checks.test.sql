-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 170): Phase 6 roster billing checks and the budget forecast. Set-up as in billing_lines.
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
-- A third client with a service but no billing terms.
insert into public.car_clients (name, status) values ('Ivy', 'active');
insert into public.client_locations (client_id, label, address, state, approved) values (test.cid('Ivy'), 'Home', '3 Test St', 'NSW', true);
insert into public.client_services (client_id, program_id, label, start_date, location_id, shift_types)
select c.id, p.id, 'Home support', '2026-07-01', l.id, '{personal_care}' from public.car_clients c join public.client_locations l on l.client_id = c.id, public.client_programs p where p.scheme = 'support_at_home' and c.name = 'Ivy';
-- A small quarter for Zara: $300, care management $30, $270 to spend.
select test.act_as('boss2@example.com');
set role authenticated;
insert into public.client_quarter_budgets (client_id, enrolment_id, funding_id, quarter_start, quarter_end, classification, quarterly_amount, start_date, source)
values (test.cid('Zara'), test.enrol('Zara'), (select id from public.client_funding limit 1), '2026-07-01', '2026-09-30', 4, 300, '2026-07-01', 'Services Australia budget notice');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
update public.client_quarter_budgets set status = 'approved' where id = test.qb('Zara', '2026-07-01');
reset role;
select test.ok((select spendable = 270 from public.client_quarter_budgets where id = test.qb('Zara', '2026-07-01')), 'Zara has $270 to spend this quarter');

-- Rostered shifts, no delivery evidence yet.
select test.shift('Zara', 'R1', '2026-09-02 09:00', '2026-09-02 11:00', 'none');
select test.shift('Zara', 'R2', '2026-09-03 09:00', '2026-09-03 11:00', 'none');
update public.shifts set status = 'draft' where ref = 'R2';
select test.shift('Ben', 'R3', '2026-09-02 12:00', '2026-09-02 13:00', 'none');
select test.shift('Ivy', 'R4', '2026-09-02 14:00', '2026-09-02 15:00', 'none');
select test.shift('Zara', 'R5', '2026-09-04 09:00', '2026-09-04 10:00', 'none');
update public.shifts set status = 'cancelled' where ref = 'R5';

-- 1. The estimate uses the rostered times and needs no evidence; it never makes a line.
select test.ok((select string_agg(band_key || ':' || amount || '/' || (calc ->> 'times_from'), ',') from public.billing_calc(test.sid('R1'), 'estimate')) = 'wd_day:160.00/roster (estimate)',
  'a rostered 2-hour weekday shift is estimated at $160 from the roster');
select test.ok((select string_agg(band_key || ':' || amount, ',') from public.billing_calc(test.sid('R2'), 'estimate')) = 'wd_day:160.00', 'a draft shift is estimated too');
select test.ok((select problem from public.billing_calc(test.sid('R2'), 'service')) like 'The shift isn''t published%', 'a draft shift still can''t be billed');
select test.ok((select problem from public.billing_calc(test.sid('R1'), 'service')) like 'Waiting for delivery evidence%', 'a rostered shift isn''t billed without delivery evidence');
select test.ok((select problem from public.billing_calc(test.sid('R5'), 'estimate')) = 'The shift was cancelled.', 'a cancelled shift isn''t estimated');

-- 2. The forecast, as the Billing Officer (view right).
select test.act_as('boss2@example.com');
set role authenticated;
create temporary table f as select * from public.roster_billing_forecast('2026-09-01', '2026-09-30');
select test.refused($$select * from public.roster_billing_forecast('2026-01-01', '2026-09-30')$$, 'the forecast period is up to six months');
reset role;
select test.ok((select count(*) from f) = 4, 'four rostered, unbilled client shifts (the cancelled one left out)');
select test.ok((select severity = 'ok' and amount = 160 and client_share = 28 and account_kind = 'quarter_budget' and available_before = 270 and left_after = 110 from f where shift_id = test.sid('R1')),
  'first shift: $160 from the $270 quarter, $110 left; client pays $28');
select test.ok((select severity = 'over_budget' and left_after = -50 and problem like '%by $50.00%' from f where shift_id = test.sid('R2')),
  'second shift would go over by $50 (after the first)');
select test.ok((select severity = 'setup' and problem like 'No approved (open) Support at Home quarter budget%' from f where shift_id = test.sid('R3')),
  'Ben has terms but no quarter budget: a set-up item');
select test.ok((select severity = 'fix' and problem = 'No approved billing terms for this service on that date.' from f where shift_id = test.sid('R4')),
  'Ivy''s service has no approved billing terms: a fix');
select test.ok((select count(*) from public.billing_lines) = 0, 'estimates never make billing lines');
drop table f;

-- 3. Billed shifts drop out; draft lines count against the balance.
insert into public.shift_timesheets (shift_id, actual_start, actual_end, break_minutes, status) select id, starts_at, ends_at, 0, 'approved' from public.shifts where ref = 'R1';
insert into public.shift_service_records (shift_id, worker_id, client_id, delivered, client_wellbeing) values (test.sid('R1'), test.pid('sam@example.com'), test.cid('Zara'), 'Personal care as planned', 'settled');
select test.act_as('boss2@example.com');
set role authenticated;
select public.billing_generate('2026-09-01', '2026-09-30');
create temporary table f as select * from public.roster_billing_forecast('2026-09-01', '2026-09-30');
reset role;
select test.ok((select count(*) from public.billing_lines where shift_id = test.sid('R1') and status = 'draft') = 1, 'the delivered shift becomes a draft line');
select test.ok(not exists (select 1 from f where shift_id = test.sid('R1')), 'a billed shift leaves the forecast');
select test.ok((select available_before = 110 and left_after = -50 from f where shift_id = test.sid('R2')), 'the draft line counts against the balance: $270 - $160 = $110 before the next shift');
drop table f;

-- 4. Who sees it: Billing view right only.
select test.ok(test.n('sam@example.com', $q$(select count(*) from public.roster_billing_forecast('2026-09-01', '2026-09-30'))$q$) = 0, 'a support worker sees no billing forecast');
select test.ok(test.n('boss@example.com', $q$(select count(*) from public.roster_billing_forecast('2026-09-01', '2026-09-30', test.cid('Ivy')))$q$) = 1, 'one client at a time');

\o
select 'All roster billing check tests passed.';
