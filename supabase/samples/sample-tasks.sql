-- Staff Portal · © cmeproject. All rights reserved.
--
-- Ten sample tasks across the registers, for testing only. Run it in the
-- Supabase SQL Editor. Tasks go round-robin to active staff (system admins
-- can't be given tasks), so invite at least one person first.
-- Every title starts with "[Sample]". To remove them later:
--   delete from public.tasks where title like '[Sample]%';

do $$
declare
  v_people uuid[];
  v_creator uuid;
  v_task uuid;
  v_reg uuid;
  i int := 0;
  s record;
begin
  select array_agg(id order by created_at) into v_people
    from public.profiles where active and role <> 'system_admin';
  if v_people is null then
    raise exception 'Invite at least one staff member (not a system admin) first, then run this again.';
  end if;
  select id into v_creator from public.profiles
   where active order by (role in ('manager', 'staff_admin')) desc, created_at limit 1;

  for s in
    select * from (values
      ('GEN', '[Sample] Restock the office printer paper', 'Two boxes of A4 for the front office.', 'low', 10, 'assigned', '{}'::jsonb),
      ('GEN', '[Sample] Update the staff phone list', 'Add the new starters and remove anyone who has left.', 'medium', 5, 'in_progress', '{}'::jsonb),
      ('RSK', '[Sample] Slippery path at the side entrance', 'Moss on the pavers after rain. Needs cleaning and a sign.', 'high', 3, 'assigned', '{"risk_rating": "High"}'::jsonb),
      ('RSK', '[Sample] Kitchen fire blanket missing', 'Replace the fire blanket in the main house kitchen.', 'urgent', 1, 'escalated', '{"risk_rating": "Extreme"}'::jsonb),
      ('RSK', '[Sample] Loose handrail on the back steps', 'Tighten or replace the bracket.', 'medium', -2, 'in_progress', '{"risk_rating": "Medium"}'::jsonb),
      ('MNT', '[Sample] Bathroom tap dripping', 'Hot tap in bathroom 2 drips constantly.', 'medium', 7, 'assigned', '{}'::jsonb),
      ('MNT', '[Sample] Service the van', 'Due for its 60,000 km service.', 'high', 14, 'assigned', '{}'::jsonb),
      ('DOC', '[Sample] Review the incident reporting policy', 'Yearly review. Check it matches current practice.', 'medium', 21, 'assigned', '{"document_title": "Incident Reporting Policy"}'::jsonb),
      ('CFB', '[Sample] Family compliment about weekend outing', 'Pass the thanks on to the weekend team.', 'low', 4, 'completed', '{"report_type": "Compliment"}'::jsonb),
      ('CIR', '[Sample] Trial a digital shift handover checklist', 'Try it for two weeks at one house and collect feedback.', 'medium', 30, 'in_progress', '{}'::jsonb)
    ) as t(prefix, title, description, priority, due_in, status, details)
  loop
    select id into v_reg from public.registries where prefix = s.prefix and kind = 'tasks' and active limit 1;
    continue when v_reg is null;
    i := i + 1;
    insert into public.tasks (title, description, registry_id, ref_number, priority, status, assigned_to, created_by,
                              due_date, details, date_reported, completed_at, escalated)
    values (s.title, s.description, v_reg, public.take_ref_number(v_reg), s.priority::public.task_priority,
            s.status::public.task_status, v_people[1 + (i - 1) % array_length(v_people, 1)], v_creator,
            current_date + s.due_in, s.details, current_date - (i % 5),
            case when s.status = 'completed' then now() end, s.status = 'escalated')
    returning id into v_task;
    insert into public.task_events (task_id, actor_id, type, to_value)
    values (v_task, v_creator, 'created', v_people[1 + (i - 1) % array_length(v_people, 1)]::text);
  end loop;

  raise notice 'Added % sample tasks.', i;
end;
$$;
