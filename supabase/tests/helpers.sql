-- Staff Portal · © cmeproject. All rights reserved.
--
-- Shared helpers for the security rule tests.

create schema test;
grant usage on schema test to anon, authenticated;

create function test.ok(cond boolean, msg text) returns void language plpgsql as $$
begin
  if cond is distinct from true then raise exception 'FAILED: %', msg; end if;
  raise notice 'ok - %', msg;
end $$;

-- Runs a statement and passes only if it is refused (error or no rows changed).
create function test.refused(stmt text, msg text) returns void language plpgsql as $$
declare n int;
begin
  begin
    execute stmt;
    get diagnostics n = row_count;
  exception when others then
    raise notice 'ok - % (refused: %)', msg, sqlerrm;
    return;
  end;
  if n > 0 then raise exception 'FAILED: % (statement was allowed)', msg; end if;
  raise notice 'ok - % (no rows changed)', msg;
end $$;

create function test.act_as(p_email text, p_aal text default 'aal2') returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', (select id from auth.users where email = p_email), 'aal', p_aal)::text,
    false);
end $$;

grant execute on all functions in schema test to anon, authenticated;

-- cmeprojects: the default Profile photo onboarding item is switched off here so
-- older tests keep counting the items they were written for (staff_photos covers it).
update public.compliance_items set active = false where sets_photo;

-- cmeprojects: Staff profiles are switched off here so older tests don't meet the
-- "Complete your profile" onboarding item (the profile tests switch it back on).
update public.features set enabled = false where key = 'hr_profiles';

-- cmeprojects: the default NDIS orientation training (update 58) is switched off
-- here too; onboarding_clearance covers it.
update public.compliance_items set active = false where title like 'NDIS Worker Orientation Module%';

-- cmeprojects (update 81): "onboarding complete" now includes bank, super,
-- right to work (checked) and the TFN form. Test people start with these
-- filled in, so older tests keep counting the checklist items they were
-- written for. The Stage B test (onboarding_stage_b) switches this off.
create or replace function test.fill_pay() returns trigger language plpgsql as $$
declare v_prev text := current_setting('session_replication_role');
begin
  perform set_config('session_replication_role', 'replica', true);
  insert into public.staff_bank (user_id, account_name, bsb, account_number) values (new.id, 'Test', '062-000', '12345678') on conflict do nothing;
  insert into public.staff_super (user_id, fund_name) values (new.id, 'Test Super') on conflict do nothing;
  insert into public.staff_tax (user_id, form_path, form_name) values (new.id, 'tax/' || new.id || '/form.pdf', 'form.pdf') on conflict do nothing;
  insert into public.staff_work_rights (user_id, status, verified_at) values (new.id, 'citizen', now()) on conflict do nothing;
  perform set_config('session_replication_role', v_prev, true);
  return new;
end $$;
drop trigger if exists test_fill_pay on public.profiles;
create trigger test_fill_pay after insert on public.profiles for each row execute function test.fill_pay();
