-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 84: puts the private details read rule back exactly as it was
-- (team leaders read their team's whole row again) and removes team_private()
-- and the "Team leaders see emergency contacts" switch. Safe to run again.
begin;
alter policy "the person and people managers see private details" on public.staff_private
  using (((select public.feature_enabled('hr_profiles'::text)) AND ((user_id = (select auth.uid())) OR (select public.can_manage_people()) OR (select public.is_system_admin()) OR (EXISTS ( SELECT 1
   FROM (team_leaders tl
     JOIN team_members tm ON ((tm.team_id = tl.team_id)))
  WHERE ((tl.user_id = (select auth.uid())) AND (tm.user_id = staff_private.user_id)))))));
drop function if exists public.team_private();
delete from public.features where key = 'hr_leader_emergency';
commit;
