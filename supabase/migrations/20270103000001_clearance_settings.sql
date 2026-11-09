-- Staff Portal · © cmeproject. All rights reserved.
--
-- HR Pack delegation and clearance settings (cmeprojects).
--   * A new delegation area, HR Pack: request approvals (who approves each
--     request type, escalation) and who can clear people to work. The system
--     admin hands it to managers (or chosen people) on the Delegation tab, and
--     a delegated manager can share it with a staff admin.
--   * "Who can clear people to work" is no longer part of Compliance settings,
--     so delegated Compliance settings alone can't grant clearance powers.
--   * "Cars: cleared staff only" sits with the other Cars settings.

create or replace function public.setting_area(p_key text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when p_key = 'compliance.clearance_roles' then 'hr'
    when p_key = 'compliance.clearance_started' then null
    when p_key = 'cars.cleared_only' then 'vehicles'
    when p_key in ('brand.support_contact', 'brand.announcement', 'people.invite_message') then 'messages'
    when p_key like 'brand.%' or p_key like 'wording.%' then 'branding'
    when p_key like 'people.%' then 'people'
    when p_key like 'compliance.%' then 'compliance'
    when p_key like 'tasks.%' then 'tasks'
    when p_key like 'reports.%' then 'reports'
    when p_key like 'vehicles.%' then 'vehicles'
    when p_key like 'website.%' or p_key like 'assistant.%' then 'website'
    else null
  end
$$;

alter table public.delegation_rules drop constraint if exists delegation_rules_area_check;
alter table public.delegation_rules add constraint delegation_rules_area_check
  check (area in ('branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'website', 'audit', 'registers', 'roles', 'register_setup', 'hr'));
insert into public.delegation_rules (area, mode) values ('hr', 'admin') on conflict (area) do nothing;

alter table public.delegation_shares drop constraint if exists delegation_shares_area_check;
alter table public.delegation_shares add constraint delegation_shares_area_check
  check (area in ('branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'website', 'registers', 'hr'));

-- A delegated manager shares (or stops sharing) an area with a staff admin (HR Pack added).
create or replace function public.share_area(p_area text, p_user uuid, p_on boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.my_role() <> 'manager' or not public.can_admin_area(p_area) then
    raise exception 'Only a manager who looks after this area can share it.';
  end if;
  if p_area not in ('branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'website', 'registers', 'hr') then
    raise exception 'This area can''t be shared.';
  end if;
  if p_on then
    if not exists (select 1 from public.profiles where id = p_user and active and role = 'staff_admin') then
      raise exception 'Areas can only be shared with active staff admins.';
    end if;
    insert into public.delegation_shares (area, user_id, shared_by) values (p_area, p_user, auth.uid())
    on conflict (area, user_id) do update set shared_by = excluded.shared_by, shared_at = now();
  else
    delete from public.delegation_shares where area = p_area and user_id = p_user;
  end if;
  perform public.write_audit(case when p_on then 'area_shared' else 'area_unshared' end, 'profile', p_user::text, jsonb_build_object('area', p_area));
end;
$$;

-- Request approvals: the system admin, or whoever looks after HR Pack.
drop policy if exists "system admin changes request types" on public.request_types;
create policy "system admin changes request types" on public.request_types for update to authenticated
  using (public.can_admin_area('hr')) with check (public.can_admin_area('hr'));
