-- Staff Portal · © cmeproject. All rights reserved.
-- Update 67: TFN declarations (file only, people with "can reveal TFN"),
-- sent-to-ATO date, blank form, manual deletion and how long private records
-- are kept. Safe to run again. Undo: undo-67.sql. Run update 66 first.
begin;
-- cmeprojects: tax file number declaration and record keeping (owner's
-- answers, 12 Nov 2026).
--   * No TFN number is stored. Staff upload their completed TFN declaration
--     form in onboarding; a staff admin or manager sends it to the ATO
--     themselves and records the date it was sent.
--   * Only the system admin and people with Payroll and tax access that
--     includes "can reveal TFN" (covering that person) can open it. Every
--     open, change and deletion is logged.
--   * A blank TFN declaration form can be uploaded by the system admin for
--     staff to download.
--   * Keeping records: "Keep private records for N years after someone
--     leaves" (5 by default, changeable); the system admin sees whose records
--     are past it and deletes them by hand (also any single TFN form).
-- No new SECURITY DEFINER function.

-- Who may open TFN declarations for this person.
create or replace function public.has_tfn_access(p_person uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select public.mfa_ok() and (
    public.is_system_admin()
    or (public.has_access('payroll_tax', p_person) and exists (
          select 1 from public.access_grants g
           where g.user_id = auth.uid() and g.area = 'payroll_tax' and g.can_reveal_tfn
             and g.revoked_at is null and (g.expires_at is null or g.expires_at > now())))
  )
$$;
revoke execute on function public.has_tfn_access(uuid) from public, anon;
grant execute on function public.has_tfn_access(uuid) to authenticated;

create table if not exists public.staff_tax (
  user_id      uuid primary key references public.profiles (id) on delete cascade,
  form_path    text not null default '' check (length(form_path) <= 300),
  form_name    text not null default '' check (length(form_name) <= 200),
  uploaded_at  timestamptz,
  lodged_on    date,
  lodged_by    uuid references public.profiles (id) on delete set null,
  updated_at   timestamptz not null default now(),
  updated_by   uuid references public.profiles (id) on delete set null,
  verified_at  timestamptz,
  verified_by  uuid references public.profiles (id) on delete set null
);
alter table public.staff_tax enable row level security;
revoke all on public.staff_tax from anon;
revoke truncate on public.staff_tax from authenticated;
grant select, insert, update, delete on public.staff_tax to authenticated;

drop policy if exists "tax: the person and people allowed to open TFN forms" on public.staff_tax;
create policy "tax: the person and people allowed to open TFN forms" on public.staff_tax for select to authenticated
  using ((select public.is_member()) and (user_id = (select auth.uid()) or public.has_tfn_access(user_id)));
drop policy if exists "tax: the person uploads theirs" on public.staff_tax;
create policy "tax: the person uploads theirs" on public.staff_tax for insert to authenticated
  with check ((select public.is_member()) and (user_id = (select auth.uid()) or public.has_tfn_access(user_id)));
drop policy if exists "tax: the person or people allowed" on public.staff_tax;
create policy "tax: the person or people allowed" on public.staff_tax for update to authenticated
  using ((select public.is_member()) and (user_id = (select auth.uid()) or public.has_tfn_access(user_id)))
  with check ((select public.is_member()) and (user_id = (select auth.uid()) or public.has_tfn_access(user_id)));
drop policy if exists "tax: people allowed delete" on public.staff_tax;
create policy "tax: people allowed delete" on public.staff_tax for delete to authenticated
  using (user_id <> (select auth.uid()) and public.has_tfn_access(user_id));

-- Log actions now include deleting records.
alter table public.sensitive_access_log drop constraint if exists sensitive_access_log_action_check;
alter table public.sensitive_access_log add constraint sensitive_access_log_action_check
  check (action in ('view', 'reveal', 'download', 'upload', 'change', 'verify', 'refused', 'delete', 'lodged'));

-- Checks on every change: who and when; only allowed people check it or
-- record that it was sent to the ATO (never the person themselves); a new
-- upload clears both; logged.
create or replace function public.guard_staff_tax()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_by uuid := auth.uid();
  v_checker boolean;
begin
  if v_by is null then
    return coalesce(new, old);
  end if;
  if tg_op = 'DELETE' then
    insert into public.sensitive_access_log (actor_id, subject_id, area, action, detail) values (v_by, old.user_id, 'payroll_tax', 'delete', 'TFN declaration');
    return old;
  end if;
  v_checker := v_by <> new.user_id and public.has_tfn_access(new.user_id);
  if (tg_op = 'INSERT' and (new.verified_at is not null or new.lodged_on is not null))
     or (tg_op = 'UPDATE' and (new.verified_at is distinct from old.verified_at or new.lodged_on is distinct from old.lodged_on)) then
    if not v_checker and (new.verified_at is not null or new.lodged_on is not null) then
      raise exception 'Only the person handling payroll (not the staff member) can mark this checked or sent to the ATO.';
    end if;
  end if;
  new.updated_at := now();
  new.updated_by := v_by;
  if tg_op = 'INSERT' or new.form_path is distinct from old.form_path then
    new.uploaded_at := now();
    if tg_op = 'UPDATE' then
      new.verified_at := null; new.verified_by := null; new.lodged_on := null; new.lodged_by := null;
    end if;
    insert into public.sensitive_access_log (actor_id, subject_id, area, action, detail) values (v_by, new.user_id, 'payroll_tax', 'upload', 'TFN declaration');
  end if;
  if new.verified_at is not null and (tg_op = 'INSERT' or old.verified_at is null) then
    new.verified_at := now(); new.verified_by := v_by;
    insert into public.sensitive_access_log (actor_id, subject_id, area, action, detail) values (v_by, new.user_id, 'payroll_tax', 'verify', 'TFN declaration');
  end if;
  if new.lodged_on is not null and (tg_op = 'INSERT' or old.lodged_on is distinct from new.lodged_on) then
    new.lodged_by := v_by;
    insert into public.sensitive_access_log (actor_id, subject_id, area, action, detail) values (v_by, new.user_id, 'payroll_tax', 'lodged', format('TFN declaration sent to the ATO on %s', new.lodged_on));
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_staff_tax() from public, anon, authenticated;
drop trigger if exists guard_staff_tax on public.staff_tax;
create trigger guard_staff_tax before insert or update or delete on public.staff_tax
  for each row execute function public.guard_staff_tax();

-- Does the signed-in person hold live access of this kind (any scope)?
create or replace function public.holds_area(p_area text)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select public.is_system_admin() or exists (
    select 1 from public.access_grants g join public.profiles me on me.id = g.user_id
     where g.user_id = auth.uid() and g.area = p_area and g.revoked_at is null
       and (g.expires_at is null or g.expires_at > now()) and me.active and me.role in ('manager', 'staff_admin'))
$$;
revoke execute on function public.holds_area(text) from public, anon;
grant execute on function public.holds_area(text) to authenticated;

-- ---------------------------------------------------------------------------
-- Files: tax/<person>/... for TFN forms (TFN access only); templates/ for the
-- blank form (everyone reads, the system admin adds). People allowed delete
-- (manual deletion and the retention clean-up).
-- ---------------------------------------------------------------------------
do $$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  drop policy if exists "staff records: the person and people with access read" on storage.objects;
  create policy "staff records: the person and people with access read" on storage.objects for select to authenticated
    using (bucket_id = 'staff-records' and (
      ((storage.foldername(name))[1] in ('payroll_tax', 'identity_docs')
       and ((storage.foldername(name))[2] = (select auth.uid())::text
            or public.has_access((storage.foldername(name))[1], ((storage.foldername(name))[2])::uuid)))
      or ((storage.foldername(name))[1] = 'tax'
          and ((storage.foldername(name))[2] = (select auth.uid())::text or public.has_tfn_access(((storage.foldername(name))[2])::uuid)))
      or ((storage.foldername(name))[1] = 'templates' and (select public.is_member()))));
  drop policy if exists "staff records: the person and people with access upload" on storage.objects;
  create policy "staff records: the person and people with access upload" on storage.objects for insert to authenticated
    with check (bucket_id = 'staff-records' and (select public.is_member()) and (
      ((storage.foldername(name))[1] in ('payroll_tax', 'identity_docs')
       and ((storage.foldername(name))[2] = (select auth.uid())::text
            or public.has_access((storage.foldername(name))[1], ((storage.foldername(name))[2])::uuid)))
      or ((storage.foldername(name))[1] = 'tax'
          and ((storage.foldername(name))[2] = (select auth.uid())::text or public.has_tfn_access(((storage.foldername(name))[2])::uuid)))
      or ((storage.foldername(name))[1] = 'templates' and ((select public.is_system_admin()) or (select public.holds_area('payroll_tax'))))));
  drop policy if exists "staff records: deleted by people allowed" on storage.objects;
  create policy "staff records: deleted by people allowed" on storage.objects for delete to authenticated
    using (bucket_id = 'staff-records' and (
      (select public.is_system_admin())
      or ((storage.foldername(name))[1] = 'tax' and (storage.foldername(name))[2] <> (select auth.uid())::text
          and public.has_tfn_access(((storage.foldername(name))[2])::uuid))));
end;
$$;

-- ---------------------------------------------------------------------------
-- Keeping records
-- ---------------------------------------------------------------------------
insert into public.app_settings (key, value, label, description, is_public)
values ('records.private_retention_years', '5', 'Keep private staff records after someone leaves (years)',
        'Bank, super, work rights and TFN declarations of people who have left are listed for deletion after this many years. The system admin deletes them.', false)
on conflict (key) do nothing;
insert into public.app_settings (key, value, label, description, is_public)
values ('records.tfn_template', '""', 'Blank TFN declaration form', 'Where the blank form staff can download is stored. Set by the system admin, or a manager or staff admin with Payroll and tax access.', false)
on conflict (key) do nothing;

-- The system admin can delete a leaver's other private records (bank, super,
-- work rights). The Phase 3 rule covered every action; it's split so that
-- people with access read, add and change, and only the system admin deletes.
grant delete on public.staff_bank, public.staff_super, public.staff_work_rights to authenticated;
do $$
declare
  t text;
