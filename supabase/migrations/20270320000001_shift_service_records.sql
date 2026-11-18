-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 134, rostering brief §7): a service record for each
-- shift: what was delivered, as the worker records it after the shift. Kept
-- apart from the timesheet (hours) and the roster (the plan).
--   * The rostered worker writes it once the shift has started, and can change
--     it for 24 hours; then it's kept as written.
--   * People who roster and people who see the client's care plans read it.
--   * An incident or issue flagged tells the managers and the client's case
--     manager straight away (and the hourly reminders catch any missed).
-- Safe to run again.

create table if not exists public.shift_service_records (
  shift_id uuid primary key references public.shifts (id) on delete restrict,
  worker_id uuid not null references public.profiles (id) on delete restrict default auth.uid(),
  delivered text not null check (length(trim(delivered)) between 1 and 4000),
  client_wellbeing text not null default 'settled' check (client_wellbeing in ('settled', 'some_concerns', 'unwell_or_distressed')),
  concern boolean not null default false,
  concern_note text not null default '' check (length(concern_note) <= 2000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  told_at timestamptz
);
alter table public.shift_service_records enable row level security;

drop policy if exists "see service records" on public.shift_service_records;
create policy "see service records" on public.shift_service_records
  for select to authenticated
  using (worker_id = (select auth.uid())
         or (select public.can('ops.roster', 'view'))
         or exists (select 1 from public.shifts s where s.id = shift_id and s.client_id is not null and public.can('clients.care_plans', 'view', s.client_id)));
drop policy if exists "workers write their service record" on public.shift_service_records;
create policy "workers write their service record" on public.shift_service_records
  for insert to authenticated
  with check (worker_id = (select auth.uid())
              and shift_id in (select s.id from public.shifts s where s.worker_id = (select auth.uid()) and s.status = 'published' and s.starts_at <= now() + interval '1 hour'));
drop policy if exists "workers change their service record" on public.shift_service_records;
create policy "workers change their service record" on public.shift_service_records
  for update to authenticated
  using (worker_id = (select auth.uid()))
  with check (worker_id = (select auth.uid()));
-- No delete rule.
grant select, insert, update on public.shift_service_records to authenticated;

create or replace function public.guard_service_record()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and new.told_at is distinct from old.told_at
     and (to_jsonb(new) - 'told_at') = (to_jsonb(old) - 'told_at') then
    return new; -- the server marking a reminder as sent
  end if;
  if tg_op = 'INSERT' then
    new.worker_id := auth.uid();
    new.created_at := now();
    new.told_at := null;
  else
    if new.worker_id is distinct from old.worker_id or new.shift_id is distinct from old.shift_id or new.created_at is distinct from old.created_at then
      raise exception 'A service record stays with its shift and worker.';
    end if;
    if old.created_at < now() - interval '24 hours' then
      raise exception 'A service record can only be changed within 24 hours. Tell the roster team if something needs correcting.';
    end if;
    -- A concern added later is told again.
    if new.concern and not old.concern then new.told_at := null; else new.told_at := old.told_at; end if;
  end if;
  new.updated_at := now();
  if not new.concern then new.concern_note := ''; end if;
  insert into public.shift_events (shift_id, actor, kind, summary, source)
  values (new.shift_id, auth.uid(), 'event',
          case when tg_op = 'INSERT' then 'recorded the service delivered' else 'updated the service record' end
          || case when new.concern then ' and flagged a concern' else '' end, 'worker');
  return new;
end;
$$;
revoke execute on function public.guard_service_record() from public, anon, authenticated;
drop trigger if exists guard_service_record on public.shift_service_records;
create trigger guard_service_record before insert or update on public.shift_service_records
  for each row execute function public.guard_service_record();

-- Concerns: the client's case manager (or the managers) are told, once.
create or replace function public.run_service_record_alerts()
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  r record;
  v int := 0;
begin
  for r in
    select q.shift_id, s.client_id, c.name, c.client_ref, coalesce(nullif(p.full_name, ''), p.email) as who, q.concern_note
      from public.shift_service_records q
      join public.shifts s on s.id = q.shift_id
      join public.profiles p on p.id = q.worker_id
      left join public.car_clients c on c.id = s.client_id
     where q.concern and q.told_at is null
  loop
    -- The managers, and the client's case manager (once each).
    perform public.notify(u, 'service_concern', r.who || ' reported an incident or issue after a shift', coalesce(r.name || ' (' || r.client_ref || '): ', '') || left(r.concern_note, 200),
                          '/roster?shift=' || r.shift_id || '&tab=service', true)
      from (select p.id as u from public.profiles p where p.active and p.role = 'manager'
            union
            select c.u from public.client_care_contacts(r.client_id) c(u) where r.client_id is not null) x;
    update public.shift_service_records set told_at = now() where shift_id = r.shift_id;
    v := v + 1;
  end loop;
  return jsonb_build_object('service_concerns', v);
end;
$$;
revoke execute on function public.run_service_record_alerts() from public, anon, authenticated;
grant execute on function public.run_service_record_alerts() to service_role;
