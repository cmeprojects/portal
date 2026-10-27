-- Staff Portal · © cmeproject. All rights reserved.
--
-- Milestone 1: foundations.
-- People, roles, teams, registries, invitations, system settings, feature
-- switches and an append-only audit log. Every table has Row Level Security
-- on, so access is enforced by the database and not just the screens.
--
-- One company per install: each company has its own Supabase project.
-- The org_id column is a hidden "company" tag kept for a possible shared
-- (multi-company) version later. It is filled in automatically.

-- ---------------------------------------------------------------------------
-- Types
-- ---------------------------------------------------------------------------

create type public.app_role as enum (
  'support_worker',
  'team_leader',
  'manager',
  'staff_admin',
  'system_admin'
);

-- ---------------------------------------------------------------------------
-- Company (one row per install)
-- ---------------------------------------------------------------------------

create table public.organisation (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  created_at timestamptz not null default now()
);

create unique index organisation_single_row on public.organisation ((true));

create function public.default_org_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select id from public.organisation limit 1
$$;

-- ---------------------------------------------------------------------------
-- Settings and feature switches (changed only by the system admin)
-- ---------------------------------------------------------------------------

create table public.app_settings (
  key         text primary key,
  value       jsonb not null,
  label       text not null,
  description text,
  -- Public settings (branding) can be read before signing in.
  is_public   boolean not null default false,
  updated_at  timestamptz not null default now(),
  updated_by  uuid references auth.users (id)
);

create table public.features (
  key         text primary key,
  label       text not null,
  description text,
  enabled     boolean not null default true,
  sort_order  int not null default 0,
  updated_at  timestamptz not null default now(),
  updated_by  uuid references auth.users (id)
);

-- ---------------------------------------------------------------------------
-- People
-- ---------------------------------------------------------------------------

create table public.teams (
  id         uuid primary key default gen_random_uuid(),
  org_id     uuid not null default public.default_org_id() references public.organisation (id),
  name       text not null,
  active     boolean not null default true,
  created_at timestamptz not null default now()
);

create unique index teams_name_unique on public.teams (lower(name));

create table public.profiles (
  id             uuid primary key references auth.users (id) on delete restrict,
  org_id         uuid not null default public.default_org_id() references public.organisation (id),
  email          text not null,
  full_name      text not null default '',
  role           public.app_role not null default 'support_worker',
  -- The team a support worker belongs to (their team leader sees their tasks).
  team_id        uuid references public.teams (id) on delete set null,
  active         boolean not null default true,
  created_at     timestamptz not null default now(),
  deactivated_at timestamptz
);

create unique index profiles_email_unique on public.profiles (lower(email));
create index profiles_team_idx on public.profiles (team_id);

