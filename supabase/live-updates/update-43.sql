-- Staff Portal · © cmeproject. All rights reserved.
-- Update 43: Demo data tools for the system admin (System settings → Demo
-- data): load sample records, delete only those, or delete every task.
-- Nothing is deleted by running this file. Safe to run again.
-- To remove the tools, run undo-43.sql.
begin;
-- Demo data tools for the system admin (cmeprojects): load a fresh set of
-- sample records to show the portal, delete just those sample records, or
-- clear every task to start again. Each sample record is listed in
-- demo_records, so deleting them never touches real work.

create table if not exists public.demo_records (
  table_name text not null check (table_name in ('tasks', 'website_enquiries')),
  row_id     uuid not null,
  primary key (table_name, row_id)
);
alter table public.demo_records enable row level security;
revoke all on public.demo_records from anon, authenticated;

-- Removes the given tasks and everything hanging off them. Task history is
-- normally append-only; its guard is lifted for this delete only.
create or replace function public.delete_tasks_completely(p_ids uuid[])
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count int;
begin
  if not public.is_system_admin() then
    raise exception 'Only the system admin can do this' using errcode = '42501';
  end if;
  if coalesce(cardinality(p_ids), 0) = 0 then
    return 0;
  end if;
  update public.tasks set parent_task_id = null where parent_task_id = any (p_ids);
  update public.people_change_requests set task_id = null where task_id = any (p_ids);
  delete from public.notifications where href in (select '/tasks/' || unnest(p_ids)::text);
  delete from public.email_outbox where task_id = any (p_ids);
  alter table public.task_events disable trigger task_events_append_only;
  delete from public.task_events where task_id = any (p_ids);
  alter table public.task_events enable trigger task_events_append_only;
  delete from public.tasks where id = any (p_ids);
  get diagnostics v_count = row_count;
  delete from public.demo_records where table_name = 'tasks' and row_id = any (p_ids);
  return v_count;
end $$;
revoke all on function public.delete_tasks_completely(uuid[]) from public, anon, authenticated;

-- Every task, sample or real. The system admin types DELETE to confirm in the portal.
create or replace function public.demo_clear_all_tasks()
returns int
language sql
security definer
set search_path = ''
as $$
  select public.delete_tasks_completely(coalesce((select array_agg(id) from public.tasks), '{}'))
$$;
revoke all on function public.demo_clear_all_tasks() from public, anon;
grant execute on function public.demo_clear_all_tasks() to authenticated;

-- Only the sample records loaded by demo_load().
create or replace function public.demo_clear()
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tasks int;
  v_enquiries int;
begin
  if not public.is_system_admin() then
    raise exception 'Only the system admin can do this' using errcode = '42501';
  end if;
  v_tasks := public.delete_tasks_completely(coalesce((select array_agg(row_id) from public.demo_records where table_name = 'tasks'), '{}'));
  delete from public.notifications n using public.website_enquiries e, public.demo_records d
   where d.table_name = 'website_enquiries' and d.row_id = e.id and n.kind = 'website_enquiry' and n.title = 'New enquiry: ' || e.full_name;
  delete from public.website_enquiries where id in (select row_id from public.demo_records where table_name = 'website_enquiries');
  get diagnostics v_enquiries = row_count;
  delete from public.demo_records where table_name = 'website_enquiries';
  return v_tasks + v_enquiries;
end $$;
revoke all on function public.demo_clear() from public, anon;
grant execute on function public.demo_clear() to authenticated;

-- A fresh set of sample records: 12 tasks across the registers, in different
-- states, given to the active staff in turn, plus 3 website enquiries (each
-- makes its own Call back task). No emails go out for them.
create or replace function public.demo_load()
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_people uuid[];
  v_general uuid;
  v_task uuid;
  v_enquiry uuid;
  v_today date := public.local_today();
  v_count int := 0;
  i int := 0;
  r record;
