-- Staff Portal · © cmeproject. All rights reserved.
--
-- Forms: a premium add-on; makers chosen by the system admin; only the maker
-- and people they share with change a form or see its replies; staff fill in
-- published forms (once, or many times); anonymous replies; sending and
-- reminders; a form as a Compliance item.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('boss2@example.com', 'Max', 'manager'), ('office@example.com', 'Olive', 'staff_admin'),
  ('sam@example.com', 'Sam', 'support_worker'), ('lee@example.com', 'Lee', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('boss2@example.com'), ('office@example.com'), ('sam@example.com'), ('lee@example.com');
insert into public.teams (name) values ('Team A');
insert into public.team_members (team_id, user_id) select t.id, p.id from public.teams t, public.profiles p where t.name = 'Team A' and p.email = 'sam@example.com';
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.form(p_title text) returns uuid language sql security definer as $$ select id from public.forms where title = p_title $$;
create function test.q(p_label text) returns uuid language sql security definer as $$ select id from public.form_questions where label = p_label $$;
create function test.notes(p_email text, p_kind text) returns bigint language sql security definer as $$
  select count(*) from public.notifications where user_id = test.pid(p_email) and kind = p_kind $$;
grant execute on all functions in schema test to authenticated;

-- Off until the system admin switches it on.
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.forms (title) values ('Staff survey')$$, 'Forms is off: no one can make forms');
reset role;
select test.act_as('owner@example.com');
update public.features set enabled = true, included = true where key = 'forms';

select test.act_as('office@example.com');
set role authenticated;
select test.refused($$insert into public.forms (title) values ('Staff survey')$$, 'staff admins can''t make forms unless ticked');
reset role;

select test.act_as('boss@example.com');
set role authenticated;
with f as (insert into public.forms (title, intro) values ('Staff survey', 'Tell us how it''s going') returning id)
select test.ok(count(*) = 1, 'a manager makes a form (and gets it straight back)') from f;
insert into public.form_questions (form_id, label, type, required, options, sort_order) values
  (test.form('Staff survey'), 'Happy at work?', 'yesno', true, '[]', 1),
  (test.form('Staff survey'), 'Best part', 'choice', false, '["Clients", "Team", "Pay"]', 2),
  (test.form('Staff survey'), 'Anything else', 'long', false, '[]', 3);
reset role;

-- A draft can't be filled in or seen by staff.
select test.act_as('sam@example.com');
set role authenticated;
select test.ok((select count(*) from public.forms) = 0, 'staff don''t see drafts');
select test.refused(format($$select public.submit_form_response(%L, '{}')$$, test.form('Staff survey')), 'or fill them in');
reset role;

-- Another manager can't touch it until it's shared.
select test.act_as('boss2@example.com');
set role authenticated;
select test.refused($$update public.forms set title = 'Mine now'$$, 'another manager can''t change it');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
insert into public.form_collaborators (form_id, user_id) values (test.form('Staff survey'), test.pid('boss2@example.com'));
update public.forms set status = 'published', published_at = now(), due_date = current_date + 7 where title = 'Staff survey';
reset role;
select test.act_as('boss2@example.com');
set role authenticated;
update public.forms set anonymous = true where title = 'Staff survey';
select test.ok((select anonymous from public.forms where title = 'Staff survey'), 'once shared, they can change it');
select test.refused($$insert into public.form_collaborators (form_id, user_id) select id, test.pid('office@example.com') from public.forms$$,
  'but only the maker shares it further');
select test.ok(public.send_form(test.form('Staff survey'), null, (select id from public.teams where name = 'Team A')) = 1, 'sent to a team');
reset role;
select test.ok(test.notes('sam@example.com', 'form_sent') = 1, 'Sam gets a bell note');
select test.ok(exists (select 1 from public.email_outbox where to_user = test.pid('sam@example.com') and data ->> 'title' = 'Please fill in: Staff survey'), 'and an email');

