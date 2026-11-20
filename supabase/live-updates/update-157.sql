-- Staff Portal · © cmeproject. All rights reserved.
-- Update 157: an opening of a client's page or audit trail is recorded once.
-- Safe to run again. Undo: undo-157.sql.
begin;
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
commit;
