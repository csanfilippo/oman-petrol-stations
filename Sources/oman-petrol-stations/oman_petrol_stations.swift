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

import Logging
import Foundation
import ArgumentParser

extension SerializationFormat: ExpressibleByArgument {
    init?(argument: String) {
        switch argument.lowercased() {
        case "kml": self = .kml
        case "csv": self = .csv
        default: return nil
        }
    }
}

extension PetrolCompany: ExpressibleByArgument {
    init?(argument: String) {
        self.init(rawValue: argument.lowercased())
    }
}

struct PetrolCompanyList: ExpressibleByArgument, ExpressibleByArrayLiteral {
    
    let companies: Set<PetrolCompany>

    init?(argument: String) {
        let values = argument.split(separator: ",").compactMap {
            PetrolCompany(rawValue: String($0).lowercased())
        }
        
        if values.isEmpty { return nil }
        self.companies = Set(values)
    }
    
    init(arrayLiteral elements: PetrolCompany...) {
        self.companies = Set(elements)
    }
    
    var defaultValueDescription: String {
        companies.sorted { $0.rawValue < $1.rawValue }.map(\.rawValue).joined(separator: ",")
    }
}


@main
struct oman_petrol_stations: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "oman-petrol-stations",
        abstract: "Fetches petrol stations in Oman and exports them to a file.",
        discussion: """
        This tool downloads station data from multiple providers and serializes it \
        into a chosen output format (KML or CSV)
        """,
        version: "1.1.0"
    )
    
    @Option(help: "The path of output file")
    var outputFilePath: String
    
    @Option(help: "The format of output file")
    var format: SerializationFormat = .kml
    
    @Option(help: "Comma-separated list of petrol companies")
    var petrolCompanyList: PetrolCompanyList = [.shell, .oomco, .almaha]
    
    mutating func run() async throws {
        
        let session = URLSession.shared
        
        let stations = try await fetchAllFrom {
            for company in petrolCompanyList.companies.sorted(by: { $0.rawValue < $1.rawValue }) {
                company.makeSource(session: session)
            }
        }
        
        let serializer = serializerFor(format)
        
        try serializer.save(stations: stations, into: File(absolutePath: outputFilePath))
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
