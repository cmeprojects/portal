-- Staff Portal · © cmeproject. All rights reserved.
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
