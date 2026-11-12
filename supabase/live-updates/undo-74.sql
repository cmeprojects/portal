-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 74: removes the owner protection. Safe to run again.
begin;
drop trigger if exists profiles_guard_owner on public.profiles;
drop function if exists public.guard_owner();
CREATE OR REPLACE FUNCTION public.can_help_sign_in(p_user uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.mfa_ok()
     and p_user is distinct from auth.uid()
     and exists (select 1 from public.profiles where id = p_user)
     and (public.my_role() = 'system_admin'
          or (public.my_role() = any (public.setting_roles('people.access_reset_roles'))
              and (select role from public.profiles where id = p_user) <> 'system_admin'))
$function$;

CREATE OR REPLACE FUNCTION public.sign_out_everywhere(p_user_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_count integer;
begin
  if not public.is_system_admin() then
    raise exception 'Only the system admin can do this.';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'To sign yourself out of other devices, use My account.';
  end if;
  delete from auth.sessions where user_id = p_user_id;
  get diagnostics v_count = row_count;
  perform public.write_audit('signed_out_everywhere', 'profile', p_user_id::text, jsonb_build_object('devices', v_count));
  return v_count;
end;
$function$;

CREATE OR REPLACE FUNCTION public.sign_out_everyone()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_count integer;
begin
  if not public.is_system_admin() then
    raise exception 'Only the system admin can do this.';
  end if;
  delete from auth.sessions
   where id is distinct from nullif(auth.jwt() ->> 'session_id', '')::uuid;
  get diagnostics v_count = row_count;
  perform public.write_audit('signed_out_everyone', 'system', 'everyone', jsonb_build_object('devices', v_count));
  return v_count;
end;
$function$;

drop index if exists public.profiles_one_owner;
alter table public.profiles drop column if exists is_owner;
commit;
