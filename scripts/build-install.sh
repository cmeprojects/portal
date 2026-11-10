#!/usr/bin/env bash
# Staff Portal · © cmeproject. All rights reserved.
#
# cmeprojects: builds supabase/install/fresh-install.sql (install or update,
# safe to run again) from the migrations. Run this after adding a migration,
# then commit the result. The work is done by build-install.py.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 scripts/build-install.py
