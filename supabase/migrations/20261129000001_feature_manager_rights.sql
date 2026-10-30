-- Staff Portal · © cmeproject. All rights reserved.
--
-- Feature builder (cmeprojects): what managers may change. For each feature
-- the system admin ticks whether managers can
--   * fix entries (after the undo time, with a reason; the change log keeps
--     the before and after),
--   * set each client's daily target, and
--   * change the drop-down options.
-- Plus, per drop-down: an answer staff type that isn't in the list joins the
-- list for everyone next time.

alter table public.custom_features add column if not exists managers_fix boolean not null default false;
alter table public.custom_features add column if not exists managers_targets boolean not null default false;
alter table public.custom_features add column if not exists managers_options boolean not null default false;
alter table public.custom_fields add column if not exists add_typed boolean not null default false;
alter table public.custom_entries add column if not exists corrected_by uuid references public.profiles (id);
alter table public.custom_entries add column if not exists correction_reason text not null default '';

-- The system admin always; managers when the feature allows it.
create or replace function public.can_manage_feature(p_feature uuid, p_what text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.can_build_features()
      or (public.is_member() and public.mfa_ok() and public.my_role() = 'manager' and public.custom_feature_live(p_feature)
          and exists (select 1 from public.custom_features
                       where id = p_feature
                         and case p_what when 'fix' then managers_fix when 'targets' then managers_targets
                                         when 'options' then managers_options else false end))
$$;

-- Managers who fix entries see them all.
create or replace function public.sees_custom_entry(p_feature uuid, p_by uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_by = auth.uid()
      or public.can_build_features()
      or public.can_manage_feature(p_feature, 'fix')
      or (public.can_see_feature(p_feature) and (public.my_role() <> 'team_leader' or public.leads_user(p_by)))
$$;

-- Checks every answer and returns the cleaned entry. p_old is the entry being
-- fixed (its photos are kept as they are). Typed answers join the list when
-- the field says so.
create or replace function public.clean_custom_entry(p_feature uuid, p_data jsonb, p_old jsonb default null)
returns table (clean jsonb, client_id uuid, client_name text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  f record;
  v text;
  n numeric;
  v_clean jsonb := '{}'::jsonb;
  v_client uuid;
  v_client_name text := '';
  v_new text[];
begin
  if p_data is null or jsonb_typeof(p_data) <> 'object' then
    raise exception 'Fill in the form';
  end if;

  for f in select * from public.custom_fields where feature_id = p_feature and not archived order by sort_order loop
    if f.type = 'multi' then
      if jsonb_typeof(p_data -> f.id::text) = 'array' and jsonb_array_length(p_data -> f.id::text) > 0 then
        select array_agg(x) into v_new from jsonb_array_elements_text(p_data -> f.id::text) x where not f.options ? x;
        if v_new is not null and not f.allow_other then
          raise exception '%: choose from the list', f.label;
        end if;
        if v_new is not null and f.add_typed then
          update public.custom_fields
             set options = options || (select coalesce(jsonb_agg(t), '[]') from unnest(v_new) t
                                         where length(trim(t)) between 1 and 80
                                           and not exists (select 1 from jsonb_array_elements_text(options) o where lower(o) = lower(trim(t))))
           where id = f.id and jsonb_array_length(options) < 60;
        end if;
        v_clean := v_clean || jsonb_build_object(f.id::text, p_data -> f.id::text);
      elsif f.required then
        raise exception '%: choose at least one', f.label;
      end if;
      continue;
    end if;

    v := nullif(trim(p_data ->> f.id::text), '');
    if v is null then
      if f.required then
        raise exception '%: this is needed', f.label;
      end if;
      continue;
    end if;
    if length(v) > (case when f.type = 'long' then 2000 else 200 end) then
      raise exception '%: that''s too long', f.label;
    end if;

    case f.type
      when 'number' then
        begin
          n := v::numeric;
        exception when others then
          raise exception '%: enter a number', f.label;
        end;
        if f.min_value is not null and n < f.min_value then
          raise exception '%: the smallest allowed is %', f.label, f.min_value;
        end if;
        if f.max_value is not null and n > f.max_value then
          raise exception '%: the largest allowed is %', f.label, f.max_value;
        end if;
        v_clean := v_clean || jsonb_build_object(f.id::text, n);
        continue;
      when 'choice' then
        if not f.options ? v then
          if not f.allow_other then
            raise exception '%: choose from the list', f.label;
          end if;
          if f.add_typed and length(v) <= 80 then
            update public.custom_fields set options = options || to_jsonb(v)
             where id = f.id and jsonb_array_length(options) < 60
               and not exists (select 1 from jsonb_array_elements_text(options) o where lower(o) = lower(v));
          end if;
        end if;
      when 'yesno' then
        if v not in ('Yes', 'No') then
          raise exception '%: choose Yes or No', f.label;
        end if;
      when 'date' then
        if v !~ '^\d{4}-\d{2}-\d{2}$' then
          raise exception '%: enter a date', f.label;
        end if;
      when 'time' then
        if v !~ '^\d{2}:\d{2}$' then
          raise exception '%: enter a time', f.label;
        end if;
      when 'client' then
        select c.id, c.name into v_client, v_client_name from public.car_clients c where c.id::text = v and c.active;
        if v_client is null then
          raise exception '%: choose from the list', f.label;
        end if;
      when 'staff' then
        if not exists (select 1 from public.profiles where id::text = v and active) then
          raise exception '%: choose from the list', f.label;
        end if;
      when 'photo' then
        if v not like auth.uid()::text || '/%' and v is distinct from (p_old ->> f.id::text) then
          raise exception '%: upload the photo again', f.label;
        end if;
      else
        null;
    end case;
    v_clean := v_clean || jsonb_build_object(f.id::text, v);
  end loop;

  return query select v_clean, v_client, coalesce(v_client_name, '');
end;
$$;
revoke execute on function public.clean_custom_entry(uuid, jsonb, jsonb) from public, anon, authenticated;

create or replace function public.submit_custom_entry(p_feature uuid, p_data jsonb)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  c record;
  v_id bigint;
begin
  if not public.can_fill_feature(p_feature) then
    raise exception 'You can''t fill this in';
  end if;
  select * into c from public.clean_custom_entry(p_feature, p_data);

  insert into public.custom_entries (feature_id, data, client_id, client_name, team_names)
  values (p_feature, c.clean, c.client_id, c.client_name,
          case when (select record_team from public.custom_features where id = p_feature)
               then coalesce((select string_agg(t.name, ', ' order by t.name) from public.team_members m join public.teams t on t.id = m.team_id
                               where m.user_id = auth.uid()), '')
               else '' end)
  returning id into v_id;
  return v_id;
end;
$$;

-- Fix an entry: the new answers are checked like a new one, and the change
-- log keeps what it was, what it is now, and why.
create or replace function public.correct_custom_entry(p_id bigint, p_data jsonb, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  e public.custom_entries;
  c record;
begin
  select * into e from public.custom_entries where id = p_id for update;
  if e.id is null or not public.can_manage_feature(e.feature_id, 'fix') then
    raise exception 'You can''t fix this entry';
  end if;
  if length(trim(coalesce(p_reason, ''))) < 3 then
    raise exception 'Say why it''s being changed';
  end if;
  select * into c from public.clean_custom_entry(e.feature_id, p_data, e.data);
  if c.clean = e.data then
    raise exception 'Nothing was changed';
  end if;
  update public.custom_entries
     set data = c.clean, client_id = c.client_id, client_name = c.client_name,
         corrected_at = now(), corrected_by = auth.uid(), correction_reason = left(trim(p_reason), 300)
   where id = e.id;
  perform public.write_audit('custom_entry_fixed', 'custom_entry', e.id::text,
    jsonb_build_object('before', e.data, 'after', c.clean, 'reason', left(trim(p_reason), 300)));
end;
$$;

-- Daily targets: the default for everyone and each client's own.
-- p_targets is {client id: target or null}; null takes a client's own target away.
create or replace function public.set_custom_targets(p_feature uuid, p_default numeric, p_targets jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  k text;
  v jsonb;
begin
  if not public.can_manage_feature(p_feature, 'targets') then
    raise exception 'You can''t change these targets';
  end if;
  if p_default is not null and p_default < 0 then
    raise exception 'A target can''t be below zero';
  end if;
  update public.custom_features set default_target = p_default where id = p_feature;
  for k, v in select * from jsonb_each(coalesce(p_targets, '{}')) loop
    if jsonb_typeof(v) = 'number' and (v #>> '{}')::numeric >= 0 then
      insert into public.custom_client_targets (feature_id, client_id, target)
      select p_feature, id, (v #>> '{}')::numeric from public.car_clients where id::text = k
      on conflict (feature_id, client_id) do update set target = excluded.target;
    else
      delete from public.custom_client_targets where feature_id = p_feature and client_id::text = k;
    end if;
  end loop;
  perform public.write_audit('custom_targets_set', 'custom_feature', p_feature::text,
    jsonb_build_object('default', p_default, 'targets', p_targets));
end;
$$;

-- A drop-down's options (managers when allowed; the change log keeps the old list).
create or replace function public.set_custom_field_options(p_field uuid, p_options jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  f public.custom_fields;
  v_list jsonb;
begin
  select * into f from public.custom_fields where id = p_field and not archived;
  if f.id is null or f.type not in ('choice', 'multi') or not public.can_manage_feature(f.feature_id, 'options') then
    raise exception 'You can''t change this list';
  end if;
  if jsonb_typeof(p_options) <> 'array' then
    raise exception 'Give a list of options';
  end if;
  select coalesce(jsonb_agg(o order by n), '[]') into v_list
    from (select distinct on (lower(trim(x))) trim(x) o, n
            from jsonb_array_elements_text(p_options) with ordinality t(x, n)
           where length(trim(x)) between 1 and 80
           order by lower(trim(x)), n) d;
  if jsonb_array_length(v_list) > 60 then
    raise exception 'Keep the list to 60 options';
  end if;
  if jsonb_array_length(v_list) = 0 and not f.allow_other then
    raise exception 'Keep at least one option';
  end if;
  update public.custom_fields set options = v_list where id = f.id;
end;
$$;

revoke execute on function public.can_manage_feature(uuid, text), public.correct_custom_entry(bigint, jsonb, text),
  public.set_custom_targets(uuid, numeric, jsonb), public.set_custom_field_options(uuid, jsonb) from public, anon;
grant execute on function public.can_manage_feature(uuid, text), public.correct_custom_entry(bigint, jsonb, text),
  public.set_custom_targets(uuid, numeric, jsonb), public.set_custom_field_options(uuid, jsonb) to authenticated;
