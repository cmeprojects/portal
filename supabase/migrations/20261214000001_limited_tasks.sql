-- Staff Portal · © cmeproject. All rights reserved.
--
-- Limited tasks (cmeprojects): some roles (support workers by default) may
-- only raise General tasks and questions themselves. Tasks made for them by
-- the portal (alerts, form questions) aren't affected.

insert into public.app_settings (key, value, label, description, is_public) values
  ('tasks.limited_roles', '["support_worker"]', 'Who can only raise General tasks and questions',
   'They don''t see the other registers in New task. They follow what they raised in My tasks → My requests and questions.', false)
on conflict (key) do nothing;

create or replace function public.limited_task_guard() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  -- Only a person creating a task themselves (not a task made by another rule).
  if pg_trigger_depth() = 1 and new.created_by = auth.uid()
     and public.my_role()::text in (select jsonb_array_elements_text(coalesce(
           (select value from public.app_settings where key = 'tasks.limited_roles'), '[]')))
     and not exists (select 1 from public.registries r where r.id = new.registry_id and r.is_default) then
    raise exception 'You can raise General tasks and questions only' using errcode = '42501';
  end if;
  return new;
end $$;
drop trigger if exists limited_task_guard on public.tasks;
create trigger limited_task_guard before insert on public.tasks
  for each row execute function public.limited_task_guard();
