-- Staff Portal · © cmeproject. All rights reserved.
-- Update 34: a form put in Compliance says "Please fill in" (not "Please
-- upload") and opens the form; "Ask a question" on a form becomes a task
-- for the person who made it. Run update 32 first. Safe to run again.
begin;
--
-- Forms (cmeprojects):
--   * A form put in Compliance is announced as "Please fill in: …" (not
--     "Please upload") and the note opens the form.
--   * "Ask a question" on a form: it becomes a task for the person who made
--     the form (General tasks), or a bell note and email if a task can't be
--     made (for example the asker is a new starter).

create or replace function public.compliance_item_announce()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
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
$$;

create or replace function public.ask_form_question(p_form uuid, p_question text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  f public.forms;
  v_task uuid;
  v_q text := left(trim(coalesce(p_question, '')), 2000);
begin
  if not (public.can_fill_form(p_form) or public.can_manage_form(p_form)) then
    raise exception 'Form not found';
  end if;
  if length(v_q) < 3 then
    raise exception 'Type your question';
  end if;
  select * into f from public.forms where id = p_form;
  if f.created_by = auth.uid() then
    raise exception 'This is your own form';
  end if;
  begin
    v_task := public.create_task(
      left(format('Question about the form: %s', f.title), 200),
      (select id from public.registries where is_default and kind = 'tasks' and active order by sort_order limit 1),
      f.created_by,
      format(E'%s\n\nAsked by %s from the form "%s".', v_q, public.my_name(), f.title),
      'medium');
    return 'task';
  exception when others then
    perform public.notify(f.created_by, 'form_question', format('Question about the form: %s', f.title),
      format('%s asks: %s', public.my_name(), v_q), '/forms/' || f.id || '/replies', true);
    return 'note';
  end;
end;
$$;
revoke execute on function public.ask_form_question(uuid, text) from public, anon;
grant execute on function public.ask_form_question(uuid, text) to authenticated;

commit;
