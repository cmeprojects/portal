-- Staff Portal · © cmeproject. All rights reserved.
--
-- The Staff app (cmeprojects): one phone app holding the features the system
-- admin chooses (built features, and Cars if they like), with its own name
-- and icon. A premium add-on, off until the system admin switches it on. The
-- Cars app carries on as its own app; the system admin can switch that off
-- when Cars lives in the Staff app instead.

insert into public.features (key, label, description, enabled, sort_order, premium, included) values
  ('staff_app', 'Staff app',
   'One phone app for staff with the features you choose: built features like Fluid intake, and Cars if you like.',
   false, 76, true, false)
on conflict (key) do nothing;

-- Shown on phones before anyone signs in, so public.
insert into public.app_settings (key, value, label, description, is_public) values
  ('staff_app.name', '"Staff"', 'Staff app name on the phone',
   'The name under the icon on staff phones. Keep it short (about 12 letters), for example EC Staff.', true),
  ('staff_app.icon', '"car"', 'Staff app icon',
   'The picture on staff phones'' home screens. Tap one to use it, or upload your own.', true),
  ('staff_app.icon_uploads', '[]', 'Uploaded Staff app icons', 'Pictures uploaded for the Staff app icon.', true),
  ('staff_app.cars', 'false', 'Cars in the Staff app',
   'Show Cars as an icon inside the Staff app.', true),
  ('vehicles.separate_app', 'true', 'Separate Cars app',
   'Keep the Cars app as its own app. Turn off if Cars is in the Staff app and you want only one app.', true)
on conflict (key) do nothing;

-- Each built feature: in the Staff app or not, and its icon there.
alter table public.custom_features add column if not exists in_app boolean not null default true;
alter table public.custom_features add column if not exists app_icon text not null default 'clipboard' check (length(app_icon) <= 20);
alter table public.custom_features add column if not exists app_colour text not null default '#134f8e' check (app_colour ~ '^#[0-9a-fA-F]{6}$');
