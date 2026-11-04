#!/bin/bash
# Deterministic gates for the swayu-app working tree. Writes a failure bundle
# and prints one verdict line: VERDICT PASS or VERDICT FAIL <step>.
# Run from inside swayu-app. Usage: verify.sh [--branch] [extra test files...]
#   default   checks what changed since the last commit (the fast inner loop)
#   --branch  checks everything the branch changed against main (before a pull request)
set -u
REPO=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Run this inside swayu-app."; exit 2; }
BUNDLE=/tmp/verify-bundle
cd "$REPO" || exit 2
rm -rf "$BUNDLE"; mkdir -p "$BUNDLE"
BASE=HEAD
if [ "${1:-}" = "--branch" ]; then BASE=$(git merge-base HEAD origin/main); shift; fi
CHANGED=$( { git diff --name-only "$BASE"; git ls-files --others --exclude-standard; } | sort -u | grep -v '^\.o[0-9]*-real-run/' )
TS=$(echo "$CHANGED" | grep -E '\.(ts|tsx)$' | while read -r f; do [ -f "$f" ] && echo "$f"; done)
# Tests: changed test files, tests that import a changed source module, and any named on the command line.
TESTS=$(echo "$TS" | grep -E '\.test\.tsx?$')
for f in $(echo "$TS" | grep -vE '\.test\.tsx?$'); do
  mod=$(basename "$f" | sed -E 's/\.tsx?$//')
  TESTS="$TESTS
$(grep -rlE "/${mod}(\.js)?['\"]" tests web/tests --include='*.ts' --include='*.tsx' 2>/dev/null)"
done
TESTS=$(printf '%s\n' $TESTS "$@" | grep -v '^$' | sort -u)
echo "$CHANGED" > "$BUNDLE/changed.txt"; echo "$TESTS" > "$BUNDLE/tests.txt"

fail() { echo "{\"verdict\":\"FAIL\",\"step\":\"$1\",\"log\":\"$BUNDLE/$1.log\"}" > "$BUNDLE/verdict.json"; tail -60 "$BUNDLE/$1.log"; echo "VERDICT FAIL $1"; exit 1; }

npx tsc --noEmit > "$BUNDLE/typecheck.log" 2>&1 || fail typecheck
if echo "$CHANGED" | grep -q '^web/'; then npx tsc -p web/tsconfig.json --noEmit >> "$BUNDLE/typecheck.log" 2>&1 || fail typecheck; fi
if [ -n "$TS" ]; then npx eslint $TS > "$BUNDLE/lint.log" 2>&1 || fail lint; fi
if echo "$CHANGED" | grep -qE '^(contracts|docs/product/contracts)/'; then pnpm -s contracts:check > "$BUNDLE/contracts.log" 2>&1 || fail contracts; fi
if [ -n "$TESTS" ]; then
  if ! npx vitest run $TESTS > "$BUNDLE/tests.log" 2>&1; then
    KNOWN=$(dirname "$0")/known-failures.txt; touch "$KNOWN"
    grep -E '^ FAIL ' "$BUNDLE/tests.log" | sed -E 's/^ FAIL +[^>]+> //; s/.* > //' | sort -u > "$BUNDLE/failed.txt"
    NEW=$(while read -r name; do grep -qF "$name|" "$KNOWN" || echo "$name"; done < "$BUNDLE/failed.txt")
    if [ -n "$NEW" ] || [ ! -s "$BUNDLE/failed.txt" ]; then echo "$NEW" > "$BUNDLE/new-failures.txt"; fail tests; fi
    echo "Known failures, not new:"; while read -r name; do grep -F "$name|" "$KNOWN" | sed 's/^/  /'; done < "$BUNDLE/failed.txt"
  fi
fi
grep -E 'Test Files|Tests ' "$BUNDLE/tests.log" 2>/dev/null
echo '{"verdict":"PASS"}' > "$BUNDLE/verdict.json"
echo "VERDICT PASS ($(echo "$TESTS" | grep -c . ) test files)"
