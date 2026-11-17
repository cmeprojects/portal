-- Staff Portal · © cmeproject. All rights reserved.
-- Update 109: staff admins no longer have default access to client records
-- (D-052). Safe to run again. Undo: undo-109.sql. Run update 108 first.
begin;
-- cmeprojects (update 109; owner decision D-052, 17 Nov 2026): staff admins
-- no longer have default access to client records.
--
--   * The staff admin access-level defaults for every part of Clients
--     (copied from the old rule in update 107) are revoked. Kept for history,
--     never deleted.
--   * A staff admin can still be given client access on the Access page (in
--     person, or through their role). Managers, the system admin, Case
--     Managers and Intake officers are unchanged.
--   * Revoked only if it's still the default copied at switch-over (a default
--     set later by the system admin is left alone).

update public.access_baselines
   set revoked_at = now()
 where access_level = 'staff_admin' and module_id like 'clients.%' and revoked_at is null
   and note = 'Set at switch-over: managers and staff admins managed clients';
commit;
