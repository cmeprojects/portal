-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 37. Puts enquiries back to managers only, removes the password
-- lock and the Compliance switch. Nothing else is touched. Safe to run again.
begin;
drop function if exists public.my_forms_to_fill();
drop trigger if exists compliance_items_guard on public.compliance_items;
drop function if exists public.compliance_items_guard();
delete from public.features where key = 'compliance';
drop function if exists public.sign_in_guard(text, text);
drop table if exists public.sign_in_failures;
drop policy if exists "the builder removes unused features" on public.custom_features;
drop policy if exists "the builder removes unused drafts" on public.custom_features;
create policy "the builder removes unused drafts" on public.custom_features for delete to authenticated
  using (public.can_build_features() and status = 'draft'
         and not exists (select 1 from public.custom_entries e where e.feature_id = custom_features.id));
drop policy if exists website_enquiries_read on public.website_enquiries;
create policy website_enquiries_read on public.website_enquiries
  for select to authenticated using (public.has_role(array['manager', 'system_admin']::public.app_role[]));
drop policy if exists website_enquiries_update on public.website_enquiries;
create policy website_enquiries_update on public.website_enquiries for update to authenticated
  using (public.has_role(array['manager', 'system_admin']::public.app_role[]))
  with check (public.has_role(array['manager', 'system_admin']::public.app_role[]));
create or replace function public.new_enquiry_count() returns bigint language sql stable security definer set search_path = '' as $$
  select case when public.has_role(array['manager', 'system_admin']::public.app_role[])
    then (select count(*) from public.website_enquiries where status = 'new') else 0 end
$$;
create or replace function public.website_enquiry_notify() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.notifications (user_id, kind, title, body, href)
  select p.id, 'website_enquiry', 'New enquiry: ' || new.full_name, 'Phone ' || new.phone || '. Call them back.', '/enquiries'
    from public.profiles p where p.active and p.role in ('manager', 'system_admin');
  return new;
end $$;
drop function if exists public.can_see_enquiries();
delete from public.app_settings where key = 'assistant.enquiry_roles';
commit;
