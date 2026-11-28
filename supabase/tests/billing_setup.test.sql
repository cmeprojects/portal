-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 161): billing set-up (Phase 4A).
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('boss2@example.com', 'Max', 'manager'), ('sam@example.com', 'Sam', 'support_worker'),
  ('cm@example.com', 'Casey', 'support_worker'), ('io@example.com', 'Ira', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('boss2@example.com'), ('sam@example.com'), ('cm@example.com'), ('io@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.cid(p text) returns uuid language sql security definer as $$ select id from public.car_clients where name = p $$;
create function test.n(p_email text, p_sql text) returns bigint language plpgsql as $$
declare v bigint;
begin
  perform test.act_as(p_email);
  execute 'set local role authenticated';
  execute 'select ' || p_sql into v;
  execute 'reset role';
  return v;
end $$;
create function test.svc() returns uuid language sql security definer as $$ select id from public.client_services where label = 'Home support' $$;
create function test.enrol(p_scheme text) returns uuid language sql security definer as $$ select id from public.client_enrolments where client_id = test.cid('Zara') and scheme = p_scheme limit 1 $$;
create function test.ver(p_v int) returns uuid language sql security definer as $$ select v.id from public.price_list_versions v join public.price_lists l on l.id = v.price_list_id where l.name = 'Standard' and v.version = p_v $$;
create function test.terms(p_v int) returns uuid language sql security definer as $$ select id from public.client_service_terms where service_id = test.svc() and version = p_v $$;
grant execute on all functions in schema test to authenticated;
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Case Manager') where email = 'cm@example.com';
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Intake & Assessment Officer') where email = 'io@example.com';
insert into public.car_clients (name, status) values ('Zara', 'active'), ('Ben', 'active');
insert into public.client_assignments (client_id, user_id) values (test.cid('Zara'), test.pid('cm@example.com'));
insert into public.client_locations (client_id, label, address, state, approved) values (test.cid('Zara'), 'Home', '1 Test St', 'NSW', true);
insert into public.client_services (client_id, program_id, label, start_date, location_id)
select test.cid('Zara'), p.id, 'Home support', '2026-07-01', l.id from public.client_programs p, public.client_locations l where p.scheme = 'support_at_home' and l.label = 'Home' limit 1;
insert into public.client_funding (client_id, service_id, period_start, period_end, total_amount, classification)
select test.cid('Zara'), test.svc(), '2026-10-01', '2026-12-31', 9000, 4;
insert into public.client_agreements (client_id, service_id, starts_on) values (test.cid('Zara'), test.svc(), '2026-07-01');
select test.act_as('owner@example.com');
set role authenticated;
insert into public.admin_designations (user_id, granted_by) values (test.pid('boss@example.com'), test.pid('owner@example.com'));
reset role;

-- 1. Access: Billing is its own part, separate from Funding.
select test.ok((select actions @> '{view,prepare,approve,prices,export}' from public.app_modules where id = 'clients.billing'), 'Billing has view, prepare, approve, prices and export (update 163 adds the claim and invoice actions)');
select test.ok(test.n('owner@example.com', 'public.billing_can(''approve'')::int') = 1 and test.n('owner@example.com', 'public.billing_can(''export'')::int') = 1, 'the System Administrator has every Billing action');
select test.ok(test.n('boss@example.com', '(public.billing_can(''view'')::int + public.billing_can(''prepare'')::int + public.billing_can(''approve'')::int + public.billing_can(''prices'')::int + public.billing_can(''export'')::int)') = 5, 'a Manager Administrator has every Billing action by default');
select test.ok(test.n('boss2@example.com', 'public.billing_can(''view'')::int') = 0, 'another manager has no Billing by default');
select test.ok((select count(*) from public.access_baselines where module_id = 'clients.billing' and revoked_at is null) = 0, 'no Billing default for any access level, job title or group');
-- cmeprojects (review C6, 27 Nov 2026): every Billing action, for every role, by default.
-- The full list is read from the Billing part itself, so a sixteenth action can't slip through untested.
insert into public.invitations (email, full_name, role) values
  ('pay@example.com', 'Pat', 'support_worker'), ('ros@example.com', 'Rory', 'support_worker'), ('tl@example.com', 'Terry', 'team_leader'), ('sa@example.com', 'Sasha', 'staff_admin');
insert into auth.users (email) values ('pay@example.com'), ('ros@example.com'), ('tl@example.com'), ('sa@example.com');
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Payroll Officer') where email = 'pay@example.com';
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Rostering Officer') where email = 'ros@example.com';
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Team Leader') where email = 'tl@example.com';
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Staff Administrator') where email = 'sa@example.com';
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Support Worker') where email = 'sam@example.com';
create function test.billing_actions(p_email text) returns text language plpgsql as $$
declare v text;
begin
  perform test.act_as(p_email);
  execute 'set local role authenticated';
  select coalesce(string_agg(a, ',' order by o) filter (where public.billing_can(a)), '') into v
    from unnest((select actions from public.app_modules where id = 'clients.billing')) with ordinality x(a, o);
  execute 'reset role';
  return v;
end $$;
grant execute on function test.billing_actions(text) to authenticated;
select test.ok((select array_to_string(actions, ',') from public.app_modules where id = 'clients.billing')
  = 'view,prepare,approve,prices,export,claim_prepare,claim_approve,claim_submit,invoice_prepare,invoice_approve,invoice_issue,payment_record,refund,write_off,reconcile',
  'Billing has exactly the 15 approved actions');
select test.ok(test.billing_actions('owner@example.com') = (select array_to_string(actions, ',') from public.app_modules where id = 'clients.billing'), 'the System Administrator has all 15 Billing actions');
select test.ok(test.billing_actions('boss@example.com') = (select array_to_string(actions, ',') from public.app_modules where id = 'clients.billing'), 'a Manager Administrator has all 15 Billing actions');
select test.ok(test.billing_actions(e) = '', 'no Billing action by default: ' || r)
  from (values ('boss2@example.com', 'another manager'), ('cm@example.com', 'Case Manager'), ('io@example.com', 'Intake & Assessment Officer'),
               ('pay@example.com', 'Payroll Officer'), ('ros@example.com', 'Rostering Officer'), ('tl@example.com', 'Team Leader'),
               ('sa@example.com', 'Staff Administrator'), ('sam@example.com', 'Support Worker')) v(e, r);
-- A restriction on the Access page still applies to a Manager Administrator.
insert into public.access_grants (module_id, user_id, granted_by, effect, actions) values ('clients.billing', test.pid('boss@example.com'), test.pid('owner@example.com'), 'restrict', '{approve}');
select test.ok(test.n('boss@example.com', 'public.billing_can(''approve'')::int') = 0 and test.n('boss@example.com', 'public.billing_can(''view'')::int') = 1, 'a restriction on the Access page overrides the Manager Administrator default (only for the restricted action)');
update public.access_grants set revoked_at = now() where module_id = 'clients.billing' and user_id = test.pid('boss@example.com');
-- Another manager is given Billing on the Access page (by job title).
insert into public.job_titles (name, access_level) values ('Finance Manager', 'manager');
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Finance Manager') where email = 'boss2@example.com';
insert into public.access_baselines (job_title_id, module_id, actions, scope, effect, note, by_system_admin)
select id, 'clients.billing', '{}', 'all', 'allow', 'Test: Finance Manager has Billing', true from public.job_titles where name = 'Finance Manager';
select test.ok(test.n('boss2@example.com', 'public.billing_can(''approve'')::int') = 1, 'another manager given Billing on the Access page (job title) has it');
select test.ok(test.n('cm@example.com', 'public.billing_can(''view'', test.cid(''Zara''))::int') = 0, 'a Case Manager (who can change funding) has no Billing access');
select test.ok(test.n('io@example.com', 'public.billing_can(''view'')::int') = 0 and test.n('io@example.com', 'public.can(''clients.funding'', ''edit'', test.cid(''Zara''))::int') = 1, 'Funding rights don''t give Billing');
select test.ok(test.n('sam@example.com', '(select count(*) from public.price_lists) + (select count(*) from public.billing_scheme_rules)') = 0, 'a support worker sees no billing set-up');

-- 2. Scheme rules: off until confirmed; figures verified first.
select test.ok((select count(*) from public.billing_scheme_rules where status = 'not_confirmed') = (select count(*) from public.client_schemes), 'every scheme starts not confirmed');
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.billing_scheme_rules set status = 'confirmed' where scheme = 'private'$$, 'confirming needs the rules, source and as-at date');
select test.refused($$update public.billing_scheme_rules set status = 'confirmed', rules_summary = 'x', source = 'y', as_at = current_date where scheme = 'support_at_home'$$, 'a scheme with unverified figures can''t be confirmed');
select test.refused($$update public.billing_rule_checks set status = 'verified' where scheme = 'ndis' and item like 'Claims within 90 days%'$$, 'a figure is verified only with its value, source and as-at date');
update public.billing_rule_checks set status = 'verified', value = 'Up to 90 days after the support', source = 'NDIA Pricing Schedule 2026-27', as_at = '2026-11-21' where scheme = 'ndis' and item like 'Claims within 90 days%';
update public.billing_scheme_rules set status = 'confirmed', rules_summary = 'Provider price list; GST-free; invoice monthly', source = 'Owner decision', as_at = '2026-11-21' where scheme = 'private';
select test.refused($$delete from public.billing_scheme_rules$$, 'rules are never deleted');
reset role;
select test.ok((select checked_by = test.pid('boss@example.com') from public.billing_rule_checks where scheme = 'ndis' and item like 'Claims within 90 days%'), 'records who verified a figure');
select test.ok((select status = 'confirmed' and confirmed_by = test.pid('boss@example.com') from public.billing_scheme_rules where scheme = 'private'), 'records who confirmed a scheme');
select test.act_as('cm@example.com');
set role authenticated;
select test.refused($$update public.billing_scheme_rules set status = 'not_confirmed' where scheme = 'private'$$, 'a Case Manager can''t change billing rules');
reset role;

-- 3. Price lists: versions, bands (independent of payroll), rounding; published never changes.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.price_lists (scheme, name) values ('support_at_home', 'Standard');
insert into public.price_list_versions (price_list_id, unit_minutes, rounding, minimum_minutes, crossing) select id, 15, 'up', 60, 'split' from public.price_lists where name = 'Standard';
insert into public.price_list_bands (version_id, key, label, day_kind, starts_at, ends_at) values
  (test.ver(1), 'wd_day', 'Weekday day', 'weekday', '06:00', '20:00'),
  (test.ver(1), 'wd_eve', 'Weekday evening', 'weekday', '20:00', '00:00'),
  (test.ver(1), 'sat', 'Saturday', 'saturday', null, null),
  (test.ver(1), 'sun', 'Sunday', 'sunday', null, null),
  (test.ver(1), 'ph', 'Public holiday', 'public_holiday', null, null);
insert into public.price_items (version_id, label, band_key, price, sah_category) values (test.ver(1), 'Cleaning', 'wd_day', 80, 'everyday_living');
select test.refused($$update public.price_list_versions set status = 'published', effective_from = '2026-07-01' where id = test.ver(1)$$, 'weekday bands must cover the whole day (midnight to 6am missing)');
insert into public.price_list_bands (version_id, key, label, day_kind, starts_at, ends_at) values (test.ver(1), 'wd_night', 'Weekday night', 'weekday', '00:00', '06:00');
insert into public.price_items (version_id, label, band_key, price) values (test.ver(1), 'No category', 'sat', 90);
select test.refused($$update public.price_list_versions set status = 'published', effective_from = '2026-07-01' where id = test.ver(1)$$, 'every Support at Home price needs its category');
delete from public.price_items where label = 'No category';
select test.refused($$update public.price_list_versions set status = 'published' where id = test.ver(1)$$, 'publishing needs an effective date');
update public.price_list_versions set status = 'published', effective_from = '2026-07-01' where id = test.ver(1);
select test.refused($$update public.price_items set price = 85 where version_id = test.ver(1)$$, 'a published price never changes');
select test.refused($$insert into public.price_list_bands (version_id, key, label, day_kind) values (test.ver(1), 'x', 'x', 'sunday')$$, 'or its bands');
select test.refused($$update public.price_list_versions set rounding = 'down' where id = test.ver(1)$$, 'or its rounding rule');
select test.refused($$delete from public.price_list_versions where id = test.ver(1)$$, 'a published version is never deleted');
select public.price_list_new_version((select id from public.price_lists where name = 'Standard'));
select test.refused($$select public.price_list_new_version((select id from public.price_lists where name = 'Standard'))$$, 'one draft at a time');
update public.price_items set price = 84 where version_id = test.ver(2);
-- Draft changes are in the change log: additions, edits and removals of bands and prices.
insert into public.price_list_bands (version_id, key, label, day_kind) values (test.ver(2), 'tmp_sun', 'Temporary', 'sunday');
update public.price_list_bands set label = 'Temporary band' where version_id = test.ver(2) and key = 'tmp_sun';
delete from public.price_list_bands where version_id = test.ver(2) and key = 'tmp_sun';
insert into public.price_items (version_id, label, band_key, price, sah_category) values (test.ver(2), 'Gardening', 'sat', 95, 'everyday_living');
update public.price_items set price = 96 where version_id = test.ver(2) and label = 'Gardening';
delete from public.price_items where version_id = test.ver(2) and label = 'Gardening';
select test.refused($$update public.price_list_versions set status = 'published', effective_from = '2026-07-01' where id = test.ver(2)$$, 'a new version takes effect after the one it replaces');
update public.price_list_versions set status = 'published', effective_from = '2027-01-01' where id = test.ver(2);
reset role;
select test.ok((select count(*) from public.price_list_bands where version_id = test.ver(2)) = 6 and (select price from public.price_items where version_id = test.ver(2)) = 84, 'the new version copied bands and prices');
select test.ok((select status from public.price_list_versions where id = test.ver(1)) = 'retired' and (select price from public.price_items where version_id = test.ver(1)) = 80, 'publishing retires the old version, which keeps its prices');
select test.ok((select unit_minutes = 15 and rounding = 'up' and minimum_minutes = 60 and crossing = 'split' from public.price_list_versions where id = test.ver(2)), 'rounding, minimum and boundary rule are kept with the version');
select test.ok((select count(*) from public.audit_log where entity in ('price_list_version', 'price_item', 'price_list_band')) >= 5, 'price changes are in the change log');
select test.ok((select count(*) from public.audit_log where action = 'added_price_list_band' and details ->> 'key' = 'tmp_sun') = 1
           and (select count(*) from public.audit_log where action = 'changed_price_list_band' and details -> 'after' ->> 'label' = 'Temporary band') = 1
           and (select count(*) from public.audit_log where action = 'removed_price_list_band' and details ->> 'key' = 'tmp_sun') = 1,
  'a draft rate band''s addition, edit and removal are each in the change log');
select test.ok((select count(*) from public.audit_log where action = 'added_price_item' and details ->> 'label' = 'Gardening') = 1
           and (select count(*) from public.audit_log where action = 'changed_price_item' and details -> 'after' ->> 'price' = '96.00') = 1
           and (select count(*) from public.audit_log where action = 'removed_price_item' and details ->> 'label' = 'Gardening' and details ->> 'price' = '96.00') = 1,
  'a draft price''s addition, edit and removal are each in the change log');
select test.ok((select string_agg(details ->> 'label', ',') from public.audit_log where action = 'removed_price_item' and details ->> 'version_id' = test.ver(1)::text) = 'No category',
  'version 1 only lost a price while it was a draft; nothing was removed once published');
select test.act_as('cm@example.com');
set role authenticated;
select test.refused($$insert into public.price_lists (scheme, name) values ('ndis', 'Mine')$$, 'a Case Manager can''t make price lists');
reset role;

-- 4. Public holidays by state.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.public_holidays (state, on_date, name) values ('NSW', '2026-12-25', 'Christmas Day'), ('VIC', '2026-11-03', 'Melbourne Cup');
select test.refused($$insert into public.public_holidays (state, on_date, name) values ('NSW', '2026-12-25', 'Again')$$, 'one holiday per state and date');
select test.refused($$update public.public_holidays set on_date = '2026-12-26' where name = 'Christmas Day'$$, 'a holiday keeps its date');
select test.refused($$delete from public.public_holidays$$, 'holidays are switched off, not deleted');
update public.public_holidays set active = false where name = 'Melbourne Cup';
reset role;

-- 5. Contribution rates (Support at Home), dated.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.client_contribution_rates (client_id, enrolment_id, category, rate_pct, contribution_group, effective_from, source)
values (test.cid('Zara'), test.enrol('support_at_home'), 'everyday_living', 17.5, 'standard', '2026-07-01', 'Services Australia letter, 3 Jul 2026');
select test.refused($$insert into public.client_contribution_rates (client_id, enrolment_id, category, rate_pct, effective_from, source) values (test.cid('Zara'), test.enrol('support_at_home'), 'everyday_living', 20, '2026-10-01', 'x')$$, 'overlapping rates for one category are refused');
select test.refused($$insert into public.client_contribution_rates (client_id, enrolment_id, category, rate_pct, effective_from, source) values (test.cid('Zara'), test.enrol('ndis'), 'clinical', 0, '2026-10-01', 'x')$$, 'only on a Support at Home enrolment');
select test.refused($$update public.client_contribution_rates set rate_pct = 20$$, 'a recorded rate isn''t changed');
update public.client_contribution_rates set effective_to = '2026-09-30';
insert into public.client_contribution_rates (client_id, enrolment_id, category, rate_pct, effective_from, source) values (test.cid('Zara'), test.enrol('support_at_home'), 'everyday_living', 20, '2026-10-01', 'Services Australia letter, 2 Oct 2026');
select test.refused($$update public.client_contribution_rates set effective_to = '2026-08-31' where rate_pct = 17.5$$, 'an ended rate stays ended');
select test.refused($$delete from public.client_contribution_rates$$, 'rates are never deleted');
reset role;

-- 6. Billing terms for approved services: dated versions, separate approval.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.price_lists (scheme, name) values ('ndis', 'NDIS list');
select test.refused($$insert into public.client_service_terms (client_id, service_id, effective_from, enrolment_id) values (test.cid('Zara'), test.svc(), '2026-07-01', test.enrol('ndis'))$$, 'the enrolment must be in the service''s program');
select test.refused($$insert into public.client_service_terms (client_id, service_id, effective_from, enrolment_id) values (test.cid('Zara'), test.svc(), '2026-06-01', test.enrol('support_at_home'))$$, 'terms start within the service''s dates');
select test.refused($$insert into public.client_service_terms (client_id, service_id, effective_from, enrolment_id, price_list_id) values (test.cid('Zara'), test.svc(), '2026-07-01', test.enrol('support_at_home'), (select id from public.price_lists where name = 'NDIS list'))$$, 'the price list must be for the service''s scheme');
insert into public.client_service_terms (client_id, service_id, effective_from, enrolment_id, funding_id, agreement_id, price_list_id, quantity, unit, frequency, funding_stream)
values (test.cid('Zara'), test.svc(), '2026-07-01', test.enrol('support_at_home'), (select id from public.client_funding limit 1), (select id from public.client_agreements limit 1), (select id from public.price_lists where name = 'Standard'), 3, 'hour', 'week', 'ongoing');
select test.refused($$update public.client_service_terms set status = 'pending_review' where id = test.terms(1)$$, 'Support at Home terms need the category before review');
update public.client_service_terms set sah_category = 'everyday_living' where id = test.terms(1);
update public.client_service_terms set status = 'pending_review' where id = test.terms(1);
select test.refused($$update public.client_service_terms set status = 'approved' where id = test.terms(1)$$, 'the person who made and sent them can''t approve them');
select test.refused($$update public.client_service_terms set quantity = 4 where id = test.terms(1)$$, 'terms are fixed while waiting for review');
reset role;
select test.act_as('cm@example.com');
set role authenticated;
select test.refused($$update public.client_service_terms set status = 'approved' where id = test.terms(1)$$, 'a Case Manager can''t approve billing terms (no Billing right)');
select test.ok((select count(*) from public.client_service_terms) = 0, 'a Case Manager can''t see billing terms');
reset role;
select test.act_as('boss2@example.com');
set role authenticated;
select test.refused($$update public.client_service_terms set status = 'changes_required' where id = test.terms(1)$$, 'changes required needs a note');
update public.client_service_terms set status = 'approved' where id = test.terms(1);
select test.refused($$update public.client_service_terms set quantity = 5 where id = test.terms(1)$$, 'approved terms never change');
select test.refused($$delete from public.client_service_terms where id = test.terms(1)$$, 'approved terms are kept');
-- A new version from 1 Oct supersedes the first, which ends on 30 Sep.
insert into public.client_service_terms (client_id, service_id, effective_from, enrolment_id, price_list_id, quantity, unit, frequency, sah_category, funding_stream)
values (test.cid('Zara'), test.svc(), '2026-10-01', test.enrol('support_at_home'), (select id from public.price_lists where name = 'Standard'), 4, 'hour', 'week', 'everyday_living', 'ongoing');
update public.client_service_terms set status = 'pending_review' where id = test.terms(2);
reset role;
select test.act_as('boss@example.com');
set role authenticated;
update public.client_service_terms set status = 'approved' where id = test.terms(2);
reset role;
select test.ok((select status = 'superseded' and effective_to = '2026-09-30' and quantity = 3 and approved_by = test.pid('boss2@example.com') from public.client_service_terms where id = test.terms(1)),
  'the earlier terms are superseded, end the day before, and keep what was approved and by whom');
select test.ok((select status = 'approved' and version = 2 and approved_by = test.pid('boss@example.com') and submitted_by = test.pid('boss2@example.com') from public.client_service_terms where id = test.terms(2)), 'the new terms record who submitted and approved them');
select test.ok((select count(*) from public.audit_log where action like 'client_service_terms_%') >= 4, 'terms are in the client audit trail');
select test.ok((select count(*) from public.client_care_plans) + (select count(*) from public.client_funding where used_amount <> 0) = 0, 'approving terms changes no care plan or funding record');

-- 7. Cancellation details.
update public.client_services set shift_types = '{personal_care}' where id = test.svc();
insert into public.shifts (client_id, service_id, location_id, starts_at, ends_at, status, shift_type)
select test.cid('Zara'), test.svc(), l.id, v.s, v.e, v.st, 'personal_care' from public.client_locations l,
  (values ('2026-11-10 09:00+11'::timestamptz, '2026-11-10 11:00+11'::timestamptz, 'cancelled'), ('2026-11-11 09:00+11', '2026-11-11 11:00+11', 'draft')) v(s, e, st);
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.shift_cancellations (shift_id, notified_at, cancelled_by, reason) select id, now(), 'client', 'x' from public.shifts where status = 'draft'$$, 'details go on cancelled shifts only');
insert into public.shift_cancellations (shift_id, notified_at, cancelled_by, reason) select id, '2026-11-09 18:00+11', 'client', 'Felt unwell' from public.shifts where status = 'cancelled';
select test.refused($$update public.shift_cancellations set charge = 'charge'$$, 'a charge decision needs its reason');
select test.refused($$update public.shift_cancellations set charge = 'charge', charge_note = 'Late', reasonable_grounds = true$$, 'with reasonable grounds accepted, no charge');
update public.shift_cancellations set charge = 'no_charge', charge_note = 'Sudden illness: reasonable grounds', reasonable_grounds = true;
select test.refused($$delete from public.shift_cancellations$$, 'cancellation details are kept');
reset role;
select test.ok((select decided_by = test.pid('boss@example.com') and client_id = test.cid('Zara') from public.shift_cancellations), 'records who decided the charge, and the client');
select test.ok((select count(*) from public.audit_log where action like 'shift_cancellations_%') >= 2, 'cancellation details are in the client audit trail');

\o
select 'All billing set-up tests passed.';
