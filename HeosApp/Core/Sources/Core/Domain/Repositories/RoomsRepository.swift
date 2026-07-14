import Foundation

/// The one abstraction everything above the Data layer depends on.
/// Deliberately owns more than a typical read-only repository would —
/// selection state and playback state live here too, not scattered
/// across ViewModels — because both the Rooms tab and the Now Playing
/// tab need to agree on the same state, and a repository (backed by an
/// actor) is the natural single source of truth for that, the same way
/// it would be the source of truth for cached data in a larger app.
public protocol RoomsRepository: Sendable {
    /// Fetches rooms from whichever source is currently active
    /// (cloud or mock), replacing the cached list.
    func getRooms() async throws -> [Room]

    /// The last-fetched rooms without triggering a new fetch — used so
    /// the Now Playing tab can read the currently selected room without
    /// re-fetching every time the user switches tabs.
    func cachedRooms() async -> [Room]

    func selectRoom(id: Int) async
    func selectedRoomID() async -> Int?

    /// Toggles play/pause for a room and updates the cached state in
    /// place — this is what keeps the Rooms list and Now Playing screen
    /// in sync, since they both read from this same cached state.
    func togglePlayback(roomID: Int) async throws

    func setDataSourceMode(_ mode: DataSourceMode) async
    func currentDataSourceMode() async -> DataSourceMode
}
