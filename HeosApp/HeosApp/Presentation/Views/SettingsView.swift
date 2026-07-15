import SwiftUI
import Core

struct SettingsView: View {
    var viewModel: HeosViewModel

    var body: some View {
        NavigationStack {
            Form {
                Toggle("Mock Data", isOn: Binding(
                    get: { viewModel.mockDataEnabled },
                    set: { newValue in
                        Task { await viewModel.setMockDataEnabled(newValue) }
                    }
                ))
                .accessibilityIdentifier("mockDataToggle")
            }
            .navigationTitle("Settings")
        }
    }
}
