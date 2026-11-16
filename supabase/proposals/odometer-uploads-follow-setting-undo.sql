-- Staff Portal · © cmeproject. All rights reserved.
-- Undo the odometer upload proposal: puts the policy back exactly as it was
-- (migration 20261121000001_cars.sql, live update 18). Safe to run again.
begin;
drop policy if exists "drivers upload odometer photos" on storage.objects;
create policy "drivers upload odometer photos" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'car-files' and public.cars_on() and (storage.foldername(name))[1] = auth.uid()::text);
commit;
