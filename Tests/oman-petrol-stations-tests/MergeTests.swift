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

@Suite("Merge")
struct MergeTests {

    @Test("merging empty arrays produces an empty result")
    func emptyArraysProduceEmptyResult() {
        let merged = [[PetrolStation](), []].merge()
        #expect(merged.isEmpty)
    }

    @Test("single array is returned as-is")
    func singleArrayReturnedAsIs() {
        let stations: [PetrolStation] = [
            .init(brand: .shell, name: "Shell1", location: .init(latitude: 1, longitude: 1)),
            .init(brand: .shell, name: "Shell2", location: .init(latitude: 2, longitude: 2))
        ]
        #expect([stations].merge() == stations)
    }

    @Test("duplicate stations across arrays are deduplicated")
    func duplicatesAreDeduplicatedAcrossArrays() {
        let stations1: [PetrolStation] = [
            .init(brand: .shell, name: "Shell1", location: .init(latitude: 1, longitude: 1))
        ]
        let stations2: [PetrolStation] = [
            .init(brand: .shell, name: "Shell1", location: .init(latitude: 1, longitude: 1)),
            .init(brand: .shell, name: "Shell2", location: .init(latitude: 2, longitude: 2))
        ]

        let merged = [stations1, stations2].merge()

        #expect(merged.count == 2)
        #expect(merged == [
            .init(brand: .shell, name: "Shell1", location: .init(latitude: 1, longitude: 1)),
            .init(brand: .shell, name: "Shell2", location: .init(latitude: 2, longitude: 2))
        ])
    }

    @Test("stations with the same name and location but different brands are not deduplicated")
    func differentBrandsAtSameLocationAreKeptSeparate() {
        let location = PetrolStation.Location(latitude: 23.0, longitude: 58.0)
        let stations1 = [PetrolStation(brand: .shell, name: "Station", location: location)]
        let stations2 = [PetrolStation(brand: .oomco, name: "Station", location: location)]

        let merged = [stations1, stations2].merge()

        #expect(merged.count == 2)
    }

    @Test("insertion order is preserved across merged arrays")
    func insertionOrderPreservedAcrossArrays() {
        let stations1: [PetrolStation] = [
            .init(brand: .shell, name: "Shell1", location: .init(latitude: 1, longitude: 1)),
            .init(brand: .shell, name: "Shell3", location: .init(latitude: 3, longitude: 3))
        ]
        let stations2: [PetrolStation] = [
            .init(brand: .shell, name: "Shell1", location: .init(latitude: 1, longitude: 1)),
            .init(brand: .shell, name: "Shell2", location: .init(latitude: 2, longitude: 2))
        ]

        let merged = [stations1, stations2].merge()

        #expect(merged == [
            .init(brand: .shell, name: "Shell1", location: .init(latitude: 1, longitude: 1)),
            .init(brand: .shell, name: "Shell3", location: .init(latitude: 3, longitude: 3)),
            .init(brand: .shell, name: "Shell2", location: .init(latitude: 2, longitude: 2))
        ])
    }
}
