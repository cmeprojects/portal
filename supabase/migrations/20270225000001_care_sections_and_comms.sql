-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 111; Care block C1 and C2; owner approved the Care
-- block without step approvals): My clients, section switches, communication
-- preferences, and who manages a new client.
--
--   * "My clients" (Your workspace): staff see their teams' and assigned
--     clients with approved locations and active alerts. No new access: the
--     page shows only what the existing rules already allow.
--   * Section switches (Care settings): each optional section can be turned
--     off for the organisation (data kept). On by default on Dev.
--   * Communication preferences (new part "Communication preferences",
--     normal): preferred contact, language, interpreter, accessibility needs,
--     notes. Managers: every client; Case Manager: assigned clients; Intake:
--     every client. Team staff read their teams' clients' preferences only
--     while "Team staff see communication preferences" is on.
--   * Assigned as can now also be "support coordinator" (owner: a new client
--     is given its care manager or support coordinator when it's added).
--   * Staff admins get nothing here (D-052).

insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order, actions) values
  ('workspace.my_clients', null, 'workspace', 'My clients', 'normal', false, 45, '{view}'),
  ('clients.comms', 'clients.list', 'clients', 'Communication preferences', 'normal', true, 258, '{view,edit}')
on conflict (id) do nothing;

insert into public.app_settings (key, value, label, description) values
  ('care.section_documents', 'true', 'Client documents', 'Show the Documents section on client pages. Turning it off hides it; nothing is deleted.'),
  ('care.section_care_plans', 'true', 'Assessments and care plans', 'Show the Care plans section on client pages. Turning it off hides it; nothing is deleted.'),
  ('care.section_reviews', 'true', 'Reviews and re-assessments', 'Show the Reviews section on client pages (and send review reminders). Turning it off hides it; nothing is deleted.'),
  ('care.section_agreements', 'true', 'Service agreements', 'Show the Service agreements section on client pages. Turning it off hides it; nothing is deleted.'),
  ('care.section_funding', 'true', 'Funding and budgets', 'Show the Funding section on client pages. Turning it off hides it; nothing is deleted.'),
  ('care.section_comms', 'true', 'Communication preferences', 'Show the Communication preferences section on client pages. Turning it off hides it; nothing is deleted.'),
  ('care.team_sees_comms', 'true', 'Team staff see communication preferences', 'Staff see the communication preferences of their teams'' clients (language, interpreter, how to contact).')
on conflict (key) do nothing;

alter table public.client_assignments drop constraint if exists client_assignments_assigned_as_check;
alter table public.client_assignments add constraint client_assignments_assigned_as_check
  check (assigned_as in ('case_manager', 'support_coordinator', 'intake', 'key_worker', 'other'));

create table if not exists public.client_comms (
  client_id uuid primary key references public.car_clients (id) on delete restrict,
  org_id uuid not null default public.default_org_id(),
  preferred_contact text not null default '' check (preferred_contact in ('', 'phone', 'sms', 'email', 'in_person', 'through_representative')),
  language text not null default '' check (length(language) <= 60),
  interpreter_needed boolean not null default false,
  accessibility_needs text not null default '' check (length(accessibility_needs) <= 1000),
  notes text not null default '' check (length(notes) <= 1000),
  updated_by uuid references public.profiles (id),
  updated_at timestamptz not null default now()
);
alter table public.client_comms enable row level security;

drop policy if exists "see communication preferences" on public.client_comms;
create policy "see communication preferences" on public.client_comms
  for select to authenticated
  using (((select public.can('clients.comms'::text, 'view'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
         or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
             and public.can('clients.comms'::text, 'view'::text, client_id))
         or ((select public.rule_on('care.team_sees_comms')) and (select public.is_member())
             and client_id in (select ct.client_id from public.client_teams ct
                                where ct.team_id in (select tm.team_id from public.team_members tm where tm.user_id = (select auth.uid())
                                                     union select tl.team_id from public.team_leaders tl where tl.user_id = (select auth.uid())))));
drop policy if exists "add communication preferences" on public.client_comms;
create policy "add communication preferences" on public.client_comms
  for insert to authenticated
  with check (((select public.can('clients.comms'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
              or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
                  and public.can('clients.comms'::text, 'edit'::text, client_id)));
drop policy if exists "change communication preferences" on public.client_comms;
create policy "change communication preferences" on public.client_comms
  for update to authenticated
  using (((select public.can('clients.comms'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
         or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
             and public.can('clients.comms'::text, 'edit'::text, client_id)))
  with check (((select public.can('clients.comms'::text, 'edit'::text, '00000000-0000-0000-0000-000000000000'::uuid)))
              or (client_id in (select a.client_id from public.client_assignments a where a.user_id = (select auth.uid()) and a.ended_at is null)
                  and public.can('clients.comms'::text, 'edit'::text, client_id)));
-- No delete rule.
grant select, insert, update on public.client_comms to authenticated;

-- Changes go in the change log (which part changed, never the values).
drop trigger if exists log_client_comms on public.client_comms;
create trigger log_client_comms before insert or update on public.client_comms
  for each row execute function public.log_client_change();

-- Switched over from the start, with defaults.
update public.app_modules set grant_ready = true where id = 'clients.comms' and not grant_ready;
do $$
declare
  v_cm uuid := (select id from public.job_titles where name = 'Case Manager' and active limit 1);
  v_io uuid := (select id from public.job_titles where name = 'Intake & Assessment Officer' and active limit 1);
begin
  if not exists (select 1 from public.access_baselines where module_id = 'clients.comms' and revoked_at is null) then
    insert into public.access_baselines (access_level, module_id, actions, scope, note)
    values ('manager', 'clients.comms', '{}', 'all', 'Care block default: managers, every client');
    if v_cm is not null then
      insert into public.access_baselines (job_title_id, module_id, actions, scope, note)
      values (v_cm, 'clients.comms', '{view,edit}', 'assigned', 'Care block default: case managers, assigned clients');
    end if;
    if v_io is not null then
      insert into public.access_baselines (job_title_id, module_id, actions, scope, note)
      values (v_io, 'clients.comms', '{view,edit}', 'all', 'Care block default: intake, every client');
    end if;
  end if;
end $$;
