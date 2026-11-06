-- Staff Portal · © cmeproject. All rights reserved.
--
-- Company setup: </>cmeprojects, for cmeprojects' own copies (Development and
-- Demo). Run once on that copy's own Supabase project, after the fresh install.
-- Branding only: registers are added later (the setup wizard), so these copies
-- start clean, with nothing from any client.

update public.organisation set name = 'cmeprojects';

update public.app_settings set value = '"</>cmeprojects"' where key = 'brand.company_name';
update public.app_settings set value = '"Staff Portal"' where key = 'brand.portal_name';
update public.app_settings set value = '"/companies/cmeprojects/logo.svg"'      where key = 'brand.logo_url';
update public.app_settings set value = '"/companies/cmeprojects/logo-mark.svg"' where key = 'brand.logo_mark_url';
update public.app_settings set value = '"#111111"' where key = 'brand.color_primary';
update public.app_settings set value = '"#000000"' where key = 'brand.color_dark';
update public.app_settings set value = '"#6B7280"' where key = 'brand.color_accent';
