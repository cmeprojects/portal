-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 150): SIL houses.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com'), ('kim@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.cid(p_name text) returns uuid language sql security definer as $$ select id from public.car_clients where name = p_name $$;
create function test.hid() returns uuid language sql security definer as $$ select id from public.sil_houses order by created_at limit 1 $$;
grant execute on all functions in schema test to authenticated;
insert into public.car_clients (name, status) values ('Ava', 'active'), ('Ben', 'active'), ('Cy', 'active');

-- Off by default: nothing shows, nothing can be added.
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.sil_houses (name) values ('Oak St')$$, 'off: houses can''t be added');
reset role;
update public.features set enabled = true where key = 'sil_houses';

select test.act_as('boss@example.com');
set role authenticated;
insert into public.sil_houses (name, address, beds) values ('Oak St', '4 Oak St, Penrith NSW 2750', 2);
select test.refused($$insert into public.sil_houses (name) values ('oak st')$$, 'house names are unique');
insert into public.sil_house_residents (house_id, client_id, room, moved_in) values (test.hid(), test.cid('Ava'), 'Room 1', current_date - 30), (test.hid(), test.cid('Ben'), 'Room 2', current_date);
select test.refused($$insert into public.sil_house_residents (house_id, client_id, moved_in) values (test.hid(), test.cid('Cy'), current_date)$$, 'a full house takes no one else');
select test.refused($$update public.sil_houses set beds = 1$$, 'beds can''t go below the residents');
insert into public.sil_houses (name, beds) values ('Elm Rd', 3);
select test.refused($$insert into public.sil_house_residents (house_id, client_id, moved_in) select id, test.cid('Ava'), current_date from public.sil_houses where name = 'Elm Rd'$$, 'one current house per client');
update public.sil_house_residents set moved_out = current_date, move_reason = 'Moving to Elm Rd' where client_id = test.cid('Ava');
insert into public.sil_house_residents (house_id, client_id, moved_in) select id, test.cid('Ava'), current_date from public.sil_houses where name = 'Elm Rd';
select test.refused($$update public.sil_house_residents set moved_out = null where moved_out is not null$$, 'a move-out stays');
select test.refused($$delete from public.sil_house_residents$$, 'the history is never deleted');
select test.refused($$update public.sil_houses set active = false where name = 'Oak St'$$, 'a house with residents can''t close');
reset role;
select test.ok((select count(*) from public.sil_house_residents where client_id = test.cid('Ava')) = 2, 'Ava''s move is kept as history');

-- Workers: only the house of their own published shift.
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.sil_houses) = 0, 'a worker doesn''t see houses');
select test.refused($$insert into public.sil_houses (name) values ('Mine')$$, 'a worker can''t add houses');
reset role;
insert into public.shifts (worker_id, starts_at, ends_at, status, house_id) values (test.pid('sam@example.com'), now() + interval '1 day', now() + interval '1 day 4 hours', 'published', test.hid());
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.sil_houses) = 1, 'a worker sees the house of their shift');
reset role;
select test.act_as('kim@example.com');
set role authenticated;
select test.ok((select count(*) from public.sil_houses) = 0, 'other workers don''t');
reset role;

-- Off again: hidden, kept.
update public.features set enabled = false where key = 'sil_houses';
select test.act_as('boss@example.com');
set role authenticated;
select test.ok((select count(*) from public.sil_houses) = 0, 'off: houses are hidden');
reset role;
select test.ok((select count(*) from public.sil_houses) = 2, 'off: nothing is deleted');
\o
select 'All SIL house tests passed.';
