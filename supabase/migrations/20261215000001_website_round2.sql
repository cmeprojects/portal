-- Staff Portal · © cmeproject. All rights reserved.
--
-- Website, round 2 (cmeprojects):
--   * The system admin can hand "Website" (where the Assistant looks, and
--     its documents) to a manager, like the other System settings areas.
--   * The website's own logo (blank = the portal's), and the words shown
--     while the website is switched off.
--   * Credit bought for the AI, so Website settings can show what's left.
--   * The website becomes the front page.

alter table public.admin_delegations drop constraint if exists admin_delegations_areas_check;
alter table public.admin_delegations add constraint admin_delegations_areas_check
  check (areas <@ array['branding', 'messages', 'people', 'compliance', 'tasks', 'reports', 'vehicles', 'audit', 'website']);

create or replace function public.setting_area(p_key text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when p_key in ('brand.support_contact', 'brand.announcement', 'people.invite_message') then 'messages'
    when p_key like 'brand.%' or p_key like 'wording.%' then 'branding'
    when p_key like 'people.%' then 'people'
    when p_key like 'compliance.%' then 'compliance'
    when p_key like 'tasks.%' then 'tasks'
    when p_key like 'reports.%' then 'reports'
    when p_key like 'vehicles.%' then 'vehicles'
    when p_key like 'website.%' or p_key like 'assistant.%' then 'website'
    else null
  end
$$;

insert into public.app_settings (key, value, label, description, is_public) values
  ('website.logo_url', '""', 'Website logo', 'Leave empty to use the portal''s logo.', true),
  ('website.closed_title', '"Our website is coming soon"', 'Heading while the website is off', 'Shown when Website and Assistant is switched off.', true),
  ('website.closed_text', '"In the meantime, please call us, or sign in if you''re part of the team."', 'Words while the website is off', 'Shown under that heading.', true)
on conflict (key) do nothing;
update public.app_settings set value = 'true' where key = 'website.front_page';

alter table public.assistant_settings add column if not exists credit_aud numeric(8,2) not null default 0 check (credit_aud >= 0);
alter table public.assistant_settings add column if not exists credit_since date;

-- Website settings and documents: the system admin, or a manager given "Website".
drop policy if exists assistant_settings_read on public.assistant_settings;
create policy assistant_settings_read on public.assistant_settings
  for select to authenticated using (public.can_admin_area('website'));
drop policy if exists assistant_settings_write on public.assistant_settings;
create policy assistant_settings_write on public.assistant_settings
  for update to authenticated using (public.can_admin_area('website')) with check (public.can_admin_area('website'));
drop policy if exists assistant_documents_all on public.assistant_documents;
create policy assistant_documents_all on public.assistant_documents
  for all to authenticated using (public.can_admin_area('website')) with check (public.can_admin_area('website'));
drop policy if exists assistant_questions_read on public.assistant_questions;
create policy assistant_questions_read on public.assistant_questions
  for select to authenticated using (public.can_admin_area('website'));

-- Indexing a document: the same people.
create or replace function public.assistant_index(p_document uuid)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_body text;
  v_piece text := '';
  v_para text;
  v_pos int := 0;
begin
  if not public.can_admin_area('website') then
    raise exception 'Only the system admin (or a manager given Website) can do this' using errcode = '42501';
  end if;
  select body into v_body from public.assistant_documents where id = p_document;
  if v_body is null then return 0; end if;
  delete from public.assistant_chunks where document_id = p_document;
  foreach v_para in array regexp_split_to_array(v_body, E'\\n\\s*\\n') loop
    v_para := btrim(v_para);
    continue when v_para = '';
    -- A very long paragraph is split further.
    while length(v_para) > 1400 loop
      if v_piece <> '' then
        v_pos := v_pos + 1;
        insert into public.assistant_chunks (document_id, position, content) values (p_document, v_pos, v_piece);
        v_piece := '';
      end if;
      v_pos := v_pos + 1;
      insert into public.assistant_chunks (document_id, position, content) values (p_document, v_pos, left(v_para, 1200));
      v_para := substr(v_para, 1201);
    end loop;
    if length(v_piece) + length(v_para) > 900 and v_piece <> '' then
      v_pos := v_pos + 1;
      insert into public.assistant_chunks (document_id, position, content) values (p_document, v_pos, v_piece);
      v_piece := '';
    end if;
    v_piece := case when v_piece = '' then v_para else v_piece || E'\n\n' || v_para end;
  end loop;
  if v_piece <> '' then
    v_pos := v_pos + 1;
    insert into public.assistant_chunks (document_id, position, content) values (p_document, v_pos, v_piece);
  end if;
  return v_pos;
end $$;
revoke all on function public.assistant_index(uuid) from public, anon;
grant execute on function public.assistant_index(uuid) to authenticated;

-- Questions from forms are tagged "Staff question" too.
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
      left(format('Staff question: about the form %s', f.title), 200),
      (select id from public.registries where is_default and kind = 'tasks' and active order by sort_order limit 1),
      f.created_by,
      format(E'%s\n\nAsked by %s from the form "%s".', v_q, public.my_name(), f.title),
      'medium');
    return 'task';
  exception when others then
    perform public.notify(f.created_by, 'form_question', format('Staff question: about the form %s', f.title),
      format('%s asks: %s', public.my_name(), v_q), '/forms/' || f.id || '/replies', true);
    return 'note';
  end;
end;
$$;
