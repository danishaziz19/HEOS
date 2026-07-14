import Foundation

/// One shared protocol for both the cloud and mock sources — the
/// repository holds whichever one is active behind this interface and
/// never branches on "which kind of source is this," it just calls
/// `fetchDevices()`/`fetchNowPlaying()` on whatever's currently selected.
protocol RoomsDataSource: Sendable {
    func fetchDevices() async throws -> [DeviceDTO]
    func fetchNowPlaying() async throws -> [NowPlayingDTO]
}