begin
  foreach t in array array['staff_bank', 'staff_super', 'staff_work_rights'] loop
    execute format('drop policy if exists "the person and people with access" on public.%I', t);
    execute format('drop policy if exists "records: the person and people with access read" on public.%I', t);
    execute format($p$create policy "records: the person and people with access read" on public.%I for select to authenticated
      using ((select public.is_member()) and (user_id = (select auth.uid()) or public.has_access(%L, user_id)))$p$, t, public.record_area(t));
    execute format('drop policy if exists "records: the person and people with access add" on public.%I', t);
    execute format($p$create policy "records: the person and people with access add" on public.%I for insert to authenticated
      with check ((select public.is_member()) and (user_id = (select auth.uid()) or public.has_access(%L, user_id)))$p$, t, public.record_area(t));
    execute format('drop policy if exists "records: the person and people with access change" on public.%I', t);
    execute format($p$create policy "records: the person and people with access change" on public.%I for update to authenticated
      using ((select public.is_member()) and (user_id = (select auth.uid()) or public.has_access(%L, user_id)))
      with check ((select public.is_member()) and (user_id = (select auth.uid()) or public.has_access(%L, user_id)))$p$, t, public.record_area(t), public.record_area(t));
    execute format('drop policy if exists "the system admin deletes records" on public.%I', t);
    execute format('create policy "the system admin deletes records" on public.%I for delete to authenticated using ((select public.is_system_admin()) and user_id <> (select auth.uid()))', t);
  end loop;
