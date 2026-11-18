-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 127: takes back the two client-list defaults (kept on record as
-- revoked). Safe to run again.
begin;
update public.access_baselines set revoked_at = now()
 where revoked_at is null and module_id = 'clients.list'
   and note in ('AUD-016 Stage 5: support workers, their assigned clients (list entry only)', 'AUD-016 Stage 5: team leaders, their team''s clients (list entry only)');
commit;
