-- Staff Portal · © cmeproject. All rights reserved.
--
-- Feature builder alerts (cmeprojects). The system admin adds rules to a
-- feature: when an entry is saved (or fixed) and matches, chosen people are
-- told straight away by the bell, email, or both. Managers by default.
--
-- What sets an alert off:
--   any          every new entry
--   choice       a drop-down or yes/no answer is a given value
--   above/below  a number is above or below a limit
--   total_over   a client's daily total goes over their target (a restriction)
--   total_met    a client's daily total reaches their target (a goal)

create table if not exists public.custom_alerts (
  id             uuid primary key default gen_random_uuid(),
  feature_id     uuid not null references public.custom_features (id) on delete cascade,
  name           text not null default '' check (length(name) <= 80),
  when_kind      text not null default 'any' check (when_kind in ('any', 'choice', 'above', 'below', 'total_over', 'total_met')),
  field_id       uuid references public.custom_fields (id) on delete cascade,
  match_text     text not null default '' check (length(match_text) <= 80),
  limit_value    numeric,
  notify_roles   public.app_role[] not null default '{manager}',
  notify_leader  boolean not null default false,
  notify_people  uuid[] not null default '{}',
  by_bell        boolean not null default true,
  by_email       boolean not null default false,
  on_fix         boolean not null default false,
  message        text not null default '' check (length(message) <= 200),
  active         boolean not null default true,
  created_at     timestamptz not null default now()
);
create index if not exists custom_alerts_feature on public.custom_alerts (feature_id);

alter table public.custom_alerts enable row level security;
drop policy if exists "the builder manages alerts" on public.custom_alerts;
create policy "the builder manages alerts" on public.custom_alerts for all to authenticated
  using (public.can_build_features()) with check (public.can_build_features());

drop trigger if exists custom_alerts_log on public.custom_alerts;
create trigger custom_alerts_log after insert or update or delete on public.custom_alerts
  for each row execute function public.log_feature_setup('custom_alert');

