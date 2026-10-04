# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Swift command-line tool (macOS 26+, Swift 6 language mode) that fetches petrol station
locations from three Omani providers — Oman Oil (oomco), Shell, and Al Maha — and exports
them as KML, CSV, or GeoJSON.

## Commands

```bash
swift build                          # build
swift run oman-petrol-stations --help
swift run oman-petrol-stations --output-file-path stations.kml --format kml
swift run oman-petrol-stations --format csv --petrol-company-list shell,oomco   # omit --output-file-path to write to stdout
swift run oman-petrol-stations --format geojson                                 # --format: kml (default), csv, geojson

swift test                                                              # run all tests
swift test --filter ShellStationsSourceTests                           # run one suite
swift test --filter ShellStationsSourceTests/parsesActiveStationsFromResponse  # run one test
```

Tests use **Swift Testing** (`import Testing`, `@Suite`/`@Test`/`#expect`), not XCTest.

## Architecture

Pipeline: `oman_petrol_stations` (ArgumentParser entry point) → `StationExporter.export` →
fan-out fetch across providers → merge → serialize → `Output`.

- **`StationSource/`** — one `PetrolStationsSource` conformer per provider (`ShellStationsSource`,
  `OmanOilStationsSource`, `AlMahaStationsSource`), each owning its own endpoint URL and
  response parsing (JSON decode for Shell/Oman Oil, HTML scraping via Kanna for Al Maha).
  All conformers are `Sendable` and share request/error handling through the
  `performRequest` protocol extension in `PetrolStationsSource.swift`, which maps transport
  and HTTP-status failures to `PetrolStationSourceError` (`.noData`, `.invalidData`,
  `.invalidResponse`, `.serverError`). A row that fails to parse or whose coordinates are
  out of range is dropped with a `stderr` warning rather than failing the whole fetch — an
  empty result *after* filtering is what throws `.noData`.
- **`PetrolStation.Location`** guards its own invariant: its failable init rejects
  latitudes outside -90...90 and longitudes outside -180...180 (NaN/infinity included).
  Sources build locations through it, so downstream code (merge, serializers) can trust
  every `PetrolStation` it receives.
  `PetrolCompany.makeSource(session:)` (in `StationExporter.swift`) is the only place that
  maps a company to its source; add a new provider there plus a new `PetrolStationsSource`
  file.
- **`Utils/FetchAll.swift`** — `fetchAllFrom { ... }` is a result-builder DSL
  (`@FetchAllStationsBuilder`) over a list of sources, run concurrently via
  `withThrowingTaskGroup`; any source's thrown error propagates and cancels the rest.
- **`Utils/Merge.swift`** — `[[PetrolStation]].merge()` unions per-source results into a
  single deduplicated list using `PetrolStation: Hashable` + `OrderedSet`, preserving
  first-seen order across providers.
- **`Serialization/`** — `PetrolStationSerializer` (`KMLPetrolStationSerializer`,
  `CSVPetrolStationSerializer`, `GeoJSONPetrolStationSerializer`) turns `[PetrolStation]`
  into a format-specific string — GeoJSON is built with the **sfera** package as a
  `FeatureCollection` of `Point` features with `stationName`/`brand` properties;
  `serializerFor(_:)` is the factory keyed on `SerializationFormat`. `Output` (`File`,
  `Stdout`) abstracts *where* the string goes; `output(for:)` in `OutputFactory.swift`
  picks `Stdout` when `--output-file-path` is omitted.
- **`StationExporter`** is the only place that wires fetch → merge → serialize → output
  together and prints progress; it takes `Set<PetrolCompany>`, a `SerializationFormat`, and
  an `Output` so it can be tested/composed without touching the CLI layer. It owns the
  partial-export policy: each source is wrapped in `SkippingUnavailableSource`, which turns
  a `PetrolStationSourceError` into an empty result and records it, so the summary prints
  `<Company>: skipped (<error>)`; only when *every* source fails does it throw
  `StationExportError.noSourceAvailable` (nothing is written). `fetchAllFrom` itself stays
  fail-fast.

## Testing conventions

- Provider sources (`ShellStationsSourceTests`, `OmanOilStationsSourceTests`,
  `AlMahaStationsSourceTests`) use the **Replay** package to stub network calls: either
  recorded `.har` fixtures under `Tests/oman-petrol-stations-tests/Replays/` (via
  `.replay("name", ...)`) or inline `.replay(stubs: [.get(...)], ...)` responses. Suites are
  marked `.playbackIsolated(replaysFrom: Bundle.module)` and pass `Replay.session` into the
  source's `session:` initializer instead of `URLSession.shared`.
- `FetchAllTests` and `MergeTests` use hand-written `DummySource`/`ThrowingSource` fakes
  conforming to `PetrolStationsSource` rather than network stubbing, since they're testing
  orchestration, not parsing.
- Serializer tests assert on the exact emitted string (KML/CSV), including escaping and
  empty-list edge cases. GeoJSON tests instead decode the output back into sfera's
  `GeoJSON` and compare values, since `JSONEncoder` key order isn't stable.
- Build test locations with `PetrolStation.Location.fixture(latitude:longitude:)`
  (`PetrolStationFixtures.swift`), which traps on invalid coordinates — the real init is
  failable and can't be used in `@Test(arguments:)` lists.