end;
$$;

-- Log each deletion of those too.
create or replace function public.log_record_deleted()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if auth.uid() is not null then
    insert into public.sensitive_access_log (actor_id, subject_id, area, action, detail)
    values (auth.uid(), old.user_id, public.record_area(tg_table_name), 'delete',
            case tg_table_name when 'staff_bank' then 'Bank details' when 'staff_super' then 'Super' else 'Work rights' end);
  end if;
  return old;
end;
$$;
revoke execute on function public.log_record_deleted() from public, anon, authenticated;
do $$
declare
  t text;
begin
  foreach t in array array['staff_bank', 'staff_super', 'staff_work_rights'] loop
    execute format('drop trigger if exists log_record_deleted on public.%I', t);
    execute format('create trigger log_record_deleted after delete on public.%I for each row execute function public.log_record_deleted()', t);
  end loop;
end;
$$;

-- The blank form's location can be set by the system admin or Payroll and tax holders.
drop policy if exists "payroll holders set the TFN form template" on public.app_settings;
create policy "payroll holders set the TFN form template" on public.app_settings for update to authenticated
  using (key = 'records.tfn_template' and (select public.holds_area('payroll_tax')))
  with check (key = 'records.tfn_template' and (select public.holds_area('payroll_tax')) and jsonb_typeof(value) = 'string');
commit;
