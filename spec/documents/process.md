# DriveAndGuide — Working Process

Status: adopted from the PhotoSync/Homeroll process, with a UX step for the screens of the iPhone app.

The process turns an idea into reviewed, tested, committed code, one small task at a time. The commands and agents live in `.claude/`; this document explains the rules they enforce.

## 1. Principles

1. **Humans decide, agents execute.** The user answers questions and approves stories, screens and plans; after that work runs on its own and stops when it cannot continue safely.
2. **Commit is the last step.** Code is committed only after it has been reviewed and tested. The cycle is **implement → review → test → commit**, for **one task** at a time.
3. **Every commit is green.** The repository builds and all its tests pass after every commit.
4. **Tests travel with the code.** A task includes the tests for its own code.
5. **Everything is traceable.** Feature → stories → acceptance criteria → screens → tasks → tests → commits.

## 2. The lifecycle

```
 idea.md ──▶ features.md ──▶ architecture.md          (documents, discussed with you)
                 │
                 ▼        per feature F-XX
 research (optional) ─▶ specify ─▶ ux ─▶ plan ─▶ [implement ─▶ review ─▶ test ─▶ commit]* ─▶ verify ─▶ complete
                          │         │      │
                     you approve  you    you approve
                     the stories  approve the plan
                                  the screens
```

The **UX** step is marked ➖ Not needed in `progress.md`, and skipped, for a feature with no user interface (an enabler feature with no screen, such as the project foundation).

## 3. Where things live

| What | Where |
|---|---|
| Project documents | `spec/documents/` |
| Feature list | `spec/documents/features.md` |
| One folder per feature | `spec/specifications/F-XX-<slug>/` |
| UX screens per feature (SVG) | `spec/design/features/F-XX-<slug>/` |
| Spec template | `spec/specifications/F-00-template/` |
| Commands, agents, rules | `.claude/` |
| Project instructions for Claude | `CLAUDE.md` |
| Production code | `source/` |
| Build and check scripts | `source/scripts/` |

Files in a feature's spec folder:

| File | Purpose |
|---|---|
| `research.md` | Optional. Findings for the feature's technical unknowns. |
| `stories.md` | User stories, acceptance criteria (`[auto]` or `[device]`), out of scope, coverage of the feature's Done-when statements. |
| `plan.md` | Ordered tasks (`T001`…), each with layer tag, files, and the criteria it covers. |
| `progress.md` | Phase status, task in flight, task log, deferred findings, test results, amendments. |
| `device-checklist.md` | Written in verify mode, for the `[device]` criteria. |

Files in a feature's design folder (`spec/design/features/F-XX-<slug>/`): one SVG per screen (`NN-<screen>.svg`), `index.html` showing all screens in order, and `screens.md` with the screen table, the legend, the review findings and the open points.

## 4. The commands

Defined in `.claude/commands/`; automated steps run as agents from `.claude/agents/` with a fresh context each.

| Command | What it does | You are asked |
|---|---|---|
| `/research [F-XX [topic]]` | Optional. No argument audits the feature list; with a feature, investigates unknowns into `research.md`; with `F-02 S#`, runs a spike | A few questions |
| `/specify F-XX` | Clarifies gaps, writes `stories.md`, checks coverage of the Done-when statements, commits the spec | Questions; **approve the stories** |
| `/ux F-XX` | Draws the screens as SVG, runs the `usability` and `visual` reviews, checks that every UI criterion has a screen, commits the screens | **Approve the screens** |
| `/plan F-XX` | Writes `plan.md`, checks every criterion is covered, commits the plan | **Approve the plan** |
| `/implement F-XX [T###]` | Implements one task and its tests, stages the change | — |
| `/review F-XX` | Reviews the staged diff, fixes findings (max 2 rounds) | — |
| `/test F-XX [verify]` | Task mode: runs `source/scripts/task-check.sh`. Verify mode: criteria matrix and device checklist | Device results |
| `/commit F-XX` | Bookkeeping in `progress.md`, then one commit for the task | — |
| `/pipeline F-XX [research]` | Runs everything above for a feature, resumable | Only at pause points |

The scripts: `source/scripts/build-all.sh` formats, builds and tests every package under `source/Packages/`; it fails when there are no packages. `source/scripts/task-check.sh` runs it under `caffeinate`, keeps the full log in `.build/task-check.log` and prints a short result. The first feature that adds a Swift package creates the first package; an app target (xcodebuild) is added to the script by the feature that adds the first app target.

## 5. Rules of engagement

- **Branching:** work directly on `main`; no feature branches.
- **Remote:** `origin` is `https://github.com/vyacheslavkozyrev/drive-and-guide`. Nothing is pushed unless the user asks.
- **Task size:** about 50–200 changed lines, one clear purpose. A task over 400 lines must be split.
- **Commit messages** start with the feature ID: `feat(F-01): T001 …`, `spec(F-01): …`, `design(F-01): …`, `plan(F-01): …`. Project-level commits start with `docs:`.
- **Never** push, force, amend, or rewrite history without being asked. Never commit around a failed review or test.
- **Dependencies:** a feature starts only when the features it depends on are complete.
- **Screens before code:** a feature with a user interface is not planned or built before its screens are approved.

## 6. The task cycle

| Step | Outcome | If it fails |
|---|---|---|
| **Implement** | Code and tests written; format, build and tests pass; task ticked in `plan.md` | Fix and retry up to 3 times, then stop |
| **Review** | Findings (BLOCKER / WARNING / SUGGESTION) fixed; checks re-run | Unresolved BLOCKER or WARNING after 2 rounds stops the work |
| **Test** | Build and full tests of changed packages and dependants pass | Back to implement for the same task; max 2 fix cycles |
| **Commit** | One commit; `progress.md` updated in the same commit | A failed preflight stops it |

## 7. Feature-level verification

After the last task is committed: check that every `[auto]` criterion is covered by a passing test whose name contains `F-XX AC-###`, and run the manual checklist for `[device]` criteria. A gap becomes new tasks appended to `plan.md`, recorded as an amendment in `progress.md`.

## 8. Stop conditions

Work stops, leaves the tree as it is, and says how to resume when: a preflight check or dependency fails; the plan turns out to be wrong; an approved screen and the stories disagree; review leaves a BLOCKER or WARNING after 2 rounds; tests keep failing after 2 fix cycles; a required tool is missing; a task diff is over 400 lines; or an approval is declined.

## 9. Resuming

State lives in `progress.md` (phase table, **Current Task** with the step reached) and `plan.md` (ticked tasks). A task in flight resumes at its next step; otherwise the next unchecked task starts.

## 10. Open decisions

1. The backend (.NET, `architecture.md` §4) needs its own rule file when the first backend feature is specified.
2. Xcode is needed for app targets. The script that runs the checks does not cover them until the first app target feature extends it.
