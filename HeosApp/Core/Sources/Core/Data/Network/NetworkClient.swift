import Foundation

/// Generic fetch-and-decode over HTTP. Knows nothing about HEOS,
/// devices, or rooms — any data source can inject this.
protocol NetworkClient: Sendable {
    func fetch<T: Decodable>(_ url: URL) async throws -> T
}

/// URLSession-backed implementation. Session is injected so a test can
/// pass in a stub.
struct URLSessionNetworkClient: NetworkClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetch<T: Decodable>(_ url: URL) async throws -> T {
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
