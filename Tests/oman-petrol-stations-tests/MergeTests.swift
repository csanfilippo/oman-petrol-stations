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

@Suite("MergeTests")
struct MergeTests {
    @Test("merging empty arrays results in an empty array")
    func emptyArrays() async throws {
        
        let stations1: [PetrolStation] = []
        let stations2: [PetrolStation] = []
        
        let arrayOfArrays = [stations1, stations2]
        
        let merged = arrayOfArrays.merge()
        
        let expected: [PetrolStation] = []
        
        #expect(merged == expected)
        
    }
    
    @Test("merge of non empty arrays consists only of unique elements")
    func mergingArrays() async throws {
        
        let stations1: [PetrolStation] = [.init(id: "1", brand: "Shell", name: "Shell1", location: .init(latitude: 1, longitude: 1))]
        let stations2: [PetrolStation] = [
            .init(id: "1", brand: "Shell", name: "Shell1", location: .init(latitude: 1, longitude: 1)),
            .init(id: "2", brand: "Shell", name: "Shell2", location: .init(latitude: 2, longitude: 2))
        ]
        
        let arrayOfArrays = [stations1, stations2]
        
        let merged = arrayOfArrays.merge()
        
        let expected: [PetrolStation] = [
            .init(id: "1", brand: "Shell", name: "Shell1", location: .init(latitude: 1, longitude: 1)),
            .init(id: "2", brand: "Shell", name: "Shell2", location: .init(latitude: 2, longitude: 2))
        ]
        
        #expect(merged == expected)
    }
    
    @Test("merge preservs the order of elements as they appear in the input")
    func preserveOrder() async throws {
        
        let stations1: [PetrolStation] = [
            .init(id: "1", brand: "Shell", name: "Shell1", location: .init(latitude: 1, longitude: 1)),
            .init(id: "3", brand: "Shell", name: "Shell3", location: .init(latitude: 3, longitude: 3))
        ]
        
        let stations2: [PetrolStation] = [
            .init(id: "1", brand: "Shell", name: "Shell1", location: .init(latitude: 1, longitude: 1)),
            .init(id: "2", brand: "Shell", name: "Shell2", location: .init(latitude: 2, longitude: 2))
        ]
        
        let arrayOfArrays = [stations1, stations2]
        
        let merged = arrayOfArrays.merge()
        
        let expected: [PetrolStation] = [
            .init(id: "1", brand: "Shell", name: "Shell1", location: .init(latitude: 1, longitude: 1)),
            .init(id: "3", brand: "Shell", name: "Shell3", location: .init(latitude: 3, longitude: 3)),
            .init(id: "2", brand: "Shell", name: "Shell2", location: .init(latitude: 2, longitude: 2))
        ]
        
        #expect(merged == expected)
    }
}

