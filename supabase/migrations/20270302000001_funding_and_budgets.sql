-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 116; Care block C7): funding and budgets.
--
--   * New part "Funding and budgets" (sensitive). Managers: every client;
--     Case Manager: assigned clients, view only. Staff admins, Intake and team
--     staff: none by default.
--   * A budget is for one service and one period; its scheme comes from that
--     service's program. Scheme rules never cross over:
--       - NDIS budgets need plan management (NDIA-managed, plan-managed or
--         self-managed); other schemes can't have it.
--       - Support at Home budgets need the classification (1 to 8); other
--         schemes can't have it.
--   * Amounts in AUD: the total for the period and what's been used so far (as
--     at a date). This is a record for planning, not invoicing.
--   * Active, then ended (fixed after that). Nothing is deleted.

insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order, actions) values
  ('clients.funding', 'clients.list', 'clients', 'Funding and budgets', 'sensitive', true, 263, '{view,edit}')
on conflict (id) do nothing;

create table if not exists public.client_funding (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id) on delete restrict,
  service_id uuid not null references public.client_services (id) on delete restrict,
  scheme text not null default 'other' references public.client_schemes (key) on delete restrict,
  period_start date not null,
  period_end date not null,
  total_amount numeric(12,2) not null check (total_amount >= 0),
  used_amount numeric(12,2) not null default 0 check (used_amount >= 0),
  used_as_of date,
  plan_management text check (plan_management in ('ndia', 'plan', 'self')),
  classification int check (classification between 1 and 8),
  status text not null default 'active' check (status in ('active', 'ended')),
  notes text not null default '' check (length(notes) <= 1000),
  created_by uuid default auth.uid() references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_by uuid references public.profiles (id),
  updated_at timestamptz not null default now(),
  check (period_end >= period_start)
);
create index if not exists client_funding_client on public.client_funding (client_id);
alter table public.client_funding enable row level security;
drop policy if exists "see funding" on public.client_funding;
create policy "see funding" on public.client_funding
  for select to authenticated
  using (((select public.can('clients.funding'::text, 'view'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
         or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
             and public.can('clients.funding'::text, 'view'::text, client_id)));
drop policy if exists "add funding" on public.client_funding;
create policy "add funding" on public.client_funding
  for insert to authenticated
  with check (((select public.can('clients.funding'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
              or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
                  and public.can('clients.funding'::text, 'edit'::text, client_id)));
drop policy if exists "change funding" on public.client_funding;
create policy "change funding" on public.client_funding
  for update to authenticated
  using (((select public.can('clients.funding'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
         or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
             and public.can('clients.funding'::text, 'edit'::text, client_id)))
  with check (((select public.can('clients.funding'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
              or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
                  and public.can('clients.funding'::text, 'edit'::text, client_id)));
-- No delete rule.
grant select, insert, update on public.client_funding to authenticated;

create or replace function public.guard_client_funding()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_scheme text;
begin
  if tg_op = 'INSERT' then
    select p.scheme into v_scheme
      from public.client_services s join public.client_programs p on p.id = s.program_id
     where s.id = new.service_id and s.client_id = new.client_id;
    if v_scheme is null then
      raise exception 'That service belongs to another client.';
    end if;
    new.scheme := v_scheme;
    new.status := 'active';
    new.created_by := auth.uid();
    new.created_at := now();
  else
    if (new.service_id, new.scheme, new.created_by, new.created_at) is distinct from (old.service_id, old.scheme, old.created_by, old.created_at) then
      raise exception 'A budget stays with its service. Add a new budget instead.';
    end if;
    if old.status = 'ended' and new is distinct from old then
      raise exception 'This budget has ended. Add a new one instead.';
    end if;
  end if;
  -- Each scheme's own rules; never mixed.
  if new.scheme = 'ndis' then
    if new.plan_management is null then
      raise exception 'Choose how the NDIS plan is managed.';
    end if;
  elsif new.plan_management is not null then
    raise exception 'Plan management is for NDIS budgets only.';
  end if;
  if new.scheme = 'support_at_home' then
    if new.classification is null then
      raise exception 'Choose the Support at Home classification.';
    end if;
  elsif new.classification is not null then
    raise exception 'The classification is for Support at Home budgets only.';
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_client_funding() from public, anon, authenticated;
drop trigger if exists guard_client_funding on public.client_funding;
create trigger guard_client_funding before insert or update on public.client_funding
  for each row execute function public.guard_client_funding();
drop trigger if exists log_client_funding on public.client_funding;
create trigger log_client_funding before insert or update on public.client_funding
  for each row execute function public.log_client_change();

-- Switched over from the start, with defaults.
update public.app_modules set grant_ready = true where id = 'clients.funding' and not grant_ready;
do $$
declare
  v_cm uuid := (select id from public.job_titles where name = 'Case Manager' and active limit 1);
begin
  if not exists (select 1 from public.access_baselines where module_id = 'clients.funding' and revoked_at is null) then
    insert into public.access_baselines (access_level, module_id, actions, scope, note)
    values ('manager', 'clients.funding', '{}', 'all', 'Care block default: managers, every client');
    if v_cm is not null then
      insert into public.access_baselines (job_title_id, module_id, actions, scope, note)
      values (v_cm, 'clients.funding', '{view}', 'assigned', 'Care block default: case managers, assigned clients, view');
    end if;
  end if;
end $$;
