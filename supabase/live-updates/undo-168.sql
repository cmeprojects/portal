-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 168 (document templates). Safe to run again. Templates and the record of which version
-- each document used are first copied to a locked schema, undo_168_kept, that only the database
-- owner can read; undo restores nothing by itself. Issued PDFs never change either way.
begin;
create schema if not exists undo_168_kept;
revoke all on schema undo_168_kept from public;
do $$
declare
  t text;
begin
  foreach t in array array['document_templates', 'document_issues'] loop
    if to_regclass('public.' || t) is not null then
      if to_regclass('undo_168_kept.' || t) is null then
        execute format('create table undo_168_kept.%I as table public.%I', t, t);
      else
        execute format('insert into undo_168_kept.%I select * from public.%I p where not exists (select 1 from undo_168_kept.%I k where k.id = p.id)', t, t, t);
      end if;
    end if;
  end loop;
end $$;
revoke all on all tables in schema undo_168_kept from public;
do $$ begin
  execute 'revoke all on schema undo_168_kept from anon, authenticated';
  execute 'revoke all on all tables in schema undo_168_kept from anon, authenticated';
exception when undefined_object then null;
end $$;
drop table if exists public.document_issues;
drop table if exists public.document_templates;
drop function if exists public.guard_document_template();
drop function if exists public.guard_document_issue();
commit;
