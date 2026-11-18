-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 144): a starter set of shift types and catalogue
-- services (SIL, short term accommodation, community nursing and others), for
-- Manager Administrators to edit, switch off or extend. Descriptions are left
-- for the organisation to write (no official definitions are invented).
-- Nothing that already exists is changed. Safe to run again.

insert into public.shift_types (key, label, sort_order, used_for) values
  ('meal_preparation', 'Meal preparation', 135, 'client'),
  ('medication_support', 'Medication support', 136, 'client'),
  ('wound_care', 'Wound care', 137, 'client'),
  ('continence_care', 'Continence and catheter care', 138, 'client'),
  ('nursing_visit', 'Nursing visit', 139, 'client'),
  ('transport', 'Transport', 141, 'client'),
  ('laundry', 'Laundry', 142, 'client'),
  ('home_maintenance', 'Home maintenance', 143, 'client'),
  ('behaviour_support', 'Behaviour support', 144, 'client'),
  ('skills_building', 'Skills building', 145, 'client')
on conflict (key) do nothing;

insert into public.service_catalogue (name, description, shift_types, sort_order)
select x.n, '', x.t, x.o
  from (values
    ('Supported Independent Living (SIL)', array['personal_care', 'domestic', 'community_access', 'meal_preparation', 'medication_support', 'overnight', 'sleepover'], 80),
    ('Short Term Accommodation', array['respite_care', 'personal_care', 'sleepover', 'overnight', 'community_access'], 90),
    ('Community Nursing', array['wound_care', 'medication_support', 'continence_care', 'nursing_visit'], 100),
    ('Meal Preparation', array['meal_preparation'], 110),
    ('Transport', array['transport'], 120),
    ('Laundry', array['laundry'], 130),
    ('Home Maintenance', array['home_maintenance', 'gardening'], 140),
    ('Behaviour Support', array['behaviour_support'], 150),
    ('Skills Building', array['skills_building'], 160),
    ('Group and Centre-based Activities', array['group_activity', 'social_activities'], 170),
    ('Overnight Support (active)', array['overnight'], 180)
  ) as x(n, t, o)
 where not exists (select 1 from public.service_catalogue c where lower(c.name) = lower(x.n));
