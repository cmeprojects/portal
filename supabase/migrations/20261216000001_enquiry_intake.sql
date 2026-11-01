-- Staff Portal · © cmeproject. All rights reserved.
--
-- Enquiry intake (cmeprojects): each new website enquiry becomes a "Call
-- back" task for the intake person (staff admins to start with; the system
-- admin can change who), due the next business day: weekends and public
-- holidays don't count. They get the bell straight away and an email once
-- emails are switched on.

insert into public.app_settings (key, value, label, description, is_public) values
  ('assistant.intake_roles', '["staff_admin"]', 'Who calls back new enquiries',
   'Each new enquiry becomes a Call back task for one of them (whoever has the fewest open), due the next business day.', false),
  ('tasks.public_holidays', '["2026-12-25 Christmas Day", "2026-12-28 Boxing Day (observed)", "2027-01-01 New Year''s Day", "2027-01-26 Australia Day", "2027-03-08 Labour Day", "2027-03-26 Good Friday", "2027-03-27 Easter Saturday", "2027-03-29 Easter Monday", "2027-06-14 King''s Birthday", "2027-11-02 Melbourne Cup", "2027-12-27 Christmas Day (observed)", "2027-12-28 Boxing Day (observed)"]',
   'Public holidays', 'One per line: the date (YYYY-MM-DD), then its name. These don''t count as business days (Victoria to start with; add the Grand Final Friday each year).', false)
on conflict (key) do nothing;

-- The next business day after a date: not a weekend, not a listed holiday.
create or replace function public.next_business_day(p_from date)
returns date
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  d date := p_from + 1;
  v_holidays date[];
begin
  select coalesce(array_agg(left(h, 10)::date), '{}') into v_holidays
    from jsonb_array_elements_text(coalesce((select value from public.app_settings where key = 'tasks.public_holidays'), '[]')) h
   where h ~ '^\d{4}-\d{2}-\d{2}';
  while extract(isodow from d) in (6, 7) or d = any (v_holidays) loop
    d := d + 1;
  end loop;
  return d;
end $$;

create or replace function public.website_enquiry_notify() returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_intake uuid;
  v_registry uuid;
  v_task uuid;
begin
  -- The people who see enquiries get the bell.
  insert into public.notifications (user_id, kind, title, body, href)
  select p.id, 'website_enquiry', 'New enquiry: ' || new.full_name, 'Phone ' || new.phone || '. Call them back.', '/enquiries'
    from public.profiles p
   where p.active and (p.role = 'system_admin' or p.role::text in (select jsonb_array_elements_text(coalesce(
           (select value from public.app_settings where key = 'assistant.enquiry_roles'), '[]'))));

  -- A Call back task for the intake person with the fewest open ones.
  select p.id into v_intake
    from public.profiles p
   where p.active and p.role::text in (select jsonb_array_elements_text(coalesce(
           (select value from public.app_settings where key = 'assistant.intake_roles'), '[]')))
   order by (select count(*) from public.tasks t where t.assigned_to = p.id and t.title like 'Call back: %'
              and t.status not in ('completed', 'closed')), p.full_name
   limit 1;
  select id into v_registry from public.registries where is_default and kind = 'tasks' and active order by sort_order limit 1;
  if v_intake is null or v_registry is null then
    return new;
  end if;

  insert into public.tasks (title, description, registry_id, ref_number, priority, assigned_to, created_by, due_date, details, date_reported)
  values (left('Call back: ' || new.full_name, 200),
          concat_ws(E'\n', 'New enquiry from the website. Please call them back by the due date.', '',
            'Phone: ' || new.phone,
            nullif('Email: ' || new.email, 'Email: '),
            nullif('Suburb: ' || new.suburb, 'Suburb: '),
            nullif('Support is for: ' || new.support_for, 'Support is for: '),
            nullif('NDIS plan: ' || concat_ws(', ', nullif(new.has_plan, ''), nullif(new.managed_by, '')), 'NDIS plan: '),
            nullif('Looking for: ' || array_to_string(new.needs, ', '), 'Looking for: '),
            nullif('Best time to call: ' || new.best_time, 'Best time to call: '),
            nullif('They asked the assistant: ' || new.asked, 'They asked the assistant: '),
            nullif('Message: ' || new.message, 'Message: ')),
          v_registry, public.take_ref_number(v_registry), 'high', v_intake, v_intake,
          public.next_business_day(public.local_today()), '{}'::jsonb, public.local_today())
  returning id into v_task;
  insert into public.task_events (task_id, actor_id, type, to_value) values (v_task, null, 'created', v_intake::text);
  perform public.queue_task_email('task_assigned', v_task, v_intake);
  insert into public.notifications (user_id, kind, title, body, href)
  values (v_intake, 'task_assigned', 'Call back: ' || new.full_name, 'A new enquiry from the website. Due the next business day.', '/tasks/' || v_task);
  return new;
end $$;
