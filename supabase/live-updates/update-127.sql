-- Staff Portal · © cmeproject. All rights reserved.
-- Update 127 (AUD-016 Stage 5): support workers see the list entry (name,
-- status) of their assigned clients; team leaders of their team's clients.
-- Nothing else changes. Safe to run again. Undo: undo-127.sql. Run 126 first.
begin;
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
commit;
