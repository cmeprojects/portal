-- Staff Portal · © cmeproject. All rights reserved.
-- Update 37: forms "To fill in" fix, who sees website enquiries, a 15-minute
-- lock after five wrong passwords, Compliance as a premium add-on (stays on),
-- deleting unused built features, and live role updates.
-- Run update 36 first. Safe to run again. To remove it again, run undo-37.sql.
begin;
-- Quick fixes (cmeprojects):
--   * Forms "To fill in": forms sent to me, in Compliance for my role or
--     team, or open to everyone (not sent to anyone in particular).
--   * Who sees website enquiries is a System setting (managers by default).
--   * Five wrong passwords lock that email out for 15 minutes.
--   * Compliance becomes a premium add-on (on for companies already using it);
--     while it's off, nothing can be added to Compliance.
--   * Any built feature nobody has used yet can be deleted (not only drafts).
--   * Open pages hear about role changes straight away.

-- Forms to fill in ------------------------------------------------------------
create or replace function public.my_forms_to_fill()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select f.id from public.forms f
   where public.can_fill_form(f.id)
     and (exists (select 1 from public.form_recipients r where r.form_id = f.id and r.user_id = auth.uid())
          or exists (select 1 from public.compliance_items i
                      where i.form_id = f.id and i.active
                        and (cardinality(i.applies_roles) = 0 or public.my_role() = any (i.applies_roles))
                        and (cardinality(i.applies_teams) = 0 or exists (
                              select 1 from public.team_members m where m.user_id = auth.uid() and m.team_id = any (i.applies_teams))))
          or (not exists (select 1 from public.form_recipients r where r.form_id = f.id)
              and not exists (select 1 from public.compliance_items i where i.form_id = f.id)))
$$;
revoke all on function public.my_forms_to_fill() from public, anon;
grant execute on function public.my_forms_to_fill() to authenticated;

-- Who sees enquiries ----------------------------------------------------------
insert into public.app_settings (key, value, label, description, is_public) values
  ('assistant.enquiry_roles', '["manager"]', 'Who sees website enquiries',
   'Besides the system admin. They see Enquiries in the menu and get a bell note for each new one.', false)
on conflict (key) do nothing;

create or replace function public.can_see_enquiries()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and (public.is_system_admin()
    or public.my_role()::text in (select jsonb_array_elements_text(coalesce(
         (select value from public.app_settings where key = 'assistant.enquiry_roles'), '[]'))))
$$;
revoke all on function public.can_see_enquiries() from public, anon;
grant execute on function public.can_see_enquiries() to authenticated;

drop policy if exists website_enquiries_read on public.website_enquiries;
create policy website_enquiries_read on public.website_enquiries
  for select to authenticated using (public.can_see_enquiries());
drop policy if exists website_enquiries_update on public.website_enquiries;
create policy website_enquiries_update on public.website_enquiries
  for update to authenticated using (public.can_see_enquiries()) with check (public.can_see_enquiries());

create or replace function public.new_enquiry_count()
returns bigint
language sql
stable
security definer
set search_path = ''
as $$
  select case when public.can_see_enquiries() then (select count(*) from public.website_enquiries where status = 'new') else 0 end
$$;

create or replace function public.website_enquiry_notify() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.notifications (user_id, kind, title, body, href)
  select p.id, 'website_enquiry', 'New enquiry: ' || new.full_name, 'Phone ' || new.phone || '. Call them back.', '/enquiries'
    from public.profiles p
   where p.active and (p.role = 'system_admin' or p.role::text in (select jsonb_array_elements_text(coalesce(
           (select value from public.app_settings where key = 'assistant.enquiry_roles'), '[]'))));
  return new;
end $$;

-- Five wrong passwords: locked for 15 minutes ---------------------------------
create table if not exists public.sign_in_failures (
  email        text primary key,
  failed       int not null default 0,
  locked_until timestamptz,
  updated_at   timestamptz not null default now()
);
alter table public.sign_in_failures enable row level security;
revoke all on public.sign_in_failures from anon, authenticated;

-- 'check': minutes still locked (0 = free); 'fail': count a wrong password;
-- 'ok': signed in, start again. Only the server (service role) calls it.
create or replace function public.sign_in_guard(p_email text, p_event text)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row public.sign_in_failures;
  v_email text := lower(btrim(p_email));
begin
  select * into v_row from public.sign_in_failures where email = v_email;
  if p_event = 'ok' then
    delete from public.sign_in_failures where email = v_email;
    return 0;
  end if;
  if v_row.locked_until is not null and v_row.locked_until > now() then
    return ceil(extract(epoch from v_row.locked_until - now()) / 60)::int;
  end if;
  if p_event = 'fail' then
    insert into public.sign_in_failures as s (email, failed, updated_at) values (v_email, 1, now())
    on conflict (email) do update
      set failed = case when s.locked_until is not null and s.locked_until <= now() then 1 else s.failed + 1 end,
          locked_until = case when s.locked_until is not null and s.locked_until <= now() then null else s.locked_until end,
          updated_at = now()
    returning * into v_row;
    if v_row.failed >= 5 then
      update public.sign_in_failures set locked_until = now() + interval '15 minutes', failed = 0 where email = v_email;
      return 15;
    end if;
  end if;
  return 0;
end $$;
revoke all on function public.sign_in_guard(text, text) from public, anon, authenticated;
grant execute on function public.sign_in_guard(text, text) to service_role;

-- Compliance as a premium add-on ----------------------------------------------
insert into public.features (key, label, description, enabled, sort_order, premium, included) values
  ('compliance', 'Compliance (staff management)',
   'Onboarding, documents to read, trainings, uploads with expiry dates, and the Compliance report.',
   true, 40, true, true)
on conflict (key) do nothing;

create or replace function public.compliance_items_guard() returns trigger language plpgsql set search_path = '' as $$
begin
  if not public.feature_enabled('compliance') then
    raise exception 'Compliance is switched off' using errcode = '42501';
  end if;
  return new;
end $$;
drop trigger if exists compliance_items_guard on public.compliance_items;
create trigger compliance_items_guard before insert on public.compliance_items
  for each row execute function public.compliance_items_guard();

-- Delete any built feature nobody has used -----------------------------------
drop policy if exists "the builder removes unused drafts" on public.custom_features;
drop policy if exists "the builder removes unused features" on public.custom_features;
create policy "the builder removes unused features" on public.custom_features for delete to authenticated
  using (public.can_build_features()
         and not exists (select 1 from public.custom_entries e where e.feature_id = custom_features.id));

-- Role changes are heard straight away ----------------------------------------
do $live$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'profiles') then
    alter publication supabase_realtime add table public.profiles;
  end if;
end;
$live$;

commit;
