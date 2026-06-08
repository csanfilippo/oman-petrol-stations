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

struct StationExporter {
    static func export(companies: Set<PetrolCompany>, format: SerializationFormat, output: some Output) async throws -> Void {
        let session: URLSession = .shared
        
        let sortedCompanies = companies.sorted(by: { $0.rawValue < $1.rawValue })
        let progress: (String) -> Void = { print($0) }
        
        for company in sortedCompanies {
            progress("Fetching \(company.displayName) stations...")
        }

        let stations = try await fetchAllFrom {
            for company in sortedCompanies {
                company.makeSource(session: session)
            }
        }

        let countsByBrand = Dictionary(grouping: stations, by: \.brand).mapValues(\.count)
        for company in sortedCompanies {
            progress("  \(company.displayName): \(countsByBrand[company] ?? 0)")
        }

        try serializerFor(format).save(stations: stations, into: output)
        progress("Exported \(stations.count) stations to \(output)")
    }
}

private extension PetrolCompany {
    func makeSource(session: URLSession) -> any PetrolStationsSource {
        switch self {
        case .almaha: AlMahaStationsSource(session: session)
        case .oomco:  OmanOilStationsSource(session: session)
        case .shell:  ShellStationsSource(session: session)
        }
    }
}
