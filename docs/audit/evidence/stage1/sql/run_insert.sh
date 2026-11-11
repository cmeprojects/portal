DB=postgresql://postgres:postgres@127.0.0.1:54322/postgres
psql $DB -qAt -f $1 2>&1 | awk '/^INS\|/ {k=substr($0,5); next} /^R\|OK/ { if (k!="") {print k "|ALLOWED"; k=""}; next } /ERROR/ { if (k!="") { m=$0; sub(/.*ERROR: */,"",m); gsub(/"[^"]*"/,"\"…\"",m); gsub(/\([^)]*\)=\([^)]*\)/,"(…)",m); print k "|REFUSED: " m; k="" } }'
