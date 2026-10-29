-- Staff Portal · © cmeproject. All rights reserved.
--
-- Premium features (cmeprojects). Some features are paid add-ons, marked
-- Premium. The system admin (cmeproject) switches them on for a company that
-- has them in its plan; nobody else can. Cars is the first.

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

-- Only the system admin decides what's included (from System settings →
-- Features, or the SQL Editor); no one else can change it.
create or replace function public.guard_feature_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.is_system_admin()
     and (new.premium is distinct from old.premium or new.included is distinct from old.included) then
    raise exception 'Only the system admin can change what''s included in the plan';
  end if;
  if new.enabled and not new.included and not old.enabled then
    raise exception '% isn''t included in the plan.', new.label;
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_feature_change() from public, anon, authenticated;

drop trigger if exists features_guard on public.features;
create trigger features_guard before update on public.features for each row execute function public.guard_feature_change();
