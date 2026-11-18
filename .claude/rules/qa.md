# QA Rules — tests and acceptance criteria

## Tests travel with the code
Every task adds or updates the tests for the code it changes, in the same task. There are no "tests later" tasks.

## Where tests live

| Level | Location |
|---|---|
| Unit / component (a package) | `source/Packages/<Package>/Tests/<Package>Tests/` |
| End-to-end | `source/Packages/E2ETests/` (if needed) |
| App targets | `source/<App>Tests/` for view-model and OS-glue logic |

## Naming acceptance criteria
- Criterion IDs restart in every feature; every test that proves one carries the feature and criterion, e.g. `F-08 AC-003 rejects an oversized upload`.
- A criterion tagged `[auto]` in `stories.md` needs at least one passing test naming it.
- A criterion tagged `[device]` goes into the feature's manual checklist.

## What to test
- Pure logic with table-driven tests, including edge and negative cases.
- Error paths and recovery, not only the happy path.
- Run per package: `swift test --package-path source/Packages/<Package>`; a change also runs the tests of every package that depends on it.
- No test depends on the real network, the wall clock, or another test's state.
