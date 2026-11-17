-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 100; function-based access, Stage 3b; D-047, D-049):
-- Teams switched over to the one permission check `can()`.
--
--   * Who adds, renames and closes teams, and changes who's in them, now
--     comes from `can('people.teams', 'edit')` instead of the built-in roles.
--   * Defaults reproduce today's rule: managers and staff admins manage
--     teams. Nobody's access changes.
--   * Unchanged: staff admins send changes to who's in a team to a manager for
--     approval while "Staff admins' team changes need approval" is on (a
--     workflow rule in People rules), and staff admins don't write team
--     members directly; everyone reads teams; the core team is automatic.

update public.app_modules set grant_ready = true where id = 'people.teams' and not grant_ready;

do $$
begin
  if exists (select 1 from public.access_baselines
              where module_id = 'people.teams' and access_level is not null and revoked_at is null) then
    return;
  end if;
  insert into public.access_baselines (access_level, module_id, actions, scope, note) values
    ('manager', 'people.teams', '{}', 'all', 'Set at switch-over: managers managed teams'),
    ('staff_admin', 'people.teams', '{}', 'all', 'Set at switch-over: staff admins managed teams');
end $$;

drop policy if exists "managers and admins manage teams" on public.teams;
create policy "managers and admins manage teams" on public.teams for ALL to authenticated using (( SELECT public.can('people.teams'::text, 'edit'::text) AS can)) with check (( SELECT public.can('people.teams'::text, 'edit'::text) AS can));
drop policy if exists "managers set team leaders" on public.team_leaders;
create policy "managers set team leaders" on public.team_leaders for ALL to authenticated using ((( SELECT public.can('people.teams'::text, 'edit'::text) AS can) AND NOT ( SELECT public.has_role(ARRAY['staff_admin'::public.app_role]) AS has_role))) with check ((( SELECT public.can('people.teams'::text, 'edit'::text) AS can) AND NOT ( SELECT public.has_role(ARRAY['staff_admin'::public.app_role]) AS has_role)));
drop policy if exists "managers change team members" on public.team_members;
create policy "managers change team members" on public.team_members for ALL to authenticated using ((( SELECT public.can('people.teams'::text, 'edit'::text) AS can) AND NOT ( SELECT public.has_role(ARRAY['staff_admin'::public.app_role]) AS has_role))) with check ((( SELECT public.can('people.teams'::text, 'edit'::text) AS can) AND NOT ( SELECT public.has_role(ARRAY['staff_admin'::public.app_role]) AS has_role)));

CREATE OR REPLACE FUNCTION public.set_team(p_team_id uuid, p_members uuid[], p_leader uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_members uuid[] := coalesce(p_members, '{}');
  v_old jsonb;
begin
  -- cmeprojects (update 100): who may change teams is the Access page (Teams,
  -- edit); staff admins still send it for approval while that rule is on.
  if not (public.can('people.teams', 'edit')
          and not (public.has_role(array['staff_admin']::public.app_role[])
                   and public.rule_on('people.staff_admin_team_approval'))) then
    raise exception 'Only managers change who is in a team. Send it as a request.';
  end if;
  if (select is_core from public.teams where id = p_team_id) then
    raise exception 'The core team is managers and staff admins, automatically';
  end if;
  if p_leader is not null and not (p_leader = any (v_members)) then
    v_members := v_members || p_leader;
  end if;
  select jsonb_build_object(
           'members', coalesce((select jsonb_agg(user_id order by user_id) from public.team_members where team_id = p_team_id), '[]'),
           'leader', (select to_jsonb(user_id) from public.team_leaders where team_id = p_team_id limit 1))
    into v_old;

  delete from public.team_leaders where team_id = p_team_id and user_id is distinct from p_leader;
  delete from public.team_members where team_id = p_team_id and not (user_id = any (v_members));
  insert into public.team_members (team_id, user_id)
  select p_team_id, m from unnest(v_members) m on conflict do nothing;
  if p_leader is not null then
    insert into public.team_leaders (team_id, user_id) values (p_team_id, p_leader) on conflict do nothing;
  end if;

  perform public.write_audit('team_changed', 'team', p_team_id::text,
    jsonb_build_object('from', v_old, 'to', jsonb_build_object('members', to_jsonb(v_members), 'leader', p_leader)));
end;
$function$;
