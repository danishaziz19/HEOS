//
//  DIContainer.swift
//  HeosApp
//
//  Created by Danish Aziz on 14/7/2026.
//

import Foundation
import Core

/// Manual DI container, same reasoning as earlier prep: no third-party
/// DI framework needed at this scope, but every dependency below this
/// point is still constructor-injected and depends only on protocols.
struct DIContainer {
    private let repository: RoomsRepository

    private init(repository: RoomsRepository) {
        self.repository = repository
    }

    static func live() -> DIContainer {
        // UI tests launch with "--uitesting" to force Mock Data mode —
        // this makes UI tests deterministic and fast (no real network
        // call, no dependency on the live S3 endpoint being reachable
        // or its content staying the same), while exercising exactly
        // the same code path a real user hits when they flip the
        // Settings toggle themselves. Same reasoning as the dev-switch/
        // feature-flag pattern from the interview — a flag controlling
        // behavior for a specific context, checked in exactly one place.
        let initialMode: DataSourceMode = ProcessInfo.processInfo.arguments.contains("--uitesting")
            ? .mockData
            : .cloud // Settings spec: Mock Data switch is off by default

        return DIContainer(
            repository: CoreDI.makeRepository(initialMode: initialMode)
        )
    }
    

    @MainActor
    func makeHeosViewModel() -> HeosViewModel {
        HeosViewModel(
            getRooms: DefaultGetRoomsUseCase(repository: repository),
            getCachedRooms: DefaultGetCachedRoomsUseCase(repository: repository),
            selectRoomUseCase: DefaultSelectRoomUseCase(repository: repository),
            getSelectedRoomID: DefaultGetSelectedRoomIDUseCase(repository: repository),
            togglePlaybackUseCase: DefaultTogglePlaybackUseCase(repository: repository),
            setDataSourceMode: DefaultSetDataSourceModeUseCase(repository: repository),
            getCurrentDataSourceMode: DefaultGetCurrentDataSourceModeUseCase(repository: repository)
        )
    }
}
