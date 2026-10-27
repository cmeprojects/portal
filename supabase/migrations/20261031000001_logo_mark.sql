-- Staff Portal · © cmeproject. All rights reserved.
--
-- A second, small logo for tight spaces (the menu, browser tab and phone
-- home-screen icon). The main logo is shown on the sign-in page.

insert into public.app_settings (key, value, label, description, is_public) values
  ('brand.logo_mark_url', '"/logo.svg"', 'Small logo',
   'A square version for the menu, browser tab and phone icon. Leave as the main logo if you only have one.', true)
on conflict (key) do nothing;

update public.app_settings
   set label = 'Main logo', description = 'Shown on the sign-in page and in emails.'
 where key = 'brand.logo_url';
