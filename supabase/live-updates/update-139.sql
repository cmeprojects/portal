-- Staff Portal · © cmeproject. All rights reserved.
-- Update 139: who reads shift notes (privacy review SEC-003).
-- Safe to run again. Undo: undo-139.sql.
begin;
-- Shift notes keep the client they're about (filled in from the shift).
alter table public.shift_service_records add column if not exists client_id uuid references public.car_clients (id) on delete set null;
update public.shift_service_records r set client_id = s.client_id from public.shifts s where s.id = r.shift_id and r.client_id is null and s.client_id is not null;
create index if not exists shift_service_records_client on public.shift_service_records (client_id, created_at desc);

drop policy if exists "see service records" on public.shift_service_records;
create policy "see service records" on public.shift_service_records
  for select to authenticated
  using (worker_id = (select auth.uid())
         or (client_id is not null and public.can('clients.care_plans', 'view', client_id))
         -- A shift with no client (office work, training) holds no care information.
         or (client_id is null and (select public.can('ops.roster', 'view'))));

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
    -- cmeprojects (update 139): the client is kept on the notes, so who may read them follows the client.
    new.client_id := (select s.client_id from public.shifts s where s.id = new.shift_id);
    new.created_at := now();
    new.told_at := null;
  else
    new.client_id := old.client_id;
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
-- Incident alerts no longer put the incident text in the notice or email.
CREATE OR REPLACE FUNCTION public.run_service_record_alerts()
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  r record;
  v int := 0;
begin
  for r in
    select q.shift_id, s.client_id, c.name, c.client_ref, coalesce(nullif(p.full_name, ''), p.email) as who
      from public.shift_service_records q
      join public.shifts s on s.id = q.shift_id
      join public.profiles p on p.id = q.worker_id
      left join public.car_clients c on c.id = s.client_id
     where q.concern and q.told_at is null
  loop
    -- The managers, and the client's case manager (once each). Notices are also
    -- emailed, so they name the client but never carry the incident itself:
    -- that's read in the portal (cmeprojects, update 139).
    perform public.notify(u, 'service_concern', r.who || ' reported an incident or issue after a shift',
                          coalesce(r.name || ' (' || r.client_ref || '). ', '') || 'Open the portal to read it.',
                          case when r.client_id is not null then '/settings/clients/' || r.client_id || '?tab=shifts' else '/roster?shift=' || r.shift_id || '&tab=service' end, true)
      from (select p.id as u from public.profiles p where p.active and p.role = 'manager'
            union
            select c.u from public.client_care_contacts(r.client_id) c(u) where r.client_id is not null) x;
    update public.shift_service_records set told_at = now() where shift_id = r.shift_id;
    v := v + 1;
  end loop;
  return jsonb_build_object('service_concerns', v);
end;
$function$;
commit;
