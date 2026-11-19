-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 151. Safe to run again. CHSP is removed only where nothing uses it yet.
begin;
create or replace function public.client_gaps(p_client uuid, p_program uuid, p_location uuid, p_consent_required boolean, p_consent_given date)
returns text[]
language sql
stable
set search_path = ''
as $$
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
    case when (select scheme from public.client_programs where id = p_program) = 'support_at_home'
              and coalesce((select aged_care_id from public.client_details where client_id = p_client), '') = ''
         then 'The My Aged Care ID is needed for a Support at Home service.' end,
    case when p_consent_required and p_consent_given is null
         then 'Consent is needed and hasn''t been recorded.' end
  ], null)
$$;
delete from public.client_programs p where lower(p.name) = 'chsp' and p.scheme = 'chsp'
   and not exists (select 1 from public.client_services s where s.program_id = p.id);
do $$ begin
  if not exists (select 1 from public.client_programs where scheme = 'chsp')
     and not exists (select 1 from public.car_clients where scheme = 'chsp')
     and not exists (select 1 from public.client_reviews where scheme = 'chsp')
     and not exists (select 1 from public.client_agreements where scheme = 'chsp')
     and not exists (select 1 from public.client_funding where scheme = 'chsp') then
    delete from public.client_schemes where key = 'chsp';
    alter table public.client_schemes drop constraint if exists client_schemes_key_check;
    alter table public.client_schemes add constraint client_schemes_key_check check (key in ('ndis', 'support_at_home', 'private', 'other'));
  end if;
end $$;
commit;
