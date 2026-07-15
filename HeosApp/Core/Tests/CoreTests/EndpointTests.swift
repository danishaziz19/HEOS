import XCTest
@testable import Core

final class EndpointTests: XCTestCase {

    func test_url_appendsPathToBaseURL() {
        let baseURL = URL(string: "https://example.com")!
        let endpoint = Endpoint(path: "/foo/bar.json")

        let url = endpoint.url(baseURL: baseURL)

        XCTAssertEqual(url.absoluteString, "https://example.com/foo/bar.json")
    }

    func test_devicesEndpoint_resolvesAgainstRealBaseURL() {
        let url = Endpoint.devices.url(baseURL: HEOSAPI.baseURL)

        XCTAssertEqual(url.absoluteString, "https://skyegloup-eula.s3.amazonaws.com/heos_app/code_test/devices.json")
    }

    func test_nowPlayingEndpoint_resolvesAgainstRealBaseURL() {
        let url = Endpoint.nowPlaying.url(baseURL: HEOSAPI.baseURL)

        XCTAssertEqual(url.absoluteString, "https://skyegloup-eula.s3.amazonaws.com/heos_app/code_test/nowplaying.json")
    }
}
