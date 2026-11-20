-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 154. Safe to run again. The download trail is removed.
begin;
drop table if exists public.download_log;
drop function if exists public.guard_download_log();
update public.app_modules set status = 'retired' where id = 'system.downloads' and (exists (select 1 from public.access_grants where module_id = 'system.downloads') or exists (select 1 from public.access_baselines where module_id = 'system.downloads'));
delete from public.app_modules where id = 'system.downloads' and not exists (select 1 from public.access_grants where module_id = 'system.downloads') and not exists (select 1 from public.access_baselines where module_id = 'system.downloads');
commit;
