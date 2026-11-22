-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 163): claims, client invoices and statements (Phase 5A).
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('boss2@example.com', 'Max', 'manager'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('boss2@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.cid(p text) returns uuid language sql security definer as $$ select id from public.car_clients where name = p $$;
create function test.svc(p_client text) returns uuid language sql security definer as $$ select id from public.client_services where client_id = test.cid(p_client) and label = 'Home support' $$;
create function test.enrol(p_client text, p_scheme text default 'support_at_home') returns uuid language sql security definer as $$ select id from public.client_enrolments where client_id = test.cid(p_client) and scheme = p_scheme limit 1 $$;
create function test.fund(p_client text) returns uuid language sql security definer as $$ select id from public.client_funding where client_id = test.cid(p_client) limit 1 $$;
create function test.shift(p_client text, p_ref text, p_start text, p_end text) returns uuid language plpgsql security definer as $$
declare v uuid;
begin
  insert into public.shifts (worker_id, client_id, service_id, location_id, starts_at, ends_at, status, shift_type, ref)
  select test.pid('sam@example.com'), test.cid(p_client), test.svc(p_client), l.id, (p_start::timestamp at time zone 'Australia/Sydney'), (p_end::timestamp at time zone 'Australia/Sydney'), 'published', 'personal_care', p_ref
    from public.client_locations l where l.client_id = test.cid(p_client) limit 1 returning id into v;
  insert into public.shift_timesheets (shift_id, actual_start, actual_end, break_minutes, status) select id, starts_at, ends_at, 0, 'approved' from public.shifts where id = v;
  insert into public.shift_service_records (shift_id, worker_id, client_id, delivered, client_wellbeing) values (v, test.pid('sam@example.com'), test.cid(p_client), 'Care as planned', 'settled');
  return v;
end $$;
create function test.sid(p_ref text) returns uuid language sql security definer as $$ select id from public.shifts where ref = p_ref $$;
create function test.line(p_ref text) returns uuid language sql security definer as $$ select id from public.billing_lines where shift_id = test.sid(p_ref) and status <> 'voided' limit 1 $$;
create function test.n(p_email text, p_sql text) returns bigint language plpgsql as $$
declare v bigint;
begin
  perform test.act_as(p_email);
  execute 'set local role authenticated';
  execute 'select ' || p_sql into v;
  execute 'reset role';
  return v;
end $$;
create function test.claim(p_program text) returns uuid language sql security definer as $$ select id from public.claims where program = p_program and status <> 'cancelled' order by prepared_at desc, id limit 1 $$;
grant execute on all functions in schema test to authenticated;
insert into public.job_titles (name, access_level) values ('Billing Officer', 'manager');
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Billing Officer') where email = 'boss2@example.com';
insert into public.access_baselines (job_title_id, module_id, actions, scope, effect, note, by_system_admin)
select id, 'clients.billing', '{view,prepare,prices,claim_prepare,invoice_prepare}', 'all', 'allow', 'Test: Billing Officer prepares', true from public.job_titles where name = 'Billing Officer';
insert into public.car_clients (name, status) values ('Zara', 'active'), ('Ned', 'active');
insert into public.client_locations (client_id, label, address, state, approved) values (test.cid('Zara'), 'Home', '1 Test St', 'NSW', true), (test.cid('Ned'), 'Home', '9 Bush Rd', 'NSW', true);
insert into public.client_services (client_id, program_id, label, start_date, location_id, shift_types)
select c.id, p.id, 'Home support', '2026-07-01', l.id, '{personal_care}' from public.car_clients c join public.client_locations l on l.client_id = c.id
  join public.client_programs p on p.scheme = case when c.name = 'Ned' then 'ndis' else 'support_at_home' end where c.name in ('Zara', 'Ned');
insert into public.client_funding (client_id, service_id, period_start, period_end, total_amount, classification) select test.cid('Zara'), test.svc('Zara'), '2026-07-01', '2027-06-30', 40000, 4;
insert into public.client_funding (client_id, service_id, period_start, period_end, total_amount, plan_management) select test.cid('Ned'), test.svc('Ned'), '2026-07-01', '2027-06-30', 30000, 'ndia';
select test.act_as('owner@example.com');
set role authenticated;
insert into public.admin_designations (user_id, granted_by) values (test.pid('boss@example.com'), test.pid('owner@example.com'));
reset role;

-- Set-up (Manager Administrator): rules confirmed WITHOUT the new official link, version and review date.
select test.act_as('boss@example.com');
set role authenticated;
update public.billing_rule_checks set status = 'verified', value = 'As listed', source = 'Official guidance', as_at = '2026-11-21' where scheme in ('support_at_home', 'ndis');
update public.billing_scheme_rules set status = 'confirmed', rules_summary = 'As documented', source = 'Program manual', as_at = '2026-11-21' where scheme in ('support_at_home', 'ndis');
update public.billing_parameters set status = 'verified', source = 'Support at Home program manual', as_at = '2026-11-21';
insert into public.price_lists (scheme, name) values ('support_at_home', 'Standard'), ('ndis', 'NDIS');
insert into public.price_list_versions (price_list_id, unit_minutes, rounding, minimum_minutes, crossing) select id, 15, 'nearest', 0, 'split' from public.price_lists;
insert into public.price_list_bands (version_id, key, label, day_kind, starts_at, ends_at) select v.id, b.k, b.l, b.d, b.s::time, b.e::time from public.price_list_versions v,
  (values ('wd_night', 'Weekday night', 'weekday', '00:00', '06:00'), ('wd_day', 'Weekday day', 'weekday', '06:00', '20:00'), ('wd_eve', 'Weekday evening', 'weekday', '20:00', '00:00'),
          ('sat', 'Saturday', 'saturday', null, null), ('sun', 'Sunday', 'sunday', null, null), ('ph', 'Public holiday', 'public_holiday', null, null)) b(k, l, d, s, e);
insert into public.price_items (version_id, label, price, sah_category, ndis_item)
select v.id, 'Home support', case when l.scheme = 'ndis' then 70 else 80 end, case when l.scheme = 'support_at_home' then 'everyday_living' end, case when l.scheme = 'ndis' then '01_011_0107_1_1' else '' end
  from public.price_list_versions v join public.price_lists l on l.id = v.price_list_id;
update public.price_list_versions set status = 'published', effective_from = '2026-07-01';
insert into public.client_contribution_rates (client_id, enrolment_id, category, rate_pct, effective_from, source) values
  (test.cid('Zara'), test.enrol('Zara'), 'everyday_living', 17.5, '2026-07-01', 'Services Australia letter');
reset role;
select test.act_as('boss2@example.com');
set role authenticated;
insert into public.client_service_terms (client_id, service_id, effective_from, enrolment_id, funding_id, price_list_id, quantity, unit, frequency, sah_category, funding_stream)
values (test.cid('Zara'), test.svc('Zara'), '2026-07-01', test.enrol('Zara'), test.fund('Zara'), (select id from public.price_lists where scheme = 'support_at_home'), 6, 'hour', 'week', 'everyday_living', 'ongoing'),
       (test.cid('Ned'), test.svc('Ned'), '2026-07-01', test.enrol('Ned', 'ndis'), test.fund('Ned'), (select id from public.price_lists where scheme = 'ndis'), 4, 'hour', 'week', null, 'ndis_plan');
update public.client_service_terms set status = 'pending_review';
insert into public.client_quarter_budgets (client_id, enrolment_id, funding_id, quarter_start, quarter_end, classification, quarterly_amount, start_date, source)
values (test.cid('Zara'), test.enrol('Zara'), test.fund('Zara'), '2026-07-01', '2026-09-30', 4, 10000, '2026-07-01', 'Services Australia budget notice');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
update public.client_service_terms set status = 'approved';
update public.client_quarter_budgets set status = 'approved';
reset role;
select test.shift('Zara', 'S1', '2026-09-02 09:00', '2026-09-02 11:00');
select test.shift('Ned', 'N1', '2026-09-03 09:00', '2026-09-03 11:00');
select test.act_as('boss2@example.com');
set role authenticated;
select public.billing_generate('2026-09-01', '2026-09-30');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
update public.billing_lines set status = 'approved', approve_note = case when over_budget then 'Plan funds checked in the NDIS portal' else approve_note end where status = 'draft';
reset role;
select test.ok((select string_agg(scheme || ':' || amount || ':' || coalesce(client_share::text, '-'), ',' order by scheme) from public.billing_lines where status = 'approved')
  = 'ndis:140.00:0.00,support_at_home:160.00:28.00', 'set-up: an approved Support at Home line ($160, client $28) and an NDIS line ($140)');

-- 1. ABN check and business details (versions; GST verified by the accountant).
select test.ok(public.abn_valid('51824753556') and not public.abn_valid('51824753557') and not public.abn_valid('1234'), 'ABNs are checked with the official checksum');
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$insert into public.business_details (legal_name, abn, address, suburb, state, postcode) values ('X', '51824753556', '1 St', 'Town', 'NSW', '2000')$$, 'a support worker can''t enter business details');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.business_details (legal_name, abn, address, suburb, state, postcode) values ('Wear It Care', '12345678901', '1 St', 'Town', 'NSW', '2000')$$, 'an invalid ABN is refused');
select test.refused($$insert into public.business_details (legal_name, abn, address, suburb, state, postcode, gst_verified_by_name) values ('Wear It Care', '51824753556', '1 St', 'Town', 'NSW', '2000', 'A. Accountant')$$, 'GST verification needs both who and when');
insert into public.business_details (legal_name, abn, address, suburb, state, postcode, email, payment_bsb, payment_account_number, payment_account_name)
values ('Wear It Care Pty Ltd', '51 824 753 556', '1 Test St', 'Sydney', 'NSW', '2000', 'accounts@example.com', '062-000', '12345678', 'Wear It Care');
select test.refused($$update public.business_details set legal_name = 'Changed'$$, 'business details are never edited (new version instead)');
reset role;
select test.ok((select version = 1 and abn = '51824753556' and not gst_verified from public.business_current), 'version 1 saved; ABN without spaces; GST not verified yet');

