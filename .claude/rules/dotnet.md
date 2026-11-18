# .NET Rules — the backend (`source/Backend/`)

Source of truth for structure and technology: `spec/documents/architecture.md` (§3 layout, §4 technology, §6 components). The backend is an ASP.NET Core web API. It holds the AI API key, aggregates the data sources (OpenStreetMap, Wikipedia/Wikidata by default) behind one interface, and caches generated narration. The iPhone app talks to it over `URLSession` and never calls the AI provider or the data sources directly.

These rules apply to every .NET project and file under `source/Backend/`. The Swift rules (`swift.md`) do not apply here.

## Language and project setup
- Target the current long-term-support release of .NET, pinned in `global.json`. Upgrading the SDK is a change recorded in `architecture.md` §4.
- `Nullable` is `enable` in every project. Warnings are errors (`TreatWarningsAsErrors`). Nullable and analyzer warnings are never suppressed in source; a suppression needs a comment that says why.
- Analysers: the .NET analysers at `AnalysisLevel` `latest-recommended`, enabled in `Directory.Build.props` so every project gets them.
- Formatting follows `.editorconfig` at the repository root. `dotnet format --verify-no-changes` must pass, the .NET counterpart of `swift format lint --strict`.
- Use file-scoped namespaces, `required` members and records for immutable data, and `sealed` for classes that are not designed for inheritance.

## Structure
- Logic lives in class libraries that do not reference ASP.NET Core. The web host (`DriveAndGuide.Api`) holds only routing, middleware, configuration binding and the wiring of the logic. The dependency direction is `Api → Application → Domain`, and `Infrastructure` (the data-source adapters, the AI client, the cache) implements interfaces that `Application` defines. Nothing in `Domain` or `Application` references an infrastructure package.
- Public surface is deliberate: `internal` unless another project needs it. Test projects see internals through `InternalsVisibleTo`, declared in one place.
- Shared contracts (request and response models of the API) live in one project. Never define a second copy of a shared type.
- One class, one job. Controllers or minimal-API handlers stay small: validate, call one application service, map the result.

## Async, cancellation and resources
- `async`/`await` end to end. No `.Result`, `.Wait()` or `GetAwaiter().GetResult()` in production code.
- Every asynchronous method that can wait accepts and passes on a `CancellationToken`. Long loops check it between items.
- Create `HttpClient` only through `IHttpClientFactory`. Every outgoing call has an explicit timeout, and transient failures are retried with backoff. Adding a resilience library needs approval and an entry in `architecture.md` §4.
- Dispose what you create (`await using`). No unbounded in-memory buffers: stream large responses, and bound caches by size.
- No static mutable state. Shared state lives in a singleton service whose thread-safety is part of its contract; prefer immutable values and `ConcurrentDictionary` over locks you write yourself.

## Configuration and secrets
- Configuration is bound to options classes with validation (`ValidateDataAnnotations` or `ValidateOnStart`). A missing required value stops the host at start, with an error that names the setting.
- The AI API key comes from the environment, .NET user secrets (development) or the hosting platform's secret store (production). It is never in `appsettings*.json`, source, a fixture, a test snapshot, a log line, an error message or an HTTP response.
- `appsettings.json` holds defaults only, never a credential. A `.env` file is git-ignored and is not read by the host.

## Errors and logging
- No empty `catch`. Every caught exception is handled, logged without secrets, or rethrown. Catch the narrowest type you can handle.
- Map failures at the HTTP edge to `ProblemDetails` with a stable error code the app can act on. Never return stack traces, provider responses or internal type names to a client.
- Use `ILogger<T>` with message templates and `LoggerMessage` source generation for hot paths. Never interpolate values into the message template.
- Route and location data are personal data. Log them at `Debug` only, never at `Information` or above, and never with a user identifier. Log the AI call's model, duration, token counts and outcome, not its prompt or reply.

## Data sources and the AI client
- Every data source is an adapter behind one interface defined in `Application`. Adapters translate the source's model into the domain model; the rest of the backend never sees a source's raw types.
- Each adapter has its own timeout and reports its failure as a typed result, so one failing source does not fail the whole response.
- Attribution required by a source's licence (OpenStreetMap, Wikipedia text under CC BY-SA) is returned with the data, not dropped by the aggregator.
- The AI client is the only place that knows the provider's request shape. Its prompts are built in one place, and the response is validated before it is returned or cached. A reply that fails validation is an error, not content.
- Rate limits and the daily cost ceiling are enforced before the call, not after it.

## Caching
- The narration cache key contains everything that changes the text: place identifier, language, narration style and the model version. Two requests that differ in any of these never share an entry.
- A cache entry has a time-to-live and a size bound. A cache hit is honoured only if the entry is complete and not expired.
- Cached content never contains a credential, a user identifier or a route.

## Security
- HTTPS only, with HSTS in production. No endpoint is public until its authentication is decided and recorded in `architecture.md` §11; `/health` is the only exception.
- Input from the app is validated at the edge: ranges (driving limit, interest radius), lengths and enumerations. Reject, do not clamp silently.
- Dependencies are the approved list in `architecture.md` §4. Any other package needs the user's approval and an entry there first. Pin exact versions.

## Tests
- A test framework is listed in `architecture.md` §4 before the first test project is added. Until it is, no test project exists.
- Pure logic (aggregation, validation, cache keys, mapping) has table-driven tests, including the edge and failure cases.
- Adapters and the AI client are tested against fake `HttpMessageHandler`s with recorded fixtures that contain no secret. No test calls a real provider, a real data source, the network or the wall clock; time comes from an injected `TimeProvider`.
- Host behaviour (routes, status codes, `ProblemDetails`) is tested with an in-memory test host.
- Test names carry the feature and criterion: `F-14 AC-003 rejects a request with an empty destination`.
- Tests are independent and deterministic. A test that cannot fail is a defect.
