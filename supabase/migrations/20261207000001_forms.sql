-- Staff Portal · © cmeproject. All rights reserved.
--
-- Forms (cmeprojects, premium). Managers and/or staff admins (the system
-- admin chooses) make simple forms: a title, a note and questions. They try
-- them out, publish, and send them to people, a team or everyone (bell and
-- email, with an optional due date), or make them a Compliance item. Each
-- form has a link and a QR code. Only the person who made a form, and anyone
-- they share it with, can change it or see its replies.

insert into public.features (key, label, description, enabled, sort_order, premium, included) values
  ('forms', 'Forms',
   'Managers and staff admins make forms, send them to staff or put them in Compliance, and see the replies.',
   false, 78, true, false)
on conflict (key) do nothing;

insert into public.app_settings (key, value, label, description, is_public) values
  ('forms.maker_roles', '["manager"]', 'Who can make forms',
   'Besides the system admin. They see Forms in the menu with + New form.', false)
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- Forms, questions, who it's shared with and sent to, and replies
-- ---------------------------------------------------------------------------

create table if not exists public.forms (
  id             uuid primary key default gen_random_uuid(),
  org_id         uuid not null default public.default_org_id() references public.organisation (id),
  title          text not null check (length(trim(title)) between 1 and 120),
  intro          text not null default '' check (length(intro) <= 2000),
  status         text not null default 'draft' check (status in ('draft', 'published')),
  -- Turned off: hidden from staff, replies kept.
  enabled        boolean not null default true,
  -- Once per person, or as many times as needed (e.g. an incident form).
  repeatable     boolean not null default false,
  anonymous      boolean not null default false,
  show_header    boolean not null default true,
  show_contact   boolean not null default true,
  notify_creator boolean not null default false,
  due_date       date,
  closes_on      date,
  created_by     uuid not null references public.profiles (id) default auth.uid(),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  published_at   timestamptz
);

create table if not exists public.form_questions (
  id         uuid primary key default gen_random_uuid(),
  form_id    uuid not null references public.forms (id) on delete cascade,
  label      text not null check (length(trim(label)) between 1 and 300),
  type       text not null check (type in ('text', 'long', 'choice', 'multi', 'yesno', 'date', 'number', 'file', 'signature')),
  required   boolean not null default false,
  help       text not null default '' check (length(help) <= 300),
  options    jsonb not null default '[]' check (jsonb_typeof(options) = 'array'),
  sort_order int not null default 0,
  -- Taken off the form: old replies keep their answers.
  archived   boolean not null default false
);
create index if not exists form_questions_form on public.form_questions (form_id, sort_order);