-- 2. Compliance register: claims need every rule verified with its official link, version and review date.
select test.act_as('boss2@example.com');
set role authenticated;
select test.refused($$select public.claim_prepare('support_at_home', '2026-09-01', '2026-09-30')$$, 'no claim while rules lack their official link, version and review date');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
update public.billing_rule_checks set official_url = 'https://www.health.gov.au/support-at-home', document_version = 'Program manual v1', effective_from = '2025-11-01', review_by = '2027-06-30' where scheme in ('support_at_home', 'ndis');
update public.billing_parameters set official_url = 'https://www.health.gov.au/support-at-home', document_version = 'Program manual v1', review_by = '2027-06-30';
select test.refused($$update public.billing_rule_checks set official_url = 'https://example.com' where scheme = 'ndis'$$, 'a verified rule keeps its official link');
reset role;
select test.act_as('boss2@example.com');
set role authenticated;
select test.refused($$select public.claim_prepare('support_at_home', '2026-09-01', '2026-09-30')$$, 'no claim until the official claim template is uploaded and verified');
select test.refused($$insert into public.claims (program, payer_id, period_from, period_to) select 'support_at_home', id, '2026-09-01', '2026-09-30' from public.billing_payers where kind = 'services_australia'$$, 'claims can''t be typed in');
insert into public.claim_templates (program, name, headers, date_format, file_name_max) values ('support_at_home', 'Services Australia claim', '["Provider ID","Care Recipient ID","Service Date","Service Type","Units","Unit Price","Amount"]', 'YYYY-MM-DD', 50);
select test.refused($$update public.claim_templates set status = 'verified'$$, 'the preparer can''t verify a template');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.claim_templates set status = 'verified'$$, 'a template is verified only with its official link, version and review date');
update public.claim_templates set official_url = 'https://www.servicesaustralia.gov.au/aged-care-provider-portal', document_version = '2026-11', review_by = '2027-05-31', status = 'verified';
select test.refused($$update public.claim_templates set headers = '["Changed"]'$$, 'a verified template never changes');
select test.refused($$delete from public.claim_templates$$, 'a verified template is never deleted');
insert into public.claim_templates (program, name, headers, official_url, document_version, review_by) values ('ndis', 'NDIS Bulk Upload File', '["RegistrationNumber","NDISNumber","SupportsDeliveredFrom","SupportsDeliveredTo","SupportNumber","ClaimReference","Quantity","Hours","UnitPrice","GSTCode"]', 'https://www.ndis.gov.au/providers/working-provider/getting-paid', '2026', '2027-05-31');
update public.claim_templates set status = 'verified' where program = 'ndis';
reset role;
select test.ok((select bool_and(verified_by = test.pid('boss@example.com')) from public.claim_templates where status = 'verified'), 'templates record who verified them');

