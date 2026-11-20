-- Staff Portal · © cmeproject. All rights reserved.
-- Update 156: one change-log entry per client change.
-- Safe to run again. Undo: undo-156.sql.
begin;
CREATE OR REPLACE FUNCTION public.guard_client_location()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $$
declare
  v_ref text := (select client_ref from public.car_clients where id = new.client_id);
  v_moved boolean;
begin
  if tg_op = 'UPDATE' and new.client_id is distinct from old.client_id then
    raise exception 'A location stays with its client. Add a new one for another client.';
  end if;
  new.updated_at := now();
  new.updated_by := auth.uid();
  v_moved := tg_op = 'UPDATE' and (new.address, new.suburb, new.state, new.postcode)
                                is distinct from (old.address, old.suburb, old.state, old.postcode);
  if v_moved and old.approved then
    new.approved := false; -- a new address always needs approving again
  end if;
  if new.approved and tg_op = 'UPDATE' and old.approved then
    new.approved_at := old.approved_at; -- who approved it can't be rewritten
    new.approved_by := old.approved_by;
  elsif new.approved then
    new.approved_at := now();
    new.approved_by := auth.uid();
  else
    new.approved_at := null;
    new.approved_by := null;
  end if;
  -- The change is recorded by log_client_change (update 155), with field values.
  return new;
end;
$$;

CREATE OR REPLACE FUNCTION public.guard_client_record()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $$
begin
  if tg_op = 'INSERT' then
    new.client_ref := public.next_client_ref(); -- always made here, never chosen
    if new.status <> 'pending' and auth.uid() is not null and not public.can('clients.list', 'edit', new.id) then
      raise exception 'You can''t set a client''s status. Ask someone who manages clients.';
    end if;
    return new;
  end if;
  if new.client_ref is distinct from old.client_ref then
    raise exception 'A client''s reference never changes.';
  end if;
  if new.status is distinct from old.status then
    if auth.uid() is not null and not public.can('clients.list', 'edit', new.id) then
      raise exception 'You can''t change this client''s status. Ask someone who manages clients.';
    end if;
    new.status_changed_at := now();
    new.status_changed_by := auth.uid();
    -- Recorded by log_client_change (update 155), with the before and after status.
  end if;
  return new;
end;
$$;
commit;
