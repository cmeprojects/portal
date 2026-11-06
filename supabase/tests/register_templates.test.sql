-- Staff Portal · © cmeproject. All rights reserved.
--
-- Register templates: the library, adding one, and who may.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com');
grant execute on all functions in schema test to authenticated;

select test.ok((select count(*) from public.register_templates) = 8, 'the library has 8 standard registers');

select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$select public.add_register_from_template('incidents')$$, 'a support worker can''t add registers');
reset role;

select test.act_as('owner@example.com');
set role authenticated;
select test.ok(public.add_register_from_template('incidents') is not null, 'the system admin adds the Incident Register');
select test.refused($$select public.add_register_from_template('incidents')$$, 'but not twice');
reset role;
select test.ok((select count(*) from public.registry_fields f join public.registries r on r.id = f.registry_id where r.prefix = 'INC') = 6, 'with all its fields');
select test.ok((select option_colors ->> 'Extreme' from public.registry_fields f join public.registries r on r.id = f.registry_id where r.prefix = 'INC' and f.key = 'severity') = 'red', 'and its colours');

-- Managers can add registers by default (Adding registers: all managers).
-- (The test copy already has an Asset Register from a company file: remove it first.)
select test.act_as('boss@example.com');
set role authenticated;
select test.refused($$select public.add_register_from_template('assets')$$, 'a register already there isn''t added again');
reset role;
delete from public.registry_fields where registry_id = (select id from public.registries where prefix = 'AST');
delete from public.registry_managers where registry_id = (select id from public.registries where prefix = 'AST');
delete from public.registries where prefix = 'AST';
select test.act_as('boss@example.com');
set role authenticated;
select test.ok(public.add_register_from_template('assets') is not null, 'a manager adds the Asset Register');
reset role;
select test.ok((select kind from public.registries where prefix = 'AST') = 'records', 'as a list of records');

\o
\echo All register template tests passed.
