#!/usr/bin/env bash
# Staff Portal · © cmeproject. All rights reserved.
#
# Tests the database security rules on a throwaway local Postgres database.
# Needs a running Postgres you can reach with psql. Set PG* variables to
# point at it (for example PGHOST, PGPORT, PGUSER). Never point this at a
# real Supabase project.
set -euo pipefail

cd "$(dirname "$0")/.."
DB="portal_test_$$"

createdb "$DB"
trap 'dropdb --if-exists "$DB"' EXIT

run() { psql -X -q -v ON_ERROR_STOP=1 -d "$DB" "$@"; }

run -f supabase/tests/supabase_stub.sql
for f in supabase/migrations/*.sql; do
  run -f "$f"
done
run -f supabase/companies/engaged-care.sql
run -f supabase/tests/foundations.test.sql 2>&1 | sed 's/^psql:[^ ]* NOTICE:  /  /'
