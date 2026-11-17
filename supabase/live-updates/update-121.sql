-- Staff Portal · © cmeproject. All rights reserved.
-- Update 121: performance and development reviews, and HR reminders (HR
-- block step 5). Safe to run again. Undo: undo-121.sql. Run update 120 first.
begin;
--
-- cmeprojects (update 121; HR block step 5, owner's order): performance and
-- development.
--
--   * New part "Performance and development" (sensitive: a role or a person
--     only). Managers and staff admins: everyone. Team leaders: their teams'
--     staff (a team rule, like requests). Each person sees their own reviews
--     once they're held, and acknowledges them. Nobody runs their own review.
--   * A review is a probation review, an annual review or a check-in, with a
--     due date, then held (date, summary, goals, training and development
--     plan) or cancelled. A held review stays as it was (except the person's
--     acknowledgement). Nothing is deleted.
--   * Reminders (from the hourly timer, server only): 14 days before a review
--     is due and once when overdue, to the reviewer (else the managers); and
--     the day before a leaving person's last day, to whoever started the
--     offboarding.

insert into public.app_modules (id, parent_id, category, label, sensitivity, delegable, sort_order, actions) values
  ('hr.performance', null, 'hr', 'Performance and development', 'sensitive', true, 247, '{view,edit}')
on conflict (id) do nothing;

create table if not exists public.staff_reviews (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  user_id uuid not null references public.profiles (id) on delete restrict,
  kind text not null check (kind in ('probation', 'annual', 'check_in')),
  due_on date not null,
  reviewer_id uuid references public.profiles (id),
  status text not null default 'planned' check (status in ('planned', 'held', 'cancelled')),
  held_on date,
  summary text not null default '' check (length(summary) <= 5000),
  goals text not null default '' check (length(goals) <= 3000),
  development text not null default '' check (length(development) <= 3000),
  outcome text not null default '' check (outcome in ('', 'passed', 'extended', 'not_passed', 'on_track', 'needs_support')),
  acknowledged_at timestamptz,
  created_by uuid default auth.uid() references public.profiles (id),
  created_at timestamptz not null default now(),
  closed_by uuid references public.profiles (id),
  updated_at timestamptz not null default now()
);
create index if not exists staff_reviews_user on public.staff_reviews (user_id);
create index if not exists staff_reviews_due on public.staff_reviews (due_on) where status = 'planned';
alter table public.staff_reviews enable row level security;

-- Team leaders: their own teams' staff (not themselves).
create or replace function public.leads_person(p_person uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select exists (select 1 from public.team_leaders tl join public.team_members tm on tm.team_id = tl.team_id
                  where tl.user_id = (select auth.uid()) and tm.user_id = p_person and p_person <> (select auth.uid()))
$$;
grant execute on function public.leads_person(uuid) to authenticated;

drop policy if exists "see reviews" on public.staff_reviews;
create policy "see reviews" on public.staff_reviews
  for select to authenticated
  using ((user_id = (select auth.uid()) and status = 'held')
         or (user_id <> (select auth.uid()) and (public.can('hr.performance', 'view', user_id) or public.leads_person(user_id))));
drop policy if exists "plan reviews" on public.staff_reviews;
create policy "plan reviews" on public.staff_reviews
  for insert to authenticated
  with check (user_id <> (select auth.uid()) and (public.can('hr.performance', 'edit', user_id) or public.leads_person(user_id)));
drop policy if exists "hold reviews" on public.staff_reviews;
create policy "hold reviews" on public.staff_reviews
  for update to authenticated
  using ((user_id <> (select auth.uid()) and (public.can('hr.performance', 'edit', user_id) or public.leads_person(user_id)))
         or (user_id = (select auth.uid()) and status = 'held'))
  with check ((user_id <> (select auth.uid()) and (public.can('hr.performance', 'edit', user_id) or public.leads_person(user_id)))
              or (user_id = (select auth.uid()) and status = 'held'));
-- No delete rule.
grant select, insert, update on public.staff_reviews to authenticated;

create or replace function public.guard_staff_review()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.status := 'planned';
    new.held_on := null;
    new.acknowledged_at := null;
    new.created_by := auth.uid();
    new.created_at := now();
    new.reviewer_id := coalesce(new.reviewer_id, auth.uid());
    if new.reviewer_id = new.user_id then
      raise exception 'Someone else runs their review.';
    end if;
    return new;
  end if;
  if (new.user_id, new.kind, new.created_by, new.created_at) is distinct from (old.user_id, old.kind, old.created_by, old.created_at) then
    raise exception 'A review stays with its person and kind.';
  end if;
  -- The person themselves: only their acknowledgement.
  if old.user_id = auth.uid() then
    if (new.status, new.due_on, new.reviewer_id, new.held_on, new.summary, new.goals, new.development, new.outcome, new.closed_by)
       is distinct from (old.status, old.due_on, old.reviewer_id, old.held_on, old.summary, old.goals, old.development, old.outcome, old.closed_by) then
      raise exception 'You can only acknowledge your review.';
    end if;
    new.acknowledged_at := coalesce(old.acknowledged_at, now());
    new.updated_at := now();
    return new;
  end if;
  if new.acknowledged_at is distinct from old.acknowledged_at then
    raise exception 'Only the person acknowledges their review.';
  end if;
  if old.status <> 'planned' then
    raise exception 'This review is closed and stays as it was.';
  end if;
  if new.reviewer_id = new.user_id then
    raise exception 'Someone else runs their review.';
  end if;
  if new.status = 'held' then
    if new.held_on is null or length(trim(new.summary)) = 0 then
      raise exception 'Record when it was held and a summary.';
    end if;
    if new.held_on > public.local_today() then
      raise exception 'A review can''t be held in the future.';
    end if;
  end if;
  if new.status <> 'planned' then
    new.closed_by := auth.uid();
  end if;
  new.updated_at := now();
  return new;
end;
$$;
revoke execute on function public.guard_staff_review() from public, anon, authenticated;
drop trigger if exists guard_staff_review on public.staff_reviews;
create trigger guard_staff_review before insert or update on public.staff_reviews
  for each row execute function public.guard_staff_review();

-- Reminders sent (one per review, kind and day). Server only.
create table if not exists public.hr_alerts_sent (
  kind text not null,
  item_id uuid not null,
  due_on date not null,
  sent_at timestamptz not null default now(),
  primary key (kind, item_id, due_on)
);
alter table public.hr_alerts_sent enable row level security;

create or replace function public.run_hr_alerts()
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  r record;
  v_reviews int := 0;
  v_leaving int := 0;
  v_today date := public.local_today();
begin
  for r in
    select s.id, s.user_id, s.kind, s.due_on, s.reviewer_id, p.full_name, p.email,
           case when s.due_on < v_today then 'staff_review_overdue' else 'staff_review_due' end as alert
      from public.staff_reviews s join public.profiles p on p.id = s.user_id and p.active
     where s.status = 'planned' and s.due_on <= v_today + 14
  loop
    if not exists (select 1 from public.hr_alerts_sent a where a.kind = r.alert and a.item_id = r.id and a.due_on = r.due_on) then
      insert into public.hr_alerts_sent (kind, item_id, due_on) values (r.alert, r.id, r.due_on);
      perform public.notify(u.id, r.alert,
        case r.kind when 'probation' then 'Probation review' when 'annual' then 'Annual review' else 'Check-in' end
          || case when r.alert = 'staff_review_overdue' then ' is overdue' else ' due ' || to_char(r.due_on, 'DD Mon YYYY') end,
        coalesce(nullif(r.full_name, ''), r.email), '/settings/staff/' || r.user_id || '?tab=performance', true)
        from public.profiles u
       where u.active and u.id <> r.user_id
         and (u.id = r.reviewer_id or (r.reviewer_id is null and u.role = 'manager'));
      v_reviews := v_reviews + 1;
    end if;
  end loop;
  for r in
    select o.id, o.user_id, o.last_day, o.started_by, p.full_name, p.email
      from public.offboardings o join public.profiles p on p.id = o.user_id
     where o.status = 'open' and o.last_day = v_today + 1
  loop
    if not exists (select 1 from public.hr_alerts_sent a where a.kind = 'last_day_tomorrow' and a.item_id = r.id and a.due_on = r.last_day) then
      insert into public.hr_alerts_sent (kind, item_id, due_on) values ('last_day_tomorrow', r.id, r.last_day);
      perform public.notify(r.started_by, 'last_day_tomorrow', 'Last day tomorrow: check the offboarding list',
        coalesce(nullif(r.full_name, ''), r.email), '/settings/staff/' || r.user_id || '?tab=offboarding', true)
       where r.started_by is not null;
      v_leaving := v_leaving + 1;
    end if;
  end loop;
  return jsonb_build_object('staff_reviews', v_reviews, 'last_days', v_leaving);
end;
$$;
revoke execute on function public.run_hr_alerts() from public, anon, authenticated;
grant execute on function public.run_hr_alerts() to service_role;

-- Switched over from the start: the people who manage staff.
update public.app_modules set grant_ready = true where id = 'hr.performance' and not grant_ready;
insert into public.access_baselines (access_level, module_id, actions, scope, note)
select l::public.app_role, 'hr.performance', '{}', 'all', 'HR block default: people who manage staff'
  from unnest(array['manager', 'staff_admin']) l
 where not exists (select 1 from public.access_baselines b where b.module_id = 'hr.performance' and b.revoked_at is null and b.access_level = l::public.app_role);
insert into public.function_group_modules (function_group_id, module_id)
select g.id, 'hr.performance' from public.function_groups g where g.key in ('hr_workforce', 'management_admin')
on conflict do nothing;
commit;
