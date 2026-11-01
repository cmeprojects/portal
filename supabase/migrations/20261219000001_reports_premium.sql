-- Staff Portal · © cmeproject. All rights reserved.
--
-- Reports and exports becomes a premium add-on (cmeprojects): the Reports
-- pages and every Excel download. It stays on for companies already using it.

update public.features
   set label = 'Reports and exports',
       description = 'The Reports pages (tasks, compliance, cars, built features) and every Excel download.',
       premium = true,
       included = true
 where key = 'reports';
