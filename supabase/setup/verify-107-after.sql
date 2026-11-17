-- Staff Portal · © cmeproject. All rights reserved.
-- Update 107, check AFTER (read only; changes no data). Compares who sees and
-- changes every client under the old rule (managers, staff admins and the
-- system admin) with the new permission check, for Clients and each part.
-- People with one of the new roles (Case Manager, Intake & Assessment
-- Officer) are listed separately: their access is new by design.
-- Expected: one row, changed = 0.
create temp table if not exists verify_107 (who text, role text, title text, part text, old_rule boolean, new_rule boolean);
truncate verify_107;
do $$
declare p record; m text; a text;
begin
  for p in select pr.id, coalesce(nullif(pr.full_name, ''), pr.email) as who, pr.role, coalesce(t.name, '') as title
             from public.profiles pr left join public.job_titles t on t.id = pr.job_title_id
            where pr.active and pr.role <> 'system_admin' loop
    perform set_config('request.jwt.claims', json_build_object('sub', p.id, 'aal', 'aal2')::text, true);
    foreach m in array array['clients.list', 'clients.details', 'clients.people', 'clients.locations', 'clients.alerts', 'clients.notes', 'clients.services'] loop
      foreach a in array array['view', 'edit'] loop
        insert into verify_107 values (p.who, p.role::text, p.title, m || ' ' || a, p.role in ('manager', 'staff_admin'),
          public.can(m, a, '00000000-0000-0000-0000-000000000000'::uuid));
      end loop;
    end loop;
  end loop;
  perform set_config('request.jwt.claims', '', true);
end $$;
select count(*) filter (where old_rule is distinct from new_rule and title not in ('Case Manager', 'Intake & Assessment Officer')) as changed,
       count(distinct who) as people_checked,
       count(distinct who) filter (where title in ('Case Manager', 'Intake & Assessment Officer')) as people_in_new_client_roles
  from verify_107;
select who, role, title, part, old_rule, new_rule from verify_107
 where old_rule is distinct from new_rule and title not in ('Case Manager', 'Intake & Assessment Officer') order by who, part;
