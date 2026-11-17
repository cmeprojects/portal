-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 117: takes back the extra defaults and restores the Care block
-- defaults they replaced. Safe to run again.
begin;
update public.access_baselines set revoked_at = now()
 where note = 'Update 117: owner chose more default access for this role' and revoked_at is null;
do $$
declare
  v_cm uuid := (select id from public.job_titles where name = 'Case Manager' and active limit 1);
  v_io uuid := (select id from public.job_titles where name = 'Intake & Assessment Officer' and active limit 1);
  g record;
begin
  for g in
    select * from (values
      (v_cm, 'clients.funding', '{view}'::text[], 'assigned', 'Care block default: case managers, assigned clients, view'),
      (v_cm, 'clients.agreements', '{view}'::text[], 'assigned', 'Care block default: case managers, assigned clients, view'),
      (v_io, 'clients.services', '{view}'::text[], 'all', 'Intake: every client')
    ) as t(title_id, module_id, actions, scope, note)
  loop
    continue when g.title_id is null;
    continue when exists (select 1 from public.access_baselines b where b.job_title_id = g.title_id and b.module_id = g.module_id and b.revoked_at is null);
    insert into public.access_baselines (job_title_id, module_id, actions, scope, note) values (g.title_id, g.module_id, g.actions, g.scope, g.note);
  end loop;
end $$;
commit;
