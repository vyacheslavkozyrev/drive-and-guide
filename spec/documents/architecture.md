# DriveAndGuide — Architecture

Status: draft for review, generated 2026-11-17 from [idea.md](idea.md). Replaces the PhotoSync/Homeroll draft. Items marked **to confirm** are proposals the user has not yet agreed; items marked **open** are not decided.

## 1. Goals of the architecture

In priority order:

1. **Safety while driving.** Nothing requires a tap or a read while driving. Narration never interrupts navigation.
2. **Trustworthy facts.** Narration is built only from retrieved source text, and says where it came from. A failed check produces silence, not an invented sentence.
3. **Testability.** Planning, narration selection and the backend's aggregation are pure logic that runs in tests without a device, a network or a clock.
4. **Low running cost.** AI calls are cached and rate-limited; the backend stores no trip, location or route data.
5. **Simplicity.** Two technologies only (Swift for the app, .NET for the backend). No own navigation, no database on the server in the MVP.

## 2. System overview

```
┌──────────────── iPhone (Swift) ────────────────┐         ┌──────── Backend (.NET) ────────┐
│ App (SwiftUI, MapKit view)                     │  HTTPS  │ Api  ──▶ Application ──▶ Domain │
│  ├─ TripPlanning   (pure logic)                │ ──────▶ │          │                      │
│  ├─ Narration      (pure logic)                │  JSON   │          ▼                      │
│  ├─ PlaceClient    (URLSession)  ──────────────┼─────────┤   Infrastructure               │
│  └─ Platform       (CoreLocation, MapKit       │         │    ├─ OpenStreetMap source     │
│                     routing, speech, hand-off) │         │    ├─ Wikipedia / Wikidata     │
└───────┬────────────────────────────────────────┘         │    ├─ Claude client            │
        │ hand-off (route, waypoints)                      │    └─ in-memory narration cache│
        ▼                                                  └────────────────────────────────┘
 Apple Maps / Google Maps / Waze   (external navigation app, runs in the foreground while driving)

 Narration audio: the app calls Azure AI Speech directly, with a short-lived token from the backend.
```

Where data lives:

| Data | Where | Kept for |
|---|---|---|
| Trips: destination, target, interests, radius, planned stops, and the places already spoken | Phone, a JSON file in Application Support | Kept on the phone; survives app restarts; no limit on the number of trips in the MVP. Nothing is stored on the server. After the MVP, trips move to an Azure Storage account (decided 2026-11-17). |
| Settings (radius, enabled data sources, narration on or off) | Phone, `UserDefaults` (no secrets) | Until changed |
| Narration text and its sources | Backend, memory cache with time-to-live | Hours, not days; lost on restart |
| Source data (place facts) | Backend, memory cache with time-to-live | Same |
| Claude API key | Backend environment or secret store only | — |

The backend has no database and no user records in the MVP.

## 3. Repository and module layout

All code lives under `source/`.

```
source/
├── Packages/                     Swift packages, one per module (tests in Tests/<Package>Tests/)
│   ├── Shared/                   domain types and message shapes used by the app and its packages
│   ├── TripPlanning/             stop placement and interest scoring (pure)
│   ├── Narration/                choosing what to say and when; text checks (pure)
│   ├── PlaceClient/              HTTP client for the backend; DTO mapping; typed errors
│   └── Platform/                 CoreLocation, MapKit routing, speech, hand-off to other apps
├── DriveAndGuide/                iOS app target (SwiftUI, MapKit view, composition, settings)
├── Backend/                      .NET solution (one solution, one rule file: .claude/rules/dotnet.md)
│   ├── DriveAndGuide.Api/        ASP.NET Core host: endpoints, validation, ProblemDetails, wiring
│   ├── DriveAndGuide.Application/  use cases and the interfaces they need
│   ├── DriveAndGuide.Domain/     places, narrations, rules (no framework references)
│   ├── DriveAndGuide.Infrastructure/  source adapters, Claude client, cache
│   └── tests/                    one test project per project above
├── scripts/                      build-all.sh (Swift), task-check.sh (the check the commands run)
└── Spikes/                       throw-away experiments; never imported by production code
```

**Dependency rule.** Arrows point to what may be used:

