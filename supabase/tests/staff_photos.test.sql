-- Staff Portal · © cmeproject. All rights reserved.
--
-- Staff photos (cmeprojects): people set only their own photo, nobody edits
-- it directly, staff admins can remove one, and the onboarding photo works.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('office@example.com', 'Olive', 'staff_admin'), ('sam@example.com', 'Sam', 'support_worker'), ('lee@example.com', 'Lee', 'support_worker');
insert into auth.users (email) values ('office@example.com'), ('sam@example.com'), ('lee@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.photo(p_email text) returns text language sql security definer as $$ select avatar_ref from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;

select test.ok((select count(*) from public.compliance_items where sets_photo and kind = 'upload') = 1, 'every copy has a Profile photo upload in onboarding');

select test.act_as('sam@example.com');
set role authenticated;
select public.set_my_avatar('avatars/' || test.pid('sam@example.com') || '/me.jpg');
select test.refused($$select public.set_my_avatar('avatars/' || test.pid('lee@example.com') || '/lee.jpg')$$, 'Sam can''t use a file in someone else''s folder');
select test.refused($$select public.set_my_avatar('compliance-files/' || test.pid('lee@example.com') || '/id.pdf')$$, 'Sam can''t point his photo at someone''s documents');
select test.refused($$update public.profiles set avatar_ref = 'avatars/x/y.jpg' where id = test.pid('sam@example.com')$$, 'nobody edits the photo field directly');
select test.refused($$select public.remove_avatar(test.pid('lee@example.com'))$$, 'a support worker can''t remove someone else''s photo');
reset role;
select test.ok(test.photo('sam@example.com') = 'avatars/' || test.pid('sam@example.com') || '/me.jpg', 'Sam sets his own photo');

select test.act_as('office@example.com');
set role authenticated;
select public.remove_avatar(test.pid('sam@example.com'));
reset role;
select test.ok(test.photo('sam@example.com') is null, 'a staff admin removes a photo');
select test.ok((select count(*) from public.audit_log where action = 'photo_removed') = 1, 'it''s in the change log');

-- The onboarding photo becomes the photo when sent, and stops when sent back.
insert into public.compliance_records (item_id, user_id, version, status, file_path, file_name)
select id, test.pid('lee@example.com'), 1, 'submitted', test.pid('lee@example.com') || '/photo.jpg', 'photo.jpg'
  from public.compliance_items where sets_photo;
select test.ok(test.photo('lee@example.com') = 'compliance-files/' || test.pid('lee@example.com') || '/photo.jpg', 'sending the onboarding photo sets it');
update public.compliance_records set status = 'rejected' where user_id = test.pid('lee@example.com');
select test.ok(test.photo('lee@example.com') is null, 'sending it back removes it');
insert into public.compliance_records (item_id, user_id, version, status, file_path, file_name)
select id, test.pid('lee@example.com'), 1, 'submitted', test.pid('sam@example.com') || '/other.jpg', 'other.jpg'
  from public.compliance_items where sets_photo;
select test.ok(test.photo('lee@example.com') is null, 'a file outside their own folder is never used');

\o
\echo All staff photo tests passed.
