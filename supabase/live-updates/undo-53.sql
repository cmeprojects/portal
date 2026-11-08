-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 53: removes staff photos (the photo field, the onboarding
-- Profile photo item and its rules). Uploaded photo files stay in storage.
-- Safe to run again.
begin;
drop trigger if exists photo_from_onboarding on public.compliance_records;
drop function if exists public.photo_from_onboarding();
drop trigger if exists guard_avatar_ref on public.profiles;
drop function if exists public.guard_avatar_ref();
drop function if exists public.set_my_avatar(text);
drop function if exists public.remove_avatar(uuid);
delete from public.compliance_items where sets_photo
  and not exists (select 1 from public.compliance_records r where r.item_id = compliance_items.id);
update public.compliance_items set active = false where sets_photo;
drop policy if exists "people upload their own photo" on storage.objects;
drop policy if exists "people read their own photo" on storage.objects;
drop policy if exists "people remove their own photo" on storage.objects;
alter table public.profiles drop column if exists avatar_ref;
commit;
