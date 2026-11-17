-- Staff Portal · © cmeproject. All rights reserved.
-- Update 106: client assignments and "assigned clients only" in the permission check
-- (Stage 5c). Nobody's access changes.
-- Safe to run again. Undo: undo-106.sql. Run update 105 first.
begin;
-- cmeprojects (update 106; function-based access, Stage 5c; owner approved
-- the Stage 5 recommendations): client assignments, and "assigned clients
-- only" in the permission check.
--
--   * client_assignments: which staff member is assigned to which client, as
--     what (case manager, intake, key worker, other), from and to which date.
--     Never deleted: ending an assignment records when and by whom. Access
--     stops the moment an assignment ends.
--   * An assignment gives nothing by itself: the person also needs a grant
--     for that part of Clients. A grant can be limited to "assigned clients
--     only" (new scope) or "their own teams' clients".
--   * Who may assign: whoever has Assigning staff (edit) for that client.
--     Nobody assigns a client to themselves (the system admin aside).
--   * Nobody's access changes in this update (Clients still uses the
--     built-in rule until update 107).

create table if not exists public.client_assignments (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id) on delete restrict,
  user_id uuid not null references public.profiles (id) on delete restrict,
  assigned_as text not null default 'case_manager' check (assigned_as in ('case_manager', 'intake', 'key_worker', 'other')),
  starts_on date not null default public.local_today(),
  ends_on date,
  note text not null default '' check (length(note) <= 300),
  assigned_by uuid default auth.uid() references public.profiles (id),
  created_at timestamptz not null default now(),
  ended_at timestamptz,
  ended_by uuid references public.profiles (id),
  constraint client_assignments_dates check (ends_on is null or ends_on >= starts_on)
);
create index if not exists client_assignments_user on public.client_assignments (user_id) where ended_at is null;
create index if not exists client_assignments_client on public.client_assignments (client_id);
alter table public.client_assignments enable row level security;

drop policy if exists "people see their own assignments, assigners see the client's" on public.client_assignments;
create policy "people see their own assignments, assigners see the client's" on public.client_assignments
  for select to authenticated
  using (user_id = (select auth.uid()) or public.can('clients.assign', 'view', client_id));
drop policy if exists "assigners assign staff" on public.client_assignments;
create policy "assigners assign staff" on public.client_assignments
  for insert to authenticated
  with check (public.can('clients.assign', 'edit', client_id));
drop policy if exists "assigners end assignments" on public.client_assignments;
create policy "assigners end assignments" on public.client_assignments
  for update to authenticated
  using (public.can('clients.assign', 'edit', client_id))
  with check (public.can('clients.assign', 'edit', client_id));
-- No delete rule: ended, never deleted.
grant select, insert, update on public.client_assignments to authenticated;

create or replace function public.guard_client_assignment()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' then
    if new.client_id is distinct from old.client_id or new.user_id is distinct from old.user_id
       or new.assigned_as is distinct from old.assigned_as or new.starts_on is distinct from old.starts_on
       or new.assigned_by is distinct from old.assigned_by or new.created_at is distinct from old.created_at then
      raise exception 'An assignment isn''t changed: end it and assign again.';
    end if;
    if old.ended_at is not null then
      raise exception 'That assignment has already ended.';
    end if;
    if new.ended_at is not null then
      new.ended_at := now();
      new.ended_by := auth.uid();
      if new.ends_on is null or new.ends_on > public.local_today() then
        new.ends_on := greatest(new.starts_on, public.local_today());
      end if;
    end if;
    return new;
  end if;
  if new.user_id = auth.uid() and not public.is_system_admin() then
    raise exception 'You can''t assign a client to yourself. Ask someone who assigns clients.';
  end if;
  if not exists (select 1 from public.profiles p where p.id = new.user_id and p.active and p.role <> 'new_starter') then
    raise exception 'Choose an active staff member (not a new starter).';
  end if;
  new.assigned_by := auth.uid();
  new.created_at := now();
  new.ended_at := null;
  new.ended_by := null;
  return new;
end;
$$;
revoke execute on function public.guard_client_assignment() from public, anon, authenticated;
drop trigger if exists guard_client_assignment on public.client_assignments;
create trigger guard_client_assignment before insert or update on public.client_assignments
  for each row execute function public.guard_client_assignment();

-- New scope for role, group and access-level grants.
alter table public.access_baselines drop constraint if exists access_baselines_scope_check;
alter table public.access_baselines add constraint access_baselines_scope_check check (scope in ('all', 'own_teams', 'assigned'));

CREATE OR REPLACE FUNCTION public.guard_access_baseline()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
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
  -- cmeprojects (update 106): "assigned clients only" is for client parts
  -- (not Assigning staff itself, which the check reads to decide it).
  if new.scope = 'assigned' and (m.category <> 'clients' or m.id = 'clients.assign') then
    raise exception 'Assigned clients only is for the parts of Clients.';
  end if;
  if new.access_level in ('system_admin', 'new_starter', 'external') then
    raise exception 'That access level can''t hold grants.';
  end if;
  new.granted_by := auth.uid();
  new.by_system_admin := public.is_system_admin() or auth.uid() is null;
  new.created_at := now();
  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.can(p_module text, p_action text DEFAULT 'view'::text, p_person uuid DEFAULT NULL::uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
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
                                        union select tl.team_id from public.team_leaders tl where tl.user_id = auth.uid())))
            -- cmeprojects (update 106): for client parts the person is the client.
            or (b.scope = 'own_teams' and m.category = 'clients' and exists (
                  select 1 from public.client_teams ct
                   where ct.client_id = p_person
                     and ct.team_id in (select tm.team_id from public.team_members tm where tm.user_id = auth.uid()
                                        union select tl.team_id from public.team_leaders tl where tl.user_id = auth.uid())))
            or (b.scope = 'assigned' and m.category = 'clients' and m.id <> 'clients.assign' and exists (
                  select 1 from public.client_assignments a
                   where a.client_id = p_person and a.user_id = auth.uid() and a.ended_at is null
                     and a.starts_on <= public.local_today() and (a.ends_on is null or a.ends_on >= public.local_today()))))
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
commit;