-- 3. Support at Home claim: lines plus the quarter's care management (clinical, no contribution).
select test.act_as('boss2@example.com');
set role authenticated;
select public.claim_prepare('support_at_home', '2026-09-01', '2026-09-30');
reset role;
select test.ok((select item_count = 2 and total_claimed = 1160 and total_expected = 1132 and status = 'draft' from public.claims where id = test.claim('support_at_home')),
  'claim: the $160 line (Services Australia pays $132) plus $1,000 care management');
select test.ok((select count(*) = 1 from public.care_management_accounts where in_claim and allocated = 1000), 'care management is in its own account, now in a claim');
select test.act_as('boss2@example.com');
set role authenticated;
select test.ok((public.claim_prepare('support_at_home', '2026-09-01', '2026-09-30') ->> 'lines')::int = 0, 'preparing again finds nothing: a line is claimed once');
select test.refused($$update public.claims set status = 'approved' where id = test.claim('support_at_home')$$, 'the preparer can''t approve');
reset role;
-- The empty second draft is cancelled with a reason.
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.claims set status = 'cancelled' where item_count = 0$$, 'cancelling needs a reason');
update public.claims set status = 'cancelled', cancel_reason = 'Nothing to claim' where item_count = 0;
select test.refused($$update public.claims set status = 'submitted' where id = test.claim('support_at_home')$$, 'a claim can''t be marked submitted directly');
update public.claims set status = 'approved' where id = test.claim('support_at_home');
select test.refused($$update public.claim_items set status = 'removed' where claim_id = test.claim('support_at_home')$$, 'an approved claim''s lines don''t change');
select test.refused($$update public.billing_lines set status = 'voided', void_reason = 'other', void_note = 'x' where id = test.line('S1')$$, 'a claimed line can''t be voided');
select test.refused($$insert into public.claim_submissions (claim_id, submitted_at, channel, external_reference) values (test.claim('support_at_home'), now(), 'aged_care_provider_portal', 'REF-1')$$, 'no submission before the file is made');
update public.claims set file_name = 'sah-claim-2026-09.csv', file_content = 'Provider ID,Care Recipient ID' || chr(10), file_checksum = 'abc' where id = test.claim('support_at_home');
select test.refused($$update public.claims set file_content = 'x' where id = test.claim('support_at_home')$$, 'the claim file is made once');
reset role;
select test.ok((select status = 'approved' and file_generated_by = test.pid('boss@example.com') from public.claims where id = test.claim('support_at_home')), 'downloading the file doesn''t mark the claim submitted');
select test.act_as('boss2@example.com');
set role authenticated;
select test.refused($$insert into public.claim_submissions (claim_id, submitted_at, channel, external_reference) values (test.claim('support_at_home'), now(), 'aged_care_provider_portal', 'REF-1')$$, 'only the claim submit right records a submission');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.claim_submissions (claim_id, submitted_at, channel, external_reference) values (test.claim('support_at_home'), now(), 'aged_care_provider_portal', '')$$, 'a submission needs the portal''s reference');
insert into public.claim_submissions (claim_id, submitted_at, channel, external_reference, notes) values (test.claim('support_at_home'), now() - interval '1 hour', 'aged_care_provider_portal', 'SA-2026-0917', 'Uploaded in the Aged Care Provider Portal');
select test.refused($$update public.claim_submissions set external_reference = 'X'$$, 'a submission record never changes');
select test.refused($$update public.claims set notes = 'x' where id = test.claim('support_at_home')$$, 'a submitted claim never changes');
update public.claim_submissions set acknowledgement = 'Accepted in full' where claim_id = test.claim('support_at_home');
reset role;
select test.ok((select c.status = 'acknowledged' and s.submitted_by = test.pid('boss@example.com') and s.acknowledged_at is not null from public.claims c join public.claim_submissions s on s.claim_id = c.id where c.id = test.claim('support_at_home')),
  'recording the upload marks it submitted; the acknowledgement marks it acknowledged');
