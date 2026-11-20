-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 157 (the page's own once-an-hour check stays). Safe to run again.
begin;
drop trigger if exists client_view_once on public.client_staff_views;
drop function if exists public.client_view_once();
commit;
