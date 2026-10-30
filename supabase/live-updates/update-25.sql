-- Staff Portal · © cmeproject. All rights reserved.
-- Update 25: the Cars app's name and icon on staff phones (System settings
-- → Cars). Safe to run again.
begin;
--
-- The Cars app on staff phones (cmeprojects): the name under its icon, and
-- which picture is the icon. Public, because a phone reads them when it
-- installs the app, before anyone signs in.

insert into public.app_settings (key, value, label, description, is_public) values
  ('vehicles.app_name', '"Cars"', 'Cars app name on the phone',
   'The name under the icon on staff phones. Keep it short (about 12 letters), for example EC Cars.', true),
  ('vehicles.app_icon', '"car"', 'Cars app icon',
   'The picture on staff phones'' home screens. Phones that already have the app may need it added again to show a new icon.', true),
  ('vehicles.app_icon_url', '""', 'Your own icon picture',
   'Used when the icon is set to "Your own picture". A square PNG, at least 512 × 512.', true)
on conflict (key) do nothing;

commit;
