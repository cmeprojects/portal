-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 114): reviews and re-assessments, kept apart by scheme
-- (Care block C5).

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin'),
  ('sam@example.com', 'Sam', 'support_worker'), ('cm@example.com', 'Casey', 'support_worker'), ('io@example.com', 'Ira', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('sam@example.com'), ('cm@example.com'), ('io@example.com');
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
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Case Manager') where email = 'cm@example.com';
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Intake & Assessment Officer') where email = 'io@example.com';
insert into public.teams (name) values ('North');
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'North';
insert into public.car_clients (name) values ('Zara North'), ('Alex South');
insert into public.client_teams (client_id, team_id) select test.cid('Zara North'), id from public.teams where name = 'North';

insert into public.client_locations (client_id, label, address) values (test.cid('Zara North'), 'Home', '1 Test St');
insert into public.client_services (client_id, program_id, label, start_date, location_id)
select test.cid('Zara North'), p.id, 'NDIS daily living', current_date, l.id from public.client_programs p, public.client_locations l where p.scheme = 'ndis' and l.label = 'Home' limit 1;
insert into public.client_services (client_id, program_id, label, start_date, location_id)
select test.cid('Zara North'), p.id, 'Home support', current_date, l.id from public.client_programs p, public.client_locations l where p.scheme = 'support_at_home' and l.label = 'Home' limit 1;
create function test.svc(p_label text) returns uuid language sql security definer as $$ select id from public.client_services where label = p_label $$;
grant execute on all functions in schema test to authenticated;
insert into public.client_assignments (client_id, user_id) values (test.cid('Zara North'), test.pid('cm@example.com'));

select test.ok((select sensitivity from public.app_modules where id = 'clients.reviews') = 'sensitive', 'Reviews is sensitive');

-- The case manager schedules an NDIS plan review and a Support at Home re-assessment.
select test.act_as('cm@example.com');
set role authenticated;
insert into public.client_reviews (client_id, scheme, service_id, due_on) values (test.cid('Zara North'), 'other', test.svc('NDIS daily living'), current_date + 45);
insert into public.client_reviews (client_id, scheme, service_id, due_on) values (test.cid('Zara North'), 'ndis', test.svc('Home support'), current_date + 20);
select test.refused($$insert into public.client_reviews (client_id, scheme, kind, due_on) values (test.cid('Zara North'), 'ndis', 'change_of_situation', current_date + 9)$$, 'a change of situation needs a reason');
select test.refused($$insert into public.client_reviews (client_id, scheme, due_on) values (test.cid('Alex South'), 'ndis', current_date)$$, 'not for an unassigned client');
reset role;
select test.ok((select scheme from public.client_reviews where service_id = test.svc('NDIS daily living')) = 'ndis', 'the scheme comes from the service''s program (NDIS)');
select test.ok((select scheme from public.client_reviews where service_id = test.svc('Home support')) = 'support_at_home', 'the scheme comes from the service''s program (Support at Home), whatever was sent');

-- Who sees them.
select test.ok(test.n('boss@example.com', '(select count(*) from public.client_reviews)') = 2, 'manager sees them');
select test.ok(test.n('office@example.com', '(select count(*) from public.client_reviews)') = 0, 'staff admin: none (D-052)');
select test.ok(test.n('io@example.com', '(select count(*) from public.client_reviews)') = 0, 'intake: none by default');
select test.ok(test.n('sam@example.com', '(select count(*) from public.client_reviews)') = 0, 'team staff: none');

-- Reminders: NDIS at 60 days before (passed), Support at Home at 30 (passed); once each.
select public.run_care_alerts();
select public.run_care_alerts();
select test.ok((select count(*) from public.notifications where user_id = test.pid('cm@example.com') and kind = 'client_review_due' and title like 'Plan review due%') = 1, 'one NDIS "Plan review" reminder');
select test.ok((select count(*) from public.notifications where user_id = test.pid('cm@example.com') and kind = 'client_review_due' and title like 'Re-assessment due%') = 1, 'one Support at Home "Re-assessment" reminder');
select test.ok((select count(*) from public.notifications where kind like 'client_review%' and (title like '%Plan review%' and body like '%Support at Home%' or title like '%Re-assessment%' and body like '%NDIS%')) = 0, 'NDIS and Support at Home wording never mix');
select test.ok((select count(*) from public.notifications where kind like 'client_review%' and user_id = test.pid('boss@example.com')) = 0, 'not to managers while someone is assigned');

-- Change of situation: due straight away, reminder straight away, no reason in it.
select test.act_as('cm@example.com');
set role authenticated;
insert into public.client_reviews (client_id, scheme, service_id, kind, due_on, reason) values (test.cid('Zara North'), 'ndis', test.svc('Home support'), 'change_of_situation', current_date + 99, 'Hospital stay, private detail');
reset role;
select public.run_care_alerts();
select test.ok((select due_on from public.client_reviews where kind = 'change_of_situation') = public.local_today(), 'a change of situation is due today');
select test.ok((select count(*) from public.notifications where kind = 'client_review_change' and title = 'Re-assessment (change of situation) raised') = 1, 'Support at Home change: "Re-assessment (change of situation)"');
select test.ok((select count(*) from public.notifications where body like '%Hospital%' or title like '%Hospital%') = 0, 'the reason is never in a reminder');

-- Completing and closing.
select test.act_as('cm@example.com');
set role authenticated;
select test.refused($$update public.client_reviews set status = 'completed' where kind = 'change_of_situation'$$, 'completing needs the outcome');
update public.client_reviews set status = 'completed', outcome = 'Supports adjusted' where kind = 'change_of_situation';
select test.refused($$update public.client_reviews set status = 'open' where kind = 'change_of_situation'$$, 'a closed review isn''t reopened');
select test.refused($$update public.client_reviews set scheme = 'private' where service_id = test.svc('NDIS daily living')$$, 'the scheme never changes');
select test.refused($$delete from public.client_reviews$$, 'reviews are never deleted');
reset role;
select test.ok((select closed_by = test.pid('cm@example.com') and completed_on = public.local_today() from public.client_reviews where kind = 'change_of_situation'), 'records who completed it and when');

-- Overdue: once.
update public.client_reviews set due_on = current_date - 1 where service_id = test.svc('NDIS daily living') and kind = 'scheduled';
select public.run_care_alerts();
select public.run_care_alerts();
select test.ok((select count(*) from public.notifications where kind = 'client_review_overdue' and title = 'Plan review is overdue') = 1, 'one overdue reminder');
set role authenticated;
select test.refused($$select public.run_care_alerts()$$, 'staff can''t run the reminders');
reset role;

\o