```
App ──▶ TripPlanning, Narration, PlaceClient, Platform, Shared
TripPlanning ──▶ Shared
Narration ──▶ Shared
PlaceClient ──▶ Shared
Platform ──▶ Shared
```

- `Shared`, `TripPlanning` and `Narration` import no UI, location, speech or networking framework.
- `Platform` may import CoreLocation, MapKit, AVFoundation and UIKit (for opening other apps), but never SwiftUI.
- Only the `DriveAndGuide` app target imports SwiftUI.
- `PlaceClient` imports `URLSession` only.
- The backend: `Api ──▶ Application ──▶ Domain`; `Infrastructure ──▶ Application` (it implements interfaces that `Application` defines). `Domain` and `Application` reference no infrastructure or ASP.NET Core package.
- No Swift package references the backend project, and no backend project references Swift code. The two sides meet only through the API contract (§5).

## 4. Technology decisions

| Area | Choice | Notes |
|---|---|---|
| App language | **Swift 6**, strict concurrency (actors, `async`/`await`, `Sendable`) | Toolchain shipped with Xcode 27. |
| App UI | **SwiftUI** with a MapKit map view | AppKit and macOS are not used. |
| App platform | **iOS only** (decided 2026-11-17), iPhone; **iOS 26 or later** | The minimum version is **to confirm**. No iPad, Mac or other platforms. |
| App structure | Swift packages for all logic; a thin app target | See §3. |
| Routing on the phone | **MapKit** `MKDirections` for the route and leg times | Drives stop placement. See spike S1. |
| Map drawing | **MapKit** (`Map` view) | Decided in the idea. No Google Maps SDK. |
| Navigation | Hand-off to Apple Maps, Google Maps or Waze | No navigation SDK. Embedding one is a later step. |
| Location | **CoreLocation** (`CLLocationManager`) behind a protocol | Background location mode needed while narrating. |
| Speech | **Azure AI Speech** (neural voices, through Microsoft Foundry), called from the app with a short-lived token issued by the backend; **AVSpeechSynthesizer** as the fallback. Both behind a protocol | Decided 2026-11-17. About $15 per million characters (estimate, to verify). The voice itself is still to be chosen. |
| Settings | `UserDefaults` (no secrets): radius, enabled sources, narration on or off, number of stop options | Decided 2026-11-17. |
| Secrets on the phone | **Keychain**: the install secret used for the access token (§11, O1) | Never in `UserDefaults`, a file or a log. |
| Trips | A Codable JSON file in Application Support, with planned stops and the spoken places | Decided 2026-11-17. A file, not a database; survives app restarts. GRDB is not used. |
| Networking | `URLSession`, HTTPS only, system trust | No certificate pinning in the MVP (§10). |
| Logging | **`os.Logger`** with privacy annotations | No location or secrets at info level or above. |
| App tests | **Swift Testing** | See §8. |
| Backend language | **C#** on **.NET** (the current LTS release, pinned in `global.json`) | Rules in `.claude/rules/dotnet.md`. |
| Backend web | **ASP.NET Core** minimal APIs | Only framework packages from Microsoft. |
| Backend hosting | **Microsoft Azure**, **Azure App Service**, Basic tier (B1), Linux, .NET (decided 2026-11-17) | About $13 a month (estimate, to verify); Standard S1 is about $57 to $69 if scaling is needed later. One instance, so the in-memory cache is shared by all requests. Custom domain on a subdomain such as `api.<domain>`; the managed certificate is not offered for the bare domain. |
| Domain and DNS | **Cloudflare**: domain registration and DNS (decided 2026-11-17) | The domain name is open. DNS-only record to the App Service host; Cloudflare proxying is **to confirm**. |
| Backend secrets | **Azure Key Vault**, read by the App Service managed identity | The Claude API key is never in source, `appsettings` or the repository. |
| Places data | OpenStreetMap (Overpass) and Wikipedia/Wikidata, behind `IPlaceSource` | Defaults in the idea. Each source keeps its licence attribution. |
| AI | **Claude** through **Microsoft Foundry** (billed through the Azure Marketplace), called only from the backend | Decided 2026-11-17. Model: **to confirm** in spike S4 (§11). The key never reaches the app. |
| Backend cache | In-memory, with time-to-live and size bound (decided 2026-11-17) | No Redis in the MVP. Revisit if more than one instance is needed. |
| Backend resilience | Timeouts and retries through `IHttpClientFactory` | **To approve**: `Microsoft.Extensions.Http.Resilience`. |
| Backend tests | **xUnit** with fake `HttpMessageHandler`s (approved 2026-11-17) | |
| Swift build | `swift build` and `swift test` per package via `source/scripts/build-all.sh` | Needs Xcode for app targets. |
| .NET build | `dotnet build`, `dotnet test`, `dotnet format --verify-no-changes` | Not yet in the scripts; added by the first backend feature. |
| App target build | `xcodebuild` with the workspace scheme | Not yet in the scripts; added by the first app target feature. |

