-- Staff Portal · © cmeproject. All rights reserved.
-- Update 24: role changes by a staff admin always need a manager's approval
-- (conditional roles and a new starter's first role too). Safe to run again.
begin;
--
-- Role changes by a staff admin always need a manager's approval
-- (cmeprojects): conditional roles, and a new starter's first role too.

update public.app_settings set value = 'true'
 where key in ('people.staff_admin_role_approval', 'people.first_role_approval');

-- Managers give a conditional role straight away; staff admins ask a manager.
create or replace function public.give_conditional_role(
  p_user_id uuid, p_role public.app_role, p_title_id uuid, p_teams uuid[], p_reason text, p_deadline date
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  me public.profiles;
  v_role public.app_role := p_role;
  v_teams uuid[] := coalesce(p_teams, '{}');
  v_missing text[];
  v_id uuid;
  v_name text;
  v_manager uuid;
  v_to jsonb;
begin
  select * into me from public.profiles where id = auth.uid();
  if not public.can_manage_people() then
    raise exception 'Only managers and staff admins give roles';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'You cannot change your own role';
  end if;
  if (select role from public.profiles where id = p_user_id and active) is distinct from 'new_starter' then
    raise exception 'Conditional roles are for new starters';
  end if;
  if p_title_id is not null then
    select access_level into v_role from public.job_titles where id = p_title_id and active;
    if v_role is null then raise exception 'Choose a role that is in use'; end if;
  end if;
  if v_role in ('new_starter', 'system_admin') or not public.can_manage_role(v_role) then
    raise exception 'Choose a role you''re allowed to give';
  end if;
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'Give a reason for the conditional role';
  end if;
  if p_deadline is null or p_deadline < public.local_today() or p_deadline > public.local_today() + 180 then
    raise exception 'Choose a deadline in the next six months';
  end if;
  if v_role not in ('support_worker', 'team_leader') then
    v_teams := '{}';
  elsif v_role = 'team_leader' and cardinality(v_teams) > 1 then
    raise exception 'A team leader can be in one team only';
  end if;
  if exists (select 1 from unnest(v_teams) t where not exists (select 1 from public.teams where id = t and active and not is_core)) then
    raise exception 'Choose teams that are in use';
  end if;

  -- What's missing for the chosen role. Items only for new starters (or other
  -- roles) don't count, so this can be nothing even when the Staff page shows
  -- items still to do.
  v_missing := public.onboarding_missing(p_user_id, v_role, v_teams);

  v_to := jsonb_build_object('role', v_role, 'title', p_title_id, 'teams', to_jsonb(v_teams),
                             'deadline', p_deadline, 'missing', to_jsonb(v_missing));

  -- Managers give it straight away; a staff admin's always goes to a manager.
  if me.role in ('manager', 'system_admin') then
    insert into public.people_change_requests (kind, user_id, from_value, to_value, reason, requested_by,
                                               status, decided_by, decided_at, requester_seen_at)
    values ('conditional', p_user_id, jsonb_build_object('role', 'new_starter'), v_to, trim(p_reason), auth.uid(),
            'approved', auth.uid(), now(), now())
    returning id into v_id;
    perform public.apply_conditional_role(v_id);
    perform public.write_audit('conditional_role_given', 'profile', p_user_id::text, v_to);
    return v_id;
  end if;

  v_id := public.add_change_request('conditional', p_user_id, null, jsonb_build_object('role', 'new_starter'), v_to, p_reason);
  select coalesce(nullif(full_name, ''), email) into v_name from public.profiles where id = p_user_id;
  for v_manager in select id from public.profiles where active and role = 'manager' loop
    perform public.notify(v_manager, 'approval_needed',
      format('Conditional role for %s needs your approval', v_name),
      format('%s asks to give them a role before onboarding is finished (deadline %s).',
             coalesce(nullif(me.full_name, ''), me.email), to_char(p_deadline, 'FMDD Mon YYYY')),
      '/settings/staff', true);
  end loop;
  return v_id;
end;
$$;

commit;
