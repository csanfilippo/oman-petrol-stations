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

private struct ShellStation: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case latitude = "lat"
        case longitude = "lng"
        case inactive
    }
    
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let inactive: Bool
    
    var isActive: Bool { !inactive }
}

private struct ShellResponse: Decodable {
    let locations: [ShellStation]
}

struct ShellStationsSource: PetrolStationsSource {
    
    private let session: URLSession
    private let url: URL
    
    init(session: URLSession) {
        self.session = session
        self.url = URL(string: "https://shellretaillocator.geoapp.me/api/v2/locations/within_bounds?sw[]=18.626924&sw[]=50.890848&ne[]=23.434461&ne[]=60.932352&locale=en_OM&format=json")!
    }
    
    func getAllPetrolStations() async throws(PetrolStationSourceError) -> [PetrolStation] {
        let request = URLRequest(url: url)
        let data = try await performRequest(request, session: session)

        guard let responseBody = try? JSONDecoder().decode(ShellResponse.self, from: data) else {
            throw .invalidData
        }

        guard !responseBody.locations.isEmpty else {
            throw .noData
        }

        let stations = responseBody.locations
            .filter { $0.isActive }
            .compactMap { station -> PetrolStation? in
                guard let location = PetrolStation.Location(latitude: station.latitude, longitude: station.longitude) else {
                    fputs("warning: skipping Shell station with out-of-range coordinates: id=\(station.id) lat=\(station.latitude) lng=\(station.longitude)\n", stderr)
                    return nil
                }
                return PetrolStation(brand: .shell, name: station.name, location: location)
            }

        return stations
    }
}
