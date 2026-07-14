import Foundation
import Core

/// One `@Observable` instance shared across all three tabs (constructed
/// once in the composition root, passed to `RoomsView`, `NowPlayingView`,
/// and `SettingsView` alike), rather than a separate ViewModel per tab.
/// This is the single biggest architectural decision in this project and
/// worth being able to defend directly:
///
/// **Why one shared ViewModel instead of three.** Rooms, Now Playing,
/// and Settings aren't three independent screens — they're three views
/// over ONE piece of app state: the list of rooms, which room is
/// selected, and where that data comes from. If each tab had its own
/// ViewModel, keeping them in sync (Rooms selection updating Now
/// Playing; the Play/Pause button on Now Playing updating the Rooms
/// list; the Settings toggle triggering every tab to refetch) would
/// require some separate synchronization mechanism between them —
/// a delegate, NotificationCenter, or a shared Combine publisher. With
/// `@Observable`, sharing one instance gives that synchronization for
/// free: SwiftUI already re-renders any view reading a property that
/// changed, regardless of which tab triggered the change.
///
/// **Where this WOULDN'T be the right call**, and I'd want to be
/// explicit about that boundary rather than pretend one shared
/// ViewModel is always correct: if the app grew to the point where
/// Now Playing needed genuinely independent state (e.g. a persistent
/// mini-player surviving navigation, queue management, its own loading
/// states unrelated to the Rooms list), I'd split it out and have each
/// ViewModel subscribe to an `AsyncStream<[Room]>` exposed by the
/// repository instead of sharing one object directly — same single
/// source of truth at the Data layer, but presentation-layer boundaries
/// that scale with feature ownership rather than one god-object. For
/// this app's actual scope, that would be premature complexity for no
/// real benefit.
@MainActor
@Observable
final class HeosViewModel {
    private(set) var rooms: [Room] = []
    private(set) var selectedRoomID: Int?
    private(set) var viewState: RoomsViewState = .loading
    private(set) var mockDataEnabled: Bool

    var selectedRoom: Room? {
        rooms.first(where: { $0.id == selectedRoomID })
    }

    private let getRooms: GetRoomsUseCase
    private let getCachedRooms: GetCachedRoomsUseCase
    private let selectRoomUseCase: SelectRoomUseCase
    private let getSelectedRoomID: GetSelectedRoomIDUseCase
    private let togglePlaybackUseCase: TogglePlaybackUseCase
    private let setDataSourceMode: SetDataSourceModeUseCase
    private let getCurrentDataSourceMode: GetCurrentDataSourceModeUseCase

    init(
        getRooms: GetRoomsUseCase,
        getCachedRooms: GetCachedRoomsUseCase,
        selectRoomUseCase: SelectRoomUseCase,
        getSelectedRoomID: GetSelectedRoomIDUseCase,
        togglePlaybackUseCase: TogglePlaybackUseCase,
        setDataSourceMode: SetDataSourceModeUseCase,
        getCurrentDataSourceMode: GetCurrentDataSourceModeUseCase
    ) {
        self.getRooms = getRooms
        self.getCachedRooms = getCachedRooms
        self.selectRoomUseCase = selectRoomUseCase
        self.getSelectedRoomID = getSelectedRoomID
        self.togglePlaybackUseCase = togglePlaybackUseCase
        self.setDataSourceMode = setDataSourceMode
        self.getCurrentDataSourceMode = getCurrentDataSourceMode
        self.mockDataEnabled = false // Settings spec: off by default
    }

    func onAppear() async {
        guard rooms.isEmpty else { return } // avoid refetching every tab switch; Rooms/NowPlaying share this same call
        await refresh()
    }

    func refresh() async {
        viewState = .loading
        // Sync the displayed toggle state from the repository's actual
        // current mode, rather than only ever updating it from a direct
        // user interaction. Without this, a mode set some other way
        // (e.g. the launch-argument override used for UI testing, see
        // HeosApp.swift) would leave the Settings toggle showing the
        // wrong state even though the underlying data source was
        // correct — a real bug I caught while adding UI tests, not a
        // hypothetical one.
        mockDataEnabled = await getCurrentDataSourceMode.execute() == .mockData
        do {
            rooms = try await getRooms.execute()
            selectedRoomID = await getSelectedRoomID.execute() ?? rooms.first?.id
            if let selectedRoomID { await selectRoomUseCase.execute(roomID: selectedRoomID) }
            viewState = .loaded
        } catch let error as RoomsError {
            viewState = .failed(error)
        } catch {
            viewState = .failed(.unknown)
        }
    }

    func selectRoom(_ roomID: Int) async {
        selectedRoomID = roomID
        await selectRoomUseCase.execute(roomID: roomID)
    }

    /// Re-entrant-safe the same way as the earlier repository-level
    /// request coalescing: this can be called rapidly (button mashing on
    /// Now Playing) and each call still resolves correctly, because the
    /// actual mutation happens in the actor-isolated repository, not
    /// here — this method just reflects the repository's cached state
    /// back into `rooms` afterward.
    func togglePlayback() async {
        guard let selectedRoomID else { return }
        do {
            try await togglePlaybackUseCase.execute(roomID: selectedRoomID)
            rooms = await getCachedRooms.execute()
        } catch {
            viewState = .failed((error as? RoomsError) ?? .unknown)
        }
    }

    func setMockDataEnabled(_ enabled: Bool) async {
        mockDataEnabled = enabled
        await setDataSourceMode.execute(mode: enabled ? .mockData : .cloud)
        await refresh()
    }
}
