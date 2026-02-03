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

@Suite("OmanOilStationsSourceDetails", .playbackIsolated(replaysFrom: Bundle.module))
struct OmanOilStationsSourceTests {

    @Test(
        "should return the correct stations",
        .replay(
            stubs: [
                .get(
                    "https://www.oomco.com/station-search",
                    200,
                    ["Content-Type": "application/json"],
                    {
                        """
                        [
                          {
                            "id": 1,
                            "name": "Station 1",
                            "locX": "23.61388",
                            "locY": "58.5922"
                          },
                          {
                            "id": 2,
                            "name": "Station 2",
                            "locX": "23.58800",
                            "locY": "58.38200"
                          }
                        ]
                        """
                    }
                )
            ],
            matching: [.path],
            scope: .test
        )
    )
    func happyPath() async throws {
        let source = OmanOilStationsSource(session: Replay.session)

        let stations = try await source.getAllPetrolStations()

        #expect(stations.count == 2)
        
        let first = try #require(stations.first { $0.id == "1" })
        #expect(first.name == "Station 1")
        #expect(first.brand == "Oman Oil")
        #expect(first.location.latitude == 23.61388)
        #expect(first.location.longitude == 58.5922)
    }

    @Test(
        "should throw an exception in case of invalid data",
        .replay(
            stubs: [
                .get(
                    "https://www.oomco.com/station-search",
                    200,
                    ["Content-Type": "application/json"],
                    { "{ \"invalid\": \"json\" }" }
                )
            ],
            matching: [.path],
            scope: .test
        )
    )
    func invalidData() async throws {
        let source = OmanOilStationsSource(session: Replay.session)

        await #expect(throws: PetrolStationSourceError.self) {
            try await source.getAllPetrolStations()
        }
    }
}
