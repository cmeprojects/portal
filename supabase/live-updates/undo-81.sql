-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 81. Safe to run again.
begin;
CREATE OR REPLACE FUNCTION public.onboarding_missing(p_user uuid, p_role app_role DEFAULT NULL::app_role, p_teams uuid[] DEFAULT NULL::uuid[])
 RETURNS text[]
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select (case when public.profile_required(p_user) then array['Complete your profile'] else '{}'::text[] end)
      || coalesce((select array_agg(s.title order by array_position(array['read', 'training', 'upload', 'agreement', 'form'], s.kind), s.sort_order, s.title)
                     from public.compliance_status(p_user, p_role, p_teams) s
                    where s.state not in ('done', 'submitted', 'accepted', 'expiring')), '{}')
$function$;

CREATE OR REPLACE FUNCTION public.grant_clearance(p_user uuid, p_note text DEFAULT ''::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  p public.profiles;
  v_missing text[];
  v_rest text[];
begin
  if not public.can_grant_clearance() then
    raise exception 'Only managers (or staff admins they''ve delegated to) can clear people to work';
  end if;
  select * into p from public.profiles where id = p_user;
  if p.id is null or not p.active then
    raise exception 'Person not found';
  end if;
  if p_user = auth.uid() then
    raise exception 'Someone else needs to clear you to work';
  end if;
  -- cmeprojects (update 80): clearing someone already cleared does nothing
  -- else (no second notice, and who cleared them and when stay as they were).
  if p.cleared_at is not null then
    raise exception 'They''re already cleared to work.';
  end if;
  v_missing := public.before_work_missing(p_user);
  if cardinality(v_missing) > 0 then
    raise exception 'Still needed before working: %. Finish and check these first, or give an override.', array_to_string(v_missing, ', ');
  end if;
  update public.profiles set cleared_at = now(), cleared_by = auth.uid() where id = p_user;
  v_rest := public.onboarding_missing(p_user);
  perform public.finish_onboarding_task(p_user);
  perform public.notify(p_user, 'cleared_to_work', 'You''re cleared to work',
    case when cardinality(v_rest) > 0 then 'Please finish the rest of your onboarding within a week.' else '' end, '/onboarding', true);
  perform public.write_audit('cleared_to_work', 'profile', p_user::text, jsonb_build_object('note', p_note, 'still_to_do', v_rest));
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
    'before_work_missing', to_jsonb(public.before_work_missing(p_user)),
    'can_work', public.can_work(p_user),
    'override', case when o.id is null then null else jsonb_build_object('id', o.id, 'reason', o.reason, 'until', o.until_date,
                  'by', (select coalesce(nullif(full_name, ''), email) from public.profiles where id = o.granted_by)) end);
end;
$function$;
drop function if exists public.pay_onboarding_missing(uuid, public.app_role);
drop function if exists public.right_to_work_missing(uuid, public.app_role);
commit;
