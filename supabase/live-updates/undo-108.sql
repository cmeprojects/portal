-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 108: puts the Service Delivery description back. Safe to run again.
begin;
update public.function_groups
   set description = 'Team leaders and support workers delivering services.'
 where key = 'service_delivery' and description = 'Frontline staff and team leaders delivering services.';
commit;
