-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 118: removes the new client details and archive reasons (and
-- what was recorded in them) and puts the readiness check back. Archived
-- clients stay Discharged. Safe to run again.
begin;
drop trigger if exists guard_client_names_and_archive on public.car_clients;
drop function if exists public.guard_client_names_and_archive();
alter table public.car_clients drop column if exists title, drop column if exists given_name, drop column if exists middle_name,
  drop column if exists family_name, drop column if exists archive_reason, drop column if exists archive_note,
  drop column if exists archived_at, drop column if exists archived_by;
alter table public.client_details drop column if exists gender, drop column if exists state, drop column if exists time_zone,
  drop column if exists living_situation, drop column if exists about, drop column if exists religion,
  drop column if exists marital_status, drop column if exists atsi_status, drop column if exists country_of_birth,
  drop column if exists nationality, drop column if exists tags;
create or replace function public.client_gaps(p_client uuid, p_program uuid, p_location uuid, p_consent_required boolean, p_consent_given date)
 RETURNS text[]
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
  select array_remove(array[
    case when (select status from public.car_clients where id = p_client) is distinct from 'active'
         then 'The client isn''t active yet.' end,
    case when not exists (select 1 from public.client_locations l
                           where l.id = p_location and l.client_id = p_client and l.approved
                             and (l.from_date is null or l.from_date <= public.local_today())
                             and (l.to_date is null or l.to_date >= public.local_today()))
         then 'The service location isn''t approved and current.' end,
    case when not exists (select 1 from public.client_people where client_id = p_client and kind = 'emergency' and active)
         then 'No emergency contact.' end,
    case when not exists (select 1 from public.client_alerts where client_id = p_client and active)
         then 'Safety isn''t answered (add an alert, or record "No known safety alerts").' end,
    case when coalesce((select needs_dob from public.client_programs where id = p_program), false)
              and (select date_of_birth from public.client_details where client_id = p_client) is null
         then 'Date of birth is needed for this program.' end,
    case when p_consent_required and p_consent_given is null
         then 'Consent is needed and hasn''t been recorded.' end
  ], null)
$function$

;
commit;
