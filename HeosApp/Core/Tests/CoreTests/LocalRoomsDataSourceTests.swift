import XCTest
@testable import Core

/// Unlike RoomsRepositoryImplTests (which uses MockRoomsDataSource and
/// never touches a real bundle), this exercises LocalRoomsDataSource
/// against the actual devices_mock.json / nowplaying_mock.json shipped
/// in the Core package — the only test that would catch a resource-name
/// typo or a missing .copy(...) entry in Package.swift.
final class LocalRoomsDataSourceTests: XCTestCase {

    func test_fetchDevices_decodesRealBundledMockJSON() async throws {
        let sut = LocalRoomsDataSource()

        let devices = try await sut.fetchDevices()

        XCTAssertEqual(devices.count, 3)
        XCTAssertTrue(devices.contains { $0.id == 101 && $0.name == "Office (Mock)" })
    }

    func test_fetchNowPlaying_decodesRealBundledMockJSON() async throws {
        let sut = LocalRoomsDataSource()

        let nowPlaying = try await sut.fetchNowPlaying()

        XCTAssertEqual(nowPlaying.count, 3)
        XCTAssertTrue(nowPlaying.contains { $0.deviceID == 101 && $0.trackName == "Mock Track One" })
    }

    func test_mockDevicesAndNowPlaying_joinIntoThreeRooms() async throws {
        let sut = LocalRoomsDataSource()

        let devices = try await sut.fetchDevices()
        let nowPlaying = try await sut.fetchNowPlaying()
        let rooms = RoomMapper.toDomain(devices: devices, nowPlaying: nowPlaying)

        XCTAssertEqual(rooms.count, 3, "Every mock device should have a matching now-playing entry")
    }
}
