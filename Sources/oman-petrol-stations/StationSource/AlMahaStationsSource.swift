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

import Kanna
import Foundation

final class AlMahaStationsSource: PetrolStationsSource {
    
    private let session: URLSession
    private let url: URL
    
    init(session: URLSession) {
        self.session = session
        self.url = URL(string: "https://www.almaha.com.om/en/map/")!
    }
    
    func getAllPetrolStations() async throws(PetrolStationSourceError) -> [PetrolStation] {
        var request = URLRequest(url: self.url)
        
        request.httpMethod = "POST"
        
        guard let (data, response) = try? await session.data(for: request) else {
            throw .invalidResponse
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw .invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw .serverError
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw .invalidData
        }
        
        guard let document = try? HTML(html: html, encoding: .utf8) else {
            throw .invalidData
        }
        
        var stations: [PetrolStation] = []
        
        for station in document.css("div.products-list") {
            
            let nameSet = station.xpath(".//h5")
            
            guard let loadMapFunc = station["onclick"] else {
                continue
            }
            
            guard let rawName = nameSet.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !rawName.isEmpty else {
                continue
            }
            
            guard let (latitude, longitude) = locationFrom(onClick: loadMapFunc) else {
                continue
            }
            
            
            stations.append(.init(
                id: "",
                brand: "Al Maha",
                name: rawName,
                location: .init(latitude: latitude, longitude: longitude)
                )
            )
        }
        
        return stations
    }
    
    private func locationFrom(onClick: String) -> (latitude: Double, longitude: Double)? {
        
        guard let firstTick = onClick.firstIndex(where: { character in character == "'" }) else {
            return nil
        }
        
        guard let lastTick = onClick.lastIndex(where: { character in character == "'" }) else {
            return nil
        }
        
        var substring = String(onClick[firstTick...lastTick])
        
        substring.removeAll(where: { char in char == "'"})
        
        let split = substring
            .split(whereSeparator: {$0 == ","})
            .map({ String($0).trimmingCharacters(in: .whitespacesAndNewlines) })
            .filter { $0.count > 0 }
            .compactMap { Double($0) }
        
        guard split.count >= 2 else {
            return nil
        }
        
        return (latitude: split[0], longitude: split[1])
    }
}
