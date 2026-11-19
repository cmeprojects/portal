-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 151): CHSP (Commonwealth Home Support Programme) as a
-- "Funded by" scheme, with its own program. Like Support at Home, a CHSP
-- client needs their My Aged Care ID before a CHSP service can start.
-- Nothing is deleted. No new security definer function. Safe to run again.

alter table public.client_schemes drop constraint if exists client_schemes_key_check;
alter table public.client_schemes add constraint client_schemes_key_check check (key in ('ndis', 'support_at_home', 'chsp', 'private', 'other'));
insert into public.client_schemes (key, label, person_word, review_label, change_review_label, review_lead_days, needs_dob, sort_order) values
  ('chsp', 'CHSP', null, 'Review', 'Review (change of situation)', '{30}', true, 25)
on conflict (key) do nothing;
insert into public.client_programs (name, scheme, needs_dob, active, sort_order)
select 'CHSP', 'chsp', true, true, 25
 where not exists (select 1 from public.client_programs where lower(name) = 'chsp');

-- The My Aged Care ID: Support at Home and CHSP.
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
    case when (select scheme from public.client_programs where id = p_program) in ('support_at_home', 'chsp')
              and coalesce((select aged_care_id from public.client_details where client_id = p_client), '') = ''
         then 'The My Aged Care ID is needed for a Support at Home or CHSP service.' end,
    case when p_consent_required and p_consent_given is null
         then 'Consent is needed and hasn''t been recorded.' end
  ], null)
$$;
