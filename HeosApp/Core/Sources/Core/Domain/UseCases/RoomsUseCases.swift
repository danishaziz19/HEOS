import Foundation

public protocol GetRoomsUseCase: Sendable {
    func execute() async throws -> [Room]
}

public protocol GetCachedRoomsUseCase: Sendable {
    func execute() async -> [Room]
}

public protocol SelectRoomUseCase: Sendable {
    func execute(roomID: Int) async
}

public protocol GetSelectedRoomIDUseCase: Sendable {
    func execute() async -> Int?
}

public protocol TogglePlaybackUseCase: Sendable {
    func execute(roomID: Int) async throws
}

public protocol SetDataSourceModeUseCase: Sendable {
    func execute(mode: DataSourceMode) async
}

public protocol GetCurrentDataSourceModeUseCase: Sendable {
    func execute() async -> DataSourceMode
}

// MARK: - Default implementations (thin pass-throughs onto the repository)

public struct DefaultGetRoomsUseCase: GetRoomsUseCase {
    private let repository: RoomsRepository
    public init(repository: RoomsRepository) { self.repository = repository }
    public func execute() async throws -> [Room] { try await repository.getRooms() }
}

public struct DefaultGetCachedRoomsUseCase: GetCachedRoomsUseCase {
    private let repository: RoomsRepository
    public init(repository: RoomsRepository) { self.repository = repository }
    public func execute() async -> [Room] { await repository.cachedRooms() }
}

public struct DefaultSelectRoomUseCase: SelectRoomUseCase {
    private let repository: RoomsRepository
    public init(repository: RoomsRepository) { self.repository = repository }
    public func execute(roomID: Int) async { await repository.selectRoom(id: roomID) }
}

public struct DefaultGetSelectedRoomIDUseCase: GetSelectedRoomIDUseCase {
    private let repository: RoomsRepository
    public init(repository: RoomsRepository) { self.repository = repository }
    public func execute() async -> Int? { await repository.selectedRoomID() }
}

public struct DefaultTogglePlaybackUseCase: TogglePlaybackUseCase {
    private let repository: RoomsRepository
    public init(repository: RoomsRepository) { self.repository = repository }
    public func execute(roomID: Int) async throws { try await repository.togglePlayback(roomID: roomID) }
}

public struct DefaultSetDataSourceModeUseCase: SetDataSourceModeUseCase {
    private let repository: RoomsRepository
    public init(repository: RoomsRepository) { self.repository = repository }
    public func execute(mode: DataSourceMode) async { await repository.setDataSourceMode(mode) }
}

public struct DefaultGetCurrentDataSourceModeUseCase: GetCurrentDataSourceModeUseCase {
    private let repository: RoomsRepository
    public init(repository: RoomsRepository) { self.repository = repository }
    public func execute() async -> DataSourceMode { await repository.currentDataSourceMode() }
}
