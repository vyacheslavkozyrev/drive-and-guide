# General Rules

Language rules are in `swift.md`. Add area-specific rule files (e.g. `server.md`, `client.md`) once the architecture defines those areas.

## Scope
- Implement what the task and its acceptance criteria ask for, nothing more.
- Production code goes under `source/`; throw-away experiments under `source/Spikes/` and are never imported by production code.

## Code
- Match the style and idioms of the surrounding code.
- No dead code, no commented-out code, no TODOs without a feature ID.
- Handle errors explicitly; never swallow them silently.
- No secrets, tokens or credentials in the repository.

## Architecture
- Respect the module boundaries and dependency direction in `spec/documents/architecture.md`.
- A decision that changes the architecture is recorded in `architecture.md` §11 before code depends on it.

## Documentation
- When behaviour changes, update the document that describes it in the same task.
