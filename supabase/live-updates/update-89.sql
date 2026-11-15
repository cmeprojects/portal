-- Staff Portal · © cmeproject. All rights reserved.
-- Update 89: Clients & Care step 4: safety alerts, worker instructions and
-- detailed risk notes. Safe to run again. Undo: undo-89.sql. Run update 88 first.
begin;
-- cmeprojects (update 89): Clients & Care step 4: safety. Alerts, risks and
-- precautions, with severity, what workers must do, who to call, and a review
-- date. "No known safety alerts" is recorded the same way, so the safety step
-- is always answered before a service starts (step 5 checks it).
--
--   * client_alerts: what workers need (title, severity, worker instructions,
--     escalation). Staff and team leaders see the active alerts of their own
--     teams' clients.
--   * client_alert_notes: the detailed risk notes for an alert. Sensitive:
--     people managers and the system admin only.
--   * Alerts are never deleted: they're made inactive. Every change is in the
--     change log (no values).

create table if not exists public.client_alerts (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  client_id uuid not null references public.car_clients (id) on delete restrict,
  kind text not null check (kind in ('safety', 'medical', 'behaviour', 'environment', 'mobility', 'other', 'no_known_alerts')),
  severity text not null default 'medium' check (severity in ('low', 'medium', 'high')),
  title text not null check (length(trim(title)) between 1 and 120),
  worker_instructions text not null default '' check (length(worker_instructions) <= 2000),
  escalation text not null default '' check (length(escalation) <= 500),
  active boolean not null default true,
  review_date date,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now()
);
create index if not exists client_alerts_client on public.client_alerts (client_id);
alter table public.client_alerts enable row level security;

create table if not exists public.client_alert_notes (
  alert_id uuid primary key references public.client_alerts (id) on delete restrict,
  client_id uuid not null references public.car_clients (id) on delete restrict,
  org_id uuid not null default public.default_org_id(),
  details text not null default '' check (length(details) <= 5000),
  updated_by uuid,
  updated_at timestamptz not null default now()
);
alter table public.client_alert_notes enable row level security;

do $$
declare
  t text;
begin
  foreach t in array array['client_alerts', 'client_alert_notes'] loop
    execute format('drop policy if exists "people managers see %1$s" on public.%1$I', t);
    execute format('create policy "people managers see %1$s" on public.%1$I for select to authenticated using ((select public.can_manage_people()))', t);
    execute format('drop policy if exists "people managers add %1$s" on public.%1$I', t);
    execute format('create policy "people managers add %1$s" on public.%1$I for insert to authenticated with check ((select public.can_manage_people()))', t);
    execute format('drop policy if exists "people managers change %1$s" on public.%1$I', t);
    execute format('create policy "people managers change %1$s" on public.%1$I for update to authenticated using ((select public.can_manage_people())) with check ((select public.can_manage_people()))', t);
    execute format('grant select, insert, update on public.%I to authenticated', t);
  end loop;
end;
$$;

-- Staff and team leaders: active alerts of their own teams' clients (not the notes).
drop policy if exists "staff see their teams' client alerts" on public.client_alerts;
create policy "staff see their teams' client alerts" on public.client_alerts
  for select to authenticated
  using (active
     and (select public.is_member())
     and exists (
       select 1 from public.client_teams ct
        where ct.client_id = client_alerts.client_id
          and (exists (select 1 from public.team_members tm where tm.team_id = ct.team_id and tm.user_id = (select auth.uid()))
               or exists (select 1 from public.team_leaders tl where tl.team_id = ct.team_id and tl.user_id = (select auth.uid())))));

-- A note always belongs to its alert's client.
create or replace function public.fill_alert_note_client()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.client_id := (select client_id from public.client_alerts where id = new.alert_id);
  if new.client_id is null then
    raise exception 'Choose an alert.';
  end if;
  return new;
end;
$$;
revoke execute on function public.fill_alert_note_client() from public, anon, authenticated;

drop trigger if exists a_fill_alert_note_client on public.client_alert_notes;
create trigger a_fill_alert_note_client before insert or update on public.client_alert_notes
  for each row execute function public.fill_alert_note_client();
drop trigger if exists log_client_change on public.client_alert_notes;
create trigger log_client_change before insert or update on public.client_alert_notes
  for each row execute function public.log_client_change();
drop trigger if exists log_client_change on public.client_alerts;
create trigger log_client_change before insert or update on public.client_alerts
  for each row execute function public.log_client_change();
commit;
