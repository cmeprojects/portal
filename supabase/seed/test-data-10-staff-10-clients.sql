-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects: TEST DATA ONLY — 10 approved staff and 10 clients for the Dev copy.
--
--   * DEV / LOCAL ONLY. Never run on Demo, production or a customer's copy.
--   * Every person and client is fictional. Emails use example.com (never
--     delivered); phone numbers are from the 0491 570 xxx range set aside for
--     fiction; NDIS numbers start 999 (real ones don't); My Aged Care IDs start
--     TEST-. No TFNs, bank details, licence numbers or real documents.
--   * Marked as test data: staff employee IDs and client references start TEST-.
--   * Safe to run again: staff are matched by email, clients by their TEST-
--     reference; nothing is duplicated.
--   * The 10 staff are cleared to work by this script (a recorded test action,
--     audit note "Test data seed"), not through the onboarding workflow. No
--     onboarding or clearance rule is changed for real staff.
--   * No shifts, timesheets or roster. Notices this script would create are
--     removed before it finishes, so nobody is emailed or notified.
--   * The accounts get a random password: to sign in as one, set a password
--     for it in Supabase (Authentication → Users), or use "Forgot password"
--     on a copy whose email goes to a test inbox.
begin;

do $seed$
declare
  v_actor uuid := coalesce(
    (select id from public.profiles where role = 'system_admin' and active order by created_at limit 1),
    (select id from public.profiles where role = 'manager' and active order by created_at limit 1));
  v_north uuid;
  v_south uuid;
  s record;
  c record;
  v_uid uuid;
  v_title uuid;
  v_cid uuid;
  v_loc uuid;
  v_svc uuid;
  v_plan uuid;
  v_prog uuid;
  i record;
begin
  -- Teams.
  select id into v_north from public.teams where name = 'Test Team North';
  if v_north is null then insert into public.teams (name) values ('Test Team North') returning id into v_north; end if;
  select id into v_south from public.teams where name = 'Test Team South';
  if v_south is null then insert into public.teams (name) values ('Test Team South') returning id into v_south; end if;

  -- ===== Staff =====
  for s in
    select * from (values
      ('S01', 'Ava',    'Thompson', 'test.ava.thompson@example.com',   '0491 570 110', 'Support Worker',              'support_worker', 'north', 'part_time', '{"mon":["am","pm"],"tue":["am","pm"],"wed":["am","pm"],"thu":["am","pm"],"fri":["am","pm"],"sat":[],"sun":[]}',              'Certificate III Individual Support; manual handling; NDIS and Support at Home'),
      ('S02', 'Noah',   'Patel',    'test.noah.patel@example.com',     '0491 570 111', 'Support Worker',              'support_worker', 'north', 'casual',    '{"mon":["am","pm"],"tue":["am","pm"],"wed":["am","pm"],"thu":["am","pm"],"fri":["am","pm"],"sat":["am","pm"],"sun":[]}',               'Certificate IV Disability; community access; NDIS'),
      ('S03', 'Mia',    'Robertson','test.mia.robertson@example.com',  '0491 570 112', 'Support Worker',              'support_worker', 'north', 'full_time', '{"mon":["am"],"tue":["am"],"wed":["am"],"thu":["am"],"fri":["am"],"sat":[],"sun":[]}',                      'Certificate III Individual Support; personal care; Support at Home'),
      ('S04', 'Ethan',  'Kowalski', 'test.ethan.kowalski@example.com', '0491 570 113', 'Support Worker',              'support_worker', 'south', 'part_time', '{"mon":[],"tue":["am","pm"],"wed":["am","pm"],"thu":["am","pm"],"fri":["am","pm"],"sat":["am","pm"],"sun":[]}',               'Certificate III Individual Support; domestic assistance; NDIS and Private'),
      ('S05', 'Chloe',  'Martin',   'test.chloe.martin@example.com',   '0491 570 114', 'Support Worker',              'support_worker', 'south', 'casual',    '{"mon":[],"tue":[],"wed":[],"thu":[],"fri":[],"sat":["am","pm"],"sun":["am","pm"]}',         'Certificate III Individual Support; Auslan (basic); NDIS'),
      ('S06', 'Grace',  'Holloway', 'test.grace.holloway@example.com', '0491 570 115', 'Case Manager',                'support_worker', 'north', 'full_time', '{"mon":["am","pm"],"tue":["am","pm"],"wed":["am","pm"],"thu":["am","pm"],"fri":["am","pm"],"sat":[],"sun":[]}',                 'Diploma Community Services; NDIS and Support at Home case management'),
      ('S07', 'Samuel', 'Achebe',   'test.samuel.achebe@example.com',  '0491 570 116', 'Case Manager',                'support_worker', 'south', 'full_time', '{"mon":["am","pm"],"tue":["am","pm"],"wed":["am","pm"],"thu":["am","pm"],"fri":["am","pm"],"sat":[],"sun":[]}',                 'Bachelor Social Work; NDIS and Private case management'),
      ('S08', 'Isla',   'Fraser',   'test.isla.fraser@example.com',    '0491 570 117', 'Intake & Assessment Officer', 'support_worker', null,    'part_time', '{"mon":["am","pm"],"tue":[],"wed":["am","pm"],"thu":["am","pm"],"fri":[],"sat":[],"sun":[]}',                        'Intake and referral; initial assessments'),
      ('S09', 'Lucas',  'Moreau',   'test.lucas.moreau@example.com',   '0491 570 118', 'Rostering Officer',           'support_worker', null,    'full_time', '{"mon":["am","pm"],"tue":["am","pm"],"wed":["am","pm"],"thu":["am","pm"],"fri":["am","pm"],"sat":[],"sun":[]}',                 'Rostering and timesheets'),
      ('S10', 'Zoe',    'Campbell', 'test.zoe.campbell@example.com',   '0491 570 119', 'Team Leader',                 'team_leader',    'both',  'full_time', '{"mon":["am","pm"],"tue":["am","pm"],"wed":["am","pm"],"thu":["am","pm"],"fri":["am","pm"],"sat":[],"sun":[]}',  'Certificate IV Disability; team leadership; NDIS and Support at Home')
    ) as t(code, given, family, email, phone, title, level, team, emp, avail, skills)
  loop
    select id into v_title from public.job_titles where name = s.title and access_level = s.level::public.app_role and active;
    if v_title is null then
      raise exception 'Job title % is missing. Run live updates 125 and 126 first.', s.title;
    end if;
    select id into v_uid from public.profiles where lower(email) = s.email;
    if v_uid is null then
      if not exists (select 1 from public.invitations where lower(email) = s.email) then
        insert into public.invitations (email, full_name, role, job_title_id) values (s.email, s.given || ' ' || s.family, s.level::public.app_role, v_title);
      end if;
      v_uid := gen_random_uuid();
      insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
                              created_at, updated_at, confirmation_token, recovery_token, email_change_token_new, email_change)
      values ('00000000-0000-0000-0000-000000000000', v_uid, 'authenticated', 'authenticated', s.email,
              extensions.crypt(gen_random_uuid()::text, extensions.gen_salt('bf')), now(),
              '{"provider":"email","providers":["email"]}', jsonb_build_object('full_name', s.given || ' ' || s.family),
              now(), now(), '', '', '', '');
      insert into auth.identities (id, user_id, provider_id, provider, identity_data, created_at, updated_at, last_sign_in_at)
      values (gen_random_uuid(), v_uid, v_uid::text, 'email', jsonb_build_object('sub', v_uid::text, 'email', s.email, 'email_verified', true), now(), now(), null);
    end if;
    -- Role, team and start date.
    update public.profiles set full_name = s.given || ' ' || s.family, role = s.level::public.app_role, job_title_id = v_title, active = true,
           joined_at = coalesce(joined_at, now() - interval '60 days'),
           team_id = case s.team when 'north' then v_north when 'south' then v_south when 'both' then v_north else null end
     where id = v_uid;
    insert into public.staff_private (user_id, address, emergency_name, emergency_phone, start_date, employment_type, employee_id, availability)
    values (v_uid, (10 + right(s.code, 2)::int) || ' Example Street, Marrickville NSW 2204', 'Test Contact ' || s.family, '0491 570 1' || (20 + right(s.code, 2)::int),
            current_date - 60, s.emp, 'TEST-' || s.code, s.avail::jsonb)
    on conflict (user_id) do update set emergency_name = excluded.emergency_name, emergency_phone = excluded.emergency_phone,
           start_date = coalesce(public.staff_private.start_date, excluded.start_date), employment_type = excluded.employment_type,
           employee_id = excluded.employee_id, availability = excluded.availability, address = excluded.address;
    insert into public.staff_directory (user_id, department, work_phone, skills)
    values (v_uid, coalesce(nullif(s.team, ''), 'office'), s.phone, string_to_array(s.skills, '; '))
    on conflict (user_id) do update set department = excluded.department, work_phone = excluded.work_phone, skills = excluded.skills;
    insert into public.staff_work_rights (user_id, status, verified_at, verified_by)
    values (v_uid, 'citizen', now(), v_actor)
    on conflict (user_id) do update set status = 'citizen', verified_at = coalesce(public.staff_work_rights.verified_at, now()), verified_by = coalesce(public.staff_work_rights.verified_by, v_actor);
    -- Teams.
    if s.level = 'team_leader' then
      insert into public.team_leaders (team_id, user_id) values (v_north, v_uid) on conflict do nothing; -- a team leader leads one team (existing rule)
    elsif s.team in ('north', 'south') then
      insert into public.team_members (team_id, user_id) values (case s.team when 'north' then v_north else v_south end, v_uid) on conflict do nothing;
    end if;
    -- Every active onboarding item: an accepted test record (placeholders only).
    for i in select * from public.compliance_items where active and not coalesce(sets_photo, false) loop
      if not exists (select 1 from public.compliance_records r where r.item_id = i.id and r.user_id = v_uid and r.status = 'accepted') then
        insert into public.compliance_records (item_id, user_id, version, status, file_name, expires_on, issued_on, doc_number, completed_on, provider, signed_name, reviewed_by, reviewed_at, review_note)
        values (i.id, v_uid, coalesce(i.version, 1), 'accepted',
                case when i.kind = 'upload' then 'TEST placeholder (no file).pdf' end,
                case when i.needs_expiry then current_date + 400 end,
                case when coalesce(i.needs_issue_date, false) then current_date - 365 end,
                case when coalesce(i.needs_number, false) then 'TEST-' || s.code else '' end,
                current_date - 50, case when i.kind = 'training' then 'Test training provider' else '' end,
                case when i.kind = 'agreement' then s.given || ' ' || s.family else '' end,
                v_actor, now(), 'Test data seed');
      end if;
    end loop;
    -- Approved and cleared for testing (recorded; not the real clearance workflow).
    update public.profiles
       set onboarded_at = coalesce(onboarded_at, now()), compliance_verified_at = coalesce(compliance_verified_at, now()),
           cleared_at = coalesce(cleared_at, now()), cleared_by = coalesce(cleared_by, v_actor)
     where id = v_uid;
    perform public.write_audit('cleared_to_work', 'profile', v_uid::text, jsonb_build_object('note', 'Test data seed', 'test_data', true));
  end loop;

  -- ===== Clients =====
  for c in
    select * from (values
      ('TEST-C01', 'Margaret', 'Ellison',  'Peggy', 'mrs', 'female', '1946-03-12', 'Support at Home', 'active',  'Domestic assistance',            'Weekly, Tuesday mornings (2 h)',                '14 Wattle Lane',     'Marrickville', '2204', 'Key in lockbox; code with case manager.', 'own_home',  'phone',  'Hard of hearing: speak clearly, face her.',     'S06', 'S01,',      'north', 'falls',    'Walks with a frame; keep walkways clear.'),
      ('TEST-C02', 'Daniel',   'Okafor',   '',      'mr',  'male',   '1988-07-04', 'NDIS',            'active',  'Personal care',                  'Daily, 7–9am',                                 '3/22 Banksia Road',  'Dulwich Hill', '2203', 'Ground floor unit; ramp at the side.',     'own_home',  'sms',    'Prefers text messages.',                         'S06', 'S01,S02',   'north', 'mobility', 'Uses a power wheelchair; hoist transfers need two workers (trained).'),
      ('TEST-C03', 'Priya',    'Raman',    '',      'ms',  'female', '1995-11-20', 'NDIS',            'active',  'Community access',               'Twice weekly (Mon and Thu, 4 h)',               '8 Grevillea Street', 'Petersham',    '2049', 'Meet at the front gate.',                  'with_family','through_representative', 'Uses an AAC device; allow time to respond.', 'S06', 'S02,',      'north', 'comms',    'Give choices with the device; don''t speak for her.'),
      ('TEST-C04', 'Harold',   'Finch',    'Harry', 'mr',  'male',   '1939-01-30', 'Support at Home', 'active',  'Personal care',                  'Three times weekly (Mon, Wed, Fri mornings)',   '61 Jacaranda Avenue','Stanmore',     '2048', 'Ring the bell twice; he may be slow to answer.', 'own_home', 'phone', 'Prefers a call before visits.',             'S06', 'S03,S01',   'north', 'falls',    'High falls risk: shower chair and rails; never leave him standing alone.'),
      ('TEST-C05', 'Sienna',   'Walsh',    '',      'ms',  'female', '2001-05-09', 'NDIS',            'active',  'Community access and skills',    'Weekly, Saturday (5 h)',                        '17 Waratah Parade',  'Lewisham',     '2049', '',                                         'with_family','email',  'Deaf: Auslan interpreter for planning meetings; text on shifts.', 'S06', 'S03,', 'north', 'none', 'Write things down or text; she lip-reads some English.'),
      ('TEST-C06', 'Thomas',   'Nguyen',   'Tom',   'mr',  'male',   '1972-09-15', 'NDIS',            'active',  'Domestic assistance',            'Fortnightly, Wednesday (3 h)',                  '5 Melaleuca Close',  'Ashfield',     '2131', 'Friendly dog in the yard; ask Tom to put him inside.', 'own_home', 'phone', '',                                       'S07', 'S04,',      'south', 'env',      'Dog on site; Tom prefers products he supplies.'),
      ('TEST-C07', 'Beatrice', 'Cole',     'Bea',   'mrs', 'female', '1950-02-27', 'Private',         'active',  'Domestic assistance and shopping','Weekly, Friday (3 h)',                         '29 Bottlebrush Way', 'Summer Hill',  '2130', 'Parking at the back.',                     'own_home',  'phone',  '',                                               'S07', 'S05,',      'south', 'diet',     'Diabetic diet: shopping list from Bea; no sugary drinks.'),
      ('TEST-C08', 'Liam',     'O''Connor','',      'mr',  'male',   '1999-12-03', 'NDIS',            'pending', 'Community access',               'To be agreed after assessment',                 '12 Acacia Street',   'Croydon',      '2132', '',                                         'with_family','sms',    '',                                               'S07', 'S04,',      'south', 'unknown',  ''),
      ('TEST-C09', 'Rosa',     'Martinez', '',      'mrs', 'female', '1944-06-18', 'Support at Home', 'pending', '',                               '',                                              '40 Kurrajong Road',  'Haberfield',   '2045', '',                                         'own_home',  'phone',  'Spanish first language; interpreter may be needed.', 'S07', 'S05,', 'south', 'unknown', ''),
      ('TEST-C10', 'Jacob',    'Lee',      'Jake',  'mr',  'male',   '1983-08-22', 'Private',         'pending', 'Personal care',                  'Three times weekly (to confirm)',               '7/90 Paperbark Drive','Five Dock',   '2046', 'Building intercom 7.',                     'supported_accommodation','phone', '',                                     'S07', 'S04,S05',   'south', 'unknown',  '')
    ) as t(ref, given, family, pref, title, gender, dob, program, status, service, freq, street, suburb, postcode, access, living, contact, comms, cm, sws, team, alert, instr)
  loop
    select id into v_cid from public.car_clients where reference = c.ref;
    if v_cid is not null then
      continue; -- already seeded
    end if;
    select id into v_prog from public.client_programs where name = c.program and active limit 1;
    insert into public.car_clients (name, reference, client_ref, title, given_name, family_name, preferred_name, status, created_by)
    values (c.given || ' ' || c.family, c.ref, public.next_client_ref(), c.title, c.given, c.family, c.pref, 'pending', v_actor)
    returning id into v_cid;
    insert into public.client_details (client_id, date_of_birth, phone, email, home_address, preferred_contact, communication_needs, ndis_number, aged_care_id, gender, state, time_zone, living_situation, about, tags)
    values (v_cid, c.dob::date, '0491 570 ' || (130 + right(c.ref, 2)::int), case when c.contact = 'email' then 'test.' || lower(c.given) || '@example.com' else '' end,
            c.street || ', ' || c.suburb || ' NSW ' || c.postcode, c.contact, c.comms,
            case when c.program = 'NDIS' and c.status = 'active' then '999' || lpad(right(c.ref, 2), 6, '0') else '' end,
            case when c.program = 'Support at Home' and c.status = 'active' then 'TEST-MAC-' || right(c.ref, 2) else '' end,
            c.gender, 'NSW', 'Australia/Sydney', c.living, 'TEST DATA. Fictional client for portal testing.', '{test}')
    on conflict (client_id) do nothing;
    insert into public.client_people (client_id, kind, name, relationship, phone, primary_contact)
    values (v_cid, 'emergency', 'Test Emergency ' || c.family, case when c.living = 'with_family' then 'Parent' else 'Daughter' end, '0491 570 ' || (140 + right(c.ref, 2)::int), true);
    if c.ref in ('TEST-C03', 'TEST-C05') then
      insert into public.client_people (client_id, kind, name, relationship, phone, authority)
      values (v_cid, 'nominee', 'Test Nominee ' || c.family, 'Parent', '0491 570 15' || right(c.ref, 1), 'NDIS plan nominee (test). Consent for sharing information recorded.');
    elsif c.ref = 'TEST-C04' then
      insert into public.client_people (client_id, kind, name, relationship, phone, authority)
      values (v_cid, 'representative', 'Test Representative Finch', 'Son', '0491 570 155', 'Enduring power of attorney (test placeholder; no document).');
    end if;
    insert into public.client_comms (client_id, preferred_contact, language, interpreter_needed, accessibility_needs, notes)
    values (v_cid, case when c.contact = 'post' then '' else c.contact end, case when c.ref = 'TEST-C09' then 'Spanish' when c.ref = 'TEST-C05' then 'Auslan' else 'English' end,
            c.ref in ('TEST-C05', 'TEST-C09'), c.comms, 'TEST DATA')
    on conflict (client_id) do nothing;
    insert into public.client_locations (client_id, label, address, suburb, state, postcode, access_notes, from_date, approved, approved_at, approved_by)
    values (v_cid, 'Home', c.street, c.suburb, 'NSW', c.postcode, c.access, current_date - 30, c.status = 'active',
            case when c.status = 'active' then now() end, case when c.status = 'active' then v_actor end)
    returning id into v_loc;
    insert into public.client_teams (client_id, team_id) values (v_cid, case c.team when 'north' then v_north else v_south end) on conflict do nothing;
    -- Safety.
    if c.alert = 'none' then
      insert into public.client_alerts (client_id, kind, title, active) values (v_cid, 'no_known_alerts', 'No known safety alerts', true);
    elsif c.alert <> 'unknown' then
      insert into public.client_alerts (client_id, kind, severity, title, worker_instructions, active, review_date)
      values (v_cid, case c.alert when 'falls' then 'mobility' when 'mobility' then 'mobility' when 'comms' then 'other' when 'env' then 'environment' when 'diet' then 'medical' else 'other' end,
              case when c.alert in ('falls', 'mobility') then 'high' else 'medium' end,
              case c.alert when 'falls' then 'Falls risk' when 'mobility' then 'Wheelchair and hoist transfers' when 'comms' then 'Communication: AAC device' when 'env' then 'Dog on property' when 'diet' then 'Diabetic diet' else 'Note' end,
              c.instr, true, current_date + 90);
    end if;
    if c.instr <> '' then
      insert into public.client_worker_instructions (client_id, title, instructions, active, sort_order) values (v_cid, 'Each visit', c.instr, true, 1);
    end if;
    -- Clients with complete records become active (pending ones stay pending).
    if c.status = 'active' then
      update public.car_clients set status = 'active' where id = v_cid;
    end if;
    -- Service, agreement, funding, care plan and review (where intake has got that far).
    if c.service <> '' and v_prog is not null then
      insert into public.client_services (client_id, program_id, label, status, start_date, location_id, scheduling_notes)
      values (v_cid, v_prog, c.service, case when c.status = 'active' then 'active' else 'planned' end, current_date - case when c.status = 'active' then 21 else -14 end, v_loc, c.freq)
      returning id into v_svc;
      if c.status = 'active' then
        insert into public.client_agreements (client_id, service_id, scheme, status, starts_on, ends_on, signed_on, signed_by_name, notes)
        values (v_cid, v_svc, (select scheme from public.client_programs where id = v_prog), 'signed', current_date - 21, current_date + 344, current_date - 25,
                coalesce(nullif(c.pref, ''), c.given) || ' ' || c.family, 'TEST DATA');
        insert into public.client_funding (client_id, service_id, scheme, period_start, period_end, total_amount, used_amount, used_as_of, plan_management, classification, status, notes)
        values (v_cid, v_svc, (select scheme from public.client_programs where id = v_prog), current_date - 21, current_date + 344,
                case c.program when 'NDIS' then 24000 when 'Support at Home' then 18500 else 6000 end, 0, current_date,
                case when c.program = 'NDIS' then 'plan' end, case when c.program = 'Support at Home' then 4 end, 'active', 'TEST DATA');
        insert into public.client_care_plans (client_id, title, status, assessed_on, starts_on, review_by, summary)
        values (v_cid, c.service || ' plan', 'draft', current_date - 28, current_date - 21, current_date + 160, 'TEST DATA. ' || c.service || ', ' || lower(c.freq) || '.')
        returning id into v_plan;
        insert into public.client_care_goals (plan_id, client_id, goal, measure, sort_order)
        values (v_plan, v_cid, 'Stay safe and independent at home', 'No unplanned changes to support', 1),
               (v_plan, v_cid, 'Take part in chosen activities', 'Reviewed at each plan review', 2);
        update public.client_care_plans set status = 'current' where id = v_plan;
        insert into public.client_reviews (client_id, scheme, service_id, kind, due_on, reason, status)
        values (v_cid, (select scheme from public.client_programs where id = v_prog), v_svc, 'scheduled', current_date + 160, 'Six-monthly review (test)', 'open');
      end if;
    end if;
    -- People working with this client.
    insert into public.client_assignments (client_id, user_id, assigned_as, starts_on, note, assigned_by)
    select v_cid, p.id, 'case_manager', current_date - 30, 'TEST DATA', v_actor from public.profiles p where p.email = (select e from (values
      ('S06', 'test.grace.holloway@example.com'), ('S07', 'test.samuel.achebe@example.com')) x(k, e) where k = c.cm);
    insert into public.client_assignments (client_id, user_id, assigned_as, starts_on, note, assigned_by)
    select v_cid, p.id, 'key_worker', current_date - 30, 'TEST DATA', v_actor
      from public.profiles p join public.staff_private sp on sp.user_id = p.id
     where sp.employee_id = any (select 'TEST-' || x from unnest(string_to_array(trim(both ',' from c.sws), ',')) x);
    if c.status = 'pending' then
      insert into public.client_assignments (client_id, user_id, assigned_as, starts_on, note, assigned_by)
      select v_cid, p.id, 'intake', current_date - 7, 'TEST DATA: intake and initial assessment', v_actor from public.profiles p where p.email = 'test.isla.fraser@example.com';
    end if;
    -- Active clients must pass every readiness check, or the seed stops.
    if c.status = 'active' and not coalesce((public.client_readiness(v_cid) ->> 'ready')::boolean, false) then
      raise exception 'Test client % isn''t service-ready: %', c.ref, public.client_readiness(v_cid);
    end if;
  end loop;

  -- Nobody is notified or emailed about test data (this transaction's notices only).
  delete from public.email_outbox where created_at = now();
  delete from public.notifications where created_at = now();
end
$seed$;

commit;

-- Check (read only): staff and clients made by this script.
select 'staff' as what, j.name as job_title, count(*) from public.profiles p join public.job_titles j on j.id = p.job_title_id
  join public.staff_private sp on sp.user_id = p.id where sp.employee_id like 'TEST-S%' group by j.name
union all
select 'clients', c.status, count(*) from public.car_clients c where c.reference like 'TEST-C%' group by c.status
order by 1, 2;
