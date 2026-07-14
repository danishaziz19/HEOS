import Foundation

/// The single source of truth behind both the Rooms and Now Playing
/// tabs. Three design decisions worth being able to defend directly:
///
/// 1. **Why selection and playback state live here, not in a
///    ViewModel.** The Rooms tab and Now Playing tab are two different
///    views over the SAME underlying state — which room is selected,
///    and whether it's playing. If that state lived in a ViewModel, the
///    other tab's ViewModel would need some separate mechanism to stay
///    in sync with it (a delegate, a shared Combine publisher, NotificationCenter).
///    Putting it in the repository — the thing both tabs' use cases
///    already depend on — means there's only ever one copy of the
///    truth, not two copies that need to be kept consistent.
///
/// 2. **Why an actor.** Same reasoning as the request-coalescing
///    pattern from earlier prep: this holds mutable state read and
///    written from concurrent callers (both tabs, potentially
///    simultaneously), and an actor gives mutual exclusion on that
///    state without a manual lock.
///
/// 3. **In-flight fetch coalescing**, reused directly from the pattern
///    discussed in the first-round interview: if `getRooms()` is called
///    again while a fetch is already running — e.g. both tabs appear in
///    quick succession and each triggers a refresh — the second caller
///    awaits the SAME task rather than firing a duplicate network
///    request.
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
            let fetched = RoomMapper.toDomain(devices: try await devices, nowPlaying: try await nowPlaying)
            return mergePlaybackState(fetched)
        }
        inFlightTask = task

        defer { inFlightTask = nil }
        let result = try await task.value
        rooms = result

        // If the previously selected room no longer exists in the new
        // set (e.g. after switching data source), clear the selection
        // rather than pointing at a stale ID.
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

    public func togglePlayback(roomID: Int) throws {
        guard let index = rooms.firstIndex(where: { $0.id == roomID }) else {
            throw RoomsError.roomNotFound
        }
        rooms[index] = rooms[index].togglingPlayback()
    }

    public func setDataSourceMode(_ newMode: DataSourceMode) {
        mode = newMode
        // Deliberately doesn't auto-refetch here — the next call to
        // getRooms() (triggered by the ViewModel right after this) will
        // read `mode` fresh. Keeping "switch mode" and "fetch" as two
        // separate, explicit steps rather than one method doing both
        // makes each easier to test and reason about independently.
    }

    public func currentDataSourceMode() -> DataSourceMode {
        mode
    }

    /// When a fresh fetch comes back, any room that already existed in
    /// the cached set keeps its current (possibly locally-toggled)
    /// playback state instead of being reset back to the API's implicit
    /// default. Without this, refreshing the Rooms list would silently
    /// undo whatever the user had just toggled on the Now Playing screen.
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
