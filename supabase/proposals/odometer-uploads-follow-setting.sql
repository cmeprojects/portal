-- Staff Portal · © cmeproject. All rights reserved.
-- PROPOSAL (not applied; awaiting the owner, plan QA-008 action B).
-- Becomes the next numbered live update (with its migration and tests) if approved.
-- Drivers can upload an odometer photo only while "Odometer photo when
-- returning" isn't Off. With the setting Off (decision D-009) the database
-- refuses the upload. Existing files aren't touched; who can read them is
-- unchanged; car managers' car photos ("cars/" folder) are unchanged.
-- Only this one storage policy changes. Safe to run again.
-- Undo: odometer-uploads-follow-setting-undo.sql.
begin;
drop policy if exists "drivers upload odometer photos" on storage.objects;
create policy "drivers upload odometer photos" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'car-files' and public.cars_on() and (storage.foldername(name))[1] = auth.uid()::text
              and public.car_setting('vehicles.odo_photo', 'optional') <> 'off');
commit;
