-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 57: the profile is no longer part of onboarding. Safe to run again.
begin;
drop trigger if exists profile_saved_check_onboarding on public.staff_directory;
drop trigger if exists profile_saved_check_onboarding on public.staff_private;
drop function if exists public.profile_saved_check_onboarding();
create or replace function public.onboarding_missing(p_user uuid, p_role public.app_role default null, p_teams uuid[] default null)
returns text[]
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(array_agg(s.title order by array_position(array['read', 'training', 'upload'], s.kind), s.sort_order, s.title), '{}')
    from public.compliance_status(p_user, p_role, p_teams) s
   where s.state not in ('done', 'submitted', 'accepted', 'expiring')
$$;
drop function if exists public.profile_required(uuid);
drop function if exists public.profile_complete(uuid);
commit;
