-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 153): one client per NDIS number and per My Aged Care ID.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into public.car_clients (name, status) values ('Ann', 'pending'), ('Bob', 'pending');
insert into public.client_details (client_id, ndis_number, aged_care_id) select id, '430000001', 'AC10000001' from public.car_clients where name = 'Ann';
select test.refused($$insert into public.client_details (client_id, ndis_number) select id, '430000001' from public.car_clients where name = 'Bob'$$, 'an NDIS number belongs to one client');
select test.refused($$insert into public.client_details (client_id, aged_care_id) select id, 'ac10000001' from public.car_clients where name = 'Bob'$$, 'a My Aged Care ID belongs to one client (any letter case)');
insert into public.client_details (client_id, ndis_number, aged_care_id) select id, '', '' from public.car_clients where name = 'Bob';
select test.ok((select count(*) from public.client_details where ndis_number = '') >= 1, 'blank numbers can repeat');
select test.refused($$select public.create_client_full('{"name": "Cy Dee", "given_name": "Cy", "family_name": "Dee"}'::jsonb, '{"ndis_number": "430000001"}'::jsonb, null, 'case_manager', array[(select id from public.client_programs where name = 'NDIS')])$$, 'a new client with an NDIS number in use is refused');
select test.ok(not exists (select 1 from public.car_clients where name = 'Cy Dee'), 'and nothing is left half-saved');
select test.ok(public.create_client_full('{"name": "Cy Dee", "given_name": "Cy", "family_name": "Dee"}'::jsonb, '{"ndis_number": "430000099"}'::jsonb, null, 'case_manager', array[(select id from public.client_programs where name = 'NDIS')]) is not null, 'a new number saves the client and details together');
\o
select 'All unique ID tests passed.';
