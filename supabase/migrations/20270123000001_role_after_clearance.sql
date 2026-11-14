-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects: a new starter can only be given another role once they're
-- cleared to work (Onboarding → Clear to work). Before that, including when
-- their account isn't set up or onboarding hasn't started, the only way is a
-- conditional role with a deadline. With the Onboarding feature switched off,
-- the earlier rule (onboarding items for the new role finished) still applies.
-- No new SECURITY DEFINER function.

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
