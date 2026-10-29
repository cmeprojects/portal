-- Staff Portal · © cmeproject. All rights reserved.
--
-- Delegation: the system admin lets a named manager look after some areas
-- of System settings. Never delegated: Security, Features, General (region
-- and record keeping), making system admins, and Delegation itself.
--   branding    company name, logos, colours, wording
--   messages    support contact, announcement, invite note
--   people      people rules
--   compliance  Compliance settings
--   tasks       task settings (due dates, reminders, required fields)
--   reports     who can see Reports
--   audit       read the change log

create table public.admin_delegations (
  user_id    uuid primary key references public.profiles (id) on delete cascade,
  areas      text[] not null default '{}'
             check (areas <@ array['branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'audit']),
  granted_by uuid references public.profiles (id),
  granted_at timestamptz not null default now()
);

alter table public.admin_delegations enable row level security;
create policy "system admin and the delegate read delegations" on public.admin_delegations
  for select to authenticated using (public.is_system_admin() or user_id = auth.uid());
revoke insert, update, delete, truncate on public.admin_delegations from anon, authenticated;

-- Can the signed-in person look after this area of System settings?
create function public.can_admin_area(p_area text)
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

-- Which area a setting belongs to (null = system admin only).
create function public.setting_area(p_key text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when p_key in ('brand.support_contact', 'brand.announcement', 'people.invite_message') then 'messages'
    when p_key like 'brand.%' or p_key like 'wording.%' then 'branding'
    when p_key like 'people.%' then 'people'
    when p_key like 'compliance.%' then 'compliance'
    when p_key like 'tasks.%' then 'tasks'
    when p_key like 'reports.%' then 'reports'
    else null
  end
$$;

create policy "delegated managers edit their settings" on public.app_settings
  for update to authenticated
  using (public.can_admin_area(public.setting_area(key)))
  with check (public.can_admin_area(public.setting_area(key)));

create policy "delegated managers read the change log" on public.audit_log
  for select to authenticated using (public.can_admin_area('audit'));

-- Set (or clear, with no areas) what a manager looks after.
create function public.set_delegation(p_user_id uuid, p_areas text[])
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

revoke execute on function public.set_delegation(uuid, text[]) from public, anon;
grant execute on function public.set_delegation(uuid, text[]) to authenticated;

-- Someone who stops being an active manager loses their delegated areas.
create function public.drop_delegation_on_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.role <> 'manager' or not new.active then
    delete from public.admin_delegations where user_id = new.id;
  end if;
  return new;
end;
$$;

create trigger profiles_drop_delegation
  after update of role, active on public.profiles
  for each row execute function public.drop_delegation_on_change();

-- Delegated managers with Branding can upload logos.
do $storage$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  create policy "delegated managers upload logos" on storage.objects
    for insert to authenticated with check (bucket_id = 'branding' and public.can_admin_area('branding'));
end;
$storage$;
