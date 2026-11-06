-- Staff Portal · © cmeproject. All rights reserved.
--
-- Neutral examples (cmeprojects): setting descriptions no longer name a client,
-- so a fresh copy for any company shows nothing from another.

update public.app_settings
   set description = 'The address people use, for example https://yourcompany.com.au. Used by search engines.'
 where key = 'website.site_url';
update public.app_settings
   set description = 'About 50 to 60 characters, for example: Your Company | NDIS support services in your area.'
 where key = 'website.seo_title';
