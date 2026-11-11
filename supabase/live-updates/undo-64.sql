-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 64. WARNING: deletes all contracts, their signatures and the
-- kept versions of policy wording. Signed PDFs stay in the 'contracts' store
-- but nobody can open them (remove them in Supabase → Storage if you no
-- longer need them). Safe to run again.
begin;

-- Policies: back to roles, teams and positions only.
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
    if public.compliance_applies(new, p.role, p.teams) then
      perform public.notify(p.id, 'onboarding_item',
        case when tg_op = 'UPDATE' and new.version > old.version then format('Updated: %s', new.title) else format('%s: %s', v_word, new.title) end,
        case when new.kind = 'form' then 'A form to fill in. It''s also on your My onboarding page.' else 'It''s on your My onboarding page.' end,
        case when new.kind = 'form' and new.form_id is not null then '/forms/' || new.form_id else '/onboarding' end);
    end if;
  end loop;
  return new;
end;
$function$;

-- The daily job without contract expiry.
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

do $$
begin
  if to_regclass('storage.objects') is not null then
    drop policy if exists "contracts: the employee and people with access read" on storage.objects;
    drop policy if exists "contracts: the employee and people with access add files" on storage.objects;
  end if;
end;
$$;

drop table if exists public.contract_signatures;
drop table if exists public.contracts;
drop table if exists public.compliance_item_versions;
drop trigger if exists keep_item_version on public.compliance_items;
drop function if exists public.keep_item_version();
drop function if exists public.guard_contract();
drop function if exists public.contract_supersede();
drop function if exists public.contract_signed();
alter table public.compliance_items drop column if exists applies_people;
commit;
