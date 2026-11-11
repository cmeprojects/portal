-- Staff Portal · © cmeproject. All rights reserved.
-- Update 64 (Phase 4): policies for specific people and kept versions of
-- their wording; employment contracts with signatures, the signed PDF and
-- statuses. Safe to run again. Undo: undo-64.sql. Run update 63 first.
begin;
-- cmeprojects Phase 4: agreements, policies and employment contracts.
--   1. Policies and agreements can go to specific people (as well as roles,
--      teams and positions), and every earlier version's wording is kept.
--   2. Employment contracts: one per person per version, with statuses
--      Draft → Awaiting employee signature → Awaiting employer signature →
--      Fully signed, or Cancelled / Expired / Superseded. A revised contract is
--      a new contract (new version) with a new signing process; the old one is
--      never changed and is marked Superseded once the new one is signed.
--   3. Signatures: the signer, typed name, drawn signature, consent wording,
--      how their identity was re-checked, IP, device, time (server), and the
--      SHA-256 of the exact wording signed. Never changed or deleted.
--   4. The final signed PDF (with an audit page) and its SHA-256 are stored
--      in a private 'contracts' store; signed contracts can't be changed.
--   Who prepares, sends and countersigns: people with Staff details access
--   covering the employee (or the system admin), never the employee.
-- No new SECURITY DEFINER function. compliance_status_all, the item
-- announcement trigger and run_compliance_alerts (existing) are updated.

-- ---------------------------------------------------------------------------
-- 1. Specific people, and version history
-- ---------------------------------------------------------------------------
alter table public.compliance_items add column if not exists applies_people uuid[] not null default '{}';

create or replace function public.compliance_status_all(p_user uuid, p_role app_role DEFAULT NULL::app_role, p_teams uuid[] DEFAULT NULL::uuid[])
 RETURNS TABLE(item_id uuid, kind text, title text, state text, record_id bigint, expires_on date, note text, sort_order integer, before_work boolean, category text, needs_check boolean)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
     -- cmeprojects Phase 4: or only the chosen people.
     and (cardinality(i.applies_people) = 0 or p_user = any (i.applies_people))
   order by array_position(array['read', 'training', 'upload', 'agreement', 'form'], i.kind), i.sort_order, i.title;
end;
$function$;

create or replace function public.compliance_item_announce()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  p record;
  v_word text := case new.kind when 'read' then 'Please read and confirm' when 'training' then 'New training' when 'form' then 'Please fill in' else 'Please upload' end;
begin
  if not new.active then
    return new;
  end if;
  if tg_op = 'UPDATE' and new.version = old.version and old.active then
    return new;
  end if;
  for p in
    select pr.id, pr.role, (select array_agg(team_id) from public.team_members where user_id = pr.id) teams
      from public.profiles pr
     where pr.active and pr.role <> 'system_admin'
  loop
    if public.compliance_applies(new, p.role, p.teams)
       and (cardinality(new.applies_people) = 0 or p.id = any (new.applies_people)) then
      perform public.notify(p.id, 'onboarding_item',
        case when tg_op = 'UPDATE' and new.version > old.version then format('Updated: %s', new.title) else format('%s: %s', v_word, new.title) end,
        case when new.kind = 'form' then 'A form to fill in. It''s also on your My onboarding page.' else 'It''s on your My onboarding page.' end,
        case when new.kind = 'form' and new.form_id is not null then '/forms/' || new.form_id else '/onboarding' end);
    end if;
  end loop;
  return new;
end;
$function$;


create table if not exists public.compliance_item_versions (
  id           bigint generated always as identity primary key,
  item_id      uuid not null references public.compliance_items (id) on delete cascade,
  version      int not null,
  title        text not null,
  body         text not null default '',
  link_url     text,
  content_hash text not null,
  saved_at     timestamptz not null default now(),
  saved_by     uuid references public.profiles (id) on delete set null,
  unique (item_id, version)
);
alter table public.compliance_item_versions enable row level security;
revoke all on public.compliance_item_versions from anon;
revoke update, delete, truncate on public.compliance_item_versions from authenticated;
grant select, insert on public.compliance_item_versions to authenticated;
drop policy if exists "members read earlier versions" on public.compliance_item_versions;
create policy "members read earlier versions" on public.compliance_item_versions for select to authenticated
  using ((select public.is_member()));
