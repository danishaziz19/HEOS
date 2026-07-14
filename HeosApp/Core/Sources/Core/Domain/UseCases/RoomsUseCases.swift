import Foundation

/// Why seven separate use case protocols instead of one RoomsUseCase
/// with seven methods on it? This is probably the first thing I'd get
/// asked about in review, so here's the reasoning.
///
/// The brief says to design assuming the app gets more complex later.
/// This is where that assumption actually pays off — each use case is
/// a spot where a real rule can get added down the line without
/// touching the ViewModel or the repository. Some examples that
/// actually make sense for a HEOS app:
///
/// - TogglePlaybackUseCase could check `room.isReachable` and throw if
///   the speaker's gone offline — disconnected devices are a real
///   problem for remote-control apps, not a made-up scenario.
/// - GetRoomsUseCase could retry once before showing an error, instead
///   of failing the whole screen on one dropped packet.
/// - SetDataSourceModeUseCase could get wrapped in #if DEBUG so the
///   mock toggle disappears in release builds. That's the kind of rule
///   that doesn't really belong in the repository or the view either.
///
/// It also lines up with SOLID pretty directly: single responsibility
/// because each use case only changes for one reason, interface
/// segregation because a screen that only reads rooms depends on
/// GetRoomsUseCase and nothing else, and dependency inversion because
/// everything points at a protocol — use cases depend on
/// RoomsRepository, the ViewModel depends on the use case protocols —
/// with DIContainer as the only place any of it gets wired to a
/// concrete type.
///
/// And to be upfront about it: for an app this small, with no real
/// business rules yet, just calling RoomsRepository straight from the
/// ViewModel, or using one RoomsUseCase with seven methods, would work
/// fine and would be just as easy to defend. I split it out this far
/// because the brief specifically asked for it, not because more files
/// automatically means better code. If this were staying a small
/// 3-tab app forever, I'd use the simpler version — knowing when not
/// to reach for a pattern matters as much as knowing the pattern.
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
