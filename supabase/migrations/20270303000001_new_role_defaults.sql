-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 117; owner chose these on 17 Nov 2026): more default
-- access for the Case Manager, Intake & Assessment Officer and Payroll &
-- Rostering job titles. Everything stays changeable on the Access page.
--
--   * Case Manager (their assigned clients): change funding (update what's
--     been used) and service agreements; view the compliance report.
--   * Intake & Assessment Officer (every client): view and add funding, view
--     reviews and re-assessments, change services.
--   * Payroll & Rostering (every client, view only): the client list,
--     approved locations, services, safety alerts and funding. (The staff
--     onboarding expiry list waits for a decision: today only people who
--     manage onboarding can read other staff's check records.)
--   * Nobody else changes. Staff admins still get nothing for clients (D-052).

do $$
declare
  v_cm uuid := (select id from public.job_titles where name = 'Case Manager' and active limit 1);
  v_io uuid := (select id from public.job_titles where name = 'Intake & Assessment Officer' and active limit 1);
  v_pr uuid := (select id from public.job_titles where name = 'Payroll & Rostering' and active limit 1);
  g record;
begin
  for g in
    select * from (values
      (v_cm, 'clients.funding', '{view,edit}'::text[], 'assigned'),
      (v_cm, 'clients.agreements', '{view,edit}'::text[], 'assigned'),
      (v_cm, 'insights.reports.compliance', '{view}'::text[], 'all'),
      (v_io, 'clients.funding', '{view,edit}'::text[], 'all'),
      (v_io, 'clients.reviews', '{view}'::text[], 'all'),
      (v_io, 'clients.services', '{view,edit}'::text[], 'all'),
      (v_pr, 'clients.list', '{view}'::text[], 'all'),
      (v_pr, 'clients.locations', '{view}'::text[], 'all'),
      (v_pr, 'clients.services', '{view}'::text[], 'all'),
      (v_pr, 'clients.alerts', '{view}'::text[], 'all'),
      (v_pr, 'clients.funding', '{view}'::text[], 'all')
    ) as t(title_id, module_id, actions, scope)
  loop
    continue when g.title_id is null;
    -- Already given exactly this (for example on a second run): nothing to do.
    continue when exists (select 1 from public.access_baselines b
                           where b.job_title_id = g.title_id and b.module_id = g.module_id and b.revoked_at is null
                             and b.actions @> g.actions and b.actions <@ g.actions and b.scope = g.scope);
    -- Replace the narrower default (kept for history, marked revoked).
    update public.access_baselines set revoked_at = now()
     where job_title_id = g.title_id and module_id = g.module_id and revoked_at is null;
    insert into public.access_baselines (job_title_id, module_id, actions, scope, note)
    values (g.title_id, g.module_id, g.actions, g.scope, 'Update 117: owner chose more default access for this role');
  end loop;
end $$;
