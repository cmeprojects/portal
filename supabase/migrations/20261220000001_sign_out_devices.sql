-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects: signing out other devices.
--   * Anyone: sign out their own other devices (phones, other computers).
--   * The system admin: sign a person out everywhere, or everyone except themselves.
-- Removing a sign-in session also removes its refresh tokens, and the portal
-- checks its session still exists, so a signed-out device stops within a minute.

-- Is the session this request came from still there?
create or replace function public.my_session_active()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when coalesce(auth.jwt() ->> 'session_id', '') = '' then true
    else exists (
      select 1 from auth.sessions s
       where s.id = (auth.jwt() ->> 'session_id')::uuid and s.user_id = auth.uid()
    )
  end
$$;

-- Sign out my other devices; this one stays signed in.
create or replace function public.sign_out_my_other_devices()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer;
begin
  if auth.uid() is null then
    raise exception 'Please sign in first.';
  end if;
  delete from auth.sessions
   where user_id = auth.uid()
     and id is distinct from nullif(auth.jwt() ->> 'session_id', '')::uuid;
  get diagnostics v_count = row_count;
  perform public.write_audit('signed_out_other_devices', 'profile', auth.uid()::text, jsonb_build_object('devices', v_count));
  return v_count;
end;
$$;

-- System admin: sign one person out of every device.
create or replace function public.sign_out_everywhere(p_user_id uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
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
$$;

-- System admin: sign everyone out (for example after a lost phone or a
-- security worry). The admin's own current device stays signed in.
create or replace function public.sign_out_everyone()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
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
$$;

revoke execute on function public.my_session_active() from public, anon;
revoke execute on function public.sign_out_my_other_devices() from public, anon;
revoke execute on function public.sign_out_everywhere(uuid) from public, anon;
revoke execute on function public.sign_out_everyone() from public, anon;
grant execute on function public.my_session_active() to authenticated;
grant execute on function public.sign_out_my_other_devices() to authenticated;
grant execute on function public.sign_out_everywhere(uuid) to authenticated;
grant execute on function public.sign_out_everyone() to authenticated;
