-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 109: gives staff admins back their default access to every part
-- of Clients (as copied in update 107). Safe to run again.
begin;
insert into public.access_baselines (access_level, module_id, actions, scope, note)
select 'staff_admin', m, '{}'::text[], 'all', 'Set at switch-over: managers and staff admins managed clients'
  from unnest(array['clients.list', 'clients.details', 'clients.people', 'clients.locations', 'clients.alerts', 'clients.notes', 'clients.services', 'clients.assign']) m
 where not exists (select 1 from public.access_baselines b
                    where b.access_level = 'staff_admin' and b.module_id = m and b.revoked_at is null);
commit;
