-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 46: back to the settings as they were after update 45.
-- Saved drafts and the new delegation choices are removed; today's named
-- managers keep their areas. Safe to run again.
begin;

-- The rules as they were.
create or replace function public.can_admin_area(p_area text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.mfa_ok() and (
    public.is_system_admin()
    or (p_area is not null and public.my_role() = 'manager'
        and exists (select 1 from public.admin_delegations d where d.user_id = auth.uid() and p_area = any (d.areas)))
  )
$$;

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
     and not exists (select 1 from public.profiles where id = p_user_id and role = 'manager' and active) then
    raise exception 'Only active managers can be given areas to look after';
  end if;
  if cardinality(v_areas) = 0 then
    delete from public.admin_delegations where user_id = p_user_id;
  else
    insert into public.admin_delegations (user_id, areas, granted_by)
    values (p_user_id, v_areas, auth.uid())
    on conflict (user_id) do update set areas = excluded.areas, granted_by = excluded.granted_by, granted_at = now();
  end if;
  perform public.write_audit('delegation_changed', 'profile', p_user_id::text, jsonb_build_object('areas', to_jsonb(v_areas)));
end;
$$;

create or replace function public.feature_enabled(p_key text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select enabled and included from public.features where key = p_key), false)
$$;

create or replace function public.compliance_applies(p_item public.compliance_items, p_role public.app_role, p_teams uuid[])
returns boolean
language sql
stable
set search_path = ''
as $$
  select p_item.active
     and (cardinality(p_item.applies_roles) = 0 or p_role = any (p_item.applies_roles))
     and (cardinality(p_item.applies_teams) = 0 or p_item.applies_teams && coalesce(p_teams, '{}'))
$$;

create or replace function public.leads_user(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.team_leaders tl
      join public.team_members m on m.team_id = tl.team_id
     where tl.user_id = auth.uid()
       and m.user_id = p_user_id
  ) and public.has_role(array['team_leader', 'manager', 'system_admin']::public.app_role[])
$$;

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
    values (p_user, 'notice', jsonb_build_object('title', p_title, 'body', coalesce(p_body, ''), 'href', coalesce(p_href, '/')));
  end if;
end;
$$;

create or replace function public.can_make_forms()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and public.feature_enabled('forms')
     and (public.is_system_admin()
          or public.my_role()::text in (select jsonb_array_elements_text(coalesce(
               (select value from public.app_settings where key = 'forms.maker_roles'), '[]'))))
$$;

-- Adding registers and job titles: managers and the system admin again.
drop policy if exists "delegated people create registries" on public.registries;
drop policy if exists "managers create registries" on public.registries;
create policy "managers create registries" on public.registries
  for insert to authenticated with check (public.has_role(array['manager', 'system_admin']::public.app_role[]));
drop policy if exists "delegated people add job titles" on public.job_titles;
drop policy if exists "delegated people change job titles" on public.job_titles;
drop policy if exists "managers add job titles" on public.job_titles;
drop policy if exists "managers change job titles" on public.job_titles;
create policy "managers add job titles" on public.job_titles
  for insert to authenticated with check (public.has_role(array['manager', 'system_admin']::public.app_role[]));
create policy "managers change job titles" on public.job_titles
  for update to authenticated
  using (public.has_role(array['manager', 'system_admin']::public.app_role[]))
  with check (public.has_role(array['manager', 'system_admin']::public.app_role[]));

-- Notification filters off.
drop trigger if exists notifications_filter on public.notifications;
drop trigger if exists email_outbox_filter on public.email_outbox;
drop function if exists public.filter_notification();
drop function if exists public.filter_email();
drop function if exists public.notification_on(text, text);
drop function if exists public.notification_feature(text);
delete from public.app_settings where key = 'notify.channels';

-- Save and deploy, delegation per area, the front page check.
drop function if exists public.deploy_drafts();
drop function if exists public.discard_drafts();
drop function if exists public.save_draft(text, text, jsonb);
drop function if exists public.live_value(text, text);
drop function if exists public.may_change(text, text);
drop function if exists public.my_admin_areas();
drop function if exists public.website_front_page();
drop table if exists public.settings_drafts;
drop table if exists public.delegation_rules;

-- Feature parts.
delete from public.features where key in ('teams', 'roles', 'form_builder', 'compliance_read', 'compliance_training', 'compliance_upload', 'compliance_forms');
alter table public.features drop column if exists parent;

commit;