-- A client's total for the entry's day, with or without this entry.
create or replace function public.custom_day_total(p_entry public.custom_entries, p_with boolean)
returns numeric
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(sum((e.data ->> f.total_field::text)::numeric), 0)
    from public.custom_entries e
    join public.custom_features f on f.id = e.feature_id
   where e.feature_id = p_entry.feature_id
     and e.client_id = p_entry.client_id
     and (p_with or e.id <> p_entry.id)
     and jsonb_typeof(e.data -> f.total_field::text) = 'number'
     and (e.created_at at time zone coalesce((select value #>> '{}' from public.app_settings where key = 'region.timezone'), 'Australia/Melbourne'))::date
       = (p_entry.created_at at time zone coalesce((select value #>> '{}' from public.app_settings where key = 'region.timezone'), 'Australia/Melbourne'))::date
$$;
revoke execute on function public.custom_day_total(public.custom_entries, boolean) from public, anon, authenticated;

-- Runs after an entry is saved or fixed: tells people for each matching alert.
create or replace function public.fire_custom_alerts()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  feat public.custom_features;
  a public.custom_alerts;
  v_fixed boolean := tg_op = 'UPDATE';
  v_answer text;
  v_num numeric;
  v_target numeric;
  v_before numeric;
  v_after numeric;
  v_unit text;
  v_staff text;
  v_title text;
  v_body text;
  v_user uuid;
  v_detail text;
begin
  if v_fixed and new.data is not distinct from old.data then
    return new;
  end if;
  select * into feat from public.custom_features where id = new.feature_id;
  if not (feat.status = 'published' and feat.enabled) then
    return new;
  end if;
  select coalesce(nullif(full_name, ''), email) into v_staff from public.profiles where id = new.created_by;
  select unit into v_unit from public.custom_fields where id = feat.total_field;

  for a in select * from public.custom_alerts where feature_id = new.feature_id and active and (not v_fixed or on_fix) loop
    v_detail := '';
    v_answer := case when a.field_id is null then null
                     when jsonb_typeof(new.data -> a.field_id::text) = 'array'
                       then (select string_agg(x, ', ') from jsonb_array_elements_text(new.data -> a.field_id::text) x)
                     else new.data ->> a.field_id::text end;

    if a.when_kind = 'choice' then
      if v_answer is null or not (lower(v_answer) = lower(a.match_text)
             or (jsonb_typeof(new.data -> a.field_id::text) = 'array'
                 and exists (select 1 from jsonb_array_elements_text(new.data -> a.field_id::text) x where lower(x) = lower(a.match_text)))) then
        continue;
      end if;
      v_detail := format('%s: %s', (select label from public.custom_fields where id = a.field_id), a.match_text);
    elsif a.when_kind in ('above', 'below') then
      begin
        v_num := v_answer::numeric;
      exception when others then
        continue;
      end;
      if v_num is null or a.limit_value is null
         or (a.when_kind = 'above' and v_num <= a.limit_value)
         or (a.when_kind = 'below' and v_num >= a.limit_value) then
        continue;
      end if;
      select format('%s: %s%s', label, rtrim(to_char(v_num, 'FM999G999G990D##'), '.'), case when unit <> '' then ' ' || unit else '' end)
        into v_detail from public.custom_fields where id = a.field_id;
    elsif a.when_kind in ('total_over', 'total_met') then
      if new.client_id is null or feat.total_field is null then
        continue;
      end if;
      v_target := coalesce((select target from public.custom_client_targets where feature_id = feat.id and client_id = new.client_id), feat.default_target);
      if v_target is null then
        continue;
      end if;
      v_after := public.custom_day_total(new, true);
      v_before := case when v_fixed then v_after - coalesce((new.data ->> feat.total_field::text)::numeric, 0)
                                               + coalesce((old.data ->> feat.total_field::text)::numeric, 0)
                       else public.custom_day_total(new, false) end;
      -- Only when the total crosses the line, so it's one alert a day.
      if (a.when_kind = 'total_over' and not (v_after > v_target and v_before <= v_target))
         or (a.when_kind = 'total_met' and not (v_after >= v_target and v_before < v_target)) then
        continue;
      end if;
      v_detail := format('%s is at %s of %s%s today', new.client_name, trim(to_char(v_after, 'FM999G999G990')),
                         trim(to_char(v_target, 'FM999G999G990')), case when v_unit <> '' then ' ' || v_unit else '' end);
    end if;

    v_title := coalesce(nullif(trim(replace(replace(replace(a.message, '{client}', new.client_name), '{staff}', v_staff), '{feature}', feat.name)), ''),
                        format('%s: %s', feat.name, coalesce(nullif(a.name, ''), case when a.when_kind = 'any' then 'new entry' else v_detail end)));
    v_body := concat_ws(' · ',
                        nullif(v_detail, ''),
                        nullif(case when a.when_kind in ('total_over', 'total_met') then '' else new.client_name end, ''),
                        format('%s by %s', case when v_fixed then 'Fixed' else 'Entered' end, v_staff));

    for v_user in
      select p.id from public.profiles p
       where p.active and p.id <> coalesce(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
         and (p.role = any (a.notify_roles)
              or p.id = any (a.notify_people)
              or (a.notify_leader and exists (select 1 from public.team_leaders l join public.team_members m on m.team_id = l.team_id
                                               where m.user_id = new.created_by and l.user_id = p.id)))
    loop
      if a.by_bell then
        insert into public.notifications (user_id, kind, title, body, href)
        values (v_user, 'feature_alert', left(v_title, 200), v_body, '/f/' || feat.slug);
      end if;
      if a.by_email and public.feature_enabled('email_notifications') then
        insert into public.email_outbox (to_user, template, data)
        values (v_user, 'notice', jsonb_build_object('title', left(v_title, 200), 'body', v_body, 'href', '/f/' || feat.slug));
      end if;
    end loop;
  end loop;
  return new;
end;
$$;
revoke execute on function public.fire_custom_alerts() from public, anon, authenticated;

drop trigger if exists custom_entries_alerts on public.custom_entries;
create trigger custom_entries_alerts after insert or update of data on public.custom_entries
  for each row execute function public.fire_custom_alerts();
