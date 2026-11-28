-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 170, review C7): seed data for tests/e2e/roster-billing.e2e.cjs. LOCAL ONLY:
-- run by that test against a local Supabase (npx supabase start), never against Dev or a real copy.
-- Fictional people and clients (names start "E2E"). Mirrors the set-up in
-- supabase/tests/roster_billing_checks.test.sql. Variables (psql -v): d1 = the shift day (tomorrow,
-- Sydney), qs / qe = that day's quarter. Skipped if the E2E clients already exist.
\set ON_ERROR_STOP 1
select not exists (select 1 from public.car_clients where name = 'E2E Zara') as need_seed \gset
\if :need_seed
-- People (made by the test through the sign-up API first): a Manager Administrator, a Billing
-- Officer (view and prepare), a Team Leader and a Staff Administrator (no Billing).
insert into public.job_titles (name, access_level) select 'Billing Officer', 'manager' where not exists (select 1 from public.job_titles where name = 'Billing Officer');
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Billing Officer') where email = 'e2e-bill@example.com';
insert into public.access_baselines (job_title_id, module_id, actions, scope, effect, note, by_system_admin)
select id, 'clients.billing', '{view,prepare}', 'all', 'allow', 'E2E: Billing Officer prepares', true from public.job_titles where name = 'Billing Officer';
insert into public.admin_designations (user_id, granted_by)
select (select id from public.profiles where email = 'e2e-boss@example.com'), (select id from public.profiles where email = 'e2e-owner@example.com');
-- Clients, programs, locations, services, funding.
insert into public.car_clients (name, status) values ('E2E Zara', 'active'), ('E2E Ivy', 'active');
insert into public.client_enrolments (client_id, program_id, scheme, starts_on)
select distinct on (c.id) c.id, p.id, p.scheme, (:'qs')::date - 365 from public.car_clients c, public.client_programs p
 where c.name in ('E2E Zara', 'E2E Ivy') and p.scheme = 'support_at_home' and p.active order by c.id, p.sort_order;
insert into public.client_locations (client_id, label, address, state, approved)
select id, 'Home', '1 Test St', 'NSW', true from public.car_clients where name in ('E2E Zara', 'E2E Ivy');
insert into public.client_services (client_id, program_id, label, start_date, location_id, shift_types)
select c.id, e.program_id, 'Home support', (:'qs')::date - 365, l.id, '{personal_care}'
  from public.car_clients c join public.client_locations l on l.client_id = c.id join public.client_enrolments e on e.client_id = c.id where c.name in ('E2E Zara', 'E2E Ivy');
insert into public.client_funding (client_id, service_id, period_start, period_end, total_amount, classification)
select c.id, s.id, (:'qs')::date, (:'qs')::date + 364, 40000, 4 from public.car_clients c join public.client_services s on s.client_id = c.id where c.name = 'E2E Zara';
insert into public.billing_payers (kind, client_id, name) select 'client', id, 'E2E Zara (client)' from public.car_clients where name = 'E2E Zara';

-- Billing set-up as the Manager Administrator.
select set_config('request.jwt.claims', (select json_build_object('sub', id, 'aal', 'aal2', 'role', 'authenticated')::text from public.profiles where email = 'e2e-boss@example.com'), false);
set role authenticated;
update public.billing_rule_checks set status = 'verified', value = 'As listed', source = 'E2E test', as_at = current_date where scheme = 'support_at_home';
update public.billing_scheme_rules set status = 'confirmed', rules_summary = 'E2E test rules', source = 'E2E test', as_at = current_date where scheme = 'support_at_home';
update public.billing_parameters set status = 'verified', source = 'E2E test', as_at = current_date;
insert into public.price_lists (scheme, name) values ('support_at_home', 'E2E Standard');
insert into public.price_list_versions (price_list_id, unit_minutes, rounding, minimum_minutes, crossing) select id, 15, 'up', 60, 'split' from public.price_lists where name = 'E2E Standard';
insert into public.price_list_bands (version_id, key, label, day_kind, starts_at, ends_at)
select v.id, b.k, b.l, b.d, b.s::time, b.e::time from public.price_list_versions v join public.price_lists pl on pl.id = v.price_list_id and pl.name = 'E2E Standard',
  (values ('wd_night', 'Weekday night', 'weekday', '00:00', '06:00'), ('wd_day', 'Weekday day', 'weekday', '06:00', '20:00'), ('wd_eve', 'Weekday evening', 'weekday', '20:00', '00:00'),
          ('sat', 'Saturday', 'saturday', null, null), ('sun', 'Sunday', 'sunday', null, null), ('ph', 'Public holiday', 'public_holiday', null, null)) b(k, l, d, s, e);