drop policy if exists "compliance managers keep versions" on public.compliance_item_versions;
create policy "compliance managers keep versions" on public.compliance_item_versions for insert to authenticated
  with check ((select public.can_manage_compliance()) or (select public.is_system_admin()));

-- Each version's wording is kept as it was when that version went out.
create or replace function public.keep_item_version()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.kind in ('read', 'agreement') and (tg_op = 'INSERT' or new.version is distinct from old.version or new.body is distinct from old.body) then
    insert into public.compliance_item_versions (item_id, version, title, body, link_url, content_hash, saved_by)
    values (new.id, new.version, new.title, coalesce(new.body, ''), new.link_url,
            encode(sha256(convert_to(new.title || E'\n' || coalesce(new.body, ''), 'UTF8')), 'hex'), auth.uid())
    on conflict (item_id, version) do nothing;
  end if;
  return null;
end;
$$;
revoke execute on function public.keep_item_version() from public, anon, authenticated;
drop trigger if exists keep_item_version on public.compliance_items;
create trigger keep_item_version after insert or update on public.compliance_items
  for each row execute function public.keep_item_version();
-- The current wording of existing policies and agreements, once.
insert into public.compliance_item_versions (item_id, version, title, body, link_url, content_hash)
select i.id, i.version, i.title, coalesce(i.body, ''), i.link_url, encode(sha256(convert_to(i.title || E'\n' || coalesce(i.body, ''), 'UTF8')), 'hex')
  from public.compliance_items i
 where i.kind in ('read', 'agreement')
on conflict (item_id, version) do nothing;