-- Sam fills it in: required answers, the list, a draft first, then send; once only.
select test.act_as('sam@example.com');
set role authenticated;
select test.refused(format($$select public.submit_form_response(%L, '{}')$$, test.form('Staff survey')), 'required questions must be answered');
select test.refused(format($$select public.submit_form_response(%L, jsonb_build_object(%L, 'Yes', %L, 'Holidays'))$$,
  test.form('Staff survey'), test.q('Happy at work?'), test.q('Best part')), 'choices come from the list');
select public.submit_form_response(test.form('Staff survey'), jsonb_build_object(test.q('Best part')::text, 'Team'), false);
select test.ok((select status = 'draft' and user_id = auth.uid() from public.form_responses), 'save and finish later keeps a draft');
select public.submit_form_response(test.form('Staff survey'), jsonb_build_object(test.q('Happy at work?')::text, 'Yes', test.q('Best part')::text, 'Team'), true, true);
select test.refused(format($$select public.submit_form_response(%L, jsonb_build_object(%L, 'No'))$$, test.form('Staff survey'), test.q('Happy at work?')),
  'a once-only form can''t be filled in twice');
reset role;
select test.ok((select count(*) = 1 and bool_and(user_id is null and status = 'submitted') from public.form_responses), 'Sam ticked Answer anonymously: the draft became a reply without their name');
select test.act_as('lee@example.com');
set role authenticated;
select public.submit_form_response(test.form('Staff survey'), jsonb_build_object(test.q('Happy at work?')::text, 'No'));
reset role;
select test.ok((select user_id = test.pid('lee@example.com') from public.form_responses where answers ->> test.q('Happy at work?')::text = 'No'),
  'Lee didn''t tick it: their name is kept');

select test.act_as('boss@example.com');
set role authenticated;
select test.ok((select count(*) from public.form_responses) = 2 and (select count(*) from public.form_completions) = 2,
  'the maker sees the replies and that Sam and Lee have done it');
select test.ok(public.remind_form(test.form('Staff survey')) = 0, 'no one left to remind');
reset role;
select test.act_as('lee@example.com');
set role authenticated;
select test.ok((select count(*) from public.form_responses) = 1, 'other staff only see their own reply');
reset role;
select test.act_as('office@example.com');
set role authenticated;
select test.ok((select count(*) from public.form_responses) = 0, 'nor do staff admins who aren''t sharing the form');
reset role;

-- Ticked staff admins can make forms; a form in Compliance counts when filled in.
select test.act_as('owner@example.com');
update public.app_settings set value = '["manager", "staff_admin"]' where key = 'forms.maker_roles';
select test.act_as('office@example.com');
set role authenticated;
insert into public.forms (title, repeatable) values ('Policy sign-off', false);
insert into public.form_questions (form_id, label, type, required, sort_order) values (test.form('Policy sign-off'), 'Signature', 'signature', true, 1);
update public.forms set status = 'published', published_at = now() where title = 'Policy sign-off';
select public.form_to_compliance(test.form('Policy sign-off'), '{support_worker}', '{}');
reset role;
select test.ok(public.onboarding_missing(test.pid('lee@example.com')) @> array['Policy sign-off'], 'it shows in Compliance as to do');
select test.act_as('lee@example.com');
set role authenticated;
select public.submit_form_response(test.form('Policy sign-off'), jsonb_build_object(test.q('Signature')::text, 'Lee Worker'));
reset role;
select test.ok(not (public.onboarding_missing(test.pid('lee@example.com')) @> array['Policy sign-off']), 'and is done once filled in');

-- Turned off: no more replies; deleting needs the maker or a collaborator.
select test.act_as('office@example.com');
set role authenticated;
update public.forms set enabled = false where title = 'Policy sign-off';
reset role;
select test.act_as('sam@example.com');
set role authenticated;
select test.refused(format($$select public.submit_form_response(%L, '{}')$$, test.form('Policy sign-off')), 'a turned-off form takes no replies');
reset role;
select test.act_as('boss2@example.com');
set role authenticated;
select test.refused($$delete from public.forms where title = 'Policy sign-off'$$, 'someone else can''t delete it');
reset role;

\o
\echo All forms tests passed.
