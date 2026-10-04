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

private struct DummySource: PetrolStationsSource {
    let injectedStations: [PetrolStation]

    func getAllPetrolStations() async throws(PetrolStationSourceError) -> [PetrolStation] {
        injectedStations
    }
}

private struct ThrowingSource: PetrolStationsSource {
    let error: PetrolStationSourceError

    func getAllPetrolStations() async throws(PetrolStationSourceError) -> [PetrolStation] {
        throw error
    }
}

private final class RecordingOutput: Output {
    private(set) var saved: String?

    func save(_ string: String) throws {
        saved = string
    }
}

extension RecordingOutput: CustomStringConvertible {
    var description: String { "test-output" }
}

private actor RecordingProgressReporter: ExportProgressReporter {
    private(set) var messages: [String] = []

    func report(_ message: String) async {
        messages.append(message)
    }
}

@Suite("StationExporter")
struct StationExporterTests {

    @Test("serializes merged stations from the sources for the requested companies")
    func serializesMergedStationsFromRequestedCompanies() async throws {
        let output = RecordingOutput()

        try await StationExporter.export(
            companies: [.shell, .oomco],
            format: .csv,
            output: output,
            reporter: RecordingProgressReporter(),
            makeSource: { company in
                switch company {
                case .shell:
                    DummySource(injectedStations: [
                        .init(brand: .shell, name: "Shell1", location: .fixture(latitude: 1, longitude: 1))
                    ])
                case .oomco:
                    DummySource(injectedStations: [
                        .init(brand: .oomco, name: "Oomco1", location: .fixture(latitude: 2, longitude: 2))
                    ])
                case .almaha:
                    DummySource(injectedStations: [])
                }
            }
        )

        // Sources are fetched concurrently, so rows can be merged in either order;
        // only the header's position and the row content are guaranteed.
        let lines = try #require(output.saved).split(separator: "\n").map(String.init)
        #expect(lines.first == "Name,Brand,Latitude,Longitude")
        #expect(Set(lines.dropFirst()) == [
            "Oomco1,Oman Oil,2.000000,2.000000",
            "Shell1,Shell,1.000000,1.000000"
        ])
    }

    @Test("reports fetching progress, per-brand counts, and the export summary")
    func reportsProgress() async throws {
        let reporter = RecordingProgressReporter()
        let output = RecordingOutput()

        try await StationExporter.export(
            companies: [.oomco, .shell],
            format: .csv,
            output: output,
            reporter: reporter,
            makeSource: { company in
                DummySource(injectedStations: [
                    .init(brand: company, name: "station", location: .fixture(latitude: 0, longitude: 0))
                ])
            }
        )

        let messages = await reporter.messages

        // The two "Fetching..." messages come from concurrently scheduled tasks, so their
        // relative order isn't guaranteed; the summary lines are emitted after all fetches
        // complete and are therefore strictly ordered.
        #expect(Set(messages.prefix(2)) == [
            "Fetching Oman Oil stations...",
            "Fetching Shell stations..."
        ])
        #expect(messages.suffix(3) == [
            "  Oman Oil: 1",
            "  Shell: 1",
            "Exported 2 stations to test-output"
        ])
    }

    @Test("skips a failing source and exports the stations of the others")
    func skipsFailingSourceAndExportsTheOthers() async throws {
        let output = RecordingOutput()

        try await StationExporter.export(
            companies: [.shell, .oomco],
            format: .csv,
            output: output,
            reporter: RecordingProgressReporter(),
            makeSource: { company in
                switch company {
                case .shell:
                    ThrowingSource(error: .serverError)
                case .oomco, .almaha:
                    DummySource(injectedStations: [
                        .init(brand: .oomco, name: "Oomco1", location: .fixture(latitude: 2, longitude: 2))
                    ])
                }
            }
        )

        #expect(output.saved == """
            Name,Brand,Latitude,Longitude
            Oomco1,Oman Oil,2.000000,2.000000
            """)
    }

    @Test("reports a skipped source with its error in the summary")
    func reportsSkippedSourceInSummary() async throws {
        let reporter = RecordingProgressReporter()

        try await StationExporter.export(
            companies: [.shell, .oomco],
            format: .csv,
            output: RecordingOutput(),
            reporter: reporter,
            makeSource: { company in
                switch company {
                case .shell:
                    ThrowingSource(error: .serverError)
                case .oomco, .almaha:
                    DummySource(injectedStations: [
                        .init(brand: .oomco, name: "Oomco1", location: .fixture(latitude: 2, longitude: 2))
                    ])
                }
            }
        )

        #expect(await reporter.messages.suffix(3) == [
            "  Oman Oil: 1",
            "  Shell: skipped (serverError)",
            "Exported 1 stations to test-output"
        ])
    }

    @Test("throws noSourceAvailable when every source fails, reporting each skip and writing nothing")
    func throwsWhenEverySourceFails() async throws {
        let reporter = RecordingProgressReporter()
        let output = RecordingOutput()

        await #expect(throws: StationExportError.noSourceAvailable) {
            try await StationExporter.export(
                companies: [.shell, .oomco],
                format: .csv,
                output: output,
                reporter: reporter,
                makeSource: { company in
                    ThrowingSource(error: company == .shell ? .serverError : .invalidData)
                }
            )
        }

        #expect(output.saved == nil)
        #expect(await reporter.messages.suffix(2) == [
            "  Oman Oil: skipped (invalidData)",
            "  Shell: skipped (serverError)"
        ])
    }
}
