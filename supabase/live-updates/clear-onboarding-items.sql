-- Staff Portal · © cmeproject. All rights reserved.
-- DEVELOPMENT ONLY (cmeprojects): remove every current "read and confirm",
-- training and upload item from onboarding, with what people did for them.
-- Keeps the Profile photo item, forms, and the new defaults from update 58.
-- Can't be undone. Run it once, before (or after) update 58.
begin;
alter table public.compliance_items disable trigger compliance_items_guard;
delete from public.compliance_items
 where kind in ('read', 'training', 'upload')
   and not coalesce(sets_photo, false)
   and title not in ('NDIS Worker Orientation Module: Quality, Safety and You', 'NDIS Worker Screening Check',
                     'Working with Children Check', 'National Police Check', 'First Aid and CPR certificate',
                     'Driver''s licence', 'Comprehensive car insurance', 'Qualification (Certificate III or IV)');
alter table public.compliance_items enable trigger compliance_items_guard;
commit;