select test.ok((select claimed = 1000 from public.care_management_accounts), 'the care management account shows the submitted claim');
select test.ok(test.n('sam@example.com', $q$(select count(*) from public.claims)$q$) = 0 and test.n('boss2@example.com', $q$(select count(*) from public.claims)$q$) = 2, 'support workers don''t see claims; billing staff do');

-- 4. NDIS agency-managed claim: "my provider", pricing zone of the delivery location, catalogue in force.
select test.act_as('boss2@example.com');
set role authenticated;
select public.claim_prepare('ndis', '2026-09-01', '2026-09-30');
select test.ok((select excluded -> 0 ->> 'reason' like 'Not recorded as "my provider"%' and item_count = 0 from public.claims where id = test.claim('ndis')), 'not "my provider": the line is listed as excluded, with the reason');
insert into public.ndis_plan_details (funding_id, my_provider, recorded_on) values (test.fund('Ned'), true, '2026-07-01');
select public.claim_prepare('ndis', '2026-09-01', '2026-09-30');
select test.ok((select excluded -> 0 ->> 'reason' like '%no NDIS pricing zone%' from public.claims where id = test.claim('ndis')), 'no pricing zone for the delivery location: excluded');
insert into public.client_location_pricing (location_id, ndis_zone, mmm, source) select id, 'remote', 'MM6', 'Modified Monash Model locator' from public.client_locations where client_id = test.cid('Ned');
select public.claim_prepare('ndis', '2026-09-01', '2026-09-30');
select test.ok((select excluded -> 0 ->> 'reason' like 'No verified NDIS catalogue%' from public.claims where id = test.claim('ndis')), 'no verified catalogue in force on the support date: excluded');
insert into public.ndis_catalogue_versions (name, effective_from, official_url, document_version, review_by) values ('Support Catalogue 2026-27 (test)', '2026-07-01', 'https://www.ndis.gov.au/providers/pricing-arrangements', '2026-27 v1.0', '2027-06-30');
insert into public.ndis_support_items (version_id, item_number, item_name, unit, limit_national, limit_remote, limit_very_remote) select id, '01_011_0107_1_1', 'Assistance with self-care', 'H', 60, 65, 68 from public.ndis_catalogue_versions;
reset role;
select test.act_as('boss@example.com');
set role authenticated;
update public.ndis_catalogue_versions set status = 'verified';
select test.refused($$update public.ndis_support_items set limit_remote = 99$$, 'a verified catalogue never changes');
reset role;
select test.act_as('boss2@example.com');
set role authenticated;
select public.claim_prepare('ndis', '2026-09-01', '2026-09-30');
select test.ok((select excluded -> 0 ->> 'reason' like '%above the NDIS limit $65.00%remote%' from public.claims where id = test.claim('ndis')), 'price $70 above the remote-zone limit $65: excluded');
insert into public.ndis_catalogue_versions (name, effective_from, official_url, document_version, review_by) values ('Support Catalogue update (test)', '2026-09-01', 'https://www.ndis.gov.au/providers/pricing-arrangements', '2026-27 v1.1', '2027-06-30');
insert into public.ndis_support_items (version_id, item_number, unit, limit_national, limit_remote, limit_very_remote) select id, '01_011_0107_1_1', 'H', 70, 75, 80 from public.ndis_catalogue_versions where document_version = '2026-27 v1.1';
reset role;
select test.act_as('boss@example.com');
set role authenticated;
update public.ndis_catalogue_versions set status = 'verified' where status = 'draft';
reset role;
select test.act_as('boss2@example.com');
set role authenticated;
select public.claim_prepare('ndis', '2026-09-01', '2026-09-30');
reset role;
select test.ok((select r.ndis_zone = 'remote' and r.ndis_limit = 75 and r.ndis_item = '01_011_0107_1_1' and r.amount = 140 and v.document_version = '2026-27 v1.1'
                  from public.line_recoveries r join public.ndis_catalogue_versions v on v.id = r.ndis_catalogue_version_id where r.line_id = test.line('N1')),
  'with the catalogue in force from 1 Sep (limit $75): claimed; zone, item, limit and catalogue version kept');

