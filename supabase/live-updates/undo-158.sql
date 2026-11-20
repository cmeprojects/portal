-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 158 (program enrolments). Safe to run again.
-- Removes enrolments and their checks; "Funded by" keeps its current value.
-- Services, agreements, budgets, shifts and the change log are not touched.
begin;
drop trigger if exists guard_shift_enrolment on public.shifts;
drop trigger if exists guard_service_enrolment on public.client_services;
drop trigger if exists guard_funded_by on public.car_clients;
drop trigger if exists client_schemes_log on public.client_schemes;
drop trigger if exists client_programs_log on public.client_programs;
drop table if exists public.client_enrolments;
drop function if exists public.guard_shift_enrolment();
drop function if exists public.guard_service_enrolment();
drop function if exists public.guard_funded_by();
drop function if exists public.sync_client_main();
drop function if exists public.guard_client_enrolment();
drop function if exists public.from_portal();
alter table public.client_schemes drop column if exists offered;
alter table public.client_schemes drop column if exists id;
drop function if exists public.create_client_full(jsonb, jsonb, uuid, text, uuid[], uuid, date);
CREATE OR REPLACE FUNCTION public.create_client_full(p_client jsonb, p_details jsonb, p_manager uuid DEFAULT NULL::uuid, p_as text DEFAULT 'case_manager'::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO ''
AS $$
declare
  v_id uuid;
begin
  insert into public.car_clients (name, title, given_name, middle_name, family_name, preferred_name, reference, scheme)
  values (p_client ->> 'name', coalesce(p_client ->> 'title', ''), p_client ->> 'given_name', coalesce(p_client ->> 'middle_name', ''), p_client ->> 'family_name',
          coalesce(p_client ->> 'preferred_name', ''), coalesce(p_client ->> 'reference', ''), nullif(p_client ->> 'scheme', ''))
  returning id into v_id;
  insert into public.client_details (client_id, date_of_birth, gender, phone, email, home_address, state, ndis_number, aged_care_id)
  values (v_id, nullif(p_details ->> 'date_of_birth', '')::date, coalesce(p_details ->> 'gender', ''), coalesce(p_details ->> 'phone', ''), coalesce(p_details ->> 'email', ''),
          coalesce(p_details ->> 'home_address', ''), coalesce(p_details ->> 'state', ''), coalesce(p_details ->> 'ndis_number', ''), coalesce(p_details ->> 'aged_care_id', ''));
  if p_manager is not null then
    insert into public.client_assignments (client_id, user_id, assigned_as) values (v_id, p_manager, coalesce(p_as, 'case_manager'));
  end if;
  return v_id;
end;
$$
;
revoke execute on function public.create_client_full(jsonb, jsonb, uuid, text) from public, anon;
grant execute on function public.create_client_full(jsonb, jsonb, uuid, text) to authenticated;
CREATE OR REPLACE FUNCTION public.client_gaps(p_client uuid, p_program uuid, p_location uuid, p_consent_required boolean, p_consent_given date)
 RETURNS text[]
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $$
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
    case when (select scheme from public.client_programs where id = p_program) = 'ndis'
              and coalesce((select ndis_number from public.client_details where client_id = p_client), '') = ''
         then 'The NDIS number is needed for an NDIS service.' end,
    case when (select scheme from public.client_programs where id = p_program) in ('support_at_home', 'chsp')
              and coalesce((select aged_care_id from public.client_details where client_id = p_client), '') = ''
         then 'The My Aged Care ID is needed for a Support at Home or CHSP service.' end,
    case when p_consent_required and p_consent_given is null
         then 'Consent is needed and hasn''t been recorded.' end
  ], null)
$$
;
commit;
