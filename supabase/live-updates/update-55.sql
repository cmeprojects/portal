-- Staff Portal · © cmeproject. All rights reserved.
-- Update 55: HR Pack (premium, on by default, every part switchable) and staff
-- profiles with a directory and private details. Safe to run again. Undo: undo-55.sql.
begin;
insert into public.features (key, label, description, enabled, sort_order, premium, included, parent) values
  ('hr', 'HR Pack', 'Staff profiles and directory, My requests and approvals, and Compliance and onboarding.', true, 39, true, true, null),
  ('hr_profiles', 'Staff profiles and directory', 'Professional profiles (photo, preferred name, department, contact, skills, availability) and a staff directory.', true, 330, false, true, 'hr'),
  ('hr_requests', 'My requests', 'Staff send requests (leave, shift swaps, availability and more) and track them; approvers approve or decline.', true, 340, false, true, 'hr'),
  ('hr_req_leave', 'Leave requests', 'Annual, personal/carer''s, unpaid, long service, compassionate and other leave.', true, 341, false, true, 'hr_requests'),
  ('hr_req_swap', 'Shift swap requests', 'Swap a shift with a colleague (they accept first).', true, 342, false, true, 'hr_requests'),
  ('hr_req_shift', 'Shift change requests', 'Ask to change a shift.', true, 343, false, true, 'hr_requests'),
  ('hr_req_availability', 'Availability changes', 'Change your regular weekly availability.', true, 344, false, true, 'hr_requests'),
  ('hr_req_timesheet', 'Timesheet corrections', 'Correct the times on a timesheet.', true, 345, false, true, 'hr_requests'),
  ('hr_req_hr', 'HR and employment enquiries', 'Questions about pay, contracts and employment.', true, 346, false, true, 'hr_requests'),
  ('hr_req_other', 'Other requests', 'Anything else.', true, 347, false, true, 'hr_requests')
on conflict (key) do nothing;

-- Compliance and onboarding becomes part of the HR Pack.
update public.features set parent = 'hr' where key = 'compliance' and parent is null;

-- On only while it and every level above it are on (and included).
create or replace function public.feature_live(p_key text)
returns boolean
language sql
stable
set search_path = ''
as $$
  with recursive chain as (
    select f.key, f.parent, (f.enabled and f.included) as on_, 1 as depth from public.features f where f.key = p_key
    union all
    select p.key, p.parent, (p.enabled and p.included), c.depth + 1
      from public.features p join chain c on p.key = c.parent
     where c.depth < 6
  )
  select coalesce(bool_and(on_), false) and exists (select 1 from chain) from chain
$$;

-- ---------------------------------------------------------------------------
-- Staff profiles
-- ---------------------------------------------------------------------------

create table if not exists public.staff_directory (
  user_id        uuid primary key references public.profiles (id) on delete cascade,
  preferred_name text not null default '' check (length(preferred_name) <= 60),
  department     text not null default '' check (length(department) <= 80),
  work_phone     text not null default '' check (length(work_phone) <= 30),
  skills         text[] not null default '{}',
  updated_at     timestamptz not null default now()
);

create table if not exists public.staff_private (
  user_id         uuid primary key references public.profiles (id) on delete cascade,
  address         text not null default '' check (length(address) <= 300),
  emergency_name  text not null default '' check (length(emergency_name) <= 100),
  emergency_phone text not null default '' check (length(emergency_phone) <= 30),
  start_date      date,
  employment_type text not null default '' check (employment_type in ('', 'full_time', 'part_time', 'casual', 'contractor')),
  employee_id     text not null default '' check (length(employee_id) <= 40),
  -- Weekly availability, for example {"mon": ["am", "pm"], "tue": [], ...}
  availability    jsonb not null default '{}'::jsonb,
  updated_at      timestamptz not null default now()
);

alter table public.staff_directory enable row level security;
alter table public.staff_private enable row level security;