create table if not exists public.form_collaborators (
  form_id uuid not null references public.forms (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  primary key (form_id, user_id)
);

create table if not exists public.form_recipients (
  form_id     uuid not null references public.forms (id) on delete cascade,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  sent_at     timestamptz not null default now(),
  reminded_at timestamptz,
  primary key (form_id, user_id)
);

-- Who has filled it in (kept even for anonymous forms, so "still to do" works).
create table if not exists public.form_completions (
  form_id uuid not null references public.forms (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  done_at timestamptz not null default now(),
  primary key (form_id, user_id)
);

create table if not exists public.form_responses (
  id           bigint generated always as identity primary key,
  form_id      uuid not null references public.forms (id) on delete cascade,
  -- Empty for anonymous forms once sent.
  user_id      uuid references public.profiles (id) on delete set null,
  answers      jsonb not null default '{}' check (jsonb_typeof(answers) = 'object'),
  status       text not null default 'submitted' check (status in ('draft', 'submitted')),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  submitted_at timestamptz
);
create index if not exists form_responses_form on public.form_responses (form_id, submitted_at desc);
-- One saved draft per person per form.
create unique index if not exists form_responses_one_draft on public.form_responses (form_id, user_id) where status = 'draft';

-- A form can be a Compliance item: staff fill it in as part of onboarding.
alter table public.compliance_items add column if not exists form_id uuid references public.forms (id) on delete set null;
alter table public.compliance_items drop constraint if exists compliance_items_kind_check;
alter table public.compliance_items add constraint compliance_items_kind_check check (kind in ('read', 'training', 'upload', 'form'));

-- ---------------------------------------------------------------------------
-- Who can do what
-- ---------------------------------------------------------------------------

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

create or replace function public.can_manage_form(p_form uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and public.feature_enabled('forms') and (
    public.is_system_admin()
    or exists (select 1 from public.forms where id = p_form and created_by = auth.uid())
    or exists (select 1 from public.form_collaborators where form_id = p_form and user_id = auth.uid()))
$$;

create or replace function public.can_fill_form(p_form uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and public.feature_enabled('forms') and exists (
    select 1 from public.forms f
     where f.id = p_form and f.status = 'published' and f.enabled
       and (f.closes_on is null or f.closes_on >= public.local_today()))
$$;

alter table public.forms enable row level security;
alter table public.form_questions enable row level security;
alter table public.form_collaborators enable row level security;
alter table public.form_recipients enable row level security;
alter table public.form_completions enable row level security;
alter table public.form_responses enable row level security;

drop policy if exists "forms are seen by their managers, or to fill in" on public.forms;
create policy "forms are seen by their managers, or to fill in" on public.forms for select to authenticated
  using ((created_by = auth.uid() and public.is_member()) or public.can_manage_form(id) or public.can_fill_form(id));
drop policy if exists "form makers add forms" on public.forms;
create policy "form makers add forms" on public.forms for insert to authenticated
  with check (public.can_make_forms() and created_by = auth.uid());
drop policy if exists "form managers change forms" on public.forms;
create policy "form managers change forms" on public.forms for update to authenticated
  using (public.can_manage_form(id)) with check (public.can_manage_form(id));
drop policy if exists "form managers delete forms" on public.forms;
create policy "form managers delete forms" on public.forms for delete to authenticated using (public.can_manage_form(id));

drop policy if exists "questions follow their form" on public.form_questions;
create policy "questions follow their form" on public.form_questions for select to authenticated
  using (public.can_manage_form(form_id) or public.can_fill_form(form_id));
drop policy if exists "form managers change questions" on public.form_questions;
create policy "form managers change questions" on public.form_questions for all to authenticated
  using (public.can_manage_form(form_id)) with check (public.can_manage_form(form_id));

drop policy if exists "collaborators are seen with the form" on public.form_collaborators;
create policy "collaborators are seen with the form" on public.form_collaborators for select to authenticated
  using (public.can_manage_form(form_id));
drop policy if exists "the form's maker shares it" on public.form_collaborators;
create policy "the form's maker shares it" on public.form_collaborators for all to authenticated
  using (public.is_system_admin() or exists (select 1 from public.forms where id = form_id and created_by = auth.uid()))
  with check (public.is_system_admin() or exists (select 1 from public.forms where id = form_id and created_by = auth.uid()));

drop policy if exists "recipients see their own, managers all" on public.form_recipients;
create policy "recipients see their own, managers all" on public.form_recipients for select to authenticated
  using (user_id = auth.uid() or public.can_manage_form(form_id));
drop policy if exists "completions: your own, or the form's managers" on public.form_completions;
create policy "completions: your own, or the form's managers" on public.form_completions for select to authenticated
  using (user_id = auth.uid() or public.can_manage_form(form_id));
drop policy if exists "replies: your own, or the form's managers" on public.form_responses;
create policy "replies: your own, or the form's managers" on public.form_responses for select to authenticated
  using (user_id = auth.uid() or (status = 'submitted' and public.can_manage_form(form_id)));
-- Sending, replying and completions only through the functions below.
revoke insert, update, delete, truncate on public.form_recipients, public.form_completions, public.form_responses from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Filling in
-- ---------------------------------------------------------------------------

-- Save a reply (p_send = false keeps it as a draft to finish later).
create or replace function public.submit_form_response(p_form uuid, p_answers jsonb, p_send boolean default true)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  f public.forms;
  q record;
  v text;
  v_clean jsonb := '{}'::jsonb;
  v_id bigint;
  v_item uuid;
begin
  if not public.can_fill_form(p_form) then
    raise exception 'This form isn''t open';
  end if;
  select * into f from public.forms where id = p_form;
  if not f.repeatable and exists (select 1 from public.form_completions where form_id = f.id and user_id = auth.uid()) then
    raise exception 'You''ve already filled this in';
  end if;
  if p_answers is null or jsonb_typeof(p_answers) <> 'object' then
    raise exception 'Fill in the form';
  end if;

  for q in select * from public.form_questions where form_id = f.id and not archived order by sort_order loop
    if q.type = 'multi' then
      if jsonb_typeof(p_answers -> q.id::text) = 'array' and jsonb_array_length(p_answers -> q.id::text) > 0 then
        if exists (select 1 from jsonb_array_elements_text(p_answers -> q.id::text) x where not q.options ? x) then
          raise exception '%: choose from the list', q.label;
        end if;
        v_clean := v_clean || jsonb_build_object(q.id::text, p_answers -> q.id::text);
      elsif q.required and p_send then
        raise exception '%: choose at least one', q.label;
      end if;
      continue;
    end if;
    v := nullif(trim(p_answers ->> q.id::text), '');
    if v is null then
      if q.required and p_send then
        raise exception '%: this is needed', q.label;
      end if;
      continue;
    end if;
    if length(v) > (case when q.type = 'long' then 5000 else 300 end) then
      raise exception '%: that''s too long', q.label;
    end if;
    if q.type = 'choice' and not q.options ? v then
      raise exception '%: choose from the list', q.label;
    elsif q.type = 'yesno' and v not in ('Yes', 'No') then
      raise exception '%: choose Yes or No', q.label;
    elsif q.type = 'date' and v !~ '^\d{4}-\d{2}-\d{2}$' then
      raise exception '%: enter a date', q.label;
    elsif q.type = 'number' and v !~ '^-?\d+(\.\d+)?$' then
      raise exception '%: enter a number', q.label;
    elsif q.type = 'file' and v not like auth.uid()::text || '/%' then
      raise exception '%: upload the file again', q.label;
    end if;
    v_clean := v_clean || jsonb_build_object(q.id::text, v);
  end loop;

  -- Their saved draft becomes this reply (or stays a draft).
  select id into v_id from public.form_responses where form_id = f.id and user_id = auth.uid() and status = 'draft';
  if v_id is not null then
    update public.form_responses
       set answers = v_clean, updated_at = now(),
           status = case when p_send then 'submitted' else 'draft' end,
           submitted_at = case when p_send then now() end,
           user_id = case when p_send and f.anonymous then null else user_id end
     where id = v_id;
  else
    insert into public.form_responses (form_id, user_id, answers, status, submitted_at)
    values (f.id, case when p_send and f.anonymous then null else auth.uid() end, v_clean,
            case when p_send then 'submitted' else 'draft' end, case when p_send then now() end)
    returning id into v_id;
  end if;

  if p_send then
    insert into public.form_completions (form_id, user_id) values (f.id, auth.uid())
    on conflict (form_id, user_id) do update set done_at = now();
    -- Part of Compliance: it counts as done.
    for v_item in select id from public.compliance_items where form_id = f.id and active loop
      insert into public.compliance_records (item_id, user_id, version, status)
      select v_item, auth.uid(), version, 'done' from public.compliance_items where id = v_item;
    end loop;
    if f.notify_creator and f.created_by <> auth.uid() then
      perform public.notify(f.created_by, 'form_reply', format('New reply: %s', f.title),
        case when f.anonymous then 'Someone sent a reply.' else format('%s sent a reply.', public.my_name()) end,
        '/forms/' || f.id || '/replies', false);
    end if;
  end if;
  return v_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Publishing, sending, reminding and Compliance
-- ---------------------------------------------------------------------------

-- Send to people, a team or everyone: bell and email, with the due date.
create or replace function public.send_form(p_form uuid, p_users uuid[], p_team uuid default null, p_everyone boolean default false)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  f public.forms;
  v_user uuid;
  v_count int := 0;
begin
  if not public.can_manage_form(p_form) then
    raise exception 'You can''t send this form';
  end if;
  select * into f from public.forms where id = p_form;
  if f.status <> 'published' or not f.enabled then
    raise exception 'Publish the form first';
  end if;
  for v_user in
    select p.id from public.profiles p
     where p.active and p.role <> 'system_admin'
       and (p_everyone
            or p.id = any (coalesce(p_users, '{}'))
            or (p_team is not null and exists (select 1 from public.team_members m where m.team_id = p_team and m.user_id = p.id)))
  loop
    insert into public.form_recipients (form_id, user_id) values (f.id, v_user)
    on conflict (form_id, user_id) do update set sent_at = now();
    perform public.notify(v_user, 'form_sent', format('Please fill in: %s', f.title),
      case when f.due_date is not null then format('Due %s. From %s.', to_char(f.due_date, 'FMDD Mon YYYY'), public.my_name())
           else format('From %s.', public.my_name()) end,
      '/forms/' || f.id, true);
    v_count := v_count + 1;
  end loop;
  perform public.write_audit('form_sent', 'form', f.id::text, jsonb_build_object('people', v_count));
  return v_count;
end;
$$;

-- A reminder to those it was sent to who haven't filled it in.
create or replace function public.remind_form(p_form uuid)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  f public.forms;
  v_user uuid;
  v_count int := 0;
begin
  if not public.can_manage_form(p_form) then
    raise exception 'You can''t remind people about this form';
  end if;
  select * into f from public.forms where id = p_form;
  for v_user in
    select r.user_id from public.form_recipients r
     where r.form_id = f.id
       and not exists (select 1 from public.form_completions c where c.form_id = f.id and c.user_id = r.user_id)
  loop
    perform public.notify(v_user, 'form_sent', format('Reminder: %s', f.title),
      case when f.due_date is not null then format('Please fill it in by %s.', to_char(f.due_date, 'FMDD Mon YYYY')) else 'Please fill it in.' end,
      '/forms/' || f.id, true);
    update public.form_recipients set reminded_at = now() where form_id = f.id and user_id = v_user;
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

-- Put the form in Compliance for these roles and teams (everyone if both empty).
create or replace function public.form_to_compliance(p_form uuid, p_roles public.app_role[], p_teams uuid[])
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  f public.forms;
  v_item uuid;
begin
  if not public.can_manage_form(p_form) then
    raise exception 'You can''t change this form';
  end if;
  select * into f from public.forms where id = p_form;
  if f.status <> 'published' or not f.enabled then
    raise exception 'Publish the form first';
  end if;
  select id into v_item from public.compliance_items where form_id = f.id;
  if v_item is null then
    insert into public.compliance_items (kind, title, description, form_id, applies_roles, applies_teams, sort_order)
    values ('form', f.title, left(f.intro, 300), f.id, coalesce(p_roles, '{}'), coalesce(p_teams, '{}'), 200)
    returning id into v_item;
  else
    update public.compliance_items
       set title = f.title, applies_roles = coalesce(p_roles, '{}'), applies_teams = coalesce(p_teams, '{}'), active = true, updated_at = now()
     where id = v_item;
  end if;
  return v_item;
end;
$$;

create or replace function public.form_out_of_compliance(p_form uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.can_manage_form(p_form) then
    raise exception 'You can''t change this form';
  end if;
  update public.compliance_items set active = false, updated_at = now() where form_id = p_form;
end;
$$;

-- Names of the people a form's managers may see in its report (staff names only).
create or replace function public.form_people(p_form uuid)
returns table (id uuid, name text, email text, role public.app_role)
language sql
stable
security definer
set search_path = ''
as $$
  select p.id, coalesce(nullif(p.full_name, ''), p.email), p.email, p.role
    from public.profiles p
   where public.can_manage_form(p_form) and p.active and p.role <> 'system_admin'
   order by 2
$$;

-- Who made the form, for "Questions? Contact …" at the bottom.
create or replace function public.form_contact(p_form uuid)
returns table (name text, email text)
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(nullif(p.full_name, ''), p.email), p.email
    from public.forms f join public.profiles p on p.id = f.created_by
   where f.id = p_form and (public.can_fill_form(p_form) or public.can_manage_form(p_form))
$$;

revoke execute on function public.can_make_forms(), public.can_manage_form(uuid), public.can_fill_form(uuid),
  public.submit_form_response(uuid, jsonb, boolean), public.send_form(uuid, uuid[], uuid, boolean), public.remind_form(uuid),
  public.form_to_compliance(uuid, public.app_role[], uuid[]), public.form_out_of_compliance(uuid),
  public.form_people(uuid), public.form_contact(uuid) from public, anon;
grant execute on function public.can_make_forms(), public.can_manage_form(uuid), public.can_fill_form(uuid),
  public.submit_form_response(uuid, jsonb, boolean), public.send_form(uuid, uuid[], uuid, boolean), public.remind_form(uuid),
  public.form_to_compliance(uuid, public.app_role[], uuid[]), public.form_out_of_compliance(uuid),
  public.form_people(uuid), public.form_contact(uuid) to authenticated;

-- Changes to forms and questions go in the change log.
drop trigger if exists forms_log on public.forms;
create trigger forms_log after insert or update or delete on public.forms
  for each row execute function public.log_feature_setup('form');

-- Files and photos attached to replies.
do $storage$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  insert into storage.buckets (id, name, public) values ('form-files', 'form-files', false) on conflict (id) do nothing;
  drop policy if exists "staff upload form files" on storage.objects;
  create policy "staff upload form files" on storage.objects
    for insert to authenticated
    with check (bucket_id = 'form-files' and public.is_member() and (storage.foldername(name))[1] = auth.uid()::text);
  drop policy if exists "form files are seen with their replies" on storage.objects;
  create policy "form files are seen with their replies" on storage.objects
    for select to authenticated
    using (bucket_id = 'form-files' and public.is_member()
           and ((storage.foldername(name))[1] = auth.uid()::text
                or exists (select 1 from public.form_responses r
                            where r.answers::text like '%' || storage.objects.name || '%'
                              and public.can_manage_form(r.form_id))));
end;
$storage$;

-- New replies and sends show up straight away on open pages.
do $live$
declare
  t text;
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    return;
  end if;
  foreach t in array array['forms', 'form_responses', 'form_completions'] loop
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end;
$live$;
