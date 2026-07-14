//
//  DIContainer.swift
//  HeosApp
//
//  Created by Danish Aziz on 14/7/2026.
//

import Foundation
import Core

/// Manual DI container — no third-party framework, everything below
/// is constructor-injected and depends only on protocols.
struct DIContainer {
    private let repository: RoomsRepository

    private init(repository: RoomsRepository) {
        self.repository = repository
    }

    static func make() -> DIContainer {
        // --uitesting forces mock mode so UI tests are deterministic and network-independent.
        let initialMode: DataSourceMode = ProcessInfo.processInfo.arguments.contains("--uitesting")
            ? .mockData
            : .cloud // off by default per spec

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
