-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 102): Due dates (SLA) and Request approvals follow can()
-- (Stage 3b). Nobody's access changes.

\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

insert into auth.users (email) values ('owner@example.com');
insert into public.invitations (email, full_name, role) values
  ('boss@example.com', 'Morgan', 'manager'), ('lead@example.com', 'Taylor', 'team_leader'),
  ('kim@example.com', 'Kim', 'support_worker'), ('ada@example.com', 'Ada', 'staff_admin');
insert into auth.users (email) values ('boss@example.com'), ('lead@example.com'), ('kim@example.com'), ('ada@example.com');
create function test.pid(p_email text) returns uuid language sql security definer as $$ select id from public.profiles where email = p_email $$;
create function test.sla_changed(p_email text) returns boolean language plpgsql as $$
declare n int;
begin
  perform test.act_as(p_email);
  execute 'set local role authenticated';
  update public.app_settings set value = value where key like 'tasks.sla%';
  get diagnostics n = row_count;
  execute 'reset role';
  return n > 0;
end $$;
grant execute on all functions in schema test to authenticated;

select test.ok((select legacy_kind = 'settings' and legacy_area = 'hr' from public.app_modules where id = 'workflows.request_rules'), 'Request approvals is part of the HR settings area');
select test.ok((select grant_ready from public.app_modules where id = 'workflows.sla'), 'Due dates is switched over');

-- Due dates: same as today.
select test.ok(test.sla_changed('owner@example.com'), 'system admin sets due dates');
select test.ok(test.sla_changed('boss@example.com'), 'manager sets due dates');
select test.ok(not test.sla_changed('ada@example.com'), 'staff admin doesn''t (without the Tasks settings area)');
select test.ok(not test.sla_changed('lead@example.com'), 'team leader doesn''t');

-- Request approvals: same answer as the HR settings area.
select test.act_as('boss@example.com');
select test.ok(public.can('workflows.request_rules', 'configure') = public.can_admin_area('hr'), 'Request approvals follows the HR settings area');
select test.act_as('owner@example.com');
select test.ok(public.can('workflows.request_rules', 'configure'), 'system admin has Request approvals');

-- Changed on the Access page now.
insert into public.job_titles (name, access_level) values ('Roster Clerk', 'support_worker');
update public.profiles set job_title_id = (select id from public.job_titles where name = 'Roster Clerk') where email = 'kim@example.com';
select set_config('request.jwt.claims', '', false);
insert into public.access_baselines (job_title_id, module_id, actions) values ((select id from public.job_titles where name = 'Roster Clerk'), 'workflows.sla', '{view,configure}');
select test.ok(test.sla_changed('kim@example.com'), 'a role (job title) given Due dates sets them');
select set_config('request.jwt.claims', '', false);
update public.access_baselines set revoked_at = now() where module_id = 'workflows.sla' and access_level = 'manager' and revoked_at is null;
select test.ok(not test.sla_changed('boss@example.com'), 'taken from managers on the Access page: they can''t');

\i supabase/live-updates/update-102.sql
\o /dev/null
select test.ok((select count(*) from public.access_baselines where module_id = 'workflows.sla' and access_level is not null and revoked_at is null) = 1, 'running it again re-adds the managers'' default only if none is live');

\o
