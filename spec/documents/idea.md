# DriveAndGuide — Idea

Status: reviewed 2026-11-17 for conflicts and gaps; the decisions from that review are recorded under Decisions. Written 2026-10-18 from the first idea discussion.

## Summary

DriveAndGuide is an iPhone app for long road trips. The driver sets a destination and how long they can drive before they need a rest (for example 4 hours). The app plans the route and picks the rest stops so that each stop is somewhere worth stopping, based on the driver's interests. While driving, an AI voice tells the driver interesting facts about places along the route, within a radius the driver chooses.

## Problem

On a long drive, rest stops are usually chosen by chance: the next fuel station or whatever exit is closest. Drivers who would happily stop somewhere interesting (a castle, a viewpoint, a good town) don't find out about it in time. Existing audio-guide apps narrate what is nearby but don't plan the trip around the driver's need to rest, and navigation apps don't know anything about the driver's interests.

## Users

| User | Goal | Notes |
|---|---|---|
| Long-distance road tripper (**MVP**) | Get from A to B with sensible, interesting rest stops, and hear about places on the way | Drives alone or with passengers; hands and eyes are busy, so voice first |
| Tourist exploring a region by car (**next**, higher priority than commuters) | Discover places along a route | Needs richer planning and more content |
| Commuter (**later**) | Make a familiar drive more interesting | Needs non-repetitive content; lowest priority |

## Core concept

1. **Trip setup:** destination, planning target for the driving time before a rest (default e.g. 4 h), interest radius (default 10 km), interest areas chosen from a fixed list (history, nature, architecture, food, viewpoints, towns, and similar).
2. **Trip plan:** a route with a rest stop planned near each driving-time target. For each stop the app scores candidates against the driver's interests and near the route, and offers a shortlist of options. The driver chooses one option for each stop before the trip. While driving, a suggested replacement can be accepted by voice; this is optional and never required.
3. **Navigation:** the route and turn-by-turn guidance come from a third-party navigation and maps provider; we do not build our own navigation. For the MVP the app hands the route off to an external navigation app (Apple Maps, Google Maps or Waze) and keeps running in the background to narrate. The planned route and stops are drawn on an Apple MapKit map inside our app.
4. **Narration while driving:** from the current location, find notable places within the interest radius, rank them by the driver's interests, and read out an AI-written fact summary in English. The app speaks only under the rules in Decisions (notable places, spaced apart, no place twice in a trip).
5. **Stop guidance:** approaching a planned stop, tell the driver what is there and why it is worth the stop.

## Product direction

- **Primary goal:** make long drives safer and more enjoyable by pairing necessary rest stops with interesting places.
- **MVP:** iOS only. Long road trips. Trip planning by driving-time target and interests, route on a map with navigation, spoken facts about nearby places in English. [Exact scope to be set in `features.md`.]
- **Post-MVP:** tourist features (multi-day trips, richer content, saved trips), then commuter features (non-repeating content on familiar routes). More narration languages. CarPlay. Android. Offline use.

## Differentiation

See [market-research.md](market-research.md). Narration of nearby places is already offered by several apps (WikiTrip, RoadWhisper, Narrando, AI TourMate and others), so narration alone is not the differentiator. The proposed differentiators are:

1. **The route is planned around the driver's rest rhythm.** The stop after N hours is chosen for interest, not by chance. The first market search found no app that offers this as a core input; this is not yet verified (see market research, "To verify next").
2. **Interest-driven selection** of both stops and narration.
3. **Restraint:** it speaks only when there is something worth saying, does not repeat a place within a trip, and stays quiet at busy moments (the rule for busy moments is still to be defined in `features.md`).
4. **Facts that can be trusted:** narration is based on retrieved source data (map and encyclopedia sources) rather than invented by the model, and says where the facts come from.

## Scope

**In scope (MVP)**
- Destination and driving-time target input; interest areas from a fixed list; interest radius (default 10 km).
- Route planning with rest stops near the driving-time target.
- Map display of the planned trip and stops in our app (Apple MapKit); turn-by-turn guidance by a handed-off external app.
- Location-based discovery of places and spoken AI narration in English.
- Hands-free operation: no tap is ever required while driving.

**Out of scope (MVP)**
- Android, CarPlay, Apple Watch.
- Our own turn-by-turn navigation or embedded navigation SDK.
- Multi-day itineraries with hotels.
- Bookings, payments, social features.
- Commuter-specific behaviour.
- Narration in languages other than English.

## Decisions

