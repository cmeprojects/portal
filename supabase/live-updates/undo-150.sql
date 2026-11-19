-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 150. Safe to run again. Houses and their residents are removed; shifts lose their house.
begin;
drop trigger if exists guard_shift_house on public.shifts;
drop function if exists public.guard_shift_house();
drop table if exists public.sil_house_residents;
do $$ begin if to_regclass('public.sil_houses') is not null then drop policy if exists "read houses" on public.sil_houses; end if; end $$;
alter table public.shifts drop column if exists house_id;
drop table if exists public.sil_houses;
drop function if exists public.guard_sil_resident();
drop function if exists public.guard_sil_house();
update public.access_baselines set revoked_at = now() where module_id = 'clients.houses' and revoked_at is null;
update public.app_modules set status = 'retired' where id = 'clients.houses' and exists (select 1 from public.access_baselines where module_id = 'clients.houses');
delete from public.app_modules where id = 'clients.houses' and not exists (select 1 from public.access_baselines where module_id = 'clients.houses') and not exists (select 1 from public.access_grants where module_id = 'clients.houses');
delete from public.features where key = 'sil_houses';
commit;
