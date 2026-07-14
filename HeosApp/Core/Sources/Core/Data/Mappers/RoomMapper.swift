import Foundation

/// The join point between two independently-fetched endpoints. This is
/// deliberately isolated in its own type rather than inlined into the
/// repository, for the same reason `TrackMapper` was isolated in earlier
/// work: mapping bugs (a device with no matching now-playing entry, a
/// malformed artwork URL) are easy to miss buried inside a repository
/// method, and easy to catch with direct, isolated mapper tests.
enum RoomMapper {

    /// Joins devices with their now-playing entry by `Device ID` / `ID`.
    /// A device with no matching now-playing entry is dropped rather
    /// than shown with blank/fake track data — the Rooms tab spec
    /// requires track name, artist name, and artwork per row, so a
    /// device we have no playback data for isn't something the view
    /// layer should have to guess how to render. In a production app
    /// I'd expect this to be a rarer edge case worth telemetry on, not
    /// a silent drop, but that's outside this exercise's scope.
    static func toDomain(devices: [DeviceDTO], nowPlaying: [NowPlayingDTO]) -> [Room] {
        let nowPlayingByDeviceID = Dictionary(
            nowPlaying.map { ($0.deviceID, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        return devices.compactMap { device in
            guard let playing = nowPlayingByDeviceID[device.id] else { return nil }

            return Room(
                id: device.id,
                name: device.name,
                trackTitle: playing.trackName,
                artistName: playing.artistName,
                // Not present in the API response at all — see the
                // doc comment on `Room.albumTitle`.
                albumTitle: nil,
                artworkSmallURL: playing.artworkSmall.flatMap(URL.init(string:)),
                artworkLargeURL: playing.artworkLarge.flatMap(URL.init(string:)),
                // Not present in the API response either — defaulted
                // to true on initial fetch, then owned locally by the
                // repository from that point on. See
                // `RoomsRepositoryImpl.mergePlaybackState`.
                isPlaying: true
            )
        }
    }
}
