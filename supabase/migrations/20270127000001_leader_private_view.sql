-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 84): team leaders get only what they need from private
-- details. Before, the read rule on staff_private let a team leader read the
-- whole row for their team (address, emergency contact, employee ID,
-- employment type, start date). Now:
--   * the read rule keeps the person, people managers and the system admin,
--     exactly as before, and drops the team leader part (same Stage 1 form);
--   * team_private() gives a team leader, for their own teams only:
--     availability and start date (for work anniversaries), and the emergency
--     contact only when the system admin turns on "Team leaders see emergency
--     contacts" (off by default);
--   * nothing else changes: writes, other tables and other roles are untouched.
-- team_private() is SECURITY DEFINER (approved by the owner, 15 Nov 2026) so it
-- can read past the narrowed rule; it returns fixed columns for the caller's
-- own teams only.

insert into public.features (key, label, description, enabled, sort_order, premium, included, parent)
values ('hr_leader_emergency', 'Team leaders see emergency contacts',
        'Team leaders can see the emergency contact of people in their teams. When off, they see availability and work anniversaries only.',
        false, 335, false, true, 'hr_profiles')
on conflict (key) do nothing;

alter policy "the person and people managers see private details" on public.staff_private
  using (((select public.feature_enabled('hr_profiles'::text)) AND ((user_id = (select auth.uid())) OR (select public.can_manage_people()) OR (select public.is_system_admin()))));

create or replace function public.team_private()
returns table (user_id uuid, availability jsonb, start_date date, emergency_name text, emergency_phone text)
language sql
stable
security definer
set search_path = ''
as $$
  select sp.user_id, sp.availability, sp.start_date,
         case when e.on_ then coalesce(sp.emergency_name, '') end,
         case when e.on_ then coalesce(sp.emergency_phone, '') end
    from public.staff_private sp
   cross join (select public.feature_live('hr_leader_emergency') as on_) e
   where auth.uid() is not null
     and public.is_member()
     and public.feature_enabled('hr_profiles')
     and sp.user_id <> auth.uid()
     and exists (select 1
                   from public.team_leaders tl
                   join public.team_members tm on tm.team_id = tl.team_id
                  where tl.user_id = auth.uid() and tm.user_id = sp.user_id)
$$;

revoke execute on function public.team_private() from public, anon;
grant execute on function public.team_private() to authenticated;
