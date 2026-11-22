-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 169 (contracted hours). Safe to run again. Contracted hours are first copied to a locked
-- schema, undo_169_kept, that only the database owner can read; undo restores nothing by itself.
begin;
create schema if not exists undo_169_kept;
revoke all on schema undo_169_kept from public;
do $$ begin
  if to_regclass('public.staff_contract_hours') is not null then
    if to_regclass('undo_169_kept.staff_contract_hours') is null then
      create table undo_169_kept.staff_contract_hours as table public.staff_contract_hours;
    else
      insert into undo_169_kept.staff_contract_hours select * from public.staff_contract_hours p where not exists (select 1 from undo_169_kept.staff_contract_hours k where k.user_id = p.user_id and k.updated_at = p.updated_at);
    end if;
  end if;
end $$;
revoke all on all tables in schema undo_169_kept from public;
do $$ begin
  execute 'revoke all on schema undo_169_kept from anon, authenticated';
  execute 'revoke all on all tables in schema undo_169_kept from anon, authenticated';
exception when undefined_object then null;
end $$;
drop table if exists public.staff_contract_hours;
drop function if exists public.guard_contract_hours();
commit;
