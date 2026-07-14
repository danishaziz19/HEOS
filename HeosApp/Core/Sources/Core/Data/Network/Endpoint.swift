import Foundation

/// A relative path against some base URL. Keeps "which path" separate
/// from "which server" — the base URL is injected elsewhere (see
/// `HEOSAPI.baseURL` and `RemoteRoomsDataSource.init`).
struct Endpoint: Sendable {
    let path: String

    func url(baseURL: URL) -> URL {
        baseURL.appendingPathComponent(path)
    }
}

extension Endpoint {
    static let devices = Endpoint(path: "/heos_app/code_test/devices.json")
    static let nowPlaying = Endpoint(path: "/heos_app/code_test/nowplaying.json")
}

/// The HEOS API host.
enum HEOSAPI {
    static let baseURL = URL(string: "https://skyegloup-eula.s3.amazonaws.com")!
}
