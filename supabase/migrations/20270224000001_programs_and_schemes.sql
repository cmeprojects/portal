-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 110; Care block C0; owner: "I want a proper
-- determination; I don't want to cross over the wordings and business rules
-- and policies in between"): programs belong to a fixed scheme, and the
-- scheme decides its own wording and rules.
--
--   * Schemes are fixed in the portal: NDIS, Support at Home, Private, Other.
--     Each has its own wording (what the person is called, what its review is
--     called) and rules (date of birth, review reminders), in client_schemes.
--     The wording and rules can be changed; the list of schemes can't.
--   * Every program sits under exactly one scheme. Existing programs are
--     matched by name; anything else is Other. A program's scheme can't change
--     once a service uses it.
--   * New settings area "Care settings": programs, scheme wording and rules,
--     and (later steps) the client section switches. The system admin can give
--     it to a manager (for example the Manager Administrator) on the Access
--     page, like the other settings areas. The system admin always has it.
--   * Nobody's access to client records changes.

-- The new settings area.
alter table public.delegation_rules drop constraint if exists delegation_rules_area_check;
alter table public.delegation_rules add constraint delegation_rules_area_check
  check (area = any (array['branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'website', 'audit', 'registers', 'roles', 'register_setup', 'hr', 'care']));

insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order) values
  ('system.settings.care', 'system.settings', 'system', 'Care settings', 'normal', true, 1125)
on conflict (id) do nothing;
update public.app_modules set legacy_kind = 'settings', legacy_area = 'care' where id = 'system.settings.care' and legacy_kind is null;

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
    when p_key like 'care.%' then 'care'
    else null
  end
$$;

-- Schemes, their wording and rules.
create table if not exists public.client_schemes (
  key text primary key check (key in ('ndis', 'support_at_home', 'private', 'other')),
  org_id uuid not null default public.default_org_id(),
  label text not null check (length(label) between 1 and 60),
  person_word text check (person_word is null or length(person_word) between 1 and 30),
  review_label text not null check (length(review_label) between 1 and 60),
  change_review_label text not null check (length(change_review_label) between 1 and 60),
  review_lead_days int[] not null default '{30}' check (cardinality(review_lead_days) between 1 and 5),
  needs_dob boolean not null default false,
  sort_order int not null default 0,
  updated_by uuid references public.profiles (id),
  updated_at timestamptz not null default now()
);
alter table public.client_schemes enable row level security;
drop policy if exists "members read schemes" on public.client_schemes;
create policy "members read schemes" on public.client_schemes
  for select to authenticated using ((select public.is_member()));
drop policy if exists "care settings change scheme wording" on public.client_schemes;
create policy "care settings change scheme wording" on public.client_schemes
  for update to authenticated
  using ((select public.can_admin_area('care')))
  with check ((select public.can_admin_area('care')));
grant select, update on public.client_schemes to authenticated;

create or replace function public.guard_client_scheme()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.key is distinct from old.key then
    raise exception 'A scheme can''t be renamed or replaced. Change its wording instead.';
  end if;
  new.updated_by := auth.uid();
  new.updated_at := now();
  return new;
end;
$$;
revoke execute on function public.guard_client_scheme() from public, anon, authenticated;
drop trigger if exists guard_client_scheme on public.client_schemes;
create trigger guard_client_scheme before update on public.client_schemes
  for each row execute function public.guard_client_scheme();

insert into public.client_schemes (key, label, person_word, review_label, change_review_label, review_lead_days, needs_dob, sort_order) values
  ('ndis', 'NDIS', 'Participant', 'Plan review', 'Change of situation', '{90,60,30}', true, 10),
  ('support_at_home', 'Support at Home', null, 'Re-assessment', 'Re-assessment (change of situation)', '{30}', true, 20),
  ('private', 'Private', null, 'Review', 'Review (change of situation)', '{30}', false, 30),
  ('other', 'Other', null, 'Review', 'Review (change of situation)', '{30}', false, 40)
on conflict (key) do nothing;

-- Every program sits under one scheme.
alter table public.client_programs add column if not exists scheme text not null default 'other'
  references public.client_schemes (key) on delete restrict;
update public.client_programs set scheme = case lower(name)
    when 'ndis' then 'ndis' when 'support at home' then 'support_at_home' when 'private' then 'private' else 'other' end
 where scheme = 'other' and lower(name) in ('ndis', 'support at home', 'private');

create or replace function public.guard_program_scheme()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and new.scheme is distinct from old.scheme
     and exists (select 1 from public.client_services s where s.program_id = old.id) then
    raise exception 'This program is used by services, so its scheme can''t change. Add a new program instead.';
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_program_scheme() from public, anon, authenticated;
drop trigger if exists guard_program_scheme on public.client_programs;
create trigger guard_program_scheme before update on public.client_programs
  for each row execute function public.guard_program_scheme();

-- Programs are managed in Care settings (was the system admin only).
drop policy if exists "the system admin adds programs" on public.client_programs;
drop policy if exists "care settings add programs" on public.client_programs;
create policy "care settings add programs" on public.client_programs
  for insert to authenticated with check ((select public.can_admin_area('care')));
drop policy if exists "the system admin changes programs" on public.client_programs;
drop policy if exists "care settings change programs" on public.client_programs;
create policy "care settings change programs" on public.client_programs
  for update to authenticated
  using ((select public.can_admin_area('care')))
  with check ((select public.can_admin_area('care')));
