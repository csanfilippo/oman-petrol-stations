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

@Suite("CSVPetrolStationSerializerTests")
struct CSVPetrolStationSerializerTests {
    
    @Test("saving an empty array will result in a csv file with just the header")
    func emptyArray() throws {
        let emptyArray: [PetrolStation] = []
        let serializer = CSVPetrolStationSerializer()
        let inspectableStorage = InspectableStorage()
        try serializer.save(stations: emptyArray, into: inspectableStorage)
        let expected = "Name,Brand,Latitude,Longitude"
        
        #expect(inspectableStorage.storage == expected)
    }
    
    @Test("saving an not empty array will result in a csv file all the lines")
    func notEmptyArray() throws {
        let emptyArray: [PetrolStation] = [.init(id: "1", brand: "Shell", name: "Test", location: .init(latitude: 2.2, longitude: 3.2))]
        let serializer = CSVPetrolStationSerializer()
        let inspectableStorage = InspectableStorage()
        try serializer.save(stations: emptyArray, into: inspectableStorage)
        let expected = """
            Name,Brand,Latitude,Longitude
            Test,Shell,2.200000,3.200000
            """
        
        
        #expect(inspectableStorage.storage == expected)
    }
    
    @Test("station names are capitalized")
    func capitalizedStationName() throws {
        let emptyArray: [PetrolStation] = [.init(id: "1", brand: "Shell", name: "TEST", location: .init(latitude: 2.2, longitude: 3.2))]
        let serializer = CSVPetrolStationSerializer()
        let inspectableStorage = InspectableStorage()
        try serializer.save(stations: emptyArray, into: inspectableStorage)
        let expected = """
            Name,Brand,Latitude,Longitude
            Test,Shell,2.200000,3.200000
            """
        
        
        #expect(inspectableStorage.storage == expected)
    }
}
