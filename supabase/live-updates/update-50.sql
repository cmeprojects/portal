-- Staff Portal · © cmeproject. All rights reserved.
-- Update 50: two setting examples no longer name a company. Safe to run again.
-- (Nothing to undo: it only changes example wording.)
begin;
update public.app_settings
   set description = 'The address people use, for example https://yourcompany.com.au. Used by search engines.'
 where key = 'website.site_url';
update public.app_settings
   set description = 'About 50 to 60 characters, for example: Your Company | NDIS support services in your area.'
 where key = 'website.seo_title';

commit;
