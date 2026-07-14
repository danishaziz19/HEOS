//
//  CoreDI.swift
//  Core
//
//  Created by Danish Aziz on 14/7/2026.
//

import Foundation

public enum CoreDI {

    public static func makeRepository(
        initialMode: DataSourceMode
    ) -> RoomsRepository {
        RoomsRepositoryImpl(
            cloudSource: RemoteRoomsDataSource(),
            mockSource: LocalRoomsDataSource(),
            initialMode: initialMode
        )
    }
}
