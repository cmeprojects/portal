-- Staff Portal · © cmeproject. All rights reserved.
-- Update 108: Service Delivery group description (wording only). Safe to run
-- again. Undo: undo-108.sql. Run update 107 first.
begin;
-- cmeprojects (update 108): wording only. The base access level is now called
-- "Standard access" on screen, so the Service Delivery function group's
-- description no longer names an access level. Changed only if it's still the
-- original text. Nobody's access changes.

update public.function_groups
   set description = 'Frontline staff and team leaders delivering services.'
 where key = 'service_delivery' and description = 'Team leaders and support workers delivering services.';
commit;