-- 5. Client invoices: payer needed, fee reduction supplement, GST verified before issue, numbering.
select test.shift('Zara', 'S2', '2026-09-09 09:00', '2026-09-09 11:00');
select test.act_as('boss2@example.com');
set role authenticated;
select public.billing_generate('2026-09-01', '2026-09-30');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
update public.billing_lines set status = 'approved' where status = 'draft';
insert into public.client_fee_reductions (client_id, enrolment_id, starts_on, source) values (test.cid('Zara'), test.enrol('Zara'), '2026-09-09', 'Services Australia fee reduction supplement notice');
reset role;
select test.act_as('boss2@example.com');
set role authenticated;
select test.ok((public.invoice_prepare('sah_contribution', '2026-09-01', '2026-09-30') -> 'excluded' -> 0 ->> 'reason') like 'No billing contact%', 'no billing contact for the client: listed, no invoice');
insert into public.billing_payers (kind, client_id, name, email) values ('client', test.cid('Zara'), 'Zara (self)', 'zara@example.com');
insert into public.client_payer_links (client_id, role, payer_id, starts_on) select test.cid('Zara'), 'client', id, '2026-07-01' from public.billing_payers where client_id = test.cid('Zara');
select test.ok((public.invoice_prepare('sah_contribution', '2026-09-01', '2026-09-30') -> 'excluded' -> 0 ->> 'reason') = 'Full fee reduction supplement applies.', 'the 9 Sep line is covered by the fee reduction supplement');
select test.refused($$update public.client_payer_links set payer_id = payer_id, starts_on = '2026-01-01'$$, 'a payer link only gets an end date');
reset role;
select test.ok((select count(*) = 1 and sum(total) = 28 and bool_and(status = 'draft' and number is null) from public.invoices), 'one draft invoice for the $28 contribution, not numbered yet');
select test.act_as('boss@example.com');
set role authenticated;
update public.invoices set status = 'approved';
select test.refused($$update public.invoices set status = 'issued'$$, 'not issued while the GST position isn''t verified');
insert into public.business_details (legal_name, abn, address, suburb, state, postcode, gst_registered, gst_verified_by_name, gst_verified_on, gst_evidence)
values ('Wear It Care Pty Ltd', '51824753556', '1 Test St', 'Sydney', 'NSW', '2000', true, 'A. Accountant (CPA)', '2026-11-20', 'Letter on file');
update public.invoices set status = 'issued';
select test.refused($$update public.invoices set total = 1$$, 'an issued invoice never changes');
select test.refused($$update public.invoice_items set status = 'removed'$$, 'an issued invoice''s lines never change');
update public.invoices set pdf_base64 = 'JVBERi0=', pdf_checksum = 'x';
select test.refused($$update public.invoices set pdf_base64 = 'other'$$, 'the issued document never changes');
update public.invoices set status = 'sent', sent_note = 'Emailed';
reset role;
select test.ok((select number = 'INV-' || extract(year from now() at time zone 'Australia/Sydney')::int || '-000001' and not tax_invoice and gst = 0 and business_version = 2
                       and snapshot -> 'business' ->> 'abn' = '51824753556' and due_date = issue_date + 14 and status = 'sent' from public.invoices),
  'issued as INV-YYYY-000001; not a tax invoice (GST-free care); business details snapshot; due in 14 days');
