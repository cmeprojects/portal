-- Staff Portal · © cmeproject. All rights reserved.
--
-- Conditional roles (cmeprojects): when nothing is left to do for the chosen
-- role (the items still to do are for new starters or other roles only),
-- "Give conditional role" simply gives the role, with no onboarding task.
-- Managers always give it straight away; staff admins do too in that case,
-- unless the company's rule says a first role needs a manager's approval.

create or replace function public.apply_conditional_role(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.people_change_requests;
  v_team uuid;
  v_task uuid;
  v_missing text;
begin
  select * into r from public.people_change_requests where id = p_request_id;
  if (select role from public.profiles where id = r.user_id) <> 'new_starter' then
    raise exception 'They already have a role';
  end if;
  perform set_config('app.conditional_role', 'on', true);
  if r.to_value ->> 'title' is not null then
    update public.profiles set job_title_id = (r.to_value ->> 'title')::uuid where id = r.user_id;
  else
    update public.profiles set role = (r.to_value ->> 'role')::public.app_role where id = r.user_id;
  end if;
  perform set_config('app.conditional_role', 'off', true);

  if (r.to_value ->> 'role') in ('support_worker', 'team_leader') then
    for v_team in select x::uuid from jsonb_array_elements_text(coalesce(r.to_value -> 'teams', '[]')) x loop
      insert into public.team_members (team_id, user_id) values (v_team, r.user_id) on conflict do nothing;
    end loop;
  end if;

  -- Nothing left to do for this role: just the role, no task.
  if jsonb_array_length(coalesce(r.to_value -> 'missing', '[]')) = 0 then
    return;
  end if;
  select string_agg('• ' || x, E'\n') into v_missing from jsonb_array_elements_text(r.to_value -> 'missing') x;
  v_task := public.create_task(
    'Finish onboarding',
    (select id from public.registries where is_default and kind = 'tasks' and active order by sort_order limit 1),
    r.user_id,
    format(E'Your role was given on condition that you finish onboarding by %s.\n\nStill to do:\n%s\n\nReason: %s',
           to_char((r.to_value ->> 'deadline')::date, 'FMDD Mon YYYY'), coalesce(v_missing, ''), r.reason),
    'medium',
    (r.to_value ->> 'deadline')::date);
  update public.people_change_requests set task_id = v_task where id = r.id;
end;
$$;

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

  -- Managers give it straight away; so do staff admins when nothing is left
  -- for that role and a first role doesn't need approval.
  if me.role in ('manager', 'system_admin')
     or (cardinality(v_missing) = 0 and not public.rule_on('people.first_role_approval')) then
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