**Approved third-party dependencies (exact versions pinned):** none for the Swift side. Everything there is an Apple framework. Backend packages are added only after approval and an entry here.

## 5. Shared contracts

**Swift shared types** (`Shared` package). The app and its packages use one copy of each:

- `DrivingTarget`: hours before a rest, and the window (e.g. 3.5 to 4.5 h for 4 h).
- `InterestArea`: a fixed enum of about six areas (history, nature, architecture, food, viewpoints, towns). Final list in `features.md`.
- `Trip`: destination, target, selected interests, radius, planned stops.
- `Stop`: the place (optional until chosen), the expected elapsed time, and the window.
- `Place`: id, name, coordinate, interest areas, notability reasons, the sources it came from.
- `NarrationSource`: source name, URL, licence, attribution text.
- `Narration`: place id, English text, its sources.
- `Coordinate`, `Distance` and `Duration` value types with unit-safe arithmetic.

**API contract.** The HTTP contract lives in `spec/documents/api.md`, written by the first feature that defines an endpoint. The Swift DTOs in `PlaceClient` and the .NET DTOs in `Api` must match it; a change to the contract changes that document first. The planned endpoints are:

| Endpoint | Purpose |
|---|---|
| `GET /health` | Liveness. The only endpoint that needs no authentication. |
| `POST /v1/places/nearby` | Places within a radius of a point, for the enabled sources, with their interest areas. |
| `POST /v1/narrations` | A narration for one place id: the backend fetches the source text itself and returns the checked text with its sources. |
| `POST /v1/access-tokens` | Exchanges the install secret for a signed, short-lived access token (§11, O1). |
| `POST /v1/speech-tokens` | Issues a short-lived token for Azure AI Speech, so the app can call Azure directly. Needs a valid access token; rate-limited. |

The backend never accepts facts from the app to put into narration; it looks them up from the sources. The app does not ask the backend to route.

## 6. Components

### 6.1 TripPlanning (Swift package)
- **Responsibility.** Given a route with leg times, find the points at each driving-time target and the window around each one. Score candidate places against the driver's interests and the distance from the route.
- **Input.** Route legs with travel times (from Platform), candidate places (from PlaceClient), the trip settings.
- **Scoring is in the app.** The app scores each candidate against the driver's interest areas, the distance from the route and the notability reasons. The backend returns facts and interest tags only; it does not rank.
- **Output.** For each planned stop, a window and a ranked shortlist of options (the number is set in settings; 3 by default, **to confirm**). The driver chooses one option before the trip. Nothing is planned without candidates; a stop with no candidate is marked "no place found" and the driver is told.
- **Errors.** Typed results (`noRoute`, `targetBeyondRoute`, `noCandidates`); never a silent empty plan.
### 6.2 Narration (Swift package)
- **Responsibility.** Decide what to say, and when. Applies the rules from the idea: notable places only, a minimum distance between two spoken places, no place twice in a trip, and nothing while the driver is near a planned stop unless it is that stop.
- **Input.** The current location, nearby places, the spoken history of the trip, settings.
- **Output.** At most one `Narration` to speak now, or nothing.
- **Errors.** Checks the narration text (length, language, no empty text) before it reaches speech. A text that fails the check is dropped and logged without content.

### 6.3 PlaceClient (Swift package)
- **Responsibility.** Calls the three endpoints in §5; maps DTOs to `Shared` types.
- **Errors.** Typed: `offline`, `timeout`, `serverRefused(code)`, `unexpectedResponse`. A failed source is reported per source, not as a failed request.
- **Retries.** At most one retry for idempotent calls, and only for network errors.

