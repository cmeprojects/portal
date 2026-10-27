-- Staff Portal · © cmeproject. All rights reserved.
--
-- Company setup: Engaged Care Pty Ltd (Engaged Care Melbourne), Derrimut VIC.
-- Run once on this company's own Supabase project, after the migrations.
-- Registry names 5–7 are placeholders until the real names are confirmed.

update public.organisation set name = 'Engaged Care Pty Ltd';

update public.app_settings set value = '"Engaged Care"' where key = 'brand.company_name';
update public.app_settings set value = '"Staff Portal"' where key = 'brand.portal_name';
-- Swap in the real logo by saving it as public/logo.png and changing this.
update public.app_settings set value = '"/logo.svg"'    where key = 'brand.logo_url';
update public.app_settings set value = '"#134F8E"'      where key = 'brand.color_primary';
update public.app_settings set value = '"#0F2F57"'      where key = 'brand.color_dark';
update public.app_settings set value = '"#6497C8"'      where key = 'brand.color_accent';

insert into public.registries (name, description, requires_approval, sort_order) values
  ('Compliance Registry', 'Policies, screening, audits and other compliance work.', true, 10),
  ('Maintenance',         'Repairs and upkeep of houses, equipment and cars.',      false, 20),
  ('Feedback',            'Compliments, complaints and suggestions to follow up.',  true, 30),
  ('Training',            'Staff training and refreshers.',                         false, 40),
  ('Registry 5 (name TBC)', '', false, 50),
  ('Registry 6 (name TBC)', '', false, 60),
  ('Registry 7 (name TBC)', '', false, 70)
on conflict do nothing;
