-- Staff Portal · © cmeproject. All rights reserved.
-- Update 19: System health (how full the database and files are, the hourly
-- timer and emails). Run once, after update 18.
begin;
--
-- System health (cmeprojects, system admin only): how full the database and
-- file storage are for the Supabase plan, whether the hourly timer is
-- running, and whether emails are going out.

insert into public.app_settings (key, value, label, description, is_public) values
  ('system.hosting_plan', '"free"', 'Supabase plan',
   'Free or Pro, so System health shows how full the database and file storage are.', false)
on conflict (key) do nothing;

-- The hourly timer writes here each time it runs (with the service key).
create table public.system_heartbeat (
  job      text primary key,
  ran_at   timestamptz not null default now(),
  ok       boolean not null default true,
  detail   text not null default ''
);
alter table public.system_heartbeat enable row level security;
revoke all on public.system_heartbeat from anon, authenticated;

create function public.system_health()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_files jsonb := '[]'::jsonb;
begin
  if not public.is_system_admin() then
    raise exception 'Only the system admin can see System health' using errcode = 'insufficient_privilege';
  end if;
  -- File storage (Supabase keeps each file's size with it), by bucket.
  if to_regclass('storage.objects') is not null then
    execute $q$select coalesce(jsonb_agg(jsonb_build_object('bucket', bucket_id, 'files', n, 'bytes', b) order by b desc), '[]'::jsonb)
                 from (select bucket_id, count(*) n, coalesce(sum((metadata ->> 'size')::bigint), 0) b
                         from storage.objects group by bucket_id) s$q$
      into v_files;
  end if;
  return jsonb_build_object(
    'database_bytes', pg_database_size(current_database()),
    'files', v_files,
    'people_active', (select count(*) from public.profiles where active and role <> 'system_admin'),
    'people_total', (select count(*) from public.profiles),
    'tasks_open', (select count(*) from public.tasks where status not in ('completed', 'closed')),
    'tasks_total', (select count(*) from public.tasks),
    'trips_total', (select count(*) from public.car_trips),
    'cars_active', (select count(*) from public.cars where active),
    'emails_waiting', (select count(*) from public.email_outbox where sent_at is null and attempts < 5),
    'emails_failed', (select count(*) from public.email_outbox where sent_at is null and attempts >= 5),
    'emails_sent_week', (select count(*) from public.email_outbox where sent_at > now() - interval '7 days'),
    'oldest_waiting', (select min(created_at) from public.email_outbox where sent_at is null and attempts < 5),
    'last_error', (select last_error from public.email_outbox where last_error is not null order by id desc limit 1),
    'timer', (select to_jsonb(h) from public.system_heartbeat h where job = 'hourly')
  );
end;
$$;
revoke all on function public.system_health() from public, anon;
grant execute on function public.system_health() to authenticated;
commit;
