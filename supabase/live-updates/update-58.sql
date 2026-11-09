-- Staff Portal · © cmeproject. All rights reserved.
-- Update 58: onboarding, compliance and clearance to work (HR Pack).
--   Onboarding complete / Compliance verified / Cleared to work, overrides,
--   cleared-only registers and cars, document details and replacements,
--   policy acknowledgement, training completion, signed agreements, defaults.
-- Safe to run again. Undo: undo-58.sql. Run update 57 first.
-- (On Development: run clear-onboarding-items.sql first if you want the old
-- read, training and upload items removed.)
begin;
--
-- Onboarding, compliance and clearance to work (cmeprojects, HR Pack).
--   * Three separate statuses: Onboarding complete (everything done or sent),
--     Compliance verified (every document and certificate checked) and Cleared
--     to work (granted by a manager, or a staff admin if delegated).
--   * Items marked "needed before working" must be done and verified before
--     someone can be cleared. The rest goes into a "Finish onboarding" task due
--     within their first week.
--   * Authorised overrides let someone work before that, with a reason and an
--     end date. Everything is in the change log.
--   * Registers can be "cleared staff only", and so can using a car: the
--     database refuses to give those tasks or trips to anyone not cleared.
--   * Documents get a category, issue date and number, and can be sent back
--     for replacement. Policies record opening and acknowledgement (typed name)
--     separately; trainings record a completion date, provider and certificate;
--     employment agreements are signed (drawn signature plus typed name, with
--     the exact version's fingerprint, time and device).
-- Uploading never marks anything as verified.

-- Items ----------------------------------------------------------------------
alter table public.compliance_items drop constraint if exists compliance_items_kind_check;
alter table public.compliance_items add constraint compliance_items_kind_check
  check (kind in ('read', 'training', 'upload', 'form', 'agreement'));
alter table public.compliance_items add column if not exists category text not null default '';
alter table public.compliance_items drop constraint if exists compliance_items_category_check;
alter table public.compliance_items add constraint compliance_items_category_check
  check (category in ('', 'qualification', 'certificate', 'screening', 'licence', 'insurance', 'identity', 'other'));
alter table public.compliance_items add column if not exists before_work boolean not null default false;
alter table public.compliance_items add column if not exists applies_titles uuid[] not null default '{}';
alter table public.compliance_items add column if not exists needs_issue_date boolean not null default false;
alter table public.compliance_items add column if not exists needs_number boolean not null default false;
-- Trainings: is a certificate needed (it's then checked like a document)?
alter table public.compliance_items add column if not exists certificate text not null default 'optional';
alter table public.compliance_items drop constraint if exists compliance_items_certificate_check;
alter table public.compliance_items add constraint compliance_items_certificate_check check (certificate in ('none', 'optional', 'required'));

-- Records --------------------------------------------------------------------
alter table public.compliance_records drop constraint if exists compliance_records_status_check;
alter table public.compliance_records add constraint compliance_records_status_check
  check (status in ('done', 'submitted', 'accepted', 'rejected', 'replace_requested'));
alter table public.compliance_records add column if not exists issued_on date;
alter table public.compliance_records add column if not exists doc_number text not null default '';
alter table public.compliance_records add column if not exists completed_on date;
alter table public.compliance_records add column if not exists provider text not null default '';
alter table public.compliance_records add column if not exists signed_name text not null default '';
alter table public.compliance_records add column if not exists signature_path text;
alter table public.compliance_records add column if not exists content_hash text not null default '';
alter table public.compliance_records add column if not exists signed_from text not null default '';

-- When a policy (or agreement) was opened, per version. Separate from acknowledging it.
create table if not exists public.compliance_opens (
  item_id   uuid not null references public.compliance_items (id) on delete cascade,
  user_id   uuid not null references public.profiles (id) on delete cascade,
  version   int not null,
  opened_at timestamptz not null default now(),
  primary key (item_id, user_id, version)
);
alter table public.compliance_opens enable row level security;
drop policy if exists "people see their own opens; compliance managers see all" on public.compliance_opens;
create policy "people see their own opens; compliance managers see all" on public.compliance_opens for select to authenticated
  using (user_id = auth.uid() or public.can_manage_compliance());

-- Statuses on the person -------------------------------------------------------
alter table public.profiles add column if not exists compliance_verified_at timestamptz;
alter table public.profiles add column if not exists cleared_at timestamptz;
alter table public.profiles add column if not exists cleared_by uuid references public.profiles (id);

create table if not exists public.work_overrides (
  id          bigint generated always as identity primary key,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  reason      text not null check (length(trim(reason)) between 3 and 500),
  until_date  date not null,
  granted_by  uuid not null references public.profiles (id),
  created_at  timestamptz not null default now(),
  ended_at    timestamptz,
  ended_by    uuid references public.profiles (id)
);
create index if not exists work_overrides_user_idx on public.work_overrides (user_id, until_date desc);
alter table public.work_overrides enable row level security;
drop policy if exists "the person and people who manage staff see overrides" on public.work_overrides;
create policy "the person and people who manage staff see overrides" on public.work_overrides for select to authenticated
  using (user_id = auth.uid() or public.can_manage_compliance() or public.can_manage_people()
         or public.has_role(array['manager']::public.app_role[]) or public.leads_user(user_id));

-- Registers: cleared staff only.
alter table public.registries add column if not exists cleared_only boolean not null default false;

-- Agreements are a Compliance part of their own (on by default, HR Pack).
insert into public.features (key, label, description, enabled, sort_order, premium, included, parent) values
  ('compliance_agreement', 'Employment agreements', 'Staff read and sign their employment agreement on screen.', true, 324, false, true, 'compliance')
on conflict (key) do nothing;

-- Settings: who besides managers clears people to work, and cars for cleared staff only.
insert into public.app_settings (key, value, label, description, is_public) values
  ('compliance.clearance_roles', '[]', 'Who can clear people to work',
   'Besides managers and the system admin. Tick staff admins to let them clear people and give overrides.', false),
  ('cars.cleared_only', 'false', 'Cars: cleared staff only',
   'Only staff cleared to work (or with an override) can start a trip.', false)
on conflict (key) do nothing;

-- Who may clear people to work: managers and the system admin, plus staff
-- admins when delegated (Settings: compliance.clearance_roles).
create or replace function public.can_grant_clearance()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.mfa_ok() and (public.my_role() in ('system_admin', 'manager')
         or (public.my_role() = 'staff_admin' and 'staff_admin' = any (public.setting_roles('compliance.clearance_roles'))))
$$;

-- A mandatory training (needed before working) always asks for a certificate.
create or replace function public.mandatory_training_needs_certificate()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.kind = 'training' and new.before_work then
    new.certificate := 'required';
  end if;
  return new;
end;
$$;
drop trigger if exists mandatory_training_needs_certificate on public.compliance_items;
create trigger mandatory_training_needs_certificate before insert or update on public.compliance_items
  for each row execute function public.mandatory_training_needs_certificate();
update public.compliance_items set certificate = 'required' where kind = 'training' and before_work and certificate <> 'required';

-- Which items apply: role, team and now job title.
create or replace function public.compliance_applies(p_item public.compliance_items, p_role public.app_role, p_teams uuid[], p_title uuid)
returns boolean
language sql
stable
set search_path = ''
as $$
  select public.compliance_applies(p_item, p_role, p_teams)
     and (cardinality(p_item.applies_titles) = 0 or p_title = any (p_item.applies_titles))
$$;

-- Everything that applies to a person, and where each is up to.
-- Internal (no permission check): used by the clearance rules, which must
-- give the same answer whoever is asking. Not callable by staff.
drop function if exists public.compliance_status_all(uuid, public.app_role, uuid[]);
create function public.compliance_status_all(p_user uuid, p_role public.app_role default null, p_teams uuid[] default null)
returns table (item_id uuid, kind text, title text, state text, record_id bigint, expires_on date, note text, sort_order int,
               before_work boolean, category text, needs_check boolean)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_role public.app_role;
  v_title uuid;
  v_teams uuid[];
  v_warn int := coalesce((select (value #>> '{}')::int from public.app_settings where key = 'compliance.expiry_warning_days'), 30);
  v_today date := public.local_today();
begin
  select coalesce(p_role, p.role), p.job_title_id into v_role, v_title from public.profiles p where p.id = p_user;
  v_teams := coalesce(p_teams, (select array_agg(team_id) from public.team_members where user_id = p_user), '{}');

  return query
  select i.id, i.kind, i.title,
         case
           when r.id is null then 'todo'
           -- Policies, agreements and forms: done for the current version.
           when i.kind in ('read', 'agreement', 'form') then case when r.version >= i.version then 'done' else 'update' end
           when r.status in ('rejected', 'replace_requested') then r.status
           when r.expires_on is not null and r.expires_on < v_today then 'expired'
           when r.expires_on is not null and r.expires_on <= v_today + v_warn then 'expiring'
           when i.kind = 'training' and r.status = 'done' and r.version < i.version then 'update'
           else r.status
         end,
         r.id, r.expires_on, coalesce(r.review_note, ''), i.sort_order,
         i.before_work, i.category,
         -- Has a file someone must check (uploads, and trainings with a certificate).
         (i.kind = 'upload' or (i.kind = 'training' and r.file_path is not null) or (i.kind = 'training' and (i.certificate = 'required' or i.before_work)))
    from public.compliance_items i
    left join lateral (
      select * from public.compliance_records cr
       where cr.item_id = i.id and cr.user_id = p_user
       order by cr.created_at desc, cr.id desc limit 1
    ) r on true
   where public.compliance_applies(i, v_role, v_teams, v_title)
   order by array_position(array['read', 'training', 'upload', 'agreement', 'form'], i.kind), i.sort_order, i.title;
end;
$$;
drop function if exists public.compliance_status(uuid, public.app_role, uuid[]);
create function public.compliance_status(p_user uuid, p_role public.app_role default null, p_teams uuid[] default null)
returns table (item_id uuid, kind text, title text, state text, record_id bigint, expires_on date, note text, sort_order int,
               before_work boolean, category text, needs_check boolean)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not (p_user = auth.uid() or public.can_manage_compliance() or public.can_manage_people()
          or public.has_role(array['manager']::public.app_role[]) or public.leads_user(p_user)
          or auth.uid() is null) then
    return;
  end if;
  return query select * from public.compliance_status_all(p_user, p_role, p_teams);
end;
$$;
revoke execute on function public.compliance_status_all(uuid, public.app_role, uuid[]) from public, anon, authenticated;
revoke execute on function public.compliance_status(uuid, public.app_role, uuid[]) from public, anon;
grant execute on function public.compliance_status(uuid, public.app_role, uuid[]) to authenticated;

-- Still to do before onboarding is complete (submitted counts: it's been sent).
create or replace function public.onboarding_missing(p_user uuid, p_role public.app_role default null, p_teams uuid[] default null)
returns text[]
language sql
stable
security definer
set search_path = ''
as $$
  select (case when public.profile_required(p_user) then array['Complete your profile'] else '{}'::text[] end)
      || coalesce((select array_agg(s.title order by array_position(array['read', 'training', 'upload', 'agreement', 'form'], s.kind), s.sort_order, s.title)
                     from public.compliance_status(p_user, p_role, p_teams) s
                    where s.state not in ('done', 'submitted', 'accepted', 'expiring')), '{}')
$$;

-- Needed before working and not yet done AND checked (titles).
create or replace function public.before_work_missing(p_user uuid)
returns text[]
language sql
stable
security definer
set search_path = ''
as $$
  select (case when public.profile_required(p_user) then array['Complete your profile'] else '{}'::text[] end)
      || coalesce((select array_agg(s.title order by s.sort_order, s.title)
                     from public.compliance_status_all(p_user) s
                    where s.before_work
                      and not (s.state in ('accepted', 'expiring') or (s.state = 'done' and not s.needs_check))), '{}')
$$;

-- Everything sent has been checked: no file waiting, rejected, expired or missing.
create or replace function public.compliance_is_verified(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select not public.profile_required(p_user)
     and not exists (select 1 from public.compliance_status_all(p_user) s where s.state not in ('done', 'submitted', 'accepted', 'expiring'))
     and not exists (select 1 from public.compliance_status_all(p_user) s where s.needs_check and s.state not in ('accepted', 'expiring'))
$$;

-- An override in force today.
create or replace function public.active_override(p_user uuid)
returns public.work_overrides
language sql
stable
security definer
set search_path = ''
as $$
  select o.* from public.work_overrides o
   where o.user_id = p_user and o.ended_at is null and o.until_date >= public.local_today()
   order by o.until_date desc limit 1
$$;

-- Can this person be given cleared-only duties? Cleared, and nothing needed
-- before working has since expired; or an override is in force.
create or replace function public.can_work(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (public.active_override(p_user)).id is not null
      or coalesce((select p.cleared_at is not null from public.profiles p where p.id = p_user), false)
         and cardinality(public.before_work_missing(p_user)) = 0
$$;

-- The three statuses, for the screens.
create or replace function public.work_status(p_user uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  p public.profiles;
  o public.work_overrides;
begin
  if not (p_user = auth.uid() or public.can_manage_compliance() or public.can_manage_people()
          or public.has_role(array['manager']::public.app_role[]) or public.leads_user(p_user)) then
    return null;
  end if;
  select * into p from public.profiles where id = p_user;
  o := public.active_override(p_user);
  return jsonb_build_object(
    'onboarding_complete', p.onboarded_at is not null and cardinality(public.onboarding_missing(p_user)) = 0,
    'onboarded_at', p.onboarded_at,
    'compliance_verified', public.compliance_is_verified(p_user),
    'cleared', p.cleared_at is not null,
    'cleared_at', p.cleared_at,
    'cleared_by', (select coalesce(nullif(full_name, ''), email) from public.profiles where id = p.cleared_by),
    'before_work_missing', to_jsonb(public.before_work_missing(p_user)),
    'can_work', public.can_work(p_user),
    'override', case when o.id is null then null else jsonb_build_object('id', o.id, 'reason', o.reason, 'until', o.until_date,
                  'by', (select coalesce(nullif(full_name, ''), email) from public.profiles where id = o.granted_by)) end);
end;
$$;

-- Keep "compliance verified" on the person up to date when records change.
create or replace function public.refresh_compliance_verified(p_user uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.compliance_is_verified(p_user) then
    update public.profiles set compliance_verified_at = coalesce(compliance_verified_at, now()) where id = p_user and compliance_verified_at is null;
  else
    update public.profiles set compliance_verified_at = null where id = p_user and compliance_verified_at is not null;
  end if;
end;
$$;

create or replace function public.compliance_record_changed()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.refresh_compliance_verified(new.user_id);
  return new;
end;
$$;
drop trigger if exists compliance_record_changed on public.compliance_records;
create trigger compliance_record_changed after insert or update on public.compliance_records
  for each row execute function public.compliance_record_changed();

-- Opening a policy or agreement (before acknowledging it).
create or replace function public.open_compliance_item(p_item_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  i public.compliance_items;
begin
  if not public.is_member() then
    raise exception 'Please sign in again';
  end if;
  select * into i from public.compliance_items where id = p_item_id and active;
  if i.id is null then
    raise exception 'That item isn''t available';
  end if;
  insert into public.compliance_opens (item_id, user_id, version) values (i.id, auth.uid(), i.version) on conflict do nothing;
end;
$$;

-- Acknowledge a policy: opened first, then a tick and their full name.
create or replace function public.acknowledge_policy(p_item_id uuid, p_name text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  i public.compliance_items;
  v_me text;
begin
  if not public.is_member() then
    raise exception 'Please sign in again';
  end if;
  select * into i from public.compliance_items where id = p_item_id and active and kind = 'read';
  if i.id is null then
    raise exception 'Choose a policy to acknowledge';
  end if;
  if not exists (select 1 from public.compliance_opens where item_id = i.id and user_id = auth.uid() and version = i.version) then
    raise exception 'Open and read the policy first';
  end if;
  select full_name into v_me from public.profiles where id = auth.uid();
  if lower(regexp_replace(trim(coalesce(p_name, '')), '\s+', ' ', 'g')) <> lower(regexp_replace(trim(coalesce(v_me, '')), '\s+', ' ', 'g')) then
    raise exception 'Type your full name exactly as it is on your account (%)', v_me;
  end if;
  insert into public.compliance_records (item_id, user_id, version, status, signed_name, content_hash)
  values (i.id, auth.uid(), i.version, 'done', trim(p_name),
          encode(sha256(convert_to(i.title || E'\n' || i.body || E'\n' || coalesce(i.file_path, '') || E'\n' || i.link_url, 'UTF8')), 'hex'));
  perform public.check_onboarding_complete(auth.uid());
end;
$$;

-- Complete a training: the date, provider, and a certificate (checked like a document).
create or replace function public.complete_training(p_item_id uuid, p_completed_on date, p_provider text default '',
                                                    p_path text default null, p_name text default null, p_expires date default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  i public.compliance_items;
  me public.profiles;
  v_admin uuid;
begin
  if not public.is_member() then
    raise exception 'Please sign in again';
  end if;
  select * into i from public.compliance_items where id = p_item_id and active and kind = 'training';
  if i.id is null then
    raise exception 'Choose a training';
  end if;
  if p_completed_on is null or p_completed_on > public.local_today() then
    raise exception 'Enter the date you completed it (not in the future)';
  end if;
  -- Mandatory trainings (needed before working) always need a certificate.
  if (i.certificate = 'required' or i.before_work) and p_path is null then
    raise exception 'Upload your certificate to complete this training';
  end if;
  if p_path is not null and p_path not like auth.uid()::text || '/%' then
    raise exception 'Upload the certificate again';
  end if;
  if i.needs_expiry and p_path is not null and p_expires is null then
    raise exception 'Enter the certificate''s expiry date';
  end if;
  if p_expires is not null and p_expires < public.local_today() then
    raise exception 'This certificate has already expired';
  end if;
  insert into public.compliance_records (item_id, user_id, version, status, completed_on, provider, file_path, file_name, expires_on)
  values (i.id, auth.uid(), i.version, case when p_path is null then 'done' else 'submitted' end, p_completed_on,
          left(trim(coalesce(p_provider, '')), 120), p_path, left(coalesce(p_name, ''), 200), p_expires);
  if p_path is not null then
    select * into me from public.profiles where id = auth.uid();
    for v_admin in select a from public.people_admins() a loop
      continue when v_admin = auth.uid();
      perform public.notify(v_admin, 'upload_submitted',
        format('%s sent a certificate for %s', coalesce(nullif(me.full_name, ''), me.email), i.title),
        'Check it in People → Onboarding.', '/compliance/people/' || auth.uid());
    end loop;
  end if;
  perform public.check_onboarding_complete(auth.uid());
end;
$$;

-- Upload a document with its details. Never verified on upload.
create or replace function public.submit_document(p_item_id uuid, p_path text, p_name text, p_expires date default null,
                                                  p_issued date default null, p_number text default '')
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  i public.compliance_items;
  v_id bigint;
begin
  select * into i from public.compliance_items where id = p_item_id and active and kind = 'upload';
  if i.id is null then
    raise exception 'Uploads for this document are switched off';
  end if;
  if i.needs_issue_date and p_issued is null then
    raise exception 'Enter the issue date';
  end if;
  if p_issued is not null and p_issued > public.local_today() then
    raise exception 'The issue date can''t be in the future';
  end if;
  if i.needs_number and coalesce(trim(p_number), '') = '' then
    raise exception 'Enter the document or card number';
  end if;
  perform public.submit_compliance_upload(p_item_id, p_path, p_name, p_expires);
  select id into v_id from public.compliance_records where item_id = i.id and user_id = auth.uid() order by id desc limit 1;
  update public.compliance_records set issued_on = p_issued, doc_number = left(trim(coalesce(p_number, '')), 60) where id = v_id;
end;
$$;

-- Sign an employment agreement: drawn signature (an image they uploaded to
-- their own folder) and their full name typed. Records the exact version.
create or replace function public.sign_agreement(p_item_id uuid, p_name text, p_signature_path text, p_device text default '')
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  i public.compliance_items;
  v_me text;
  v_ip text := coalesce(nullif(split_part(coalesce((nullif(current_setting('request.headers', true), '')::json ->> 'x-forwarded-for'), ''), ',', 1), ''), '');
begin
  if not public.is_member() then
    raise exception 'Please sign in again';
  end if;
  select * into i from public.compliance_items where id = p_item_id and active and kind = 'agreement';
  if i.id is null then
    raise exception 'Choose an agreement to sign';
  end if;
  if not exists (select 1 from public.compliance_opens where item_id = i.id and user_id = auth.uid() and version = i.version) then
    raise exception 'Open and read the agreement first';
  end if;
  select full_name into v_me from public.profiles where id = auth.uid();
  if lower(regexp_replace(trim(coalesce(p_name, '')), '\s+', ' ', 'g')) <> lower(regexp_replace(trim(coalesce(v_me, '')), '\s+', ' ', 'g')) then
    raise exception 'Type your full name exactly as it is on your account (%)', v_me;
  end if;
  if p_signature_path is null or p_signature_path !~ ('^' || auth.uid()::text || '/signature-[A-Za-z0-9._-]+\.png$') then
    raise exception 'Draw your signature, then sign again';
  end if;
  insert into public.compliance_records (item_id, user_id, version, status, signed_name, signature_path, content_hash, signed_from)
  values (i.id, auth.uid(), i.version, 'done', trim(p_name), p_signature_path,
          encode(sha256(convert_to(i.title || E'\n' || i.body || E'\n' || coalesce(i.file_path, '') || E'\n' || i.link_url, 'UTF8')), 'hex'),
          left(trim(concat_ws(' · ', nullif(v_ip, ''), nullif(trim(coalesce(p_device, '')), ''))), 300));
  perform public.write_audit('agreement_signed', 'compliance_item', i.id::text, jsonb_build_object('item', i.title, 'version', i.version));
  perform public.check_onboarding_complete(auth.uid());
end;
$$;

-- Checking documents: accept, reject (with a reason) or ask for a replacement.
create or replace function public.review_compliance_upload(p_record_id bigint, p_accept boolean, p_note text default '')
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.compliance_records;
  v_title text;
begin
  if not public.can_manage_compliance() then
    raise exception 'Only people who manage Compliance can check uploads';
  end if;
  select * into r from public.compliance_records where id = p_record_id for update;
  if r.id is null or r.file_path is null or r.status not in ('submitted', 'accepted', 'rejected', 'replace_requested') then
    raise exception 'Upload not found';
  end if;
  if r.user_id = auth.uid() then
    raise exception 'Someone else needs to check your own documents';
  end if;
  if not p_accept and coalesce(trim(p_note), '') = '' then
    raise exception 'Say what''s wrong, so they know what to upload';
  end if;
  update public.compliance_records
     set status = case when p_accept then 'accepted' else 'rejected' end,
         review_note = coalesce(trim(p_note), ''), reviewed_by = auth.uid(), reviewed_at = now()
   where id = r.id;
  select title into v_title from public.compliance_items where id = r.item_id;
  if not p_accept then
    perform public.notify(r.user_id, 'upload_rejected', format('Please upload %s again', v_title),
      trim(p_note), '/onboarding', true);
  end if;
  perform public.write_audit(case when p_accept then 'upload_accepted' else 'upload_rejected' end,
    'compliance_record', r.id::text, jsonb_build_object('item', v_title, 'note', p_note));
end;
$$;

create or replace function public.request_replacement(p_record_id bigint, p_note text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.compliance_records;
  v_title text;
begin
  if not public.can_manage_compliance() then
    raise exception 'Only people who manage Compliance can ask for a replacement';
  end if;
  if coalesce(trim(p_note), '') = '' then
    raise exception 'Say why a new one is needed';
  end if;
  select * into r from public.compliance_records where id = p_record_id for update;
  if r.id is null or r.file_path is null then
    raise exception 'Document not found';
  end if;
  update public.compliance_records
     set status = 'replace_requested', review_note = trim(p_note), reviewed_by = auth.uid(), reviewed_at = now()
   where id = r.id;
  select title into v_title from public.compliance_items where id = r.item_id;
  perform public.notify(r.user_id, 'upload_rejected', format('Please upload a new %s', v_title), trim(p_note), '/onboarding', true);
  perform public.write_audit('upload_replacement_requested', 'compliance_record', r.id::text, jsonb_build_object('item', v_title, 'note', p_note));
end;
$$;

-- The "Finish onboarding" task for what's left after clearance, due within a
-- week. New starters can't be given tasks, so theirs is made when they get a role.
create or replace function public.finish_onboarding_task(p_user uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_rest text[] := public.onboarding_missing(p_user);
begin
  if cardinality(v_rest) = 0 or not public.can_take_tasks(p_user)
     or (select cleared_at is null from public.profiles where id = p_user)
     or exists (select 1 from public.tasks t where t.assigned_to = p_user and t.title = 'Finish onboarding' and t.status not in ('completed', 'closed')) then
    return;
  end if;
  perform public.create_task(
    'Finish onboarding',
    (select id from public.registries where is_default and kind = 'tasks' and active order by sort_order limit 1),
    p_user,
    format(E'You''re cleared to work. Please finish the rest of your onboarding by %s.\n\nStill to do:\n%s\n\nOpen My onboarding to finish them.',
           to_char(public.local_today() + 7, 'FMDD Mon YYYY'),
           (select string_agg('• ' || x, E'\n') from unnest(v_rest) x)),
    'medium', public.local_today() + 7);
end;
$$;

create or replace function public.role_given_finish_onboarding()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.role = 'new_starter' and new.role <> 'new_starter' and new.cleared_at is not null then
    perform public.finish_onboarding_task(new.id);
  end if;
  return new;
end;
$$;
drop trigger if exists role_given_finish_onboarding on public.profiles;
create trigger role_given_finish_onboarding after update of role on public.profiles
  for each row execute function public.role_given_finish_onboarding();
revoke execute on function public.finish_onboarding_task(uuid) from public, anon, authenticated;

-- Clear someone to work. Everything needed before working must be done and
-- checked. Anything else left goes into a "Finish onboarding" task due within
-- a week (on the default General tasks register).
create or replace function public.grant_clearance(p_user uuid, p_note text default '')
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  p public.profiles;
  v_missing text[];
  v_rest text[];
begin
  if not public.can_grant_clearance() then
    raise exception 'Only managers (or staff admins they''ve delegated to) can clear people to work';
  end if;
  select * into p from public.profiles where id = p_user;
  if p.id is null or not p.active then
    raise exception 'Person not found';
  end if;
  if p_user = auth.uid() then
    raise exception 'Someone else needs to clear you to work';
  end if;
  v_missing := public.before_work_missing(p_user);
  if cardinality(v_missing) > 0 then
    raise exception 'Still needed before working: %. Finish and check these first, or give an override.', array_to_string(v_missing, ', ');
  end if;
  update public.profiles set cleared_at = now(), cleared_by = auth.uid() where id = p_user;
  v_rest := public.onboarding_missing(p_user);
  perform public.finish_onboarding_task(p_user);
  perform public.notify(p_user, 'cleared_to_work', 'You''re cleared to work',
    case when cardinality(v_rest) > 0 then 'Please finish the rest of your onboarding within a week.' else '' end, '/onboarding', true);
  perform public.write_audit('cleared_to_work', 'profile', p_user::text, jsonb_build_object('note', p_note, 'still_to_do', v_rest));
end;
$$;

create or replace function public.revoke_clearance(p_user uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.can_grant_clearance() then
    raise exception 'Only managers (or staff admins they''ve delegated to) can change clearance';
  end if;
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'Give a reason';
  end if;
  update public.profiles set cleared_at = null, cleared_by = null where id = p_user and cleared_at is not null;
  perform public.write_audit('clearance_removed', 'profile', p_user::text, jsonb_build_object('reason', trim(p_reason)));
end;
$$;

-- Let someone work before they're cleared, when really needed: a reason and
-- an end date (up to 30 days).
create or replace function public.grant_work_override(p_user uuid, p_reason text, p_until date)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id bigint;
begin
  if not public.can_grant_clearance() then
    raise exception 'Only managers (or staff admins they''ve delegated to) can give an override';
  end if;
  if p_user = auth.uid() then
    raise exception 'Someone else needs to give you an override';
  end if;
  if coalesce(length(trim(p_reason)), 0) < 3 then
    raise exception 'Give a reason for the override';
  end if;
  if p_until is null or p_until < public.local_today() or p_until > public.local_today() + 30 then
    raise exception 'Choose an end date within the next 30 days';
  end if;
  update public.work_overrides set ended_at = now(), ended_by = auth.uid() where user_id = p_user and ended_at is null;
  insert into public.work_overrides (user_id, reason, until_date, granted_by) values (p_user, trim(p_reason), p_until, auth.uid())
  returning id into v_id;
  perform public.notify(p_user, 'cleared_to_work', 'You can start work for now',
    format('Until %s. Please finish your onboarding.', to_char(p_until, 'FMDD Mon YYYY')), '/onboarding', true);
  perform public.write_audit('work_override_given', 'profile', p_user::text, jsonb_build_object('reason', trim(p_reason), 'until', p_until));
  return v_id;
end;
$$;

create or replace function public.end_work_override(p_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  o public.work_overrides;
begin
  if not public.can_grant_clearance() then
    raise exception 'Only managers (or staff admins they''ve delegated to) can end an override';
  end if;
  update public.work_overrides set ended_at = now(), ended_by = auth.uid() where id = p_id and ended_at is null returning * into o;
  if o.id is not null then
    perform public.write_audit('work_override_ended', 'profile', o.user_id::text, jsonb_build_object('reason', o.reason));
  end if;
end;
$$;

-- Duty restrictions ----------------------------------------------------------
create or replace function public.guard_cleared_tasks()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.assigned_to is not null
     and (tg_op = 'INSERT' or new.assigned_to is distinct from old.assigned_to)
     and exists (select 1 from public.registries r where r.id = new.registry_id and r.cleared_only)
     and not public.can_work(new.assigned_to) then
    raise exception 'This register is for cleared staff only, and % isn''t cleared to work yet',
      (select coalesce(nullif(full_name, ''), email) from public.profiles where id = new.assigned_to);
  end if;
  return new;
end;
$$;
drop trigger if exists guard_cleared_tasks on public.tasks;
create trigger guard_cleared_tasks before insert or update of assigned_to, registry_id on public.tasks
  for each row execute function public.guard_cleared_tasks();

create or replace function public.guard_cleared_trips()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if coalesce((select (value #>> '{}')::boolean from public.app_settings where key = 'cars.cleared_only'), false)
     and not public.can_work(new.driver_id) then
    raise exception 'Only staff cleared to work can use the cars';
  end if;
  return new;
end;
$$;
drop trigger if exists guard_cleared_trips on public.car_trips;
create trigger guard_cleared_trips before insert on public.car_trips
  for each row execute function public.guard_cleared_trips();

-- Grants -----------------------------------------------------------------------
revoke execute on function public.can_grant_clearance(), public.before_work_missing(uuid), public.compliance_is_verified(uuid),
  public.active_override(uuid), public.can_work(uuid), public.work_status(uuid), public.refresh_compliance_verified(uuid),
  public.open_compliance_item(uuid), public.acknowledge_policy(uuid, text),
  public.complete_training(uuid, date, text, text, text, date), public.submit_document(uuid, text, text, date, date, text),
  public.sign_agreement(uuid, text, text, text), public.request_replacement(bigint, text),
  public.grant_clearance(uuid, text), public.revoke_clearance(uuid, text), public.grant_work_override(uuid, text, date),
  public.end_work_override(bigint) from public, anon;
revoke execute on function public.refresh_compliance_verified(uuid), public.before_work_missing(uuid), public.compliance_is_verified(uuid),
  public.can_work(uuid), public.active_override(uuid) from authenticated;
grant execute on function public.can_grant_clearance(), public.work_status(uuid),
  public.open_compliance_item(uuid), public.acknowledge_policy(uuid, text),
  public.complete_training(uuid, date, text, text, text, date), public.submit_document(uuid, text, text, date, date, text),
  public.sign_agreement(uuid, text, text, text), public.request_replacement(bigint, text),
  public.grant_clearance(uuid, text), public.revoke_clearance(uuid, text), public.grant_work_override(uuid, text, date),
  public.end_work_override(bigint) to authenticated;

-- People already working before this update count as cleared, so nobody is
-- suddenly blocked. New starters from now on need clearing.
-- (Once only, so running this again never re-clears someone.)
do $$
begin
  if not exists (select 1 from public.app_settings where key = 'compliance.clearance_started') then
    update public.profiles set cleared_at = now()
     where active and role not in ('new_starter', 'external') and cleared_at is null;
    insert into public.app_settings (key, value, label, description, is_public)
    values ('compliance.clearance_started', to_jsonb(now()::text), 'Clearance to work started',
            'When clearance to work began on this copy. Staff working before then were counted as cleared.', false);
  end if;
end;
$$;

-- Defaults (once per copy). Paused guard as in update 53, so this also runs
-- when Compliance is switched off.
alter table public.compliance_items disable trigger compliance_items_guard;
-- Mandatory training: the NDIS Commission's free Worker Orientation Module.
insert into public.compliance_items (kind, title, description, link_url, before_work, certificate, active, sort_order, created_by)
select 'training', 'NDIS Worker Orientation Module: Quality, Safety and You',
       'The free online module from the NDIS Quality and Safeguards Commission (about 90 minutes). Complete it, then upload your certificate.',
       'https://training.ndiscommission.gov.au/', true, 'required', true, 10, null
where not exists (select 1 from public.compliance_items where title like 'NDIS Worker Orientation Module%');
-- Common documents, switched off until the company chooses them.
insert into public.compliance_items (kind, title, description, category, needs_expiry, needs_number, needs_issue_date, before_work, active, sort_order, created_by)
select v.kind, v.title, v.description, v.category, v.needs_expiry, v.needs_number, v.needs_issue_date, v.before_work, false, v.sort_order, null
  from (values
    ('upload', 'NDIS Worker Screening Check', 'Your NDIS Worker Screening clearance letter or card.', 'screening', true, true, false, true, 20),
    ('upload', 'Working with Children Check', 'Your Working with Children Check card or letter.', 'screening', true, true, false, true, 21),
    ('upload', 'National Police Check', 'A National Police Certificate issued in the last 3 years.', 'screening', false, false, true, true, 22),
    ('upload', 'First Aid and CPR certificate', 'HLTAID011 Provide First Aid (CPR is renewed every year).', 'certificate', true, false, true, false, 23),
    ('upload', 'Driver''s licence', 'Front and back of your current licence.', 'licence', true, true, false, false, 24),
    ('upload', 'Comprehensive car insurance', 'If you use your own car for work.', 'insurance', true, false, false, false, 25),
    ('upload', 'Qualification (Certificate III or IV)', 'For example Certificate III in Individual Support.', 'qualification', false, false, true, false, 26)
  ) as v(kind, title, description, category, needs_expiry, needs_number, needs_issue_date, before_work, sort_order)
 where not exists (select 1 from public.compliance_items c where c.title = v.title);
-- A sample employment agreement, switched off until the company adds its own.
insert into public.compliance_items (kind, title, description, body, before_work, active, sort_order, created_by)
select 'agreement', 'Employment agreement',
       'Read your employment agreement, then sign it on screen.',
       E'SAMPLE ONLY: replace this with your company''s employment agreement before switching it on.\n\nThis agreement is between the company and the employee named below. It covers the position, hours, pay, duties, confidentiality, and the company''s policies and procedures.',
       true, false, 30, null
where not exists (select 1 from public.compliance_items where kind = 'agreement');
alter table public.compliance_items enable trigger compliance_items_guard;

commit;
