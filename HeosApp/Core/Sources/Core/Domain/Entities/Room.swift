import Foundation

/// A HEOS room: a device plus whatever is playing on it. Joins
/// `devices.json` and `nowplaying.json` into one type.
///
/// `albumTitle` is nil — not in the API. `isPlaying` is also not in
/// the API; defaults to true on fetch, then owned locally by
/// `RoomsRepositoryImpl`.
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

    /// Returns a copy with isPlaying flipped.
    func togglingPlayback() -> Room {
        Room(
            id: id, name: name, trackTitle: trackTitle, artistName: artistName,
            albumTitle: albumTitle, artworkSmallURL: artworkSmallURL,
            artworkLargeURL: artworkLargeURL, isPlaying: !isPlaying
        )
    }
}
