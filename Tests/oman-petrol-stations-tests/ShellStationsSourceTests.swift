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
        "parses active stations from response",
        .replay("fetchShellStations", matching: [.path], filters: [], scope: .test)
    )
    func parsesActiveStationsFromResponse() async throws {
        let source = ShellStationsSource(session: Replay.session)

        let stations = try await source.getAllPetrolStations()

        #expect(stations.count == 2)
        #expect(stations.allSatisfy { $0.brand == .shell })
        #expect(stations.map(\.name).contains("SAIH AL RAWL SS"))
        #expect(stations.map(\.name).contains("ZAMAIM SS"))
    }

    @Test(
        "excludes inactive stations from results",
        .replay(
            stubs: [
                .get(
                    "https://shellretaillocator.geoapp.me/api/v2/locations/within_bounds",
                    200,
                    ["Content-Type": "application/json"],
                    { """
                    {"locations":[
                      {"id":"1","name":"Active","lat":23.0,"lng":58.0,"inactive":false},
                      {"id":"2","name":"Inactive","lat":24.0,"lng":59.0,"inactive":true}
                    ]}
                    """ }
                )
            ],
            matching: [.path], filters: [], scope: .test
        )
    )
    func excludesInactiveStations() async throws {
        let source = ShellStationsSource(session: Replay.session)

        let stations = try await source.getAllPetrolStations()

        #expect(stations.count == 1)
        #expect(stations[0].name == "Active")
    }

    @Test(
        "throws invalidData on malformed response body",
        .replay(
            stubs: [
                .get(
                    "https://shellretaillocator.geoapp.me/api/v2/locations/within_bounds",
                    200,
                    ["Content-Type": "application/json"],
                    { "" }
                )
            ],
            matching: [.path], filters: [], scope: .test
        )
    )
    func throwsInvalidDataOnMalformedResponse() async throws {
        let source = ShellStationsSource(session: Replay.session)

        await #expect(throws: PetrolStationSourceError.invalidData) {
            try await source.getAllPetrolStations()
        }
    }

    @Test(
        "throws noData when locations array is empty",
        .replay(
            stubs: [
                .get(
                    "https://shellretaillocator.geoapp.me/api/v2/locations/within_bounds",
                    200,
                    ["Content-Type": "application/json"],
                    { "{\"locations\":[]}" }
                )
            ],
            matching: [.path], filters: [], scope: .test
        )
    )
    func throwsNoDataWhenLocationsEmpty() async throws {
        let source = ShellStationsSource(session: Replay.session)

        await #expect(throws: PetrolStationSourceError.noData) {
            try await source.getAllPetrolStations()
        }
    }

    @Test(
        "throws serverError on 5xx response",
        .replay(
            stubs: [
                .get(
                    "https://shellretaillocator.geoapp.me/api/v2/locations/within_bounds",
                    500,
                    [:],
                    { "" }
                )
            ],
            matching: [.path], filters: [], scope: .test
        )
    )
    func throwsServerErrorOn5xxResponse() async throws {
        let source = ShellStationsSource(session: Replay.session)

        await #expect(throws: PetrolStationSourceError.serverError) {
            try await source.getAllPetrolStations()
        }
    }
}
