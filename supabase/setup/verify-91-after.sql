-- Staff Portal · © cmeproject. All rights reserved.
-- Update 91, check AFTER. Run on its own after update-91.sql. Nothing to edit.
-- It picks test accounts itself. Each test upload is undone straight away
-- inside the check (no file is kept, the setting isn't changed).
create or replace function pg_temp.try_upload(p_user uuid, p_folder text) returns text language plpgsql as $$
begin
  if p_user is null then return 'no suitable account'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub', p_user, 'role', 'authenticated', 'aal', 'aal2')::text, true);
  execute 'set role authenticated';
  begin
    insert into storage.objects (bucket_id, name) values ('car-files', p_folder || '/verify-' || gen_random_uuid() || '.jpg');
    raise exception using errcode = 'P0099', message = 'undo';
  exception
    when sqlstate 'P0099' then execute 'reset role'; return 'allowed';
    when insufficient_privilege or check_violation then execute 'reset role'; return 'refused';
  end;
end $$;

-- The "driver" is any active staff member who can use Cars (support worker first, otherwise any role but system admin or new starter).
with driver as (select id from public.profiles where active and role not in ('system_admin', 'new_starter', 'external') order by (role = 'support_worker') desc, created_at limit 1),
     other as (select id from public.profiles where active and role not in ('system_admin', 'new_starter') and id <> (select id from driver) order by created_at limit 1),
     admin as (select id from public.profiles where active and role = 'system_admin' order by created_at limit 1)
select 1 as n, 'Setting (expect off)' as check_name, (select value #>> '{}' from public.app_settings where key = 'vehicles.odo_photo') as result
union all select 2, 'Car files stored (expect same as before)', (select count(*)::text from storage.objects where bucket_id = 'car-files')
union all select 3, 'Other storage policies (expect same as before)', (select count(*) || ' / ' || md5(string_agg(policyname || '|' || cmd || '|' || coalesce(qual, '') || '|' || coalesce(with_check, ''), ';' order by policyname)) from pg_policies where schemaname = 'storage' and policyname <> 'drivers upload odometer photos')
union all select 4, 'Driver upload to own folder (expect refused)', pg_temp.try_upload((select id from driver), (select id::text from driver))
union all select 5, 'Driver upload to another person''s folder (expect refused)', pg_temp.try_upload((select id from driver), (select id::text from other))
union all select 6, 'System admin car photo to cars/ (expect allowed)', pg_temp.try_upload((select id from admin), 'cars')
union all select 7, 'New rule includes the setting (expect yes)', case when (select with_check from pg_policies where schemaname = 'storage' and policyname = 'drivers upload odometer photos') like '%car_setting%' then 'yes' else 'no' end
order by n;
