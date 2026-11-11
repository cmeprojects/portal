-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects Phase 3: staff records.
--   1. First Aid, CPR and Life saving as separate default onboarding items
--      (switched off until the company chooses them).
--   2. Expiry reminders in stages: 60, 30 and 7 days before, on the day, and
--      once expired, to the person and the people who manage onboarding.
--      Visa expiry too, to the person and those with Identity and work
--      rights access covering them.
--   3. Sensitive records: bank details and super (Payroll and tax access),
--      work rights and visa (Identity and work rights access). Readable and
--      changeable only by the person and people whose access covers them
--      (has_access, Phase 2). Never in the directory, dashboards,
--      notifications or reports.
--   4. A record of access: every change is logged by the database; views,
--      reveals and downloads are logged by the app before anything is shown.
--   5. A separate private file store for these documents.
-- Tax file numbers are NOT collected yet (waiting on the accountant/ATO review).
-- No new SECURITY DEFINER function (run_compliance_alerts is updated).

-- ---------------------------------------------------------------------------
-- 1. Default certificate items
-- ---------------------------------------------------------------------------
alter table public.compliance_items disable trigger compliance_items_guard;
insert into public.compliance_items (kind, title, description, category, needs_expiry, needs_number, needs_issue_date, before_work, active, sort_order, created_by)
select v.kind, v.title, v.description, 'certificate', true, false, true, false, false, v.sort_order, null
  from (values
    ('upload', 'First Aid certificate', 'HLTAID011 Provide First Aid (usually renewed every 3 years).', 27),
    ('upload', 'CPR certificate', 'HLTAID009 Provide cardiopulmonary resuscitation (renewed every year).', 28),
    ('upload', 'Life saving certificate', 'For example a Bronze Medallion or pool lifeguard certificate, if your work needs it.', 29)
  ) as v(kind, title, description, sort_order)
 where not exists (select 1 from public.compliance_items c where c.title = v.title);
alter table public.compliance_items enable trigger compliance_items_guard;

-- ---------------------------------------------------------------------------
-- 2. Staged expiry reminders
-- ---------------------------------------------------------------------------
alter table public.compliance_alerts drop constraint if exists compliance_alerts_step_check;
alter table public.compliance_alerts add constraint compliance_alerts_step_check
  check (step in ('expiring', 'expired', 'd60', 'd30', 'd7', 'today'));

-- Which reminder is due for something that expires on p_expires (null: none yet).
create or replace function public.expiry_stage(p_expires date)
returns text
language sql
stable
security invoker
set search_path = ''
as $$
  select case
    when p_expires is null then null
    when p_expires < public.local_today() then 'expired'
    when p_expires = public.local_today() then 'today'
    when p_expires - public.local_today() <= 7 then 'd7'
    when p_expires - public.local_today() <= 30 then 'd30'
    when p_expires - public.local_today() <= 60 then 'd60'
  end
$$;

-- ---------------------------------------------------------------------------
-- 3. Sensitive records
-- ---------------------------------------------------------------------------
create table if not exists public.staff_bank (
  user_id        uuid primary key references public.profiles (id) on delete cascade,
  account_name   text not null default '' check (length(account_name) <= 100),
  bsb            text not null default '' check (bsb = '' or bsb ~ '^\d{3}-\d{3}$'),
  account_number text not null default '' check (account_number = '' or account_number ~ '^\d{5,9}$'),
  updated_at     timestamptz not null default now(),
  updated_by     uuid references public.profiles (id),
  verified_at    timestamptz,
  verified_by    uuid references public.profiles (id)
);

create table if not exists public.staff_super (
  user_id       uuid primary key references public.profiles (id) on delete cascade,
  fund_name     text not null default '' check (length(fund_name) <= 120),
  fund_abn      text not null default '' check (fund_abn = '' or fund_abn ~ '^\d{11}$'),
  usi           text not null default '' check (length(usi) <= 20),
  member_number text not null default '' check (length(member_number) <= 30),
  choice_doc    text not null default '' check (length(choice_doc) <= 300),
  choice_name   text not null default '' check (length(choice_name) <= 200),
  updated_at    timestamptz not null default now(),
  updated_by    uuid references public.profiles (id),
  verified_at   timestamptz,
  verified_by   uuid references public.profiles (id)
);

