-- Staff Portal · © cmeproject. All rights reserved.
--
-- Registers: each registry has its own reference prefix, labels and custom
-- fields. All tasks still live in ONE table (public.tasks); a register page
-- is a filtered view of it, so nothing is ever copied or synced.
--
-- Registries come in two kinds:
--   tasks   – work with someone looking after it (most registers)
--   records – a list of things with no workflow (for example an asset register)

-- ---------------------------------------------------------------------------
-- Registry settings
-- ---------------------------------------------------------------------------

alter table public.registries
  add column kind text not null default 'tasks' check (kind in ('tasks', 'records')),
  add column prefix text,
  add column next_number int not null default 1,
  add column description_label text not null default 'Description',
  add column title_label text not null default 'Title',
  add column show_due_date boolean not null default true,
  add column show_review_date boolean not null default false,
  add column review_label text not null default 'Next review date',
  add column show_outcome boolean not null default false,
  add column outcome_label text not null default 'Outcome / actions taken',
  -- The built-in "General tasks" registry: can be renamed, never retired.
  add column is_default boolean not null default false,
  add column created_by uuid references public.profiles (id);

update public.registries
   set prefix = upper(left(regexp_replace(name, '[^A-Za-z]', '', 'g'), 3)) || sort_order
 where prefix is null;

alter table public.registries
  alter column prefix set not null,
  add constraint registries_prefix_format check (prefix ~ '^[A-Z0-9]{2,6}$');
create unique index registries_prefix_unique on public.registries (prefix);
create unique index registries_one_default on public.registries ((true)) where is_default;

-- Custom fields of a registry.
create table public.registry_fields (
  id          uuid primary key default gen_random_uuid(),
  registry_id uuid not null references public.registries (id) on delete cascade,
  key         text not null check (key ~ '^[a-z][a-z0-9_]{0,39}$'),
  label       text not null check (length(trim(label)) between 1 and 80),
  type        text not null check (type in (
                'text', 'long_text', 'number', 'money', 'date',
                'choice', 'multi_choice', 'yes_no', 'person', 'asset')),
  required    boolean not null default false,
  -- Choices for choice / multi_choice fields.
  options     jsonb not null default '[]'::jsonb check (jsonb_typeof(options) = 'array'),
  help        text not null default '',
  sort_order  int not null default 0,
  -- Retired fields keep their data but are no longer shown on forms.
  active      boolean not null default true,
  created_at  timestamptz not null default now(),
  unique (registry_id, key)
);

-- ---------------------------------------------------------------------------
-- Task additions
-- ---------------------------------------------------------------------------

alter table public.tasks
  add column ref_number int,
  add column details jsonb not null default '{}'::jsonb check (jsonb_typeof(details) = 'object'),
  add column date_reported date not null default current_date,
  add column review_date date,
  add column outcome text not null default '',
  -- Follow-up actions point at the task they belong to.
  add column parent_task_id uuid references public.tasks (id);

update public.tasks set ref_number = number where ref_number is null;
alter table public.tasks alter column ref_number set not null;
create unique index tasks_registry_ref_unique on public.tasks (registry_id, ref_number);
create index tasks_parent_idx on public.tasks (parent_task_id);
create index tasks_details_idx on public.tasks using gin (details);

-- ---------------------------------------------------------------------------
-- Records (for "records" registries such as an asset register)
-- ---------------------------------------------------------------------------

create table public.records (
  id          uuid primary key default gen_random_uuid(),
  org_id      uuid not null default public.default_org_id() references public.organisation (id),
  registry_id uuid not null references public.registries (id),
  ref_number  int not null,
  title       text not null check (length(trim(title)) between 1 and 200),
  details     jsonb not null default '{}'::jsonb check (jsonb_typeof(details) = 'object'),
  archived    boolean not null default false,
  created_by  uuid not null references public.profiles (id),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (registry_id, ref_number)
);

