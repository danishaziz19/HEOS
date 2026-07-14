import Foundation

/// Backs the "Mock Data" switch in Settings. Reads bundled JSON using
/// the same DTOs and decoder as `RemoteRoomsDataSource`.
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
