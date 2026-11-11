-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 62. WARNING: deletes the bank, super and work-rights records
-- staff have entered, and the access log. Files already uploaded stay in the
-- 'staff-records' store but nobody can open them (remove them in Supabase →
-- Storage if you no longer need them). Safe to run again.
begin;

-- Reminders as before (one before expiry, one after).
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

delete from public.compliance_alerts where step not in ('expiring', 'expired');
alter table public.compliance_alerts drop constraint if exists compliance_alerts_step_check;
alter table public.compliance_alerts add constraint compliance_alerts_step_check check (step in ('expiring', 'expired'));

-- The three new default items, only if nobody has used them.
delete from public.compliance_items i
 where i.title in ('First Aid certificate', 'CPR certificate', 'Life saving certificate') and i.created_by is null
   and not exists (select 1 from public.compliance_records r where r.item_id = i.id);

do $$
begin
  if to_regclass('storage.objects') is not null then
    drop policy if exists "staff records: the person and people with access read" on storage.objects;
    drop policy if exists "staff records: the person and people with access upload" on storage.objects;
  end if;
end;
$$;

drop table if exists public.work_rights_alerts;
drop table if exists public.staff_bank;
drop table if exists public.staff_super;
drop table if exists public.staff_work_rights;
drop table if exists public.sensitive_access_log;
drop function if exists public.guard_staff_record();
drop function if exists public.record_area(text);
drop function if exists public.expiry_stage(date);
commit;