create table public.record_events (
  id         bigint generated always as identity primary key,
  record_id  uuid not null references public.records (id),
  actor_id   uuid references public.profiles (id),
  type       text not null,
  details    jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index record_events_record_idx on public.record_events (record_id, created_at);

create trigger record_events_append_only
  before update or delete on public.record_events
  for each row execute function public.block_audit_changes();

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

create function public.manages_registry(p_registry_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_staff_admin() or (
    public.has_role(array['manager', 'system_admin']::public.app_role[])
    and exists (select 1 from public.registry_managers
                 where registry_id = p_registry_id and user_id = auth.uid())
  )
$$;

-- The person looking after it, its creator, their team leader, the
-- registry's managers and system admins can change a task's details.
create function public.can_edit_task(p_task_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and exists (
    select 1 from public.tasks t
     where t.id = p_task_id
       and (
         t.assigned_to = auth.uid()
         or t.created_by = auth.uid()
         or public.leads_user(t.assigned_to)
         or (public.has_role(array['manager', 'system_admin']::public.app_role[])
             and exists (select 1 from public.registry_managers rm
                          where rm.registry_id = t.registry_id and rm.user_id = auth.uid()))
         or public.is_system_admin()
       )
  )
$$;

-- Next reference number in a registry (locks the registry row briefly).
create function public.take_ref_number(p_registry_id uuid)
returns int
language sql
security definer
set search_path = ''
as $$
  update public.registries set next_number = next_number + 1
   where id = p_registry_id
  returning next_number - 1
$$;

-- Checks custom field values against a registry's fields and returns them
-- cleaned up: unknown keys removed, empty values dropped, types checked.
-- Values of retired fields are kept from p_existing.
create function public.clean_details(p_registry_id uuid, p_details jsonb, p_existing jsonb default '{}'::jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  f public.registry_fields;
  v jsonb;
  out jsonb := '{}'::jsonb;
  item jsonb;
begin
  p_details := coalesce(p_details, '{}'::jsonb);

  for f in select * from public.registry_fields where registry_id = p_registry_id order by sort_order loop
    if not f.active then
      if p_existing ? f.key then
        out := out || jsonb_build_object(f.key, p_existing -> f.key);
      end if;
      continue;
    end if;

    v := p_details -> f.key;
    if v is null or v = 'null'::jsonb or v = '""'::jsonb or v = '[]'::jsonb then
      if f.required then
        raise exception '% is required', f.label;
      end if;
      continue;
    end if;

    case f.type
      when 'text', 'long_text' then
        if jsonb_typeof(v) <> 'string' then raise exception '% must be text', f.label; end if;
        if length(v #>> '{}') > 5000 then raise exception '% is too long', f.label; end if;
      when 'number', 'money' then
        if jsonb_typeof(v) <> 'number' then raise exception '% must be a number', f.label; end if;
      when 'date' then
        if jsonb_typeof(v) <> 'string' or (v #>> '{}') !~ '^\d{4}-\d{2}-\d{2}$' then
          raise exception '% must be a date', f.label;
        end if;
        perform (v #>> '{}')::date;
      when 'yes_no' then
        if jsonb_typeof(v) <> 'boolean' then raise exception '% must be yes or no', f.label; end if;
      when 'choice' then
        if jsonb_typeof(v) <> 'string' or not (f.options ? (v #>> '{}')) then
          raise exception 'Choose one of the options for %', f.label;
        end if;
      when 'multi_choice' then
        if jsonb_typeof(v) <> 'array' then raise exception 'Choose options for %', f.label; end if;
        for item in select * from jsonb_array_elements(v) loop
          if jsonb_typeof(item) <> 'string' or not (f.options ? (item #>> '{}')) then
            raise exception 'Choose from the options for %', f.label;
          end if;
        end loop;
      when 'person' then
        if jsonb_typeof(v) <> 'string' or not exists (
          select 1 from public.profiles where id::text = (v #>> '{}')) then
          raise exception 'Choose a person for %', f.label;
        end if;
      when 'asset' then
        if jsonb_typeof(v) <> 'string' or not exists (
          select 1 from public.records r join public.registries g on g.id = r.registry_id
           where r.id::text = (v #>> '{}') and g.kind = 'records') then
          raise exception 'Choose an item for %', f.label;
        end if;
    end case;

    out := out || jsonb_build_object(f.key, v);
  end loop;

  return out;
end;
$$;

-- ---------------------------------------------------------------------------
-- Guard rails on registries
-- ---------------------------------------------------------------------------

create function public.guard_registry()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  base text;
  n int := 1;
begin
  new.prefix := upper(trim(coalesce(new.prefix, '')));
  -- No prefix given: make one from the name's initials (Risk Management
  -- Register -> RMR), adding a number if it's already taken.
  if new.prefix = '' then
    select upper(string_agg(left(w, 1), '')) into base
      from regexp_split_to_table(regexp_replace(new.name, '[^A-Za-z0-9 ]', '', 'g'), '\s+') w
     where w <> '';
    base := left(coalesce(nullif(base, ''), 'REG'), 4);
    if length(base) < 2 then base := upper(left(regexp_replace(new.name, '[^A-Za-z]', '', 'g') || 'XX', 3)); end if;
    new.prefix := base;
    while exists (select 1 from public.registries where prefix = new.prefix and id <> new.id) loop
      n := n + 1;
      new.prefix := base || n;
    end loop;
  end if;
  if tg_op = 'INSERT' then
    new.created_by := coalesce(new.created_by, auth.uid());
    new.next_number := 1;
    new.is_default := coalesce(new.is_default, false) and auth.uid() is null;
  else
    if new.kind <> old.kind and (
         exists (select 1 from public.tasks where registry_id = old.id)
         or exists (select 1 from public.records where registry_id = old.id)) then
      raise exception 'A registry''s kind can''t change once it has entries';
    end if;
    if old.is_default and not new.active then
      raise exception 'The General tasks registry can''t be retired';
    end if;
    new.is_default := old.is_default;
    if new.next_number < old.next_number then
      new.next_number := old.next_number;
    end if;
  end if;
  return new;
end;
$$;

create trigger registries_guard
  before insert or update on public.registries
  for each row execute function public.guard_registry();

-- A manager who creates a registry becomes its manager.
create function public.add_creator_as_manager()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.my_role() = 'manager' then
    insert into public.registry_managers (registry_id, user_id) values (new.id, auth.uid())
    on conflict do nothing;
  end if;
  perform public.write_audit('registry_created', 'registry', new.id::text, jsonb_build_object('name', new.name));
  return new;
end;
$$;

create trigger registries_creator_manager
  after insert on public.registries
  for each row execute function public.add_creator_as_manager();

-- Keys of fields never change once there is data under them.
create function public.guard_registry_field()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and (new.key <> old.key or new.registry_id <> old.registry_id) then
    raise exception 'A field''s key can''t be changed';
  end if;
  if tg_op = 'UPDATE' and new.type <> old.type and (
       exists (select 1 from public.tasks where registry_id = old.registry_id and details ? old.key)
       or exists (select 1 from public.records where registry_id = old.registry_id and details ? old.key)) then
    raise exception 'A field''s type can''t change once it has been filled in. Retire it and add a new field instead.';
  end if;
  return new;
end;
$$;

create trigger registry_fields_guard
  before update on public.registry_fields
  for each row execute function public.guard_registry_field();

-- ---------------------------------------------------------------------------
-- Creating and changing tasks
-- ---------------------------------------------------------------------------

drop function public.create_task(text, uuid, uuid, text, public.task_priority, date, uuid[]);

create function public.create_task(
  p_title text,
  p_registry_id uuid,
  p_assigned_to uuid,
  p_description text default '',
  p_priority public.task_priority default 'medium',
  p_due_date date default null,
  p_helpers uuid[] default '{}',
  p_details jsonb default '{}'::jsonb,
  p_date_reported date default null,
  p_review_date date default null,
  p_parent_task_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_task_id uuid;
  v_helper uuid;
  v_manager uuid;
  v_helpers uuid[];
  v_registry public.registries;
  v_details jsonb;
begin
  if not public.is_member() then
    raise exception 'Please sign in again';
  end if;
  if not public.feature_enabled('tasks') then
    raise exception 'Tasks are switched off at the moment';
  end if;
  if coalesce(trim(p_title), '') = '' then
    raise exception 'Give the task a title';
  end if;

  -- A follow-up action belongs to the same registry as its task.
  if p_parent_task_id is not null then
    if not public.can_edit_task(p_parent_task_id) then
      raise exception 'You can''t add actions to this task';
    end if;
    select registry_id into p_registry_id from public.tasks where id = p_parent_task_id;
    p_details := '{}'::jsonb;
  end if;

  select * into v_registry from public.registries where id = p_registry_id and active;
  if v_registry.id is null or v_registry.kind <> 'tasks' then
    raise exception 'Choose a registry that is in use';
  end if;
  if not exists (select 1 from public.profiles where id = p_assigned_to and active) then
    raise exception 'Choose someone who can sign in to look after this task';
  end if;

  v_details := case when p_parent_task_id is null then public.clean_details(p_registry_id, p_details) else '{}'::jsonb end;

  select coalesce(array_agg(distinct h), '{}') into v_helpers
    from unnest(coalesce(p_helpers, '{}')) h
    join public.profiles p on p.id = h and p.active
   where h <> p_assigned_to;

  insert into public.tasks (title, description, registry_id, ref_number, priority, assigned_to, created_by,
                            due_date, details, date_reported, review_date, parent_task_id)
  values (trim(p_title), coalesce(trim(p_description), ''), p_registry_id, public.take_ref_number(p_registry_id),
          p_priority, p_assigned_to, auth.uid(), p_due_date, v_details,
          coalesce(p_date_reported, current_date), p_review_date, p_parent_task_id)
  returning id into v_task_id;

  insert into public.task_events (task_id, actor_id, type, to_value)
  values (v_task_id, auth.uid(), 'created', p_assigned_to::text);

  if p_parent_task_id is not null then
    insert into public.task_events (task_id, actor_id, type, to_value)
    values (p_parent_task_id, auth.uid(), 'action_added', v_task_id::text);
  end if;

  foreach v_helper in array v_helpers loop
    insert into public.task_helpers (task_id, user_id, added_by) values (v_task_id, v_helper, auth.uid());
    insert into public.task_events (task_id, actor_id, type, to_value)
    values (v_task_id, auth.uid(), 'helper_added', v_helper::text);
  end loop;

  perform public.queue_task_email('task_assigned', v_task_id, p_assigned_to, v_helpers);
  if p_assigned_to = auth.uid() then
    foreach v_helper in array v_helpers loop
      perform public.queue_task_email('helper_added', v_task_id, v_helper);
    end loop;
  end if;
  if p_parent_task_id is null then
    for v_manager in
      select rm.user_id from public.registry_managers rm
       where rm.registry_id = p_registry_id
         and rm.user_id <> p_assigned_to
         and not (rm.user_id = any (v_helpers))
    loop
      perform public.queue_task_email('task_created_manager', v_task_id, v_manager);
    end loop;
  end if;

  return v_task_id;
end;
$$;

-- Edit a task's details (not its status or who looks after it; those have
-- their own steps). Records which fields changed on the timeline.
create function public.update_task_details(
  p_task_id uuid,
  p_title text,
  p_description text,
  p_priority public.task_priority,
  p_due_date date,
  p_date_reported date,
  p_review_date date,
  p_outcome text,
  p_details jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.tasks;
  v_details jsonb;
  changed text[] := '{}';
  f record;
begin
  if not public.can_edit_task(p_task_id) then
    raise exception 'You can''t change this task';
  end if;
  if not public.feature_enabled('tasks') then
    raise exception 'Tasks are switched off at the moment';
  end if;
  select * into t from public.tasks where id = p_task_id for update;
  if t.status = 'closed' then
    raise exception 'This task is closed';
  end if;
  if coalesce(trim(p_title), '') = '' then
    raise exception 'Give the task a title';
  end if;

  v_details := case when t.parent_task_id is null then public.clean_details(t.registry_id, p_details, t.details) else t.details end;

  if trim(p_title) <> t.title then changed := array_append(changed, ('title')::text); end if;
  if coalesce(trim(p_description), '') <> t.description then changed := array_append(changed, ('description')::text); end if;
  if p_priority <> t.priority then changed := array_append(changed, ('priority')::text); end if;
  if p_due_date is distinct from t.due_date then changed := array_append(changed, ('due date')::text); end if;
  if coalesce(p_date_reported, t.date_reported) <> t.date_reported then changed := array_append(changed, ('date reported')::text); end if;
  if p_review_date is distinct from t.review_date then changed := array_append(changed, ('review date')::text); end if;
  if coalesce(trim(p_outcome), '') <> t.outcome then changed := array_append(changed, ('outcome')::text); end if;
  for f in select key, label from public.registry_fields where registry_id = t.registry_id order by sort_order loop
    if (v_details -> f.key) is distinct from (t.details -> f.key) then
      changed := array_append(changed, lower(f.label));
    end if;
  end loop;

  if cardinality(changed) = 0 then
    return;
  end if;

  update public.tasks
     set title = trim(p_title),
         description = coalesce(trim(p_description), ''),
         priority = p_priority,
         due_date = p_due_date,
         date_reported = coalesce(p_date_reported, t.date_reported),
         review_date = p_review_date,
         outcome = coalesce(trim(p_outcome), ''),
         details = v_details,
         updated_at = now()
   where id = p_task_id;

  insert into public.task_events (task_id, actor_id, type, comment)
  values (p_task_id, auth.uid(), 'details_changed', array_to_string(changed, ', '));
end;
$$;

-- ---------------------------------------------------------------------------
-- Creating and changing records
-- ---------------------------------------------------------------------------

create function public.create_record(p_registry_id uuid, p_title text, p_details jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
begin
  if not public.manages_registry(p_registry_id) and not public.is_system_admin() then
    raise exception 'Only this register''s managers can add to it';
  end if;
  if not exists (select 1 from public.registries where id = p_registry_id and active and kind = 'records') then
    raise exception 'Choose a register that is in use';
  end if;
  if coalesce(trim(p_title), '') = '' then
    raise exception 'Give it a name or description';
  end if;
  insert into public.records (registry_id, ref_number, title, details, created_by)
  values (p_registry_id, public.take_ref_number(p_registry_id), trim(p_title),
          public.clean_details(p_registry_id, p_details), auth.uid())
  returning id into v_id;
  insert into public.record_events (record_id, actor_id, type) values (v_id, auth.uid(), 'created');
  return v_id;
end;
$$;

create function public.update_record(p_record_id uuid, p_title text, p_details jsonb, p_archived boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.records;
  v_details jsonb;
  changed text[] := '{}';
  f record;
begin
  select * into r from public.records where id = p_record_id for update;
  if r.id is null or (not public.manages_registry(r.registry_id) and not public.is_system_admin()) then
    raise exception 'Only this register''s managers can change it';
  end if;
  if coalesce(trim(p_title), '') = '' then
    raise exception 'Give it a name or description';
  end if;
  v_details := public.clean_details(r.registry_id, p_details, r.details);
  if trim(p_title) <> r.title then changed := array_append(changed, ('name')::text); end if;
  if p_archived <> r.archived then changed := array_append(changed, (case when p_archived then 'archived' else 'restored' end)::text); end if;
  for f in select key, label from public.registry_fields where registry_id = r.registry_id order by sort_order loop
    if (v_details -> f.key) is distinct from (r.details -> f.key) then
      changed := array_append(changed, lower(f.label));
    end if;
  end loop;
  if cardinality(changed) = 0 then return; end if;
  update public.records
     set title = trim(p_title), details = v_details, archived = p_archived, updated_at = now()
   where id = p_record_id;
  insert into public.record_events (record_id, actor_id, type, details)
  values (p_record_id, auth.uid(), 'changed', jsonb_build_object('fields', to_jsonb(changed)));
end;
$$;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.registry_fields enable row level security;
alter table public.records         enable row level security;
alter table public.record_events   enable row level security;

-- Managers can create registries; managers can change the registries they
-- manage; staff admins and system admins can change any.
drop policy "staff admin manages registries" on public.registries;
create policy "managers create registries" on public.registries
  for insert to authenticated
  with check (public.is_staff_admin() or public.has_role(array['manager']::public.app_role[]));
create policy "registry managers update registries" on public.registries
  for update to authenticated
  using (public.manages_registry(id)) with check (public.manages_registry(id));

drop policy "staff admin manages registry managers" on public.registry_managers;
create policy "registry managers manage managers" on public.registry_managers
  for all to authenticated
  using (public.manages_registry(registry_id)) with check (public.manages_registry(registry_id));

create policy "members read registry fields" on public.registry_fields
  for select to authenticated using (public.is_member());
create policy "registry managers manage fields" on public.registry_fields
  for insert to authenticated with check (public.manages_registry(registry_id));
create policy "registry managers change fields" on public.registry_fields
  for update to authenticated
  using (public.manages_registry(registry_id)) with check (public.manages_registry(registry_id));
-- Fields are retired, never deleted, so their data is kept.

create policy "members read records" on public.records
  for select to authenticated using (public.is_member());
create policy "members read record history" on public.record_events
  for select to authenticated using (public.is_member());

revoke insert, update, delete, truncate on public.records, public.record_events from anon, authenticated;
revoke delete on public.registries, public.registry_fields from anon, authenticated;

revoke execute on function public.take_ref_number(uuid) from public, anon, authenticated;
revoke execute on function public.clean_details(uuid, jsonb, jsonb) from public, anon, authenticated;
revoke execute on function public.create_task(text, uuid, uuid, text, public.task_priority, date, uuid[], jsonb, date, date, uuid) from public, anon;
revoke execute on function public.update_task_details(uuid, text, text, public.task_priority, date, date, date, text, jsonb) from public, anon;
revoke execute on function public.create_record(uuid, text, jsonb) from public, anon;
revoke execute on function public.update_record(uuid, text, jsonb, boolean) from public, anon;
grant execute on function public.create_task(text, uuid, uuid, text, public.task_priority, date, uuid[], jsonb, date, date, uuid) to authenticated;
grant execute on function public.update_task_details(uuid, text, text, public.task_priority, date, date, date, text, jsonb) to authenticated;
grant execute on function public.create_record(uuid, text, jsonb) to authenticated;
grant execute on function public.update_record(uuid, text, jsonb, boolean) to authenticated;

-- ---------------------------------------------------------------------------
-- The built-in General tasks registry
-- ---------------------------------------------------------------------------

insert into public.registries (name, description, prefix, is_default, sort_order)
values ('General tasks', 'Everyday jobs that don''t belong to a register.', 'GEN', true, 0)
on conflict do nothing;
