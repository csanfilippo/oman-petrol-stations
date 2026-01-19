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

enum OutputFormat: ExpressibleByArgument, CaseIterable {
    init?(argument: String) {
        switch argument.lowercased() {
        case "kml": self = .kml
        case "csv": self = .csv
        default: return nil
        }
    }
    
    case csv
    case kml
}

@main
struct oman_petrol_stations: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "oman-petrol-stations",
        abstract: "Fetches petrol stations in Oman and exports them to a file.",
        discussion: """
        This tool downloads station data from multiple providers and serializes it \
        into a chosen output format (KML or CSV). Use --format to select the format \
        and --output-file-path to specify where to save the file.
        """,
        version: "1.0.0"
    )
    
    @Option(name: .long, help: "The path of output file")
    var outputFilePath: String
    
    @Option(name: .long, help: "The format of output file")
    var format: OutputFormat = .kml
    
    mutating func run() async throws {
		let session = URLSession.shared
        
        let omainOilSource = OmanOilStationsSource(session: session)
        let shellSource = ShellStationsSource(session: session)
        let alMahaSource = AlMahaStationsSource(session: session)

        let stations = try await fetchAllFrom {
            omainOilSource
            shellSource
            alMahaSource
        }
        
        let serializer = serializerFor(format.asSerializationFormat)
        
        try serializer.save(stations: stations, into: File(absolutePath: outputFilePath))
    }
}

private extension OutputFormat {
    var asSerializationFormat: SerializationFormat {
        switch self {
        case .csv: return .csv
        case .kml: return .kml
        }
    }
}
