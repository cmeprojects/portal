# cmeprojects: test the re-runnable install. Usage: inst.sh <mode> [K]
cd /home/user/portal
export PGHOST=/tmp/pgtest PGPORT=54329 PGUSER=postgres
S=/tmp/claude-0/-home-user/0e8c81c8-4ff7-548d-a193-f843c6a8d85a/scratchpad
q(){ psql -X -q -v ON_ERROR_STOP=1 -d "$1" -f "$2" >/dev/null 2>$S/err.txt || { echo "ERROR in $2: $(grep -m1 ERROR $S/err.txt)"; return 1; }; }
schema(){ pg_dump -s -d "$1" --schema=public | grep -v "^--\|^$\|install_log\|^SET \|^SELECT pg_catalog" | grep -v "^.restrict\|^.unrestrict" | sort | grep -v "^);$\|applied_at timestamp with time zone DEFAULT now() NOT NULL\|^    name text NOT NULL,$\|^ADD CONSTRAINT install_log\|^    ADD CONSTRAINT install_log_pkey\|^ALTER TABLE public.install_log"; }
mk(){ dropdb --if-exists $1; createdb $1; psql -X -q -d $1 -f supabase/tests/supabase_stub.sql >/dev/null 2>&1; }
# Reference: all migrations, in order.
if [ "$1" = ref ]; then mk ref_full; for f in supabase/migrations/*.sql; do q ref_full $f || exit 1; done; schema ref_full > $S/ref.schema; echo "ref $(wc -l < $S/ref.schema) lines"; exit; fi
if [ "$1" = empty ]; then mk t_empty; q t_empty supabase/install/fresh-install.sql && q t_empty supabase/install/fresh-install.sql && echo "empty: installed, and ran a second time OK"; schema t_empty > $S/t.schema; diff <(sed 's/[[:space:]]*$//' $S/ref.schema) <(sed 's/[[:space:]]*$//' $S/t.schema) | head -5; echo "diff lines: $(diff $S/ref.schema $S/t.schema | wc -l)"; dropdb t_empty; exit; fi
if [ "$1" = cut ]; then K=$2; mk t_cut; n=0; for f in supabase/migrations/*.sql; do n=$((n+1)); [ $n -le $K ] || break; q t_cut $f || exit 1; done
  if ! q t_cut supabase/install/fresh-install.sql; then grep -q "First run these two lines" $S/err.txt && echo "  (cut at $K: stopped with the two-line message, as designed; running them)" && psql -X -q -d t_cut -c "alter type public.app_role add value if not exists 'new_starter'" -c "alter type public.app_role add value if not exists 'external'" >/dev/null 2>&1 || exit 1; q t_cut supabase/install/fresh-install.sql || exit 1; fi
  q t_cut supabase/install/fresh-install.sql || exit 1
  schema t_cut > $S/t.schema; echo "cut at $K: OK, diff lines vs full: $(diff $S/ref.schema $S/t.schema | wc -l)"; dropdb t_cut; exit; fi
if [ "$1" = old ]; then mk t_old; q t_old "$2" || exit 1; q t_old supabase/install/fresh-install.sql && q t_old supabase/install/fresh-install.sql || exit 1
  schema t_old > $S/t.schema; echo "old install $(basename $2): OK, diff lines vs full: $(diff $S/ref.schema $S/t.schema | wc -l)"; diff $S/ref.schema $S/t.schema | head -6; dropdb t_old; exit; fi
