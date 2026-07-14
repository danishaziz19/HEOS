//
//  HeosAppApp.swift
//  HeosApp
//
//  Created by Danish Aziz on 14/7/2026.
//

import SwiftUI
import Core

@main
struct HeosApp: App {
    // Composition root. One HeosViewModel instance, shared across all
    // three tabs — see the doc comment on HeosViewModel for why.
    @State private var viewModel = DIContainer.live().makeHeosViewModel()

    var body: some Scene {
        WindowGroup {
            TabView {
                RoomsView(viewModel: viewModel)
                    .tabItem { Label("Rooms", systemImage: "house") }

                NowPlayingView(viewModel: viewModel)
                    .tabItem { Label("Now Playing", systemImage: "play.circle") }

                SettingsView(viewModel: viewModel)
                    .tabItem { Label("Settings", systemImage: "gear") }
            }
        }
    }
}
