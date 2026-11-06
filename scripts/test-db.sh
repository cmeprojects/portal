#!/usr/bin/env bash
# Staff Portal · © cmeproject. All rights reserved.
#
# Tests the database security rules on throwaway local Postgres databases,
# one fresh database per test file. Needs a running Postgres you can reach
# with psql. Set PG* variables to point at it (for example PGHOST, PGPORT,
# PGUSER). Never point this at a real Supabase project.
set -euo pipefail

cd "$(dirname "$0")/.."

for test in supabase/tests/*.test.sql; do
  DB="portal_test_$$"
  createdb "$DB"
  trap 'dropdb --if-exists "$DB"' EXIT
  run() { psql -X -q -v ON_ERROR_STOP=1 -d "$DB" "$@"; }

  echo "== $(basename "$test")"
  run -f supabase/tests/supabase_stub.sql
  for f in supabase/migrations/*.sql; do
    run -f "$f"
  done
  run -o /dev/null -f supabase/companies/engaged-care.sql
  run -f supabase/tests/helpers.sql
  run -f "$test" 2>&1 | sed 's/^psql:[^ ]* NOTICE:  /  /'

  dropdb "$DB"
  trap - EXIT
done

# cmeprojects: the fresh install file is current, runs in one go (as Supabase's
# SQL Editor runs it), and with the cmeprojects company file holds nothing from any client.
echo "== fresh install"
expected=$(mktemp)
cp supabase/install/fresh-install.sql "$expected"
bash scripts/build-install.sh > /dev/null
if ! cmp -s "$expected" supabase/install/fresh-install.sql; then
  echo "FAILED: supabase/install/fresh-install.sql is out of date. Run scripts/build-install.sh and commit it."
  exit 1
fi
rm -f "$expected"
DB="portal_fresh_$$"
createdb "$DB"
trap 'dropdb --if-exists "$DB"' EXIT
psql -X -q -v ON_ERROR_STOP=1 -d "$DB" -f supabase/tests/supabase_stub.sql > /dev/null
psql -X -q -1 -v ON_ERROR_STOP=1 -d "$DB" -f supabase/install/fresh-install.sql > /dev/null 2>&1 \
  || { echo "FAILED: the fresh install doesn't run in one go"; exit 1; }
psql -X -q -v ON_ERROR_STOP=1 -d "$DB" -f supabase/companies/cmeprojects.sql > /dev/null
leftovers=$(psql -X -q -At -d "$DB" -c "select count(*) from (select to_jsonb(t)::text x from public.app_settings t union all select to_jsonb(r)::text from public.registries r union all select to_jsonb(o)::text from public.organisation o) s where x ilike '%engaged%' or x ilike '%derrimut%'")
[ "$leftovers" = "0" ] || { echo "FAILED: client wording in a fresh copy"; exit 1; }
dropdb "$DB"
trap - EXIT
echo "  ok - the fresh install is current, runs in one go and holds no client content"
