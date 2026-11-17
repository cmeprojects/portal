-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 93: removes the role-to-group links and puts the Stage 1 group
-- guard back (key never changes). Function groups and roles are untouched.
-- Safe to run again.
begin;
drop table if exists public.job_title_functions;
drop function if exists public.guard_job_title_function();
create or replace function public.guard_function_group()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and new.key is distinct from old.key then
    raise exception 'A function group''s key never changes. Rename it instead.';
  end if;
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end;
$$;
commit;
