# DriveAndGuide — Architecture

Status: template. Fill in once the idea and features are agreed.

## 1. Goals of the architecture

[Qualities that drive the design, in priority order: e.g. correctness, simplicity, testability, performance, security.]

## 2. System overview

[Components, who talks to whom, and where data lives. Add a diagram.]

```
[component] ──▶ [component] ──▶ [store]
```

## 3. Repository and module layout

All code lives under `source/`. [Describe modules/packages and the allowed dependency direction.]

```
source/
└── [module]/
```

Dependency rule: [e.g. "UI depends on logic; logic never depends on UI."]

## 4. Technology decisions

Proposed from the PhotoSync/Homeroll stack; confirm or change each row.

| Area | Choice | Notes |
|---|---|---|
| Language | **Swift 6**, strict concurrency (actors, `async`/`await`, `Sendable`) | Data races are compile errors. |
| UI | **SwiftUI**; `MenuBarExtra` if there is a Mac menu bar item | AppKit/UIKit only where SwiftUI can't. |
| Platforms | latest **macOS**, **iOS 26+** | [confirm which platforms this project targets] |
| Structure | Swift packages for all logic, thin app targets, one shared package for shared types | See §3. |
| Database | **SQLite via GRDB** | [confirm if persistence is needed] |
| Crypto | **CryptoKit** | First-party. |
| Networking | `URLSession`; Hummingbird 2 / SwiftNIO if a server is needed | Backend decided: the app talks to our .NET backend over `URLSession` |
| Logging | **`os.Logger`** with privacy annotations | No secrets or personal data in logs. |
| Testing | **Swift Testing** | See §8 and `.claude/rules/qa.md`. |
| Backend | **.NET** (ASP.NET Core) web API, hosting [to decide] | Proposed. Holds the Claude API key, aggregates data sources, caches narration. Not in the PhotoSync stack; needs its own rule file. |
| Navigation and maps | External navigation app via hand-off (Apple Maps, Google Maps, Waze) for the MVP | We do not build navigation; our app narrates in the background. An embedded SDK is a possible later step. |
| Data sources | OpenStreetMap, Wikipedia/Wikidata by default; user-selectable, behind a common interface | More sources are optional add-ons. |
| AI | Claude via the backend only | The key never ships in the app. |
| Build | `swift build` / `swift test` per package; `xcodebuild` for app targets | Needs full Xcode for app targets. |

Third-party dependencies (exact versions pinned) must be approved here before use. Candidates carried over from Homeroll: Hummingbird, swift-nio-ssl, swift-certificates, swift-crypto, GRDB. Everything else is Apple frameworks.

## 5. Shared contracts

[Data models, API or protocol shared between components.]

## 6. Components

### 6.1 [Component]

[Responsibility, key types, data flow, error handling.]

## 7. Data model

[Entities, relationships, persistence format, migrations.]

## 8. Testing strategy

[Test levels, what each proves, where tests live. See `.claude/rules/qa.md`.]

## 9. Prototype spikes and build order

[Riskiest assumptions to prove first, and the order of construction.]

| Spike | Question | Pass criteria | Fallback |
|---|---|---|---|
| S1 | [ ] | [ ] | [ ] |

## 10. Risks and fallbacks

| Risk | Likelihood | Impact | Mitigation / fallback |
|---|---|---|---|
| [ ] | | | |

## 11. Decisions and open questions

Taken in this draft (change any you disagree with):

1. [decision]

Open questions:

- [question]
