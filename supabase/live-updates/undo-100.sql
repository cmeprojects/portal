-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 100: teams go back to the built-in roles. Copied defaults are
-- kept (no effect). Safe to run again.
begin;
update public.app_modules set grant_ready = false where id = 'people.teams' and grant_ready;
drop policy if exists "managers and admins manage teams" on public.teams;
create policy "managers and admins manage teams" on public.teams for ALL to authenticated using (( SELECT can_manage_people() AS can_manage_people)) with check (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "managers set team leaders" on public.team_leaders;
create policy "managers set team leaders" on public.team_leaders for ALL to authenticated using (has_role(ARRAY['manager'::app_role, 'system_admin'::app_role])) with check (has_role(ARRAY['manager'::app_role, 'system_admin'::app_role]));
drop policy if exists "managers change team members" on public.team_members;
create policy "managers change team members" on public.team_members for ALL to authenticated using (has_role(ARRAY['manager'::app_role, 'system_admin'::app_role])) with check (has_role(ARRAY['manager'::app_role, 'system_admin'::app_role]));
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
  if not (public.has_role(array['manager', 'system_admin']::public.app_role[])
          or (public.has_role(array['staff_admin']::public.app_role[])
              and not public.rule_on('people.staff_admin_team_approval'))) then
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
commit;
