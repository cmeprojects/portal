-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (SEC-003): who-sees-what check for client, care and roster tables.
-- Read only: adds temporary people inside a transaction and rolls everything back.
-- Local or test copies only (it uses the test logins). Run with psql -f.
\set QUIET 1
\pset format unaligned
\pset fieldsep '|'
begin;
-- Temporary people for roles the test data doesn't have (rolled back at the end).
insert into public.invitations (email, full_name, role, job_title_id)
select x.e, x.n, x.r::public.app_role, (select id from public.job_titles where name = x.t)
  from (values ('tmp.sa@example.com','Tmp SA','staff_admin','Staff Administrator'),
               ('tmp.pay@example.com','Tmp Pay','support_worker','Payroll Officer'),
               ('tmp.csc@example.com','Tmp CSC','support_worker','Client Services Coordinator'),
               ('tmp.ext@example.com','Tmp Ext','external','Psychologist')) x(e,n,r,t);
insert into auth.users (id, email, aud, role) select gen_random_uuid(), e, 'authenticated', 'authenticated' from unnest(array['tmp.sa@example.com','tmp.pay@example.com','tmp.csc@example.com','tmp.ext@example.com']) e;
update public.profiles p set active = true, role = i.role, job_title_id = i.job_title_id from public.invitations i where i.email = p.email and p.email like 'tmp.%';
create temp table who (label text, email text);
insert into who values ('Manager','boss@example.com'),('Team Leader','test.zoe.campbell@example.com'),('Case Manager','test.grace.holloway@example.com'),
  ('Intake Officer','test.isla.fraser@example.com'),('Client Services Coord.','tmp.csc@example.com'),('Rostering Officer','test.lucas.moreau@example.com'),
  ('Payroll Officer','tmp.pay@example.com'),('Staff Administrator','tmp.sa@example.com'),('Support Worker','test.ava.thompson@example.com'),('Practitioner (external)','tmp.ext@example.com');
grant select on who to authenticated;
create temp table result (label text, tbl text, n bigint);
grant insert on result to authenticated;
do $$
declare w record; t text; n bigint;
  tbls text[] := array['car_clients','client_details','client_people','client_alerts','client_services','client_locations','client_comms','client_documents','client_care_plans','client_worker_instructions','client_funding','client_agreements','client_reviews','client_assignments','client_practitioner_notes','shifts','shift_service_records','shift_notes','shift_events'];
begin
  for w in select * from who loop
    perform set_config('request.jwt.claims', json_build_object('sub', (select id from public.profiles where email = w.email), 'role', 'authenticated', 'aal', 'aal2')::text, true);
    set local role authenticated;
    foreach t in array tbls loop
      begin execute format('select count(*) from public.%I', t) into n; exception when others then n := -1; end;
      insert into result values (w.label, t, n);
    end loop;
    reset role;
  end loop;
end $$;
select 'table|' || string_agg(label, '|' order by ord) from (select label, row_number() over () ord from who) w;
select r.tbl || '|' || string_agg(r.n::text, '|' order by w.ord)
  from result r join (select label, row_number() over () ord from who) w using (label)
 group by r.tbl order by min(array_position(array['car_clients','client_details','client_people','client_alerts','client_services','client_locations','client_comms','client_documents','client_care_plans','client_worker_instructions','client_funding','client_agreements','client_reviews','client_assignments','client_practitioner_notes','shifts','shift_service_records','shift_notes','shift_events'], r.tbl));
rollback;
