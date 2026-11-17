-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 119; HR block step 1, owner's order): offboarding.
--
--   * New part "Offboarding" (HR). Managers and staff admins by default (the
--     same people who manage staff); changeable on the Access page.
--   * Starting offboarding records why they're leaving and their last day,
--     and makes a checklist: car keys and fuel card, equipment and ID badge,
--     client keys and key safe codes, exit interview, final pay to payroll,
--     deactivate the portal account, and reassign their open tasks and
--     clients. Steps are ticked (or marked not needed); who and when are kept.
--   * The "deactivate" step ticks itself when their account is deactivated.
--   * Exit interview notes stay with the people who manage offboarding (the
--     person leaving doesn't see the record). Nothing is deleted.

insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order, actions) values
  ('hr.offboarding', null, 'hr', 'Offboarding', 'normal', true, 245, '{view,edit}')
on conflict (id) do nothing;

create table if not exists public.offboardings (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  user_id uuid not null references public.profiles (id) on delete restrict,
  reason text not null check (reason in ('resigned', 'contract_ended', 'dismissed', 'retired', 'redundancy', 'other')),
  last_day date not null,
  note text not null default '' check (length(note) <= 1000),
  exit_notes text not null default '' check (length(exit_notes) <= 3000),
  status text not null default 'open' check (status in ('open', 'completed', 'cancelled')),
  started_by uuid default auth.uid() references public.profiles (id),
  started_at timestamptz not null default now(),
  closed_by uuid references public.profiles (id),
  closed_at timestamptz,
  updated_at timestamptz not null default now()
);
create unique index if not exists offboardings_one_open on public.offboardings (user_id) where status = 'open';

create table if not exists public.offboarding_steps (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  offboarding_id uuid not null references public.offboardings (id) on delete restrict,
  step text not null,
  title text not null check (length(title) between 1 and 120),
  sort_order int not null default 0,
  state text not null default 'todo' check (state in ('todo', 'done', 'not_needed')),
  done_by uuid references public.profiles (id),
  done_at timestamptz,
  unique (offboarding_id, step)
);

alter table public.offboardings enable row level security;
alter table public.offboarding_steps enable row level security;

drop policy if exists "see offboarding" on public.offboardings;
create policy "see offboarding" on public.offboardings
  for select to authenticated using (user_id <> (select auth.uid()) and public.can('hr.offboarding', 'view', user_id));
drop policy if exists "start offboarding" on public.offboardings;
create policy "start offboarding" on public.offboardings
  for insert to authenticated with check (user_id <> (select auth.uid()) and public.can('hr.offboarding', 'edit', user_id));
drop policy if exists "change offboarding" on public.offboardings;
create policy "change offboarding" on public.offboardings
  for update to authenticated
  using (user_id <> (select auth.uid()) and public.can('hr.offboarding', 'edit', user_id))
  with check (user_id <> (select auth.uid()) and public.can('hr.offboarding', 'edit', user_id));

drop policy if exists "see offboarding steps" on public.offboarding_steps;
create policy "see offboarding steps" on public.offboarding_steps
  for select to authenticated using (offboarding_id in (select o.id from public.offboardings o));
drop policy if exists "tick offboarding steps" on public.offboarding_steps;
create policy "tick offboarding steps" on public.offboarding_steps
  for update to authenticated
  using (offboarding_id in (select o.id from public.offboardings o where o.status = 'open' and public.can('hr.offboarding', 'edit', o.user_id)))
  with check (offboarding_id in (select o.id from public.offboardings o where o.status = 'open' and public.can('hr.offboarding', 'edit', o.user_id)));
drop policy if exists "add offboarding steps" on public.offboarding_steps;
create policy "add offboarding steps" on public.offboarding_steps
  for insert to authenticated
  with check (offboarding_id in (select o.id from public.offboardings o where o.status = 'open' and public.can('hr.offboarding', 'edit', o.user_id)));
-- No delete rules.
grant select, insert, update on public.offboardings, public.offboarding_steps to authenticated;

