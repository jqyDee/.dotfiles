#!/usr/bin/env bash
# Run every test_* function in tests/test_*.sh, each in its own sandbox.
#   tests/run.sh            all tests
#   tests/run.sh <pattern>  only tests whose name contains <pattern>
set -u

cd "$(dirname "$0")" || exit 1
# shellcheck source=tests/lib.sh
. ./lib.sh

pattern=${1:-}
out=$(mktemp)
total=0
failed=0

for file in test_*.sh; do
    while read -r t; do
        case "$t" in *"$pattern"*) ;; *) continue ;; esac
        total=$((total + 1))
        (
            set -euo pipefail
            sandbox
            # shellcheck disable=SC1090
            . "./$file"
            "$t"
        ) >"$out" 2>&1
        rc=$?
        if [ "$rc" -eq 0 ]; then
            echo "ok   $file $t"
        else
            echo "FAIL $file $t"
            sed 's/^/     /' "$out"
            failed=$((failed + 1))
        fi
    done < <(grep -oE '^test_[A-Za-z0-9_]+' "$file" | sort -u)
done

rm -f "$out"
echo "$((total - failed))/$total passed"
[ "$failed" -eq 0 ] && [ "$total" -gt 0 ]
