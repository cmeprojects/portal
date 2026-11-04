-- Staff Portal · © cmeproject. All rights reserved.
--
-- Settings revamp (cmeprojects):
--   1. Feature parts: Teams, Roles, Form builder and the Compliance parts can
--      be switched off on their own. A part only works while its feature is on.
--   2. Delegation per area: only the system admin, all managers, or selected
--      managers and staff admins. Today's delegations carry over.
--      New areas: adding registers, and roles (job titles).
--   3. Save, then deploy: settings, feature switches and delegation are
--      saved as drafts and go live together when deployed.
--   4. Notifications: bell and email can be switched off per notification,
--      and nothing is sent for a feature that's off.
--   5. The website is the front page only while the Assistant is on.
-- Everything starts at today's behaviour.

-- ---------------------------------------------------------------------------
-- 1. Feature parts
-- ---------------------------------------------------------------------------

alter table public.features add column if not exists parent text references public.features (key);

insert into public.features (key, label, description, enabled, sort_order, premium, included, parent) values
  ('teams', 'Teams', 'Teams and team leaders. Off: team leaders work like support workers; teams are kept.', true, 300, false, true, null),
  ('roles', 'Roles (job titles)', 'Job titles linked to access levels. Off: people get an access level only; job titles are kept.', true, 301, false, true, null),
  ('form_builder', 'Form builder', 'Making and changing forms. Off: published forms still work and can be filled in.', true, 310, false, true, 'forms'),
  ('compliance_read', 'Read and confirm', 'Documents staff read and confirm.', true, 320, false, true, 'compliance'),
  ('compliance_training', 'Trainings', 'Trainings staff complete.', true, 321, false, true, 'compliance'),
  ('compliance_upload', 'Documents to upload', 'Certificates and checks staff upload, with expiry dates.', true, 322, false, true, 'compliance'),
  ('compliance_forms', 'Forms in onboarding', 'Forms that are part of onboarding (needs Forms on too).', true, 323, false, true, 'compliance')
on conflict (key) do nothing;

