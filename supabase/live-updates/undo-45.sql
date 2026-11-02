-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 45: removes the sign-out-other-devices functions. Safe to run again.
begin;
drop function if exists public.sign_out_everyone();
drop function if exists public.sign_out_everywhere(uuid);
drop function if exists public.sign_out_my_other_devices();
drop function if exists public.my_session_active();
commit;
