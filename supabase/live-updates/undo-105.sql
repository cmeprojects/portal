-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 105: removes the parts of Clients and the three new roles,
-- only if nothing uses them yet (a role someone holds, or a part with grants,
-- is kept and reported). Safe to run again.
begin;
do $$
begin
  if exists (select 1 from public.access_baselines where module_id like 'clients.%' and module_id <> 'clients.list')
     or exists (select 1 from public.access_grants where module_id like 'clients.%' and module_id <> 'clients.list') then
    raise notice 'Client parts have grants; undo update 107 first. Parts kept.';
  else
    delete from public.function_group_modules where module_id like 'clients.%' and module_id <> 'clients.list';
    delete from public.app_modules where id in ('clients.details', 'clients.people', 'clients.locations', 'clients.alerts', 'clients.notes', 'clients.services', 'clients.assign');
  end if;
  delete from public.job_title_functions jf using public.job_titles t
   where jf.job_title_id = t.id and t.name in ('Case Manager', 'Intake & Assessment Officer', 'Payroll & Rostering')
     and not exists (select 1 from public.profiles p where p.job_title_id = t.id)
     and not exists (select 1 from public.access_baselines b where b.job_title_id = t.id);
  delete from public.job_titles t
   where t.name in ('Case Manager', 'Intake & Assessment Officer', 'Payroll & Rostering')
     and not exists (select 1 from public.profiles p where p.job_title_id = t.id)
     and not exists (select 1 from public.job_title_functions jf where jf.job_title_id = t.id)
     and not exists (select 1 from public.access_baselines b where b.job_title_id = t.id);
end $$;
commit;
