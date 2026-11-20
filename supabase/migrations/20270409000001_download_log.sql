-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 154): a trail of who downloaded what. Exports (client and
-- staff lists, registers, reports, rosters, timesheets, form replies, leave),
-- documents (client documents, compliance files, task attachments) and staff
-- records (contracts, tax forms, records) are recorded: who, what, when, and the
-- client or staff member it was about. A document download is recorded as
-- "download link issued" (a link isn't proof the file arrived); refused
-- attempts are recorded as denied. Seen by the system admin and Manager
-- Administrators (Portal settings, Downloads); people who assign staff to a
-- client see that client's downloads. Entries can't be changed or deleted.
-- No new security definer function. Safe to run again.

create table if not exists public.download_log (
  id bigint generated always as identity primary key,
  org_id uuid not null default public.default_org_id(),
  user_id uuid not null default auth.uid() references public.profiles (id),
  kind text not null check (kind in ('export', 'document', 'record')),
  -- A link handed over is not proof the file arrived, so it is called that.
  action text not null default 'download_link_issued' check (action in ('export', 'download_link_issued', 'download_denied')),
  outcome text not null default 'success' check (outcome in ('success', 'denied', 'failed')),
  label text not null check (length(trim(label)) between 1 and 300),
  client_id uuid references public.car_clients (id),
  person_id uuid references public.profiles (id),
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists download_log_when on public.download_log (created_at desc);
create index if not exists download_log_client on public.download_log (client_id, created_at desc) where client_id is not null;
create index if not exists download_log_user on public.download_log (user_id, created_at desc);

alter table public.download_log enable row level security;
drop policy if exists "record my downloads" on public.download_log;
create policy "record my downloads" on public.download_log
  for insert to authenticated with check (user_id = (select auth.uid()));
drop policy if exists "read downloads" on public.download_log;
create policy "read downloads" on public.download_log
  for select to authenticated
  using ((select public.is_system_admin()) or (select public.is_manager_admin())
         or (client_id is not null and public.can('clients.assign', 'edit', client_id)));
-- No update or delete: the trail stays as it was written.
grant select, insert on public.download_log to authenticated;
revoke all on public.download_log from anon;

create or replace function public.guard_download_log() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.user_id := auth.uid();
  new.created_at := now();
  return new;
end;
$$;
revoke execute on function public.guard_download_log() from public, anon, authenticated;
drop trigger if exists guard_download_log on public.download_log;
create trigger guard_download_log before insert on public.download_log
  for each row execute function public.guard_download_log();

-- The Downloads section in Portal settings.
insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order)
values ('system.downloads', 'system.settings', 'system', 'Downloads', 'normal', false, 1127)
on conflict (id) do nothing;
update public.app_modules set status = 'active' where id = 'system.downloads' and status = 'retired'; -- run again after an undo
