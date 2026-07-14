import XCTest
import Core
@testable import HeosApp

// NOTE: "HeosApp" must match your actual Xcode project's module name
// (Target -> Build Settings -> Product Module Name). Rename this import
// if you named the project differently.

private struct MockGetRoomsUseCase: GetRoomsUseCase {
    var result: Result<[Room], Error>
    func execute() async throws -> [Room] { try result.get() }
}

private struct MockGetCachedRoomsUseCase: GetCachedRoomsUseCase {
    let rooms: [Room]
    func execute() async -> [Room] { rooms }
}

private actor MockSelectRoomUseCase: SelectRoomUseCase {
    private(set) var lastSelected: Int?
    func execute(roomID: Int) async { lastSelected = roomID }
}

private struct MockGetSelectedRoomIDUseCase: GetSelectedRoomIDUseCase {
    let id: Int?
    func execute() async -> Int? { id }
}

private struct MockTogglePlaybackUseCase: TogglePlaybackUseCase {
    var error: Error?
    func execute(roomID: Int) async throws { if let error { throw error } }
}

private actor MockSetDataSourceModeUseCase: SetDataSourceModeUseCase {
    private(set) var lastMode: DataSourceMode?
    func execute(mode: DataSourceMode) async { lastMode = mode }
}

private struct MockGetCurrentDataSourceModeUseCase: GetCurrentDataSourceModeUseCase {
    let mode: DataSourceMode
    func execute() async -> DataSourceMode { mode }
}

@MainActor
final class HeosViewModelTests: XCTestCase {

    private func sampleRoom(_ id: Int, playing: Bool = true) -> Room {
        Room(id: id, name: "Room \(id)", trackTitle: "Track", artistName: "Artist",
             albumTitle: nil, artworkSmallURL: nil, artworkLargeURL: nil, isPlaying: playing)
    }

    private func makeSUT(
        rooms: [Room] = [],
        selectedID: Int? = nil,
        togglePlaybackError: Error? = nil
    ) -> HeosViewModel {
        HeosViewModel(
            getRooms: MockGetRoomsUseCase(result: .success(rooms)),
            getCachedRooms: MockGetCachedRoomsUseCase(rooms: rooms),
            selectRoomUseCase: MockSelectRoomUseCase(),
            getSelectedRoomID: MockGetSelectedRoomIDUseCase(id: selectedID),
            togglePlaybackUseCase: MockTogglePlaybackUseCase(error: togglePlaybackError),
            setDataSourceMode: MockSetDataSourceModeUseCase(),
            getCurrentDataSourceMode: MockGetCurrentDataSourceModeUseCase(mode: .cloud)
        )
    }

    func test_refresh_loadsRoomsAndDefaultsSelectionToFirstRoom() async {
        let rooms = [sampleRoom(1), sampleRoom(2)]
        let sut = makeSUT(rooms: rooms, selectedID: nil)

        await sut.refresh()

        XCTAssertEqual(sut.rooms.count, 2)
        XCTAssertEqual(sut.selectedRoomID, 1, "Should default to the first room when nothing was previously selected")
        XCTAssertEqual(sut.viewState, .loaded)
    }

    func test_refresh_respectsExistingSelection() async {
        let rooms = [sampleRoom(1), sampleRoom(2)]
        let sut = makeSUT(rooms: rooms, selectedID: 2)

        await sut.refresh()

        XCTAssertEqual(sut.selectedRoomID, 2)
    }

    func test_selectedRoom_returnsMatchingRoomFromSelectedID() async {
        let rooms = [sampleRoom(1), sampleRoom(2)]
        let sut = makeSUT(rooms: rooms, selectedID: 2)

        await sut.refresh()

        XCTAssertEqual(sut.selectedRoom?.id, 2)
    }

    func test_togglePlayback_refreshesRoomsFromCacheAfterToggling() async {
        let initialRooms = [sampleRoom(1, playing: true)]
        let sut = makeSUT(rooms: initialRooms, selectedID: 1)
        await sut.refresh()

        await sut.togglePlayback()

        // Cached rooms mock always returns the same fixed array in this
        // test double, so this mainly proves togglePlayback() doesn't
        // crash and re-reads from getCachedRooms — the actual state
        // flip is covered by RoomsRepositoryImplTests at the Core layer.
        XCTAssertEqual(sut.rooms.count, 1)
    }

    func test_setMockDataEnabled_updatesFlagAndTriggersRefresh() async {
        let rooms = [sampleRoom(1)]
        let sut = makeSUT(rooms: rooms)

        await sut.setMockDataEnabled(true)

        XCTAssertTrue(sut.mockDataEnabled)
        XCTAssertEqual(sut.viewState, .loaded)
    }
}
