-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects module framework step 2: one permission check for everything.
--   * can(module, action, person) answers "may the signed-in person do this?"
--     - the system admin: always (protected modules: only the system admin);
--     - modules already covered by today's rules answer from those rules
--       exactly (settings areas → can_admin_area; staff records → has_access,
--       TFN → has_tfn_access), so nobody's access changes;
--     - everything else: grants on the module, its parent or its category,
--       the nearest one winning; a "restrict" grant blocks; sensitive modules
--       never inherit (they need their own grant); actions can be limited;
--       scope (all / teams / people), start and end dates apply; a module
--       added after the grant was given is not covered by it.
--   * my_modules(): the modules the signed-in person can view (for menus).
--   * Grants (access_grants) gain: module, actions, effect (allow/restrict),
--     include children, start date. Existing grants get their module filled in.
--   * Categories are in the catalogue too (cat_*), so a whole category can be granted.
-- Nothing in existing security rules changes, so pages do no extra work.
-- No new SECURITY DEFINER function.

-- 1. Catalogue: categories, permission-only modules, and the link to today's rules.
alter table public.app_modules add column if not exists legacy_kind text check (legacy_kind in ('settings', 'record'));
alter table public.app_modules add column if not exists legacy_area text;
alter table public.app_modules add column if not exists actions text[] not null default array['view'];
-- When a module was added: access given to a parent or category before then
-- doesn't reach it (new modules are never given to anyone automatically).
alter table public.app_modules add column if not exists added_at timestamptz not null default now();

insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order) values
  ('cat_workspace', null, 'workspace', 'My workspace', 'normal', false, 0),
  ('cat_operations', null, 'operations', 'Operations', 'normal', true, 1),
  ('cat_people', null, 'people', 'People & organisation', 'normal', true, 2),
  ('cat_hr', null, 'hr', 'HR & workforce', 'normal', true, 3),
  ('cat_clients', null, 'clients', 'Clients & care', 'normal', true, 4),
  ('cat_workflows', null, 'workflows', 'Forms & workflows', 'normal', true, 5),
  ('cat_insights', null, 'insights', 'Reports & insights', 'normal', true, 6),
  ('cat_engagement', null, 'engagement', 'Website & engagement', 'normal', true, 7),
  ('cat_system', null, 'system', 'Administration', 'normal', false, 8)
on conflict (id) do update set label = excluded.label, delegable = excluded.delegable, sort_order = excluded.sort_order;

insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order) values
  ('hr.records', null, 'hr', 'Staff records', 'normal', true, 1010),
  ('hr.records.details', 'hr.records', 'hr', 'Staff details', 'normal', true, 1020),
  ('hr.records.payroll', 'hr.records', 'hr', 'Payroll and tax (bank, super, TFN)', 'sensitive', true, 1030),
  ('hr.records.identity', 'hr.records', 'hr', 'Identity and work rights', 'sensitive', true, 1040),
  ('system.settings.branding', 'system.settings', 'system', 'Branding', 'normal', true, 1050),
  ('system.settings.messages', 'system.settings', 'system', 'Messages', 'normal', true, 1060),
  ('system.settings.people', 'system.settings', 'system', 'People rules', 'normal', true, 1070),
  ('system.settings.compliance', 'system.settings', 'system', 'Compliance settings', 'normal', true, 1080),
  ('system.settings.tasks', 'system.settings', 'system', 'Task settings', 'normal', true, 1090),
  ('system.settings.reports', 'system.settings', 'system', 'Who can see reports', 'normal', true, 1100),
  ('system.settings.vehicles', 'system.settings', 'system', 'Car settings', 'normal', true, 1110),
  ('system.settings.hr', 'system.settings', 'system', 'HR Pack settings', 'normal', true, 1120),
  ('ops.registers.setup', 'ops.registers', 'operations', 'Set up any register', 'normal', true, 1130)
on conflict (id) do update set parent_id = excluded.parent_id, category = excluded.category, label = excluded.label,
  sensitivity = excluded.sensitivity, delegable = excluded.delegable, sort_order = excluded.sort_order;

