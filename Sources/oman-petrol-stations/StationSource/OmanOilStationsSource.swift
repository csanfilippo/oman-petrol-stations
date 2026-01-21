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

import altai
import Foundation

private struct OmanOilPetrolStation: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case latitude = "locX"
        case longitude = "locY"
    }
    
    let id: Int
    let name: String
    let latitude: String
    let longitude: String
}

final class OmanOilStationsSource: PetrolStationsSource {
    
    private let session: URLSession
    private let source: URL
    
    init(session: URLSession) {
        self.session = session
        self.source = URL(string: "https://www.oomco.com/station-search")!
    }
    
    func getAllPetrolStations() async throws(PetrolStationSourceError) -> [PetrolStation] {
        
        let (data, _) = try await PetrolStationSourceError.uplift {
            try await self.session.data(from: self.source)
        }
        
        let stations: [OmanOilPetrolStation] = try PetrolStationSourceError.uplift {
            try JSONDecoder().decode([OmanOilPetrolStation].self, from: data)
        }
        
        return stations.compactMap { station -> PetrolStation? in
            guard let latitude = Double(station.latitude), let longitude = Double(station.longitude) else {
                return nil
            }
            
            return .init(id: String(describing: station.id), brand: "Omain Oil", name: station.name, location: .init(latitude: latitude, longitude: longitude))
        }
    }
    
    
}
