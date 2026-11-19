-- Staff Portal · © cmeproject. All rights reserved.
-- Update 147: the client communication log.
-- Safe to run again. Undo: undo-147.sql.
begin;
create table if not exists public.client_communications (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id) on delete cascade,
  happened_at timestamptz not null default now(),
  method text not null check (method in ('phone', 'sms', 'email', 'meeting', 'video', 'letter', 'other')),
  direction text not null default 'out' check (direction in ('in', 'out')),
  with_whom text not null default '' check (length(with_whom) <= 120),
  summary text not null check (length(trim(summary)) between 1 and 2000),
  follow_up text not null default '' check (length(follow_up) <= 500),
  follow_up_by date,
  follow_up_done_at timestamptz,
  follow_up_done_by uuid,
  author_id uuid not null default auth.uid() references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists client_communications_client on public.client_communications (client_id, happened_at desc);
alter table public.client_communications enable row level security;
drop policy if exists "read the communication log" on public.client_communications;
create policy "read the communication log" on public.client_communications
  for select to authenticated
  using (public.can('clients.comms', 'edit', client_id) or public.can('clients.care_plans', 'view', client_id));
drop policy if exists "write the communication log" on public.client_communications;
create policy "write the communication log" on public.client_communications
  for insert to authenticated
  with check (author_id = (select auth.uid()) and public.can('clients.comms', 'edit', client_id));
drop policy if exists "correct or follow up the communication log" on public.client_communications;
create policy "correct or follow up the communication log" on public.client_communications
  for update to authenticated
  using (public.can('clients.comms', 'edit', client_id))
  with check (public.can('clients.comms', 'edit', client_id));
-- No delete.
grant select, insert, update on public.client_communications to authenticated;
revoke all on public.client_communications from anon;

create or replace function public.guard_client_communication() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    new.author_id := auth.uid();
    new.created_at := now();
    new.follow_up_done_at := null;
    new.follow_up_done_by := null;
    if new.happened_at > now() + interval '1 hour' then
      raise exception 'A communication can''t be in the future.';
    end if;
  else
    if new.client_id <> old.client_id or new.author_id <> old.author_id or new.created_at <> old.created_at then
      raise exception 'A log entry stays with its client and author.';
    end if;
    -- Marking a follow-up done (or undone) is open to anyone who can write; anything else is a correction.
    if (new.happened_at, new.method, new.direction, new.with_whom, new.summary, new.follow_up, new.follow_up_by)
       is distinct from (old.happened_at, old.method, old.direction, old.with_whom, old.summary, old.follow_up, old.follow_up_by) then
      if old.author_id <> auth.uid() then
        raise exception 'Only the person who wrote it can correct a log entry.';
      end if;
      if old.created_at < now() - interval '24 hours' then
        raise exception 'A log entry can only be corrected within 24 hours. Add a new entry instead.';
      end if;
    end if;
    if new.follow_up_done_at is distinct from old.follow_up_done_at then
      new.follow_up_done_at := case when new.follow_up_done_at is null then null else now() end;
      new.follow_up_done_by := case when new.follow_up_done_at is null then null else auth.uid() end;
    end if;
  end if;
  new.updated_at := now();
  return new;
end;
$$;
revoke execute on function public.guard_client_communication() from public, anon, authenticated;
drop trigger if exists guard_client_communication on public.client_communications;
create trigger guard_client_communication before insert or update on public.client_communications
  for each row execute function public.guard_client_communication();
commit;