### 6.4 Platform (Swift package)
- **Routing.** `MKDirections` for the route. `MKRoute.Step` does not carry a time, so leg times come from separate calculations between waypoints or from an estimate (spike S1).
- **Location.** A protocol `LocationSource`; the CoreLocation implementation requests "when in use" first, and "always" only when background narration is turned on.
- **Speech.** A protocol `SpeechOutput` with two implementations. The Azure AI Speech implementation takes a token from the backend and streams the audio from Azure; the backend is not on the audio path. The AVSpeechSynthesizer implementation is the fallback when Azure is unreachable (to confirm). Both set the audio session to duck other audio while speaking.
- **Hand-off.** Builds the URL for the chosen navigation app with the stops as waypoints, and opens it. Which apps and how waypoints are passed: spike S5.

### 6.5 App target (DriveAndGuide)
- SwiftUI screens: trip setup, planning (map, and for each stop the shortlist of options to choose from), driving (next stop, narration status, hand-off button), settings.
- View models are `@Observable` and `@MainActor`; they hold no business rules, they call the packages.
- **Errors shown to the driver**, in plain words: location off, no network (narration pauses and resumes), no place found for a stop.

### 6.6 Backend: Api
- Endpoints, input validation (ranges, lengths, enumerations; reject, do not clamp), the access-token check on every endpoint except `/health` and the token exchange, speech tokens issued only to valid access tokens, rate limits per IP and the daily cost ceiling checked before any AI call, and `ProblemDetails` for every error with a stable code.
- No endpoint returns stack traces, provider replies or internal type names.

### 6.7 Backend: Application
- Use cases: `FindNearbyPlaces`, `GetNarration`.
- Interfaces: `IPlaceSource` (one per source), `INarrationGenerator`, `INarrationCache`, `TimeProvider` for time.
- `GetNarration`: cache lookup by place, language and model version; on a miss, fetch the source text, call the generator with that text only, check the reply, cache it, return it with its sources.

### 6.8 Backend: Domain
- `Place`, `Narration`, `PlaceSourceRef`, and the rules that check a narration: it cites at least one source, it is English, it is not longer than the limit, and it contains no claim outside the source text that the checks can detect (a heuristic; the fidelity spike S4 measures it).

### 6.9 Backend: Infrastructure
- `OpenStreetMapSource` (Overpass queries with timeouts), `WikipediaSource` (article extracts), `WikidataSource` (identifiers and categories).
- `ClaudeNarrationGenerator`: the only class that knows the provider's request shape; builds the prompt in one place.
- `MemoryNarrationCache`: time-to-live and a size bound.
- Each source adapter translates its model into `Place` and is the only code that sees the source's raw types.

## 7. Data model

**On the phone** (JSON, versioned by a `schemaVersion` field):

- `Trip { schemaVersion, id, destination, target, interests, radiusMeters, stops[], spokenPlaceIds[], createdAt }`
- `Stop { expectedElapsed, window, options: [Place] (ranked), chosenPlaceId?, status: planned | chosen | passed | none }`
- `spokenPlaceIds` is saved with the trip, so the rule "no place twice" holds across app restarts for the whole trip.
- The MVP has one user, the owner, and keeps every trip on the phone with no count limit. After the MVP, trips move to an Azure Storage account; that move will need its own privacy and retention decisions.

**On the backend** (no database):

- `Place { id, name, lat, lon, interestAreas[], notabilityReasons[], sources[] }`
- `Narration { placeId, language, modelVersion, text, sources[], createdAt }` in the cache only.
- The backend stores no install records. Access tokens are signed and expire (§11, O1), so the backend keeps nothing per install.
- The cache key is `(placeId, language, modelVersion)`. Nothing else is stored.

Migrations: the phone's JSON file is read with a version check; an unknown version discards the trip with a message.

## 8. Testing strategy

Levels, following `.claude/rules/qa.md`:

| Level | Where | What it proves |
|---|---|---|
| Swift unit | `source/Packages/<Package>/Tests/` | Stop placement, scoring, narration rules, DTO mapping, error paths. Fakes for location, speech, network. |
| App view models | `source/DriveAndGuideTests/` | Screen states and the messages shown for each error. |
| Backend unit | `source/Backend/tests/` | Aggregation, validation, narration checks, cache keys, rate limits. Fake sources and a fake Claude client. |
| Backend host | same | Routes, status codes, `ProblemDetails`, authentication once decided. |
| Device | `device-checklist.md` in each feature | Real GPS, background narration, audio ducking, hand-off to each navigation app, driving safety. |

