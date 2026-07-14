import Foundation

/// Hits the two endpoints given in the brief. HTTP work lives in
/// `NetworkClient`, the host lives in `HEOSAPI.baseURL` — both
/// injected with defaults so a test can swap either one.
final class RemoteRoomsDataSource: RoomsDataSource, Sendable {
    private let baseURL: URL
    private let networkClient: NetworkClient

    init(
        baseURL: URL = HEOSAPI.baseURL,
        networkClient: NetworkClient = URLSessionNetworkClient()
    ) {
        self.baseURL = baseURL
        self.networkClient = networkClient
    }

    func fetchDevices() async throws -> [DeviceDTO] {
        let response: DevicesResponseDTO = try await networkClient.fetch(Endpoint.devices.url(baseURL: baseURL))
        return response.devices
    }

    func fetchNowPlaying() async throws -> [NowPlayingDTO] {
        let response: NowPlayingResponseDTO = try await networkClient.fetch(Endpoint.nowPlaying.url(baseURL: baseURL))
        return response.nowPlaying
    }
}
