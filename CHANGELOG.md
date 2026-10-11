# Changelog

All notable changes to `oman-petrol-stations` are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## 1.4.0 – 2026-10-12

### Added

- `--require-all-sources` makes the export fail, writing nothing, when any requested provider is unavailable, instead of exporting the others. Use it for unattended runs whose output is published, so a provider outage never replaces a complete export with a partial one.

## 1.3.1 – 2026-10-05

### Fixed

- Oman Oil stations are fetched from `oomco.om` directly, instead of following the redirect from the old `www.oomco.com` domain.

## 1.3.0 – 2026-10-05

### Added

- `geojson` output format (`--format geojson`): a `FeatureCollection` of `Point` features with `stationName` and `brand` properties.

### Changed

- An unavailable provider is skipped and reported as `skipped (<error>)` in the summary instead of failing the whole export. The tool fails only when every requested provider is unavailable.
- A provider that returns no usable stations is reported as unavailable instead of contributing an empty result.
- Progress messages go to stderr, so exporting to stdout (`> stations.geojson`) produces clean output.
- Building from source requires Swift 6.4.

### Fixed

- Stations with out-of-range coordinates are dropped with a warning.

## 1.2.1 – 2026-06-06

### Changed

- Bump `swift-argument-parser` 1.7.1 → 1.8.2, `swift-collections` 1.4.1 → 1.5.1 and `swift-log` 1.12.0 → 1.13.1.

## 1.2.0 – 2026-05-01

### Fixed

- KML exports place stations correctly: `<coordinates>` is written in `longitude,latitude` order, as KML requires, instead of `latitude,longitude`.
- Brand names with special characters are no longer double-escaped in KML descriptions (`&` became `&amp;amp;`).
- `--help` shows the default `--petrol-company-list` in alphabetical order instead of a random one.
- The Al Maha source fails with `.noData` when the page has no recognisable stations, instead of silently returning an empty list.

## 1.1.1 – 2026-02-03

### Fixed

- Typo in the Oman Oil name.
- Petrol station sources are more robust.

## 1.1.0 – 2026-01-22

### Added

- `--petrol-company-list` selects which petrol companies to fetch.

### Changed

- Serializers capitalize station names.

## 1.0.2 – 2026-01-22

### Fixed

- The Oman Oil source no longer always returns an empty list of stations.

## 1.0.1 – 2026-01-21

### Fixed

- KML coordinates are written correctly.

## 1.0.0 – 2026-01-20

Initial release: fetches the stations of Oman Oil, Shell and Al Maha and exports them as KML or CSV.
