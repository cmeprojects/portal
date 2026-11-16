-- Staff Portal · © cmeproject. All rights reserved.
-- Update 91: odometer photo uploads follow the setting (Off = refused).
-- Safe to run again. Undo: undo-91.sql. Run update 90 first.
begin;
-- cmeprojects (QA-008 B, update 91; decisions D-009, D-042): drivers can upload
-- an odometer photo only while "Odometer photo when returning" isn't Off.
--   Off: refused by the database. Optional, Required: allowed (own folder).
-- Only the one storage policy changes. Reading existing photos and car
-- managers' uploads (cars/ folder) are unchanged. No files are touched.
do $storage$
begin
  if to_regclass('storage.objects') is null then
    return; -- databases without file storage (the test database)
  end if;
  drop policy if exists "drivers upload odometer photos" on storage.objects;
  create policy "drivers upload odometer photos" on storage.objects
    for insert to authenticated
    with check (bucket_id = 'car-files' and public.cars_on() and (storage.foldername(name))[1] = auth.uid()::text
                and public.car_setting('vehicles.odo_photo', 'optional') <> 'off');
end;
$storage$;
commit;
