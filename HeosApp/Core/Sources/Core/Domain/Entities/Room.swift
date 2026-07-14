import Foundation

/// The domain-layer concept of a "HEOS room": a device plus whatever is
/// currently playing on it. The two source endpoints (`devices.json` and
/// `nowplaying.json`) model these as two separate collections joined by
/// `Device ID`; the presentation layer should never have to know that —
/// it works with one cohesive `Room`, joined once in the Data layer.
///
/// Two fields here are worth flagging explicitly rather than leaving
/// silent, since they don't actually exist in the provided API response:
///
/// - `albumTitle` is `nil` because `nowplaying.json` has no album field
///   at all — only track name and artist name. Rather than inventing a
///   value, I surface it as optional end-to-end and let the view show a
///   sensible placeholder.
/// - `isPlaying` doesn't exist in the API either, despite the spec
///   asking for a playback state per device. I default every room to
///   `true` on initial fetch — "now playing" data reasonably implies
///   active playback — and then the app owns that state locally from
///   that point on (toggled via the Play/Pause button, kept in sync
///   between the Rooms and Now Playing tabs). See `RoomsRepositoryImpl`
///   for where that state actually lives.
public struct Room: Equatable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let trackTitle: String
    public let artistName: String
    public let albumTitle: String?
    public let artworkSmallURL: URL?
    public let artworkLargeURL: URL?
    public let isPlaying: Bool

    public init(
        id: Int,
        name: String,
        trackTitle: String,
        artistName: String,
        albumTitle: String?,
        artworkSmallURL: URL?,
        artworkLargeURL: URL?,
        isPlaying: Bool
    ) {
        self.id = id
        self.name = name
        self.trackTitle = trackTitle
        self.artistName = artistName
        self.albumTitle = albumTitle
        self.artworkSmallURL = artworkSmallURL
        self.artworkLargeURL = artworkLargeURL
        self.isPlaying = isPlaying
    }

    /// Convenience for producing a copy with playback toggled — used by
    /// the repository when applying a local play/pause mutation without
    /// needing a mutable class or re-fetching from the network.
    func togglingPlayback() -> Room {
        Room(
            id: id, name: name, trackTitle: trackTitle, artistName: artistName,
            albumTitle: albumTitle, artworkSmallURL: artworkSmallURL,
            artworkLargeURL: artworkLargeURL, isPlaying: !isPlaying
        )
    }
}
