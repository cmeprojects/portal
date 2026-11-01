-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 44: Reports is a standard feature again. Safe to run again.
begin;
update public.features set label = 'Reports', premium = false where key = 'reports';
commit;
