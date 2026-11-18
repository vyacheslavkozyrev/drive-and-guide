> Carried over from PhotoSync/Homeroll. Product-specific guarantees below are examples to trim or replace once this project's architecture is decided; delete the file if there is no such area.

# Server Rules — ServerCore, ServerHTTP, DriveAndGuideServer

Specification: `spec/documents/server-requirements.md`, `protocol.md`, `architecture.md` §6.

## Guarantees that must never break
- **Never a false "stored" or "complete".** A resource is reported `stored` and an asset `complete` only after the file is durably in its final location and the database record is committed.
- **Write procedure (exFAT has no journal):** write to `.driveandguide/incoming/<uploadId>.part` on the same volume → verify size and SHA-256 → `F_FULLFSYNC` → set the modification time → choose the target and record an intent → reserve the target name with `O_CREAT|O_EXCL` and `rename()` over it (exFAT has no exclusive rename; plain `rename` overwrites silently) → remove the file's provenance-only `._` sidecar (must be the **last** action on the file) → commit content index + manifest → respond. Do not reorder these steps.
- **Sidecars:** macOS gives every file on exFAT a `._name` sidecar. Remove one with `unlink` only when the base file's sole attribute is `com.apple.provenance`; sweep at startup, when idle and on eject. Deletion code tolerates `ENOENT`.
- **Startup recovery rolls forward** an intent whose verified `.part` still exists, and clears a zero-byte placeholder at the target name.
- **Never overwrite** an existing file. Name clashes get a numeric suffix, checked case-insensitively (and on normalised Unicode); all resources of one asset share the same suffix.
- **Startup recovery** finishes or discards leftover intents, drops index entries whose file is gone, and cleans stale `.part` files (older than 7 days).
- **Duplicates:** the content index is keyed by `(scope, sha256)`, scope = device id or `archive`. A hit is honoured only if the referenced file still exists with the recorded size; otherwise drop the entry and request the upload.

## Structure
- `ServerCore` holds logic and is UI-free and HTTP-framework-free. `ServerHTTP` contains only routing, middleware and TLS glue that calls `ServerCore`. The app target contains only SwiftUI and OS integration.
- **Never abandon an accepted connection before the client can observe it.** Spike S2 found that cancelling an `NWListener`-accepted connection immediately (without starting it, or before the peer's own connection reaches `.ready`) can silently prevent the client from ever completing its own connect — no error, just a hang. Accept, start, and let a connection reach a stable state before closing it.

## Discovery
- The Bonjour advertiser uses `DNSServiceRegister` with the TXT record shape in protocol §4 (`pv`, `id`); it re-registers whenever `NWPathMonitor` reports a change in **path status or expense, not just the interface name set** — spike S2 found that toggling WiFi off/on on macOS does not change the interface name list, only the path status (`satisfied` ↔ `unsatisfied`).
- All paths under the library are built by `PathPlanner`; request handlers never assemble paths themselves. Sanitising follows server-requirements §4 (invalid characters, Windows reserved names, 255 UTF-16 units, no leading dot or trailing dot/space).
- The drive database (`library.db`) uses GRDB `DatabaseQueue` (rollback-journal mode, `synchronous = FULL`, `fullfsync = ON`). Never `DatabasePool` and never WAL on the drive.
- Never write extended attributes or resource forks ourselves. macOS adds `com.apple.provenance` on its own, and the sidecar rule above deals with it. The OS does not enforce Windows-safe names on exFAT, so sanitising is entirely ours.

## Security
- TLS 1.3 only. Tokens are stored as SHA-256 hashes and compared in constant time. Unauthenticated routes (`/v1/info`, `/v1/pair`) are rate-limited.
- Pairing offers live only in memory, are single-use, expire after 5 minutes and cancel after 5 failed attempts.
- No endpoint lists or downloads stored files.

## Uploads
- Stream request bodies to disk; memory use must not grow with file size.
- Behaviour and error codes follow protocol §3 and §7 exactly (`409 offset_mismatch`, `422 checksum_mismatch`, `503 drive_unavailable`, `507 insufficient_storage`, …).