- **Platform.** Decided: iOS only. (2026-10-18, confirmed 2026-11-17)
- **Stack.** Decided: same as PhotoSync/Homeroll: Swift 6, SwiftUI, Swift packages. See [architecture.md](architecture.md) §4. (2026-10-18)
- **Rest stops.** Decided: the app plans stops from the driver's stated driving-time target (e.g. every 4 hours), chosen by the driver's interests. (2026-10-18)
- **Navigation.** Decided: third-party navigation and maps; we do not build turn-by-turn navigation. MVP mechanism: hand off to an external navigation app; embedding a navigation SDK is a possible later step. (2026-10-19)
- **Backend.** Decided: a backend is needed (it holds the AI API key, controls cost, and aggregates data sources). Proposed technology: .NET. (2026-10-18)
- **Data sources.** Decided: OpenStreetMap and Wikipedia/Wikidata are the defaults; the user can enable or disable sources in settings, and more sources will be added as options. Each source sits behind a common interface. (2026-10-18)
- **Driving-time target.** Decided: a planning target with flexibility, not a hard cutoff; stops are chosen within a window around the target (e.g. 3.5 to 4.5 h for a 4 h target), where a good place exists. (2026-10-18, reworded 2026-11-17)
- **Audience.** Decided: long road trips for the MVP; tourists next (higher priority); commuters later. (2026-10-18)
- **Stop choice.** Decided: the app scores candidates by interest and offers a shortlist of options for each stop; the driver chooses one before the trip. While driving, a suggested replacement may be accepted by voice; no tap is ever required while driving. Stop ranking is done in the app, not by the AI model. (2026-11-17)
- **Accounts.** Decided: no user accounts in the MVP. The app identifies itself with a credential it holds, not with an account; the access design is in `architecture.md` §11 (O1). (2026-11-17)
- **Hosting.** Decided: Microsoft Azure App Service (Basic tier) for the backend, Cloudflare for the domain and DNS. (2026-11-17)
- **Trips.** Decided: trips, with their planned stops and the places already spoken, are kept on the phone and survive app restarts. Nothing about trips is stored on the server. (2026-11-17)
- **Narration audio.** Decided: Azure AI Speech, called by the app with a short-lived token from the backend; the built-in voice is the fallback. (2026-11-17)
- **AI service.** Decided: Claude through Microsoft Foundry. (2026-11-17)
- **Prefetch.** Decided: nothing is downloaded before the trip in the MVP. Narration needs signal, and falls back to the built-in voice when the speech service is unreachable. After the MVP, the driver can download the narration for a trip on request. (2026-11-17)
- **Users and storage in the MVP.** Decided: the owner is the only user during the MVP. Trips on the phone have no count limit. After the MVP, trips move to an Azure Storage account. (2026-11-17)
- **Privacy.** Decided: the backend stores no location, route or trip data. Logs contain no location. Any trip history stays on the phone. (2026-11-17)
- **Language.** Decided: English only for the MVP, for narration and UI. (2026-11-17)
- **Map.** Decided: Apple MapKit draws the map and the route inside the app. No Google Maps SDK in the MVP. (2026-11-17)
- **Interest areas and radius.** Decided: a fixed list of about six areas, finalised in `features.md`; the default radius is 10 km, changeable in settings. (2026-11-17)
- **Narration rules.** Decided: rule-based. Speak only about notable places (for example with a Wikipedia article or a heritage tag), with a minimum distance between two spoken places, and never the same place twice in a trip. The exact rules are set in `features.md`. (2026-11-17)

## Open questions

- Hand-off details: which navigation apps to support first, how to pass a multi-stop route (waypoints) to each, and how the app keeps narrating in the background (background location and audio modes, App Store review). Does the driver need to return to our app when a stop is reached?
- Which further data sources to offer beyond the two defaults (candidates: Apple MapKit points of interest, Google Places, Foursquare, Wikivoyage, national heritage registers) and their licences and costs.
- Cost control for AI calls beyond the decided caching (`.claude/rules/dotnet.md`): the rate-limit and daily-ceiling values, and the access design that the rate limits depend on (`architecture.md` §11, O1).
- Which Claude model for narration (through Microsoft Foundry).
- Which neural voice to use (deferred).
- Connectivity: decided for the MVP (see Decisions). After the MVP, the driver can download narration on request.
- The size of the stop window around the driving-time target, and whether the target counts traffic stops.
- Attribution: where OpenStreetMap and Wikipedia credits appear in the app (the licences require it).
- Deferred until the feature needs them: the domain name, the Claude model, the neural voice, and the hand-off details.
- Monetisation: free, subscription, or per-trip? AI and voice costs are per use.
- Safety and legal: driver distraction rules; App Store review of apps that interact while driving; a privacy policy and App Store privacy labels before release.
- Name and App Store check before any public release.

## Repository layout

```
DriveAndGuide/
├── .claude/              # commands, agents and rules for building the project
├── CLAUDE.md             # project instructions for Claude Code
├── spec/
│   ├── documents/        # project documentation (this file lives here)
│   ├── design/features/  # UX screens (SVG) per feature with a user interface
│   └── specifications/   # one folder per feature
└── source/
    ├── Packages/         # Swift packages (logic and tests)
    ├── Backend/          # .NET backend (ASP.NET Core)
    ├── scripts/          # build and check scripts
    └── Spikes/           # throw-away experiments, never imported by production code
```

## Next steps

1. Settle the hand-off details and the data sources to offer.
2. Confirm the stop-choice-by-voice design and the narration rules in `features.md`.
3. Confirm the .NET backend. Its rule file is in place (`.claude/rules/dotnet.md`); its build and test scripts are not yet.
4. Break the MVP into features in [features.md](features.md) and choose the structure in [architecture.md](architecture.md).
