# cmeprojects evidence: INSERT attempts per table x 6 identities (each rolled back).
import json, subprocess
DB = "postgresql://postgres:postgres@127.0.0.1:54322/postgres"
def q(s): return subprocess.check_output(["psql", DB, "-qAtc", s]).decode().strip()
ids = dict(l.split("|") for l in q("select email, id from profiles where email in ('owner@example.com','boss@example.com','office@example.com','lead@example.com','sam@example.com')").split("\n"))
who = {"system admin": ids["owner@example.com"], "manager": ids["boss@example.com"], "staff admin": ids["office@example.com"],
       "team leader": ids["lead@example.com"], "staff": ids["sam@example.com"], "signed out": None}
tables = q("select string_agg(distinct tablename, ' ') from pg_policies where schemaname='public'").split()
# Columns we may set: not identity, not generated.
cols = {}
for l in q("select table_name||'|'||string_agg(column_name, ',' order by ordinal_position) from information_schema.columns where table_schema='public' and is_identity='NO' and is_generated='NEVER' group by table_name").split("\n"):
    t, c = l.split("|"); cols[t] = c.split(",")
pk = {}
for l in q("select c.relname||'|'||string_agg(a.attname||':'||format_type(a.atttypid,a.atttypmod), ',') from pg_index i join pg_class c on c.oid=i.indrelid join pg_namespace n on n.oid=c.relnamespace join pg_attribute a on a.attrelid=c.oid and a.attnum=any(i.indkey) where i.indisprimary and n.nspname='public' group by c.relname").split("\n"):
    t, c = l.split("|"); pk[t] = [x.split(":") for x in c.split(",")]
out = []; plan = []
for t in tables:
    samples = {"general": q(f"select to_jsonb(x) from public.{t} x order by md5(x::text) limit 1")}
    for w, uid in who.items():
        mine = q(f"select to_jsonb(x) from public.{t} x where to_jsonb(x)::text like '%{uid}%' order by md5(x::text) limit 1") if uid else ""
        # Constructed rows (cover empty tables too): every person/uuid field set to
        # the actor ("constructed own") or to someone else ("constructed other").
        uu = q(f"select coalesce(string_agg(column_name, ','), '') from information_schema.columns where table_schema='public' and table_name='{t}' and data_type='uuid'").split(",")
        other = "11111111-1111-4111-8111-111111111111"
        cons_own = json.dumps({c: (uid or other) for c in uu if c})
        cons_other = json.dumps({c: other for c in uu if c})
        for kind, js in (("general", samples["general"]), ("their own", mine), ("constructed own", cons_own), ("constructed other", cons_other)):
            if not js: continue
            row = json.loads(js)
            # A fresh primary key so it's a new row (uuid keys get a new uuid; identity keys are left to the database).
            for col, typ in pk.get(t, []):
                if typ == "uuid" and col in row: row[col] = "00000000-0000-4000-8000-" + format(abs(hash((t, w, kind))) % 10**12, "012d")
            c = ",".join(x for x in cols.get(t, []) if x in row) if not kind.startswith("constructed") else ",".join(cols.get(t, []))
            if not c: continue
            claims = json.dumps({"sub": uid, "role": "authenticated", "aal": "aal2"}) if uid else json.dumps({"role": "anon"})
            role = "authenticated" if uid else "anon"
            lit = json.dumps(row).replace("'", "''")
            out.append(f"\\echo INS|{w}|{t}|{kind}\nbegin; set local role {role}; select set_config('request.jwt.claims', '{claims}', true) is null;\n"
                       f"insert into public.{t} ({c}) select {c} from jsonb_populate_record(null::public.{t}, '{lit}'::jsonb);\nselect 'R|OK';\nrollback;")
            plan.append((w, t, kind))
open("insert.sql", "w").write("\n".join(out) + "\n")
print("insert attempts:", len(plan), "tables:", len(tables), "tables with no sample row:", sum(1 for t in tables if not q(f"select 1 from public.{t} limit 1")))
