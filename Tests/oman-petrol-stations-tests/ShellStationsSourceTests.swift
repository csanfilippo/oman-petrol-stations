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


@Suite("ShellStationsSource", .playbackIsolated(replaysFrom: Bundle.module))
struct ShellStationsSourceTests {
    
    @Test(
        "should return the correct stations",
            .replay(
                "fetchShellStations",
                matching: [.path],
                filters: [],
                scope: .test)
    )
    func happyPath() async throws {
        let source = ShellStationsSource(session: Replay.session)
        
        let stations = try await source.getAllPetrolStations()
        
        let setOfIds = stations.uniqueValues(of: \.id)
        let setOfNames = stations.uniqueValues(of: \.name)
        
        #expect(stations.count == 2)
        
        #expect(setOfIds.contains("12662228"))
        #expect(setOfIds.contains("12540496"))
        
        #expect(setOfNames.contains("SAIH AL RAWL SS"))
        #expect(setOfNames.contains("ZAMAIM SS"))
        
    }
    
    @Test(
        "should throw an exception in case of invalid data",
            .replay(
                stubs: [
                    .get(
                        "https://shellretaillocator.geoapp.me/api/v2/locations/within_bounds",
                        200,
                        ["Content-Type": "application/json"],
                        { "" }
                    )
                ],
                matching: [.path],
                filters: [],
                scope: .test
            )
    )
    
    func invalidData() async throws {
        let source = ShellStationsSource(session: Replay.session)
        
        await #expect(throws: PetrolStationSourceError.invalidData) {
            try await source.getAllPetrolStations()
        }
    }
    
    @Test("should throw an exception in case of no data",
          .replay(
            stubs: [
                .get(
                    "https://shellretaillocator.geoapp.me/api/v2/locations/within_bounds",
                    200,
                    ["Content-Type": "application/json"],
                    { "{\"locations\":[]}" }
                )
            ],
            matching: [.path],
            filters: [],
            scope: .test
          ))
    func emptyArray() async throws {
        let source = ShellStationsSource(session: Replay.session)
        
        await #expect(throws: PetrolStationSourceError.noData) {
            try await source.getAllPetrolStations()
        }
    }
}

private extension Array where Element == PetrolStation {
    func uniqueValues<T>(of keyPath: KeyPath<Element, T>) -> Set<T> {
        Set(map { $0[keyPath: keyPath] })
    }
}
