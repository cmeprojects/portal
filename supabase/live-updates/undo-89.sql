-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 89: removes safety alerts and their notes (with everything
-- entered). Run undo-90 first if it was run. Safe to run again.
begin;
drop table if exists public.client_alert_notes;
drop table if exists public.client_alerts;
drop function if exists public.fill_alert_note_client();
commit;
