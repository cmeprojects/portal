-- cmeprojects evidence: everything security-related except policy conditions, plus policy conditions separately.
\pset footer off
select 'TABLE|' || c.relname || '|rls=' || c.relrowsecurity || '|force=' || c.relforcerowsecurity || '|acl=' || coalesce(c.relacl::text,'')
  from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind in ('r','v','m') order by 1;
select 'FUNC|' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')|definer=' || p.prosecdef || '|vol=' || p.provolatile::text || '|cfg=' || coalesce(array_to_string(p.proconfig, ','),'') || '|owner=' || pg_get_userbyid(p.proowner) || '|acl=' || coalesce(p.proacl::text,'') || '|body=' || md5(p.prosrc)
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' order by 1;
select 'TRIG|' || c.relname || '|' || t.tgname || '|' || md5(pg_get_triggerdef(t.oid)) || '|enabled=' || t.tgenabled::text
  from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and not t.tgisinternal order by 1;
select 'POLICYMETA|' || tablename || '|' || policyname || '|' || cmd || '|' || permissive || '|' || array_to_string(roles, ',') from pg_policies where schemaname='public' order by 1;
select 'POLICYCOND|' || tablename || '|' || policyname || '|' || md5(coalesce(qual,'') || '#' || coalesce(with_check,'')) from pg_policies where schemaname='public' order by 1;
select 'SCHEMA|' || nspname || '|' || coalesce(nspacl::text,'') from pg_namespace where nspname in ('public','auth','storage') order by 1;