insert into public.price_items (version_id, label, band_key, price, sah_category)
select v.id, 'Home support', b.k, b.p, 'everyday_living' from public.price_list_versions v join public.price_lists pl on pl.id = v.price_list_id and pl.name = 'E2E Standard',
  (values ('wd_night', 100), ('wd_day', 80), ('wd_eve', 90), ('sat', 110), ('sun', 120), ('ph', 150)) b(k, p);
update public.price_list_versions set status = 'published', effective_from = (:'qs')::date - 365
 where price_list_id = (select id from public.price_lists where name = 'E2E Standard');
insert into public.client_contribution_rates (client_id, enrolment_id, category, rate_pct, effective_from, source)
select e.client_id, e.id, 'everyday_living', 17.5, (:'qs')::date - 365, 'E2E test letter' from public.client_enrolments e join public.car_clients c on c.id = e.client_id where c.name = 'E2E Zara';
reset role;

-- Terms for Zara only (Ivy has none): prepared by the Billing Officer, approved by the Manager Administrator.
select set_config('request.jwt.claims', (select json_build_object('sub', id, 'aal', 'aal2', 'role', 'authenticated')::text from public.profiles where email = 'e2e-bill@example.com'), false);
set role authenticated;
insert into public.client_service_terms (client_id, service_id, effective_from, enrolment_id, funding_id, price_list_id, quantity, unit, frequency, sah_category, funding_stream)
select c.id, s.id, (:'qs')::date - 365, e.id, f.id, (select id from public.price_lists where name = 'E2E Standard'), 6, 'hour', 'week', 'everyday_living', 'ongoing'
  from public.car_clients c join public.client_services s on s.client_id = c.id join public.client_enrolments e on e.client_id = c.id join public.client_funding f on f.client_id = c.id
 where c.name = 'E2E Zara';
update public.client_service_terms set status = 'pending_review' where client_id = (select id from public.car_clients where name = 'E2E Zara');
-- A small quarter: $300, care management $30, $270 to spend.
insert into public.client_quarter_budgets (client_id, enrolment_id, funding_id, quarter_start, quarter_end, classification, quarterly_amount, start_date, source)
select c.id, e.id, f.id, (:'qs')::date, (:'qe')::date, 4, 300, (:'qs')::date, 'E2E budget notice'
  from public.car_clients c join public.client_enrolments e on e.client_id = c.id join public.client_funding f on f.client_id = c.id where c.name = 'E2E Zara';
reset role;
select set_config('request.jwt.claims', (select json_build_object('sub', id, 'aal', 'aal2', 'role', 'authenticated')::text from public.profiles where email = 'e2e-boss@example.com'), false);
set role authenticated;
update public.client_service_terms set status = 'approved' where client_id = (select id from public.car_clients where name = 'E2E Zara');
update public.client_quarter_budgets set status = 'approved' where client_id = (select id from public.car_clients where name = 'E2E Zara');
reset role;
select set_config('request.jwt.claims', '', false);

-- Rostered shifts tomorrow (no worker yet, so no delivery evidence): two for Zara (the second goes
-- over the $270), one for Ivy (no billing terms).
insert into public.shifts (client_id, service_id, location_id, starts_at, ends_at, status, shift_type, ref)
select c.id, s.id, s.location_id, ((:'d1')::date + x.st::time) at time zone 'Australia/Sydney', ((:'d1')::date + x.en::time) at time zone 'Australia/Sydney', 'published', 'personal_care', x.ref
  from (values ('E2E Zara', '09:00', '11:00', 'E2E-R1'), ('E2E Zara', '13:00', '15:00', 'E2E-R2'), ('E2E Ivy', '16:00', '17:00', 'E2E-R3')) x(client, st, en, ref)
  join public.car_clients c on c.name = x.client join public.client_services s on s.client_id = c.id;
\endif
