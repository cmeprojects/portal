-- Staff Portal · © cmeproject. All rights reserved.
-- Update 57: "Complete your profile" is part of onboarding while Staff profiles
-- is on (contact phone and emergency contact). Safe to run again. Undo: undo-57.sql.
-- Run update 55 first.
begin;
create or replace function public.profile_complete(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select d.work_phone <> '' from public.staff_directory d where d.user_id = p_user), false)
     and coalesce((select pr.emergency_name <> '' and pr.emergency_phone <> '' from public.staff_private pr where pr.user_id = p_user), false)
$$;

create or replace function public.profile_required(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.feature_live('hr_profiles')
     and coalesce((select p.role::text not in ('system_admin', 'external') from public.profiles p where p.id = p_user), false)
     and not public.profile_complete(p_user)
$$;

create or replace function public.onboarding_missing(p_user uuid, p_role public.app_role default null, p_teams uuid[] default null)
returns text[]
language sql
stable
security definer
set search_path = ''
as $$
  select (case when public.profile_required(p_user) then array['Complete your profile'] else '{}'::text[] end)
      || coalesce((select array_agg(s.title order by array_position(array['read', 'training', 'upload'], s.kind), s.sort_order, s.title)
                     from public.compliance_status(p_user, p_role, p_teams) s
                    where s.state not in ('done', 'submitted', 'accepted', 'expiring')), '{}')
$$;

create or replace function public.profile_saved_check_onboarding()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.check_onboarding_complete(new.user_id);
  return new;
end;
$$;

drop trigger if exists profile_saved_check_onboarding on public.staff_directory;
create trigger profile_saved_check_onboarding after insert or update on public.staff_directory
  for each row execute function public.profile_saved_check_onboarding();
drop trigger if exists profile_saved_check_onboarding on public.staff_private;
create trigger profile_saved_check_onboarding after insert or update on public.staff_private
  for each row execute function public.profile_saved_check_onboarding();

revoke execute on function public.profile_complete(uuid), public.profile_required(uuid) from public, anon;
grant execute on function public.profile_complete(uuid), public.profile_required(uuid) to authenticated;
commit;
