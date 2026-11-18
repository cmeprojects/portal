-- Staff Portal · © cmeproject. All rights reserved.
-- Update 141: the redesigned shift panel (shift types, notify worker, pay class, notes, signatures).
-- Safe to run again. Undo: undo-141.sql.
begin;
create table if not exists public.shift_types (
  key text primary key check (key ~ '^[a-z][a-z0-9_]{1,40}$'),
  org_id uuid not null default public.default_org_id(),
  label text not null check (length(trim(label)) between 1 and 60),
  active boolean not null default true,
  sort_order int not null default 100,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.shift_types enable row level security;
drop policy if exists "members read shift types" on public.shift_types;
create policy "members read shift types" on public.shift_types
  for select to authenticated using ((select public.is_member()));
drop policy if exists "manager administrators add shift types" on public.shift_types;
create policy "manager administrators add shift types" on public.shift_types
  for insert to authenticated with check ((select public.is_system_admin()) or (select public.is_manager_admin()));
drop policy if exists "manager administrators change shift types" on public.shift_types;
create policy "manager administrators change shift types" on public.shift_types
  for update to authenticated using ((select public.is_system_admin()) or (select public.is_manager_admin()))
  with check ((select public.is_system_admin()) or (select public.is_manager_admin()));
-- No delete: a type in use is switched off instead.
grant select, insert, update on public.shift_types to authenticated;
revoke all on public.shift_types from anon;

insert into public.shift_types (key, label, sort_order) values
  ('community_access', 'Community access', 10),
  ('domestic', 'Domestic assistance', 20),
  ('employment_assistance', 'Employment assistance', 30),
  ('therapy_session', 'Therapy session', 40),
  ('gardening', 'Gardening', 50),
  ('group_activity', 'Group activity', 60),
  ('group_employment_coaching', 'Group employment coaching', 70),
  ('massage_therapy', 'Massage therapy', 80),
  ('overnight', 'Night shift', 90),
  ('admin', 'Office work', 100),
  ('on_call', 'On call', 110),
  ('on_the_job_assistance', 'On the job assistance', 120),
  ('personal_care', 'Personal care', 130),
  ('remedial_massage', 'Remedial massage', 140),
  ('remote_work', 'Remote work', 150),
  ('respite_care', 'Respite care', 160),
  ('sleepover', 'Sleepover', 170),
  ('social_activities', 'Social activities', 180),
  ('support_coordination', 'Support coordination', 190),
  ('standard', 'Standard', 200),
  ('training', 'Training', 210),
  ('meeting', 'Meeting', 220),
  ('other', 'Other', 230)
on conflict (key) do nothing;

alter table public.shifts drop constraint if exists shifts_shift_type_check;
alter table public.shifts drop constraint if exists shifts_shift_type_fkey;
alter table public.shifts add constraint shifts_shift_type_fkey foreign key (shift_type) references public.shift_types (key);
-- Templates keep a type from the same list (any type not in it becomes Standard).
update public.shift_templates set shift_type = 'standard' where shift_type is not null and shift_type not in (select key from public.shift_types);
alter table public.shift_templates drop constraint if exists shift_templates_shift_type_fkey;
alter table public.shift_templates add constraint shift_templates_shift_type_fkey foreign key (shift_type) references public.shift_types (key);

alter table public.shifts add column if not exists notify_worker boolean not null default true;
alter table public.shifts add column if not exists pay_class text;
alter table public.shifts drop constraint if exists shifts_pay_class_check;
alter table public.shifts add constraint shifts_pay_class_check check (pay_class is null or pay_class in ('regular', 'casual'));
alter table public.shifts add column if not exists extra_notes text not null default '';
alter table public.shifts drop constraint if exists shifts_extra_notes_check;
alter table public.shifts add constraint shifts_extra_notes_check check (length(extra_notes) <= 1000);
alter table public.shifts add column if not exists signatures_needed text[] not null default '{}';
alter table public.shifts drop constraint if exists shifts_signatures_needed_check;
alter table public.shifts add constraint shifts_signatures_needed_check
  check (signatures_needed <@ array['worker_in', 'worker_out', 'client_out', 'representative_out']::text[]);
update public.shifts set signatures_needed =
  (case when needs_worker_signature then array['worker_in', 'worker_out'] else '{}' end)
  || (case when needs_client_signature then array['client_out'] else '{}' end)
 where signatures_needed = '{}' and (needs_worker_signature or needs_client_signature);

alter table public.shift_templates add column if not exists extra_notes text not null default '';
alter table public.shift_templates add column if not exists signatures_needed text[] not null default '{}';

-- The older switches follow the new list (screens and the log still read them).
create or replace function public.sync_shift_signatures() returns trigger
language plpgsql set search_path = '' as $$
begin
  if (tg_op = 'INSERT' and new.signatures_needed <> '{}')
     or (tg_op = 'UPDATE' and new.signatures_needed is distinct from old.signatures_needed) then
    new.needs_worker_signature := new.signatures_needed && array['worker_in', 'worker_out']::text[];
    new.needs_client_signature := new.signatures_needed && array['client_out', 'representative_out']::text[];
  elsif tg_op = 'INSERT'
     or (new.needs_worker_signature, new.needs_client_signature) is distinct from (old.needs_worker_signature, old.needs_client_signature) then
    -- Older screens (copy, paste) set only the two switches.
    new.signatures_needed := (case when new.needs_worker_signature then array['worker_in', 'worker_out'] else '{}' end)
                             || (case when new.needs_client_signature then array['client_out'] else '{}' end);
  end if;
  return new;
end;
$$;
revoke execute on function public.sync_shift_signatures() from public, anon, authenticated;
drop trigger if exists a_sync_shift_signatures on public.shifts;
create trigger a_sync_shift_signatures before insert or update on public.shifts
  for each row execute function public.sync_shift_signatures();

CREATE OR REPLACE FUNCTION public.run_roster_alerts()
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  r record;
  v_new int := 0;
  v_tomorrow int := 0;
  v_requests int := 0;
  v_decided int := 0;
  v_queried int := 0;
  v_declined int := 0;
  v_cancelled int := 0;
  v_unfilled int := 0;
  v_today date := public.local_today();
begin
  if not public.feature_live('rostering') then
    return jsonb_build_object('rostering', 'off');
  end if;
  for r in
    select s.id, s.worker_id, s.starts_at, s.ends_at, c.name as client, s.notify_worker
      from public.shifts s left join public.car_clients c on c.id = s.client_id
     where s.status = 'published' and s.worker_id is not null and s.notified_at is null and s.ends_at > now()
  loop
    -- cmeprojects (update 141): "Notify worker" unticked: marked as done without a notice.
    if not r.notify_worker then
      update public.shifts set notified_at = now() where id = r.id;
      continue;
    end if;
    perform public.notify(r.worker_id, 'shift_published',
      'Shift ' || to_char(r.starts_at at time zone 'Australia/Sydney', 'Dy DD Mon, HH24:MI') || '–' || to_char(r.ends_at at time zone 'Australia/Sydney', 'HH24:MI'),
      coalesce(r.client, 'See My shifts'), '/my-shifts', true);
    update public.shifts set notified_at = now() where id = r.id;
    v_new := v_new + 1;
  end loop;
  for r in
    select s.id, s.worker_id, s.starts_at, c.name as client
      from public.shifts s left join public.car_clients c on c.id = s.client_id
     where s.status = 'published' and s.worker_id is not null
       and (s.starts_at at time zone 'Australia/Sydney')::date = v_today + 1 and s.reminded_on is null
  loop
    perform public.notify(r.worker_id, 'shift_tomorrow',
      'Tomorrow: shift at ' || to_char(r.starts_at at time zone 'Australia/Sydney', 'HH24:MI'), coalesce(r.client, 'See My shifts'), '/my-shifts', false);
    update public.shifts set reminded_on = v_today where id = r.id;
    v_tomorrow := v_tomorrow + 1;
  end loop;
  -- New requests: to the people who roster (managers, staff admins, and job titles with roster edit access).
  for r in
    select q.id, q.kind, p.full_name, p.email from public.shift_change_requests q join public.profiles p on p.id = q.requested_by
     where q.status = 'pending' and q.roster_told_at is null
  loop
    perform public.notify(u.id, 'shift_request',
      coalesce(nullif(r.full_name, ''), r.email) || case when r.kind = 'swap' then ' asked to swap a shift' else ' can''t work a shift' end,
      'Shift change requests', '/roster?requests=1', false)
      from public.profiles u
     where u.active and (u.role in ('manager', 'staff_admin')
                         or u.job_title_id in (select b.job_title_id from public.access_baselines b
                                              where b.module_id = 'ops.roster' and b.revoked_at is null and b.job_title_id is not null
                                                and (b.actions = '{}' or 'edit' = any (b.actions))));
    update public.shift_change_requests set roster_told_at = now() where id = r.id;
    v_requests := v_requests + 1;
  end loop;
  for r in
    select q.id, q.requested_by, q.status from public.shift_change_requests q
     where q.status in ('approved', 'declined') and q.worker_told_at is null
  loop
    perform public.notify(r.requested_by, 'shift_request_decided', 'Your shift change request was ' || r.status, 'See My shifts', '/my-shifts', true);
    update public.shift_change_requests set worker_told_at = now() where id = r.id;
    v_decided := v_decided + 1;
  end loop;
  for r in
    select t.shift_id, t.worker_id from public.shift_timesheets t where t.status = 'queried' and t.told_at is null
  loop
    perform public.notify(r.worker_id, 'timesheet_queried', 'A timesheet needs another look', 'See My shifts', '/my-shifts', true);
    update public.shift_timesheets set told_at = now() where shift_id = r.shift_id;
    v_queried := v_queried + 1;
  end loop;
  -- cmeprojects (update 129): a worker declined: tell the people who roster (once per answer).
  for r in
    select q.shift_id, q.note, q.responded_at, s.starts_at, coalesce(nullif(p.full_name, ''), p.email) as who
      from public.shift_responses q join public.shifts s on s.id = q.shift_id join public.profiles p on p.id = q.worker_id
     where q.response = 'declined' and s.status = 'published' and s.ends_at > now()
       and not exists (select 1 from public.care_alerts_sent a where a.kind = 'shift_declined' and a.item_id = q.shift_id
                        and a.due_on = (q.responded_at at time zone 'Australia/Sydney')::date)
  loop
    insert into public.care_alerts_sent (kind, item_id, due_on) values ('shift_declined', r.shift_id, (r.responded_at at time zone 'Australia/Sydney')::date)
    on conflict do nothing;
    perform public.notify(u, 'shift_declined',
      r.who || ' declined the shift on ' || to_char(r.starts_at at time zone 'Australia/Sydney', 'Dy DD Mon, HH24:MI'),
      coalesce(nullif(r.note, ''), 'Give it to someone else or make it an open shift.'), '/roster?shift=' || r.shift_id, true)
      from public.roster_people() u;
    v_declined := v_declined + 1;
  end loop;
  -- A shift the worker was told about was cancelled: tell them (once).
  for r in
    select s.id, s.worker_id, s.starts_at, c.name as client
      from public.shifts s left join public.car_clients c on c.id = s.client_id
     where s.status = 'cancelled' and s.worker_id is not null and s.ends_at > now()
       and (s.notified_at is not null or exists (select 1 from public.shift_events e where e.shift_id = s.id and e.summary = 'told the worker'))
       and not exists (select 1 from public.care_alerts_sent a where a.kind = 'shift_cancelled' and a.item_id = s.id)
  loop
    insert into public.care_alerts_sent (kind, item_id, due_on) values ('shift_cancelled', r.id, (r.starts_at at time zone 'Australia/Sydney')::date)
    on conflict do nothing;
    perform public.notify(r.worker_id, 'shift_cancelled',
      'Cancelled: your shift on ' || to_char(r.starts_at at time zone 'Australia/Sydney', 'Dy DD Mon, HH24:MI'), coalesce(r.client, 'See My shifts'), '/my-shifts', true);
    v_cancelled := v_cancelled + 1;
  end loop;
  -- Still not filled 48 hours before it starts (vacant, or the worker declined): tell the people who roster (once).
  for r in
    select s.id, s.starts_at, c.name as client
      from public.shifts s left join public.car_clients c on c.id = s.client_id
     where s.status = 'published' and s.starts_at > now() and s.starts_at <= now() + interval '48 hours'
       and (s.worker_id is null or exists (select 1 from public.shift_responses q where q.shift_id = s.id and q.response = 'declined'))
       and not exists (select 1 from public.care_alerts_sent a where a.kind = 'shift_unfilled' and a.item_id = s.id)
  loop
    insert into public.care_alerts_sent (kind, item_id, due_on) values ('shift_unfilled', r.id, (r.starts_at at time zone 'Australia/Sydney')::date)
    on conflict do nothing;
    perform public.notify(u, 'shift_unfilled',
      'Not filled yet: shift on ' || to_char(r.starts_at at time zone 'Australia/Sydney', 'Dy DD Mon, HH24:MI'), coalesce(r.client, 'Open the roster'), '/roster?shift=' || r.id, true)
      from public.roster_people() u;
    v_unfilled := v_unfilled + 1;
  end loop;
  return jsonb_build_object('shifts_notified', v_new, 'shift_reminders', v_tomorrow, 'requests_notified', v_requests, 'requests_decided', v_decided, 'timesheets_queried', v_queried, 'declined', v_declined, 'cancelled', v_cancelled, 'unfilled', v_unfilled);
end;
$function$;
commit;
