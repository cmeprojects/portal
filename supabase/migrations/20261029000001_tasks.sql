-- Staff Portal · © cmeproject. All rights reserved.
--
-- Milestone 2: tasks, helpers and email notifications.
--
-- Tasks are only changed through the functions below (create_task,
-- add_task_helper). Each one checks who is asking, records what happened in
-- the task's timeline (task_events, which can never be edited) and queues
-- the emails to send (email_outbox).

-- ---------------------------------------------------------------------------
-- Types
-- ---------------------------------------------------------------------------

create type public.task_priority as enum ('low', 'medium', 'high', 'urgent');

create type public.task_status as enum (
  'assigned',
  'in_progress',
  'escalated',
  'awaiting_approval',
  'completed',
  'closed'
);

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table public.tasks (
  id           uuid primary key default gen_random_uuid(),
  org_id       uuid not null default public.default_org_id() references public.organisation (id),
  -- Short number people can quote: T-0001, T-0002, ...
  number       bigint generated always as identity unique,
  title        text not null check (length(trim(title)) between 1 and 200),
  description  text not null default '',
  registry_id  uuid not null references public.registries (id),
  priority     public.task_priority not null default 'medium',
  status       public.task_status not null default 'assigned',
  assigned_to  uuid not null references public.profiles (id),
  created_by   uuid not null references public.profiles (id),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  due_date     date,
  escalated    boolean not null default false,
  completed_at timestamptz,
  closed_at    timestamptz
);

create index tasks_assigned_idx on public.tasks (assigned_to);
create index tasks_created_by_idx on public.tasks (created_by);
create index tasks_registry_idx on public.tasks (registry_id);
create index tasks_due_idx on public.tasks (due_date);

create table public.task_helpers (
  task_id  uuid not null references public.tasks (id) on delete cascade,
  user_id  uuid not null references public.profiles (id),
  added_by uuid references public.profiles (id),
  added_at timestamptz not null default now(),
  primary key (task_id, user_id)
);

create index task_helpers_user_idx on public.task_helpers (user_id);

-- The task's timeline. Append-only: never edited or deleted.
create table public.task_events (
  id         bigint generated always as identity primary key,
  task_id    uuid not null references public.tasks (id),
  actor_id   uuid references public.profiles (id),
  type       text not null,
  from_value text,
  to_value   text,
  comment    text,
  created_at timestamptz not null default now()
);

create index task_events_task_idx on public.task_events (task_id, created_at);

create trigger task_events_append_only
  before update or delete on public.task_events
  for each row execute function public.block_audit_changes();

create trigger task_events_no_truncate
  before truncate on public.task_events
  for each statement execute function public.block_audit_changes();

-- Emails waiting to be sent. The app sends them straight away; anything
-- that fails stays here to be retried.
create table public.email_outbox (
  id         bigint generated always as identity primary key,
  to_user    uuid not null references public.profiles (id),
  cc_users   uuid[] not null default '{}',
  template   text not null,
  task_id    uuid references public.tasks (id),
  data       jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  sent_at    timestamptz,
  attempts   int not null default 0,
  last_error text
);

create index email_outbox_pending_idx on public.email_outbox (created_at) where sent_at is null;

-- ---------------------------------------------------------------------------
-- Who can see a task
-- ---------------------------------------------------------------------------

