-- Staff Portal · © cmeproject. All rights reserved.
-- Update 53: staff photos. A photo field on each person, private photo storage,
-- set-your-own-photo and remove-a-photo, and a default "Profile photo" upload
-- in My onboarding. Safe to run again. Undo: undo-53.sql.
begin;
alter table public.profiles add column if not exists avatar_ref text;
alter table public.compliance_items add column if not exists sets_photo boolean not null default false;

-- Private storage for photos, in a folder named by each person's id.
do $$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values ('avatars', 'avatars', false, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
  on conflict (id) do nothing;

  drop policy if exists "people upload their own photo" on storage.objects;
  create policy "people upload their own photo" on storage.objects for insert to authenticated
    with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text and public.is_member());
  drop policy if exists "people read their own photo" on storage.objects;
  create policy "people read their own photo" on storage.objects for select to authenticated
    using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
  drop policy if exists "people remove their own photo" on storage.objects;
  create policy "people remove their own photo" on storage.objects for delete to authenticated
    using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
end;
$$;

-- avatar_ref only changes through the functions below (which check it points
-- at the person's own files), never by editing the profile directly.
create or replace function public.guard_avatar_ref()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.avatar_ref is distinct from old.avatar_ref
     and coalesce(current_setting('portal.avatar_ok', true), '') <> 'on' then
    raise exception 'Change the photo from My account.';
  end if;
  return new;
end;
$$;

drop trigger if exists guard_avatar_ref on public.profiles;
create trigger guard_avatar_ref before update of avatar_ref on public.profiles
  for each row execute function public.guard_avatar_ref();

-- Set my photo to a file I uploaded to the avatars store.
create or replace function public.set_my_avatar(p_ref text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null or not public.is_member() then
    raise exception 'Sign in first.';
  end if;
  if p_ref is null or p_ref !~ ('^avatars/' || auth.uid()::text || '/[A-Za-z0-9._-]+$') then
    raise exception 'Choose a photo and wait for it to upload.';
  end if;
  perform set_config('portal.avatar_ok', 'on', true);
  update public.profiles set avatar_ref = p_ref where id = auth.uid();
end;
$$;

-- Remove a photo: your own, or anyone's if you manage people.
create or replace function public.remove_avatar(p_user uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_user is distinct from auth.uid() and not (public.can_manage_people() or public.is_system_admin()) then
    raise exception 'Only you, or people who manage staff, can remove this photo.';
  end if;
  perform set_config('portal.avatar_ok', 'on', true);
  update public.profiles set avatar_ref = null where id = p_user;
  perform public.write_audit('photo_removed', 'profile', p_user::text, '{}'::jsonb);
end;
$$;

revoke execute on function public.set_my_avatar(text) from public, anon;
revoke execute on function public.remove_avatar(uuid) from public, anon;
grant execute on function public.set_my_avatar(text) to authenticated;
grant execute on function public.remove_avatar(uuid) to authenticated;

-- An onboarding upload marked sets_photo becomes the person's photo when they
-- send it, and stops being it if it's sent back.
create or replace function public.photo_from_onboarding()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ref text;
begin
  if new.file_path is null or not exists (select 1 from public.compliance_items where id = new.item_id and sets_photo) then
    return new;
  end if;
  -- Only the person's own folder (uploads are stored as <their id>/...).
  if new.file_path !~ ('^' || new.user_id::text || '/') then
    return new;
  end if;
  v_ref := 'compliance-files/' || new.file_path;
  perform set_config('portal.avatar_ok', 'on', true);
  if new.status in ('submitted', 'accepted') then
    -- Doesn't replace a photo they chose themselves in My account.
    update public.profiles set avatar_ref = v_ref
     where id = new.user_id and (avatar_ref is null or avatar_ref like 'compliance-files/%');
  elsif new.status = 'rejected' then
    update public.profiles set avatar_ref = null where id = new.user_id and avatar_ref = v_ref;
  end if;
  return new;
end;
$$;

drop trigger if exists photo_from_onboarding on public.compliance_records;
create trigger photo_from_onboarding after insert or update of status, file_path on public.compliance_records
  for each row execute function public.photo_from_onboarding();

-- The default onboarding upload: a profile photo (once per copy; staff admins
-- can edit it or switch it off in Compliance → Uploads).
insert into public.compliance_items (kind, title, description, sets_photo, active, sort_order, created_by)
select 'upload', 'Profile photo',
       'A clear, recent photo of your face, like a passport photo. It''s shown next to your name in the portal, only to signed-in staff.',
       true, true, 5, null
where not exists (select 1 from public.compliance_items where sets_photo);
commit;
