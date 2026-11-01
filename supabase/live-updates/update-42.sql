-- Staff Portal · © cmeproject. All rights reserved.
-- Update 42: the website's About page, the staff contact number, search
-- engine (SEO) settings, and a security tidy-up from the code audit.
-- Safe to run again. To remove it, run undo-42.sql.
begin;
-- Website: the About page, phone numbers and search-engine settings
-- (cmeprojects). All are words the public website shows, so they're public
-- settings; only the system admin (or a manager given "Website") changes them.

insert into public.app_settings (key, value, label, description, is_public) values
  ('website.staff_phone', '""', 'Number staff call when the Assistant can''t help',
   'Signed-in staff see "Can''t find an answer? Contact your manager" with this number.', true),
  ('website.about_intro', '""', 'About us', 'A short introduction to the company for the About page.', true),
  ('website.mission', '""', 'Our mission', 'Shown on the About page.', true),
  ('website.vision', '""', 'Our vision', 'Shown on the About page.', true),
  ('website.services', '[]', 'Our services', 'One per line, shown on the About page.', true),
  ('website.site_url', '""', 'Website address', 'The address people use, for example https://engagedcare.com.au. Used by search engines.', true),
  ('website.seo_title', '""', 'Title in search results', 'About 50 to 60 characters, for example: Engaged Care Melbourne | NDIS support services.', true),
  ('website.seo_description', '""', 'Description in search results', 'About 150 characters: who you are, what you do and where.', true)
on conflict (key) do nothing;

-- Security tidy-up (code audit): task_label() is only used inside other
-- database functions. Nobody should call it directly (it would show a task's
-- title to anyone who knew its ID).
revoke execute on function public.task_label(uuid) from public, anon, authenticated;

commit;
