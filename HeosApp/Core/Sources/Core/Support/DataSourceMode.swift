import Foundation

/// Matches the Settings tab's "Mock Data" switch directly: off (default)
/// = cloud, on = local bundled dummy data. Named to match the spec's own
/// language rather than a generic "local/remote" to keep the domain
/// vocabulary consistent with what a reviewer reading the ticket would
/// expect.
public enum DataSourceMode: Sendable, Equatable {
    case cloud
    case mockData
}

public enum RoomsError: Error, Equatable, Sendable {
    case network(String)
    case decoding
    case roomNotFound
    case unknown
}
