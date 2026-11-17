-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 103): Tasks switched over to can() with a faster task
-- check (Stage 3b). Who sees which task is unchanged.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('lead@example.com', 'Taylor', 'team_leader'),
  ('sam@example.com', 'Sam', 'support_worker'), ('kim@example.com', 'Kim', 'support_worker'),
  ('ada@example.com', 'Ada', 'staff_admin'), ('hel@example.com', 'Hel', 'support_worker');
insert into auth.users (email) values ('boss@example.com'), ('lead@example.com'), ('sam@example.com'), ('kim@example.com'), ('ada@example.com'), ('hel@example.com');
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
insert into public.teams (name) values ('North'), ('South');
insert into public.team_leaders (team_id, user_id) select id, test.pid('lead@example.com') from public.teams where name = 'North';
insert into public.team_members (team_id, user_id) select id, test.pid('sam@example.com') from public.teams where name = 'North';
insert into public.team_members (team_id, user_id) select id, test.pid('kim@example.com') from public.teams where name = 'South';
set session_replication_role = replica;
insert into public.tasks (title, registry_id, ref_number, assigned_to, created_by)
select x.t, (select id from public.registries order by name limit 1), 900000 + x.n, x.a, x.c
  from (values (1, 'Sam''s task', test.pid('sam@example.com'), test.pid('boss@example.com')),
               (2, 'Kim''s task', test.pid('kim@example.com'), test.pid('boss@example.com')),
               (3, 'Made by Kim', test.pid('boss@example.com'), test.pid('kim@example.com'))) x(n, t, a, c);
insert into public.task_helpers (task_id, user_id) select id, test.pid('hel@example.com') from public.tasks where title = 'Kim''s task';
insert into public.task_events (task_id, actor_id, type) select id, test.pid('boss@example.com'), 'comment' from public.tasks;
set session_replication_role = origin;

select test.ok((select grant_ready from public.app_modules where id = 'ops.tasks'), 'Tasks is switched over');
select test.ok((select string_agg(access_level::text, ',') from public.access_baselines where module_id = 'ops.tasks' and revoked_at is null and by_system_admin) = 'manager', 'managers see every task by default');

-- Same as today.
select test.ok(test.n('owner@example.com', '(select count(*) from public.tasks)') = 3, 'system admin sees every task');
select test.ok(test.n('boss@example.com', '(select count(*) from public.tasks)') = 3, 'manager sees every task');
select test.ok(test.n('ada@example.com', '(select count(*) from public.tasks)') = 0, 'staff admin sees only their own (none)');
select test.ok(test.n('sam@example.com', '(select count(*) from public.tasks)') = 1, 'support worker sees tasks given to them');
select test.ok(test.n('kim@example.com', '(select count(*) from public.tasks)') = 2, 'and tasks they made');
select test.ok(test.n('hel@example.com', '(select count(*) from public.tasks)') = 1, 'and tasks they help on');
select test.ok(test.n('lead@example.com', '(select count(*) from public.tasks)') = 1, 'team leader sees their team''s tasks only');
select test.ok(test.n('sam@example.com', '(select count(*) from public.task_events)') = 1, 'the timeline follows the task');
select test.ok(test.n('boss@example.com', '(select count(*) from public.task_events)') = 3, 'manager sees every timeline');
select test.act_as('sam@example.com');
select test.ok(public.can_see_task((select id from public.tasks where title = 'Sam''s task')) and not public.can_see_task((select id from public.tasks where title = 'Kim''s task')), 'the one-task check agrees');

-- Teams off: team leaders lose the team view (as before).
update public.features set enabled = false where key = 'teams';
select test.ok(test.n('lead@example.com', '(select count(*) from public.tasks)') = 0, 'teams off: team leader sees only their own');
update public.features set enabled = true where key = 'teams';

-- Changed on the Access page now.
insert into public.job_titles (name, access_level) values ('Operations Officer', 'staff_admin');
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Operations Officer') where email = 'ada@example.com';
select set_config('request.jwt.claims', '', false);
insert into public.access_baselines (job_title_id, module_id, actions) values ((select id from public.job_titles where name = 'Operations Officer'), 'ops.tasks', '{view}');
select test.ok(test.n('ada@example.com', '(select count(*) from public.tasks)') = 3, 'a role (job title) given Tasks sees every task');
select test.act_as('ada@example.com');
select test.ok(public.can_see_task((select id from public.tasks where title = 'Kim''s task')), 'and the one-task check agrees');
select set_config('request.jwt.claims', '', false);
update public.access_baselines set revoked_at = now() where module_id = 'ops.tasks' and access_level = 'manager' and revoked_at is null;
select test.ok(test.n('boss@example.com', '(select count(*) from public.tasks)') = 3, 'taken from managers: they still see tasks they made');
select test.ok(test.n('boss@example.com', $$(select count(*) from public.tasks where created_by <> test.pid('boss@example.com') and assigned_to <> test.pid('boss@example.com'))$$) = 0, 'but no longer everyone else''s');

\i supabase/live-updates/update-103.sql
\o /dev/null
select test.ok((select count(*) from public.access_baselines where module_id = 'ops.tasks' and access_level is not null and revoked_at is null) = 1, 'running it again re-adds the default only if none is live');

\o
