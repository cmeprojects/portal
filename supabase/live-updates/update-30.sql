-- Staff Portal · © cmeproject. All rights reserved.
-- Update 30: the Staff app (a premium add-on, off until the system admin
-- switches it on), people told when their role changes, and open pages
-- signing out an account that's turned off. Safe to run again.
begin;
--
-- The Staff app (cmeprojects): one phone app holding the features the system
-- admin chooses (built features, and Cars if they like), with its own name
-- and icon. A premium add-on, off until the system admin switches it on. The
-- Cars app carries on as its own app; the system admin can switch that off
-- when Cars lives in the Staff app instead.

insert into public.features (key, label, description, enabled, sort_order, premium, included) values
  ('staff_app', 'Staff app',
   'One phone app for staff with the features you choose: built features like Fluid intake, and Cars if you like.',
   false, 76, true, false)
on conflict (key) do nothing;

-- Shown on phones before anyone signs in, so public.
insert into public.app_settings (key, value, label, description, is_public) values
  ('staff_app.name', '"Staff"', 'Staff app name on the phone',
   'The name under the icon on staff phones. Keep it short (about 12 letters), for example EC Staff.', true),
  ('staff_app.icon', '"car"', 'Staff app icon',
   'The picture on staff phones'' home screens. Tap one to use it, or upload your own.', true),
  ('staff_app.icon_uploads', '[]', 'Uploaded Staff app icons', 'Pictures uploaded for the Staff app icon.', true),
  ('staff_app.cars', 'false', 'Cars in the Staff app',
   'Show Cars as an icon inside the Staff app.', true),
  ('vehicles.separate_app', 'true', 'Separate Cars app',
   'Keep the Cars app as its own app. Turn off if Cars is in the Staff app and you want only one app.', true)
on conflict (key) do nothing;

-- Each built feature: in the Staff app or not, and its icon there.
alter table public.custom_features add column if not exists in_app boolean not null default true;
alter table public.custom_features add column if not exists app_icon text not null default 'clipboard' check (length(app_icon) <= 20);
alter table public.custom_features add column if not exists app_colour text not null default '#134f8e' check (app_colour ~ '^#[0-9a-fA-F]{6}$');

--
-- When someone's role changes, they're told (cmeprojects): a note in their
-- bell, and a banner at the top of the portal. Their menu updates by itself.
-- Someone whose account is turned off is signed out of any open page.

create or replace function public.notify_role_changed()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_label text := case new.role
    when 'support_worker' then 'Support worker' when 'team_leader' then 'Team leader' when 'manager' then 'Manager'
    when 'staff_admin' then 'Staff admin' when 'system_admin' then 'System admin' else 'New starter' end;
  v_title text := (select name from public.job_titles where id = new.job_title_id);
begin
  if new.active and new.role is distinct from old.role then
    perform public.notify(new.id, 'role_changed',
      format('Your role is now %s', coalesce(v_title, v_label)),
      'Your menu has been updated to show what you can use now.', '/', false);
  end if;
  return new;
end;
$$;
revoke execute on function public.notify_role_changed() from public, anon, authenticated;

drop trigger if exists profiles_role_changed on public.profiles;
create trigger profiles_role_changed after update of role on public.profiles
  for each row execute function public.notify_role_changed();

-- A role change or a deactivated account refreshes open pages straight away
-- (a deactivated person's page then signs them out). Anyone signed in can see
-- these signals: they only say that something changed, not what.
drop policy if exists "members see signals" on public.live_signals;
drop policy if exists "signed-in people see signals" on public.live_signals;
create policy "signed-in people see signals" on public.live_signals for select to authenticated using (true);

drop trigger if exists profiles_access_signal on public.profiles;
create trigger profiles_access_signal after update of role, active on public.profiles
  for each statement execute function public.signal_change('people');

commit;
