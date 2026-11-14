-- Staff Portal · © cmeproject. All rights reserved.
-- Update 81: onboarding and clearance (all seven requirements; checked right
-- to work before clearing; 7 days for the rest; nobody's clearance removed).
-- Safe to run again. Undo: undo-81.sql. Run update 80 first.
begin;
-- cmeprojects audit Stage B: onboarding and clearance (owner's decisions,
-- 15 Nov 2026).
--   * "Onboarding complete" includes bank details, super, right to work and
--     the TFN declaration (with the onboarding checklist).
--   * Checked right to work is needed before someone can be cleared to work.
--     People already cleared stay cleared: nothing is removed automatically.
--   * Bank, super and TFN can be finished after clearance, within 7 days.
--   * work_status shows the three parts: minimum to work, still to finish, and
--     the finish-by date (and the note from the clearance).
-- Two new helper functions (SECURITY INVOKER, read-only). No tables, policies
-- or permissions change. No new SECURITY DEFINER function.

-- Right to work in Australia, checked by someone with access (needed before
-- clearing). Not for system admins or external accounts.
create or replace function public.right_to_work_missing(p_user uuid, p_role public.app_role default null)
returns text[]
language sql
stable
security invoker
set search_path = ''
as $$
  select case
    when not public.feature_enabled('compliance') then '{}'::text[]
    when coalesce(p_role, (select role from public.profiles where id = p_user)) in ('system_admin', 'external') then '{}'::text[]
    when exists (select 1 from public.staff_work_rights w where w.user_id = p_user and w.verified_at is not null) then '{}'::text[]
    else array['Right to work in Australia (checked)']
  end
$$;
revoke execute on function public.right_to_work_missing(uuid, public.app_role) from public, anon;

-- Bank, super, right to work and TFN: part of "onboarding complete".
create or replace function public.pay_onboarding_missing(p_user uuid, p_role public.app_role default null)
returns text[]
language sql
stable
security invoker
set search_path = ''
as $$
  select case
    when not public.feature_enabled('compliance') then '{}'::text[]
    when coalesce(p_role, (select role from public.profiles where id = p_user)) in ('system_admin', 'external') then '{}'::text[]
    else array_remove(array[
      case when not exists (select 1 from public.staff_bank b where b.user_id = p_user and coalesce(b.account_number, '') <> '') then 'Bank account for your pay' end,
      case when not exists (select 1 from public.staff_super s where s.user_id = p_user and coalesce(s.fund_name, '') <> '') then 'Superannuation' end,
      case when not exists (select 1 from public.staff_tax t where t.user_id = p_user and coalesce(t.form_path, '') <> '') then 'Tax file number declaration' end
    ], null) || public.right_to_work_missing(p_user, p_role)
  end
$$;
revoke execute on function public.pay_onboarding_missing(uuid, public.app_role) from public, anon;

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
      -- cmeprojects (update 81): bank, super, right to work and TFN count too.
      || public.pay_onboarding_missing(p_user, p_role)
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
  -- cmeprojects (update 81): checked right to work is needed before clearing.
  v_missing := public.before_work_missing(p_user) || public.right_to_work_missing(p_user);
  if cardinality(v_missing) > 0 then
    raise exception 'Still needed before working: %. Finish and check these first, or give an override.', array_to_string(v_missing, ', ');
  end if;
  update public.profiles set cleared_at = now(), cleared_by = auth.uid() where id = p_user;
  v_rest := public.onboarding_missing(p_user);
  perform public.finish_onboarding_task(p_user);
  perform public.notify(p_user, 'cleared_to_work', 'You''re cleared to work',
    case when cardinality(v_rest) > 0
         then format('Please finish the rest of your onboarding by %s (7 days).', to_char(public.local_today() + 7, 'FMDD Mon YYYY'))
         else '' end, '/onboarding', true);
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