- No test calls a real data source, the Claude API, the network or the wall clock.
- A feature's `[device]` criteria go into its checklist, as the process requires.
- A route fixture (recorded legs and places) drives the planning tests, so the planning logic is checked against realistic data without driving.

## 9. Prototype spikes and build order

Riskiest assumptions first. Each spike is a throw-away program under `source/Spikes/` with a result note in `spec/specifications/F-02-technical-spikes/`.

| Spike | Question | Pass criteria | Fallback |
|---|---|---|---|
| S1 | Can MapKit give a route with leg times good enough to place a stop at each 4 h mark, on a 600 km route? | Stops land within ±15 min of the target on three test routes | Estimate leg times from distance and the route's average speed; show the window wider |
| S2 | Does narration keep working in the background for 30+ minutes while Apple Maps or Google Maps is in the foreground, and is it approved for the App Store? | Speech resumes after an app switch; audio ducks; background modes accepted in review | Narration works only while our app is on screen, and the driver is told so; product decision needed |
| S3 | Is there enough notable-place data along real routes? | At least one notable place per 30 min of driving on five test routes in the first region | Add Wikivoyage or a national register as a source; widen the radius (product decision) |
| S4 | Does grounded narration stay faithful to its source, and what does it cost? | No invented fact in a sample of 30 narrations, checked by hand; cost per narration recorded | Stronger prompt; use the source's first paragraph only; a smaller model |
| S5 | Can the stops be passed as waypoints to Apple Maps, Google Maps and Waze? | Each app opens with all stops in order | Hand off one stop at a time, or the start and destination only |
| S6 | Does Azure AI Speech play in the background during a long drive, and does the backend-issued token keep working through signal drops and renewal? | Speech plays through a 30-minute background session; token renewal is seamless; a signal drop falls back to the built-in voice | Built-in voice only |

Build order: Shared and TripPlanning with fixture data → Platform routing (S1) → Narration → PlaceClient and the backend's `GetNarration` with fakes → S2 and S5 on the phone → backend sources and Claude (S3, S4) → app screens and integration.

## 10. Risks and fallbacks

| Risk | Likelihood | Impact | Mitigation / fallback |
|---|---|---|---|
| App Store rejects background narration | Medium | High | Spike S2 early; fallback is on-screen mode with a clear notice |
| Leg times from MapKit are too coarse for stop placement | Medium | Medium | Spike S1; estimate with a wider window |
| Thin place data on rural roads | High | High | Spike S3; more sources; wider radius as a product choice |
| AI invents or distorts a fact | Medium | High | Grounded prompt, checks in Domain, no narration when the check fails, fidelity spike S4 |
| AI and voice cost per trip too high | Medium | Medium | Cache by place; rate limits; daily ceiling; cheaper model if S4 allows |
| Poor signal on long routes | High | Medium | No prefetch in the MVP (O7); narration pauses offline or falls back to the built-in voice. After the MVP, the driver can download the narration on request |
| A script uses the speech token endpoint to run up the Speech bill | Medium | Medium | Speech tokens issued only to valid access tokens, within the rate limit and the daily ceiling |
| Driver distraction rules or legal limits | Medium | High | No taps while driving; voice only; legal review before release |
| Licence breach (OpenStreetMap, Wikipedia CC BY-SA) | Low | High | Attribution returned with every narration; checked in review |
| Certificate pinning not used | Low | Medium | System trust with HTTPS only; revisit with the authentication decision |
| Scripted abuse of the public endpoints (new install secrets are free) | High | High | Limits by IP address and a daily ceiling in the MVP; App Attest before the first public launch (decided, §11 O1) |

## 11. Decisions and open questions

