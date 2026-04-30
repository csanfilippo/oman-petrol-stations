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

@testable import oman_petrol_stations

@Suite("KMLPetrolStationSerializer")
struct KMLPetrolStationSerializerTests {

    @Test("empty station list produces valid KML document with no Placemarks")
    func emptyStationListProducesKMLWithNoPlacemarks() throws {
        let serializer = KMLPetrolStationSerializer()
        let storage = InspectableStorage()

        try serializer.save(stations: [], into: storage)

        let expected = """
        <?xml version="1.0" encoding="UTF-8"?>
        <kml xmlns="http://www.opengis.net/kml/2.2">
          <Document>
            <name>Petrol Stations</name>
          </Document>
        </kml>
        """
        #expect(storage.storage == expected)
    }

    @Test("station is serialized as a Placemark with longitude,latitude coordinate order")
    func stationSerializedAsPlacemarkWithCorrectCoordinateOrder() throws {
        let stations = [
            PetrolStation(brand: .shell, name: "Test Station", location: .init(latitude: 2.0, longitude: 3.0))
        ]
        let serializer = KMLPetrolStationSerializer()
        let storage = InspectableStorage()

        try serializer.save(stations: stations, into: storage)

        #expect(storage.storage.contains("<Placemark>"))
        #expect(storage.storage.contains("<name>Test Station</name>"))
        #expect(storage.storage.contains("<coordinates>3.0,2.0</coordinates>"))
        #expect(storage.storage.contains("<description>Brand: Shell</description>"))
        #expect(storage.storage.contains("</Placemark>"))
    }

    @Test("multiple stations produce one Placemark each")
    func multipleStationsProduceOnePlacemarkEach() throws {
        let stations: [PetrolStation] = [
            .init(brand: .shell, name: "Station A", location: .init(latitude: 23.0, longitude: 58.0)),
            .init(brand: .oomco, name: "Station B", location: .init(latitude: 24.0, longitude: 59.0))
        ]
        let serializer = KMLPetrolStationSerializer()
        let storage = InspectableStorage()

        try serializer.save(stations: stations, into: storage)

        let placemarkCount = storage.storage.components(separatedBy: "<Placemark>").count - 1
        #expect(placemarkCount == 2)
        #expect(storage.storage.contains("<name>Station A</name>"))
        #expect(storage.storage.contains("<description>Brand: Shell</description>"))
        #expect(storage.storage.contains("<name>Station B</name>"))
        #expect(storage.storage.contains("<description>Brand: Oman Oil</description>"))
    }

    @Test("capitalizes station names")
    func capitalizesStationNames() throws {
        let stations = [
            PetrolStation(brand: .shell, name: "TEST STATION", location: .init(latitude: 2.0, longitude: 3.0))
        ]
        let serializer = KMLPetrolStationSerializer()
        let storage = InspectableStorage()

        try serializer.save(stations: stations, into: storage)

        #expect(storage.storage.contains("<name>Test Station</name>"))
    }

    @Test("XML-escapes special characters in station name")
    func xmlEscapesSpecialCharactersInName() throws {
        let stations = [
            PetrolStation(
                brand: .shell,
                name: "A&B <C> \"D\" 'E'",
                location: .init(latitude: 1.0, longitude: 1.0)
            )
        ]
        let serializer = KMLPetrolStationSerializer()
        let storage = InspectableStorage()

        try serializer.save(stations: stations, into: storage)

        #expect(storage.storage.contains("<name>A&amp;B &lt;C&gt; &quot;D&quot; &apos;E&apos;</name>"))
        #expect(storage.storage.contains("<description>Brand: Shell</description>"))
    }
}
