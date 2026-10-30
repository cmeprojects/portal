-- Staff Portal · © cmeproject. All rights reserved.
--
-- Feature builder (cmeprojects). The system admin builds features (for
-- example a Fluid intake chart): a form of fields staff fill in, recorded with
-- the date, time and the signed-in person. A feature is a draft until it's
-- published, and each one is a premium add-on the system admin includes in
-- the company's package or not. Entries are never deleted (staff can undo
-- their own for a few minutes); switching a feature off hides it and keeps
-- its entries.
--
-- The client list (car_clients) becomes the company's client list for every
-- feature, managed by managers, staff admins and the system admin.

-- ---------------------------------------------------------------------------
-- Clients for everyone
-- ---------------------------------------------------------------------------

create or replace function public.client_options()
returns table (id uuid, name text)
language sql
stable
security definer
set search_path = ''
as $$
  select id, name from public.car_clients
   where public.is_member() and public.my_role() <> 'new_starter' and active
   order by lower(name)
$$;
revoke execute on function public.client_options() from public, anon;
grant execute on function public.client_options() to authenticated;

drop policy if exists "people managers see clients" on public.car_clients;
create policy "people managers see clients" on public.car_clients for select to authenticated using (public.can_manage_people());
drop policy if exists "people managers add clients" on public.car_clients;
create policy "people managers add clients" on public.car_clients for insert to authenticated with check (public.can_manage_people());
drop policy if exists "people managers change clients" on public.car_clients;
create policy "people managers change clients" on public.car_clients for update to authenticated
  using (public.can_manage_people()) with check (public.can_manage_people());

-- ---------------------------------------------------------------------------
-- Features, fields, entries and targets
-- ---------------------------------------------------------------------------

create table if not exists public.custom_features (
  id             uuid primary key default gen_random_uuid(),
  org_id         uuid not null default public.default_org_id() references public.organisation (id),
  slug           text not null unique check (slug ~ '^[a-z0-9][a-z0-9-]{1,39}$'),
  name           text not null check (length(trim(name)) between 1 and 60),
  menu_label     text not null check (length(trim(menu_label)) between 1 and 30),
  description    text not null default '' check (length(description) <= 300),
  status         text not null default 'draft' check (status in ('draft', 'published')),
  -- In this company's package (premium add-on).
  enabled        boolean not null default true,
  fill_roles     public.app_role[] not null default '{support_worker,team_leader}',
  see_roles      public.app_role[] not null default '{team_leader,manager}',
  undo_minutes   int not null default 10 check (undo_minutes between 0 and 1440),
  record_team    boolean not null default true,
  -- Daily totals: add up this number field, per this client field.
  total_field    uuid,
  group_field    uuid,
  default_target numeric check (default_target is null or default_target >= 0),
  sort_order     int not null default 100,
  created_by     uuid references public.profiles (id) default auth.uid(),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  published_at   timestamptz
);

create table if not exists public.custom_fields (
  id          uuid primary key default gen_random_uuid(),
  feature_id  uuid not null references public.custom_features (id) on delete cascade,
  label       text not null check (length(trim(label)) between 1 and 80),
  type        text not null check (type in ('text', 'long', 'number', 'choice', 'multi', 'yesno', 'date', 'time', 'client', 'staff', 'photo')),
  required    boolean not null default false,
  help        text not null default '' check (length(help) <= 200),
  unit        text not null default '' check (length(unit) <= 12),
  min_value   numeric,
  max_value   numeric,
  options     jsonb not null default '[]' check (jsonb_typeof(options) = 'array'),
  allow_other boolean not null default false,
  quick       jsonb not null default '[]' check (jsonb_typeof(quick) = 'array'),
  sort_order  int not null default 0,
  -- Removed from the form; old entries keep their answers.
  archived    boolean not null default false,
  created_at  timestamptz not null default now()
);
create index if not exists custom_fields_feature on public.custom_fields (feature_id, sort_order);

