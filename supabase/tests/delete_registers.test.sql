-- Staff Portal · © cmeproject. All rights reserved.
--
-- Deleting registers: only unused ones, only by the people who can add them.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values ('boss@example.com', 'Morgan', 'manager'), ('sam@example.com', 'Sam', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('sam@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.reg(p_prefix text) returns uuid language sql security definer as $$ select id from public.registries where prefix = p_prefix $$;
grant execute on all functions in schema test to authenticated;
insert into public.registries (name, kind, prefix) values ('Spare register', 'tasks', 'SPR'), ('Used register', 'tasks', 'USE');

select test.act_as('boss@example.com');
set role authenticated;
select public.create_task('A real task', test.reg('USE'), test.pid('sam@example.com'));
reset role;

select test.act_as('sam@example.com');
set role authenticated;
select test.refused($$select public.delete_unused_registry(test.reg('SPR'))$$, 'a support worker can''t delete registers');
reset role;

select test.act_as('owner@example.com');
set role authenticated;
select test.refused($$select public.delete_unused_registry(test.reg('USE'))$$, 'a register that''s been used can''t be deleted');
select test.refused($$select public.delete_unused_registry((select id from public.registries where is_default))$$, 'General tasks can''t be deleted');
reset role;

select test.act_as('boss@example.com');
set role authenticated;
select public.delete_unused_registry(test.reg('SPR'));
reset role;
select test.ok(test.reg('SPR') is null, 'a manager (Adding registers) deletes an unused register');
select test.ok(test.reg('USE') is not null, 'the used one is still there');
select test.ok((select count(*) from public.audit_log where action = 'register_deleted') = 1, 'it''s in the change log');

\o
\echo All register deletion tests passed.