begin
  if not public.is_system_admin() then
    raise exception 'Only the system admin can do this' using errcode = '42501';
  end if;
  select array_agg(id order by full_name) into v_people
    from public.profiles where active and role not in ('system_admin', 'new_starter');
  select id into v_general from public.registries where is_default and kind = 'tasks' and active order by sort_order limit 1;
  if v_people is null or v_general is null then
    raise exception 'Add at least one active staff member first';
  end if;

  for r in
    select * from (values
      ('Fall in the lounge: follow up with family', 'incident', 'urgent', 'in_progress', -1, 'Client slipped near the lounge door at 3 pm. Check the floor mats and call the family.'),
      ('Medication missed: morning dose', 'incident', 'high', 'assigned', 0, 'Morning dose not signed for. Check with the support worker and the pharmacy pack.'),
      ('Replace smoke alarm battery: Unit 4', 'maint', 'low', 'assigned', 5, 'Beeping since Tuesday.'),
      ('Fix the back gate latch', 'maint', 'medium', 'completed', -3, 'Gate doesn''t close by itself.'),
      ('Wet floor near the kitchen: risk review', 'risk', 'medium', 'assigned', 7, 'Slippery after mopping. Review signage and mopping times.'),
      ('Car service due: Corolla 1AB 2CD', 'general', 'medium', 'assigned', 3, 'Book the 60,000 km service.'),
      ('Order gloves and hand sanitiser', 'general', 'low', 'completed', -2, 'Monthly order for all houses.'),
      ('Roster: cover for Saturday afternoon', 'general', 'high', 'in_progress', 1, 'Need cover for 2 pm to 8 pm.'),
      ('Staff question: can I swap my Saturday shift?', 'general', 'medium', 'assigned', 2, 'Swap with Lee for Sunday. Is that OK?'),
      ('Update the emergency contacts list', 'general', 'medium', 'escalated', -2, 'Two numbers are out of date.'),
      ('Client review meeting: plan goals', 'general', 'high', 'assigned', 4, 'Prepare notes for the plan review.'),
      ('First aid certificate renewals', 'general', 'medium', 'assigned', 10, 'Three certificates expire next month.')
    ) as t(title, kind, priority, status, due_in, description)
  loop
    i := i + 1;
    insert into public.tasks (title, description, registry_id, ref_number, priority, assigned_to, created_by, due_date, details, date_reported, status, completed_at)
    select r.title, r.description, reg.id, public.take_ref_number(reg.id), r.priority::public.task_priority,
           v_people[1 + (i % cardinality(v_people))], auth.uid(), v_today + r.due_in, '{}'::jsonb, v_today - 2,
           r.status::public.task_status, case when r.status = 'completed' then now() - interval '1 day' end
      from (select coalesce(
              (select id from public.registries where kind = 'tasks' and active and not is_default
                 and name ilike case r.kind when 'incident' then '%incident%' when 'maint' then '%mainten%' when 'risk' then '%risk%' else '-' end
               order by sort_order limit 1),
              v_general) as id) reg
    returning id into v_task;
    insert into public.task_events (task_id, actor_id, type, to_value) values (v_task, auth.uid(), 'created', null);
    insert into public.demo_records values ('tasks', v_task);
    v_count := v_count + 1;
  end loop;

  for r in
    select * from (values
      ('Jordan Sample', '0412 345 678', 'jordan@example.com', 'Sampleton 3000', 'Me', array['Community access'], 'What''s your cancellation policy?'),
      ('Priya Test', '0400 111 222', '', 'Testville 3011', 'A family member', array['Daily living support'], ''),
      ('Alex Example', '03 9000 1234', 'alex@example.com', 'Exampleburg 3121', 'Someone I support (coordinator)', array['Supported independent living'], 'How do I start with you?')
    ) as e(full_name, phone, email, suburb, support_for, needs, asked)
  loop
    insert into public.website_enquiries (full_name, phone, email, suburb, support_for, needs, asked, source, consent)
    values (r.full_name, r.phone, r.email, r.suburb, r.support_for, r.needs, r.asked, case when r.asked = '' then 'form' else 'chat' end, true)
    returning id into v_enquiry;
    insert into public.demo_records values ('website_enquiries', v_enquiry);
    -- The Call back task it made is a sample too.
    insert into public.demo_records
    select 'tasks', t.id from public.tasks t where t.title = 'Call back: ' || r.full_name
       and not exists (select 1 from public.demo_records d where d.table_name = 'tasks' and d.row_id = t.id)
    on conflict do nothing;
    v_count := v_count + 1;
  end loop;

  -- Sample records don't send emails.
  delete from public.email_outbox where task_id in (select row_id from public.demo_records where table_name = 'tasks');
  return v_count;
end $$;
revoke all on function public.demo_load() from public, anon;
grant execute on function public.demo_load() to authenticated;

commit;
