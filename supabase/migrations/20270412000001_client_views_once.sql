-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 157): an opening is recorded once. Opening a client's
-- page, or their activity and audit trail, is recorded at most once an hour
-- for each person (the owner's rule since update 140). The page checked that
-- itself, so requests arriving together (a double click, a refresh while
-- loading) could each be recorded. The database now makes the check, one
-- request at a time, and skips a repeat within the hour. Genuine openings
-- after that are still recorded. Runs as the person (no security definer).
-- Nothing is deleted. Safe to run again.

create or replace function public.client_view_once() returns trigger
language plpgsql set search_path = '' as $$
begin
  -- One at a time for this person, client and kind of opening.
  perform pg_advisory_xact_lock(hashtextextended(new.client_id::text || '/' || new.user_id::text || '/' || new.area, 157));
  if exists (select 1 from public.client_staff_views v
              where v.client_id = new.client_id and v.user_id = new.user_id and v.area = new.area
                and v.viewed_at > now() - interval '1 hour') then
    return null; -- already recorded within the hour
  end if;
  return new;
end;
$$;
revoke execute on function public.client_view_once() from public, anon, authenticated;
drop trigger if exists client_view_once on public.client_staff_views;
create trigger client_view_once before insert on public.client_staff_views
  for each row execute function public.client_view_once();
