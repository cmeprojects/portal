-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 119): offboarding (HR block step 1).

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('office@example.com', 'Olive', 'staff_admin'),
  ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('office@example.com'), ('sam@example.com'), ('kim@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.n(p_email text, p_sql text) returns bigint language plpgsql as $$
declare v bigint;
begin
  perform test.act_as(p_email);
  execute 'set local role authenticated';
  execute 'select ' || p_sql into v;
  execute 'reset role';
  return v;
end $$;
grant execute on all functions in schema test to authenticated;

-- A staff admin starts Sam's offboarding.
select test.act_as('office@example.com');
set role authenticated;
insert into public.offboardings (user_id, reason, last_day, note, status) values (test.pid('sam@example.com'), 'resigned', current_date + 14, 'Moving interstate', 'completed');
select test.refused($$insert into public.offboardings (user_id, reason, last_day) values (test.pid('sam@example.com'), 'resigned', current_date)$$, 'one open offboarding per person');
select test.refused($$insert into public.offboardings (user_id, reason, last_day) values (test.pid('office@example.com'), 'resigned', current_date)$$, 'nobody offboards themselves');
reset role;
select test.ok((select status = 'open' and started_by = test.pid('office@example.com') from public.offboardings), 'starts open, records who');
select test.ok((select count(*) from public.offboarding_steps) = 7, 'the standard checklist is made');

-- Who sees it.
select test.ok(test.n('boss@example.com', '(select count(*) from public.offboardings)') = 1, 'manager sees it');
select test.ok(test.n('sam@example.com', '(select count(*) from public.offboardings)') = 0, 'the person leaving doesn''t see the record');
select test.ok(test.n('kim@example.com', '(select count(*) from public.offboarding_steps)') = 0, 'other staff see nothing');

-- Ticking steps; an extra step; deactivation ticks itself.
select test.act_as('boss@example.com');
set role authenticated;
update public.offboarding_steps set state = 'done' where step = 'car';
update public.offboarding_steps set state = 'not_needed' where step = 'client_keys';
insert into public.offboarding_steps (offboarding_id, step, title) select id, 'car', 'Return the defibrillator training kit' from public.offboardings;
select test.refused($$update public.offboarding_steps set title = 'x' where step = 'car'$$, 'a step''s wording stays');
select test.refused($$delete from public.offboarding_steps$$, 'steps are never deleted');
update public.offboardings set exit_notes = 'Would come back' ;
reset role;
select test.ok((select done_by = test.pid('boss@example.com') and done_at is not null from public.offboarding_steps where step = 'car'), 'ticking records who and when');
select test.ok((select count(*) from public.offboarding_steps where step like 'other_%') = 1, 'an added step is kept as "other"');
update public.profiles set active = false where email = 'sam@example.com';
select test.ok((select state from public.offboarding_steps where step = 'deactivate') = 'done', 'deactivating the account ticks that step');

-- Closing.
select test.act_as('boss@example.com');
set role authenticated;
update public.offboardings set status = 'completed';
select test.refused($$update public.offboardings set note = 'changed'$$, 'a closed offboarding stays as it was');
reset role;
select test.ok((select closed_by = test.pid('boss@example.com') from public.offboardings), 'closing records who');

\o
