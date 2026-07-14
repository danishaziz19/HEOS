import Foundation

/// Backs the "Mock Data" switch in Settings. Reads two bundled JSON
/// files matching the exact same schema as the real endpoints — using
/// the same DTOs and decoder as `RemoteRoomsDataSource` means both
/// sources are exercised through identical decode logic, and a bug in
/// decoding would show up in mock mode just as it would in cloud mode,
/// rather than mock mode using some entirely separate, unverified path.
///
/// Explicitly declared `Sendable` for the same reason as
/// `RemoteRoomsDataSource` — immutable stored state, made visible
/// rather than left to inference.
final class LocalRoomsDataSource: RoomsDataSource, Sendable {
    private let bundle: Bundle

    init(bundle: Bundle = .module) {
        self.bundle = bundle
    }

    func fetchDevices() async throws -> [DeviceDTO] {
        let response: DevicesResponseDTO = try decode("devices_mock", from: bundle)
        return response.devices
    }

    func fetchNowPlaying() async throws -> [NowPlayingDTO] {
        let response: NowPlayingResponseDTO = try decode("nowplaying_mock", from: bundle)
        return response.nowPlaying
    }

    private func decode<T: Decodable>(_ resource: String, from bundle: Bundle) throws -> T {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            throw RoomsError.unknown
        }
        let data = try Data(contentsOf: url)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw RoomsError.decoding
        }
    }
}
