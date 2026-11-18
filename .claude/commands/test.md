---
description: Run the checks and tests for the current task, or with `verify` check every acceptance criterion of the whole feature and run the device checklist.
argument-hint: F-XX [verify]
---

Arguments: `$ARGUMENTS` — a feature ID (`F-09`, `09` or `9`) and an optional word `verify`. If the feature is missing, stop and tell the user a valid feature ID is required.

## Task mode (default)

No agent. Run `source/scripts/task-check.sh` (it runs `build-all.sh` under `caffeinate` and prints a short result; full log in a file). On PASS set **Current Task** in `progress.md` to `T### — tested: <totals>`; `/commit` is next. On FAIL show the printed tail and stop.

## Verify mode (`/test F-XX verify`)

Used after every task of the feature is committed. Spawn the `test` agent (`.claude/agents/test.md`) with the arguments as the prompt and surface its output. The agent checks that every `[auto]` acceptance criterion is covered by a passing test and writes `device-checklist.md` for the `[device]` criteria.

If the agent reports that a device checklist is waiting:

1. Show the user the checklist steps for each criterion.
2. Ask the user, one criterion at a time if needed, for the result: passed, failed (with what happened), or not run yet.
3. Record the answers under **Test Results** in `progress.md`, tick the criteria in `device-checklist.md`, and stop if anything failed or was not run: the feature is not complete until every `[device]` criterion is confirmed.

If the agent reports gaps (a criterion with no test) or failures, surface them and stop; do not mark Verify complete.
