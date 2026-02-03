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

final class ShellStationsSource: PetrolStationsSource {
    
    private let session: URLSession
    private let url: URL
    
    init(session: URLSession) {
        self.session = session
        self.url = URL(string: "https://shellretaillocator.geoapp.me/api/v2/locations/within_bounds?sw[]=18.626924&sw[]=50.890848&ne[]=23.434461&ne[]=60.932352&locale=en_OM&format=json")!
    }
    
    func getAllPetrolStations() async throws(PetrolStationSourceError) -> [PetrolStation] {
        let (data, response) = try await PetrolStationSourceError.uplift {
            try await session.data(from: url)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw .invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw .serverError
        }
        
        guard let responseBody = try? JSONDecoder().decode(ShellResponse.self, from: data) else {
            throw .invalidData
        }
        
        guard responseBody.locations.count > 0 else {
            throw .noData
        }
        
        return responseBody
            .locations
            .filter { $0.isActive }
            .map {
                .init(
                    id: $0.id,
                    brand: "Shell",
                    name: $0.name,
                    location: .init(
                        latitude: $0.latitude,
                        longitude: $0.longitude
                    )
                )
            }
    }
}
