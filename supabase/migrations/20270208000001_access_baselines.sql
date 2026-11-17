-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 94; function-based access, Stage 3; decisions D-045,
-- D-046, D-047): grants held by a job title, a function group or an access
-- level, in the one permission check `can()`.
--
--   * Person grants (`access_grants`) are unchanged and still decide first.
--   * Then, in order: the person's job title, their function groups, their
--     access level (the default for everyone at that level). The first tier
--     with an applicable grant decides; within a tier the nearest module level
--     decides and a restriction beats an allow. A person's restriction is
--     never overridden.
--   * Ceiling: protected modules stay system admin only; new starters and
--     external accounts get nothing inherited; sensitive modules are never
--     given through a function group; settings areas and staff records keep
--     their own rules.
--   * Only modules marked `grant_ready` (switched over to `can()` alone,
--     Stage 3b onwards) can be given this way. None are yet, so nobody's
--     access changes in this update.
--   * The system admin sets any of these. A Manager Administrator sets job
--     title and function group grants only within their own authority: parts
--     they hold with "may pass on", never wider actions, never access-level
--     defaults; their grants stop counting if they stop being a Manager
--     Administrator. Revoked, never deleted.

alter table public.app_modules add column if not exists grant_ready boolean not null default false;

create table if not exists public.access_baselines (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  job_title_id uuid references public.job_titles (id) on delete restrict,
  function_group_id uuid references public.function_groups (id) on delete restrict,
  access_level public.app_role,
  module_id text not null references public.app_modules (id) on delete restrict,
  actions text[] not null default '{}',
  effect text not null default 'allow' check (effect in ('allow', 'restrict')),
  scope text not null default 'all' check (scope in ('all', 'own_teams')),
  note text not null default '' check (length(note) <= 300),
  granted_by uuid default auth.uid() references public.profiles (id),
  -- Given by the system admin (set on saving; system admins are hidden from staff).
  by_system_admin boolean not null default false,
  created_at timestamptz not null default now(),
  revoked_at timestamptz,
  revoked_by uuid references public.profiles (id),
  constraint access_baselines_one_holder check (num_nonnulls(job_title_id, function_group_id, access_level) = 1)
);
-- One live grant per holder and module.
create unique index if not exists access_baselines_live_title on public.access_baselines (job_title_id, module_id) where revoked_at is null and job_title_id is not null;
create unique index if not exists access_baselines_live_group on public.access_baselines (function_group_id, module_id) where revoked_at is null and function_group_id is not null;
create unique index if not exists access_baselines_live_level on public.access_baselines (access_level, module_id) where revoked_at is null and access_level is not null;
create index if not exists access_baselines_module on public.access_baselines (module_id) where revoked_at is null;
alter table public.access_baselines enable row level security;

drop policy if exists "the system admin, manager administrators and holders read baselines" on public.access_baselines;
create policy "the system admin, manager administrators and holders read baselines" on public.access_baselines
  for select to authenticated
  using ((select public.is_system_admin()) or (select public.is_manager_admin())
         or job_title_id = (select p.job_title_id from public.profiles p where p.id = (select auth.uid()))
         or function_group_id in (select jf.function_group_id from public.job_title_functions jf
                                    join public.profiles p on p.job_title_id = jf.job_title_id
                                   where p.id = (select auth.uid()))
         or access_level = (select p.role from public.profiles p where p.id = (select auth.uid())));
-- A Manager Administrator may give a job title or function group only what
-- they hold themselves with "may pass on" (same module, or a parent or
-- category that includes it), never wider actions.
create or replace function public.baseline_grant_allowed(p_module text, p_actions text[])
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  with recursive up(id) as (
    select p_module
    union all
    select m.parent_id from public.app_modules m join up on m.id = up.id where m.parent_id is not null
  )
  select public.is_manager_admin() and public.mfa_ok() and exists (
    select 1
      from public.access_grants g, public.app_modules target
     where target.id = p_module
       and g.user_id = auth.uid() and g.area is null and g.parent_id is null
       and g.can_pass_on and g.effect = 'allow' and g.revoked_at is null
       and (g.expires_at is null or g.expires_at > now()) and (g.starts_at is null or g.starts_at <= now())
       and (g.module_id = p_module
            or (target.sensitivity = 'normal' and g.include_children
                and (g.module_id in (select id from up) or g.module_id = 'cat_' || target.category)))
       and (cardinality(g.actions) = 0 or (cardinality(p_actions) > 0 and p_actions <@ g.actions)))
$$;
revoke execute on function public.baseline_grant_allowed(text, text[]) from public, anon;
grant execute on function public.baseline_grant_allowed(text, text[]) to authenticated;

drop policy if exists "the system admin and manager administrators add baselines" on public.access_baselines;
create policy "the system admin and manager administrators add baselines" on public.access_baselines
  for insert to authenticated
  with check ((select public.is_system_admin())
              or (access_level is null and public.baseline_grant_allowed(module_id, actions)));
drop policy if exists "the system admin and the giver revoke baselines" on public.access_baselines;
create policy "the system admin and the giver revoke baselines" on public.access_baselines
  for update to authenticated
  using ((select public.is_system_admin()) or granted_by = (select auth.uid()))
  with check ((select public.is_system_admin()) or granted_by = (select auth.uid()));
