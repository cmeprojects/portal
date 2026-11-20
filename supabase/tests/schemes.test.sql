-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 110): programs and schemes (Care block C0).

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('boss2@example.com', 'Max', 'manager'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('boss2@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;

select test.ok((select string_agg(key, ',' order by sort_order) from public.client_schemes) = 'ndis,support_at_home,chsp,private,other', 'five fixed schemes (CHSP from update 151)');
select test.ok((select string_agg(name || '=' || scheme, ',' order by name) from public.client_programs) = 'CHSP=chsp,NDIS=ndis,Other=other,Private=private,Support at Home=support_at_home', 'existing programs matched to their scheme');
select test.ok((select review_label from public.client_schemes where key = 'ndis') = 'Plan review' and (select review_label from public.client_schemes where key = 'support_at_home') = 'Re-assessment', 'each scheme has its own review wording');

-- Who changes them: Care settings.
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.client_programs (name, scheme) values ('NDIS SIL', 'ndis')$$, 'a manager without Care settings can''t add programs');
select test.refused($$update public.client_schemes set review_label = 'X' where key = 'ndis'$$, 'or change scheme wording');
reset role;
select set_config('request.jwt.claims', '', false);
insert into public.delegation_rules (area, mode, people) values ('care', 'selected', array[test.pid('boss@example.com')]) on conflict (area) do update set mode = 'selected', people = array[test.pid('boss@example.com')];
select test.act_as('boss@example.com');
set role authenticated;
insert into public.client_programs (name, scheme) values ('NDIS SIL', 'ndis');
update public.client_schemes set person_word = 'Participant', review_lead_days = '{60,30}' where key = 'ndis';
select test.refused($$update public.client_schemes set key = 'aged' where key = 'other'$$, 'the scheme list is fixed');
reset role;
select test.ok((select scheme from public.client_programs where name = 'NDIS SIL') = 'ndis', 'given Care settings: adds a program under its scheme');
select test.ok((select review_lead_days from public.client_schemes where key = 'ndis') = '{60,30}', 'and changes the scheme''s reminder days');
select test.act_as('boss2@example.com');
set role authenticated;
select test.refused($$insert into public.client_programs (name, scheme) values ('X', 'other')$$, 'another manager still can''t');
reset role;
select test.refused($$insert into public.client_programs (name, scheme) values ('Aged care', 'aged')$$, 'a program must use one of the schemes');

-- A program's scheme is fixed once a service uses it.
insert into public.car_clients (name) values ('Zara North');
set session_replication_role = replica;
insert into public.client_locations (client_id, address) values ((select id from public.car_clients where name = 'Zara North'), '1 Test St');
insert into public.client_services (client_id, program_id, label, start_date, location_id) values ((select id from public.car_clients where name = 'Zara North'), (select id from public.client_programs where name = 'NDIS SIL'), 'SIL', current_date, (select id from public.client_locations limit 1));
set session_replication_role = origin;
select test.refused($$update public.client_programs set scheme = 'support_at_home' where name = 'NDIS SIL'$$, 'a program in use can''t move to another scheme');
update public.client_programs set scheme = 'private' where name = 'Private';
select test.ok((select scheme from public.client_programs where name = 'Private') = 'private', 'an unused program can be corrected');

-- Staff read schemes and programs (labels only).
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.client_schemes) = 5, 'members read the schemes');
reset role;

\o