create table if not exists public.staff_work_rights (
  user_id         uuid primary key references public.profiles (id) on delete cascade,
  status          text not null default '' check (status in ('', 'citizen', 'permanent_resident', 'nz_citizen', 'visa')),
  visa_subclass   text not null default '' check (length(visa_subclass) <= 20),
  visa_conditions text not null default '' check (length(visa_conditions) <= 500),
  visa_expiry     date,
  vevo_checked_on date,
  visa_doc        text not null default '' check (length(visa_doc) <= 300),
  visa_doc_name   text not null default '' check (length(visa_doc_name) <= 200),
  vevo_doc        text not null default '' check (length(vevo_doc) <= 300),
  vevo_doc_name   text not null default '' check (length(vevo_doc_name) <= 200),
  updated_at      timestamptz not null default now(),
  updated_by      uuid references public.profiles (id),
  verified_at     timestamptz,
  verified_by     uuid references public.profiles (id),
  check (status <> 'visa' or visa_subclass <> '')
);

-- Which access area each table belongs to.
create or replace function public.record_area(p_table text)
returns text
language sql
immutable
security invoker
set search_path = ''
as $$
  select case p_table when 'staff_bank' then 'payroll_tax' when 'staff_super' then 'payroll_tax' when 'staff_work_rights' then 'identity_docs' end
$$;

-- The record of access: who did what to whose sensitive record, and when.
create table if not exists public.sensitive_access_log (
  id         bigint generated always as identity primary key,
  at         timestamptz not null default now(),
  actor_id   uuid default auth.uid() references public.profiles (id) on delete set null,
  subject_id uuid references public.profiles (id) on delete set null,
  area       text not null check (area in ('payroll_tax', 'identity_docs')),
  action     text not null check (action in ('view', 'reveal', 'download', 'upload', 'change', 'verify', 'refused')),
  detail     text not null default '' check (length(detail) <= 200)
);
create index if not exists sensitive_access_log_subject on public.sensitive_access_log (subject_id, at desc);

alter table public.staff_bank enable row level security;
alter table public.staff_super enable row level security;
alter table public.staff_work_rights enable row level security;
alter table public.sensitive_access_log enable row level security;
revoke all on public.staff_bank, public.staff_super, public.staff_work_rights, public.sensitive_access_log from anon;
revoke delete, truncate on public.staff_bank, public.staff_super, public.staff_work_rights from authenticated;
grant select, insert, update on public.staff_bank, public.staff_super, public.staff_work_rights to authenticated;
revoke update, delete, truncate on public.sensitive_access_log from authenticated;
grant select, insert on public.sensitive_access_log to authenticated;

do $$
declare
  t text;
begin
  foreach t in array array['staff_bank', 'staff_super', 'staff_work_rights'] loop
    execute format('drop policy if exists "the person and people with access" on public.%I', t);
    execute format($p$create policy "the person and people with access" on public.%I for all to authenticated
      using ((select public.is_member()) and (user_id = (select auth.uid()) or public.has_access(%L, user_id)))
      with check ((select public.is_member()) and (user_id = (select auth.uid()) or public.has_access(%L, user_id)))$p$,
      t, public.record_area(t), public.record_area(t));
  end loop;
end;
$$;

-- Log entries: written as yourself only; read by the system admin.
drop policy if exists "log your own actions" on public.sensitive_access_log;
create policy "log your own actions" on public.sensitive_access_log for insert to authenticated
  with check (actor_id = (select auth.uid()) and (select public.is_member()));
drop policy if exists "the system admin reads the access log" on public.sensitive_access_log;
create policy "the system admin reads the access log" on public.sensitive_access_log for select to authenticated
  using ((select public.is_system_admin()));