-- A feature works if it's on and included, and so is the feature it's part of.
create or replace function public.feature_enabled(p_key text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((
    select f.enabled and f.included
       and (f.parent is null or coalesce((select p.enabled and p.included from public.features p where p.key = f.parent), false))
      from public.features f
     where f.key = p_key
  ), false)
$$;

-- Compliance items only count while their part is on (so a switched-off part
-- never holds up anyone's onboarding).
create or replace function public.compliance_applies(p_item public.compliance_items, p_role public.app_role, p_teams uuid[])
returns boolean
language sql
stable
set search_path = ''
as $$
  select p_item.active
     and public.feature_enabled(case p_item.kind when 'form' then 'compliance_forms' else 'compliance_' || p_item.kind end)
     and (p_item.kind <> 'form' or public.feature_enabled('forms'))
     and (cardinality(p_item.applies_roles) = 0 or p_role = any (p_item.applies_roles))
     and (cardinality(p_item.applies_teams) = 0 or p_item.applies_teams && coalesce(p_teams, '{}'))
$$;

-- Teams off: team leaders don't see their team's work (they work like support workers).
create or replace function public.leads_user(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.feature_enabled('teams') and exists (
    select 1
      from public.team_leaders tl
      join public.team_members m on m.team_id = tl.team_id
     where tl.user_id = auth.uid()
       and m.user_id = p_user_id
  ) and public.has_role(array['team_leader', 'manager', 'system_admin']::public.app_role[])
$$;

-- Form builder off: only the system admin makes forms (published ones still work).
create or replace function public.can_make_forms()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and public.feature_enabled('forms')
     and (public.is_system_admin()
          or (public.feature_enabled('form_builder')
              and public.my_role()::text in (select jsonb_array_elements_text(coalesce(
                    (select value from public.app_settings where key = 'forms.maker_roles'), '[]')))))
$$;

-- ---------------------------------------------------------------------------
-- 2. Delegation per area
-- ---------------------------------------------------------------------------

create table if not exists public.delegation_rules (
  area       text primary key
             check (area in ('branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'website', 'audit', 'registers', 'roles')),
  -- admin: only the system admin. managers: every manager. selected: the people listed (managers or staff admins).
  mode       text not null default 'admin' check (mode in ('admin', 'managers', 'selected')),
  people     uuid[] not null default '{}',
  updated_by uuid references public.profiles (id),
  updated_at timestamptz not null default now()
);

alter table public.delegation_rules enable row level security;
drop policy if exists "members read delegation" on public.delegation_rules;
create policy "members read delegation" on public.delegation_rules
  for select to authenticated using (public.is_member());
revoke insert, update, delete, truncate on public.delegation_rules from anon, authenticated;

-- Carry over today's delegations (named managers per area).
insert into public.delegation_rules (area, mode, people)
select a.area,
       case when count(d.user_id) > 0 then 'selected' else 'admin' end,
       coalesce(array_agg(d.user_id) filter (where d.user_id is not null), '{}')
  from unnest(array['branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'website', 'audit']) as a(area)
  left join public.admin_delegations d on a.area = any (d.areas)
 group by a.area
on conflict (area) do nothing;

-- Today every manager adds registers and job titles: keep that.
insert into public.delegation_rules (area, mode) values ('registers', 'managers'), ('roles', 'managers')
on conflict (area) do nothing;

-- Can the signed-in person look after this area?
create or replace function public.can_admin_area(p_area text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.mfa_ok() and (
    public.is_system_admin()
    or (p_area is not null and exists (
      select 1
        from public.delegation_rules r
        join public.profiles p on p.id = auth.uid()
       where r.area = p_area
         and p.active
         and ((r.mode = 'managers' and p.role = 'manager')
              or (r.mode = 'selected' and p.id = any (r.people) and p.role in ('manager', 'staff_admin')))
    ))
  )
$$;

-- The areas the signed-in person looks after.
create or replace function public.my_admin_areas()
returns text[]
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(array_agg(r.area order by r.area), '{}')
    from public.delegation_rules r
   where public.can_admin_area(r.area)
$$;

-- The older per-manager call still works: it now updates the per-area rules.
create or replace function public.set_delegation(p_user_id uuid, p_areas text[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_areas text[] := coalesce((select array_agg(distinct a order by a) from unnest(coalesce(p_areas, '{}')) a), '{}');
begin
  if not public.is_system_admin() or not public.mfa_ok() then
    raise exception 'Only the system admin delegates';
  end if;
  if cardinality(v_areas) > 0
     and not exists (select 1 from public.profiles where id = p_user_id and role in ('manager', 'staff_admin') and active) then
    raise exception 'Only active managers and staff admins can be given areas to look after';
  end if;
  if exists (select 1 from unnest(v_areas) a where a not in (select area from public.delegation_rules)) then
    raise exception 'That area can''t be delegated';
  end if;
  update public.delegation_rules r
     set people = array_append(array_remove(r.people, p_user_id), p_user_id),
         mode = case when r.mode = 'managers' then 'managers' else 'selected' end,
         updated_by = auth.uid(), updated_at = now()
   where r.area = any (v_areas);
  update public.delegation_rules r
     set people = array_remove(r.people, p_user_id),
         mode = case when r.mode = 'selected' and cardinality(array_remove(r.people, p_user_id)) = 0 then 'admin' else r.mode end,
         updated_by = auth.uid(), updated_at = now()
   where not (r.area = any (v_areas)) and p_user_id = any (r.people);
  perform public.write_audit('delegation_changed', 'profile', p_user_id::text, jsonb_build_object('areas', to_jsonb(v_areas)));
end;
$$;

-- Adding registers and job titles follow their delegation.
drop policy if exists "managers create registries" on public.registries;
drop policy if exists "delegated people create registries" on public.registries;
create policy "delegated people create registries" on public.registries
  for insert to authenticated with check (public.can_admin_area('registers'));

drop policy if exists "managers add job titles" on public.job_titles;
drop policy if exists "managers change job titles" on public.job_titles;
drop policy if exists "delegated people add job titles" on public.job_titles;
drop policy if exists "delegated people change job titles" on public.job_titles;
create policy "delegated people add job titles" on public.job_titles
  for insert to authenticated with check (public.can_admin_area('roles'));
create policy "delegated people change job titles" on public.job_titles
  for update to authenticated using (public.can_admin_area('roles')) with check (public.can_admin_area('roles'));

-- ---------------------------------------------------------------------------
-- 3. Save, then deploy
-- ---------------------------------------------------------------------------

create table if not exists public.settings_drafts (
  kind     text not null check (kind in ('setting', 'feature', 'delegation', 'website')),
  key      text not null,
  value    jsonb not null,
  saved_by uuid not null references public.profiles (id) on delete cascade,
  saved_at timestamptz not null default now(),
  primary key (kind, key)
);

alter table public.settings_drafts enable row level security;
drop policy if exists "see your drafts, the system admin sees all" on public.settings_drafts;
create policy "see your drafts, the system admin sees all" on public.settings_drafts
  for select to authenticated using (public.is_system_admin() or saved_by = auth.uid());
revoke insert, update, delete, truncate on public.settings_drafts from anon, authenticated;

-- May the signed-in person change this?
create or replace function public.may_change(p_kind text, p_key text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case p_kind
    when 'setting' then public.can_admin_area(public.setting_area(p_key))
                        or (p_key like 'tasks.sla%' and public.my_role() = 'manager' and public.mfa_ok())
                        or (public.is_system_admin() and public.mfa_ok())
    -- Website settings: the system admin; "where it looks for answers" can be delegated.
    when 'website' then (public.is_system_admin() and public.mfa_ok()) or (p_key = 'answers' and public.can_admin_area('website'))
    else public.is_system_admin() and public.mfa_ok()
  end
$$;

-- The live value of something, in the same shape as its draft.
create or replace function public.live_value(p_kind text, p_key text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select case p_kind
    when 'setting' then (select value from public.app_settings where key = p_key)
    when 'feature' then (select jsonb_build_object('enabled', enabled) from public.features where key = p_key)
    when 'delegation' then (select jsonb_build_object('mode', mode, 'people', to_jsonb(people)) from public.delegation_rules where area = p_key)
  end
$$;

-- Save a change as a draft. Saving the live value again removes the draft.
-- Returns 'saved' or 'unchanged'.
create or replace function public.save_draft(p_kind text, p_key text, p_value jsonb)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_live jsonb;
  v_value jsonb := p_value;
begin
  if p_kind = 'website' then
    -- A part of Website settings: only real columns, compared with what's live.
    if p_key not in ('landing', 'answers', 'limits') or jsonb_typeof(p_value) <> 'object' or exists (
      select 1 from jsonb_object_keys(p_value) k
       where k in ('id', 'updated_at')
          or k not in (select column_name::text from information_schema.columns where table_schema = 'public' and table_name = 'assistant_settings')
    ) then
      raise exception 'Something went wrong. Please refresh and try again.';
    end if;
    select jsonb_object_agg(k, to_jsonb(s) -> k) into v_live
      from public.assistant_settings s, jsonb_object_keys(p_value) k
     where s.id;
  else
    v_live := public.live_value(p_kind, p_key);
  end if;
  if not public.may_change(p_kind, p_key) then
    raise exception 'You don''t have permission to change this.';
  end if;
  if v_live is null then
    raise exception 'This setting doesn''t exist.';
  end if;
  if p_kind = 'feature' then
    if jsonb_typeof(p_value -> 'enabled') <> 'boolean' then
      raise exception 'Choose on or off.';
    end if;
    v_value := jsonb_build_object('enabled', p_value -> 'enabled');
  elsif p_kind = 'delegation' then
    if coalesce(p_value ->> 'mode', '') not in ('admin', 'managers', 'selected') then
      raise exception 'Choose who looks after it.';
    end if;
    v_value := jsonb_build_object(
      'mode', p_value ->> 'mode',
      'people', coalesce((
        select jsonb_agg(p.id order by p.full_name)
          from public.profiles p
         where p.active and p.role in ('manager', 'staff_admin')
           and p.id::text in (select jsonb_array_elements_text(coalesce(p_value -> 'people', '[]')))
      ), '[]'));
    if v_value ->> 'mode' = 'selected' and jsonb_array_length(v_value -> 'people') = 0 then
      raise exception 'Choose at least one manager or staff admin.';
    end if;
    if v_value ->> 'mode' <> 'selected' then
      v_value := jsonb_set(v_value, '{people}', '[]');
    end if;
  end if;

  if v_value = v_live then
    delete from public.settings_drafts where kind = p_kind and key = p_key;
    return 'unchanged';
  end if;
  insert into public.settings_drafts (kind, key, value, saved_by)
  values (p_kind, p_key, v_value, auth.uid())
  on conflict (kind, key) do update set value = excluded.value, saved_by = excluded.saved_by, saved_at = now();
  return 'saved';
end;
$$;

-- Make saved changes live: everyone's for the system admin, your own for others.
create or replace function public.deploy_drafts()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  d record;
  v_count integer := 0;
  v_enabled boolean;
  v_col text;
begin
  if auth.uid() is null then
    raise exception 'Please sign in first.';
  end if;
  for d in
    select * from public.settings_drafts
     where public.is_system_admin() or saved_by = auth.uid()
     order by case kind when 'feature' then 1 when 'setting' then 2 when 'website' then 3 else 4 end, key
     for update
  loop
    if not public.may_change(d.kind, d.key) then
      continue;
    end if;
    if d.kind = 'setting' then
      update public.app_settings set value = d.value, updated_at = now(), updated_by = auth.uid() where key = d.key;
    elsif d.kind = 'feature' then
      v_enabled := (d.value ->> 'enabled')::boolean;
      update public.features
         set enabled = v_enabled,
             included = case when v_enabled and premium then true else included end,
             updated_at = now(), updated_by = auth.uid()
       where key = d.key;
    elsif d.kind = 'website' then
      for v_col in select jsonb_object_keys(d.value) loop
        execute format('update public.assistant_settings set %I = (jsonb_populate_record(null::public.assistant_settings, $1)).%I where id', v_col, v_col)
          using d.value;
      end loop;
      perform public.write_audit('website_settings_changed', 'website', d.key, '{}'::jsonb);
    else
      update public.delegation_rules
         set mode = d.value ->> 'mode',
             people = coalesce((select array_agg(x::uuid) from jsonb_array_elements_text(d.value -> 'people') x), '{}'),
             updated_by = auth.uid(), updated_at = now()
       where area = d.key;
      perform public.write_audit('delegation_changed', 'area', d.key, d.value);
    end if;
    delete from public.settings_drafts where kind = d.kind and key = d.key;
    v_count := v_count + 1;
  end loop;
  if v_count > 0 then
    perform public.write_audit('settings_deployed', 'settings', 'deploy', jsonb_build_object('changes', v_count));
  end if;
  return v_count;
end;
$$;

-- Throw away saved changes: everyone's for the system admin, your own for others.
create or replace function public.discard_drafts()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer;
begin
  delete from public.settings_drafts where public.is_system_admin() or saved_by = auth.uid();
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. Notifications: bell and email per notification
-- ---------------------------------------------------------------------------

insert into public.app_settings (key, value, label, description) values
  ('notify.channels', '{}', 'Notifications', 'Bell and email for each notification. Anything not listed is on.')
on conflict (key) do nothing;

-- Which feature a notification belongs to (null: always allowed).
create or replace function public.notification_feature(p_code text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when p_code like 'car\_%' then 'vehicles'
    when p_code like 'form\_%' then 'forms'
    when p_code in ('document_expiring', 'document_expired', 'onboarding_item', 'upload_submitted', 'upload_rejected', 'uploaded_for_you', 'onboarded') then 'compliance'
    when p_code = 'website_enquiry' then 'assistant'
    else null
  end
$$;

-- Is this channel on for this notification? (Anything not set is on.)
create or replace function public.notification_on(p_code text, p_channel text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (public.notification_feature(p_code) is null or public.feature_enabled(public.notification_feature(p_code)))
     and coalesce(((select value from public.app_settings where key = 'notify.channels') -> p_code ->> p_channel)::boolean, true)
$$;

create or replace function public.filter_notification()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.notification_on(new.kind, 'bell') then
    return null;
  end if;
  return new;
end;
$$;

drop trigger if exists notifications_filter on public.notifications;
create trigger notifications_filter
  before insert on public.notifications
  for each row execute function public.filter_notification();

create or replace function public.filter_email()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.notification_on(case when new.template = 'notice' then coalesce(new.data ->> 'kind', 'notice') else new.template end, 'email') then
    return null;
  end if;
  return new;
end;
$$;

drop trigger if exists email_outbox_filter on public.email_outbox;
create trigger email_outbox_filter
  before insert on public.email_outbox
  for each row execute function public.filter_email();

-- notify() also records which notification an email is, so it can be filtered.
create or replace function public.notify(p_user uuid, p_kind text, p_title text, p_body text, p_href text, p_email boolean default false)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_user is null or not exists (select 1 from public.profiles where id = p_user and active) then
    return;
  end if;
  insert into public.notifications (user_id, kind, title, body, href)
  values (p_user, p_kind, p_title, coalesce(p_body, ''), coalesce(p_href, '/'));
  if p_email and public.feature_enabled('email_notifications') then
    insert into public.email_outbox (to_user, template, data)
    values (p_user, 'notice', jsonb_build_object('title', p_title, 'body', coalesce(p_body, ''), 'href', coalesce(p_href, '/'), 'kind', p_kind));
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- 5. The website is the front page only while the Assistant is on
-- ---------------------------------------------------------------------------

create or replace function public.website_front_page()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.feature_enabled('assistant')
     and coalesce((select value = 'true'::jsonb from public.app_settings where key = 'website.front_page'), false)
$$;

-- ---------------------------------------------------------------------------
-- Permissions
-- ---------------------------------------------------------------------------

revoke execute on function public.my_admin_areas() from public, anon;
revoke execute on function public.may_change(text, text) from public, anon;
revoke execute on function public.live_value(text, text) from public, anon, authenticated;
revoke execute on function public.save_draft(text, text, jsonb) from public, anon;
revoke execute on function public.deploy_drafts() from public, anon;
revoke execute on function public.discard_drafts() from public, anon;
revoke execute on function public.notification_on(text, text) from public, anon, authenticated;
revoke execute on function public.filter_notification() from public, anon, authenticated;
revoke execute on function public.filter_email() from public, anon, authenticated;
grant execute on function public.my_admin_areas() to authenticated;
grant execute on function public.may_change(text, text) to authenticated;
grant execute on function public.save_draft(text, text, jsonb) to authenticated;
grant execute on function public.deploy_drafts() to authenticated;
grant execute on function public.discard_drafts() to authenticated;
grant execute on function public.website_front_page() to anon, authenticated;
