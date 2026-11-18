-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 136: removes only the defaults it added (kept in history as revoked). Safe to run again.
begin;
update public.access_baselines set revoked_at = now()
 where note = 'Stage 5 default: Client Services Coordinator' and revoked_at is null;
commit;
