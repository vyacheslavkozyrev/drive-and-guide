# DriveAndGuide — Claude Code

DriveAndGuide is an iPhone app for long road trips: the driver sets a destination and a driving limit (e.g. 4 h), the app plans interest-based rest stops, and an AI voice narrates facts about places near the route. MVP is iOS only.

Tech stack (same as PhotoSync/Homeroll): Swift 6 with strict concurrency, SwiftUI, Swift packages for all logic with thin app targets, Swift Testing. Details in `spec/documents/architecture.md` §4.

Documents are **not** auto-loaded (plain paths, no `@` imports, to keep every session small). Read only the part you need, with `grep -n '^## ' <file>` to find sections:

- Overview and decisions: `spec/documents/idea.md`
- Feature list: `spec/documents/features.md`
- Architecture, modules, technology choices: `spec/documents/architecture.md`
- Working process (lifecycle, rules of engagement): `spec/documents/process.md`

## Layout

```
spec/documents/          project documentation
spec/specifications/     one folder per feature: stories.md, plan.md, progress.md (+ research.md)
source/Packages/         Swift packages (logic, tests)
source/<App>/            app targets (SwiftUI)
source/Spikes/           throw-away experiments (never imported by production code)
.claude/rules/           coding and QA rules
```

## Working rules

- Every feature is identified as `F-XX`; every commit message starts with its feature ID, e.g. `feat(F-01): T001 …`.
- Every commit leaves the repository building and its tests passing.
- Never push, never force, never rewrite history without being asked.

## Rules

Read per task (not auto-loaded):

- Any Swift code: `.claude/rules/swift.md`
- Any code: `.claude/rules/general.md`
- Writing tests and acceptance criteria: `.claude/rules/qa.md`
