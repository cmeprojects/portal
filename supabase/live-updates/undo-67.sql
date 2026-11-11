-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 67. WARNING: deletes the TFN declaration records and the access
-- log entries for deletions and ATO dates. Uploaded files stay in the
-- 'staff-records' store (remove them in Supabase → Storage if needed).
-- Safe to run again.
begin;

drop table if exists public.staff_tax;
drop function if exists public.guard_staff_tax();

-- Back to one rule for bank, super and work rights (no deleting).
do $$
declare
  t text;
begin
  foreach t in array array['staff_bank', 'staff_super', 'staff_work_rights'] loop
    execute format('drop policy if exists "the system admin deletes records" on public.%I', t);
    execute format('drop policy if exists "records: the person and people with access read" on public.%I', t);
    execute format('drop policy if exists "records: the person and people with access add" on public.%I', t);
    execute format('drop policy if exists "records: the person and people with access change" on public.%I', t);
    execute format('drop trigger if exists log_record_deleted on public.%I', t);
  end loop;
end;
$$;
revoke delete on public.staff_bank, public.staff_super, public.staff_work_rights from authenticated;
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
drop function if exists public.log_record_deleted();

delete from public.sensitive_access_log where action in ('delete', 'lodged');
alter table public.sensitive_access_log drop constraint if exists sensitive_access_log_action_check;
alter table public.sensitive_access_log add constraint sensitive_access_log_action_check
  check (action in ('view', 'reveal', 'download', 'upload', 'change', 'verify', 'refused'));

do $$
begin
  if to_regclass('storage.objects') is null then
    return;
  end if;
  drop policy if exists "staff records: deleted by people allowed" on storage.objects;
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
end;
$$;

drop policy if exists "payroll holders set the TFN form template" on public.app_settings;
delete from public.app_settings where key in ('records.private_retention_years', 'records.tfn_template');
drop function if exists public.has_tfn_access(uuid);
drop function if exists public.holds_area(text);
commit;
