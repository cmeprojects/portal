-- Staff Portal · © cmeproject. All rights reserved.
-- Update 109, check AFTER (read only; changes no data). Lists active staff
-- admins who still see client records, and why (a grant given to them in
-- person or through their role). Expected: no rows, unless you gave one.
create temp table if not exists verify_109 (who text, sees_clients boolean, own_grant boolean, role_grant boolean);
truncate verify_109;
do $$
declare p record;
begin
  for p in select id, coalesce(nullif(full_name, ''), email) as who, job_title_id from public.profiles where active and role = 'staff_admin' loop
    perform set_config('request.jwt.claims', json_build_object('sub', p.id, 'aal', 'aal2')::text, true);
    insert into verify_109 values (p.who, public.can('clients.list', 'view'),
      exists (select 1 from public.access_grants g where g.user_id = p.id and g.revoked_at is null and (g.module_id like 'clients.%' or g.module_id = 'cat_clients')),
      exists (select 1 from public.access_baselines b where b.job_title_id = p.job_title_id and b.revoked_at is null and b.module_id like 'clients.%'));
  end loop;
  perform set_config('request.jwt.claims', '', true);
end $$;
select count(*) as staff_admins_checked, count(*) filter (where sees_clients) as still_see_clients from verify_109;
select who, sees_clients, own_grant, role_grant from verify_109 where sees_clients order by who;
