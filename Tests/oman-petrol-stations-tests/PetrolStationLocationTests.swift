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

@testable import oman_petrol_stations

@Suite("PetrolStation.Location")
struct PetrolStationLocationTests {

    @Test("accepts coordinates on the boundaries of the valid range", arguments: [
        (-90.0, -180.0),
        (90.0, 180.0),
        (0.0, 0.0)
    ])
    func acceptsBoundaryCoordinates(latitude: Double, longitude: Double) throws {
        let location = try #require(PetrolStation.Location(latitude: latitude, longitude: longitude))

        #expect(location.latitude == latitude)
        #expect(location.longitude == longitude)
    }

    @Test("rejects latitude outside -90...90", arguments: [-90.000001, 90.000001])
    func rejectsOutOfRangeLatitude(latitude: Double) {
        #expect(PetrolStation.Location(latitude: latitude, longitude: 58.0) == nil)
    }

    @Test("rejects longitude outside -180...180", arguments: [-180.000001, 180.000001])
    func rejectsOutOfRangeLongitude(longitude: Double) {
        #expect(PetrolStation.Location(latitude: 23.0, longitude: longitude) == nil)
    }

    @Test("rejects non-finite coordinates", arguments: [
        (Double.nan, 58.0),
        (23.0, Double.nan),
        (Double.infinity, 58.0),
        (23.0, -Double.infinity)
    ])
    func rejectsNonFiniteCoordinates(latitude: Double, longitude: Double) {
        #expect(PetrolStation.Location(latitude: latitude, longitude: longitude) == nil)
    }
}