**Taken from the idea and the review (2026-10-18 to 2026-11-17):** iOS only; Swift and SwiftUI on the phone; third-party navigation by hand-off, no own navigation; .NET backend that holds the AI key; OpenStreetMap and Wikipedia/Wikidata behind one interface; driving time as a target with a window; before-trip choice from a shortlist of options per stop, plus optional voice acceptance while driving; no server-side storage of trip data; English only; MapKit map; fixed interest list and 10 km default; rule-based narration; stops scored in the app; no backend routing; Azure App Service and Cloudflare; in-memory backend cache; xUnit for backend tests; settings in `UserDefaults`, no database on the phone; trips kept in a phone file that survives restarts; Azure AI Speech called from the app, with the built-in voice as fallback; Claude through Microsoft Foundry; Azure App Service Basic (B1).

**Taken in this draft (to confirm):**

1. The app runs on iOS 26 or later. The minimum version is to confirm.
2. Routing and stop placement run on the phone with MapKit; the backend does not route.
3. The phone holds no database. Settings are in `UserDefaults`; the install secret is in the Keychain; trips, with their planned stops and spoken places, are a JSON file that survives restarts.
4. The backend has no database. Its cache is in memory and is lost on restart.
5. Stop ranking is done in the app by interest scoring. The driver chooses from a shortlist of options per stop. The shortlist size is 3 by default, to confirm.
6. Narration is produced only from fetched source text, and the backend checks the reply before returning it.
7. Backend tests use xUnit (approved). Resilience uses `Microsoft.Extensions.Http.Resilience`, which still needs approval (§4).
8. A solution `source/Backend/` with the projects in §3.
9. Hosting: Azure App Service (Basic B1) for the backend, Cloudflare for the domain and DNS, Azure Key Vault for the Claude key. Estimated cost about $13 a month (§4).
10. Narration audio: Azure AI Speech, called by the app with a token from the backend; the built-in voice is the fallback.
11. Claude is called through Microsoft Foundry.

**Decided by the owner, 2026-11-17:** the owner is the only user in the MVP. Rate limits and the daily ceiling still apply, because they protect the cost. Speech tokens are issued only to valid access tokens, within the rate limit and the daily ceiling.

**Deferred by the owner, 2026-11-17:** O2 (domain name), O3 (Claude model), the neural voice in O4, O6 (hand-off details), O10 and O11. They will be decided when the feature that needs them is specified.

**Open questions:**

- **O1 Access design: decided 2026-11-17.** The app creates a random 256-bit install secret on first launch and keeps it in the Keychain. It exchanges the secret at `POST /v1/access-tokens` for an access token, signed by the backend with a key in Key Vault, that expires after a short time (one hour, to confirm). The backend stores nothing per install, so it needs no database. The app sends the token on every call except `/health` and the exchange. A new install gets a new secret.
  - **What this gives:** each install has an unguessable identity that is not linked to the phone ID or to other apps.
  - **What it does not give:** the secret does not stop a script, which can exchange a new secret at any time. Per-install limits are therefore not possible without storage, and the backend limits by IP address and by the daily ceiling only.
  - **Protection against scripted abuse:** Apple App Attest, which proves the request comes from a genuine copy of the app. Decided 2026-11-17: added before the first public launch, not before the first backend feature.
  - The rejected alternative was a token derived from the phone ID. `identifierForVendor` is not secret, so it proves nothing about the caller. It is also the same kind of identity as the secret without the benefit of being unguessable.
  - Closed.
- **O2 Domain name.** Still open. The subdomain `api.<domain>` is proposed, and Cloudflare proxying is to confirm.
- **O3 Claude model** for narration, through Microsoft Foundry. Candidate: Sonnet 5.5 (about $2 and $10 per million tokens, estimate); Haiku 5.5 is the cheaper option. To be decided with S4.
- **O4 Text to speech.** Decided: Azure AI Speech, called from the app, with the built-in voice as fallback. The neural voice itself is still to be chosen.
- **O5 Stop ranking.** Decided: scored in the app (§6.1). Closed.
- **O6 Hand-off.** Which navigation apps to support first, and how waypoints are passed (S5).
- **O7 Prefetch.** Decided: no prefetch in the MVP. After the MVP, the driver can download the narration for the trip on request. Closed.
- **O8 Past trips.** Decided: trips are kept on the phone with no count limit in the MVP. After the MVP, they move to an Azure Storage account. Closed.
- **O9 Restart mid-trip.** Decided: the spoken history survives restarts (§7). Closed.
- **O10 Window size and traffic stops** (from the idea).
- **O11 Region for the first release**, which decides the data-source tests in S3.