-- Every change: who and when is set here; a person's own change needs
-- checking again; only someone with access (never the person) verifies; and
-- the change goes in the access log. Runs as the person making the change.
create or replace function public.guard_staff_record()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_area text := public.record_area(tg_table_name);
  v_by uuid := auth.uid();
  v_checker boolean := v_by is not null and v_by <> new.user_id and public.has_access(v_area, new.user_id);
  v_verify boolean;
begin
  if v_by is null then
    return new; -- system jobs
  end if;
  v_verify := new.verified_at is not null and (tg_op = 'INSERT' or new.verified_at is distinct from old.verified_at);
  if v_verify and not v_checker then
    raise exception 'Only someone with access to this record (not the person themselves) can mark it checked.';
  end if;
  new.updated_at := now();
  new.updated_by := v_by;
  if v_verify then
    new.verified_at := now();
    new.verified_by := v_by;
  elsif tg_op = 'UPDATE' and (to_jsonb(new) - 'verified_at' - 'verified_by' - 'updated_at' - 'updated_by')
                         is distinct from (to_jsonb(old) - 'verified_at' - 'verified_by' - 'updated_at' - 'updated_by') then
    -- Any change to the details means it needs checking again.
    new.verified_at := null;
    new.verified_by := null;
  end if;
  insert into public.sensitive_access_log (actor_id, subject_id, area, action, detail)
  values (v_by, new.user_id, v_area, case when v_verify then 'verify' else 'change' end,
          case tg_table_name when 'staff_bank' then 'Bank details' when 'staff_super' then 'Super' else 'Work rights' end);
  return new;
end;
$$;

revoke execute on function public.guard_staff_record() from public, anon, authenticated;

do $$
declare
  t text;
begin
  foreach t in array array['staff_bank', 'staff_super', 'staff_work_rights'] loop
    execute format('drop trigger if exists guard_staff_record on public.%I', t);
    execute format('create trigger guard_staff_record before insert or update on public.%I for each row execute function public.guard_staff_record()', t);
  end loop;
end;
$$;

revoke execute on function public.record_area(text) from public, anon;
grant execute on function public.record_area(text) to authenticated;
revoke execute on function public.expiry_stage(date) from public, anon;
grant execute on function public.expiry_stage(date) to authenticated;

