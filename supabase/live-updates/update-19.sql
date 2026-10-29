-- Staff Portal · © cmeproject. All rights reserved.
-- Update 19: who sees Registers, and premium features (Cars is premium and
-- stays included for Engaged Care). Safe to run again.
begin;

-- ===== 20261124000001_registers_menu.sql =====
--
-- Who sees Registers in the menu (cmeprojects). The system admin always does;
-- staff open their own tasks from My tasks either way.

insert into public.app_settings (key, value, label, description, is_public) values
  ('tasks.registers_roles', '["team_leader", "manager", "staff_admin"]', 'Who sees Registers',
   'Besides the system admin. People without it still see and create their own tasks under Tasks.', false)
on conflict (key) do nothing;

-- ===== 20261125000001_premium_features.sql =====
--
-- Premium features (cmeprojects). Some features are add-ons: cmeproject
-- includes them in a company's plan (in the database, never from the portal),
-- and the system admin then switches them on or off. Cars is the first.
--   To include Cars for a company:      update public.features set included = true  where key = 'vehicles';
--   To take it out of a company's plan: update public.features set included = false where key = 'vehicles';

alter table public.features add column if not exists premium boolean not null default false;
alter table public.features add column if not exists included boolean not null default true;
update public.features set premium = true where key = 'vehicles';

-- A feature only works if it's switched on and included in the plan.
create or replace function public.feature_enabled(p_key text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select enabled and included from public.features where key = p_key), false)
$$;

-- People in the portal can switch features on and off, but can't change what's
-- premium or included (that's done by cmeproject in the database).
create or replace function public.guard_feature_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null and (new.premium is distinct from old.premium or new.included is distinct from old.included) then
    raise exception 'Only cmeproject can change what''s included in your plan';
  end if;
  if new.enabled and not new.included and not old.enabled then
    raise exception '% isn''t included in your plan. Contact cmeproject to add it.', new.label;
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_feature_change() from public, anon, authenticated;

drop trigger if exists features_guard on public.features;
create trigger features_guard before update on public.features for each row execute function public.guard_feature_change();
commit;
