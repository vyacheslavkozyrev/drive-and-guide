---
description: Optional research. No argument audits the feature list; with a feature it investigates unknowns; with `F-02 S#` it runs a technical spike.
argument-hint: [F-XX [topic]]   e.g. /research F-09   or   /research F-02 S3
---

Arguments: `$ARGUMENTS`

You are acting as a senior engineer and product owner doing focused discovery. Ask the user questions **one at a time**, each with 2–4 answer options and the recommended option first. Never invent scope: every finding is grounded in the project documents, an official source, or a measurement.

## Mode selection

- **No arguments** → Project mode.
- **`F-XX`** (accept `F-09`, `09` or `9`; normalise) → Feature mode. The feature must exist in `spec/documents/features.md`.
- **`F-02 S#`** (S1–S8) → Spike mode.

Before anything else: the current branch must be `main`. If it is not, stop and tell the user.

## Project mode

1. Read every file in `spec/documents/`.
2. Audit `features.md` against `idea.md` and `architecture.md`: every idea-level decision has an owning feature; no feature is missing a "Done when"; dependencies are consistent; the architecture's spikes (§9) are each owned by a feature.
3. Ask up to 3 questions, only where the answer would change the feature list.
4. Report gaps and propose specific edits. Edit `features.md` only after the user approves. Never edit `idea.md` in this mode.
5. Commit approved changes: `docs(project): <summary>`.

## Feature mode

1. Read the feature entry, the sections of `idea.md` and `architecture.md` it touches, and any related research.
2. List the **technical unknowns** that would change the specification or plan (Apple APIs such as MapKit, speech and location; platform limits; library behaviour; the .NET backend's contract with the app).
3. Investigate each with WebSearch/WebFetch on official sources first. Label each finding **verified** (source cited) or **assumption**.
4. Ensure the spec folder `spec/specifications/F-XX-<slug>/` exists (slug = kebab-case feature name). If not, create it by copying `spec/specifications/F-00-template/`. In its `progress.md`, set Research to ✅ Complete with today's date.
5. Write `research.md` in that folder: unknowns, findings (with sources), decisions taken, remaining open questions, and the effect on stories or plan.
6. If a finding contradicts a project document, list it and ask the user whether to update the document; do not change decisions silently.
7. Commit: `research(F-XX): <summary>`.

## Spike mode (`F-02 S#`)

Spikes are throw-away experiments that prove or disprove an assumption. They are exempt from review and tests, and their code is never imported by production code.

1. Read the spike's question, pass criterion and fallback from `spec/documents/architecture.md` §9.
2. Create `source/Spikes/S#-<slug>/` with the smallest program that answers the question. Run it as far as possible from here.
3. When a step needs the user (a real device, a drive, a particular network), give exact numbered instructions, then ask the user to report what happened.
4. Write the result note `spec/specifications/F-02-technical-spikes/S#-<slug>.md` (create the folder from the template if needed): question, pass criterion, method, measurements, **result** (pass / fail / partial), **decision** (keep the design or adopt the named fallback), and which documents change.
5. Update `architecture.md` where the result changes a decision or fallback (spike table, risks). Ask before changing a decision the user already confirmed.
6. Commit: `spike(F-02): S# <title>`.

## Finish

Summarise what was learned in a few lines and suggest the next command (usually `/specify F-XX`).
