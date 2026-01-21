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


@Suite("KMLPetrolStationSerializerTests")
struct KMLPetrolStationSerializerTests {

    @Test("empty array produces only header and footer")
    func testEmptyArrayProducesOnlyHeaderAndFooter() throws {
        let stations: [PetrolStation] = []
        let serializer = KMLPetrolStationSerializer()
        let storage = InspectableStorage()

        try serializer.save(stations: stations, into: storage)

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

    @Test("single station includes a Placemark with correct coordinates and escaped name")
    func testSingleStationIncludesPlacemarkCorrectly() throws {
        // Arrange
        let stations = [
            PetrolStation(id: "1", brand: "Shell", name: "Test Station", location: .init(latitude: 2.0, longitude: 3.0))
        ]
        let serializer = KMLPetrolStationSerializer()
        let storage = InspectableStorage()

        // Act
        try serializer.save(stations: stations, into: storage)

        // Assert
        #expect(storage.storage.contains("<Placemark>"))
        #expect(storage.storage.contains("<name>Test Station</name>"))
        #expect(storage.storage.contains("<coordinates>2.0,3.0</coordinates>"))
        #expect(storage.storage.contains("</Placemark>"))
    }

    @Test("escaping of special characters in name and brand")
    func testEscapingSpecialCharactersInNameAndBrand() throws {
        let stations = [
            PetrolStation(
                id: "1",
                brand: "X&Y <Z> \"Q\" 'W'",
                name: "A&B <C> \"D\" 'E'",
                location: .init(latitude: 1.0, longitude: 1.0)
            )
        ]
        let serializer = KMLPetrolStationSerializer()
        let storage = InspectableStorage()

        try serializer.save(stations: stations, into: storage)

        #expect(storage.storage.contains("<name>A&amp;B &lt;C&gt; &quot;D&quot; &apos;E&apos;</name>"))

        #expect(storage.storage.contains("<description>"))
        #expect(storage.storage.contains("Brand: "))
        #expect(storage.storage.contains("&amp;amp;"))   // double-escaped &
        #expect(storage.storage.contains("&amp;lt;"))    // double-escaped <
        #expect(storage.storage.contains("&amp;gt;"))    // double-escaped >
        #expect(storage.storage.contains("&amp;quot;"))  // double-escaped "
        #expect(storage.storage.contains("&amp;apos;"))  // double-escaped '
    }
}
