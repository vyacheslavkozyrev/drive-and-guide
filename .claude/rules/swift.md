# Swift Rules — all DriveAndGuide code

Source of truth for structure and technology: `spec/documents/architecture.md`. These rules are what the reviewer checks. Carried over from the PhotoSync/DriveAndGuide rules, keeping only what is not specific to that product.

## Language and concurrency
- Swift 6 with strict concurrency. No warnings about `Sendable` or data races left behind.
- **Every executable target (app or CLI tool, including spikes) uses a proper `@main async` entry point**: `@main struct App { static func main() async throws { ... } }`. Never top-level script `main.swift` code that blocks a thread (`DispatchSemaphore.wait()`, `RunLoop.run()`) to bridge into `Task {}`-based async work. On DriveAndGuide's toolchain (Swift 6.4 / Xcode 27 / macOS 27) this silently prevented any `Task` from running in a SwiftPM-built executable.
- Shared mutable state lives in actors (or `@MainActor` for UI-facing state). No locks, no `DispatchQueue` for new code unless wrapping a blocking OS API.
- `async`/`await` throughout. Blocking file or disk work runs off the main actor and off NIO event loops.
- Honour cancellation: long loops check `Task.isCancelled` (or call `try Task.checkCancellation()`) between chunks and items.

## Safety
- No `!`, `try!` or `fatalError` in production code paths. Use typed errors (`enum … : Error`) that carry enough context to map to user-visible reasons.
- No silent `catch {}`. Every caught error is handled, logged (without secrets) or rethrown.
- Never build file paths by concatenating untrusted strings; use `URL` APIs with validated components.

## Dependencies and structure
- Only the third-party libraries approved in architecture §4. Adding another needs the user's approval and an architecture update.
- Respect the package dependency graph (architecture §3). Logic packages never import SwiftUI.
- Messages shared between targets live in one shared package. Never define a second copy of a shared type.

## Logging and privacy
- Use `os.Logger` with explicit privacy annotations. Never log secrets, tokens, private keys or personal data at info level or above.
- Secrets (tokens, keys) live in the Keychain, never in `UserDefaults` or logs.

## Style
- Follow `swift format` (run `swift format lint --strict --recursive` on changed files; fix reported issues).
- Names describe purpose; prefer small types with one job. Comments explain *why*, not *what*; no commented-out code.
- SwiftUI views stay small; state lives in `@Observable` view models, not in views.
- Public API of a package is deliberate: mark everything `internal` unless another package needs it.

## Tests
- Swift Testing (`import Testing`) for new tests. See `qa.md`.
