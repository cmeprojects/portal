-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 101: staff management goes back to the built-in "managers, staff
-- admins and the system admin" rule. Copied defaults are kept (no effect).
-- Safe to run again.
begin;
update public.app_modules set grant_ready = false where id = 'people.staff' and grant_ready;
drop policy if exists "the person and people managers see private details" on public.staff_private;
create policy "the person and people managers see private details" on public.staff_private as PERMISSIVE for SELECT to authenticated using ((( SELECT feature_enabled('hr_profiles'::text) AS feature_enabled) AND ((user_id = ( SELECT auth.uid() AS uid)) OR ( SELECT can_manage_people() AS can_manage_people) OR ( SELECT is_system_admin() AS is_system_admin))));
drop policy if exists "managers and admins create invitations" on public.invitations;
create policy "managers and admins create invitations" on public.invitations as PERMISSIVE for INSERT to authenticated with check (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "managers and admins read invitations" on public.invitations;
create policy "managers and admins read invitations" on public.invitations as PERMISSIVE for SELECT to authenticated using (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "managers and admins remove pending invitations" on public.invitations;
create policy "managers and admins remove pending invitations" on public.invitations as PERMISSIVE for DELETE to authenticated using ((( SELECT can_manage_people() AS can_manage_people) AND (accepted_at IS NULL)));
drop policy if exists "managers and admins update invitations" on public.invitations;
create policy "managers and admins update invitations" on public.invitations as PERMISSIVE for UPDATE to authenticated using (( SELECT can_manage_people() AS can_manage_people)) with check (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "managers and admins see change requests" on public.people_change_requests;
create policy "managers and admins see change requests" on public.people_change_requests as PERMISSIVE for SELECT to authenticated using (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "managers and admins update people" on public.profiles;
create policy "managers and admins update people" on public.profiles as PERMISSIVE for UPDATE to authenticated using (( SELECT can_manage_people() AS can_manage_people)) with check (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "the person and people who manage staff see overrides" on public.work_overrides;
create policy "the person and people who manage staff see overrides" on public.work_overrides as PERMISSIVE for SELECT to authenticated using (((user_id = ( SELECT auth.uid() AS uid)) OR ( SELECT can_manage_compliance() AS can_manage_compliance) OR ( SELECT can_manage_people() AS can_manage_people) OR has_role(ARRAY['manager'::app_role]) OR leads_user(user_id)));

CREATE OR REPLACE FUNCTION public.log_admin_action(p_action text, p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.give_conditional_role(p_user_id uuid, p_role app_role, p_title_id uuid, p_teams uuid[], p_reason text, p_deadline date)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.guard_invitation()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if auth.uid() is not null and not public.can_invite() then
    raise exception 'You''re not set up to send invites. Ask a staff admin.';
  end if;
  -- People who can invite but don't manage staff send general invites only.
  if auth.uid() is not null and not public.can_manage_people() and (new.role <> 'new_starter' or new.team_id is not null) then
    raise exception 'Invite them as a new starter; a staff admin sets their role later';
  end if;
  if auth.uid() is not null and public.can_manage_people() and not public.can_manage_role(new.role) then
    raise exception 'Only a system admin can invite a system admin';
  end if;
  if auth.uid() is not null and public.rule_on('people.general_invites_only')
     and new.role <> 'new_starter' and public.my_role() <> 'system_admin' then
    raise exception 'Invites are general: they join as a new starter and you set their role afterwards';
  end if;
  if auth.uid() is not null and new.team_id is not null and public.my_role() = 'staff_admin'
     and public.rule_on('people.staff_admin_team_approval') then
    raise exception 'Add them to a team once they''ve joined; a manager approves team changes';
  end if;
  new.email := lower(trim(new.email));
  if tg_op = 'INSERT' then
    new.invited_by := coalesce(new.invited_by, auth.uid());
    perform public.write_audit('invited', 'invitation', new.email,
      jsonb_build_object('role', new.role));
  end if;
  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.remove_avatar(p_user uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if p_user is distinct from auth.uid() and not (public.can_manage_people() or public.is_system_admin()) then
    raise exception 'Only you, or people who manage staff, can remove this photo.';
  end if;
  perform set_config('portal.avatar_ok', 'on', true);
  update public.profiles set avatar_ref = null where id = p_user;
  perform public.write_audit('photo_removed', 'profile', p_user::text, '{}'::jsonb);
end;
$function$;

CREATE OR REPLACE FUNCTION public.guard_profile_update()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  actor uuid := auth.uid();
begin
  if new.id <> old.id or new.email <> old.email or new.org_id <> old.org_id then
    raise exception 'This field cannot be changed here';
  end if;

  -- Names (cmeprojects Phase 2): your own only while it's still blank (account
  -- set-up); someone else's with a Staff details grant covering them, or as the
  -- system admin. System jobs (no signed-in person) aren't affected.
  if actor is not null and new.full_name is distinct from old.full_name then
    if new.id = actor and coalesce(trim(old.full_name), '') <> '' and not public.is_system_admin() then
      raise exception 'Your name is set by the office. Ask your manager or the system admin to change it.';
    end if;
    if new.id <> actor and not public.has_access('staff_details', new.id) then
      raise exception 'You don''t have access to change this person''s name. The system admin can give you access.';
    end if;
    if new.id <> actor and old.role = 'system_admin' and not public.is_system_admin() then
      raise exception 'Only a system admin can rename a system admin';
    end if;
    perform public.write_audit('name_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.full_name, 'to', new.full_name));
  end if;

  if actor is not null then
    if new.role is distinct from old.role
       or new.team_id is distinct from old.team_id
       or new.active is distinct from old.active then

      if not public.can_manage_people() then
        raise exception 'Only managers and admins can change roles, teams or access';
      end if;

      if new.id = actor and (new.role is distinct from old.role or not new.active) then
        raise exception 'You cannot change your own role or deactivate yourself';
      end if;

      if new.id <> actor and (not public.can_manage_role(old.role) or not public.can_manage_role(new.role)) then
        raise exception 'Only a system admin can manage system admins';
      end if;

      -- cmeprojects (update 79): a new starter gets another role only once
      -- cleared to work (with onboarding on); otherwise a conditional role.
      if old.role = 'new_starter' and new.role <> 'new_starter'
         and coalesce(current_setting('app.conditional_role', true), '') <> 'on'
         and public.feature_enabled('compliance') and old.cleared_at is null then
        raise exception 'They aren''t cleared to work yet. Clear them to work first (Onboarding), or give a conditional role with a deadline.';
      end if;
      if old.role = 'new_starter' and new.role <> 'new_starter'
         and coalesce(current_setting('app.conditional_role', true), '') <> 'on'
         and cardinality(public.onboarding_missing(new.id, new.role, null)) > 0 then
        raise exception 'They haven''t finished onboarding yet. Give a conditional role with a deadline instead.';
      end if;

      if new.role is distinct from old.role and public.my_role() = 'staff_admin'
         and public.rule_on('people.staff_admin_role_approval')
         and (old.role <> 'new_starter' or public.rule_on('people.first_role_approval')) then
        raise exception 'Role changes by a staff admin need a manager''s approval. Send it as a request.';
      end if;
      if new.team_id is distinct from old.team_id and public.my_role() = 'staff_admin'
         and public.rule_on('people.staff_admin_team_approval') then
        raise exception 'Team changes by a staff admin need a manager''s approval. Send it as a request.';
      end if;
    end if;
  end if;

  if actor is not null and not public.is_system_admin()
     and old.role = 'manager' and old.active
     and (new.role <> 'manager' or not new.active)
     and not exists (select 1 from public.profiles where role = 'manager' and active and id <> old.id) then
    raise exception 'They''re the only manager left, so they can''t be deactivated or given another role. Add another manager first.';
  end if;

  if old.role = 'system_admin' and old.active
     and (new.role <> 'system_admin' or not new.active)
     and not exists (
       select 1 from public.profiles
        where role = 'system_admin' and active and id <> old.id
     ) then
    raise exception 'There must always be at least one active system admin';
  end if;

  if new.active and not old.active then
    new.deactivated_at := null;
  elsif not new.active and old.active then
    new.deactivated_at := now();
  end if;

  if new.role is distinct from old.role then
    perform public.write_audit('role_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.role, 'to', new.role));
  end if;
  if new.active is distinct from old.active then
    perform public.write_audit(
      case when new.active then 'reactivated' else 'deactivated' end,
      'profile', new.id::text, '{}'::jsonb);
  end if;
  if new.team_id is distinct from old.team_id then
    perform public.write_audit('team_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.team_id, 'to', new.team_id));
  end if;

  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.compliance_status(p_user uuid, p_role app_role DEFAULT NULL::app_role, p_teams uuid[] DEFAULT NULL::uuid[])
 RETURNS TABLE(item_id uuid, kind text, title text, state text, record_id bigint, expires_on date, note text, sort_order integer, before_work boolean, category text, needs_check boolean)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if not (p_user = auth.uid() or public.can_manage_compliance() or public.can_manage_people()
          or public.has_role(array['manager']::public.app_role[]) or public.leads_user(p_user)
          or auth.uid() is null) then
    return;
  end if;
  return query select * from public.compliance_status_all(p_user, p_role, p_teams);
end;
$function$;

CREATE OR REPLACE FUNCTION public.work_status(p_user uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  p public.profiles;
  o public.work_overrides;
begin
  if not (p_user = auth.uid() or public.can_manage_compliance() or public.can_manage_people()
          or public.has_role(array['manager']::public.app_role[]) or public.leads_user(p_user)) then
    return null;
  end if;
  select * into p from public.profiles where id = p_user;
  o := public.active_override(p_user);
  return jsonb_build_object(
    'onboarding_complete', p.onboarded_at is not null and cardinality(public.onboarding_missing(p_user)) = 0,
    'onboarded_at', p.onboarded_at,
    'compliance_verified', public.compliance_is_verified(p_user),
    'cleared', p.cleared_at is not null,
    'cleared_at', p.cleared_at,
    'cleared_by', (select coalesce(nullif(full_name, ''), email) from public.profiles where id = p.cleared_by),
    -- cmeprojects (update 81): minimum to work (before clearing, checked right
    -- to work too), what's still to finish, and the 7-day date for it.
    'before_work_missing', to_jsonb(case when p.cleared_at is null
                                         then public.before_work_missing(p_user) || public.right_to_work_missing(p_user)
                                         else public.before_work_missing(p_user) end),
    'still_to_finish', to_jsonb(public.onboarding_missing(p_user)),
    'finish_by', case when p.cleared_at is not null and cardinality(public.onboarding_missing(p_user)) > 0
                      then ((p.cleared_at at time zone 'Australia/Sydney')::date + 7) end,
    'cleared_note', (select a.details ->> 'note' from public.audit_log a
                      where a.action = 'cleared_to_work' and a.entity_id = p_user::text order by a.id desc limit 1),
    'can_work', public.can_work(p_user),
    'override', case when o.id is null then null else jsonb_build_object('id', o.id, 'reason', o.reason, 'until', o.until_date,
                  'by', (select coalesce(nullif(full_name, ''), email) from public.profiles where id = o.granted_by)) end);
end;
$function$;
commit;
