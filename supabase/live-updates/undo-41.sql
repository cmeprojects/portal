-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 41: enquiries stop making Call back tasks (tasks already made
-- stay). Safe to run again.
begin;
create or replace function public.website_enquiry_notify() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.notifications (user_id, kind, title, body, href)
  select p.id, 'website_enquiry', 'New enquiry: ' || new.full_name, 'Phone ' || new.phone || '. Call them back.', '/enquiries'
    from public.profiles p
   where p.active and (p.role = 'system_admin' or p.role::text in (select jsonb_array_elements_text(coalesce(
           (select value from public.app_settings where key = 'assistant.enquiry_roles'), '[]'))));
  return new;
end $$;
drop function if exists public.next_business_day(date);
delete from public.app_settings where key in ('assistant.intake_roles', 'tasks.public_holidays');
commit;