-- Offboarding: who started and closed it; a closed one stays as it was; the
-- standard checklist is added when it starts.
create or replace function public.guard_offboarding()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.status := 'open';
    new.started_by := auth.uid();
    new.started_at := now();
    new.closed_by := null;
    new.closed_at := null;
    return new;
  end if;
  if (new.user_id, new.started_by, new.started_at) is distinct from (old.user_id, old.started_by, old.started_at) then
    raise exception 'Who is leaving, and who started it, stay as they were.';
  end if;
  if old.status <> 'open' and new is distinct from old then
    raise exception 'This offboarding is closed. Start a new one if needed.';
  end if;
  if new.status <> 'open' and old.status = 'open' then
    new.closed_by := auth.uid();
    new.closed_at := now();
  end if;
  new.updated_at := now();
  return new;
end;
$$;
revoke execute on function public.guard_offboarding() from public, anon, authenticated;
drop trigger if exists guard_offboarding on public.offboardings;
create trigger guard_offboarding before insert or update on public.offboardings
  for each row execute function public.guard_offboarding();

create or replace function public.add_offboarding_steps()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  insert into public.offboarding_steps (offboarding_id, step, title, sort_order) values
    (new.id, 'car', 'Car keys and fuel card returned', 10),
    (new.id, 'equipment', 'Phone, laptop, ID badge and uniform returned', 20),
    (new.id, 'client_keys', 'Client keys returned; key safe codes changed', 30),
    (new.id, 'reassign', 'Open tasks and clients handed to someone else', 40),
    (new.id, 'exit_interview', 'Exit interview done', 50),
    (new.id, 'final_pay', 'Final pay and leave payout sent to payroll', 60),
    (new.id, 'deactivate', 'Portal account deactivated', 70)
  on conflict (offboarding_id, step) do nothing;
  return null;
end;
$$;
revoke execute on function public.add_offboarding_steps() from public, anon, authenticated;
drop trigger if exists add_offboarding_steps on public.offboardings;
create trigger add_offboarding_steps after insert on public.offboardings
  for each row execute function public.add_offboarding_steps();

-- A step: who ticked it and when; added steps are "other" ones.
create or replace function public.guard_offboarding_step()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and (new.offboarding_id, new.step, new.title) is distinct from (old.offboarding_id, old.step, old.title) then
    raise exception 'A step''s wording stays as it was.';
  end if;
  -- Steps added by hand (not the standard checklist) are kept as "other" ones.
  if tg_op = 'INSERT' and pg_trigger_depth() <= 1 then
    new.step := 'other_' || substr(md5(random()::text), 1, 8);
  end if;
  if new.state <> 'todo' and (tg_op = 'INSERT' or old.state is distinct from new.state) then
    new.done_by := auth.uid();
    new.done_at := now();
  elsif new.state = 'todo' then
    new.done_by := null;
    new.done_at := null;
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_offboarding_step() from public, anon, authenticated;
drop trigger if exists guard_offboarding_step on public.offboarding_steps;
create trigger guard_offboarding_step before insert or update on public.offboarding_steps
  for each row execute function public.guard_offboarding_step();

-- "Portal account deactivated" ticks itself when they're deactivated.
create or replace function public.offboarding_on_deactivate()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if old.active and not new.active then
    update public.offboarding_steps s set state = 'done'
     where s.step = 'deactivate' and s.state = 'todo'
       and s.offboarding_id in (select o.id from public.offboardings o where o.user_id = new.id and o.status = 'open');
  end if;
  return null;
end;
$$;
revoke execute on function public.offboarding_on_deactivate() from public, anon, authenticated;
drop trigger if exists offboarding_on_deactivate on public.profiles;
create trigger offboarding_on_deactivate after update of active on public.profiles
  for each row execute function public.offboarding_on_deactivate();

-- Switched over from the start: the people who manage staff.
update public.app_modules set grant_ready = true where id = 'hr.offboarding' and not grant_ready;
insert into public.access_baselines (access_level, module_id, actions, scope, note)
select l::public.app_role, 'hr.offboarding', '{}', 'all', 'HR block default: people who manage staff'
  from unnest(array['manager', 'staff_admin']) l
 where not exists (select 1 from public.access_baselines b where b.module_id = 'hr.offboarding' and b.revoked_at is null and b.access_level = l::public.app_role);

-- Catalogue: Offboarding sits with the other HR parts (a mapping only; it gives nobody access).
insert into public.function_group_modules (function_group_id, module_id)
select g.id, 'hr.offboarding' from public.function_groups g where g.key in ('hr_workforce', 'management_admin')
on conflict do nothing;