-- ---------------------------------------------------------------------------
-- 5. Private file store: <area>/<person id>/<file>
-- ---------------------------------------------------------------------------
do $$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values ('staff-records', 'staff-records', false, 10485760,
          array['application/pdf', 'image/jpeg', 'image/png', 'image/webp', 'application/msword',
                'application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
  on conflict (id) do nothing;

  drop policy if exists "staff records: the person and people with access read" on storage.objects;
  create policy "staff records: the person and people with access read" on storage.objects for select to authenticated
    using (bucket_id = 'staff-records' and (storage.foldername(name))[1] in ('payroll_tax', 'identity_docs')
           and ((storage.foldername(name))[2] = (select auth.uid())::text
                or public.has_access((storage.foldername(name))[1], ((storage.foldername(name))[2])::uuid)));
  drop policy if exists "staff records: the person and people with access upload" on storage.objects;
  create policy "staff records: the person and people with access upload" on storage.objects for insert to authenticated
    with check (bucket_id = 'staff-records' and (select public.is_member()) and (storage.foldername(name))[1] in ('payroll_tax', 'identity_docs')
           and ((storage.foldername(name))[2] = (select auth.uid())::text
                or public.has_access((storage.foldername(name))[1], ((storage.foldername(name))[2])::uuid)));
  -- No update or delete: a new copy is a new file, the old one stays.
end;
$$;

-- ---------------------------------------------------------------------------
-- 2 (continued). The daily reminders, in stages, plus visa expiry.
-- ---------------------------------------------------------------------------
create table if not exists public.work_rights_alerts (
  user_id    uuid not null references public.profiles (id) on delete cascade,
  expires_on date not null,
  step       text not null check (step in ('d60', 'd30', 'd7', 'today', 'expired')),
  sent_at    timestamptz not null default now(),
  primary key (user_id, expires_on, step)
);
alter table public.work_rights_alerts enable row level security;
revoke all on public.work_rights_alerts from anon, authenticated;

create or replace function public.run_compliance_alerts()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  s record;
  v_n int := 0;
  v_v int := 0;
  v_admin uuid;
  v_stage text;
  v_when text;
begin
  -- Documents and certificates: the latest record of each item that has an expiry date.
  for s in
    select p.id user_id, coalesce(nullif(p.full_name, ''), p.email) person, st.title, st.record_id, st.expires_on
      from public.profiles p
      cross join lateral public.compliance_status(p.id) st
     where p.active and p.role <> 'system_admin' and st.record_id is not null and st.expires_on is not null
       and st.expires_on <= public.local_today() + 60
  loop
    v_stage := public.expiry_stage(s.expires_on);
    continue when v_stage is null;
    insert into public.compliance_alerts (record_id, step) values (s.record_id, v_stage) on conflict do nothing;
    continue when not found;
    v_n := v_n + 1;
    v_when := case v_stage when 'expired' then 'has expired' when 'today' then 'expires today'
                           else format('expires in %s days', s.expires_on - public.local_today()) end;
    perform public.notify(s.user_id, case when v_stage = 'expired' then 'document_expired' else 'document_expiring' end,
      format('%s %s', s.title, v_when),
      format('Expiry date: %s. Upload a new copy on My onboarding.', to_char(s.expires_on, 'FMDD Mon YYYY')),
      '/onboarding', v_stage in ('expired', 'today', 'd7', 'd30'));
    for v_admin in select a from public.people_admins() a loop
      continue when v_admin = s.user_id;
      perform public.notify(v_admin, case when v_stage = 'expired' then 'document_expired' else 'document_expiring' end,
        format('%s: %s %s', s.person, s.title, v_when),
        format('Expiry date: %s.', to_char(s.expires_on, 'FMDD Mon YYYY')),
        '/compliance/expiry', v_stage in ('expired', 'today'));
    end loop;
  end loop;

  -- Visas: the person, and people with Identity and work rights access that covers them.
  for s in
    select w.user_id, coalesce(nullif(p.full_name, ''), p.email) person, w.visa_expiry expires_on
      from public.staff_work_rights w join public.profiles p on p.id = w.user_id
     where p.active and w.status = 'visa' and w.visa_expiry is not null and w.visa_expiry <= public.local_today() + 60
  loop
    v_stage := public.expiry_stage(s.expires_on);
    continue when v_stage is null;
    insert into public.work_rights_alerts (user_id, expires_on, step) values (s.user_id, s.expires_on, v_stage) on conflict do nothing;
    continue when not found;
    v_v := v_v + 1;
    v_when := case v_stage when 'expired' then 'has expired' when 'today' then 'expires today'
                           else format('expires in %s days', s.expires_on - public.local_today()) end;
    -- No visa details in the message: just that it needs attention.
    perform public.notify(s.user_id, case when v_stage = 'expired' then 'document_expired' else 'document_expiring' end,
      format('Your visa %s', v_when), 'Please update your work rights in My account.', '/account/records', true);
    for v_admin in
      select distinct g.user_id
        from public.access_grants g join public.profiles a on a.id = g.user_id
       where g.area = 'identity_docs' and g.revoked_at is null and (g.expires_at is null or g.expires_at > now())
         and a.active and a.role in ('manager', 'staff_admin') and g.user_id <> s.user_id
         and (g.scope = 'all' or (g.scope = 'people' and s.user_id = any (g.scope_ids))
              or (g.scope = 'teams' and exists (select 1 from public.team_members tm where tm.user_id = s.user_id and tm.team_id = any (g.scope_ids))))
    loop
      perform public.notify(v_admin, case when v_stage = 'expired' then 'document_expired' else 'document_expiring' end,
        format('%s: work rights %s', s.person, v_when), 'Open their record to check.', '/people?p=' || s.user_id, v_stage in ('expired', 'today'));
    end loop;
  end loop;
  return jsonb_build_object('document_alerts', v_n, 'visa_alerts', v_v);
end;
$$;
