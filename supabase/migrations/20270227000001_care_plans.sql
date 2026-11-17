-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 113; Care block C4): assessments and care plans.
--
--   * New part "Care plans" (sensitive: a role or a person only). Managers:
--     every client; Case Manager: assigned clients, view and change; Intake:
--     every client, view only. Staff admins and team staff: none (D-052).
--   * A care plan starts as a draft, becomes the current plan (the old current
--     one is archived automatically), and is archived at the end. One current
--     plan per client. A plan's wording is fixed once it's current: changes are
--     a new draft, so the history stays as it was approved.
--   * Goals belong to a plan; their wording is fixed once the plan is current,
--     their progress (active, achieved, discontinued) can still be updated.
--   * Worker instructions (what staff must do on shift) are kept apart from the
--     plan so team staff can read their teams' clients' current instructions
--     without seeing the plan itself.
--   * Nothing is deleted; changes go in the change log (never the wording).

insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order, actions) values
  ('clients.care_plans', 'clients.list', 'clients', 'Care plans', 'sensitive', true, 260, '{view,edit}')
on conflict (id) do nothing;

create table if not exists public.client_care_plans (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id) on delete restrict,
  title text not null check (length(title) between 1 and 120),
  status text not null default 'draft' check (status in ('draft', 'current', 'archived')),
  assessed_on date,
  starts_on date,
  review_by date,
  summary text not null default '' check (length(summary) <= 5000),
  document_id uuid references public.client_documents (id) on delete restrict,
  created_by uuid default auth.uid() references public.profiles (id),
  created_at timestamptz not null default now(),
  made_current_by uuid references public.profiles (id),
  made_current_at timestamptz,
  archived_at timestamptz,
  updated_by uuid references public.profiles (id),
  updated_at timestamptz not null default now()
);
create unique index if not exists client_care_plans_one_current on public.client_care_plans (client_id) where status = 'current';
create index if not exists client_care_plans_client on public.client_care_plans (client_id);

create table if not exists public.client_care_goals (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  plan_id uuid not null references public.client_care_plans (id) on delete restrict,
  client_id uuid not null references public.car_clients (id) on delete restrict,
  goal text not null check (length(goal) between 1 and 500),
  measure text not null default '' check (length(measure) <= 500),
  status text not null default 'active' check (status in ('active', 'achieved', 'discontinued')),
  sort_order int not null default 0,
  updated_by uuid references public.profiles (id),
  updated_at timestamptz not null default now()
);
create index if not exists client_care_goals_plan on public.client_care_goals (plan_id);

create table if not exists public.client_worker_instructions (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id) on delete restrict,
  title text not null check (length(title) between 1 and 120),
  instructions text not null check (length(instructions) between 1 and 2000),
  active boolean not null default true,
  sort_order int not null default 0,
  updated_by uuid references public.profiles (id),
  updated_at timestamptz not null default now()
);
create index if not exists client_worker_instructions_client on public.client_worker_instructions (client_id) where active;

alter table public.client_care_plans enable row level security;
alter table public.client_care_goals enable row level security;
alter table public.client_worker_instructions enable row level security;

