#!/usr/bin/env python3
# Staff Portal · © cmeproject. All rights reserved.
#
# cmeprojects: builds supabase/install/fresh-install.sql from the migrations,
# SAFE TO RUN AGAIN on any copy:
#   * a brand-new, empty project gets everything;
#   * a copy that's already set up (by an earlier install or the live updates)
#     gets only what's missing. Each part is recorded in public.install_log;
#     for a copy set up before that record existed, the install works out how
#     far it got from objects each part creates, and starts after that.
import re, sys, pathlib

root = pathlib.Path(__file__).resolve().parent.parent
migs = sorted((root / "supabase/migrations").glob("*.sql"))

def tidy(text: str) -> str:
    # Supabase runs a pasted script as one transaction, where a new access level
    # can't be used straight after it's added: the full list is created at the
    # start, and the later "add value" lines are left out. Old example wording
    # that named a client is made neutral.
    text = re.sub(r"^  'support_worker',$", "  'new_starter',\n  'support_worker',", text, flags=re.M)
    text = re.sub(r"^  'system_admin'$", "  'system_admin',\n  'external'", text, flags=re.M)
    text = re.sub(r"^alter type public\.app_role add value if not exists .*$", "-- (access level already in the list above)", text, flags=re.M)
    text = text.replace("Starting colours for Engaged Care's risk register", "Starting colours for a risk register, if there is one")
    text = text.replace("for example https://engagedcare.com.au", "for example https://yourcompany.com.au")
    text = text.replace("for example: Engaged Care Melbourne | NDIS support services", "for example: Your Company | NDIS support services in your area")
    return text

# Markers: objects a part creates for the first time (tables, new functions,
# new columns). Used only to work out how far an older copy got.
seen = set()
markers = []
for f in migs:
    t = f.read_text()
    found = []
    for m in re.finditer(r"create table (?:if not exists )?public\.(\w+)", t, re.I):
        k = ("t", m.group(1))
        if k not in seen: found.append(k)
    for m in re.finditer(r"create function public\.(\w+)", t, re.I):
        k = ("f", m.group(1))
        if k not in seen: found.append(k)
    for m in re.finditer(r"alter table (?:only )?public\.(\w+)\s+add column (?:if not exists )?(\w+)", t, re.I):
        k = ("c", m.group(1) + "." + m.group(2))
        if k not in seen: found.append(k)
    uniq = []
    for k in found:
        if k not in uniq: uniq.append(k)
    seen.update(uniq)
    markers.append(uniq[:4])

def check(k):
    kind, name = k
    if kind == "t": return f"to_regclass('public.{name}') is not null"
    if kind == "f": return f"exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = '{name}')"
    tbl, col = name.split(".")
    return f"exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = '{tbl}' and column_name = '{col}')"

out = []
w = out.append
w("-- Staff Portal · © cmeproject. All rights reserved.")
w("--")
w("-- INSTALL OR UPDATE (cmeprojects). Safe to run again, on any copy:")
w("--   * a brand-new, empty Supabase project: sets up everything;")
w("--   * a copy that's already in use: adds only what's missing (each part is")
w("--     recorded in public.install_log and skipped next time).")
w(f"-- Built from every migration up to: {migs[-1].name}")
w("-- New copy afterwards: run a company file (supabase/companies/...), then")
w("-- sign in: the first person to sign in becomes the system admin.")
w("")
w("create table if not exists public.install_log (")
w("  name       text primary key,")
w("  applied_at timestamptz not null default now()")
w(");")
w("alter table public.install_log enable row level security;")
w("revoke all on public.install_log from anon, authenticated;")
w("")
w("-- Older copies first need two access levels added on their own (Supabase runs")
w("-- a pasted script as one transaction, where a new access level can't be used")
w("-- straight away). Stops with the two lines to run if they're missing.")
w("do $roles$")
w("begin")
w("  if to_regtype('public.app_role') is not null and (")
w("       not exists (select 1 from pg_enum where enumtypid = to_regtype('public.app_role') and enumlabel = 'new_starter')")
w("    or not exists (select 1 from pg_enum where enumtypid = to_regtype('public.app_role') and enumlabel = 'external')) then")
w("    raise exception 'First run these two lines on their own (new query, Run), then run this file again:  alter type public.app_role add value if not exists ''new_starter'';  alter type public.app_role add value if not exists ''external'';';")
w("  end if;")
w("end;")
w("$roles$;")
w("")
w("-- A copy set up before the log existed: work out how far it got (the newest")
w("-- part whose objects are there) and record everything up to it.")
w("do $baseline$")
w("declare")
w("  v_upto int := 0;")
w("begin")
w("  if exists (select 1 from public.install_log) or to_regclass('public.profiles') is null then")
w("    return;")
w("  end if;")
for i in range(len(migs) - 1, -1, -1):
    if not markers[i]:
        continue
    cond = " and ".join(check(k) for k in markers[i])
    w(f"  if v_upto = 0 and {cond} then v_upto := {i + 1}; end if;")
w("  insert into public.install_log (name)")
w("  select x.name from (values")
w(",\n".join(f"    ({i + 1}, '{f.name}')" for i, f in enumerate(migs)))
w("  ) as x(n, name) where x.n <= v_upto")
w("  on conflict do nothing;")
w("end;")
w("$baseline$;")
for i, f in enumerate(migs):
    tag = f"$m{i + 1:03d}$"
    body = tidy(f.read_text())
    assert tag not in body
    w("")
    w("-- ====================================================================")
    w(f"-- {f.name}")
    w("-- ====================================================================")
    w("do $part$")
    w("begin")
    w(f"  if exists (select 1 from public.install_log where name = '{f.name}') then")
    w("    return;")
    w("  end if;")
    w(f"  execute {tag}")
    w(body)
    w(f"{tag};")
    w(f"  insert into public.install_log (name) values ('{f.name}');")
    w("end;")
    w("$part$;")
dest = root / "supabase/install/fresh-install.sql"
dest.write_text("\n".join(out) + "\n")
print(f"Wrote {dest.relative_to(root)} ({dest.stat().st_size} bytes, from {len(migs)} migrations); markers for {sum(1 for m in markers if m)} parts")
