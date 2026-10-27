-- Staff Portal · © cmeproject. All rights reserved.
--
-- A main switch for two-factor login. When it is off nobody is asked for a
-- code, system admins included. Only a system admin can change it, and the
-- change is recorded in the change log like every other feature switch.

insert into public.features (key, label, description, enabled, sort_order) values
  ('two_factor', 'Two-factor login',
   'Ask for a code from an authenticator app when signing in. When off, nobody is asked, including system admins.',
   true, 5)
on conflict (key) do nothing;

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