-- Plans and goals: Care plans, for that client.
drop policy if exists "see care plans" on public.client_care_plans;
create policy "see care plans" on public.client_care_plans
  for select to authenticated
  using (((select public.can('clients.care_plans'::text, 'view'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
         or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
             and public.can('clients.care_plans'::text, 'view'::text, client_id)));
drop policy if exists "add care plans" on public.client_care_plans;
create policy "add care plans" on public.client_care_plans
  for insert to authenticated
  with check (((select public.can('clients.care_plans'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
              or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
                  and public.can('clients.care_plans'::text, 'edit'::text, client_id)));
drop policy if exists "change care plans" on public.client_care_plans;
create policy "change care plans" on public.client_care_plans
  for update to authenticated
  using (((select public.can('clients.care_plans'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
         or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
             and public.can('clients.care_plans'::text, 'edit'::text, client_id)))
  with check (((select public.can('clients.care_plans'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
              or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
                  and public.can('clients.care_plans'::text, 'edit'::text, client_id)));

drop policy if exists "see care goals" on public.client_care_goals;
create policy "see care goals" on public.client_care_goals
  for select to authenticated
  using (((select public.can('clients.care_plans'::text, 'view'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
         or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
             and public.can('clients.care_plans'::text, 'view'::text, client_id)));
drop policy if exists "add care goals" on public.client_care_goals;
create policy "add care goals" on public.client_care_goals
  for insert to authenticated
  with check (((select public.can('clients.care_plans'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
              or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
                  and public.can('clients.care_plans'::text, 'edit'::text, client_id)));
drop policy if exists "change care goals" on public.client_care_goals;
create policy "change care goals" on public.client_care_goals
  for update to authenticated
  using (((select public.can('clients.care_plans'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
         or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
             and public.can('clients.care_plans'::text, 'edit'::text, client_id)))
  with check (((select public.can('clients.care_plans'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
              or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
                  and public.can('clients.care_plans'::text, 'edit'::text, client_id)));

-- Worker instructions: Care plans holders; team staff read their teams'
-- clients' current ones.
drop policy if exists "see worker instructions" on public.client_worker_instructions;
create policy "see worker instructions" on public.client_worker_instructions
  for select to authenticated
  using (((select public.can('clients.care_plans'::text, 'view'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
         or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
             and public.can('clients.care_plans'::text, 'view'::text, client_id))
         or (active and (select public.is_member())
             and client_id in (select ct.client_id from public.client_teams ct
                                where ct.team_id in (select tm.team_id from public.team_members tm where tm.user_id = (select auth.uid())
                                                     union select tl.team_id from public.team_leaders tl where tl.user_id = (select auth.uid())))));
drop policy if exists "add worker instructions" on public.client_worker_instructions;
create policy "add worker instructions" on public.client_worker_instructions
  for insert to authenticated
  with check (((select public.can('clients.care_plans'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
              or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
                  and public.can('clients.care_plans'::text, 'edit'::text, client_id)));
drop policy if exists "change worker instructions" on public.client_worker_instructions;
create policy "change worker instructions" on public.client_worker_instructions
  for update to authenticated
  using (((select public.can('clients.care_plans'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
         or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
             and public.can('clients.care_plans'::text, 'edit'::text, client_id)))
  with check (((select public.can('clients.care_plans'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
              or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
                  and public.can('clients.care_plans'::text, 'edit'::text, client_id)));
-- No delete rules.
grant select, insert, update on public.client_care_plans, public.client_care_goals, public.client_worker_instructions to authenticated;

-- A plan: draft, then current (the old current one is archived), then archived.
create or replace function public.guard_care_plan()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.document_id is not null and not exists (select 1 from public.client_documents d where d.id = new.document_id and d.client_id = new.client_id) then
    raise exception 'That document belongs to another client.';
  end if;
  if tg_op = 'INSERT' then
    new.status := 'draft';
    new.created_by := auth.uid();
    new.created_at := now();
    new.made_current_by := null;
    new.made_current_at := null;
    new.archived_at := null;
    return new;
  end if;
  if new.created_by is distinct from old.created_by or new.created_at is distinct from old.created_at then
    raise exception 'Who added a plan, and when, isn''t changed.';
  end if;
  if old.status = 'archived' and (new is distinct from old) then
    raise exception 'An archived plan isn''t changed. Start a new draft instead.';
  end if;
  if old.status = 'current' and new.status = 'draft' then
    raise exception 'A current plan can''t go back to draft. Start a new draft instead.';
  end if;
  if old.status <> 'draft' and (new.title, new.assessed_on, new.starts_on, new.review_by, new.summary, new.document_id)
       is distinct from (old.title, old.assessed_on, old.starts_on, old.review_by, old.summary, old.document_id) then
    raise exception 'A current plan''s wording is fixed. Start a new draft to change it.';
  end if;
  if new.status = 'current' and old.status = 'draft' then
    update public.client_care_plans set status = 'archived' where client_id = new.client_id and status = 'current' and id <> new.id;
    new.made_current_by := auth.uid();
    new.made_current_at := now();
  else
    new.made_current_by := old.made_current_by;
    new.made_current_at := old.made_current_at;
  end if;
  if new.status = 'archived' and old.status <> 'archived' then
    new.archived_at := now();
  else
    new.archived_at := old.archived_at;
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_care_plan() from public, anon, authenticated;
drop trigger if exists guard_care_plan on public.client_care_plans;
create trigger guard_care_plan before insert or update on public.client_care_plans
  for each row execute function public.guard_care_plan();
drop trigger if exists log_client_care_plans on public.client_care_plans;
create trigger log_client_care_plans before insert or update on public.client_care_plans
  for each row execute function public.log_client_change();

-- A goal: same client as its plan; wording fixed once the plan is current;
-- nothing changes on an archived plan.
create or replace function public.guard_care_goal()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_status text;
begin
  select p.status into v_status from public.client_care_plans p where p.id = new.plan_id and p.client_id = new.client_id;
  if v_status is null then
    raise exception 'That plan belongs to another client.';
  end if;
  if v_status = 'archived' then
    raise exception 'That plan is archived. Goals on it aren''t changed.';
  end if;
  if tg_op = 'INSERT' then
    if v_status <> 'draft' then
      raise exception 'Goals are added while the plan is a draft.';
    end if;
    return new;
  end if;
  if new.plan_id is distinct from old.plan_id then
    raise exception 'A goal stays with its plan.';
  end if;
  if v_status <> 'draft' and (new.goal, new.measure) is distinct from (old.goal, old.measure) then
    raise exception 'A current plan''s goals are fixed. Update their progress, or start a new draft.';
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_care_goal() from public, anon, authenticated;
drop trigger if exists guard_care_goal on public.client_care_goals;
create trigger guard_care_goal before insert or update on public.client_care_goals
  for each row execute function public.guard_care_goal();
drop trigger if exists log_client_care_goals on public.client_care_goals;
create trigger log_client_care_goals before insert or update on public.client_care_goals
  for each row execute function public.log_client_change();
drop trigger if exists log_client_worker_instructions on public.client_worker_instructions;
create trigger log_client_worker_instructions before insert or update on public.client_worker_instructions
  for each row execute function public.log_client_change();

-- Switched over from the start, with defaults.
update public.app_modules set grant_ready = true where id = 'clients.care_plans' and not grant_ready;
do $$
declare
  v_cm uuid := (select id from public.job_titles where name = 'Case Manager' and active limit 1);
  v_io uuid := (select id from public.job_titles where name = 'Intake & Assessment Officer' and active limit 1);
begin
  if not exists (select 1 from public.access_baselines where module_id = 'clients.care_plans' and revoked_at is null) then
    insert into public.access_baselines (access_level, module_id, actions, scope, note)
    values ('manager', 'clients.care_plans', '{}', 'all', 'Care block default: managers, every client');
    if v_cm is not null then
      insert into public.access_baselines (job_title_id, module_id, actions, scope, note)
      values (v_cm, 'clients.care_plans', '{view,edit}', 'assigned', 'Care block default: case managers, assigned clients');
    end if;
    if v_io is not null then
      insert into public.access_baselines (job_title_id, module_id, actions, scope, note)
      values (v_io, 'clients.care_plans', '{view}', 'all', 'Care block default: intake, every client, view');
    end if;
  end if;
end $$;