create table public.team_leaders (
  team_id uuid not null references public.teams (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  primary key (team_id, user_id)
);

-- Inviting someone creates their sign-in account straight away, so
-- accepted_at is when the account was linked; whether they have signed in
-- yet comes from the sign-in system.
create table public.invitations (
  id          uuid primary key default gen_random_uuid(),
  org_id      uuid not null default public.default_org_id() references public.organisation (id),
  email       text not null,
  full_name   text not null default '',
  role        public.app_role not null default 'support_worker',
  team_id     uuid references public.teams (id) on delete set null,
  invited_by  uuid references public.profiles (id),
  created_at  timestamptz not null default now(),
  accepted_at timestamptz,
  user_id     uuid references public.profiles (id)
);

create index invitations_email_idx on public.invitations (lower(email));

-- ---------------------------------------------------------------------------
-- Registries
-- ---------------------------------------------------------------------------

create table public.registries (
  id                uuid primary key default gen_random_uuid(),
  org_id            uuid not null default public.default_org_id() references public.organisation (id),
  name              text not null,
  description       text not null default '',
  requires_approval boolean not null default false,
  active            boolean not null default true,
  sort_order        int not null default 0,
  created_at        timestamptz not null default now()
);

create unique index registries_name_unique on public.registries (lower(name));

create table public.registry_managers (
  registry_id uuid not null references public.registries (id) on delete cascade,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  primary key (registry_id, user_id)
);

-- ---------------------------------------------------------------------------
-- Audit log (append-only: nobody can edit or delete it)
-- ---------------------------------------------------------------------------

create table public.audit_log (
  id         bigint generated always as identity primary key,
  org_id     uuid default public.default_org_id() references public.organisation (id),
  actor_id   uuid,
  action     text not null,
  entity     text not null,
  entity_id  text,
  details    jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index audit_log_created_idx on public.audit_log (created_at desc);

create function public.block_audit_changes()
returns trigger
language plpgsql
as $$
begin
  raise exception 'The audit log cannot be changed or deleted';
end;
$$;

create trigger audit_log_append_only
  before update or delete on public.audit_log
  for each row execute function public.block_audit_changes();

create trigger audit_log_no_truncate
  before truncate on public.audit_log
  for each statement execute function public.block_audit_changes();

create function public.write_audit(
  p_action text,
  p_entity text,
  p_entity_id text,
  p_details jsonb default '{}'::jsonb
)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.audit_log (actor_id, action, entity, entity_id, details)
  values (auth.uid(), p_action, p_entity, p_entity_id, coalesce(p_details, '{}'::jsonb));
$$;

-- ---------------------------------------------------------------------------
-- Who is asking? (helpers used by the security rules)
-- ---------------------------------------------------------------------------

-- The signed-in person's role, or null if they are deactivated or unknown.
create function public.my_role()
returns public.app_role
language sql
stable
security definer
set search_path = ''
as $$
  select role from public.profiles where id = auth.uid() and active
$$;

-- True when the person has finished two-factor login, or does not need it.
-- System admins always need it; other roles follow the
-- "security.mfa_required_roles" setting.
create function public.mfa_ok()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
    or (
      public.my_role() is distinct from 'system_admin'
      and not coalesce(
        (select s.value ? public.my_role()::text
           from public.app_settings s
          where s.key = 'security.mfa_required_roles'),
        false
      )
    )
$$;

-- True when the signed-in person is active, has one of the roles and has
-- passed two-factor login if their role needs it.
create function public.has_role(roles public.app_role[])
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(public.my_role() = any (roles), false) and public.mfa_ok()
$$;

create function public.is_member()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.my_role() is not null and public.mfa_ok()
$$;

create function public.is_staff_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.has_role(array['staff_admin', 'system_admin']::public.app_role[])
$$;

create function public.is_system_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.has_role(array['system_admin']::public.app_role[])
$$;

-- Does the signed-in team leader lead the team that this person is in?
-- (Used by the task rules in Milestone 2.)
create function public.leads_user(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.profiles p
      join public.team_leaders tl on tl.team_id = p.team_id
     where p.id = p_user_id
       and tl.user_id = auth.uid()
  ) and public.has_role(array['team_leader', 'manager', 'system_admin']::public.app_role[])
$$;

create function public.feature_enabled(p_key text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select enabled from public.features where key = p_key), false)
$$;

-- What the app needs to know about the signed-in person, readable before
-- two-factor login so it can send them to the right step.
create function public.my_access()
returns table (role public.app_role, active boolean, mfa_required boolean, mfa_ok boolean)
language sql
stable
security definer
set search_path = ''
as $$
  select
    p.role,
    p.active,
    p.role = 'system_admin' or coalesce(
      (select s.value ? p.role::text from public.app_settings s
        where s.key = 'security.mfa_required_roles'), false),
    public.mfa_ok()
  from public.profiles p
  where p.id = auth.uid()
$$;

revoke execute on function public.my_access() from public, anon;
grant execute on function public.my_access() to authenticated;

-- ---------------------------------------------------------------------------
-- New users: a profile is created from their invitation
-- ---------------------------------------------------------------------------

create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  inv public.invitations;
  first_user boolean;
begin
  select not exists (select 1 from public.profiles) into first_user;

  select * into inv
    from public.invitations i
   where lower(i.email) = lower(new.email)
     and i.accepted_at is null
   order by i.created_at desc
   limit 1;

  insert into public.profiles (id, email, full_name, role, team_id, active)
  values (
    new.id,
    new.email,
    coalesce(nullif(inv.full_name, ''), new.raw_user_meta_data ->> 'full_name', ''),
    case
      -- The very first account in a new install becomes its system admin.
      when first_user then 'system_admin'::public.app_role
      else coalesce(inv.role, 'support_worker'::public.app_role)
    end,
    inv.team_id,
    -- Public sign-up is off, but as a second lock anyone who arrives
    -- without an invitation starts deactivated.
    first_user or inv.id is not null
  );

  if inv.id is not null then
    update public.invitations
       set accepted_at = now(), user_id = new.id
     where id = inv.id;
  end if;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Guard rails on profile changes
-- ---------------------------------------------------------------------------

create function public.guard_profile_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor uuid := auth.uid();
  actor_role public.app_role := public.my_role();
begin
  if new.id <> old.id or new.email <> old.email or new.org_id <> old.org_id then
    raise exception 'This field cannot be changed here';
  end if;

  -- Server-side jobs (no signed-in person) skip the people rules below.
  if actor is not null then
    if new.role is distinct from old.role
       or new.team_id is distinct from old.team_id
       or new.active is distinct from old.active then

      if not public.is_staff_admin() then
        raise exception 'Only a staff admin can change roles, teams or access';
      end if;

      if actor_role <> 'system_admin'
         and (old.role in ('staff_admin', 'system_admin')
              or new.role in ('staff_admin', 'system_admin')) then
        raise exception 'Only a system admin can manage staff admins and system admins';
      end if;

      if new.id = actor and (new.role is distinct from old.role or not new.active) then
        raise exception 'You cannot change your own role or deactivate yourself';
      end if;
    end if;
  end if;

  -- Never leave the install without an active system admin.
  if old.role = 'system_admin' and old.active
     and (new.role <> 'system_admin' or not new.active)
     and not exists (
       select 1 from public.profiles
        where role = 'system_admin' and active and id <> old.id
     ) then
    raise exception 'There must always be at least one active system admin';
  end if;

  if new.active and not old.active then
    new.deactivated_at := null;
  elsif not new.active and old.active then
    new.deactivated_at := now();
  end if;

  if new.role is distinct from old.role then
    perform public.write_audit('role_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.role, 'to', new.role));
  end if;
  if new.active is distinct from old.active then
    perform public.write_audit(
      case when new.active then 'reactivated' else 'deactivated' end,
      'profile', new.id::text, '{}'::jsonb);
  end if;
  if new.team_id is distinct from old.team_id then
    perform public.write_audit('team_changed', 'profile', new.id::text,
      jsonb_build_object('from', old.team_id, 'to', new.team_id));
  end if;

  return new;
end;
$$;

create trigger profiles_guard
  before update on public.profiles
  for each row execute function public.guard_profile_update();

-- Staff admins can invite up to manager; only a system admin can invite
-- staff admins or system admins.
create function public.guard_invitation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null
     and new.role in ('staff_admin', 'system_admin')
     and public.my_role() is distinct from 'system_admin' then
    raise exception 'Only a system admin can invite staff admins or system admins';
  end if;
  new.email := lower(trim(new.email));
  if tg_op = 'INSERT' then
    new.invited_by := coalesce(new.invited_by, auth.uid());
    perform public.write_audit('invited', 'invitation', new.email,
      jsonb_build_object('role', new.role));
  end if;
  return new;
end;
$$;

create trigger invitations_guard
  before insert or update on public.invitations
  for each row execute function public.guard_invitation();

-- Settings and features record who changed them, and every change is logged.
create function public.track_setting_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.updated_at := now();
  new.updated_by := auth.uid();
  if tg_table_name = 'features' then
    if new.enabled is distinct from old.enabled then
      perform public.write_audit(
        case when new.enabled then 'feature_on' else 'feature_off' end,
        'feature', new.key, '{}'::jsonb);
    end if;
  elsif new.value is distinct from old.value then
    perform public.write_audit('setting_changed', 'setting', new.key,
      jsonb_build_object('from', old.value, 'to', new.value));
  end if;
  return new;
end;
$$;

create trigger app_settings_track
  before update on public.app_settings
  for each row execute function public.track_setting_change();

create trigger features_track
  before update on public.features
  for each row execute function public.track_setting_change();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.organisation      enable row level security;
alter table public.app_settings      enable row level security;
alter table public.features          enable row level security;
alter table public.teams             enable row level security;
alter table public.profiles          enable row level security;
alter table public.team_leaders      enable row level security;
alter table public.invitations       enable row level security;
alter table public.registries        enable row level security;
alter table public.registry_managers enable row level security;
alter table public.audit_log         enable row level security;

-- Company
create policy "members read the company" on public.organisation
  for select to authenticated using (public.is_member());
create policy "system admin edits the company" on public.organisation
  for update to authenticated using (public.is_system_admin()) with check (public.is_system_admin());

-- Settings: branding is public (shown on the sign-in page); the rest is
-- members only. Only the system admin changes anything.
create policy "anyone reads public settings" on public.app_settings
  for select to anon, authenticated using (is_public or public.is_member());
create policy "system admin edits settings" on public.app_settings
  for update to authenticated using (public.is_system_admin()) with check (public.is_system_admin());

create policy "members read features" on public.features
  for select to authenticated using (public.is_member());
-- The sign-in page needs to know which sign-in options are switched on.
create policy "anyone reads sign-in options" on public.features
  for select to anon, authenticated using (key like 'sign\_in\_%');
create policy "system admin switches features" on public.features
  for update to authenticated using (public.is_system_admin()) with check (public.is_system_admin());

-- Profiles: you can always read your own (even before two-factor login, so
-- the app knows where to send you). Members can see colleagues so they can
-- assign tasks. Changes are checked by guard_profile_update().
create policy "read own profile" on public.profiles
  for select to authenticated using (id = auth.uid());
create policy "members read colleagues" on public.profiles
  for select to authenticated using (public.is_member());
-- Allowed before two-factor login so new people can finish the welcome
-- page; guard_profile_update() stops anything but the name changing.
create policy "update own name" on public.profiles
  for update to authenticated
  using (id = auth.uid() and public.my_role() is not null)
  with check (id = auth.uid());
create policy "staff admin updates people" on public.profiles
  for update to authenticated using (public.is_staff_admin()) with check (public.is_staff_admin());

-- Teams and registries: members read, staff admins manage.
create policy "members read teams" on public.teams
  for select to authenticated using (public.is_member());
create policy "staff admin manages teams" on public.teams
  for all to authenticated using (public.is_staff_admin()) with check (public.is_staff_admin());

create policy "members read team leaders" on public.team_leaders
  for select to authenticated using (public.is_member());
create policy "staff admin manages team leaders" on public.team_leaders
  for all to authenticated using (public.is_staff_admin()) with check (public.is_staff_admin());

create policy "members read registries" on public.registries
  for select to authenticated using (public.is_member());
create policy "staff admin manages registries" on public.registries
  for all to authenticated using (public.is_staff_admin()) with check (public.is_staff_admin());

create policy "members read registry managers" on public.registry_managers
  for select to authenticated using (public.is_member());
create policy "staff admin manages registry managers" on public.registry_managers
  for all to authenticated using (public.is_staff_admin()) with check (public.is_staff_admin());

-- Invitations: staff admins only.
create policy "staff admin reads invitations" on public.invitations
  for select to authenticated using (public.is_staff_admin());
create policy "staff admin creates invitations" on public.invitations
  for insert to authenticated with check (public.is_staff_admin());
create policy "staff admin updates invitations" on public.invitations
  for update to authenticated using (public.is_staff_admin()) with check (public.is_staff_admin());
create policy "staff admin removes pending invitations" on public.invitations
  for delete to authenticated using (public.is_staff_admin() and accepted_at is null);

-- Audit log: only the system admin reads it; rows are written by the
-- database itself (write_audit) and can never be changed.
create policy "system admin reads the audit log" on public.audit_log
  for select to authenticated using (public.is_system_admin());

-- Lets the app log admin actions that happen outside the database
-- (resending an invite, resetting someone's two-factor login).
create function public.log_admin_action(p_action text, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_action = 'mfa_reset' and not public.is_system_admin() then
    raise exception 'Only a system admin can reset two-factor login';
  elsif p_action not in ('mfa_reset', 'invite_resent') or not public.is_staff_admin() then
    raise exception 'Not allowed';
  end if;
  perform public.write_audit(p_action, 'profile', p_user_id::text, '{}'::jsonb);
end;
$$;

revoke execute on function public.log_admin_action(text, uuid) from public, anon;
grant execute on function public.log_admin_action(text, uuid) to authenticated;

revoke insert, update, delete, truncate on public.audit_log from anon, authenticated;
revoke execute on function public.write_audit(text, text, text, jsonb) from public, anon, authenticated;
revoke execute on function public.handle_new_user() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Defaults for a new install
-- ---------------------------------------------------------------------------

insert into public.organisation (name) values ('My Company');

insert into public.app_settings (key, value, label, description, is_public) values
  ('brand.company_name',  '"My Company"', 'Company name', 'Shown in the menu, on the sign-in page and in emails.', true),
  ('brand.portal_name',   '"Staff Portal"', 'Portal name', 'Shown under the company name.', true),
  ('brand.logo_url',      '"/logo.svg"', 'Logo', 'Address of the logo image.', true),
  ('brand.color_primary', '"#134F8E"', 'Main colour', 'Buttons, links and highlights.', true),
  ('brand.color_dark',    '"#0F2F57"', 'Dark colour', 'Menu and headers.', true),
  ('brand.color_accent',  '"#6497C8"', 'Accent colour', 'Decoration only, never for text.', true),
  ('wording.client',      '"Client"', 'What you call the people you support', 'For example Client, Participant, Customer or Resident.', false),
  ('security.mfa_required_roles', '["team_leader", "manager", "staff_admin", "system_admin"]',
     'Roles that must use two-factor login', 'System admins always need it.', false),
  ('records.retention_years', '7', 'Keep records for (years)', 'Records older than this can be purged by a system admin.', false);

insert into public.features (key, label, description, enabled, sort_order) values
  ('tasks',               'Tasks and registries', 'Create, assign and track tasks.', true, 10),
  ('email_notifications', 'Email notifications', 'Send emails when tasks change.', true, 20),
  ('attachments',         'Attachments', 'Photos and files on tasks.', true, 30),
  ('auto_escalation',     'Auto-escalation', 'Flag overdue high-priority tasks every night.', true, 40),
  ('reports',             'Reports and exports', 'Excel and PDF reports for managers.', true, 50),
  ('vehicles',            'Vehicles and mileage', 'Trip logging and logbooks.', false, 60),
  ('sign_in_google',      'Google sign-in', 'Show "Continue with Google" on the sign-in page.', true, 70),
  ('sign_in_magic_link',  'Email sign-in link', 'Show "Email me a sign-in link" on the sign-in page.', true, 80);
