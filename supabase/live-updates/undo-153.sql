-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 153. Safe to run again. NDIS numbers and My Aged Care IDs can repeat again.
begin;
drop index if exists public.client_details_ndis_unique;
drop index if exists public.client_details_aged_care_unique;
drop function if exists public.create_client_full(jsonb, jsonb, uuid, text);
commit;
