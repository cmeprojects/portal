-- Staff Portal · © cmeproject. All rights reserved.
-- Update 17: staff admins and managers upload documents for staff; expiring
-- documents are emailed to the person 30 days before. Run once.
begin;
--
-- Uploading for someone, and expiry reminders by email.
--   Staff admins (anyone who manages Compliance) and managers can upload a
--   document on a person's behalf. A Compliance manager's upload counts as
--   checked; a manager's goes to a staff admin to check, as usual.
--   The person now gets an email (as well as the bell) when a document is
--   about to expire, not only once it has.

alter table public.compliance_records add column uploaded_by uuid references public.profiles (id) default auth.uid();
update public.compliance_records set uploaded_by = user_id where uploaded_by is null;

create function public.submit_compliance_upload_for(p_user_id uuid, p_item_id uuid, p_path text, p_name text, p_expires date default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  i public.compliance_items;
  v_checker boolean := public.can_manage_compliance();
  v_name text;
  v_admin uuid;
begin
  if not (v_checker or (public.has_role(array['manager']::public.app_role[]) and public.mfa_ok())) then
    raise exception 'Only staff admins and managers can upload for someone else';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'Upload your own documents on My onboarding';
  end if;
  if not exists (select 1 from public.profiles where id = p_user_id and active) then
    raise exception 'Choose someone who can sign in';
  end if;
  select * into i from public.compliance_items where id = p_item_id and active and kind = 'upload';
  if i.id is null then
    raise exception 'Uploads for this document are switched off';
  end if;
  if p_path is null or p_path not like p_user_id::text || '/%' then
    raise exception 'Upload the file again';
  end if;
  if i.needs_expiry and p_expires is null then
    raise exception 'Enter the expiry date';
  end if;
  if p_expires is not null and p_expires < public.local_today() then
    raise exception 'This document has already expired. Upload a current one.';
  end if;

  insert into public.compliance_records (item_id, user_id, version, status, file_path, file_name, expires_on,
                                         uploaded_by, reviewed_by, reviewed_at)
  values (i.id, p_user_id, i.version, case when v_checker then 'accepted' else 'submitted' end,
          p_path, left(coalesce(p_name, ''), 200), p_expires, auth.uid(),
          case when v_checker then auth.uid() end, case when v_checker then now() end);

  perform public.notify(p_user_id, 'uploaded_for_you', format('%s uploaded your %s', public.my_name(), i.title),
    'You don''t need to upload it yourself.', '/onboarding');
  if not v_checker then
    select coalesce(nullif(full_name, ''), email) into v_name from public.profiles where id = p_user_id;
    for v_admin in select a from public.people_admins() a loop
      continue when v_admin = auth.uid();
      perform public.notify(v_admin, 'upload_submitted', format('%s uploaded %s for %s', public.my_name(), i.title, v_name),
        'Check it on the Compliance page.', '/compliance/people/' || p_user_id);
    end loop;
  end if;
  perform public.write_audit('uploaded_for_someone', 'profile', p_user_id::text, jsonb_build_object('item', i.title));
  perform public.check_onboarding_complete(p_user_id);
end;
$$;

revoke execute on function public.submit_compliance_upload_for(uuid, uuid, text, text, date) from public, anon;
grant execute on function public.submit_compliance_upload_for(uuid, uuid, text, text, date) to authenticated;

create or replace function public.run_compliance_alerts()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  s record;
  v_n int := 0;
  v_admin uuid;
  v_name text;
begin
  for s in
    select p.id user_id, coalesce(nullif(p.full_name, ''), p.email) person, st.title, st.state, st.record_id, st.expires_on
      from public.profiles p
      cross join lateral public.compliance_status(p.id) st
     where p.active and p.role <> 'system_admin' and st.state in ('expiring', 'expired') and st.record_id is not null
  loop
    insert into public.compliance_alerts (record_id, step) values (s.record_id, s.state) on conflict do nothing;
    continue when not found;
    v_n := v_n + 1;
    -- The person: bell and email, both before it expires and once it has.
    perform public.notify(s.user_id, 'document_' || s.state,
      case when s.state = 'expired' then format('%s has expired', s.title) else format('%s expires soon', s.title) end,
      format('Expiry date: %s. Upload a new copy on My onboarding.', to_char(s.expires_on, 'FMDD Mon YYYY')),
      '/onboarding', true);
    for v_admin in select a from public.people_admins() a loop
      continue when v_admin = s.user_id;
      perform public.notify(v_admin, 'document_' || s.state,
        format('%s: %s %s', s.person, s.title, case when s.state = 'expired' then 'has expired' else 'expires soon' end),
        format('Expiry date: %s.', to_char(s.expires_on, 'FMDD Mon YYYY')),
        '/compliance/people/' || s.user_id, s.state = 'expired');
    end loop;
  end loop;
  return jsonb_build_object('document_alerts', v_n);
end;
$$;

revoke execute on function public.run_compliance_alerts() from public, anon, authenticated;
grant execute on function public.run_compliance_alerts() to service_role;

-- Staff admins and managers can put files in a person's folder.
do $storage$
begin
  if to_regclass('storage.buckets') is null then
    return;
  end if;
  create policy "staff admins and managers upload for staff" on storage.objects
    for insert to authenticated
    with check (bucket_id = 'compliance-files'
                and (public.can_manage_compliance() or (public.has_role(array['manager']::public.app_role[]) and public.mfa_ok())));
end;
$storage$;
commit;
