-- Staff Portal · © cmeproject. All rights reserved.
--
-- Forms (cmeprojects): instead of a whole form being anonymous, a form can
-- allow it, and each person chooses: they tick "Answer anonymously" and their
-- name isn't kept with their answers. (forms.anonymous now means "allowed".)

comment on column public.forms.anonymous is 'People may tick "Answer anonymously" on this form.';

drop function if exists public.submit_form_response(uuid, jsonb, boolean);

-- Save a reply (p_send = false keeps it as a draft to finish later). If the
-- form allows it and they ticked "Answer anonymously", their name isn't kept
-- with the answers (only that they've done it).
create or replace function public.submit_form_response(p_form uuid, p_answers jsonb, p_send boolean default true, p_anonymous boolean default false)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  f public.forms;
  q record;
  v text;
  v_clean jsonb := '{}'::jsonb;
  v_id bigint;
  v_item uuid;
  v_anon boolean;
begin
  if not public.can_fill_form(p_form) then
    raise exception 'This form isn''t open';
  end if;
  select * into f from public.forms where id = p_form;
  v_anon := f.anonymous and coalesce(p_anonymous, false);
  if not f.repeatable and exists (select 1 from public.form_completions where form_id = f.id and user_id = auth.uid()) then
    raise exception 'You''ve already filled this in';
  end if;
  if p_answers is null or jsonb_typeof(p_answers) <> 'object' then
    raise exception 'Fill in the form';
  end if;

  for q in select * from public.form_questions where form_id = f.id and not archived order by sort_order loop
    if q.type = 'multi' then
      if jsonb_typeof(p_answers -> q.id::text) = 'array' and jsonb_array_length(p_answers -> q.id::text) > 0 then
        if exists (select 1 from jsonb_array_elements_text(p_answers -> q.id::text) x where not q.options ? x) then
          raise exception '%: choose from the list', q.label;
        end if;
        v_clean := v_clean || jsonb_build_object(q.id::text, p_answers -> q.id::text);
      elsif q.required and p_send then
        raise exception '%: choose at least one', q.label;
      end if;
      continue;
    end if;
    v := nullif(trim(p_answers ->> q.id::text), '');
    if v is null then
      if q.required and p_send then
        raise exception '%: this is needed', q.label;
      end if;
      continue;
    end if;
    if length(v) > (case when q.type = 'long' then 5000 else 300 end) then
      raise exception '%: that''s too long', q.label;
    end if;
    if q.type = 'choice' and not q.options ? v then
      raise exception '%: choose from the list', q.label;
    elsif q.type = 'yesno' and v not in ('Yes', 'No') then
      raise exception '%: choose Yes or No', q.label;
    elsif q.type = 'date' and v !~ '^\d{4}-\d{2}-\d{2}$' then
      raise exception '%: enter a date', q.label;
    elsif q.type = 'number' and v !~ '^-?\d+(\.\d+)?$' then
      raise exception '%: enter a number', q.label;
    elsif q.type = 'file' and v not like auth.uid()::text || '/%' then
      raise exception '%: upload the file again', q.label;
    end if;
    v_clean := v_clean || jsonb_build_object(q.id::text, v);
  end loop;

  -- Their saved draft becomes this reply (or stays a draft).
  select id into v_id from public.form_responses where form_id = f.id and user_id = auth.uid() and status = 'draft';
  if v_id is not null then
    update public.form_responses
       set answers = v_clean, updated_at = now(),
           status = case when p_send then 'submitted' else 'draft' end,
           submitted_at = case when p_send then now() end,
           user_id = case when p_send and v_anon then null else user_id end
     where id = v_id;
  else
    insert into public.form_responses (form_id, user_id, answers, status, submitted_at)
    values (f.id, case when p_send and v_anon then null else auth.uid() end, v_clean,
            case when p_send then 'submitted' else 'draft' end, case when p_send then now() end)
    returning id into v_id;
  end if;

  if p_send then
    insert into public.form_completions (form_id, user_id) values (f.id, auth.uid())
    on conflict (form_id, user_id) do update set done_at = now();
    -- Part of Compliance: it counts as done.
    for v_item in select id from public.compliance_items where form_id = f.id and active loop
      insert into public.compliance_records (item_id, user_id, version, status)
      select v_item, auth.uid(), version, 'done' from public.compliance_items where id = v_item;
    end loop;
    if f.notify_creator and f.created_by <> auth.uid() then
      perform public.notify(f.created_by, 'form_reply', format('New reply: %s', f.title),
        case when v_anon then 'Someone sent a reply anonymously.' else format('%s sent a reply.', public.my_name()) end,
        '/forms/' || f.id || '/replies', false);
    end if;
  end if;
  return v_id;
end;
$$;

revoke execute on function public.submit_form_response(uuid, jsonb, boolean, boolean) from public, anon;
grant execute on function public.submit_form_response(uuid, jsonb, boolean, boolean) to authenticated;
