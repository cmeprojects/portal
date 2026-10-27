-- Staff Portal · © cmeproject. All rights reserved.
--
-- The bell: newly given tasks, cleared by opening them.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker');
insert into auth.users (email) values ('sam@example.com'), ('kim@example.com');

create function test.pid(p_email text) returns uuid language sql as $$ select id from public.profiles where email = p_email $$;
create function test.count_new(p_email text) returns bigint language plpgsql as $$
declare n bigint;
begin
  perform test.act_as(p_email);
  set local role authenticated;
  select count(*) into n from public.my_new_tasks();
  reset role;
  return n;
end $$;
grant execute on all functions in schema test to authenticated;

select test.act_as('kim@example.com');
set role authenticated;
select public.create_task('For Sam', (select id from public.registries where prefix = 'GEN'), test.pid('sam@example.com'));
select public.create_task('Kim''s own', (select id from public.registries where prefix = 'GEN'), test.pid('kim@example.com'),
  p_helpers => array[test.pid('sam@example.com')]);
reset role;

select test.ok(test.count_new('sam@example.com') = 2, 'Sam has two new tasks (one to look after, one to help on)');
select test.ok(test.count_new('kim@example.com') = 0, 'nothing is new for the person who created them');

select test.act_as('sam@example.com');
set role authenticated;
select public.mark_task_seen((select id from public.tasks where title = 'For Sam'));
select test.refused($$insert into public.task_views (task_id, user_id) values ((select id from public.tasks limit 1), test.pid('kim@example.com'))$$,
  'nobody can write views for someone else');
reset role;
select test.ok(test.count_new('sam@example.com') = 1, 'opening a task clears it from the bell');

select test.act_as('sam@example.com');
set role authenticated;
select public.mark_all_tasks_seen();
reset role;
select test.ok(test.count_new('sam@example.com') = 0, 'mark all as seen clears the bell');

\o
\echo 'All notification tests passed.'