-- Everyone in the company sees the directory card while profiles are on.
drop policy if exists "members see the staff directory" on public.staff_directory;
create policy "members see the staff directory" on public.staff_directory
  for select to authenticated using (public.is_member() and public.feature_enabled('hr_profiles'));

-- Private details: the person, people who manage staff, and the system admin.
-- Team leaders also see their team members' availability (for rostering later).
drop policy if exists "the person and people managers see private details" on public.staff_private;
create policy "the person and people managers see private details" on public.staff_private
  for select to authenticated using (
    public.feature_enabled('hr_profiles') and (
      user_id = auth.uid() or public.can_manage_people() or public.is_system_admin()
      or exists (
        select 1 from public.team_leaders tl join public.team_members tm on tm.team_id = tl.team_id
         where tl.user_id = auth.uid() and tm.user_id = staff_private.user_id)));

revoke insert, update, delete, truncate on public.staff_directory, public.staff_private from anon, authenticated;
grant select on public.staff_directory, public.staff_private to authenticated;

-- Fields a person edits themselves, and fields only people managers edit.
create or replace function public.save_profile(p_user uuid, p jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  me boolean := p_user = auth.uid();
  manager boolean := public.can_manage_people() or public.is_system_admin();
  v_skills text[];
begin
  if not public.is_member() or not public.feature_enabled('hr_profiles') then
    raise exception 'Staff profiles are switched off.';
  end if;
  if not me and not manager then
    raise exception 'You can only change your own profile.';
  end if;
  if not exists (select 1 from public.profiles where id = p_user) then
    raise exception 'That person doesn''t exist.';
  end if;
  insert into public.staff_directory (user_id) values (p_user) on conflict do nothing;
  insert into public.staff_private (user_id) values (p_user) on conflict do nothing;

  if p ? 'skills' then
    select coalesce(array_agg(distinct left(trim(x), 40)) filter (where trim(x) <> ''), '{}') into v_skills
      from jsonb_array_elements_text(p -> 'skills') x;
  end if;

  -- Anyone allowed here (themselves or a people manager).
  update public.staff_directory set
    preferred_name = case when p ? 'preferred_name' then left(trim(p ->> 'preferred_name'), 60) else preferred_name end,
    work_phone     = case when p ? 'work_phone' then left(trim(p ->> 'work_phone'), 30) else work_phone end,
    skills         = case when p ? 'skills' then v_skills else staff_directory.skills end,
    updated_at     = now()
   where user_id = p_user;
  update public.staff_private set
    address         = case when p ? 'address' then left(trim(p ->> 'address'), 300) else address end,
    emergency_name  = case when p ? 'emergency_name' then left(trim(p ->> 'emergency_name'), 100) else emergency_name end,
    emergency_phone = case when p ? 'emergency_phone' then left(trim(p ->> 'emergency_phone'), 30) else emergency_phone end,
    availability    = case when p ? 'availability' and jsonb_typeof(p -> 'availability') = 'object' then p -> 'availability' else availability end,
    updated_at      = now()
   where user_id = p_user;

  -- Employment details: people managers only.
  if manager then
    update public.staff_directory set
      department = case when p ? 'department' then left(trim(p ->> 'department'), 80) else department end
     where user_id = p_user;
    update public.staff_private set
      start_date      = case when p ? 'start_date' then nullif(p ->> 'start_date', '')::date else start_date end,
      employment_type = case when p ? 'employment_type' then coalesce(p ->> 'employment_type', '') else employment_type end,
      employee_id     = case when p ? 'employee_id' then left(trim(p ->> 'employee_id'), 40) else employee_id end
     where user_id = p_user;
  elsif p ?| array['department', 'start_date', 'employment_type', 'employee_id'] then
    raise exception 'Only people who manage staff can change department and employment details.';
  end if;

  if not me then
    perform public.write_audit('profile_updated', 'profile', p_user::text, '{}'::jsonb);
  end if;
end;
$$;

revoke execute on function public.save_profile(uuid, jsonb) from public, anon;
grant execute on function public.save_profile(uuid, jsonb) to authenticated;
commit;
