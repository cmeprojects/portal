-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 144. Safe to run again. Removes only the starter entries no
-- client service or shift uses yet; any in use are switched off instead.
begin;
update public.service_catalogue set active = false
 where name in ('Supported Independent Living (SIL)', 'Short Term Accommodation', 'Community Nursing', 'Meal Preparation', 'Transport', 'Laundry', 'Home Maintenance', 'Behaviour Support', 'Skills Building', 'Group and Centre-based Activities', 'Overnight Support (active)')
   and exists (select 1 from public.client_services s where s.catalogue_id = service_catalogue.id);
delete from public.service_catalogue
 where name in ('Supported Independent Living (SIL)', 'Short Term Accommodation', 'Community Nursing', 'Meal Preparation', 'Transport', 'Laundry', 'Home Maintenance', 'Behaviour Support', 'Skills Building', 'Group and Centre-based Activities', 'Overnight Support (active)')
   and not exists (select 1 from public.client_services s where s.catalogue_id = service_catalogue.id);
update public.shift_types set active = false
 where key in ('meal_preparation', 'medication_support', 'wound_care', 'continence_care', 'nursing_visit', 'transport', 'laundry', 'home_maintenance', 'behaviour_support', 'skills_building')
   and (exists (select 1 from public.shifts s where s.shift_type = shift_types.key) or exists (select 1 from public.shift_templates t where t.shift_type = shift_types.key)
        or exists (select 1 from public.service_catalogue c where shift_types.key = any (c.shift_types)) or exists (select 1 from public.client_services v where shift_types.key = any (v.shift_types)));
delete from public.shift_types
 where key in ('meal_preparation', 'medication_support', 'wound_care', 'continence_care', 'nursing_visit', 'transport', 'laundry', 'home_maintenance', 'behaviour_support', 'skills_building')
   and not exists (select 1 from public.shifts s where s.shift_type = shift_types.key) and not exists (select 1 from public.shift_templates t where t.shift_type = shift_types.key)
   and not exists (select 1 from public.service_catalogue c where shift_types.key = any (c.shift_types)) and not exists (select 1 from public.client_services v where shift_types.key = any (v.shift_types));
commit;
