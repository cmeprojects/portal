-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 153): an NDIS number and a My Aged Care ID belong to one
-- client only. If two clients already share one, that rule isn't added and a
-- notice says so: fix those records, then run this update again.
-- Nothing is deleted. No new security definer function. Safe to run again.

do $$
begin
  if exists (select 1 from public.client_details where ndis_number <> '' group by ndis_number having count(*) > 1) then
    raise notice 'NDIS numbers: not made unique yet, because some clients share one. Find them with: select ndis_number, count(*) from client_details where ndis_number <> '''' group by 1 having count(*) > 1;';
  else
    create unique index if not exists client_details_ndis_unique on public.client_details (ndis_number) where ndis_number <> '';
  end if;
  if exists (select 1 from public.client_details where aged_care_id <> '' group by upper(aged_care_id) having count(*) > 1) then
    raise notice 'My Aged Care IDs: not made unique yet, because some clients share one. Find them with: select upper(aged_care_id), count(*) from client_details where aged_care_id <> '''' group by 1 having count(*) > 1;';
  else
    create unique index if not exists client_details_aged_care_unique on public.client_details (upper(aged_care_id)) where aged_care_id <> '';
  end if;
end $$;

-- A new client, their details and who manages them, saved together: if any part
-- is refused (for example an NDIS number already in use), nothing is saved.
-- Runs as the signed-in person (the usual rules apply). Not security definer.
create or replace function public.create_client_full(p_client jsonb, p_details jsonb, p_manager uuid default null, p_as text default 'case_manager')
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
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
$$;
revoke execute on function public.create_client_full(jsonb, jsonb, uuid, text) from public, anon;
grant execute on function public.create_client_full(jsonb, jsonb, uuid, text) to authenticated;
