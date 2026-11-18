# DriveAndGuide — Idea

Status: draft for review. Written 2026-10-18 from the first idea discussion.

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

1. **Trip setup:** destination, maximum driving time before a rest (default e.g. 4 h), interest radius, interest areas (history, nature, architecture, food, ...).
2. **Trip plan:** a route with a rest stop planned near each driving-limit mark. For each stop the app suggests candidates that match the driver's interests, near the route, and the driver picks or accepts one.
3. **Navigation:** the route and turn-by-turn guidance come from a third-party navigation and maps provider; we do not build our own navigation. For the MVP the app hands the route off to an external navigation app (Apple Maps, Google Maps or Waze) and keeps running in the background to narrate.
4. **Narration while driving:** from the current location, find notable places within the interest radius, rank them by the driver's interests, and read out an AI-written fact summary. Speak only when it is worth it.
5. **Stop guidance:** approaching a planned stop, tell the driver what is there and why it is worth the stop.

## Product direction

- **Primary goal:** make long drives safer and more enjoyable by pairing necessary rest stops with interesting places.
- **MVP:** iOS only. Long road trips. Trip planning by driving limit and interests, route on a map with navigation, spoken facts about nearby places. [Exact scope to be set in `features.md`.]
- **Post-MVP:** tourist features (multi-day trips, richer content, saved trips), then commuter features (non-repeating content on familiar routes). CarPlay. Android. Offline use.

## Differentiation

See [market-research.md](market-research.md). Narration of nearby places is already offered by several apps (WikiTrip, RoadWhisper, Narrando, AI TourMate and others), so narration alone is not the differentiator. The proposed differentiators are:

1. **The route is planned around the driver's rest rhythm.** The stop after N hours is chosen for interest, not by chance. No app found offers this as a core input.
2. **Interest-driven selection** of both stops and narration.
3. **Restraint:** it speaks only when there is something worth saying, never repeats, stays quiet at busy moments.
4. **Facts that can be trusted:** narration is based on retrieved source data (map and encyclopedia sources) rather than invented by the model, and says where the facts come from.

## Scope

**In scope (MVP)**
- Destination and driving-limit input; interest areas; interest radius.
- Route planning with rest stops at the driving limit.
- Map display of the planned trip and stops in our app; turn-by-turn guidance by a handed-off external app.
- Location-based discovery of places and spoken AI narration.
- Hands-free operation: no required taps while driving.

**Out of scope (MVP)**
- Android, CarPlay, Apple Watch.
- Our own turn-by-turn navigation or embedded navigation SDK.
- Multi-day itineraries with hotels.
- Bookings, payments, social features.
- Commuter-specific behaviour.

## Decisions

- **Platform.** Decided: iOS first. (2026-10-18)
- **Stack.** Decided: same as PhotoSync/Homeroll: Swift 6, SwiftUI, Swift packages. See [architecture.md](architecture.md) §4. (2026-10-18)
- **Rest stops.** Decided: the app plans stops from the driver's stated driving limit (e.g. every 4 hours), chosen by the driver's interests. (2026-10-18)
- **Navigation.** Decided: third-party navigation and maps; we do not build turn-by-turn navigation. MVP mechanism: hand off to an external navigation app; embedding a navigation SDK is a possible later step. (2026-10-19)
- **Backend.** Decided: a backend is needed (it holds the AI API key, controls cost, and aggregates data sources). Proposed technology: .NET. (2026-10-18)
- **Data sources.** Decided: OpenStreetMap and Wikipedia/Wikidata are the defaults; the user can enable or disable sources in settings, and more sources will be added as options. Each source sits behind a common interface. (2026-10-18)
- **Driving limit.** Decided: a planning target with flexibility, not a hard cutoff; stops are chosen within a window around the limit (e.g. 3.5 to 4.5 h for a 4 h limit), where a good place exists. (2026-10-18)
- **Audience.** Decided: long road trips for the MVP; tourists next (higher priority); commuters later. (2026-10-18)

## Open questions

- Hand-off details: which navigation apps to support first, how to pass a multi-stop route (waypoints) to each, and how the app keeps narrating in the background (background location and audio modes, App Store review). Does the driver need to return to our app when a stop is reached?
- Which further data sources to offer beyond the two defaults (candidates: Apple MapKit points of interest, Google Places, Foursquare, Wikivoyage, national heritage registers) and their licences and costs.
- Backend hosting and cost control for AI calls (rate limits per user, caching of generated narration), and whether the MVP needs user accounts.
- Which Claude model for narration, and for stop ranking.
- Text to speech: Apple's built-in voices or a cloud voice?
- Connectivity: how much to prepare before the trip versus fetch while driving, given poor signal on some roads.
- The size of the stop window around the driving limit, and whether the limit counts traffic stops.
- Monetisation: free, subscription, or per-trip? AI and voice costs are per use.
- Safety and legal: driver distraction rules; App Store review of apps that interact while driving.
- Name and App Store check before any public release.

## Repository layout

```
DriveAndGuide/
├── spec/
│   ├── documents/        # project documentation (this file lives here)
│   └── specifications/   # one folder per feature
└── source/               # application source code
```

## Next steps

1. Review and correct this document.
2. Settle the hand-off details and the data sources to offer.
3. Confirm the .NET backend (this adds a second technology beside the Swift stack; it needs its own rule file and build scripts).
4. Break the MVP into features in [features.md](features.md) and choose the structure in [architecture.md](architecture.md).
