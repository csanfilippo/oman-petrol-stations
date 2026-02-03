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

import Testing
import Replay
import Foundation

@testable import oman_petrol_stations

@Suite("AlMahaStationsSourceDetails", .playbackIsolated(replaysFrom: Bundle.module))
struct AlMahaStationsSourceTests {
    
    @Test(
        "should return the correct stations from HTML",
        .replay(
            "fetchAlMahaStations",
            matching: [.path, .method],
            filters: [],
            scope: .test
        )
    )
    func happyPath() async throws {
        let source = AlMahaStationsSource(session: Replay.session)
        
        let stations = try await source.getAllPetrolStations()
        
        #expect(stations.count == 2)
        
        // Station 1
        let s1 = try #require(stations.first { $0.name == "Station 1" })
        #expect(s1.brand == "Al Maha")
        #expect(s1.location.latitude == 23.588)
        #expect(s1.location.longitude == 58.382)
        
        // Station 2
        let s2 = try #require(stations.first { $0.name == "Station 2" })
        #expect(s2.location.latitude == 24.0)
        #expect(s2.location.longitude == 57.0)
    }
    
    @Test(
         "should throw error on server failure",
         .replay(
             stubs: [
                 .post(
                     "https://www.almaha.com.om/en/map/",
                     500,
                     [:],
                     { "" }
                 )
             ],
             matching: [.path],
             scope: .test
         )
     )
    func serverError() async throws {
        let source = AlMahaStationsSource(session: Replay.session)
        
        await #expect(throws: PetrolStationSourceError.serverError) {
            try await source.getAllPetrolStations()
        }
    }
}
