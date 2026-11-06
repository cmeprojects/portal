-- Staff Portal · © cmeproject. All rights reserved.
--
-- Two-factor login per person (cmeprojects): besides choosing which roles need
-- it, the system admin can let one person off (for example someone without a
-- smartphone). System admins always need it.

alter table public.profiles add column if not exists mfa_exempt boolean not null default false;

-- Only the system admin changes it, and never for a system admin.
create or replace function public.guard_mfa_exempt()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.mfa_exempt is distinct from old.mfa_exempt then
    if auth.uid() is not null and not public.is_system_admin() then
      raise exception 'Only the system admin can change two-factor login for a person.';
    end if;
  end if;
  if new.mfa_exempt and new.role = 'system_admin' then
    new.mfa_exempt := false;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_guard_mfa_exempt on public.profiles;
create trigger profiles_guard_mfa_exempt
  before update on public.profiles
  for each row execute function public.guard_mfa_exempt();

-- Signed in well enough? Two-factor is needed by system admins, and by the
-- chosen roles unless the system admin let this person off.
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
      and (
        coalesce((select p.mfa_exempt from public.profiles p where p.id = auth.uid()), false)
        or not coalesce(
          (select s.value ? public.my_role()::text
             from public.app_settings s
            where s.key = 'security.mfa_required_roles'),
          false
        )
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
      p.role = 'system_admin' or (not p.mfa_exempt and coalesce(
        (select s.value ? p.role::text from public.app_settings s
          where s.key = 'security.mfa_required_roles'), false))
    ),
    public.mfa_ok()
  from public.profiles p
  where p.id = auth.uid()
$$;

-- The system admin lets a person off two-factor login, or asks for it again.
create or replace function public.set_mfa_exempt(p_user_id uuid, p_exempt boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_system_admin() or not public.mfa_ok() then
    raise exception 'Only the system admin can change two-factor login for a person.';
  end if;
  if exists (select 1 from public.profiles where id = p_user_id and role = 'system_admin') then
    raise exception 'System admins always need two-factor login.';
  end if;
  update public.profiles set mfa_exempt = p_exempt where id = p_user_id;
  perform public.write_audit(case when p_exempt then 'mfa_exempted' else 'mfa_required_again' end, 'profile', p_user_id::text, '{}'::jsonb);
end;
$$;

revoke execute on function public.set_mfa_exempt(uuid, boolean) from public, anon;
grant execute on function public.set_mfa_exempt(uuid, boolean) to authenticated;
revoke execute on function public.guard_mfa_exempt() from public, anon, authenticated;
