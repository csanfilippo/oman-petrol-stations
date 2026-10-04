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
import Testing
import sfera

@testable import oman_petrol_stations

@Suite("GeoJSONPetrolStationSerializer")
struct GeoJSONPetrolStationSerializerTests {

    @Test("empty station list produces a FeatureCollection with no features")
    func emptyStationListProducesEmptyFeatureCollection() throws {
        let serializer = GeoJSONPetrolStationSerializer()
        let output = InspectableOutput()

        try serializer.save(stations: [], into: output)

        #expect(try decode(output.content) == .featureCollection(.init([])))
    }

    @Test("station is serialized as a Point feature with its name and brand display name")
    func stationSerializedAsPointFeature() throws {
        let stations = [
            PetrolStation(brand: .shell, name: "Test Station", location: .fixture(latitude: 23.5, longitude: 58.4))
        ]
        let serializer = GeoJSONPetrolStationSerializer()
        let output = InspectableOutput()

        try serializer.save(stations: stations, into: output)

        let expected: GeoJSON = .featureCollection(.init([
            Feature(
                geometry: .point(try Position(latitude: 23.5, longitude: 58.4)),
                properties: ["stationName": .string("Test Station"), "brand": .string("Shell")]
            )
        ]))
        #expect(try decode(output.content) == expected)
    }

    @Test("coordinates are emitted in longitude,latitude order")
    func coordinatesEmittedInLongitudeLatitudeOrder() throws {
        let stations = [
            PetrolStation(brand: .shell, name: "Test", location: .fixture(latitude: 23.5, longitude: 58.4))
        ]
        let serializer = GeoJSONPetrolStationSerializer()
        let output = InspectableOutput()

        try serializer.save(stations: stations, into: output)

        let json = try #require(JSONSerialization.jsonObject(with: Data(output.content.utf8)) as? [String: Any])
        let features = try #require(json["features"] as? [[String: Any]])
        let geometry = try #require(features.first?["geometry"] as? [String: Any])
        #expect(geometry["type"] as? String == "Point")
        #expect(geometry["coordinates"] as? [Double] == [58.4, 23.5])
    }

    @Test("multiple stations produce one feature each with correct brand display names, preserving order")
    func multipleStationsProduceOneFeatureEachInOrder() throws {
        let stations: [PetrolStation] = [
            .init(brand: .shell, name: "Station A", location: .fixture(latitude: 23.0, longitude: 58.0)),
            .init(brand: .oomco, name: "Station B", location: .fixture(latitude: 24.0, longitude: 59.0))
        ]
        let serializer = GeoJSONPetrolStationSerializer()
        let output = InspectableOutput()

        try serializer.save(stations: stations, into: output)

        let expected: GeoJSON = .featureCollection(.init([
            Feature(
                geometry: .point(try Position(latitude: 23.0, longitude: 58.0)),
                properties: ["stationName": .string("Station A"), "brand": .string("Shell")]
            ),
            Feature(
                geometry: .point(try Position(latitude: 24.0, longitude: 59.0)),
                properties: ["stationName": .string("Station B"), "brand": .string("Oman Oil")]
            )
        ]))
        #expect(try decode(output.content) == expected)
    }

    @Test("capitalizes station names")
    func capitalizesStationNames() throws {
        let stations = [
            PetrolStation(brand: .shell, name: "TEST STATION", location: .fixture(latitude: 2.2, longitude: 3.2))
        ]
        let serializer = GeoJSONPetrolStationSerializer()
        let output = InspectableOutput()

        try serializer.save(stations: stations, into: output)

        let expected: GeoJSON = .featureCollection(.init([
            Feature(
                geometry: .point(try Position(latitude: 2.2, longitude: 3.2)),
                properties: ["stationName": .string("Test Station"), "brand": .string("Shell")]
            )
        ]))
        #expect(try decode(output.content) == expected)
    }

    private func decode(_ content: String) throws -> GeoJSON {
        try JSONDecoder().decode(GeoJSON.self, from: Data(content.utf8))
    }
}
