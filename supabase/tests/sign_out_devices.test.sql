-- Staff Portal · © cmeproject. All rights reserved.
--
-- Signing out other devices: anyone for themselves, the system admin for
-- one person or for everyone.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com');
create function test.uid(p_email text) returns uuid language sql security definer as $$ select id from auth.users where email = p_email $$;
-- Sign in on a device: a session, with the claims the portal would carry.
create function test.on_device(p_email text, p_session uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', test.uid(p_email), 'aal', 'aal2', 'session_id', p_session)::text, false);
end $$;
grant execute on all functions in schema test to authenticated;

insert into auth.sessions (id, user_id) values
  ('00000000-0000-0000-0000-00000000000a', test.uid('sam@example.com')),
  ('00000000-0000-0000-0000-00000000000b', test.uid('sam@example.com')),
  ('00000000-0000-0000-0000-00000000000c', test.uid('sam@example.com')),
  ('00000000-0000-0000-0000-00000000000d', test.uid('boss@example.com')),
  ('00000000-0000-0000-0000-00000000000e', test.uid('owner@example.com'));

-- Sam signs out his other devices from his phone (session a).
select test.on_device('sam@example.com', '00000000-0000-0000-0000-00000000000a');
set role authenticated;
select test.ok(public.my_session_active(), 'Sam''s phone is signed in');
select test.ok(public.sign_out_my_other_devices() = 2, 'Sam signs out his two other devices');
select test.ok(public.my_session_active(), 'his phone stays signed in');
select test.refused($$select public.sign_out_everywhere(test.uid('boss@example.com'))$$, 'staff can''t sign other people out');
select test.refused($$select public.sign_out_everyone()$$, 'or everyone');
reset role;
select test.ok((select count(*) from auth.sessions where user_id = test.uid('sam@example.com')) = 1, 'only one of Sam''s sessions is left');

-- His laptop (session b) is gone: the portal sees that.
select test.on_device('sam@example.com', '00000000-0000-0000-0000-00000000000b');
set role authenticated;
select test.ok(not public.my_session_active(), 'a signed-out device is no longer active');
reset role;

-- A manager can't; the system admin can.
select test.on_device('boss@example.com', '00000000-0000-0000-0000-00000000000d');
set role authenticated;
select test.refused($$select public.sign_out_everywhere(test.uid('sam@example.com'))$$, 'a manager can''t sign someone out everywhere');
reset role;
select test.on_device('owner@example.com', '00000000-0000-0000-0000-00000000000e');
set role authenticated;
select test.ok(public.sign_out_everywhere(test.uid('sam@example.com')) = 1, 'the system admin signs Sam out everywhere');
select test.refused($$select public.sign_out_everywhere(auth.uid())$$, 'but not themselves');
select test.ok(public.sign_out_everyone() = 1, 'then everyone else (the manager)');
select test.ok(public.my_session_active(), 'and stays signed in themselves');
reset role;
select test.ok((select count(*) from auth.sessions) = 1, 'only the system admin''s session is left');
select test.ok((select count(*) from public.audit_log where action like 'signed_out_%') = 3, 'each one is in the change log');

\o
\echo All sign-out tests passed.
