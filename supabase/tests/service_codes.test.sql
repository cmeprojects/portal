-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 167): service codes on the catalogue, the code prefix, and what isn't priced yet.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.code(p_name text) returns text language sql security definer as $$ select code from public.service_catalogue where name = p_name $$;
grant execute on all functions in schema test to authenticated;
select test.act_as('owner@example.com');
set role authenticated;
insert into public.admin_designations (user_id, granted_by) values (test.pid('boss@example.com'), test.pid('owner@example.com'));
reset role;

-- 1. Every existing service has a code, in catalogue order; new services get the next one.
select test.ok((select count(*) = count(code) and min(code) = 'SERV-0001' from public.service_catalogue), 'every catalogue service has a code, starting at SERV-0001');
select test.ok(test.code('Community Access') = 'SERV-0001', 'the first service in catalogue order is SERV-0001');
insert into public.service_catalogue (name, shift_types, sort_order) values ('Window Cleaning', '{domestic}', 900);
select test.ok(test.code('Window Cleaning') = 'SERV-' || lpad(((select count(*) from public.service_catalogue))::text, 4, '0'), 'a new service gets the next code automatically');

-- 2. The prefix: Manager Administrators (or Billing prices) set it; support workers can't.
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$update public.app_settings set value = '"XX"' where key = 'billing.service_code_prefix'$$, 'a support worker can''t change the prefix');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$update public.app_settings set value = '"BAD-1"' where key = 'billing.service_code_prefix'$$, 'the prefix is letters and numbers only');
update public.app_settings set value = '"WIC"' where key = 'billing.service_code_prefix';
reset role;
insert into public.service_catalogue (name, shift_types, sort_order) values ('Pet Care', '{domestic}', 910);
select test.ok(test.code('Pet Care') = 'WIC-0001' and test.code('Window Cleaning') like 'SERV-%', 'after the prefix change new services are WIC-0001 onwards; existing codes stay');

-- 3. Codes can be changed until the service is billed; never duplicated.
update public.service_catalogue set code = 'wic-pet' where name = 'Pet Care';
select test.ok(test.code('Pet Care') = 'WIC-PET', 'a code can be changed before the service is billed (kept in capitals)');
select test.refused($$update public.service_catalogue set code = 'SERV-0001' where name = 'Pet Care'$$, 'two services can''t share a code');
select test.refused($$update public.service_catalogue set code = 'no dash' where name = 'Pet Care'$$, 'a code is letters or numbers, a dash, then letters or numbers');
update public.service_catalogue set code = null where name = 'Pet Care';
select test.ok(test.code('Pet Care') = 'WIC-PET', 'clearing the code keeps the one it has');

-- 4. What isn't priced yet, and the code locked once billed.
select test.act_as('boss@example.com');
set role authenticated;
insert into public.price_lists (scheme, name) values ('support_at_home', 'Standard');
insert into public.price_list_versions (price_list_id, unit_minutes, rounding, minimum_minutes, crossing) select id, 15, 'nearest', 0, 'split' from public.price_lists;
reset role;
select test.ok((select count(*) > 0 from public.services_not_priced where kind = 'catalogue' and service = 'Pet Care'), 'Pet Care is listed as not priced yet in the Support at Home price list');
select test.act_as('boss@example.com');
set role authenticated;
insert into public.price_items (version_id, catalogue_id, label, price, sah_category) select v.id, c.id, c.name, 50, 'everyday_living' from public.price_list_versions v, public.service_catalogue c where c.name = 'Pet Care';
reset role;
select test.ok(not exists (select 1 from public.services_not_priced where service = 'Pet Care') and (select label from public.price_items where catalogue_id = (select id from public.service_catalogue where name = 'Pet Care')) = 'Pet Care',
  'once priced it''s off the list');
-- A billing line for that price (made directly; only the lock is tested here).
set session_replication_role = replica;
insert into public.billing_lines (client_id, shift_id, kind, status, scheme, service_id, terms_id, enrolment_id, funding_stream, price_list_version_id, price_item_id, band_key, band_label, service_date, starts_at, ends_at, minutes_actual, minutes_billed, unit, quantity, unit_price, amount, gst_code, personal_care, over_budget, approve_note, calc, generated_at, void_note, updated_at)
select gen_random_uuid(), gen_random_uuid(), 'service', 'approved', 'support_at_home', gen_random_uuid(), gen_random_uuid(), gen_random_uuid(), 'ongoing', i.version_id, i.id, 'x', 'x', current_date, now(), now(), 60, 60, 'hour', 1, 50, 50, 'gst_free', false, false, '', '{}', now(), '', now()
  from public.price_items i where i.catalogue_id = (select id from public.service_catalogue where name = 'Pet Care');
set session_replication_role = origin;
select test.refused($$update public.service_catalogue set code = 'WIC-0099' where name = 'Pet Care'$$, 'once billed, the code is locked');
select test.ok(public.service_billed((select id from public.service_catalogue where name = 'Pet Care')), 'the service shows as billed');
