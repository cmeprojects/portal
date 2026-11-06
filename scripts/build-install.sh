#!/usr/bin/env bash
# Staff Portal · © cmeproject. All rights reserved.
#
# cmeprojects: builds supabase/install/fresh-install.sql, the whole database
# for a NEW copy (a new client, Demo or Development), from the migrations in
# order. No company content is included: run a company file afterwards (or use
# the setup wizard). Run this after adding a migration, then commit the result.
set -euo pipefail
cd "$(dirname "$0")/.."
out=supabase/install/fresh-install.sql
latest=$(ls supabase/migrations/*.sql | tail -1 | xargs basename)
{
  echo "-- Staff Portal · © cmeproject. All rights reserved."
  echo "--"
  echo "-- FRESH INSTALL for a brand-new, empty Supabase project ONLY."
  echo "-- Never run this on a copy that's already in use (use the live updates instead)."
  echo "-- Built from every migration up to: $latest"
  echo "-- After it: run a company file (supabase/companies/...), then sign in:"
  echo "-- the first person to sign in becomes the system admin."
  echo
  for f in supabase/migrations/*.sql; do
    echo
    echo "-- ===================================================================="
    echo "-- $(basename "$f")"
    echo "-- ===================================================================="
    # Supabase runs a pasted script as one transaction, where a new access
    # level can't be used straight after it's added. So the full list is
    # created at the start, and the later "add value" lines are left out.
    # Old example wording that named a client is made neutral (cmeprojects).
    sed -e "s/^  'support_worker',\$/  'new_starter',\n  'support_worker',/" \
        -e "s/^  'system_admin'\$/  'system_admin',\n  'external'/" \
        -e "s/^alter type public.app_role add value if not exists .*/-- (access level already in the list above)/" \
        -e "s/Starting colours for Engaged Care's risk register/Starting colours for a risk register, if there is one/" \
        -e "s|for example https://engagedcare.com.au|for example https://yourcompany.com.au|" \
        -e "s/for example: Engaged Care Melbourne | NDIS support services/for example: Your Company | NDIS support services in your area/" "$f"
  done
} > "$out"
echo "Wrote $out ($(wc -c < "$out") bytes, from $(ls supabase/migrations/*.sql | wc -l) migrations)"