update public.app_modules set legacy_kind = 'settings', legacy_area = 'branding' where id = 'system.settings.branding';
update public.app_modules set legacy_kind = 'settings', legacy_area = 'messages' where id = 'system.settings.messages';
update public.app_modules set legacy_kind = 'settings', legacy_area = 'people' where id = 'system.settings.people';
update public.app_modules set legacy_kind = 'settings', legacy_area = 'compliance' where id = 'system.settings.compliance';
update public.app_modules set legacy_kind = 'settings', legacy_area = 'tasks' where id = 'system.settings.tasks';
update public.app_modules set legacy_kind = 'settings', legacy_area = 'reports' where id = 'system.settings.reports';
update public.app_modules set legacy_kind = 'settings', legacy_area = 'vehicles' where id = 'system.settings.vehicles';
update public.app_modules set legacy_kind = 'settings', legacy_area = 'hr' where id = 'system.settings.hr';
update public.app_modules set legacy_kind = 'settings', legacy_area = 'website' where id = 'engagement.website';
update public.app_modules set legacy_kind = 'settings', legacy_area = 'audit' where id = 'system.audit';
update public.app_modules set legacy_kind = 'settings', legacy_area = 'registers' where id = 'ops.registers';
update public.app_modules set legacy_kind = 'settings', legacy_area = 'register_setup' where id = 'ops.registers.setup';
update public.app_modules set legacy_kind = 'settings', legacy_area = 'roles' where id = 'people.roles';
update public.app_modules set legacy_kind = 'record', legacy_area = 'staff_details' where id = 'hr.records.details';
update public.app_modules set legacy_kind = 'record', legacy_area = 'payroll_tax' where id = 'hr.records.payroll';
update public.app_modules set legacy_kind = 'record', legacy_area = 'identity_docs' where id = 'hr.records.identity';

-- Submodules of delegable modules can be given on their own.
update public.app_modules c set delegable = true
  from public.app_modules p
 where c.parent_id = p.id and p.delegable and c.sensitivity <> 'protected' and not c.delegable;

-- What each module allows (view is always first).
update public.app_modules set actions = array['view', 'create', 'edit', 'delete', 'configure', 'export'] where id in ('ops.tasks', 'ops.registers', 'ops.features');
update public.app_modules set actions = array['view', 'configure'] where legacy_kind = 'settings' or id like 'system.settings%';
update public.app_modules set actions = array['view', 'edit'] where id in ('hr.records', 'hr.records.details', 'people.staff', 'people.teams', 'people.roles', 'clients.list');
update public.app_modules set actions = array['view', 'edit', 'download', 'reveal_tfn', 'delete'] where id = 'hr.records.payroll';
update public.app_modules set actions = array['view', 'edit', 'download', 'delete'] where id = 'hr.records.identity';
update public.app_modules set actions = array['view', 'create', 'sign_for_employer', 'download'] where id = 'hr.contracts';
update public.app_modules set actions = array['view', 'configure', 'approve', 'export'] where id in ('hr.onboarding', 'hr.onboarding.overview', 'hr.onboarding.expiry');
update public.app_modules set actions = array['view', 'approve', 'configure'] where id in ('hr.requests', 'workflows.request_rules');
update public.app_modules set actions = array['view', 'create', 'edit', 'delete', 'export'] where id = 'workflows.forms';
update public.app_modules set actions = array['view', 'export'] where id like 'insights.%';
update public.app_modules set actions = array['view', 'configure'] where id in ('workflows.sla', 'engagement.website', 'engagement.enquiries', 'ops.cars', 'ops.cars.manage');

-- 2. Grants: which module, which actions, allow or restrict, children, start date.
alter table public.access_grants alter column area drop not null;
alter table public.access_grants add column if not exists module_id text references public.app_modules (id);
alter table public.access_grants add column if not exists actions text[] not null default '{}';
alter table public.access_grants add column if not exists effect text not null default 'allow' check (effect in ('allow', 'restrict'));
alter table public.access_grants add column if not exists include_children boolean not null default true;
alter table public.access_grants add column if not exists starts_at timestamptz;
alter table public.access_grants drop constraint if exists access_grants_area_or_module;
alter table public.access_grants add constraint access_grants_area_or_module check (area is not null or module_id is not null);
-- (the "can only be removed" guard is paused for this one-off fill-in)
alter table public.access_grants disable trigger access_grants_revoke_only;
alter table public.access_grants disable trigger access_grants_cascade;
update public.access_grants g set module_id = m.id
  from public.app_modules m
 where g.module_id is null and m.legacy_kind = 'record' and m.legacy_area = g.area;
alter table public.access_grants enable trigger access_grants_revoke_only;
alter table public.access_grants enable trigger access_grants_cascade;
create unique index if not exists access_grants_one_live_module
  on public.access_grants (module_id, user_id) where revoked_at is null and area is null;
