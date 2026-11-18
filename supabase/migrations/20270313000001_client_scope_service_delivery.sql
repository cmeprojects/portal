-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects (update 127, AUD-016 Stage 5, owner instruction §6.4 and §12):
-- Service Delivery staff see the client list entry (name, preferred name,
-- reference, status) of the clients they work with, through the existing
-- permission engine. Nothing else is added: client details, care plans,
-- funding, agreements and documents stay as they were.
--   * Support Worker: clients they're assigned to (scope "assigned").
--   * Team Leader: their team's clients (scope "own_teams").
-- Safe to run again.
do $$
declare
  v_sw uuid := (select id from public.job_titles where name = 'Support Worker' and access_level = 'support_worker' and active limit 1);
  v_tl uuid := (select id from public.job_titles where name = 'Team Leader' and access_level = 'team_leader' and active limit 1);
begin
  if v_sw is not null and not exists (select 1 from public.access_baselines where job_title_id = v_sw and module_id = 'clients.list' and revoked_at is null) then
    insert into public.access_baselines (job_title_id, module_id, actions, scope, note)
    values (v_sw, 'clients.list', '{view}', 'assigned', 'AUD-016 Stage 5: support workers, their assigned clients (list entry only)');
  end if;
  if v_tl is not null and not exists (select 1 from public.access_baselines where job_title_id = v_tl and module_id = 'clients.list' and revoked_at is null) then
    insert into public.access_baselines (job_title_id, module_id, actions, scope, note)
    values (v_tl, 'clients.list', '{view}', 'own_teams', 'AUD-016 Stage 5: team leaders, their team''s clients (list entry only)');
  end if;
end $$;
