/*
 MIT License

 Copyright (c) 2026 Calogero Sanfilippo

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import Foundation

enum SerializationFormat {
    case csv
    case kml
}

protocol PetrolStationSerializer {
    func save(stations: [PetrolStation], into: some Storage) throws
}

func serializerFor(_ format: SerializationFormat) -> any PetrolStationSerializer {
    switch format {
    case .csv:
        CSVPetrolStationSerializer()
    case .kml:
        KMLPetrolStationSerializer()
    }
}

final class KMLPetrolStationSerializer: PetrolStationSerializer {
    func save(stations: [PetrolStation], into storage: some Storage) throws {
        
        let header = """
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <kml xmlns=\"http://www.opengis.net/kml/2.2\">
          <Document>
            <name>Petrol Stations</name>
        """

        let footer = """
          </Document>
        </kml>
        """
        
        guard stations.isEmpty == false else {
            
            let text = header + "\n" + footer
            try storage.save(text)
            return
        }

        let placemarks = stations.map { station -> String in
            let name = escape(station.name.capitalized(with: .current))
            let brand = escape(station.brand)
            let description = "Brand: \(brand)"
            let lon = station.location.longitude
            let lat = station.location.latitude
            return """
                <Placemark>
                    <name>\(name)</name>
                    <description>\(escape(description))</description>
                    <Point>
                        <coordinates>\(lat),\(lon)</coordinates>
                    </Point>
                </Placemark>
            """
        }.joined(separator: "\n")

        let text = [header, placemarks, footer].joined(separator: "\n")
        
        try storage.save(text)
    }
    
    private func escape(_ s: String) -> String {
        var out = s
        out = out.replacingOccurrences(of: "&", with: "&amp;")
        out = out.replacingOccurrences(of: "<", with: "&lt;")
        out = out.replacingOccurrences(of: ">", with: "&gt;")
        out = out.replacingOccurrences(of: "\"", with: "&quot;")
        out = out.replacingOccurrences(of: "'", with: "&apos;")
        return out
    }
}

final class CSVPetrolStationSerializer: PetrolStationSerializer {
    func save(stations: [PetrolStation], into storage: some Storage) throws {
        let header = "Name,Brand,Latitude,Longitude"
        
        guard stations.isEmpty == false else {
            try storage.save(header)
            return
        }
        
        let content = stations.map { station in
            [
                station.name.capitalized(with: .current),
                station.brand,
                format(station.location.latitude),
                format(station.location.longitude)
            ].joined(separator: ",")
        }.joined(separator: "\n")
        
        let text = [header, content].joined(separator: "\n")
        
        try storage.save(text)
    }
    
    @inline(__always)
    private func format(_ value: Double) -> String { String(format: "%.6f", value) }
}
