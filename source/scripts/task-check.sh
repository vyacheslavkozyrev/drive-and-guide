#!/usr/bin/env bash
# Task-level check: runs build-all.sh under caffeinate, keeps the full log in a file
# and prints a short result. On failure it prints the tail of the log.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
mkdir -p "$root/.build"
log="$root/.build/task-check.log"

echo "==> task check (full log: $log)"
status=0
caffeinate -i "$root/source/scripts/build-all.sh" >"$log" 2>&1 || status=$?

if [ "$status" -eq 0 ]; then
  # XCTest and Swift Testing print their totals in different lines; the project uses both kinds.
  totals="$(grep -E 'Executed [0-9]+ tests?|Test run with [0-9]+ tests?' "$log" | tail -n 1 || true)"
  echo "PASS${totals:+: $totals}"
  exit 0
fi

echo "FAIL (exit $status). Last 40 lines of the log:"
tail -n 40 "$log"
exit "$status"
