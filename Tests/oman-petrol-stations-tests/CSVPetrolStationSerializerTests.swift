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

final class InspectableStorage: Storage {
    private(set) var storage: String = ""

    func save(_ string: String) throws {
        storage = string
    }
}

@Suite("CSVPetrolStationSerializer")
struct CSVPetrolStationSerializerTests {

    @Test("empty station list produces header row only")
    func emptyStationListProducesHeaderOnly() throws {
        let serializer = CSVPetrolStationSerializer()
        let storage = InspectableStorage()

        try serializer.save(stations: [], into: storage)

        #expect(storage.storage == "Name,Brand,Latitude,Longitude")
    }

    @Test("single station is serialized as a CSV row with brand display name")
    func singleStationSerializedAsCSVRow() throws {
        let stations: [PetrolStation] = [
            .init(brand: .shell, name: "Test", location: .init(latitude: 2.2, longitude: 3.2))
        ]
        let serializer = CSVPetrolStationSerializer()
        let storage = InspectableStorage()

        try serializer.save(stations: stations, into: storage)

        let expected = """
            Name,Brand,Latitude,Longitude
            Test,Shell,2.200000,3.200000
            """
        #expect(storage.storage == expected)
    }

    @Test("multiple stations produce one row each with correct brand display names")
    func multipleStationsProduceOneRowEach() throws {
        let stations: [PetrolStation] = [
            .init(brand: .shell, name: "Station A", location: .init(latitude: 23.0, longitude: 58.0)),
            .init(brand: .oomco, name: "Station B", location: .init(latitude: 24.0, longitude: 59.0))
        ]
        let serializer = CSVPetrolStationSerializer()
        let storage = InspectableStorage()

        try serializer.save(stations: stations, into: storage)

        let lines = storage.storage.components(separatedBy: "\n")
        #expect(lines.count == 3)
        #expect(lines[0] == "Name,Brand,Latitude,Longitude")
        #expect(lines[1] == "Station A,Shell,23.000000,58.000000")
        #expect(lines[2] == "Station B,Oman Oil,24.000000,59.000000")
    }

    @Test("capitalizes station names")
    func capitalizesStationNames() throws {
        let stations: [PetrolStation] = [
            .init(brand: .shell, name: "TEST", location: .init(latitude: 2.2, longitude: 3.2))
        ]
        let serializer = CSVPetrolStationSerializer()
        let storage = InspectableStorage()

        try serializer.save(stations: stations, into: storage)

        let expected = """
            Name,Brand,Latitude,Longitude
            Test,Shell,2.200000,3.200000
            """
        #expect(storage.storage == expected)
    }
}
