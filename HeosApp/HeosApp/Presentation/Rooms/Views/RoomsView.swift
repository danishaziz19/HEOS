import SwiftUI
import Core

struct RoomsView: View {
    var viewModel: HeosViewModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Rooms")
                .task { await viewModel.onAppear() }
                .refreshable { await viewModel.refresh() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .loading:
            ProgressView("Loading rooms…")

        case .failed(let error):
            errorView(error)

        case .loaded:
            List(viewModel.rooms) { room in
                RoomRow(room: room, isSelected: room.id == viewModel.selectedRoomID)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Task { await viewModel.selectRoom(room.id) }
                    }
                    // Keeps children (the playback indicator) individually
                    // queryable instead of collapsing into one element.
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("room_row_\(room.id)")
            }
            .accessibilityIdentifier("roomsList")
        }
    }

    private func errorView(_ error: RoomsError) -> some View {
        VStack(spacing: 12) {
            Text("Couldn't load rooms")
            Button("Try Again") { Task { await viewModel.refresh() } }
        }
    }
}

private struct RoomRow: View {
    let room: Room
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: room.artworkSmallURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(.secondary.opacity(0.2))
                    .overlay(Image(systemName: "music.note"))
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(room.name).font(.headline)
                Text("\(room.trackTitle) — \(room.artistName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: room.isPlaying ? "speaker.wave.2.fill" : "pause.fill")
                .foregroundStyle(room.isPlaying ? .green : .secondary)
                .accessibilityIdentifier("room_\(room.id)_playbackIndicator")
                .accessibilityLabel(room.isPlaying ? "Playing" : "Paused")

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}
