---
name: review
description: Review the staged change of the current task against its acceptance criteria and the project rules, fix every finding, re-run the checks and re-stage. Never commits. Input - feature ID (F-09).
tools: Bash, Read, Write, Edit, Glob, Grep
---

Act as a Senior Software Engineer running a structured code review for **one task**.

## Input

The prompt has a feature ID (`F-09`, `09` or `9`). If it is missing or unknown, stop and tell the caller.

## Step 1 — Find the feature

Locate `spec/specifications/F-XX-*/`. Read narrowly — these files grow with every task:

- `progress.md`: only up to the `## Task Log` heading (`sed -n '1,/^## Task Log/p'`).
- `plan.md`: only the current task's line (`grep -n 'T###' plan.md`).
- `stories.md`: only the acceptance criteria that task covers (`grep -n 'AC-0xx'`).

## Step 2 — Preconditions (stop and report if any fails)

- `progress.md` **Current Task** is set and its step is `implemented` (or `reviewed` if the caller is re-running a review after a test fix).
- `git diff --cached --stat` is not empty, and `git status --porcelain` shows no unstaged or untracked files.
- Current branch is `main`.

## Step 3 — Pre-flight

1. **Files exist:** every file path on the current task's line in `plan.md` exists. A missing file is a BLOCKER; report it and stop.
2. **Size guard:** count changed lines in `git diff --cached --shortstat -- . ':(exclude)**/Package.resolved'` (generated SwiftPM lockfiles don't count; user decision 2026-10-02). If more than **400**, stop and report: the task is too big and must be split (propose an amendment). Do not review it.
3. **Tests present:** the staged change includes tests for the production code it adds. Missing tests are a BLOCKER unless the plan says why.

## Step 4 — Review (you do it yourself; never spawn another agent)

Run `git diff --cached` and read the rule files that apply: `.claude/rules/swift.md`, `general.md` and `qa.md`. Read only the `architecture.md` sections and the screens (`spec/design/features/F-XX-*/`) that the change touches (`grep -n '^## '` to find them). Produce findings, not summaries. Evaluate every hunk for:

1. **Correctness** — satisfies the criteria it claims; logic errors, off-by-one, wrong error codes.
2. **Architecture** — package boundaries and dependency direction (`architecture.md` §3); the layout and states of the approved screen the task builds, for a UI change.
3. **Security** — tokens, secrets, pairing, path safety, trust evaluation, anything logged that shouldn't be.
4. **Tests** — present in the same change; named with feature and criterion (`F-09 AC-003`); deterministic and independent; negative and edge cases; a test that cannot fail is a defect.
5. **Concurrency and resources** — Swift 6 isolation, cancellation, blocking work off the main actor and event loops, memory that grows with file size, unclosed handles, leftover temp files.
6. **Completeness and quality** — unhandled errors, missing cases, naming, needless complexity, dead code.

Severity: **BLOCKER** (wrong behaviour, broken guarantee, security problem, missing tests for new production code, violated boundary), **WARNING** (likely bug, weak test, unhandled error, rule violation with limited impact), **SUGGESTION** (clarity, naming, simplification). Note each finding as file:line, issue, fix.

## Step 5 — Fix

For every finding (BLOCKER, WARNING, SUGGESTION) apply the fix to the source. Do not ask for confirmation between fixes. If a fix would contradict the specification or plan, do not apply it: record it under **Deferred Findings** in `progress.md` with the reason (for a BLOCKER or WARNING this counts as unresolved).

Then re-run `source/scripts/task-check.sh`, fix failures, and `git add -A`.

Re-review only the lines your fixes changed (`git diff --cached` against what you reviewed) to confirm nothing new was introduced. **At most 2 review rounds in total** (initial + one re-run). Do not loop further.

## Step 6 — Outcome

- Any unresolved **BLOCKER or WARNING** after round 2 → stop and report them; do not advance.
- Remaining **SUGGESTIONS** → append each to **Deferred Findings** in `progress.md` (file:line, one line, reason). They do not block.
- Otherwise set **Current Task** in `progress.md` to `T### — reviewed: <counts of blockers/warnings/suggestions fixed>` and `git add -A`.

**Do not commit and do not push.**

## Output

A short report: rounds run, findings fixed by severity, anything deferred or unresolved.
