import Foundation

/// The single source of truth behind both the Rooms and Now Playing
/// tabs.
///
/// Selection and playback state live here, not in a ViewModel, because
/// Rooms and Now Playing are two views over the SAME state — which
/// room is selected, and whether it's playing. Keeping that state in
/// the repository means there's one copy of the truth instead of two
/// ViewModels that need a separate mechanism to stay in sync.
///
/// It's an actor because that state is read and written from
/// concurrent callers (both tabs, potentially at once), and an actor
/// gives mutual exclusion without a manual lock.
///
/// `getRooms()` also coalesces in-flight fetches: if it's called again
/// while a fetch is already running — e.g. both tabs appear in quick
/// succession — the second caller awaits the same task instead of
/// firing a duplicate network request.
public actor RoomsRepositoryImpl: RoomsRepository {
    private var cloudSource: RoomsDataSource
    private var mockSource: RoomsDataSource
    private var mode: DataSourceMode
    private var rooms: [Room] = []
    private var selectedID: Int?
    private var inFlightTask: Task<[Room], Error>?

    init(
        cloudSource: RoomsDataSource,
        mockSource: RoomsDataSource,
        initialMode: DataSourceMode = .cloud
    ) {
        self.cloudSource = cloudSource
        self.mockSource = mockSource
        self.mode = initialMode
    }

    public func getRooms() async throws -> [Room] {
        if let inFlightTask {
            return try await inFlightTask.value
        }

        let source = (mode == .cloud) ? cloudSource : mockSource

        let task = Task<[Room], Error> {
            async let devices = source.fetchDevices()
            async let nowPlaying = source.fetchNowPlaying()

            let (fetchedDevices, fetchedNowPlaying) = try await (devices, nowPlaying)

            let fetched = RoomMapper.toDomain(devices: fetchedDevices, nowPlaying: fetchedNowPlaying)
            return mergePlaybackState(fetched)
        }
        inFlightTask = task

        defer { inFlightTask = nil }
        let result = try await task.value
        rooms = result

        // Clear selection if it no longer exists in the new set (e.g. after switching source).
        if let selectedID, !result.contains(where: { $0.id == selectedID }) {
            self.selectedID = nil
        }

        return result
    }

    public func cachedRooms() -> [Room] {
        rooms
    }

    public func selectRoom(id: Int) {
        selectedID = id
    }

    public func selectedRoomID() -> Int? {
        selectedID
    }
    
    public func togglePlayback(roomID: Int) async throws {
        guard let index = rooms.firstIndex(where: { $0.id == roomID }) else {
            throw RoomsError.roomNotFound
        }

        rooms[index] = rooms[index].togglingPlayback()
    }

    public func setDataSourceMode(_ newMode: DataSourceMode) {
        mode = newMode
        // Doesn't auto-refetch — next getRooms() call reads mode fresh.
    }

    public func currentDataSourceMode() -> DataSourceMode {
        mode
    }

    /// Keeps each room's current isPlaying instead of resetting it on refetch.
    private func mergePlaybackState(_ freshRooms: [Room]) -> [Room] {
        let previousByID = Dictionary(uniqueKeysWithValues: rooms.map { ($0.id, $0) })
        return freshRooms.map { fresh in
            guard let previous = previousByID[fresh.id] else { return fresh }
            return Room(
                id: fresh.id, name: fresh.name, trackTitle: fresh.trackTitle,
                artistName: fresh.artistName, albumTitle: fresh.albumTitle,
                artworkSmallURL: fresh.artworkSmallURL, artworkLargeURL: fresh.artworkLargeURL,
                isPlaying: previous.isPlaying
            )
        }
    }
}
