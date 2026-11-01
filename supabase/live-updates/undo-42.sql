-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 42: removes the About, staff number and SEO settings. Safe to run again.
begin;
delete from public.app_settings where key in ('website.staff_phone', 'website.about_intro', 'website.mission', 'website.vision',
  'website.services', 'website.site_url', 'website.seo_title', 'website.seo_description');
grant execute on function public.task_label(uuid) to authenticated;
commit;
