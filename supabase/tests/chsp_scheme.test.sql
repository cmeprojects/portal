-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 151): CHSP as a scheme; the My Aged Care ID is needed.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into public.car_clients (name, status, scheme) values ('Cora', 'pending', 'chsp');
insert into public.client_locations (client_id, label, address, approved) select id, 'Home', '1 Test St', true from public.car_clients where name = 'Cora';
select test.ok(exists (select 1 from public.client_schemes where key = 'chsp'), 'CHSP is a scheme');
select test.ok(exists (select 1 from public.client_programs where scheme = 'chsp' and active), 'with an active CHSP program');
select test.ok((select bool_or(g like '%My Aged Care ID%') from unnest(public.client_gaps((select id from public.car_clients where name = 'Cora'), (select id from public.client_programs where scheme = 'chsp' limit 1), null, false, null)) g), 'a CHSP service needs the My Aged Care ID');
insert into public.client_details (client_id, aged_care_id) select id, 'AC12345678' from public.car_clients where name = 'Cora';
select test.ok(not coalesce((select bool_or(g like '%My Aged Care ID%') from unnest(public.client_gaps((select id from public.car_clients where name = 'Cora'), (select id from public.client_programs where scheme = 'chsp' limit 1), null, false, null)) g), false), 'with the ID recorded, that gap goes');
\o
select 'All CHSP tests passed.';
