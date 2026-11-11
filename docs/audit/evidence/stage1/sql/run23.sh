DB=postgresql://postgres:postgres@127.0.0.1:54322/postgres
psql $DB -qAt -f $1 2>&1 | awk '/\|(SELECT|UPDATE|DELETE)$/ {k=$0; next} /^R\|/ {print k "|" substr($0,3); k=""; next} /ERROR/ { if (k!="") {sub(/.*ERROR: */,""); print k "|ERROR " $0; k=""} }'
