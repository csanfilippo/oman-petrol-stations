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

@resultBuilder
struct FetchAllStationsBuilder {
    
    static func buildBlock(_ components: [PetrolStationsSource]...) -> [PetrolStationsSource] {
        components.flatMap { $0 }
    }

    static func buildExpression(_ expression: PetrolStationsSource) -> [PetrolStationsSource] {
        [expression]
    }

    static func buildOptional(_ component: [PetrolStationsSource]?) -> [PetrolStationsSource] {
        component ?? []
    }

    static func buildEither(first component: [PetrolStationsSource]) -> [PetrolStationsSource] {
        component
    }

    static func buildEither(second component: [PetrolStationsSource]) -> [PetrolStationsSource] {
        component
    }
}

func fetchAllFrom(@FetchAllStationsBuilder _ sources: () -> [PetrolStationsSource]) async throws -> [PetrolStation] {
    try await withThrowingTaskGroup(of: [PetrolStation].self) { group in
        
        for source in sources() {
            group.addTask {
                try await source.getAllPetrolStations()
            }
        }
        
        var result: [[PetrolStation]] = []
        
        for try await arr in group {
            result.append(arr)
        }
        
        return result.merge()
    }
}