-- Support workers: tasks assigned to them, helping on, or created by them.
-- Team leaders: also tasks of the support workers in their team.
-- Managers: also every task in the registries they manage.
-- System admins: everything.
-- Records stay readable when the Tasks feature is switched off.
create function public.can_see_task(p_task_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and exists (
    select 1
      from public.tasks t
     where t.id = p_task_id
       and (
         t.assigned_to = auth.uid()
         or t.created_by = auth.uid()
         or exists (select 1 from public.task_helpers h where h.task_id = t.id and h.user_id = auth.uid())
         or public.leads_user(t.assigned_to)
         or public.leads_user(t.created_by)
         or (
           public.has_role(array['manager', 'system_admin']::public.app_role[])
           and exists (select 1 from public.registry_managers rm
                        where rm.registry_id = t.registry_id and rm.user_id = auth.uid())
         )
         or public.is_system_admin()
       )
  )
$$;

-- ---------------------------------------------------------------------------
-- Changing tasks (only through these functions)
-- ---------------------------------------------------------------------------

-- Queue a task email, unless email notifications are switched off.
create function public.queue_task_email(
  p_template text,
  p_task_id uuid,
  p_to uuid,
  p_cc uuid[] default '{}',
  p_data jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.feature_enabled('email_notifications') then
    return;
  end if;
  -- Nobody is emailed about their own action, and inactive people never are.
  if p_to = auth.uid() or not exists (select 1 from public.profiles where id = p_to and active) then
    return;
  end if;
  insert into public.email_outbox (to_user, cc_users, template, task_id, data)
  values (
    p_to,
    coalesce((select array_agg(distinct c) from unnest(p_cc) c
               join public.profiles p on p.id = c and p.active
              where c <> p_to and c <> auth.uid()), '{}'),
    p_template, p_task_id, coalesce(p_data, '{}'::jsonb)
  );
end;
$$;

create function public.create_task(
  p_title text,
  p_registry_id uuid,
  p_assigned_to uuid,
  p_description text default '',
  p_priority public.task_priority default 'medium',
  p_due_date date default null,
  p_helpers uuid[] default '{}'
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
  if not exists (select 1 from public.registries where id = p_registry_id and active) then
    raise exception 'Choose a registry that is in use';
  end if;
  if not exists (select 1 from public.profiles where id = p_assigned_to and active) then
    raise exception 'Choose someone who can sign in to look after this task';
  end if;

  select coalesce(array_agg(distinct h), '{}') into v_helpers
    from unnest(coalesce(p_helpers, '{}')) h
    join public.profiles p on p.id = h and p.active
   where h <> p_assigned_to;

  insert into public.tasks (title, description, registry_id, priority, assigned_to, created_by, due_date)
  values (trim(p_title), coalesce(trim(p_description), ''), p_registry_id, p_priority,
          p_assigned_to, auth.uid(), p_due_date)
  returning id into v_task_id;

  insert into public.task_events (task_id, actor_id, type, to_value)
  values (v_task_id, auth.uid(), 'created', p_assigned_to::text);

  foreach v_helper in array v_helpers loop
    insert into public.task_helpers (task_id, user_id, added_by) values (v_task_id, v_helper, auth.uid());
    insert into public.task_events (task_id, actor_id, type, to_value)
    values (v_task_id, auth.uid(), 'helper_added', v_helper::text);
  end loop;

  -- The person looking after it, with helpers copied in.
  perform public.queue_task_email('task_assigned', v_task_id, p_assigned_to, v_helpers);
  -- If the person looking after it is also the creator, helpers still hear.
  if p_assigned_to = auth.uid() then
    foreach v_helper in array v_helpers loop
      perform public.queue_task_email('helper_added', v_task_id, v_helper);
    end loop;
  end if;
  -- Registry managers hear about every new task.
  for v_manager in
    select rm.user_id from public.registry_managers rm
     where rm.registry_id = p_registry_id
       and rm.user_id <> p_assigned_to
       and not (rm.user_id = any (v_helpers))
  loop
    perform public.queue_task_email('task_created_manager', v_task_id, v_manager);
  end loop;

  return v_task_id;
end;
$$;

-- "Tag someone to help out": anyone who can see the task can add a helper.
create function public.add_task_helper(p_task_id uuid, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.can_see_task(p_task_id) then
    raise exception 'You can''t change this task';
  end if;
  if not public.feature_enabled('tasks') then
    raise exception 'Tasks are switched off at the moment';
  end if;
  if not exists (select 1 from public.profiles where id = p_user_id and active) then
    raise exception 'Choose someone who can sign in';
  end if;
  if exists (select 1 from public.tasks where id = p_task_id and assigned_to = p_user_id) then
    raise exception 'They are already looking after this task';
  end if;
  if exists (select 1 from public.task_helpers where task_id = p_task_id and user_id = p_user_id) then
    raise exception 'They are already helping on this task';
  end if;

  insert into public.task_helpers (task_id, user_id, added_by) values (p_task_id, p_user_id, auth.uid());
  insert into public.task_events (task_id, actor_id, type, to_value)
  values (p_task_id, auth.uid(), 'helper_added', p_user_id::text);
  update public.tasks set updated_at = now() where id = p_task_id;

  perform public.queue_task_email('helper_added', p_task_id, p_user_id);
end;
$$;

-- ---------------------------------------------------------------------------
-- Row Level Security: read-only from the app; changes go through functions
-- ---------------------------------------------------------------------------

alter table public.tasks        enable row level security;
alter table public.task_helpers enable row level security;
alter table public.task_events  enable row level security;
alter table public.email_outbox enable row level security;

create policy "see tasks you have access to" on public.tasks
  for select to authenticated using (public.can_see_task(id));
create policy "see helpers on tasks you have access to" on public.task_helpers
  for select to authenticated using (public.can_see_task(task_id));
create policy "see the timeline of tasks you have access to" on public.task_events
  for select to authenticated using (public.can_see_task(task_id));
-- email_outbox: no policies, so only the server (service role) can read it.

revoke insert, update, delete, truncate on public.tasks, public.task_helpers, public.task_events, public.email_outbox
  from anon, authenticated;
revoke all on public.email_outbox from anon, authenticated;

revoke execute on function public.queue_task_email(text, uuid, uuid, uuid[], jsonb) from public, anon, authenticated;
revoke execute on function public.create_task(text, uuid, uuid, text, public.task_priority, date, uuid[]) from public, anon;
revoke execute on function public.add_task_helper(uuid, uuid) from public, anon;
grant execute on function public.create_task(text, uuid, uuid, text, public.task_priority, date, uuid[]) to authenticated;
grant execute on function public.add_task_helper(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Settings
-- ---------------------------------------------------------------------------

insert into public.app_settings (key, value, label, description, is_public) values
  ('region.timezone', '"Australia/Melbourne"', 'Time zone',
   'Used for due dates, "due this week" and "overdue". For example Australia/Melbourne or Australia/Perth.', false)
on conflict (key) do nothing;
