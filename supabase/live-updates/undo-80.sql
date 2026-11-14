-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 80. Safe to run again.
begin;
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

update public.app_settings set description = 'They don''t see the other registers in New task. They follow what they raised in My tasks → My requests and questions.'
 where key = 'tasks.limited_roles' and description = 'They don''t see the other registers in New task. They follow what they raised in My tasks → Raised by me.';
commit;