select test.refused($$delete from public.invoices$$, 'invoices are never deleted');

-- 6. Monthly statement (Support at Home), issued once.
select test.act_as('boss2@example.com');
set role authenticated;
select test.refused($$insert into public.client_statements (client_id, enrolment_id, month) values (test.cid('Zara'), test.enrol('Zara'), '2026-09-01')$$, 'only the invoice issue right issues statements');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.client_statements (client_id, enrolment_id, month) values (test.cid('Zara'), test.enrol('Zara'), date_trunc('month', now() at time zone 'Australia/Sydney')::date)$$, 'not until the month has ended');
insert into public.client_statements (client_id, enrolment_id, month) values (test.cid('Zara'), test.enrol('Zara'), '2026-09-01');
select test.refused($$update public.client_statements set month = '2026-08-01'$$, 'a statement never changes');
reset role;
select test.ok((select (snapshot ->> 'spent_in_month')::numeric = 320 and (snapshot ->> 'contributions_in_month')::numeric = 28 and (snapshot ->> 'fee_reduction_in_month')::boolean and jsonb_array_length(snapshot -> 'lines') = 2 from public.client_statements),
  'September statement: $320 of services, $28 contributions (the fee reduction covers 9 Sep), two lines');

-- 7. Review dates: a verified rule past its review date pauses claims and line approval.
select test.shift('Zara', 'S3', '2026-09-16 09:00', '2026-09-16 11:00');
select test.act_as('boss2@example.com');
set role authenticated;
select public.billing_generate('2026-09-01', '2026-09-30');
reset role;
update public.billing_rule_checks set review_by = '2026-01-01' where scheme = 'support_at_home' and item like 'Care management account%';
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.billing_lines set status = 'approved' where status = 'draft'$$, 'line approval pauses while a rule is past its review date');
reset role;
select test.act_as('boss2@example.com');
set role authenticated;
select test.refused($$select public.claim_prepare('support_at_home', '2026-09-01', '2026-09-30')$$, 'claims pause while a rule is past its review date');
reset role;
select test.ok(public.billing_scheme_ready('support_at_home') like '%past its review date%' and public.billing_scheme_ready('chsp') like '%aren''t confirmed%', 'the reason is shown; CHSP stays blocked');
