import XCTest
@testable import Core

final class RoomMapperTests: XCTestCase {

    func test_toDomain_joinsDeviceAndNowPlayingByDeviceID() {
        let devices = [DeviceDTO(id: 1, name: "Bedroom")]
        let nowPlaying = [NowPlayingDTO(
            deviceID: 1, artworkSmall: "https://example.com/s.jpg",
            artworkLarge: "https://example.com/l.jpg",
            trackName: "Track", artistName: "Artist"
        )]

        let rooms = RoomMapper.toDomain(devices: devices, nowPlaying: nowPlaying)

        XCTAssertEqual(rooms.count, 1)
        XCTAssertEqual(rooms[0].id, 1)
        XCTAssertEqual(rooms[0].name, "Bedroom")
        XCTAssertEqual(rooms[0].trackTitle, "Track")
        XCTAssertEqual(rooms[0].artistName, "Artist")
        XCTAssertEqual(rooms[0].artworkSmallURL, URL(string: "https://example.com/s.jpg"))
    }

    func test_toDomain_defaultsAlbumTitleToNil_sinceAPIDoesNotProvideOne() {
        let devices = [DeviceDTO(id: 1, name: "Bedroom")]
        let nowPlaying = [NowPlayingDTO(deviceID: 1, artworkSmall: nil, artworkLarge: nil, trackName: "T", artistName: "A")]

        let rooms = RoomMapper.toDomain(devices: devices, nowPlaying: nowPlaying)

        XCTAssertNil(rooms[0].albumTitle)
    }

    func test_toDomain_defaultsIsPlayingToTrue_sinceAPIDoesNotProvideOne() {
        let devices = [DeviceDTO(id: 1, name: "Bedroom")]
        let nowPlaying = [NowPlayingDTO(deviceID: 1, artworkSmall: nil, artworkLarge: nil, trackName: "T", artistName: "A")]

        let rooms = RoomMapper.toDomain(devices: devices, nowPlaying: nowPlaying)

        XCTAssertTrue(rooms[0].isPlaying)
    }

    func test_toDomain_dropsDeviceWithNoMatchingNowPlayingEntry() {
        let devices = [
            DeviceDTO(id: 1, name: "Bedroom"),
            DeviceDTO(id: 2, name: "Lounge") // no matching now-playing entry below
        ]
        let nowPlaying = [NowPlayingDTO(deviceID: 1, artworkSmall: nil, artworkLarge: nil, trackName: "T", artistName: "A")]

        let rooms = RoomMapper.toDomain(devices: devices, nowPlaying: nowPlaying)

        XCTAssertEqual(rooms.count, 1)
        XCTAssertEqual(rooms.first?.id, 1)
    }

    func test_toDomain_handlesNilArtworkURLsGracefully() {
        let devices = [DeviceDTO(id: 1, name: "Bedroom")]
        let nowPlaying = [NowPlayingDTO(deviceID: 1, artworkSmall: nil, artworkLarge: nil, trackName: "T", artistName: "A")]

        let rooms = RoomMapper.toDomain(devices: devices, nowPlaying: nowPlaying)

        XCTAssertNil(rooms[0].artworkSmallURL)
        XCTAssertNil(rooms[0].artworkLargeURL)
    }
}