create table if not exists public.custom_entries (
  id           bigint generated always as identity primary key,
  org_id       uuid not null default public.default_org_id() references public.organisation (id),
  feature_id   uuid not null references public.custom_features (id),
  data         jsonb not null default '{}' check (jsonb_typeof(data) = 'object'),
  client_id    uuid references public.car_clients (id),
  client_name  text not null default '',
  team_names   text not null default '',
  created_by   uuid not null references public.profiles (id) default auth.uid(),
  created_at   timestamptz not null default now(),
  corrected_at timestamptz
);
create index if not exists custom_entries_feature on public.custom_entries (feature_id, created_at desc);
create index if not exists custom_entries_client on public.custom_entries (feature_id, client_id, created_at desc);

-- A daily target for each client (e.g. 1,500 ml), or the feature's default.
create table if not exists public.custom_client_targets (
  feature_id uuid not null references public.custom_features (id) on delete cascade,
  client_id  uuid not null references public.car_clients (id) on delete cascade,
  target     numeric not null check (target >= 0),
  primary key (feature_id, client_id)
);

-- ---------------------------------------------------------------------------
-- Who can do what
-- ---------------------------------------------------------------------------

create or replace function public.can_build_features()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_system_admin() and public.mfa_ok()
$$;

create or replace function public.custom_feature_live(p_feature uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select status = 'published' and enabled from public.custom_features where id = p_feature), false)
$$;

