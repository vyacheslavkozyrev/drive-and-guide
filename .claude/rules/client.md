> Carried over from PhotoSync/Homeroll. Product-specific guarantees below are examples to trim or replace once this project's architecture is decided; delete the file if there is no such area.

# Client Rules — ClientCore, DriveAndGuideClient

Specification: `spec/documents/ios-client-requirements.md`, `protocol.md`, `architecture.md` §7.

## Guarantees that must never break
- **Synced only on the server's word.** An item is recorded as Synced only after the server reports its asset `complete`. Never on the client's own say-so.
- **In Progress lives in memory only.** After a relaunch, anything that was In Progress is Not Synced again.
- **A failed or interrupted item returns to Not Synced** and is retried on the next sync; the reason appears in the sync summary.
- **Edited-after-sync items stay Synced.** Edits are not re-uploaded.

## Structure
- `ClientCore` holds logic and never imports SwiftUI. Photo access sits behind the `PhotoSource` protocol so tests use `FakePhotoSource`; only `PhotoKitSource` imports PhotoKit.
- One sync run at a time (single-flight). Triggers call the same `runSync()`.
- Export each resource to a temp file while computing its SHA-256 in the same pass; delete temp files when the item finishes or fails.
- Records key on `PHAsset.localIdentifier`, never on file names.

## Networking and security
- Discovery uses `NWBrowser(for: .bonjourWithTXTRecord(type: "_driveandguide._tcp", domain: nil), ...)`. **Not** the plain `.bonjour(...)` descriptor — spike S2 found it delivers no TXT record data at all (`result.metadata` is always `.none`), even though the TXT record is genuinely being advertised.
- All requests go through `PinnedSession`, which accepts only the pinned SPKI fingerprint. Never fall back to default trust evaluation.
- The device token, `deviceId`, pinned fingerprint and server id live in the Keychain, never in `UserDefaults` or logs.
- The unpinned probe used by manual pairing may call only `GET /v1/info`, and must send nothing secret.

## Background continuation
- The background task is submitted only from an explicit user action (the Sync button), reports progress continuously, handles expiration by stopping cleanly, and calls `setTaskCompleted` exactly once.

## UI
- Rows read status from memory (the synced-set and the in-progress set); drawing a row does no database or network work.
- The connection indicator shows exactly: Checking…, Connected, Not Connected (+ reason from protocol §6).
