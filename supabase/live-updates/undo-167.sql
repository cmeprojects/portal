-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 167 (service codes). Safe to run again. The codes, Support at Home service types and the
-- prefix setting are first copied to a locked schema, undo_167_kept, that only the database owner can
-- read; undo restores nothing by itself. Statements already issued keep the codes printed on them.
begin;
create schema if not exists undo_167_kept;
revoke all on schema undo_167_kept from public;
do $$ begin
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'service_catalogue' and column_name = 'code') then
    create table if not exists undo_167_kept.service_codes (service_id uuid, name text, code text, sah_service_type text, kept_at timestamptz);
    insert into undo_167_kept.service_codes select id, name, code, sah_service_type, now() from public.service_catalogue;
  end if;
  create table if not exists undo_167_kept.settings as select * from public.app_settings where false;
  insert into undo_167_kept.settings select * from public.app_settings s where s.key = 'billing.service_code_prefix' and not exists (select 1 from undo_167_kept.settings k where k.key = s.key);
end $$;
revoke all on all tables in schema undo_167_kept from public;
do $$ begin
  execute 'revoke all on schema undo_167_kept from anon, authenticated';
  execute 'revoke all on all tables in schema undo_167_kept from anon, authenticated';
exception when undefined_object then null;
end $$;
drop policy if exists "billing sets the service code prefix" on public.app_settings;
drop trigger if exists guard_statement_ids on public.client_statements;
drop trigger if exists guard_statement_zcodes on public.client_statements;
drop trigger if exists guard_service_code on public.service_catalogue;
drop view if exists public.services_not_priced;
drop function if exists public.statement_add_codes();
drop function if exists public.statement_add_detail_ids();
drop function if exists public.guard_service_code();
drop function if exists public.service_code_next();
drop function if exists public.service_billed(uuid);
drop index if exists public.service_catalogue_code_unique;
alter table public.service_catalogue drop constraint if exists service_catalogue_code_format;
alter table public.service_catalogue drop constraint if exists service_catalogue_sah_type_length;
alter table public.service_catalogue drop column if exists code;
alter table public.service_catalogue drop column if exists sah_service_type;
delete from public.app_settings where key = 'billing.service_code_prefix';
commit;
