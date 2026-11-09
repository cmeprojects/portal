-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 58: removes clearance to work, overrides, cleared-only rules,
-- signed agreements and the new document and training details. Documents,
-- policies and trainings people already did stay. Safe to run again.
begin;
drop trigger if exists guard_cleared_tasks on public.tasks;
drop trigger if exists guard_cleared_trips on public.car_trips;
drop trigger if exists compliance_record_changed on public.compliance_records;
drop trigger if exists role_given_finish_onboarding on public.profiles;
drop trigger if exists mandatory_training_needs_certificate on public.compliance_items;
drop function if exists public.mandatory_training_needs_certificate();
drop function if exists public.guard_cleared_tasks();
drop function if exists public.guard_cleared_trips();
drop function if exists public.compliance_record_changed();
drop function if exists public.role_given_finish_onboarding();
drop function if exists public.grant_clearance(uuid, text);
drop function if exists public.revoke_clearance(uuid, text);
drop function if exists public.grant_work_override(uuid, text, date);
drop function if exists public.end_work_override(bigint);
drop function if exists public.finish_onboarding_task(uuid);
drop function if exists public.request_replacement(bigint, text);
drop function if exists public.sign_agreement(uuid, text, text, text);
drop function if exists public.submit_document(uuid, text, text, date, date, text);
drop function if exists public.complete_training(uuid, date, text, text, text, date);
drop function if exists public.acknowledge_policy(uuid, text);
drop function if exists public.open_compliance_item(uuid);
drop function if exists public.refresh_compliance_verified(uuid);
drop function if exists public.work_status(uuid);
drop function if exists public.can_work(uuid);
drop function if exists public.active_override(uuid);
drop function if exists public.compliance_is_verified(uuid);
drop function if exists public.before_work_missing(uuid);
drop function if exists public.can_grant_clearance();
drop table if exists public.work_overrides;
drop table if exists public.compliance_opens;

-- Agreements and replacement requests didn't exist before.
delete from public.compliance_items where kind = 'agreement';
update public.compliance_records set status = 'rejected' where status = 'replace_requested';
alter table public.compliance_items drop constraint if exists compliance_items_kind_check;
alter table public.compliance_items add constraint compliance_items_kind_check check (kind in ('read', 'training', 'upload', 'form'));
alter table public.compliance_records drop constraint if exists compliance_records_status_check;
alter table public.compliance_records add constraint compliance_records_status_check check (status in ('done', 'submitted', 'accepted', 'rejected'));
delete from public.features where key = 'compliance_agreement';
delete from public.app_settings where key in ('compliance.clearance_roles', 'cars.cleared_only', 'compliance.clearance_started');

drop function if exists public.compliance_status(uuid, public.app_role, uuid[]);
drop function if exists public.compliance_status_all(uuid, public.app_role, uuid[]);
drop function if exists public.compliance_applies(public.compliance_items, public.app_role, uuid[], uuid);
create function public.compliance_status(p_user uuid, p_role public.app_role default null, p_teams uuid[] default null)
returns table (item_id uuid, kind text, title text, state text, record_id bigint, expires_on date, note text, sort_order int)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_role public.app_role;
  v_teams uuid[];
  v_warn int := coalesce((select (value #>> '{}')::int from public.app_settings where key = 'compliance.expiry_warning_days'), 30);
  v_today date := public.local_today();
begin
  if not (p_user = auth.uid() or public.can_manage_compliance() or public.can_manage_people()
          or public.has_role(array['manager']::public.app_role[]) or public.leads_user(p_user)
          or auth.uid() is null) then
    return;
  end if;
  select coalesce(p_role, p.role) into v_role from public.profiles p where p.id = p_user;
  v_teams := coalesce(p_teams, (select array_agg(team_id) from public.team_members where user_id = p_user), '{}');

  return query
  select i.id, i.kind, i.title,
         case
           when r.id is null then 'todo'
           when i.kind <> 'upload' then case when r.version >= i.version then 'done' else 'update' end
           when r.status = 'rejected' then 'rejected'
           when r.expires_on is not null and r.expires_on < v_today then 'expired'
           when r.expires_on is not null and r.expires_on <= v_today + v_warn then 'expiring'
           else r.status
         end,
         r.id, r.expires_on, coalesce(r.review_note, ''), i.sort_order
    from public.compliance_items i
    left join lateral (
      select * from public.compliance_records cr
       where cr.item_id = i.id and cr.user_id = p_user
       order by cr.created_at desc, cr.id desc limit 1
    ) r on true
   where public.compliance_applies(i, v_role, v_teams)
   order by array_position(array['read', 'training', 'upload'], i.kind), i.sort_order, i.title;
end;
$$;
revoke execute on function public.compliance_status(uuid, public.app_role, uuid[]) from public, anon;
grant execute on function public.compliance_status(uuid, public.app_role, uuid[]) to authenticated;

create or replace function public.onboarding_missing(p_user uuid, p_role public.app_role default null, p_teams uuid[] default null)
returns text[]
language sql
stable
security definer
set search_path = ''
as $$
  select (case when public.profile_required(p_user) then array['Complete your profile'] else '{}'::text[] end)
      || coalesce((select array_agg(s.title order by array_position(array['read', 'training', 'upload'], s.kind), s.sort_order, s.title)
                     from public.compliance_status(p_user, p_role, p_teams) s
                    where s.state not in ('done', 'submitted', 'accepted', 'expiring')), '{}')
$$;

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
  if r.id is null or r.status not in ('submitted', 'accepted', 'rejected') then
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

alter table public.compliance_items drop column if exists category, drop column if exists before_work, drop column if exists applies_titles,
  drop column if exists needs_issue_date, drop column if exists needs_number, drop column if exists certificate;
alter table public.compliance_records drop column if exists issued_on, drop column if exists doc_number, drop column if exists completed_on,
  drop column if exists provider, drop column if exists signed_name, drop column if exists signature_path,
  drop column if exists content_hash, drop column if exists signed_from;
alter table public.profiles drop column if exists compliance_verified_at, drop column if exists cleared_at, drop column if exists cleared_by;
alter table public.registries drop column if exists cleared_only;
commit;
