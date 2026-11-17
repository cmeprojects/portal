-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 116: removes funding and budgets (and everything recorded in
-- them). Safe to run again.
begin;
drop table if exists public.client_funding;
drop function if exists public.guard_client_funding();
update public.access_baselines set revoked_at = now() where module_id = 'clients.funding' and revoked_at is null;
update public.app_modules set grant_ready = false where id = 'clients.funding';
commit;
