import SwiftUI
import Core

struct NowPlayingView: View {
    var viewModel: HeosViewModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Now Playing")
                .task { await viewModel.onAppear() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .loading:
            ProgressView()

        case .failed:
            Text("Couldn't load now playing")
                .foregroundStyle(.secondary)

        case .loaded:
            if let room = viewModel.selectedRoom {
                nowPlayingCard(room)
            } else {
                Text("Select a room to see what's playing")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func nowPlayingCard(_ room: Room) -> some View {
        VStack(spacing: 16) {
            AsyncImage(url: room.artworkLargeURL) { image in
                image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.secondary.opacity(0.2))
                    .overlay(Image(systemName: "music.note").font(.system(size: 40)))
            }
            .frame(width: 240, height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(room.name)
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("nowPlayingRoomName")

            Text(room.trackTitle)
                .font(.title2).bold()
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("nowPlayingTrackTitle")

            // Deliberately shown even when nil, rather than hiding the
            // row — makes it visible during review that this field is
            // genuinely absent from the API response, not just unstyled.
            Text(room.albumTitle ?? "Album title not provided by API")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("nowPlayingAlbumTitle")

            Text(room.artistName)
                .font(.subheadline)
                .accessibilityIdentifier("nowPlayingArtistName")

            Button {
                Task { await viewModel.togglePlayback() }
            } label: {
                Image(systemName: room.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 56))
            }
            .accessibilityIdentifier("playPauseButton")
            .accessibilityLabel(room.isPlaying ? "Pause" : "Play")
            .padding(.top, 8)
        }
        .padding()
    }
}
