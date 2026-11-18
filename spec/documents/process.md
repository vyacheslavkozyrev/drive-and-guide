# DriveAndGuide — Working Process

Status: template. Adjust to taste; the rules below are a starting point.

The process turns an idea into reviewed, tested, committed code, one small task at a time. Commands and agents (when added) live in `.claude/`; this document explains the rules they enforce.

## 1. Principles

1. **Humans decide, agents execute.** The user answers questions and approves stories and plans; after that work runs on its own and stops when it cannot continue safely.
2. **Commit is the last step.** Code is committed only after it has been reviewed and tested. The cycle is **implement → review → test → commit**, for **one task** at a time.
3. **Every commit is green.** The repository builds and all its tests pass after every commit.
4. **Tests travel with the code.** A task includes the tests for its own code.
5. **Everything is traceable.** Requirement → feature → stories → acceptance criteria → tasks → tests → commits.

## 2. The lifecycle

```
 idea.md ──▶ features.md ──▶ architecture.md          (documents, discussed with you)
                 │
                 ▼        per feature F-XX
 research (optional) ─▶ specify ─▶ plan ─▶ [implement ─▶ review ─▶ test ─▶ commit]* ─▶ verify
                          │          │
                     you approve  you approve
```

## 3. Where things live

| What | Where |
|---|---|
| Project documents | `spec/documents/` |
| Feature list | `spec/documents/features.md` |
| One folder per feature | `spec/specifications/F-XX-<slug>/` |
| Spec template | `spec/specifications/F-00-template/` |
| Rules and (later) commands, agents | `.claude/` |
| Project instructions for Claude | `CLAUDE.md` |
| Production code | `source/` |

Files in a feature folder:

| File | Purpose |
|---|---|
| `research.md` | Optional. Findings for the feature's technical unknowns. |
| `stories.md` | User stories, acceptance criteria (`[auto]` or `[device]`), out of scope, requirement coverage. |
| `plan.md` | Ordered tasks (`T001`…), each with layer tag, files, and the criteria it covers. |
| `progress.md` | Phase status, task in flight, task log, deferred findings, test results, amendments. |

## 4. The commands

Defined in `.claude/commands/`; automated steps run as agents from `.claude/agents/` with a fresh context each.

| Command | What it does | You are asked |
|---|---|---|
| `/research [F-XX [topic]]` | Optional. No argument audits the feature list; with a feature, investigates unknowns into `research.md`; with `F-02 S#`, runs a spike | A few questions |
| `/specify F-XX` | Clarifies gaps, writes `stories.md`, checks requirement coverage, commits the spec | Questions; **approve the stories** |
| `/plan F-XX` | Writes `plan.md`, checks every criterion is covered, commits the plan | **Approve the plan** |
| `/implement F-XX [T###]` | Implements one task and its tests, stages the change | — |
| `/review F-XX` | Reviews the staged diff, fixes findings (max 2 rounds) | — |
| `/test F-XX [verify]` | Task mode: runs `source/scripts/task-check.sh`. Verify mode: criteria matrix and device checklist | Device results |
| `/commit F-XX` | Bookkeeping in `progress.md`, then one commit for the task | — |
| `/pipeline F-XX [research]` | Runs everything above for a feature, resumable | Only at pause points |

Needs, once F-01 creates them: `source/scripts/build-all.sh` (format, build and test everything) and `source/scripts/task-check.sh` (wraps it for the test step).

## 5. Rules of engagement

- **Branching:** work directly on `main`; no feature branches, no remote (the copied commands enforce this, and need `git init` first).
- **Task size:** about 50–200 changed lines, one clear purpose. A task over 400 lines must be split.
- **Commit messages** start with the feature ID: `feat(F-01): T001 …`, `spec(F-01): …`, `plan(F-01): …`, `docs: …`.
- **Never** push, force, amend, or rewrite history without being asked. Never commit around a failed review or test.
- **Dependencies:** a feature starts only when the features it depends on are complete.

## 6. The task cycle

| Step | Outcome | If it fails |
|---|---|---|
| **Implement** | Code and tests written; format, build and tests pass; task ticked in `plan.md` | Fix and retry up to 3 times, then stop |
| **Review** | Findings (BLOCKER / WARNING / SUGGESTION) fixed; checks re-run | Unresolved BLOCKER or WARNING after 2 rounds stops the work |
| **Test** | Build and full tests of changed modules and dependants pass | Back to implement for the same task; max 2 fix cycles |
| **Commit** | One commit; `progress.md` updated in the same commit | A failed preflight stops it |

## 7. Feature-level verification

After the last task is committed: check that every `[auto]` criterion is covered by a passing test whose name contains `F-XX AC-###`, and run the manual checklist for `[device]` criteria. A gap becomes new tasks appended to `plan.md`, recorded as an amendment in `progress.md`.

## 8. Stop conditions

Work stops, leaves the tree as it is, and says how to resume when: a preflight check or dependency fails; the plan turns out to be wrong; review leaves a BLOCKER or WARNING after 2 rounds; tests keep failing after 2 fix cycles; a required tool is missing; a task diff is over 400 lines; or an approval is declined.

## 9. Resuming

State lives in `progress.md` (phase table, **Current Task** with the step reached) and `plan.md` (ticked tasks). A task in flight resumes at its next step; otherwise the next unchecked task starts.

## 10. Open decisions

1. Which of `server.md` / `client.md` apply to this project (see the note at the top of each).
2. The `source/scripts/` build and check scripts, created in the foundation feature.
