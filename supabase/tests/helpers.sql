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
