-- Staff Portal · © cmeproject. All rights reserved.
--
-- Deleting registers (cmeprojects): only a register that has never been used
-- (no tasks, no items) can be deleted, by the system admin or people given
-- "Adding registers". A register that's been used is turned off instead (its
-- history stays, for audits). General tasks can't be deleted.

create or replace function public.delete_unused_registry(p_registry_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.registries;
begin
  if not public.can_admin_area('registers') then
    raise exception 'Only people the system admin chose can delete registers.';
  end if;
  select * into r from public.registries where id = p_registry_id;
  if r.id is null then
    raise exception 'That register doesn''t exist.';
  end if;
  if r.is_default then
    raise exception 'General tasks can''t be deleted.';
  end if;
  if exists (select 1 from public.tasks where registry_id = r.id) or exists (select 1 from public.records where registry_id = r.id) then
    raise exception '% has been used, so it can''t be deleted. Turn it off instead: its history is kept.', r.name;
  end if;
  delete from public.registries where id = r.id;
  perform public.write_audit('register_deleted', 'registry', r.id::text, jsonb_build_object('name', r.name, 'prefix', r.prefix));
end;
$$;

revoke execute on function public.delete_unused_registry(uuid) from public, anon;
grant execute on function public.delete_unused_registry(uuid) to authenticated;
