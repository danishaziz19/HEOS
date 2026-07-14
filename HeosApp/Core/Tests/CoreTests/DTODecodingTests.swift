import XCTest
@testable import Core

/// Decodes the actual fixture files (copies of the real API responses)
/// rather than hand-built JSON strings — this is the test that would
/// catch it immediately if the API's actual response shape ever drifted
/// from what `DeviceDTO`/`NowPlayingDTO` expect, including the unusual
/// "Now Playing" key with a literal space in it.
final class DTODecodingTests: XCTestCase {

    private func loadFixture(_ name: String) throws -> Data {
        let url = Bundle.module.url(forResource: name, withExtension: "json")!
        return try Data(contentsOf: url)
    }

    func test_devicesResponse_decodesRealFixture() throws {
        let data = try loadFixture("devices")
        let response = try JSONDecoder().decode(DevicesResponseDTO.self, from: data)

        XCTAssertEqual(response.devices.count, 2)
        XCTAssertEqual(response.devices[0].id, 1)
        XCTAssertEqual(response.devices[0].name, "Bedroom")
    }

    func test_nowPlayingResponse_decodesRealFixtureIncludingSpaceInKey() throws {
        let data = try loadFixture("nowplaying")
        let response = try JSONDecoder().decode(NowPlayingResponseDTO.self, from: data)

        XCTAssertEqual(response.nowPlaying.count, 1)
        XCTAssertEqual(response.nowPlaying[0].deviceID, 1)
        XCTAssertEqual(response.nowPlaying[0].trackName, "Welcome To The Jungle")
        XCTAssertEqual(response.nowPlaying[0].artistName, "Guns N' Roses")
        XCTAssertNotNil(response.nowPlaying[0].artworkSmall)
    }
}