-- ---------------------------------------------------------------------------
-- 2. Employment contracts
-- ---------------------------------------------------------------------------
create table if not exists public.contracts (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references public.profiles (id) on delete cascade,
  title           text not null check (length(title) between 2 and 200),
  body            text not null default '' check (length(body) <= 100000),
  version         int not null default 1 check (version >= 1),
  supersedes      uuid references public.contracts (id),
  status          text not null default 'draft'
                  check (status in ('draft', 'awaiting_employee', 'awaiting_employer', 'fully_signed', 'cancelled', 'expired', 'superseded')),
  sign_by         date,
  content_hash    text not null default '',
  sent_at         timestamptz,
  sent_by         uuid references public.profiles (id) on delete set null,
  signed_pdf_path text not null default '',
  signed_pdf_hash text not null default '',
  completed_at    timestamptz,
  created_by      uuid default auth.uid() references public.profiles (id) on delete set null,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index if not exists contracts_user on public.contracts (user_id, created_at desc);

create table if not exists public.contract_signatures (
  id             bigint generated always as identity primary key,
  contract_id    uuid not null references public.contracts (id) on delete cascade,
  party          text not null check (party in ('employee', 'employer')),
  signer_id      uuid not null default auth.uid() references public.profiles (id),
  signed_name    text not null check (length(trim(signed_name)) between 2 and 120),
  signature_path text not null check (length(signature_path) between 1 and 300),
  consent_text   text not null check (length(consent_text) between 10 and 1000),
  content_hash   text not null,
  identity_check text not null check (identity_check in ('password', 'authenticator')),
  ip             text not null default '' check (length(ip) <= 64),
  user_agent     text not null default '' check (length(user_agent) <= 300),
  signed_at      timestamptz not null default now(),
  unique (contract_id, party)
);

alter table public.contracts enable row level security;
alter table public.contract_signatures enable row level security;
revoke all on public.contracts, public.contract_signatures from anon;
revoke truncate on public.contracts from authenticated;
revoke update, delete, truncate on public.contract_signatures from authenticated;
grant select, insert, update, delete on public.contracts to authenticated;
grant select, insert on public.contract_signatures to authenticated;

-- The employee sees their own (not drafts); people with Staff details access covering them see all.
drop policy if exists "contracts: the employee and people with access" on public.contracts;
create policy "contracts: the employee and people with access" on public.contracts for select to authenticated
  using ((select public.is_member()) and ((user_id = (select auth.uid()) and status <> 'draft') or public.has_access('staff_details', user_id)));
drop policy if exists "contracts: people with access prepare them" on public.contracts;
create policy "contracts: people with access prepare them" on public.contracts for insert to authenticated
  with check ((select public.is_member()) and status = 'draft' and user_id <> (select auth.uid()) and public.has_access('staff_details', user_id));
drop policy if exists "contracts: people with access, or the employee signing" on public.contracts;
create policy "contracts: people with access, or the employee signing" on public.contracts for update to authenticated
  using ((select public.is_member()) and ((user_id <> (select auth.uid()) and public.has_access('staff_details', user_id)) or (user_id = (select auth.uid()) and status = 'awaiting_employee')))
  with check ((select public.is_member()) and ((user_id <> (select auth.uid()) and public.has_access('staff_details', user_id)) or user_id = (select auth.uid())));
drop policy if exists "contracts: drafts can be deleted" on public.contracts;
create policy "contracts: drafts can be deleted" on public.contracts for delete to authenticated
  using (status = 'draft' and user_id <> (select auth.uid()) and public.has_access('staff_details', user_id));

drop policy if exists "signatures follow their contract" on public.contract_signatures;
create policy "signatures follow their contract" on public.contract_signatures for select to authenticated
  using (exists (select 1 from public.contracts c where c.id = contract_id));
drop policy if exists "sign as yourself, at the right step" on public.contract_signatures;
create policy "sign as yourself, at the right step" on public.contract_signatures for insert to authenticated
  with check (
    signer_id = (select auth.uid()) and (select public.is_member())
    and exists (
      select 1 from public.contracts c
       where c.id = contract_id and c.content_hash = contract_signatures.content_hash
         and ((party = 'employee' and c.user_id = (select auth.uid()) and c.status = 'awaiting_employee'
               and (c.sign_by is null or c.sign_by >= public.local_today()))
              or (party = 'employer' and c.user_id <> (select auth.uid()) and c.status = 'awaiting_employer'
                  and public.has_access('staff_details', c.user_id)))));

-- What can change, and when. Runs as the person making the change.
create or replace function public.guard_contract()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_by uuid := auth.uid();
  v_holder boolean;
begin
  if tg_op = 'INSERT' then
    new.status := 'draft';
    new.created_by := v_by;
    new.content_hash := '';
    new.signed_pdf_path := '';
    new.signed_pdf_hash := '';
    new.sent_at := null;
    new.sent_by := null;
    new.completed_at := null;
    if new.supersedes is not null then
      if not exists (select 1 from public.contracts o where o.id = new.supersedes and o.user_id = new.user_id) then
        raise exception 'A new version must be for the same person.';
      end if;
      new.version := (select max(version) + 1 from public.contracts where id = new.supersedes or supersedes = new.supersedes);
    else
      new.version := 1;
    end if;
    return new;
  end if;

  new.updated_at := now();
  if v_by is null then
    return new; -- the daily job (expiring unsigned contracts)
  end if;
  v_holder := new.user_id <> v_by and public.has_access('staff_details', new.user_id);

  -- Once sent, the wording and who it's for never change.
  if old.status <> 'draft' and (new.title is distinct from old.title or new.body is distinct from old.body or new.user_id is distinct from old.user_id
      or new.version is distinct from old.version or new.supersedes is distinct from old.supersedes or new.content_hash is distinct from old.content_hash
      or new.sign_by is distinct from old.sign_by) then
    raise exception 'A sent contract can''t be changed. Make a new version instead.';
  end if;
  if new.signed_pdf_path is distinct from old.signed_pdf_path or new.signed_pdf_hash is distinct from old.signed_pdf_hash then
    if not (old.status = 'awaiting_employer' and new.status = 'fully_signed' and v_holder and old.signed_pdf_path = '') then
      raise exception 'The signed copy can only be added when the contract is fully signed.';
    end if;
  end if;

  if new.status is distinct from old.status then
    if old.status = 'draft' and new.status = 'awaiting_employee' and v_holder then
      new.content_hash := encode(sha256(convert_to(new.title || E'\n' || new.body, 'UTF8')), 'hex');
      new.sent_at := now();
      new.sent_by := v_by;
    elsif old.status in ('draft', 'awaiting_employee', 'awaiting_employer') and new.status = 'cancelled' and v_holder then
      null;
    elsif old.status = 'awaiting_employee' and new.status = 'expired' and v_holder and new.sign_by < public.local_today() then
      null;
    elsif old.status = 'awaiting_employee' and new.status = 'awaiting_employer'
          and exists (select 1 from public.contract_signatures s where s.contract_id = new.id and s.party = 'employee' and s.content_hash = new.content_hash) then
      null;
    elsif old.status = 'awaiting_employer' and new.status = 'fully_signed' and v_holder
          and new.signed_pdf_path <> '' and new.signed_pdf_hash ~ '^[0-9a-f]{64}$'
          and exists (select 1 from public.contract_signatures s where s.contract_id = new.id and s.party = 'employer' and s.content_hash = new.content_hash) then
      new.completed_at := now();
    elsif old.status = 'fully_signed' and new.status = 'superseded' and v_holder
          and exists (select 1 from public.contracts n where n.supersedes = new.id and n.status = 'fully_signed') then
      null;
    else
      raise exception 'That step isn''t allowed for this contract right now.';
    end if;
  elsif old.status <> 'draft' and (to_jsonb(new) - 'updated_at') is distinct from (to_jsonb(old) - 'updated_at') then
    raise exception 'A sent contract can''t be changed. Make a new version instead.';
  end if;
  if old.status = 'draft' and not v_holder then
    raise exception 'You don''t have access to prepare contracts for this person.';
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_contract() from public, anon, authenticated;
drop trigger if exists guard_contract on public.contracts;
create trigger guard_contract before insert or update on public.contracts
  for each row execute function public.guard_contract();

-- When a new version is fully signed, the one it replaces is marked superseded.
create or replace function public.contract_supersede()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.status = 'fully_signed' and old.status <> 'fully_signed' and new.supersedes is not null then
    update public.contracts set status = 'superseded'
     where id = new.supersedes and status = 'fully_signed';
    update public.contracts set status = 'cancelled'
     where id = new.supersedes and status in ('draft', 'awaiting_employee', 'awaiting_employer');
  end if;
  return null;
end;
$$;
revoke execute on function public.contract_supersede() from public, anon, authenticated;
drop trigger if exists contract_supersede on public.contracts;
create trigger contract_supersede after update of status on public.contracts
  for each row execute function public.contract_supersede();

-- The employee signing moves it on to the employer.
create or replace function public.contract_signed()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.party = 'employee' then
    update public.contracts set status = 'awaiting_employer' where id = new.contract_id and status = 'awaiting_employee';
  end if;
  return null;
end;
$$;
revoke execute on function public.contract_signed() from public, anon, authenticated;
drop trigger if exists contract_signed on public.contract_signatures;
create trigger contract_signed after insert on public.contract_signatures
  for each row execute function public.contract_signed();

-- ---------------------------------------------------------------------------
-- 4. Private store for signatures and signed copies: <person>/<contract>/<file>
-- ---------------------------------------------------------------------------
do $$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values ('contracts', 'contracts', false, 10485760, array['application/pdf', 'image/png'])
  on conflict (id) do nothing;
  drop policy if exists "contracts: the employee and people with access read" on storage.objects;
  create policy "contracts: the employee and people with access read" on storage.objects for select to authenticated
    using (bucket_id = 'contracts' and ((storage.foldername(name))[1] = (select auth.uid())::text
           or public.has_access('staff_details', ((storage.foldername(name))[1])::uuid)));
  drop policy if exists "contracts: the employee and people with access add files" on storage.objects;
  create policy "contracts: the employee and people with access add files" on storage.objects for insert to authenticated
    with check (bucket_id = 'contracts' and (select public.is_member()) and ((storage.foldername(name))[1] = (select auth.uid())::text
           or public.has_access('staff_details', ((storage.foldername(name))[1])::uuid)));
  -- No update or delete: signed files never change.
end;
$$;

-- ---------------------------------------------------------------------------
-- The daily job also expires contracts not signed by their date.
-- ---------------------------------------------------------------------------
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
  -- cmeprojects Phase 4: contracts not signed by their "sign by" date expire.
  update public.contracts set status = 'expired'
   where status = 'awaiting_employee' and sign_by is not null and sign_by < public.local_today();
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
commit;
