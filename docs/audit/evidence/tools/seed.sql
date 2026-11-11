-- cmeprojects perf audit: synthetic data (local copy only, fake people).
do $$
declare i int; reg uuid; boss uuid; tid uuid; ppl uuid[];
begin
  for i in 1..300 loop
    insert into public.invitations (email, full_name, role) values (format('perf%s@example.test', i), format('Test Person %s', i), (array['support_worker','support_worker','support_worker','team_leader'])[1 + i % 4]::public.app_role) on conflict do nothing;
    insert into auth.users (id, email, aud, role) values (gen_random_uuid(), format('perf%s@example.test', i), 'authenticated', 'authenticated') on conflict do nothing;
  end loop;
  select array_agg(id) into ppl from public.profiles where email like 'perf%@example.test';
  select id into boss from public.profiles where email = 'boss@example.com';
  update public.profiles set joined_at = now() - interval '30 days' where email like 'perf%@example.test';
  for reg in select id from public.registries where kind = 'tasks' and active loop
    insert into public.tasks (ref_number, registry_id, title, description, status, priority, assigned_to, created_by, due_date, created_at)
    select (select coalesce(max(ref_number), 0) from public.tasks t2 where t2.registry_id = reg) + g, reg, format('Synthetic task %s', g), 'Test only', (array['assigned','in_progress','completed','closed','awaiting_approval'])[1 + g % 5]::public.task_status,
           (array['low','medium','high'])[1 + g % 3]::public.task_priority, ppl[1 + g % array_length(ppl, 1)], boss,
           current_date - 60 + (g % 90), now() - (g % 120) * interval '1 day'
      from generate_series(1, 1500) g;
  end loop;
  insert into public.notifications (user_id, kind, title, body, href)
  select boss, 'task_assigned', format('Synthetic notice %s', g), 'Test only', '/tasks' from generate_series(1, 3000) g;
  insert into public.compliance_records (item_id, user_id, version, status, file_path, file_name, created_at)
  select i.id, p, 1, (array['submitted','accepted','rejected'])[1 + (abs(hashtext(p::text)) % 3)], p::text || '/x.pdf', 'x.pdf', now() - interval '5 days'
    from public.compliance_items i, unnest(ppl) p where i.kind = 'upload' and i.active;
end $$;
select (select count(*) from public.profiles) profiles, (select count(*) from public.tasks) tasks, (select count(*) from public.notifications) notices, (select count(*) from public.compliance_records) records;
