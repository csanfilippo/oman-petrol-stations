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
import Foundation

@testable import oman_petrol_stations

private struct DummySource: PetrolStationsSource {
    let injectedStations: [PetrolStation]

    func getAllPetrolStations() async throws(PetrolStationSourceError) -> [PetrolStation] {
        injectedStations
    }
}

private struct ThrowingSource: PetrolStationsSource {
    let error: PetrolStationSourceError

    func getAllPetrolStations() async throws(PetrolStationSourceError) -> [PetrolStation] {
        throw error
    }
}

@Suite("FetchAll")
struct FetchAllTests {

    @Test("collects stations from all provided sources")
    func collectsStationsFromAllSources() async throws {
        let source1 = DummySource(injectedStations: [
            .init(brand: .shell, name: "ShellStation", location: .init(latitude: 2, longitude: 2))
        ])
        let source2 = DummySource(injectedStations: [
            .init(brand: .oomco, name: "OmanStation", location: .init(latitude: 22, longitude: 22))
        ])

        let stations = try await fetchAllFrom {
            source1
            source2
        }

        #expect(stations == [
            .init(brand: .shell, name: "ShellStation", location: .init(latitude: 2, longitude: 2)),
            .init(brand: .oomco, name: "OmanStation", location: .init(latitude: 22, longitude: 22))
        ])
    }

    @Test("returns empty array when all sources are empty")
    func returnsEmptyWhenAllSourcesEmpty() async throws {
        let stations = try await fetchAllFrom {
            DummySource(injectedStations: [])
            DummySource(injectedStations: [])
        }
        #expect(stations.isEmpty)
    }

    @Test("error thrown by any source propagates out")
    func errorFromSourcePropagates() async throws {
        let good = DummySource(injectedStations: [
            .init(brand: .shell, name: "S", location: .init(latitude: 1, longitude: 1))
        ])
        let failing = ThrowingSource(error: .serverError)

        await #expect(throws: PetrolStationSourceError.serverError) {
            try await fetchAllFrom {
                good
                failing
            }
        }
    }

    @Test(
        "only sources that pass the condition are fetched",
        arguments: [
            (true,  [PetrolStation(brand: .shell, name: "ShellStation", location: .init(latitude: 2, longitude: 2))]),
            (false, [
                PetrolStation(brand: .shell, name: "ShellStation", location: .init(latitude: 2, longitude: 2)),
                PetrolStation(brand: .oomco, name: "OmanStation",  location: .init(latitude: 22, longitude: 22))
            ])
        ]
    )
    func onlyConditionallIncludedSourcesAreFetched(_ include: Bool, _ expected: [PetrolStation]) async throws {
        let source1 = DummySource(injectedStations: [
            .init(brand: .shell, name: "ShellStation", location: .init(latitude: 2, longitude: 2))
        ])
        let source2 = DummySource(injectedStations: [
            .init(brand: .oomco, name: "OmanStation", location: .init(latitude: 22, longitude: 22))
        ])

        let stations = try await fetchAllFrom {
            if include {
                source1
            } else {
                source1
                source2
            }
        }

        #expect(stations == expected)
    }

    @Test(
        "source guarded by if is excluded when condition is false",
        arguments: [
            (true,  [PetrolStation(brand: .shell, name: "ShellStation", location: .init(latitude: 2, longitude: 2))]),
            (false, [PetrolStation]())
        ]
    )
    func sourceGuardedByIfIsExcludedWhenConditionFalse(_ include: Bool, _ expected: [PetrolStation]) async throws {
        let source = DummySource(injectedStations: [
            .init(brand: .shell, name: "ShellStation", location: .init(latitude: 2, longitude: 2))
        ])

        let stations = try await fetchAllFrom {
            if include { source }
        }

        #expect(stations == expected)
    }
}
