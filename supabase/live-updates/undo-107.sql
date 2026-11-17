-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 107: Clients go back to the built-in rule. Grants for
-- Clients are kept (no effect until switched over again). Safe to run again.
begin;
update public.app_modules set grant_ready = false where id like 'clients.%' and grant_ready;
drop policy if exists "people managers add clients" on public.car_clients;
create policy "people managers add clients" on public.car_clients as PERMISSIVE for INSERT to authenticated with check (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "people managers change clients" on public.car_clients;
create policy "people managers change clients" on public.car_clients as PERMISSIVE for UPDATE to authenticated using (( SELECT can_manage_people() AS can_manage_people)) with check (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "people managers see clients" on public.car_clients;
create policy "people managers see clients" on public.car_clients as PERMISSIVE for SELECT to authenticated using (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "people managers add client_alert_notes" on public.client_alert_notes;
create policy "people managers add client_alert_notes" on public.client_alert_notes as PERMISSIVE for INSERT to authenticated with check (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "people managers change client_alert_notes" on public.client_alert_notes;
create policy "people managers change client_alert_notes" on public.client_alert_notes as PERMISSIVE for UPDATE to authenticated using (( SELECT can_manage_people() AS can_manage_people)) with check (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "people managers see client_alert_notes" on public.client_alert_notes;
create policy "people managers see client_alert_notes" on public.client_alert_notes as PERMISSIVE for SELECT to authenticated using (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "people managers add client_alerts" on public.client_alerts;
create policy "people managers add client_alerts" on public.client_alerts as PERMISSIVE for INSERT to authenticated with check (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "people managers change client_alerts" on public.client_alerts;
create policy "people managers change client_alerts" on public.client_alerts as PERMISSIVE for UPDATE to authenticated using (( SELECT can_manage_people() AS can_manage_people)) with check (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "people managers see client_alerts" on public.client_alerts;
create policy "people managers see client_alerts" on public.client_alerts as PERMISSIVE for SELECT to authenticated using (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "people managers add client_details" on public.client_details;
create policy "people managers add client_details" on public.client_details as PERMISSIVE for INSERT to authenticated with check (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "people managers change client_details" on public.client_details;
create policy "people managers change client_details" on public.client_details as PERMISSIVE for UPDATE to authenticated using (( SELECT can_manage_people() AS can_manage_people)) with check (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "people managers see client_details" on public.client_details;
create policy "people managers see client_details" on public.client_details as PERMISSIVE for SELECT to authenticated using (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "people managers add client locations" on public.client_locations;
create policy "people managers add client locations" on public.client_locations as PERMISSIVE for INSERT to authenticated with check (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "people managers change client locations" on public.client_locations;
create policy "people managers change client locations" on public.client_locations as PERMISSIVE for UPDATE to authenticated using (( SELECT can_manage_people() AS can_manage_people)) with check (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "people managers see client locations" on public.client_locations;
create policy "people managers see client locations" on public.client_locations as PERMISSIVE for SELECT to authenticated using (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "people managers add client_people" on public.client_people;
create policy "people managers add client_people" on public.client_people as PERMISSIVE for INSERT to authenticated with check (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "people managers change client_people" on public.client_people;
create policy "people managers change client_people" on public.client_people as PERMISSIVE for UPDATE to authenticated using (( SELECT can_manage_people() AS can_manage_people)) with check (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "people managers see client_people" on public.client_people;
create policy "people managers see client_people" on public.client_people as PERMISSIVE for SELECT to authenticated using (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "people managers add client_services" on public.client_services;
create policy "people managers add client_services" on public.client_services as PERMISSIVE for INSERT to authenticated with check (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "people managers change client_services" on public.client_services;
create policy "people managers change client_services" on public.client_services as PERMISSIVE for UPDATE to authenticated using (( SELECT can_manage_people() AS can_manage_people)) with check (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "people managers see client_services" on public.client_services;
create policy "people managers see client_services" on public.client_services as PERMISSIVE for SELECT to authenticated using (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "people managers link clients to teams" on public.client_teams;
create policy "people managers link clients to teams" on public.client_teams as PERMISSIVE for INSERT to authenticated with check (( SELECT can_manage_people() AS can_manage_people));
drop policy if exists "people managers unlink clients from teams" on public.client_teams;
create policy "people managers unlink clients from teams" on public.client_teams as PERMISSIVE for DELETE to authenticated using (( SELECT can_manage_people() AS can_manage_people));

CREATE OR REPLACE FUNCTION public.guard_client_record()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if tg_op = 'INSERT' then
    new.client_ref := public.next_client_ref(); -- always made here, never chosen
    if new.status <> 'pending' and auth.uid() is not null and not public.can_manage_people() then
      raise exception 'Only people managers can set a client''s status.';
    end if;
    return new;
  end if;
  if new.client_ref is distinct from old.client_ref then
    raise exception 'A client''s reference never changes.';
  end if;
  if new.status is distinct from old.status then
    if auth.uid() is not null and not public.can_manage_people() then
      raise exception 'Only people managers can change a client''s status.';
    end if;
    new.status_changed_at := now();
    new.status_changed_by := auth.uid();
    perform public.write_audit('client_status', 'client', new.id::text,
      jsonb_build_object('client', new.client_ref, 'from', old.status, 'to', new.status));
  end if;
  return new;
end;
$function$;
commit;
