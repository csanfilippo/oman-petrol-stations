# oman-petrol-stations

A small Swift command line tool for macOS that downloads location and metadata for every petrol station operated by the three main Omani providers: Oman Oil, Shell, and Al Maha. 
Export results as CSV or KML for mapping and offline use.

It fetches station information from public provider sources and normalizes it into easy-to-use formats. I created this tool after a trip to Oman to make road travel safer by knowing where fuel is available. If you find it useful or want features added, feel free to open an issue or a pull request. The tool is lightweight, runs locally, and is intended for personal, offline, or research use.

# Usage
```bash
git clone https://github.com/csanfilippo/oman-petrol-stations.git
cd oman-petrol-stations
swift run oman-petrol-stations --help

OVERVIEW: Fetches petrol stations in Oman and exports them to a file.

This tool downloads station data from multiple providers and serializes it into a chosen output format (KML or CSV). Use --format to select the
format and --output-file-path to specify where to save the file.

USAGE: oman-petrol-stations --output-file-path <output-file-path> [--format <format>]

OPTIONS:
  --output-file-path <output-file-path>
                          The path of output file
  --format <format>       The format of output file (values: csv, kml; default: kml)
  --version               Show the version.
  -h, --help              Show help information.
```

# Source of the data

* [Oman Oil](https://www.oomco.com/station-search)
* [Shell](https://shellretaillocator.geoapp.me/api/v2/locations/within_bounds?sw[]=18.626924&sw[]=50.890848&ne[]=23.434461&ne[]=60.932352&locale=en_OM&format=json)
* [Al Maha](https://www.almaha.com.om/en/map)