create or replace function public.can_fill_feature(p_feature uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and public.custom_feature_live(p_feature)
     and (public.my_role() = 'system_admin'
          or exists (select 1 from public.custom_features where id = p_feature and public.my_role() = any (fill_roles)))
$$;

create or replace function public.can_see_feature(p_feature uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and public.custom_feature_live(p_feature)
     and (public.my_role() = 'system_admin'
          or exists (select 1 from public.custom_features where id = p_feature and public.my_role() = any (see_roles)))
$$;

-- Your own entries; everyone's for those who see the feature (team leaders:
-- the people in the team they lead); all of them for the builder.
create or replace function public.sees_custom_entry(p_feature uuid, p_by uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_by = auth.uid()
      or public.can_build_features()
      or (public.can_see_feature(p_feature) and (public.my_role() <> 'team_leader' or public.leads_user(p_by)))
$$;

alter table public.custom_features enable row level security;
alter table public.custom_fields enable row level security;
alter table public.custom_entries enable row level security;
alter table public.custom_client_targets enable row level security;

drop policy if exists "staff see live features, the builder sees all" on public.custom_features;
create policy "staff see live features, the builder sees all" on public.custom_features for select to authenticated
  using (public.can_build_features() or (public.is_member() and status = 'published' and enabled));
drop policy if exists "the builder adds features" on public.custom_features;
create policy "the builder adds features" on public.custom_features for insert to authenticated with check (public.can_build_features());
drop policy if exists "the builder changes features" on public.custom_features;
create policy "the builder changes features" on public.custom_features for update to authenticated
  using (public.can_build_features()) with check (public.can_build_features());
drop policy if exists "the builder removes unused drafts" on public.custom_features;
create policy "the builder removes unused drafts" on public.custom_features for delete to authenticated
  using (public.can_build_features() and status = 'draft'
         and not exists (select 1 from public.custom_entries e where e.feature_id = custom_features.id));

drop policy if exists "fields follow their feature" on public.custom_fields;
create policy "fields follow their feature" on public.custom_fields for select to authenticated
  using (public.can_build_features() or (public.is_member() and public.custom_feature_live(feature_id)));
drop policy if exists "the builder adds fields" on public.custom_fields;
create policy "the builder adds fields" on public.custom_fields for insert to authenticated with check (public.can_build_features());
drop policy if exists "the builder changes fields" on public.custom_fields;
create policy "the builder changes fields" on public.custom_fields for update to authenticated
  using (public.can_build_features()) with check (public.can_build_features());
drop policy if exists "the builder removes unused fields" on public.custom_fields;
create policy "the builder removes unused fields" on public.custom_fields for delete to authenticated
  using (public.can_build_features()
         and not exists (select 1 from public.custom_entries e where e.feature_id = custom_fields.feature_id and e.data ? custom_fields.id::text));

drop policy if exists "entries are seen by who may see them" on public.custom_entries;
create policy "entries are seen by who may see them" on public.custom_entries for select to authenticated
  using (public.sees_custom_entry(feature_id, created_by));
-- Entries change only through the functions below.
revoke insert, update, delete, truncate on public.custom_entries from anon, authenticated;

drop policy if exists "targets follow their feature" on public.custom_client_targets;
create policy "targets follow their feature" on public.custom_client_targets for select to authenticated
  using (public.can_build_features() or (public.is_member() and public.custom_feature_live(feature_id)));
drop policy if exists "the builder sets targets" on public.custom_client_targets;
create policy "the builder sets targets" on public.custom_client_targets for all to authenticated
  using (public.can_build_features()) with check (public.can_build_features());

-- Changes to features and fields go in the change log.
create or replace function public.log_feature_setup()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.write_audit(
    lower(tg_op) || '_' || tg_argv[0], tg_argv[0],
    coalesce(new.id, old.id)::text,
    case when tg_op = 'UPDATE' then jsonb_build_object('before', to_jsonb(old), 'after', to_jsonb(new))
         else to_jsonb(coalesce(new, old)) end);
  return coalesce(new, old);
end;
$$;
revoke execute on function public.log_feature_setup() from public, anon, authenticated;

drop trigger if exists custom_features_log on public.custom_features;
create trigger custom_features_log after insert or update or delete on public.custom_features
  for each row execute function public.log_feature_setup('custom_feature');
drop trigger if exists custom_fields_log on public.custom_fields;
create trigger custom_fields_log after insert or update or delete on public.custom_fields
  for each row execute function public.log_feature_setup('custom_field');

-- ---------------------------------------------------------------------------
-- Filling in and undoing
-- ---------------------------------------------------------------------------

create or replace function public.submit_custom_entry(p_feature uuid, p_data jsonb)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  f record;
  v text;
  n numeric;
  v_clean jsonb := '{}'::jsonb;
  v_client uuid;
  v_client_name text := '';
  v_id bigint;
begin
  if not public.can_fill_feature(p_feature) then
    raise exception 'You can''t fill this in';
  end if;
  if p_data is null or jsonb_typeof(p_data) <> 'object' then
    raise exception 'Fill in the form';
  end if;

  for f in select * from public.custom_fields where feature_id = p_feature and not archived order by sort_order loop
    if f.type = 'multi' then
      if jsonb_typeof(p_data -> f.id::text) = 'array' and jsonb_array_length(p_data -> f.id::text) > 0 then
        if not f.allow_other and exists (select 1 from jsonb_array_elements_text(p_data -> f.id::text) x where not f.options ? x) then
          raise exception '%: choose from the list', f.label;
        end if;
        v_clean := v_clean || jsonb_build_object(f.id::text, p_data -> f.id::text);
      elsif f.required then
        raise exception '%: choose at least one', f.label;
      end if;
      continue;
    end if;

    v := nullif(trim(p_data ->> f.id::text), '');
    if v is null then
      if f.required then
        raise exception '%: this is needed', f.label;
      end if;
      continue;
    end if;
    if length(v) > (case when f.type = 'long' then 2000 else 200 end) then
      raise exception '%: that''s too long', f.label;
    end if;

    case f.type
      when 'number' then
        begin
          n := v::numeric;
        exception when others then
          raise exception '%: enter a number', f.label;
        end;
        if f.min_value is not null and n < f.min_value then
          raise exception '%: the smallest allowed is %', f.label, f.min_value;
        end if;
        if f.max_value is not null and n > f.max_value then
          raise exception '%: the largest allowed is %', f.label, f.max_value;
        end if;
        v_clean := v_clean || jsonb_build_object(f.id::text, n);
        continue;
      when 'choice' then
        if not f.allow_other and not f.options ? v then
          raise exception '%: choose from the list', f.label;
        end if;
      when 'yesno' then
        if v not in ('Yes', 'No') then
          raise exception '%: choose Yes or No', f.label;
        end if;
      when 'date' then
        if v !~ '^\d{4}-\d{2}-\d{2}$' then
          raise exception '%: enter a date', f.label;
        end if;
      when 'time' then
        if v !~ '^\d{2}:\d{2}$' then
          raise exception '%: enter a time', f.label;
        end if;
      when 'client' then
        select id, name into v_client, v_client_name from public.car_clients where id::text = v and active;
        if v_client is null then
          raise exception '%: choose from the list', f.label;
        end if;
      when 'staff' then
        if not exists (select 1 from public.profiles where id::text = v and active) then
          raise exception '%: choose from the list', f.label;
        end if;
      when 'photo' then
        if v not like auth.uid()::text || '/%' then
          raise exception '%: upload the photo again', f.label;
        end if;
      else
        null;
    end case;
    v_clean := v_clean || jsonb_build_object(f.id::text, v);
  end loop;

  insert into public.custom_entries (feature_id, data, client_id, client_name, team_names)
  values (p_feature, v_clean, v_client, coalesce(v_client_name, ''),
          case when (select record_team from public.custom_features where id = p_feature)
               then coalesce((select string_agg(t.name, ', ' order by t.name) from public.team_members m join public.teams t on t.id = m.team_id
                               where m.user_id = auth.uid()), '')
               else '' end)
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.undo_custom_entry(p_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  e public.custom_entries;
begin
  select * into e from public.custom_entries where id = p_id for update;
  if e.id is null or e.created_by <> auth.uid() then
    raise exception 'Entry not found';
  end if;
  if e.created_at < now() - make_interval(mins => (select undo_minutes from public.custom_features where id = e.feature_id)) then
    raise exception 'It''s too late to undo. Ask a manager to fix it.';
  end if;
  delete from public.custom_entries where id = e.id;
  perform public.write_audit('custom_entry_undone', 'custom_entry', e.id::text, to_jsonb(e));
end;
$$;

-- Today's entries for one client (from everyone), for the "today so far" box
-- staff see after saving, so they know the client's total, not only their own.
create or replace function public.custom_client_today(p_feature uuid, p_client uuid)
returns table (id bigint, created_at timestamptz, data jsonb, by_name text, mine boolean)
language sql
stable
security definer
set search_path = ''
as $$
  select e.id, e.created_at, e.data, split_part(coalesce(nullif(p.full_name, ''), p.email), ' ', 1), e.created_by = auth.uid()
    from public.custom_entries e
    join public.profiles p on p.id = e.created_by
   where e.feature_id = p_feature and e.client_id = p_client
     and (public.can_fill_feature(p_feature) or public.can_see_feature(p_feature))
     and (e.created_at at time zone coalesce((select value #>> '{}' from public.app_settings where key = 'region.timezone'), 'Australia/Melbourne'))::date
         = public.local_today()
   order by e.created_at desc
$$;
revoke execute on function public.custom_client_today(uuid, uuid) from public, anon;
grant execute on function public.custom_client_today(uuid, uuid) to authenticated;

revoke execute on function public.can_build_features(), public.custom_feature_live(uuid), public.can_fill_feature(uuid),
  public.can_see_feature(uuid), public.sees_custom_entry(uuid, uuid), public.submit_custom_entry(uuid, jsonb),
  public.undo_custom_entry(bigint) from public, anon;
grant execute on function public.can_build_features(), public.custom_feature_live(uuid), public.can_fill_feature(uuid),
  public.can_see_feature(uuid), public.sees_custom_entry(uuid, uuid), public.submit_custom_entry(uuid, jsonb),
  public.undo_custom_entry(bigint) to authenticated;

-- ---------------------------------------------------------------------------
-- Photos on entries
-- ---------------------------------------------------------------------------

do $storage$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  insert into storage.buckets (id, name, public) values ('feature-files', 'feature-files', false) on conflict (id) do nothing;
  drop policy if exists "staff upload feature photos" on storage.objects;
  create policy "staff upload feature photos" on storage.objects
    for insert to authenticated
    with check (bucket_id = 'feature-files' and public.is_member() and (storage.foldername(name))[1] = auth.uid()::text);
  drop policy if exists "feature photos are seen with their entries" on storage.objects;
  create policy "feature photos are seen with their entries" on storage.objects
    for select to authenticated
    using (bucket_id = 'feature-files' and public.is_member()
           and ((storage.foldername(name))[1] = auth.uid()::text
                or exists (select 1 from public.custom_entries e
                            where e.data::text like '%' || storage.objects.name || '%'
                              and public.sees_custom_entry(e.feature_id, e.created_by))));
end;
$storage$;
