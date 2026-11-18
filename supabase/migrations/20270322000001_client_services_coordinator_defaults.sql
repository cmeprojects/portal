-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 136, AUD-016 Stage 5): default access for Client Services
-- Coordinator ("administrative client details, agreements and follow-ups"),
-- every client. View and change: details, contacts, locations,
-- agreements and comms. View only: the client list, services, safety alerts, reviews and funding.
-- Never: progress notes, documents, care plans, Allied Health access or
-- assigning staff or adding clients. Only added when the job title has no defaults yet, so the
-- owner's later changes on the Access page are kept. Safe to run again.

do $$
declare
  v_id uuid := (select id from public.job_titles where name = 'Client Services Coordinator' and access_level = 'support_worker');
begin
  if v_id is null or exists (select 1 from public.access_baselines where job_title_id = v_id and revoked_at is null) then
    return;
  end if;
  insert into public.access_baselines (job_title_id, module_id, actions, scope, note)
  select v_id, x.m, x.a, 'all', 'Stage 5 default: Client Services Coordinator'
    from (values
      ('clients.list', '{view}'::text[]),
      ('clients.details', '{view,edit}'::text[]),
      ('clients.people', '{view,edit}'::text[]),
      ('clients.locations', '{view,edit}'::text[]),
      ('clients.agreements', '{view,edit}'::text[]),
      ('clients.comms', '{view,edit}'::text[]),
      ('clients.services', '{view}'::text[]),
      ('clients.alerts', '{view}'::text[]),
      ('clients.reviews', '{view}'::text[]),
      ('clients.funding', '{view}'::text[])
    ) as x(m, a)
   where exists (select 1 from public.app_modules where id = x.m);
end $$;
