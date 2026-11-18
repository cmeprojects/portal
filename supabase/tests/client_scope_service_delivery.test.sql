-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 127, AUD-016 Stage 5): Service Delivery client scope.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.teams (name) values ('North'), ('South');
insert into public.invitations (email, full_name, role, job_title_id) values
  ('sw@example.com', 'Sam', 'support_worker', (select id from public.job_titles where name = 'Support Worker')),
  ('tl@example.com', 'Tia', 'team_leader', (select id from public.job_titles where name = 'Team Leader'));
insert into auth.users (email) values ('sw@example.com'), ('tl@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.cid(p_name text) returns uuid language sql security definer as $$ select id from public.car_clients where name = p_name $$;
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
insert into public.team_leaders (team_id, user_id) select id, test.pid('tl@example.com') from public.teams where name = 'North';
insert into public.car_clients (name) values ('Ann North'), ('Bob North'), ('Cat South');
insert into public.client_teams (client_id, team_id) select test.cid('Ann North'), id from public.teams where name = 'North';
insert into public.client_teams (client_id, team_id) select test.cid('Bob North'), id from public.teams where name = 'North';
insert into public.client_teams (client_id, team_id) select test.cid('Cat South'), id from public.teams where name = 'South';
insert into public.client_assignments (client_id, user_id, assigned_as) values (test.cid('Ann North'), test.pid('sw@example.com'), 'key_worker');
insert into public.client_details (client_id, date_of_birth) values (test.cid('Ann North'), '1950-01-01'), (test.cid('Bob North'), '1951-01-01');
select test.ok(test.n('sw@example.com', '(select count(*) from public.car_clients)') = 1, 'a support worker sees the clients they''re assigned to');
select test.ok(test.n('sw@example.com', '(select count(*) from public.client_details)') = 0, 'but not their details');
select test.ok(test.n('tl@example.com', '(select count(*) from public.car_clients)') = 2, 'a team leader sees their team''s clients');
select test.ok(test.n('tl@example.com', '(select count(*) from public.client_details)') = 0, 'but not their details');
update public.client_assignments set ended_at = now();
select test.ok(test.n('sw@example.com', '(select count(*) from public.car_clients)') = 0, 'an ended assignment ends it');
\o
select 'All Service Delivery client scope tests passed.';
