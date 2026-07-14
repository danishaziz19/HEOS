import Foundation

/// Hits the two endpoints given in the brief directly. `URLSession` is
/// injected (defaulted to `.shared`) so this can be constructed with a
/// stubbed session in a test without a full network-mocking library.
///
/// Explicitly declared `Sendable` (rather than relying on the compiler
/// to infer it purely from `RoomsDataSource: Sendable`) since it's a
/// class — all stored properties are immutable (`let`), which is what
/// makes this safe, but I wanted the conformance itself to be visible
/// rather than implicit.
final class RemoteRoomsDataSource: RoomsDataSource, Sendable {
    private let session: URLSession
    private let devicesURL = URL(string: "https://skyegloup-eula.s3.amazonaws.com/heos_app/code_test/devices.json")!
    private let nowPlayingURL = URL(string: "https://skyegloup-eula.s3.amazonaws.com/heos_app/code_test/nowplaying.json")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchDevices() async throws -> [DeviceDTO] {
        let response: DevicesResponseDTO = try await fetch(devicesURL)
        return response.devices
    }

    func fetchNowPlaying() async throws -> [NowPlayingDTO] {
        let response: NowPlayingResponseDTO = try await fetch(nowPlayingURL)
        return response.nowPlaying
    }

    private func fetch<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw RoomsError.network("Unexpected response fetching \(url.lastPathComponent)")
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw RoomsError.decoding
        }
    }
}
