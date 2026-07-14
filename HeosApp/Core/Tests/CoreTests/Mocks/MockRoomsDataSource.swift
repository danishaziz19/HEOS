import Foundation
@testable import Core

final class MockRoomsDataSource: RoomsDataSource, @unchecked Sendable {
    var devicesResult: Result<[DeviceDTO], Error>
    var nowPlayingResult: Result<[NowPlayingDTO], Error>
    private(set) var fetchCallCount = 0

    init(
        devicesResult: Result<[DeviceDTO], Error> = .success([]),
        nowPlayingResult: Result<[NowPlayingDTO], Error> = .success([])
    ) {
        self.devicesResult = devicesResult
        self.nowPlayingResult = nowPlayingResult
    }

    func fetchDevices() async throws -> [DeviceDTO] {
        fetchCallCount += 1
        return try devicesResult.get()
    }

    func fetchNowPlaying() async throws -> [NowPlayingDTO] {
        try nowPlayingResult.get()
    }
}
