-- Staff Portal · © cmeproject. All rights reserved.
-- SUPERSEDED (16 Nov 2026) by verify-91-before.sql and verify-91-after.sql (simpler, no emails to edit). Kept for history.
-- cmeprojects: verify update 91 on Dev (QA-008 B). Run in the Supabase SQL
-- Editor, ONE STEP AT A TIME. Nothing here changes anything: steps 1 and 3 only
-- read; step 4 runs its upload tests inside a transaction that always ends in
-- ROLLBACK (no files are created and the setting isn't changed).

-- STEP 1: BEFORE running update-91.sql. Note the three values shown.
select
  (select value #>> '{}' from public.app_settings where key = 'vehicles.odo_photo') as odometer_setting,
  (select count(*) from storage.objects where bucket_id = 'car-files') as car_files_stored,
  (select count(*) || ' / ' || md5(string_agg(policyname || '|' || cmd || '|' || coalesce(qual, '') || '|' || coalesce(with_check, ''), ';' order by policyname))
     from pg_policies where schemaname = 'storage' and policyname <> 'drivers upload odometer photos') as other_storage_policies;

-- STEP 2: run supabase/live-updates/update-91.sql.

-- STEP 3: AFTER. The first three values must equal step 1 (setting 'off',
-- same file count, same other-policies fingerprint); the last column must end
-- with "<> 'off'::text))".
select
  (select value #>> '{}' from public.app_settings where key = 'vehicles.odo_photo') as odometer_setting,
  (select count(*) from storage.objects where bucket_id = 'car-files') as car_files_stored,
  (select count(*) || ' / ' || md5(string_agg(policyname || '|' || cmd || '|' || coalesce(qual, '') || '|' || coalesce(with_check, ''), ';' order by policyname))
     from pg_policies where schemaname = 'storage' and policyname <> 'drivers upload odometer photos') as other_storage_policies,
  (select with_check from pg_policies where schemaname = 'storage' and policyname = 'drivers upload odometer photos') as driver_upload_rule;

-- STEP 4: upload tests (rolled back). Change the three emails first: a test
-- driver, another test driver, and a test car manager (or system admin).
begin;
create temp table r (n serial, check_name text, ok boolean);
grant all on r to authenticated; grant usage on sequence r_n_seq to authenticated;
create function pg_temp.upload(p_email text, p_folder_email text) returns boolean language plpgsql as $$
declare v_id uuid := (select id from public.profiles where email = p_email);
        v_folder text := case when p_folder_email = 'cars' then 'cars' else (select id::text from public.profiles where email = p_folder_email) end;
        v_ok boolean;
begin
  if v_id is null or v_folder is null then raise exception 'Change the test emails in step 4 first'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub', v_id, 'role', 'authenticated', 'aal', 'aal2')::text, true);
  execute 'set local role authenticated';
  begin
    insert into storage.objects (bucket_id, name) values ('car-files', v_folder || '/verify-' || gen_random_uuid() || '.jpg');
    v_ok := true;
  exception when insufficient_privilege or check_violation then
    v_ok := false;
  end;
  execute 'reset role';
  return v_ok;
end $$;
insert into r (check_name, ok) values ('Off: driver upload to own folder refused', not pg_temp.upload('DRIVER@example.com', 'DRIVER@example.com'));
insert into r (check_name, ok) values ('Driver upload into another driver''s folder refused', not pg_temp.upload('DRIVER@example.com', 'OTHER-DRIVER@example.com'));
insert into r (check_name, ok) values ('Car manager car-photo upload (cars/) still allowed', pg_temp.upload('CAR-MANAGER@example.com', 'cars'));
select case when ok then 'PASS' else 'FAIL' end || '  ' || check_name as result from r order by n;
rollback;

-- Reading permissions: the policy "car files are seen by the driver and car
-- reports" isn't touched by update 91; step 3's fingerprint covers it.
-- ROLLBACK (if needed): run supabase/live-updates/undo-91.sql, then step 3
-- again: driver_upload_rule ends with "(auth.uid())::text))" (no setting check).
