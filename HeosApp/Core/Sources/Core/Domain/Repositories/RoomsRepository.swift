import Foundation

/// Single source of truth for rooms, selection, and playback state —
/// backed by an actor so both tabs stay in sync.
public protocol RoomsRepository: Sendable {
    /// Fetches from the active source (cloud or mock), replacing the cache.
    func getRooms() async throws -> [Room]

    /// Last-fetched rooms, no new fetch.
    func cachedRooms() async -> [Room]

    func selectRoom(id: Int) async
    func selectedRoomID() async -> Int?

    /// Toggles play/pause and updates the cache in place.
    func togglePlayback(roomID: Int) async throws

    func setDataSourceMode(_ mode: DataSourceMode) async
    func currentDataSourceMode() async -> DataSourceMode
}
