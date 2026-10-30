-- Staff Portal · © cmeproject. All rights reserved.
-- One-off: delete every entry of the Fluid intake feature (test data).
-- Keeps the feature itself: its questions, targets, alerts and settings.
-- This can't be undone. Safe to run again (the second time there's nothing
-- left to delete).
begin;

do $$
declare
  v_features text;
  v_count int;
begin
  select string_agg(name || ' (/f/' || slug || ')', ', '), count(*) into v_features, v_count
    from public.custom_features where lower(trim(name)) = 'fluid intake';
  if v_count = 0 then
    raise notice 'No feature called Fluid intake was found. Nothing deleted.';
    return;
  end if;

  delete from public.custom_entries
   where feature_id in (select id from public.custom_features where lower(trim(name)) = 'fluid intake');
  get diagnostics v_count = row_count;

  -- Its alerts in people's bells go too.
  delete from public.notifications
   where kind = 'feature_alert'
     and href in (select '/f/' || slug from public.custom_features where lower(trim(name)) = 'fluid intake');

  perform public.write_audit('custom_entries_cleared', 'custom_feature', null,
    jsonb_build_object('features', v_features, 'entries_deleted', v_count, 'why', 'Test data cleared'));
  raise notice 'Deleted % Fluid intake entries from %.', v_count, v_features;
end;
$$;

commit;
