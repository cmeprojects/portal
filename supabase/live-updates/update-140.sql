-- Staff Portal · © cmeproject. All rights reserved.
-- Update 140: the owner's privacy decisions (SEC-003 §4).
-- Safe to run again. Undo: undo-140.sql.
begin;
-- 1 and 2: restrictions on the Payroll Officer job title (a restriction wins).
do $$
declare
  v_id uuid := (select id from public.job_titles where name = 'Payroll Officer');
begin
  if v_id is null then return; end if;
  insert into public.access_baselines (job_title_id, module_id, effect, actions, scope, note, by_system_admin)
  select v_id, x.m, 'restrict', '{}', 'all', 'Privacy decision 18 Nov 2026: Payroll Officer', true
    from (values ('clients.comms'), ('clients.assign')) as x(m)
   where not exists (select 1 from public.access_baselines b where b.job_title_id = v_id and b.module_id = x.m and b.revoked_at is null);
end $$;

-- 6: Payroll details (view only).
insert into public.app_modules (id, category, label, sensitivity, delegable, sort_order, actions, grant_ready)
values ('hr.payroll_view', 'hr', 'Payroll details (view only)', 'sensitive', true, 1035, '{view}', true)
on conflict (id) do nothing;
update public.app_modules set status = 'active' where id = 'hr.payroll_view' and status = 'retired'; -- run again after an undo
insert into public.function_group_modules (function_group_id, module_id)
select g.id, 'hr.payroll_view' from public.function_groups g where g.key = 'finance_accounts'
on conflict do nothing;
do $$
declare
  v_id uuid := (select id from public.job_titles where name = 'Payroll Officer');
begin
  if v_id is not null and not exists (select 1 from public.access_baselines where job_title_id = v_id and module_id = 'hr.payroll_view' and revoked_at is null) then
    insert into public.access_baselines (job_title_id, module_id, actions, scope, note, by_system_admin)
    values (v_id, 'hr.payroll_view', '{view}', 'all', 'Privacy decision 18 Nov 2026: Payroll Officer', true);
  end if;
end $$;
drop policy if exists "payroll view: read bank details" on public.staff_bank;
create policy "payroll view: read bank details" on public.staff_bank
  for select to authenticated using ((select public.can('hr.payroll_view', 'view')));
drop policy if exists "payroll view: read super details" on public.staff_super;
create policy "payroll view: read super details" on public.staff_super
  for select to authenticated using ((select public.can('hr.payroll_view', 'view')));

-- 3: who opened a client's page.
create table if not exists public.client_staff_views (
  id bigint generated always as identity primary key,
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id) on delete cascade,
  user_id uuid not null default auth.uid() references public.profiles (id),
  viewed_at timestamptz not null default now()
);
create index if not exists client_staff_views_client on public.client_staff_views (client_id, viewed_at desc);
alter table public.client_staff_views enable row level security;
drop policy if exists "staff record their own opening" on public.client_staff_views;
create policy "staff record their own opening" on public.client_staff_views
  for insert to authenticated
  with check (user_id = (select auth.uid()) and public.can('clients.list', 'view', client_id));
drop policy if exists "people who assign staff read who opened" on public.client_staff_views;
create policy "people who assign staff read who opened" on public.client_staff_views
  for select to authenticated
  using (user_id = (select auth.uid()) or public.can('clients.assign', 'edit', client_id));
-- No change or delete: the log stays as recorded.
grant select, insert on public.client_staff_views to authenticated;
revoke all on public.client_staff_views from anon;
commit;
