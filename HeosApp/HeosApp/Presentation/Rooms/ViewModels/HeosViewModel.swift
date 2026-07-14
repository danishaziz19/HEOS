import Foundation
import Core

/// One `@Observable` instance shared across all three tabs, instead of
/// a separate ViewModel per tab. Rooms, Now Playing, and Settings are
/// three views over ONE piece of state (rooms, selection, data source),
/// so sharing one instance keeps them in sync for free — SwiftUI
/// re-renders any view reading a property that changed, regardless of
/// which tab triggered it. Separate ViewModels would need their own
/// sync mechanism (delegate, NotificationCenter, Combine) to achieve
/// the same thing.
///
/// Would split this out if Now Playing ever needed genuinely
/// independent state (a persistent mini-player, a queue) — each
/// ViewModel would subscribe to an `AsyncStream<[Room]>` from the
/// repository instead. Not needed at this app's scope.
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
        // Re-read the actual mode so the toggle stays correct even when
        // mode was set some other way (e.g. --uitesting), not just from a direct tap.
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

    /// Mutation happens in the actor-isolated repository; this just
    /// reflects the cached state back into `rooms`.
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
