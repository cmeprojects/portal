-- Staff Portal · © cmeproject. All rights reserved.
-- Update 91, check BEFORE (read only). Run on its own and keep the result.
select
  (select value #>> '{}' from public.app_settings where key = 'vehicles.odo_photo') as odometer_setting,
  (select count(*) from storage.objects where bucket_id = 'car-files') as car_files_stored,
  (select count(*) || ' / ' || md5(string_agg(policyname || '|' || cmd || '|' || coalesce(qual, '') || '|' || coalesce(with_check, ''), ';' order by policyname))
     from pg_policies where schemaname = 'storage' and policyname <> 'drivers upload odometer photos') as other_storage_policies;
