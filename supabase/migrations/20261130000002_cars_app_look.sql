-- Staff Portal · © cmeproject. All rights reserved.
--
-- The Cars app on staff phones (cmeprojects): the name under its icon, and
-- which picture is the icon. Public, because a phone reads them when it
-- installs the app, before anyone signs in. The icon is "car", "mark" (the
-- small logo), "logo" or the address of an uploaded picture.

insert into public.app_settings (key, value, label, description, is_public) values
  ('vehicles.app_name', '"Cars"', 'Cars app name on the phone',
   'The name under the icon on staff phones. Keep it short (about 12 letters), for example EC Cars.', true),
  ('vehicles.app_icon', '"car"', 'Cars app icon',
   'The picture on staff phones'' home screens. Tap one to use it, or upload your own. Phones that already have the app may need it added again to show a new icon.', true),
  -- Pictures uploaded as icons, kept as choices until deleted.
  ('vehicles.app_icon_uploads', '[]', 'Uploaded icons', 'Pictures uploaded for the Cars app icon.', true)
on conflict (key) do nothing;
