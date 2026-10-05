# oman-petrol-stations

<picture>
  <source srcset="https://github.com/user-attachments/assets/338363b5-8080-4b96-bb3c-92ac6f264ab2" media="(prefers-color-scheme: dark)">
  <source srcset="https://github.com/user-attachments/assets/338363b5-8080-4b96-bb3c-92ac6f264ab2" media="(prefers-color-scheme: light)">
  <img src="https://github.com/user-attachments/assets/338363b5-8080-4b96-bb3c-92ac6f264ab2" alt="oman-petrol-stations-icon" style="width: 20%;">
</picture>


A small Swift command line tool for macOS that downloads location and metadata for every petrol station operated by the three main Omani providers: Oman Oil, Shell, and Al Maha. 
Export results as CSV, KML, or GeoJSON for mapping and offline use.

It fetches station information from public provider sources and normalizes it into easy-to-use formats. I created this tool after a trip to Oman to make road travel safer by knowing where fuel is available. If you find it useful or want features added, feel free to open an issue or a pull request. The tool is lightweight, runs locally, and is intended for personal, offline, or research use.

# Usage
```bash
git clone https://github.com/csanfilippo/oman-petrol-stations.git
cd oman-petrol-stations
swift run oman-petrol-stations --help

OVERVIEW: Fetches petrol stations in Oman and exports them to a file.

This tool downloads station data from multiple providers and serializes it into
a chosen output format (KML, CSV, or GeoJSON)

USAGE: oman-petrol-stations [--output-file-path <output-file-path>] [--format <format>] [--petrol-company-list <petrol-company-list>]

OPTIONS:
  --output-file-path <output-file-path>
                          The path of output file (omit to write to stdout)
  --format <format>       The format of output file (values: csv, kml, geojson;
                          default: kml)
  --petrol-company-list <petrol-company-list>
                          Comma-separated list of petrol companies (default:
                          almaha,oomco,shell)
  --version               Show the version.
  -h, --help              Show help information.
```

# Behaviour

* **Output to stdout.** Omit `--output-file-path` to write the export to stdout; progress and warnings go to stderr, so the output can be piped or redirected safely:
  ```bash
  swift run oman-petrol-stations --format geojson > stations.geojson
  ```
* **Unavailable providers are skipped.** If a provider can't be reached or returns unusable data, it's reported as `skipped` in the summary and the export continues with the others. The tool fails only when every requested provider is unavailable.
* **Invalid stations are dropped.** Stations with unparseable or out-of-range coordinates are skipped with a warning.

# Source of the data

* [Oman Oil](https://oomco.om/station-search)
* [Shell](https://shellretaillocator.geoapp.me/api/v2/locations/within_bounds?sw[]=18.626924&sw[]=50.890848&ne[]=23.434461&ne[]=60.932352&locale=en_OM&format=json)
* [Al Maha](https://www.almaha.com.om/en/map)
