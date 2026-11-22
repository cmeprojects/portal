-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 168): document templates (versions) and which version each document used.
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null
insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
grant execute on all functions in schema test to authenticated;
select test.act_as('owner@example.com');
set role authenticated;
insert into public.admin_designations (user_id, granted_by) values (test.pid('boss@example.com'), test.pid('owner@example.com'));
reset role;

select test.ok((select count(*) = 4 and bool_and(version = 1 and settings ->> 'layout' = 'full' and settings ->> 'colour_source' = 'theme') from public.document_templates), 'a starting template for each of the four documents: full layout, theme colours');
select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$insert into public.document_templates (kind, settings) values ('invoice', '{"layout":"compact"}')$$, 'a support worker can''t change templates');
select test.ok((select count(*) from public.document_templates) = 0, 'and can''t see them');
reset role;
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$insert into public.document_templates (kind, settings) values ('statement', '{"layout":"fancy"}')$$, 'the layout is full or compact');
select test.refused($$insert into public.document_templates (kind, settings) values ('statement', '{"colour_source":"custom","primary":"blue"}')$$, 'colours are written like #134F8E');
insert into public.document_templates (kind, settings, note) values ('statement', '{"layout":"compact","logo_position":"right","colour_source":"custom","primary":"#2E7D32","accent":"#A5D6A7","sections":{"away_note":false},"footer_text":"Thank you"}', 'Green, compact');
select test.refused($$update public.document_templates set settings = '{}' where kind = 'statement'$$, 'a template version never changes');
select test.refused($$delete from public.document_templates where kind = 'statement'$$, 'or is deleted');
insert into public.document_issues (kind, document_id, template_id, checksum) select 'statement', gen_random_uuid(), id, 'abc' from public.document_templates where kind = 'statement' and version = 2;
select test.refused($$update public.document_issues set checksum = 'x'$$, 'the record of which template a document used never changes');
reset role;
select test.ok((select version = 2 and created_by = test.pid('boss@example.com') from public.document_templates where kind = 'statement' order by version desc limit 1), 'saving made statement template version 2');
select test.ok((select template_version = 2 from public.document_issues), 'the issued statement records template version 2');