create index if not exists access_grants_user_module on public.access_grants (user_id, module_id) where revoked_at is null;

-- New module grants: an active, delegable, non-protected module; real actions only.
create or replace function public.check_module_grant()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  m record;
begin
  if new.module_id is null or new.area is not null then
    return new;
  end if;
  select * into m from public.app_modules where id = new.module_id;
  if not found or m.status <> 'active' then
    raise exception 'That module doesn''t exist.';
  end if;
  if m.sensitivity = 'protected' or not m.delegable then
    raise exception 'That part of the portal can''t be delegated.';
  end if;
  if m.legacy_kind is not null then
    raise exception 'That part is still managed on its existing page (Staff access or Delegation).';
  end if;
  if exists (select 1 from unnest(new.actions) a where a <> all (m.actions)) then
    raise exception 'One of those actions doesn''t apply to this module.';
  end if;
  return new;
end;
$$;
revoke execute on function public.check_module_grant() from public, anon, authenticated;
drop trigger if exists check_module_grant on public.access_grants;
create trigger check_module_grant before insert on public.access_grants
  for each row execute function public.check_module_grant();

-- 3. The one check.
create or replace function public.can(p_module text, p_action text default 'view', p_person uuid default null)
returns boolean
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  m record;
  v_effect text;
begin
  select * into m from public.app_modules where id = p_module;
  if not found or m.status <> 'active' then
    return false;
  end if;
  if public.is_system_admin() and public.mfa_ok() then
    return true;
  end if;
  if m.sensitivity = 'protected' or not public.mfa_ok() then
    return false;
  end if;
  -- Today's rules, unchanged.
  if m.legacy_kind = 'settings' then
    return public.can_admin_area(m.legacy_area);
  end if;
  if m.legacy_kind = 'record' then
    if p_action = 'reveal_tfn' then
      return p_person is not null and public.has_tfn_access(p_person);
    end if;
    return case when p_person is null then public.holds_area(m.legacy_area) else public.has_access(m.legacy_area, p_person) end;
  end if;
  -- Grants: the nearest level (this module, then its parents, then its category) decides.
  with recursive chain(id, depth) as (
    select m.id, 0
    union all
    select a.parent_id, c.depth + 1 from public.app_modules a join chain c on a.id = c.id where a.parent_id is not null
  ), levels as (
    select id, depth from chain
    union all
    select 'cat_' || m.category, 99
  )
  -- The nearest level with any grant decides: a restriction there for this
  -- action blocks; an allow there that includes this action allows; otherwise no.
  , applicable as (
    select g.effect, g.actions, l.depth
      from public.access_grants g
      join levels l on l.id = g.module_id
      join public.profiles me on me.id = g.user_id
      left join public.profiles gb on gb.id = g.granted_by
     where g.user_id = auth.uid() and g.area is null and g.revoked_at is null
       and (g.expires_at is null or g.expires_at > now())
       and (g.starts_at is null or g.starts_at <= now())
       and me.active and me.role in ('manager', 'staff_admin')
       and (g.parent_id is null or (gb.active and gb.role = 'manager'))
       and (l.depth = 0 or (g.include_children and m.sensitivity = 'normal' and m.added_at <= g.created_at))
       and (p_person is null or g.scope = 'all'
            or (g.scope = 'people' and p_person = any (g.scope_ids))
            or (g.scope = 'teams' and exists (select 1 from public.team_members tm where tm.user_id = p_person and tm.team_id = any (g.scope_ids))))
  )
  select case
           when bool_or(a.effect = 'restrict' and (cardinality(a.actions) = 0 or p_action = any (a.actions))) then 'restrict'
           when bool_or(a.effect = 'allow' and (cardinality(a.actions) = 0 or p_action = any (a.actions))) then 'allow'
         end into v_effect
    from applicable a
   where a.depth = (select min(depth) from applicable);
  return coalesce(v_effect = 'allow', false);
end;
$$;
revoke execute on function public.can(text, text, uuid) from public, anon;
grant execute on function public.can(text, text, uuid) to authenticated;

-- 4. The modules the signed-in person can view.
create or replace function public.my_modules()
returns setof text
language sql
stable
security invoker
set search_path = ''
as $$
  select id from public.app_modules where id not like 'cat\_%' and public.can(id, 'view')
$$;
revoke execute on function public.my_modules() from public, anon;
grant execute on function public.my_modules() to authenticated;
