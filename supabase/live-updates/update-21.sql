-- Staff Portal · © cmeproject. All rights reserved.
-- Update 21: helping staff sign in (password reset link, two-factor reset,
-- Cars app PIN) for the system admin and the roles they choose. Safe to run again.
begin;
--
-- Helping someone sign in (cmeprojects): on Staff & roles, the system admin
-- (and the roles they choose) can email a person a password reset link,
-- reset their two-factor login, and clear their Cars app PIN. No one can do
-- this for themselves here, and only the system admin can do it for a
-- system admin. Password reset emails are limited to one every 2 minutes per
-- address.

insert into public.app_settings (key, value, label, description, is_public) values
  ('people.access_reset_roles', '[]', 'Who can help staff sign in',
   'Besides the system admin: send a password reset link, reset two-factor login and clear the Cars app PIN (on Staff & roles).', false)
on conflict (key) do nothing;

create or replace function public.can_help_sign_in(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.mfa_ok()
     and p_user is distinct from auth.uid()
     and exists (select 1 from public.profiles where id = p_user)
     and (public.my_role() = 'system_admin'
          or (public.my_role() = any (public.setting_roles('people.access_reset_roles'))
              and (select role from public.profiles where id = p_user) <> 'system_admin'))
$$;
revoke execute on function public.can_help_sign_in(uuid) from public, anon;
grant execute on function public.can_help_sign_in(uuid) to authenticated;

create or replace function public.log_admin_action(p_action text, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_action in ('mfa_reset', 'password_reset_sent', 'pin_cleared') then
    if not public.can_help_sign_in(p_user_id) then
      raise exception 'You can''t do this for them. Ask the system admin.';
    end if;
  elsif p_action <> 'invite_resent' or not public.can_manage_people() then
    raise exception 'Not allowed';
  end if;
  perform public.write_audit(p_action, 'profile', p_user_id::text, '{}'::jsonb);
end;
$$;

-- When password reset emails were last sent (by the website, with the service key).
create table if not exists public.email_throttle (
  key     text primary key,
  sent_at timestamptz not null default now()
);
alter table public.email_throttle enable row level security;
revoke all on public.email_throttle from anon, authenticated;
commit;
