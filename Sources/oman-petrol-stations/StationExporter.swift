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

enum StationExportError: Error, Equatable {
    case noSourceAvailable
}

struct StationExporter {
    static func export(
        companies: Set<PetrolCompany>,
        format: SerializationFormat,
        output: some Output,
        reporter: any ExportProgressReporter = ConsoleProgressReporter(),
        makeSource: @Sendable (PetrolCompany) -> any PetrolStationsSource = { $0.makeSource(session: .shared) }
    ) async throws -> Void {
        let sortedCompanies = companies.sorted(by: { $0.rawValue < $1.rawValue })
        let unavailable = UnavailableCompanies()

        let stations = try await fetchAllFrom {
            for company in sortedCompanies {
                ReportingStationsSource(
                    wrapped: SkippingUnavailableSource(wrapped: makeSource(company), company: company, unavailable: unavailable),
                    company: company,
                    reporter: reporter
                )
            }
        }

        let countsByBrand = Dictionary(grouping: stations, by: \.brand).mapValues(\.count)
        let failures = await unavailable.failures
        for company in sortedCompanies {
            if let error = failures[company] {
                await reporter.report("  \(company.displayName): skipped (\(error))")
            } else {
                await reporter.report("  \(company.displayName): \(countsByBrand[company] ?? 0)")
            }
        }

        guard failures.count < sortedCompanies.count else {
            throw StationExportError.noSourceAvailable
        }

        try serializerFor(format).save(stations: stations, into: output)
        await reporter.report("Exported \(stations.count) stations to \(output)")
    }
}

private struct ReportingStationsSource: PetrolStationsSource {
    let wrapped: any PetrolStationsSource
    let company: PetrolCompany
    let reporter: any ExportProgressReporter

    func getAllPetrolStations() async throws(PetrolStationSourceError) -> [PetrolStation] {
        await reporter.report("Fetching \(company.displayName) stations...")
        return try await wrapped.getAllPetrolStations()
    }
}

private actor UnavailableCompanies {
    private(set) var failures: [PetrolCompany: PetrolStationSourceError] = [:]

    func record(_ error: PetrolStationSourceError, for company: PetrolCompany) {
        failures[company] = error
    }
}

private struct SkippingUnavailableSource: PetrolStationsSource {
    let wrapped: any PetrolStationsSource
    let company: PetrolCompany
    let unavailable: UnavailableCompanies

    func getAllPetrolStations() async throws(PetrolStationSourceError) -> [PetrolStation] {
        do {
            return try await wrapped.getAllPetrolStations()
        } catch {
            await unavailable.record(error, for: company)
            return []
        }
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
