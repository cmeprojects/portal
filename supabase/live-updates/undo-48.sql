-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 48: two-factor login by role only again. Safe to run again.
begin;

create or replace function public.mfa_ok()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    not public.feature_enabled('two_factor')
    or coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
    or (
      public.my_role() is distinct from 'system_admin'
      and not coalesce(
        (select s.value ? public.my_role()::text
           from public.app_settings s
          where s.key = 'security.mfa_required_roles'),
        false
      )
    )
$$;

create or replace function public.my_access()
returns table (role public.app_role, active boolean, mfa_required boolean, mfa_ok boolean)
language sql
stable
security definer
set search_path = ''
as $$
  select
    p.role,
    p.active,
    public.feature_enabled('two_factor') and (
      p.role = 'system_admin' or coalesce(
        (select s.value ? p.role::text from public.app_settings s
          where s.key = 'security.mfa_required_roles'), false)
    ),
    public.mfa_ok()
  from public.profiles p
  where p.id = auth.uid()
$$;

drop function if exists public.set_mfa_exempt(uuid, boolean);
drop trigger if exists profiles_guard_mfa_exempt on public.profiles;
drop function if exists public.guard_mfa_exempt();
alter table public.profiles drop column if exists mfa_exempt;

commit;
