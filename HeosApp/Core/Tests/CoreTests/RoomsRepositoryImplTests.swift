import XCTest
@testable import Core

final class RoomsRepositoryImplTests: XCTestCase {

    private func device(_ id: Int, _ name: String) -> DeviceDTO { DeviceDTO(id: id, name: name) }
    private func nowPlaying(_ id: Int) -> NowPlayingDTO {
        NowPlayingDTO(deviceID: id, artworkSmall: nil, artworkLarge: nil, trackName: "T\(id)", artistName: "A\(id)")
    }

    func test_getRooms_usesCloudSourceByDefault() async throws {
        let cloud = MockRoomsDataSource(devicesResult: .success([device(1, "Cloud Room")]), nowPlayingResult: .success([nowPlaying(1)]))
        let mock = MockRoomsDataSource(devicesResult: .success([device(2, "Mock Room")]), nowPlayingResult: .success([nowPlaying(2)]))
        let sut = RoomsRepositoryImpl(cloudSource: cloud, mockSource: mock)

        let rooms = try await sut.getRooms()

        XCTAssertEqual(rooms.first?.name, "Cloud Room")
    }

    func test_setDataSourceMode_switchesWhichSourceNextFetchUses() async throws {
        let cloud = MockRoomsDataSource(devicesResult: .success([device(1, "Cloud Room")]), nowPlayingResult: .success([nowPlaying(1)]))
        let mock = MockRoomsDataSource(devicesResult: .success([device(2, "Mock Room")]), nowPlayingResult: .success([nowPlaying(2)]))
        let sut = RoomsRepositoryImpl(cloudSource: cloud, mockSource: mock)

        await sut.setDataSourceMode(.mockData)
        let rooms = try await sut.getRooms()

        XCTAssertEqual(rooms.first?.name, "Mock Room")
      //  XCTAssertEqual(await sut.currentDataSourceMode(), .mockData)
    }

    func test_selectRoom_persistsSelection() async {
        let sut = RoomsRepositoryImpl(cloudSource: MockRoomsDataSource(), mockSource: MockRoomsDataSource())

        await sut.selectRoom(id: 42)

        let selected = await sut.selectedRoomID()
        XCTAssertEqual(selected, 42)
    }

    func test_togglePlayback_flipsStateAndPersistsAcrossCachedReads() async throws {
        let cloud = MockRoomsDataSource(devicesResult: .success([device(1, "Room")]), nowPlayingResult: .success([nowPlaying(1)]))
        let sut = RoomsRepositoryImpl(cloudSource: cloud, mockSource: MockRoomsDataSource())

        let initial = try await sut.getRooms()
        XCTAssertTrue(initial[0].isPlaying, "Defaults to true on first fetch since the API doesn't provide this field")

        try await sut.togglePlayback(roomID: 1)

        let cached = await sut.cachedRooms()
        XCTAssertFalse(cached[0].isPlaying)
    }

    func test_togglePlayback_throwsForUnknownRoomID() async {
        let sut = RoomsRepositoryImpl(cloudSource: MockRoomsDataSource(), mockSource: MockRoomsDataSource())

        do {
            try await sut.togglePlayback(roomID: 999)
            XCTFail("Expected togglePlayback to throw for an unknown room ID")
        } catch {
            XCTAssertEqual(error as? RoomsError, .roomNotFound)
        }
    }

    /// This is the test proving the Rooms <-> Now Playing sync
    /// requirement from the spec actually holds: a locally-toggled
    /// playback state must survive a subsequent refetch (e.g. the user
    /// toggles play/pause, then switches tabs, which re-triggers
    /// getRooms() on the tab that reappears).
    func test_getRooms_preservesLocallyToggledPlaybackStateAcrossRefetch() async throws {
        let cloud = MockRoomsDataSource(devicesResult: .success([device(1, "Room")]), nowPlayingResult: .success([nowPlaying(1)]))
        let sut = RoomsRepositoryImpl(cloudSource: cloud, mockSource: MockRoomsDataSource())

        _ = try await sut.getRooms()
        try await sut.togglePlayback(roomID: 1)

        let refetched = try await sut.getRooms()

        XCTAssertFalse(refetched[0].isPlaying, "Toggled state should survive a refetch, not reset to the API's implicit default")
    }
}