-- No delete rule: revoked, never deleted.
grant select, insert, update on public.access_baselines to authenticated;

create or replace function public.guard_access_baseline()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  m record;
begin
  if tg_op = 'UPDATE' then
    if (to_jsonb(new) - 'revoked_at' - 'revoked_by') is distinct from (to_jsonb(old) - 'revoked_at' - 'revoked_by') or old.revoked_at is not null then
      raise exception 'A grant isn''t changed: revoke it and add a new one.';
    end if;
    new.revoked_by := auth.uid();
    return new;
  end if;
  select * into m from public.app_modules where id = new.module_id;
  if not found or m.status <> 'active' or m.sensitivity = 'protected' or m.legacy_kind is not null or not m.grant_ready then
    raise exception 'That part can''t be given to a role, group or access level (yet).';
  end if;
  if new.function_group_id is not null and m.sensitivity <> 'normal' then
    raise exception 'Sensitive parts are given to a job title or a person, never to a whole function group.';
  end if;
  if new.access_level in ('system_admin', 'new_starter', 'external') then
    raise exception 'That access level can''t hold grants.';
  end if;
  new.granted_by := auth.uid();
  new.by_system_admin := public.is_system_admin();
  new.created_at := now();
  return new;
end;
$$;
revoke execute on function public.guard_access_baseline() from public, anon, authenticated;
drop trigger if exists guard_access_baseline on public.access_baselines;
create trigger guard_access_baseline before insert or update on public.access_baselines
  for each row execute function public.guard_access_baseline();

-- The one permission check, with the inherited tiers after person grants.
create or replace function public.can(p_module text, p_action text default 'view', p_person uuid default null)
returns boolean
language plpgsql
stable
set search_path = ''
as $function$
declare
  m record;
  v_me record;
  v_effect text;
  v_groups uuid[];
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
  -- 1. Person grants (unchanged): the nearest level (this module, then its
  -- parents, then its category) decides.
  with recursive chain(id, depth) as (
    select m.id, 0
    union all
    select a.parent_id, c.depth + 1 from public.app_modules a join chain c on a.id = c.id where a.parent_id is not null
  ), levels as (
    select id, depth from chain
    union all
    select 'cat_' || m.category, 99
  )
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
       and (case when g.parent_id is null then public.is_manager_admin(g.user_id) else (gb.active and gb.role = 'manager' and public.is_manager_admin(g.granted_by)) end)
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
  if v_effect is not null then
    return v_effect = 'allow';
  end if;

  -- 2 to 4. Inherited (cmeprojects Stage 3, D-047): job title, then function
  -- groups, then access level. Only for modules switched over to can().
  if not m.grant_ready then
    return false;
  end if;
  select p.role, p.active, p.job_title_id, coalesce(t.active, false) as title_active
    into v_me
    from public.profiles p left join public.job_titles t on t.id = p.job_title_id
   where p.id = auth.uid();
  if not found or not v_me.active or v_me.role in ('new_starter', 'external') then
    return false;
  end if;
  select coalesce(array_agg(jf.function_group_id), '{}') into v_groups
    from public.job_title_functions jf join public.function_groups fg on fg.id = jf.function_group_id
   where jf.job_title_id = v_me.job_title_id and fg.active and v_me.title_active;

  with recursive chain(id, depth) as (
    select m.id, 0
    union all
    select a.parent_id, c.depth + 1 from public.app_modules a join chain c on a.id = c.id where a.parent_id is not null
  ), levels as (
    select id, depth from chain
    union all
    select 'cat_' || m.category, 99
  ), applicable as (
    select case when b.job_title_id is not null then 1 when b.function_group_id is not null then 2 else 3 end as tier,
           l.depth, b.effect, b.actions
      from public.access_baselines b
      join levels l on l.id = b.module_id
     where b.revoked_at is null
       -- Given by the system admin, or by someone who is still an active Manager Administrator.
       and (b.by_system_admin or public.is_manager_admin(b.granted_by))
       and ((b.job_title_id is not null and b.job_title_id = v_me.job_title_id and v_me.title_active)
            or (b.function_group_id is not null and b.function_group_id = any (v_groups) and m.sensitivity = 'normal')
            or (b.access_level is not null and b.access_level = v_me.role))
       and (l.depth = 0 or (m.sensitivity = 'normal' and m.added_at <= b.created_at))
       and (p_person is null or b.scope = 'all'
            or (b.scope = 'own_teams' and exists (
                  select 1 from public.team_members t2
                   where t2.user_id = p_person
                     and t2.team_id in (select tm.team_id from public.team_members tm where tm.user_id = auth.uid()
                                        union select tl.team_id from public.team_leaders tl where tl.user_id = auth.uid()))))
  ), best as (
    select * from applicable where tier = (select min(tier) from applicable)
  )
  select case
           when bool_or(a.effect = 'restrict' and (cardinality(a.actions) = 0 or p_action = any (a.actions))) then 'restrict'
           when bool_or(a.effect = 'allow' and (cardinality(a.actions) = 0 or p_action = any (a.actions))) then 'allow'
         end into v_effect
    from best a
   where a.depth = (select min(depth) from best);
  return coalesce(v_effect = 'allow', false);
end;
$function$;
