-- Staff Portal · © cmeproject. All rights reserved.
-- Update 63: the website Assistant can also search the whole internet
-- (new choices per audience) and skip blocked websites. Safe to run again.
-- Undo: undo-63.sql. Run update 62 first.
begin;
-- cmeprojects: the website Assistant can also search the whole internet.
-- For each audience (public, staff, managers) the system admin chooses:
--   documents       our documents only
--   web             listed websites only
--   both            our documents, then listed websites
--   docs_web        our documents, then the whole internet
--   docs_sites_web  our documents, then listed websites, then the whole internet
--   sites_web       listed websites, then the whole internet
--   internet        the whole internet only
-- Plus websites it must never use when searching the whole internet.

alter table public.assistant_settings add column if not exists blocked_sites text[] not null default '{}';

do $$
declare
  c text;
begin
  for c in
    select conname from pg_constraint
     where conrelid = 'public.assistant_settings'::regclass and contype = 'c'
       and pg_get_constraintdef(oid) like '%scope_public%'
  loop
    execute format('alter table public.assistant_settings drop constraint %I', c);
  end loop;
end;
$$;

alter table public.assistant_settings add constraint assistant_settings_scope_check check (
  scope_public in ('documents', 'web', 'both', 'docs_web', 'docs_sites_web', 'sites_web', 'internet')
  and scope_staff in ('documents', 'web', 'both', 'docs_web', 'docs_sites_web', 'sites_web', 'internet')
  and scope_managers in ('documents', 'web', 'both', 'docs_web', 'docs_sites_web', 'sites_web', 'internet')
  and cardinality(trusted_sites) <= 30
  and cardinality(suggestions) <= 8
  and cardinality(blocked_sites) <= 30
);
commit;
