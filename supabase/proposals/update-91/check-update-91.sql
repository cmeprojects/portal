-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects: checks for update 91 on a local Supabase copy (with storage).
-- Everything runs in ONE transaction that always ends in ROLLBACK, and this
-- file has no commit of its own, so nothing is left changed.
-- Run: psql <local db> -v ON_ERROR_STOP=1 -f check-update-91.sql
begin;
create temp table r (n serial, check_name text, ok boolean);
create temp table orig as select policyname, qual, with_check from pg_policies where schemaname = 'storage' and policyname in ('drivers upload odometer photos', 'car managers upload car photos', 'car files are seen by the driver and car reports');
grant all on r, orig to authenticated; grant usage on sequence r_n_seq to authenticated;

-- the change (same statements as update-91.sql, without its begin/commit)
drop policy if exists "drivers upload odometer photos" on storage.objects;
create policy "drivers upload odometer photos" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'car-files' and public.cars_on() and (storage.foldername(name))[1] = auth.uid()::text
              and public.car_setting('vehicles.odo_photo', 'optional') <> 'off');

update public.features set enabled = true where key = 'vehicles';

create function pg_temp.upload(p_email text, p_folder text, p_setting text) returns boolean language plpgsql as $$
declare v_id uuid := (select id from public.profiles where email = p_email); v_ok boolean;
begin
  update public.app_settings set value = to_jsonb(p_setting) where key = 'vehicles.odo_photo';
  perform set_config('request.jwt.claims', json_build_object('sub', v_id, 'role', 'authenticated', 'aal', 'aal2')::text, true);
  execute 'set local role authenticated';
  begin
    insert into storage.objects (bucket_id, name) values ('car-files', coalesce(p_folder, v_id::text) || '/check-' || gen_random_uuid() || '.jpg');
    v_ok := true;
  exception when insufficient_privilege or check_violation then
    v_ok := false;
  end;
  execute 'reset role';
  return v_ok;
end $$;

insert into r (check_name, ok) values ('Optional: driver uploads to own folder', pg_temp.upload('sam@example.com', null, 'optional'));
insert into r (check_name, ok) values ('Required: driver uploads to own folder', pg_temp.upload('sam@example.com', null, 'required'));
insert into r (check_name, ok) values ('Off: driver upload refused', not pg_temp.upload('sam@example.com', null, 'off'));
insert into r (check_name, ok) values ('Off: still refused in someone else''s folder', not pg_temp.upload('sam@example.com', (select id::text from public.profiles where email = 'boss@example.com'), 'off'));
insert into r (check_name, ok) values ('Off: car manager still uploads car photos (cars/)', pg_temp.upload('boss@example.com', 'cars', 'off'));
insert into r (check_name, ok) values ('Reading policy unchanged',
  (select qual from pg_policies where schemaname = 'storage' and policyname = 'car files are seen by the driver and car reports') = (select qual from orig where policyname = 'car files are seen by the driver and car reports'));
insert into r (check_name, ok) values ('Car manager upload policy unchanged',
  (select with_check from pg_policies where schemaname = 'storage' and policyname = 'car managers upload car photos') = (select with_check from orig where policyname = 'car managers upload car photos'));

-- the undo (same statements as undo-91.sql, without its begin/commit)
drop policy if exists "drivers upload odometer photos" on storage.objects;
create policy "drivers upload odometer photos" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'car-files' and public.cars_on() and (storage.foldername(name))[1] = auth.uid()::text);
insert into r (check_name, ok) values ('Undo restores the original policy exactly',
  (select with_check from pg_policies where schemaname = 'storage' and policyname = 'drivers upload odometer photos') = (select with_check from orig where policyname = 'drivers upload odometer photos'));
insert into r (check_name, ok) values ('After undo, Off no longer blocks (original behaviour)', pg_temp.upload('sam@example.com', null, 'off'));

select case when ok then 'PASS' else 'FAIL' end || '  ' || check_name from r order by n;
rollback;
